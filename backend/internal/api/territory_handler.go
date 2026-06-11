package api

import (
	"context"
	"net/http"

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
	UserID       string  `json:"user_id"`
	DistrictCode string  `json:"district_code"`
	GeoJSON      string  `json:"boundary_geojson"`
	TotalAreaSqm float64 `json:"total_area_sqm"`
}

func (h *TerritoryHandler) GetUserTerritories(c echo.Context) error {
	userID := c.Param("userId")
	if userID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "user id is required"})
	}

	query := `
		SELECT 
			user_id, 
			district_code, 
			ST_AsGeoJSON(merged_boundary) as boundary, 
			total_area_sqm 
		FROM user_territories 
		WHERE user_id = $1
	`

	rows, err := h.db.Query(context.Background(), query, userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to fetch territories"})
	}
	defer rows.Close()

	var territories []UserTerritory
	for rows.Next() {
		var ut UserTerritory
		if err := rows.Scan(&ut.UserID, &ut.DistrictCode, &ut.GeoJSON, &ut.TotalAreaSqm); err != nil {
			continue
		}
		territories = append(territories, ut)
	}

	if territories == nil {
		territories = []UserTerritory{}
	}

	return c.JSON(http.StatusOK, territories)
}

func (h *TerritoryHandler) GetAllTerritories(c echo.Context) error {
	query := `
		SELECT 
			ut.user_id, 
			ut.district_code, 
			ST_AsGeoJSON(ut.merged_boundary) as boundary, 
			ut.total_area_sqm,
			COALESCE(p.territory_color, '#0ea5e9') as color
		FROM user_territories ut
		JOIN profiles p ON ut.user_id = p.id
	`

	rows, err := h.db.Query(context.Background(), query)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to fetch all territories"})
	}
	defer rows.Close()

	type ExtendedTerritory struct {
		UserTerritory
		Color string `json:"color"`
	}

	var territories []ExtendedTerritory
	for rows.Next() {
		var et ExtendedTerritory
		if err := rows.Scan(&et.UserID, &et.DistrictCode, &et.GeoJSON, &et.TotalAreaSqm, &et.Color); err != nil {
			continue
		}
		territories = append(territories, et)
	}

	if territories == nil {
		territories = []ExtendedTerritory{}
	}

	return c.JSON(http.StatusOK, territories)
}
