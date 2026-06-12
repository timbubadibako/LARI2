package api

import (
	"context"
	"net/http"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/labstack/echo/v4"
)

type GuildHandler struct {
	db *pgxpool.Pool
}

func NewGuildHandler(db *pgxpool.Pool) *GuildHandler {
	return &GuildHandler{db: db}
}

type Guild struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	EmblemColor string `json:"emblem_color"`
}

type JoinGuildRequest struct {
	UserID  string `json:"user_id"`
	GuildID string `json:"guild_id"`
}

func (h *GuildHandler) GetFactionDominion(c echo.Context) error {
	query := `
		SELECT 
			g.id, 
			g.name, 
			g.emblem_color, 
			COALESCE(SUM(ut.total_area_sqm), 0) as total_area
		FROM guilds g
		LEFT JOIN profiles p ON g.id = p.guild_id
		LEFT JOIN user_territories ut ON p.id = ut.user_id
		GROUP BY g.id, g.name, g.emblem_color
		ORDER BY total_area DESC
	`
	rows, err := h.db.Query(context.Background(), query)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to fetch faction dominion"})
	}
	defer rows.Close()

	type DominionEntry struct {
		GuildID     string  `json:"guild_id"`
		Name        string  `json:"name"`
		EmblemColor string  `json:"emblem_color"`
		TotalArea   float64 `json:"total_area"`
		Percentage  float64 `json:"percentage"`
	}

	var entries []DominionEntry
	var grandTotal float64
	for rows.Next() {
		var e DominionEntry
		if err := rows.Scan(&e.GuildID, &e.Name, &e.EmblemColor, &e.TotalArea); err != nil {
			continue
		}
		grandTotal += e.TotalArea
		entries = append(entries, e)
	}

	if grandTotal > 0 {
		for i := range entries {
			entries[i].Percentage = (entries[i].TotalArea / grandTotal) * 100
		}
	}

	if entries == nil {
		entries = []DominionEntry{}
	}

	return c.JSON(http.StatusOK, entries)
}

func (h *GuildHandler) GetGuilds(c echo.Context) error {
	query := "SELECT id, name, emblem_color FROM guilds ORDER BY created_at ASC"
	rows, err := h.db.Query(context.Background(), query)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to fetch guilds"})
	}
	defer rows.Close()

	var guilds []Guild
	for rows.Next() {
		var g Guild
		if err := rows.Scan(&g.ID, &g.Name, &g.EmblemColor); err != nil {
			continue
		}
		guilds = append(guilds, g)
	}

	if guilds == nil {
		guilds = []Guild{}
	}

	return c.JSON(http.StatusOK, guilds)
}

func (h *GuildHandler) JoinGuild(c echo.Context) error {
	req := new(JoinGuildRequest)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}

	// First, fetch the guild's emblem color to update the user's territory color
	var emblemColor string
	err := h.db.QueryRow(context.Background(), "SELECT emblem_color FROM guilds WHERE id = $1", req.GuildID).Scan(&emblemColor)
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "guild not found"})
	}

	// Update the profile
	query := "UPDATE profiles SET guild_id = $1, territory_color = $2 WHERE id = $3"
	_, err = h.db.Exec(context.Background(), query, req.GuildID, emblemColor, req.UserID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to join guild"})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message":         "successfully joined guild",
		"territory_color": emblemColor,
	})
}

func (h *GuildHandler) LeaveGuild(c echo.Context) error {
	type LeaveRequest struct {
		UserID string `json:"user_id"`
	}
	req := new(LeaveRequest)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}

	// Reset guild_id and set territory_color to a default (e.g., #FFFFFF or a neutral color)
	query := "UPDATE profiles SET guild_id = NULL, territory_color = '#FFFFFF' WHERE id = $1"
	_, err := h.db.Exec(context.Background(), query, req.UserID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to leave guild"})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message": "successfully left guild",
	})
}
