package service

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

type SpatialEngine struct {
	db *pgxpool.Pool
}

func NewSpatialEngine(db *pgxpool.Pool) *SpatialEngine {
	return &SpatialEngine{db: db}
}

// MapMatchPoints attempts to snap points to the nearest road using a map-matching algorithm.
// For now, it returns the original points but serves as the entry point for OSRM/GraphHopper integration.
func (s *SpatialEngine) MapMatchPoints(ctx context.Context, points []Point) ([]Point, error) {
	// TODO: Integrate with local OSRM instance:
	// 1. Send points to OSRM /match service
	// 2. Parse the snapped coordinates
	// 3. Return the 'cleaned' path

	// Tactical Note: Off-road points should NOT be snapped if the distance to road is > 20m.
	// This ensures agents running in parks/fields keep their original path.
	return points, nil
}

// ProcessConquest handles the "Elastic Trails" and Loop Detection logic.
func (s *SpatialEngine) ProcessConquest(ctx context.Context, userID string, points []Point) (float64, error) {
	// A. Snap to Road first to increase accuracy
	snappedPoints, err := s.MapMatchPoints(ctx, points)
	if err == nil {
		points = snappedPoints
	}

	// 1. Create a WKT LineString from points
	wktLine := s.pointsToWKT(points)
...

	// 2. Check for "Integrity Protocol" (Connection to pending trails)
	// We'll use a SQL transaction to handle atomic trail updates
	tx, err := s.db.Begin(ctx)
	if err != nil {
		return 0, err
	}
	defer tx.Rollback(ctx)

	// A. Find matching pending trail (within 10m of start point)
	var pendingID int
	var pendingGeomWKT string
	startPointWKT := fmt.Sprintf("POINT(%f %f)", points[0].Lng, points[0].Lat)

	err = tx.QueryRow(ctx, `
		SELECT id, ST_AsText(geom) 
		FROM pending_trails 
		WHERE user_id = $1 
		  AND expires_at > NOW()
		  AND (ST_DWithin(end_point, ST_GeomFromText($2, 4326), 0.0001) 
		       OR ST_DWithin(start_point, ST_GeomFromText($2, 4326), 0.0001))
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

	// 3. Detect Loops via ST_Polygonize
	var areaSqm float64
	var remainingLinesWKT string

	// This complex query:
	// - Takes the full trail
	// - Polygonizes it (finds closed loops)
	// - Calculates area of polygons
	// - Returns the 'leftover' lines that didn't form a loop
	err = tx.QueryRow(ctx, `
		WITH raw_geom AS (SELECT ST_GeomFromText($1, 4326) as g),
		     polygons AS (SELECT (ST_Dump(ST_Polygonize(g))).geom as poly FROM raw_geom GROUP BY g),
		     merged_poly AS (SELECT ST_Union(poly) as p FROM polygons),
		     area_calc AS (SELECT ST_Area(p::geography) as area FROM merged_poly),
		     leftovers AS (SELECT ST_AsText(ST_Difference(ST_GeomFromText($1, 4326), (SELECT p FROM merged_poly))) as residue)
		SELECT COALESCE((SELECT area FROM area_calc), 0), COALESCE((SELECT residue FROM leftovers), $1)
	`, fullTrailWKT).Scan(&areaSqm, &remainingLinesWKT)

	if err != nil {
		// If polygonization fails or no loops, just keep the full trail
		remainingLinesWKT = fullTrailWKT
		areaSqm = 0
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

	// 5. If area > 0, update user_territories (Mastered Domain)
	if areaSqm > 0 {
		// Note: district_code detection logic should be here (omitted for brevity, defaulting to 'KEC-01')
		_, err = tx.Exec(ctx, `
			INSERT INTO user_territories (user_id, district_code, merged_boundary, total_area_sqm)
			VALUES ($1, 'DEFAULT', (SELECT ST_Multi(ST_Union(poly)) FROM (SELECT (ST_Dump(ST_Polygonize(ST_GeomFromText($2, 4326)))).geom as poly) as t), $3)
			ON CONFLICT (user_id, district_code) DO UPDATE SET
				merged_boundary = ST_Multi(ST_Union(user_territories.merged_boundary, EXCLUDED.merged_boundary)),
				total_area_sqm = user_territories.total_area_sqm + EXCLUDED.total_area_sqm,
				last_expanded_at = NOW()
		`, userID, fullTrailWKT, areaSqm)
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
