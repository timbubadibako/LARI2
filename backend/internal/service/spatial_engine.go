package service

import (
	"context"
	"fmt"
	"log"
	"math"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type SpatialEngine struct {
	db *pgxpool.Pool
}

type ConquestResult struct {
	CapturedAreaSqm       float64
	RunStatus             string
	ClaimReason           string
	PendingTrailActive    bool
	PendingTrailExpiresAt *time.Time
}

// SELECT
    user_id,
    total_area_sqm,
    ST_AsText(merged_boundary)
  FROM user_territories
  WHERE sector_id = 'DEFAULT';minConquestAreaSqm is the minimum enclosed area (in square meters) required
// to register a territory capture. This prevents accidental micro-loops from
// GPS jitter near the start point from claiming territory.
// 50 m² ≈ roughly the size of a large room — intentional loops will be much larger.
const minConquestAreaSqm = 50.0
const loopClosureToleranceMeters = 5.0
const minLoopDisplacementMeters = 50.0
const pendingTrailContinuationWindowHours = 72
const minRetainedTerritoryFragmentSqm = 200.0
const minRetainedTerritoryFragmentRatio = 0.12

func NewSpatialEngine(db *pgxpool.Pool) *SpatialEngine {
	return &SpatialEngine{db: db}
}

// MapMatchPoints attempts to snap points to the nearest road using a map-matching algorithm.
// Tactical Requirement: Snapping boundary is 20m.
func (s *SpatialEngine) MapMatchPoints(ctx context.Context, points []Point) ([]Point, error) {
	// TODO: Integrate with local OSRM instance /match service.

	// ARCHITECTURAL RULE:
	// If distance from point to nearest road > 20m, DO NOT SNAP (Off-Road Mode).
	// This preserves the "Elastic Trail" integrity for agents in parks/fields.

	return points, nil
}

// ProcessConquest handles the "Elastic Trails" and Loop Detection logic.
func (s *SpatialEngine) ProcessConquest(ctx context.Context, userID string, guildID string, points []Point) (ConquestResult, error) {
	result := ConquestResult{
		RunStatus:   "finished",
		ClaimReason: "no_closed_loop",
	}

	// A. Snap to Road first to increase accuracy (20m boundary inside MapMatchPoints)
	snappedPoints, err := s.MapMatchPoints(ctx, points)
	if err == nil {
		points = snappedPoints
	}

	// Align backend polygonization with the frontend loop-closure rule.
	// The UI marks a loop as closed when the runner returns near the start point,
	// even if the final GPS sample does not exactly equal the first sample.
	if s.shouldForceCloseLoop(points) {
		points = append(points, points[0])
	}

	// 1. Create a WKT LineString from points
	wktLine := s.pointsToWKT(points)

	// 2. Check for "Integrity Protocol" (Connection to pending trails)
	tx, err := s.db.Begin(ctx)
	if err != nil {
		return result, err
	}
	defer tx.Rollback(ctx)

	// A. Find matching pending trail
	// Requirement: 8-10m radius. 0.00009 degrees is ~10 meters.
	var pendingID int
	var pendingGeomWKT string
	startPointWKT := fmt.Sprintf("POINT(%f %f)", points[0].Lng, points[0].Lat)

	err = tx.QueryRow(ctx, `
		SELECT id, ST_AsText(geom) 
		FROM pending_trails 
		WHERE user_id = $1 
		  AND (ST_DWithin(end_point, ST_GeomFromText($2, 4326), 0.00009) 
		       OR ST_DWithin(start_point, ST_GeomFromText($2, 4326), 0.00009))
		LIMIT 1
	`, userID, startPointWKT).Scan(&pendingID, &pendingGeomWKT)

	var fullTrailWKT string
	if err == nil {
		log.Printf("CONQUEST_PENDING_TRAIL_MERGE: user_id=%s pending_id=%d", userID, pendingID)
		// Found a connection! Merge them.
		err = tx.QueryRow(ctx, `
			SELECT ST_AsText(ST_LineMerge(ST_Union(ST_GeomFromText($1, 4326), ST_GeomFromText($2, 4326))))
		`, pendingGeomWKT, wktLine).Scan(&fullTrailWKT)
		if err != nil {
			return result, fmt.Errorf("failed to merge lines: %w", err)
		}
		// Delete the old segment as it will be updated or turned into a polygon
		if _, err = tx.Exec(ctx, "DELETE FROM pending_trails WHERE id = $1", pendingID); err != nil {
			return result, fmt.Errorf("failed to delete consumed pending trail: %w", err)
		}
	} else if err == pgx.ErrNoRows {
		// No connection found.
		// "Chain or Crash": Clear any existing pending trails for this user (they've started a new chain elsewhere)
		if _, err = tx.Exec(ctx, "DELETE FROM pending_trails WHERE user_id = $1", userID); err != nil {
			return result, fmt.Errorf("failed to clear stale pending trails: %w", err)
		}
		fullTrailWKT = wktLine
	} else {
		return result, fmt.Errorf("failed to lookup pending trail: %w", err)
	}

	// 3. Detect Loops via ST_BuildArea
	var areaSqm float64
	var remainingLinesWKT string
	var capturedPolyWKT string

	// Use noded linework + polygonize so lasso-shaped trails (A -> B -> ... -> B)
	// can produce a valid polygon while the dangling tail remains as leftover pending trail.
	areaSqm, remainingLinesWKT, capturedPolyWKT, err = s.polygonizeTrail(ctx, fullTrailWKT)
	if err != nil {
		log.Printf("CONQUEST_POLYGONIZE_FALLBACK: user_id=%s error=%v", userID, err)
		remainingLinesWKT = fullTrailWKT
		areaSqm = 0
		capturedPolyWKT = ""
	}

	// 4. Update Pending Trails with leftovers
	pendingTrailWKT, err := s.normalizePendingTrailWKT(ctx, remainingLinesWKT)
	if err != nil {
		return result, fmt.Errorf("failed to normalize pending trail: %w", err)
	}

	if pendingTrailWKT != "" {
		var pendingExpiresAt time.Time
		_, err = tx.Exec(ctx, `
			INSERT INTO pending_trails (user_id, geom, start_point, end_point, expires_at)
			VALUES (
				$1, 
				ST_GeomFromText($2, 4326), 
				ST_StartPoint(ST_GeomFromText($2, 4326)), 
				ST_EndPoint(ST_GeomFromText($2, 4326)),
				NOW() + INTERVAL '72 hours'
			)
		`, userID, pendingTrailWKT)
		if err != nil {
			return result, fmt.Errorf("failed to save pending trail: %w", err)
		}
		pendingExpiresAt = time.Now().UTC().Add(time.Duration(pendingTrailContinuationWindowHours) * time.Hour)
		result.PendingTrailActive = true
		result.PendingTrailExpiresAt = &pendingExpiresAt
	}

	// 5. If area > minConquestAreaSqm, PROCESS CONQUEST (Clip others, then merge for self)
	if areaSqm >= minConquestAreaSqm && capturedPolyWKT != "" {
		minRetainedFragmentAreaSqm := math.Max(
			minRetainedTerritoryFragmentSqm,
			areaSqm*minRetainedTerritoryFragmentRatio,
		)

		// A. COOKIE CUTTER: Subtract this area from ALL OTHER agents
		rows, err := tx.Query(ctx, `
			SELECT user_id, ST_AsText(merged_boundary)
			FROM user_territories
			WHERE user_id != $1
			  AND sector_id = 'DEFAULT'
			  AND ST_Intersects(merged_boundary, ST_GeomFromText($2, 4326))
		`, userID, capturedPolyWKT)
		if err != nil {
			return result, fmt.Errorf("failed to fetch rival territories for clipping: %w", err)
		}
		defer rows.Close()

		clippedRows := int64(0)
		for rows.Next() {
			var rivalUserID string
			var rivalBoundaryWKT string
			if err := rows.Scan(&rivalUserID, &rivalBoundaryWKT); err != nil {
				return result, fmt.Errorf("failed to scan rival territory: %w", err)
			}

			prunedBoundaryWKT, prunedAreaSqm, err := s.prunePolygonFragments(
				ctx,
				"ST_Difference(ST_GeomFromText($1, 4326), ST_GeomFromText($2, 4326))",
				[]any{rivalBoundaryWKT, capturedPolyWKT},
				minRetainedFragmentAreaSqm,
			)
			if err != nil {
				return result, fmt.Errorf("failed to prune clipped rival territory: %w", err)
			}

			if prunedBoundaryWKT == "" || prunedAreaSqm <= 0 {
				if _, err = tx.Exec(ctx, `
					DELETE FROM user_territories
					WHERE user_id = $1 AND sector_id = 'DEFAULT'
				`, rivalUserID); err != nil {
					return result, fmt.Errorf("failed to delete emptied rival territory: %w", err)
				}
				clippedRows++
				continue
			}

			if _, err = tx.Exec(ctx, `
				UPDATE user_territories
				SET merged_boundary = ST_Multi(ST_GeomFromText($2, 4326)),
				    total_area_sqm = $3
				WHERE user_id = $1 AND sector_id = 'DEFAULT'
			`, rivalUserID, prunedBoundaryWKT, prunedAreaSqm); err != nil {
				return result, fmt.Errorf("failed to update pruned rival territory: %w", err)
			}
			clippedRows++
		}
		if err := rows.Err(); err != nil {
			return result, fmt.Errorf("failed while iterating rival territories: %w", err)
		}
		log.Printf(
			"CONQUEST_COOKIE_CUTTER: user_id=%s clipped_rows=%d captured_area_sqm=%.2f",
			userID,
			clippedRows,
			areaSqm,
		)

		// B. UPDATE SELF: Merge the new area into current territory
		var guildIDVal interface{}
		if guildID == "" {
			guildIDVal = nil
		} else {
			guildIDVal = guildID
		}
		var existingBoundaryWKT string
		err = tx.QueryRow(ctx, `
			SELECT ST_AsText(merged_boundary)
			FROM user_territories
			WHERE user_id = $1 AND sector_id = 'DEFAULT'
		`, userID).Scan(&existingBoundaryWKT)
		if err != nil && err != pgx.ErrNoRows {
			return result, fmt.Errorf("failed to fetch existing territory: %w", err)
		}

		var selfBoundaryWKT string
		var selfAreaSqm float64
		if err == pgx.ErrNoRows {
			selfBoundaryWKT, selfAreaSqm, err = s.prunePolygonFragments(
				ctx,
				"ST_GeomFromText($1, 4326)",
				[]any{capturedPolyWKT},
				minRetainedFragmentAreaSqm,
			)
		} else {
			selfBoundaryWKT, selfAreaSqm, err = s.prunePolygonFragments(
				ctx,
				"ST_UnaryUnion(ST_Collect(ST_GeomFromText($1, 4326), ST_GeomFromText($2, 4326)))",
				[]any{existingBoundaryWKT, capturedPolyWKT},
				minRetainedFragmentAreaSqm,
			)
		}
		if err != nil {
			return result, fmt.Errorf("failed to prune merged player territory: %w", err)
		}
		if selfBoundaryWKT == "" || selfAreaSqm <= 0 {
			return result, fmt.Errorf("merged player territory became empty unexpectedly")
		}

		_, err = tx.Exec(ctx, `
			INSERT INTO user_territories (user_id, guild_id, sector_id, merged_boundary, total_area_sqm)
			VALUES ($1, $2, 'DEFAULT', ST_Multi(ST_GeomFromText($3, 4326)), $4)
			ON CONFLICT (user_id, sector_id) DO UPDATE SET
				merged_boundary = ST_Multi(ST_GeomFromText($3, 4326)),
				total_area_sqm = $4,
				last_expanded_at = NOW(),
				guild_id = EXCLUDED.guild_id
		`, userID, guildIDVal, selfBoundaryWKT, selfAreaSqm)
		if err != nil {
			return result, fmt.Errorf("failed to update territories: %w", err)
		}

		result.CapturedAreaSqm = areaSqm
		result.RunStatus = "captured"
		result.ClaimReason = "territory_captured"
	} else if result.PendingTrailActive {
		result.RunStatus = "pending"
		result.ClaimReason = "pending_trail_saved"
	} else if areaSqm > 0 && areaSqm < minConquestAreaSqm {
		result.RunStatus = "finished"
		result.ClaimReason = "loop_area_below_threshold"
	}

	if err := tx.Commit(ctx); err != nil {
		return result, err
	}

	log.Printf(
		"CONQUEST_RESULT: user_id=%s run_status=%s area_sqm=%.2f pending_trail=%t reason=%s",
		userID,
		result.RunStatus,
		result.CapturedAreaSqm,
		result.PendingTrailActive,
		result.ClaimReason,
	)

	return result, nil
}

func (s *SpatialEngine) pointsToWKT(points []Point) string {
	res := "LINESTRING("
	for i, p := range points {
		res += fmt.Sprintf("%f %f", p.Lng, p.Lat)
		if i < len(points)-1 {
			res += ", "
		}
	}
	res += ")"
	return res
}

func (s *SpatialEngine) shouldForceCloseLoop(points []Point) bool {
	if len(points) < 3 {
		return false
	}

	first := points[0]
	last := points[len(points)-1]
	if first.Lat == last.Lat && first.Lng == last.Lng {
		return false
	}

	if s.haversineMeters(first, last) > loopClosureToleranceMeters {
		return false
	}

	maxDisplacement := 0.0
	for _, p := range points {
		displacement := s.haversineMeters(first, p)
		if displacement > maxDisplacement {
			maxDisplacement = displacement
		}
	}

	return maxDisplacement > minLoopDisplacementMeters
}

func (s *SpatialEngine) haversineMeters(p1, p2 Point) float64 {
	const earthRadius = 6371000.0

	lat1 := p1.Lat * math.Pi / 180.0
	lng1 := p1.Lng * math.Pi / 180.0
	lat2 := p2.Lat * math.Pi / 180.0
	lng2 := p2.Lng * math.Pi / 180.0

	dLat := lat2 - lat1
	dLng := lng2 - lng1

	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1)*math.Cos(lat2)*math.Sin(dLng/2)*math.Sin(dLng/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))

	return earthRadius * c
}

