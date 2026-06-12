package api

import (
	"context"
	"net/http"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/labstack/echo/v4"
)

type GraffitiHandler struct {
	db *pgxpool.Pool
}

func NewGraffitiHandler(db *pgxpool.Pool) *GraffitiHandler {
	return &GraffitiHandler{db: db}
}

type Graffiti struct {
	ID          string      `json:"id"`
	UserID      string      `json:"user_id"`
	DisplayName string      `json:"display_name"`
	Color       string      `json:"color"`
	Data        interface{} `json:"data"`
	CreatedAt   string      `json:"created_at"`
}

type PostGraffitiRequest struct {
	UserID string      `json:"user_id"`
	Data   interface{} `json:"data"`
}

func (h *GraffitiHandler) PostGraffiti(c echo.Context) error {
	req := new(PostGraffitiRequest)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}

	query := "INSERT INTO graffiti (user_id, data) VALUES ($1, $2)"
	_, err := h.db.Exec(context.Background(), query, req.UserID, req.Data)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to post graffiti"})
	}

	return c.JSON(http.StatusCreated, map[string]string{"message": "graffiti posted"})
}

func (h *GraffitiHandler) GetRecentGraffiti(c echo.Context) error {
	query := `
		SELECT 
			g.id, 
			g.user_id, 
			p.display_name, 
			p.territory_color, 
			g.data, 
			g.created_at 
		FROM graffiti g
		JOIN profiles p ON g.user_id = p.id
		ORDER BY g.created_at DESC
		LIMIT 20
	`
	rows, err := h.db.Query(context.Background(), query)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to fetch graffiti"})
	}
	defer rows.Close()

	var results []Graffiti
	for rows.Next() {
		var g Graffiti
		if err := rows.Scan(&g.ID, &g.UserID, &g.DisplayName, &g.Color, &g.Data, &g.CreatedAt); err != nil {
			continue
		}
		results = append(results, g)
	}

	if results == nil {
		results = []Graffiti{}
	}

	return c.JSON(http.StatusOK, results)
}
