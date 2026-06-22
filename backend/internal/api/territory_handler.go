package api

import (
	"net/http"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/labstack/echo/v4"
)

type TerritoryHandler struct {
	db *pgxpool.Pool
}

func NewTerritoryHandler(db *pgxpool.Pool) *TerritoryHandler {
	return &TerritoryHandler{db: db}
}

type UserTerritory struct {
	UserID   string  `json:"user_id"`
	SectorID string  `json:"sector_id"`
	GeoJSON  string  `json:"boundary_geojson"`
	TotalAreaSqm float64 `json:"total_area_sqm"`
}

func (h *TerritoryHandler) GetUserTerritories(c echo.Context) error {
	userID := c.Param("userId")
	if userID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "user id is required"})
	}

	ctx := c.Request().Context()
	query := `
		SELECT 
			ut.user_id, 
			ut.sector_id, 
			ST_AsGeoJSON(ut.merged_boundary) as boundary, 
			ut.total_area_sqm,
			COALESCE(p.territory_color, '#0ea5e9') as color
		FROM user_territories ut
		JOIN profiles p ON ut.user_id = p.id
		WHERE ut.user_id = $1
	`

	rows, err := h.db.Query(ctx, query, userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to fetch territories"})
	}
	defer rows.Close()

	type ExtendedTerritory struct {
		UserTerritory
		Color string `json:"color"`
	}

	var territories []ExtendedTerritory
	for rows.Next() {
		var et ExtendedTerritory
		if err := rows.Scan(&et.UserID, &et.SectorID, &et.GeoJSON, &et.TotalAreaSqm, &et.Color); err != nil {
			continue
		}
		territories = append(territories, et)
	}

	if territories == nil {
		territories = []ExtendedTerritory{}
	}

	return c.JSON(http.StatusOK, territories)
}

func (h *TerritoryHandler) GetAllTerritories(c echo.Context) error {
	ctx := c.Request().Context()

	// Viewport bbox filtering — only load territories visible in the map viewport.
	// Query params: lon_min, lat_min, lon_max, lat_max (WGS84 degrees)
	// If not provided, falls back to fetching all (for small datasets / initial load).
	lonMin := c.QueryParam("lon_min")
	latMin := c.QueryParam("lat_min")
	lonMax := c.QueryParam("lon_max")
	latMax := c.QueryParam("lat_max")

	var rows pgx.Rows
	var err error

	type ExtendedTerritory struct {
		UserTerritory
		Color string `json:"color"`
	}

	if lonMin != "" && latMin != "" && lonMax != "" && latMax != "" {
		// Viewport-filtered query using ST_MakeEnvelope for bbox intersection
		rows, err = h.db.Query(ctx, `
			SELECT 
				ut.user_id, 
				ut.sector_id, 
				ST_AsGeoJSON(ut.merged_boundary) as boundary, 
				ut.total_area_sqm,
				COALESCE(p.territory_color, '#0ea5e9') as color
			FROM user_territories ut
			JOIN profiles p ON ut.user_id = p.id
			WHERE ST_Intersects(
				ut.merged_boundary,
				ST_MakeEnvelope($1::float8, $2::float8, $3::float8, $4::float8, 4326)
			)
		`, lonMin, latMin, lonMax, latMax)
	} else {
		// No bbox provided — fetch all (acceptable for small/local datasets)
		rows, err = h.db.Query(ctx, `
			SELECT 
				ut.user_id, 
				ut.sector_id, 
				ST_AsGeoJSON(ut.merged_boundary) as boundary, 
				ut.total_area_sqm,
				COALESCE(p.territory_color, '#0ea5e9') as color
			FROM user_territories ut
			JOIN profiles p ON ut.user_id = p.id
		`)
	}

	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to fetch all territories"})
	}
	defer rows.Close()

	var territories []ExtendedTerritory
	for rows.Next() {
		var et ExtendedTerritory
		if err := rows.Scan(&et.UserID, &et.SectorID, &et.GeoJSON, &et.TotalAreaSqm, &et.Color); err != nil {
			continue
		}
		territories = append(territories, et)
	}

	if territories == nil {
		territories = []ExtendedTerritory{}
	}

	return c.JSON(http.StatusOK, territories)
}