func (s *SpatialEngine) polygonizeTrail(ctx context.Context, fullTrailWKT string) (float64, string, string, error) {
	var areaSqm float64
	var remainingLinesWKT string
	var capturedPolyWKT string

	err := s.db.QueryRow(ctx, `
		WITH raw_geom AS (
			SELECT ST_SnapToGrid(ST_GeomFromText($1, 4326), 0.00001) as g
		),
		noded AS (
			SELECT ST_Node(g) as g FROM raw_geom
		),
		polygon_parts AS (
			SELECT (ST_Dump(ST_Polygonize(g))).geom AS geom
			FROM noded
		),
		polys AS (
			SELECT ST_CollectionExtract(ST_UnaryUnion(ST_Collect(geom)), 3) as p
			FROM polygon_parts
		),
		captured_wkt AS (
			SELECT ST_AsText(p) as wkt FROM polys WHERE p IS NOT NULL AND NOT ST_IsEmpty(p)
		),
		area_calc AS (
			SELECT ST_Area(p::geography) as area FROM polys WHERE p IS NOT NULL AND NOT ST_IsEmpty(p)
		),
		leftovers AS (
			SELECT ST_AsText(
				ST_LineMerge(
					ST_CollectionExtract(
						ST_Difference(
							ST_GeomFromText($1, 4326),
							ST_Boundary((SELECT p FROM polys))
						),
						2
					)
				)
			) as residue
			FROM polys
		)
		SELECT
			COALESCE((SELECT area FROM area_calc), 0),
			COALESCE((SELECT residue FROM leftovers), $1),
			COALESCE((SELECT wkt FROM captured_wkt), '')
	`, fullTrailWKT).Scan(&areaSqm, &remainingLinesWKT, &capturedPolyWKT)
	if err != nil {
		return 0, "", "", err
	}

	return areaSqm, remainingLinesWKT, capturedPolyWKT, nil
}

