package api

import (
	"context"
	"net/http"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/labstack/echo/v4"
)

type ProfileHandler struct {
	db *pgxpool.Pool
}

func NewProfileHandler(db *pgxpool.Pool) *ProfileHandler {
	return &ProfileHandler{db: db}
}

func (h *ProfileHandler) GetProfile(c echo.Context) error {
	userID := c.Param("id")
	if userID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "user id is required"})
	}

	query := `
		SELECT 
			id, username, display_name, avatar_url, level, xp, guild_id, territory_color 
		FROM profiles 
		WHERE id = $1
	`

	var p struct {
		ID             string  `json:"id"`
		Username       *string `json:"username"`
		DisplayName    *string `json:"display_name"`
		AvatarURL      *string `json:"avatar_url"`
		Level          int     `json:"level"`
		XP             int     `json:"xp"`
		GuildID        *string `json:"guild_id"`
		TerritoryColor *string `json:"territory_color"`
	}

	err := h.db.QueryRow(context.Background(), query, userID).Scan(
		&p.ID, &p.Username, &p.DisplayName, &p.AvatarURL, &p.Level, &p.XP, &p.GuildID, &p.TerritoryColor,
	)

	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "profile not found"})
	}

	return c.JSON(http.StatusOK, p)
}
