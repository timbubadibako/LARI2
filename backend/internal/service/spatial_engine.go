package service

import (
	"context"
	"fmt"
	"math"

	"github.com/jackc/pgx/v5/pgxpool"
)

type SpatialEngine struct {
	db *pgxpool.Pool
}

// minConquestAreaSqm is the minimum enclosed area (in square meters) required
// to register a territory capture. This prevents accidental micro-loops from
// GPS jitter near the start point from claiming territory.
// 50 m² ≈ roughly the size of a large room — intentional loops will be much larger.
const minConquestAreaSqm = 50.0
const loopClosureToleranceMeters = 25.0
const minLoopDisplacementMeters = 30.0

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
func (s *SpatialEngine) ProcessConquest(ctx context.Context, userID string, guildID string, points []Point) (float64, error) {
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
		return 0, err
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
		// Found a connection! Merge them.
		err = tx.QueryRow(ctx, `
			SELECT ST_AsText(ST_LineMerge(ST_Union(ST_GeomFromText($1, 4326), ST_GeomFromText($2, 4326))))
		`, pendingGeomWKT, wktLine).Scan(&fullTrailWKT)
		if err != nil {
			return 0, fmt.Errorf("failed to merge lines: %w", err)
		}
		// Delete the old segment as it will be updated or turned into a polygon
		_, _ = tx.Exec(ctx, "DELETE FROM pending_trails WHERE id = $1", pendingID)
	} else {
		// No connection found. 
		// "Chain or Crash": Clear any existing pending trails for this user (they've started a new chain elsewhere)
		_, _ = tx.Exec(ctx, "DELETE FROM pending_trails WHERE user_id = $1", userID)
		fullTrailWKT = wktLine
	}

	// 3. Detect Loops via ST_BuildArea
	var areaSqm float64
	var remainingLinesWKT string
	var capturedPolyWKT string

	// FIX: Use ST_SnapToGrid to close small gaps and ST_BuildArea to fill all enclosed spaces.
	err = tx.QueryRow(ctx, `
		WITH raw_geom AS (SELECT ST_SnapToGrid(ST_GeomFromText($1, 4326), 0.00001) as g),
		     merged_poly AS (SELECT ST_BuildArea(g) as p FROM raw_geom),
		     captured_wkt AS (SELECT ST_AsText(p) as wkt FROM merged_poly WHERE p IS NOT NULL),
		     area_calc AS (SELECT ST_Area(p::geography) as area FROM merged_poly WHERE p IS NOT NULL),
		     leftovers AS (SELECT ST_AsText(ST_Difference(ST_GeomFromText($1, 4326), (SELECT p FROM merged_poly))) as residue)
		SELECT 
			COALESCE((SELECT area FROM area_calc), 0), 
			COALESCE((SELECT residue FROM leftovers), $1),
			COALESCE((SELECT wkt FROM captured_wkt), '')
	`, fullTrailWKT).Scan(&areaSqm, &remainingLinesWKT, &capturedPolyWKT)

	if err != nil {
		// If polygonization fails or no loops, just keep the full trail
		remainingLinesWKT = fullTrailWKT
		areaSqm = 0
		capturedPolyWKT = ""
	}

	// 4. Update Pending Trails with leftovers
	if remainingLinesWKT != "" && remainingLinesWKT != "GEOMETRYCOLLECTION EMPTY" {
		_, err = tx.Exec(ctx, `
			INSERT INTO pending_trails (user_id, geom, start_point, end_point)
			VALUES (
				$1, 
				ST_GeomFromText($2, 4326), 
				ST_StartPoint(ST_GeomFromText($2, 4326)), 
				ST_EndPoint(ST_GeomFromText($2, 4326))
			)
		`, userID, remainingLinesWKT)
		if err != nil {
			return 0, fmt.Errorf("failed to save pending trail: %w", err)
		}
	}

	// 5. If area > minConquestAreaSqm, PROCESS CONQUEST (Clip others, then merge for self)
	if areaSqm >= minConquestAreaSqm && capturedPolyWKT != "" {
		// A. COOKIE CUTTER: Subtract this area from ALL OTHER agents
		_, err = tx.Exec(ctx, `
			UPDATE user_territories 
			SET 
				merged_boundary = ST_Multi(ST_Difference(merged_boundary, ST_GeomFromText($2, 4326))),
				total_area_sqm = ST_Area(ST_Difference(merged_boundary, ST_GeomFromText($2, 4326))::geography)
			WHERE user_id != $1 
			  AND sector_id = 'DEFAULT' 
			  AND ST_Intersects(merged_boundary, ST_GeomFromText($2, 4326))
		`, userID, capturedPolyWKT)
		if err != nil {
			return 0, fmt.Errorf("failed to clip rival territories: %w", err)
		}

		// B. UPDATE SELF: Merge the new area into current territory
		var guildIDVal interface{}
		if guildID == "" {
			guildIDVal = nil
		} else {
			guildIDVal = guildID
		}

		_, err = tx.Exec(ctx, `
			INSERT INTO user_territories (user_id, guild_id, sector_id, merged_boundary, total_area_sqm)
			VALUES (
				$1, 
				$2, 
				'DEFAULT', 
				ST_Multi(ST_GeomFromText($3, 4326)), 
				$4
			)
			ON CONFLICT (user_id, sector_id) DO UPDATE SET
				merged_boundary = ST_Multi(ST_Union(user_territories.merged_boundary, EXCLUDED.merged_boundary)),
				total_area_sqm = ST_Area(ST_Union(user_territories.merged_boundary, EXCLUDED.merged_boundary)::geography),
				last_expanded_at = NOW(),
				guild_id = EXCLUDED.guild_id
		`, userID, guildIDVal, capturedPolyWKT, areaSqm)
		if err != nil {
			return 0, fmt.Errorf("failed to update territories: %w", err)
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return 0, err
	}

	return areaSqm, nil
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