func (s *SpatialEngine) normalizePendingTrailWKT(ctx context.Context, wkt string) (string, error) {
	if wkt == "" || wkt == "GEOMETRYCOLLECTION EMPTY" || wkt == "LINESTRING EMPTY" || wkt == "MULTILINESTRING EMPTY" {
		return "", nil
	}

	var normalized string
	err := s.db.QueryRow(ctx, `
		WITH input AS (
			SELECT ST_GeomFromText($1, 4326) AS g
		),
		lines AS (
			SELECT
				(ST_Dump(ST_CollectionExtract(g, 2))).geom AS geom
			FROM input
		),
		candidates AS (
			SELECT
				CASE
					WHEN GeometryType(geom) = 'LINESTRING' THEN geom
					ELSE ST_LineMerge(geom)
				END AS geom
			FROM lines
		),
		valid_lines AS (
			SELECT geom
			FROM candidates
			WHERE geom IS NOT NULL
			  AND NOT ST_IsEmpty(geom)
			  AND GeometryType(geom) = 'LINESTRING'
			  AND ST_NPoints(geom) >= 2
			ORDER BY ST_Length(geom::geography) DESC
			LIMIT 1
		)
		SELECT COALESCE((SELECT ST_AsText(geom) FROM valid_lines), '')
	`, wkt).Scan(&normalized)
	if err != nil {
		return "", err
	}

	return normalized, nil
}

