package api

import (
	"context"
	"net/http"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/labstack/echo/v4"
)

type LeaderboardHandler struct {
	db *pgxpool.Pool
}

func NewLeaderboardHandler(db *pgxpool.Pool) *LeaderboardHandler {
	return &LeaderboardHandler{db: db}
}

type LeaderboardEntry struct {
	Rank           int     `json:"rank"`
	UserID         string  `json:"user_id"`
	Username       string  `json:"username"`
	DisplayName    string  `json:"display_name"`
	AvatarURL      string  `json:"avatar_url"`
	TerritoryColor string  `json:"territory_color"`
	TotalAreaSqm   float64 `json:"total_area_sqm"`
}

func (h *LeaderboardHandler) GetLeaderboard(c echo.Context) error {
	districtCode := c.Param("district")
	if districtCode == "" {
		// Fallback to global if not provided
		districtCode = "KEC-GLOBAL"
	}

	// Query the leaderboard_cache joined with profiles
	query := `
		SELECT 
			lc.rank, 
			lc.user_id, 
			COALESCE(p.username, 'Unknown') as username, 
			COALESCE(p.display_name, 'Agent') as display_name, 
			COALESCE(p.avatar_url, '') as avatar_url, 
			COALESCE(p.territory_color, '#0ea5e9') as territory_color,
			lc.total_area_sqm
		FROM leaderboard_cache lc
		JOIN profiles p ON lc.user_id = p.id
		WHERE lc.sector_id = $1
		ORDER BY lc.rank ASC
		LIMIT 100
	`

	rows, err := h.db.Query(context.Background(), query, districtCode)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to fetch leaderboard"})
	}
	defer rows.Close()

	var entries []LeaderboardEntry
	for rows.Next() {
		var e LeaderboardEntry
		if err := rows.Scan(&e.Rank, &e.UserID, &e.Username, &e.DisplayName, &e.AvatarURL, &e.TerritoryColor, &e.TotalAreaSqm); err != nil {
			continue // Skip row on error
		}
		entries = append(entries, e)
	}

	// For now, if the cache is empty, we return an empty array
	if entries == nil {
		entries = []LeaderboardEntry{}
	}

	return c.JSON(http.StatusOK, entries)
}

// Temporary Cron-like endpoint to trigger cache refresh manually for testing
func (h *LeaderboardHandler) RefreshLeaderboardCache(c echo.Context) error {
	districtCode := c.Param("district")
	if districtCode == "" {
		districtCode = "KEC-GLOBAL"
	}

	query := `
		WITH ranked_territories AS (
			SELECT 
				user_id,
				total_area_sqm,
				RANK() OVER (ORDER BY total_area_sqm DESC) as rank
			FROM user_territories
			WHERE sector_id = $1
		)
		INSERT INTO leaderboard_cache (sector_id, user_id, rank, total_area_sqm, updated_at)
		SELECT $1, user_id, rank, total_area_sqm, NOW()
		FROM ranked_territories
		ON CONFLICT (sector_id, user_id) DO UPDATE SET
			rank = EXCLUDED.rank,
			total_area_sqm = EXCLUDED.total_area_sqm,
			updated_at = NOW();
	`

	_, err := h.db.Exec(context.Background(), query, districtCode)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}

	return c.JSON(http.StatusOK, map[string]string{"message": "leaderboard cache refreshed successfully"})
}
