package api

import (
	"context"
	"net/http"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/labstack/echo/v4"
)

type SeasonHandler struct {
	db *pgxpool.Pool
}

func NewSeasonHandler(db *pgxpool.Pool) *SeasonHandler {
	return &SeasonHandler{db: db}
}

// GetSeasons — GET /seasons
// Mengembalikan semua riwayat musim (Hall of Fame).
func (h *SeasonHandler) GetSeasons(c echo.Context) error {
	ctx := context.Background()

	rows, err := h.db.Query(ctx, `
		SELECT 
			sh.id,
			sh.season_id,
			sh.sector_id,
			sh.winner_user_id,
			sh.total_area_sqm,
			sh.created_at,
			p.display_name,
			p.username,
			p.territory_color,
			g.name as guild_name,
			g.emblem_color as guild_color
		FROM season_history sh
		LEFT JOIN profiles p ON sh.winner_user_id = p.id
		LEFT JOIN guilds g ON sh.guild_id = g.id
		ORDER BY sh.created_at DESC
		LIMIT 100
	`)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to fetch seasons"})
	}
	defer rows.Close()

	type SeasonEntry struct {
		ID             int     `json:"id"`
		SeasonID       string  `json:"season_id"`
		SectorID       string  `json:"sector_id"`
		WinnerUserID   *string `json:"winner_user_id"`
		TotalAreaSqm   float64 `json:"total_area_sqm"`
		CreatedAt      string  `json:"created_at"`
		WinnerName     *string `json:"winner_name"`
		WinnerUsername *string `json:"winner_username"`
		WinnerColor    *string `json:"winner_color"`
		GuildName      *string `json:"guild_name"`
		GuildColor     *string `json:"guild_color"`
	}

	seasons := []SeasonEntry{}
	for rows.Next() {
		var s SeasonEntry
		if err := rows.Scan(
			&s.ID, &s.SeasonID, &s.SectorID, &s.WinnerUserID,
			&s.TotalAreaSqm, &s.CreatedAt,
			&s.WinnerName, &s.WinnerUsername, &s.WinnerColor,
			&s.GuildName, &s.GuildColor,
		); err != nil {
			continue
		}
		seasons = append(seasons, s)
	}

	return c.JSON(http.StatusOK, seasons)
}

// GetUserBadges — GET /profiles/:id/badges
// Mengembalikan semua badge yang dimiliki oleh user tertentu.
func (h *SeasonHandler) GetUserBadges(c echo.Context) error {
	userID := c.Param("id")
	if userID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "user id is required"})
	}

	ctx := context.Background()

	rows, err := h.db.Query(ctx, `
		SELECT id, badge_id, badge_name, description, earned_at
		FROM user_badges
		WHERE user_id = $1
		ORDER BY earned_at DESC
	`, userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to fetch badges"})
	}
	defer rows.Close()

	type Badge struct {
		ID          int     `json:"id"`
		BadgeID     string  `json:"badge_id"`
		BadgeName   string  `json:"badge_name"`
		Description *string `json:"description"`
		EarnedAt    string  `json:"earned_at"`
	}

	badges := []Badge{}
	for rows.Next() {
		var b Badge
		if err := rows.Scan(&b.ID, &b.BadgeID, &b.BadgeName, &b.Description, &b.EarnedAt); err != nil {
			continue
		}
		badges = append(badges, b)
	}

	return c.JSON(http.StatusOK, badges)
}