func (s *SpatialEngine) prunePolygonFragments(
	ctx context.Context,
	geometryExpr string,
	args []any,
	minAreaSqm float64,
) (string, float64, error) {
	query := fmt.Sprintf(`
		WITH raw_geom AS (
			SELECT ST_CollectionExtract(ST_MakeValid(%s), 3) AS geom
		),
		fragments AS (
			SELECT (ST_Dump(geom)).geom AS geom
			FROM raw_geom
			WHERE geom IS NOT NULL AND NOT ST_IsEmpty(geom)
		),
		retained AS (
			SELECT geom
			FROM fragments
			WHERE ST_Area(geom::geography) >= $%d
		),
		merged AS (
			SELECT ST_UnaryUnion(ST_Collect(geom)) AS geom
			FROM retained
		)
		SELECT
			COALESCE((SELECT ST_AsText(ST_CollectionExtract(ST_MakeValid(geom), 3)) FROM merged), ''),
			COALESCE((SELECT ST_Area(geom::geography) FROM merged), 0)
	`, geometryExpr, len(args)+1)

	queryArgs := append(append([]any{}, args...), minAreaSqm)
	var wkt string
	var areaSqm float64
	if err := s.db.QueryRow(ctx, query, queryArgs...).Scan(&wkt, &areaSqm); err != nil {
		return "", 0, err
	}
	if wkt == "MULTIPOLYGON EMPTY" || wkt == "POLYGON EMPTY" {
		return "", 0, nil
	}
	return wkt, areaSqm, nil
}
