package api

import (
	"context"
	"net/http"
	"strconv"

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

	ctx := context.Background()

	// 1. Fetch basic profile info
	queryProfile := `
		SELECT 
			id, username, display_name, avatar_url, level, xp, guild_id, territory_color, bio, public_profile, ghost_mode, signature_data
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
		Bio            *string `json:"bio"`
		PublicProfile  bool    `json:"public_profile"`
		GhostMode      bool    `json:"ghost_mode"`
		SignatureData  *string `json:"signature_data"`
		TotalDistance  float64 `json:"total_distance_km"`
		TotalSectors   int     `json:"total_sectors_held"`
		GlobalRank     int     `json:"global_rank"`
	}

	err := h.db.QueryRow(ctx, queryProfile, userID).Scan(
		&p.ID, &p.Username, &p.DisplayName, &p.AvatarURL, &p.Level, &p.XP, &p.GuildID, &p.TerritoryColor, &p.Bio, &p.PublicProfile, &p.GhostMode, &p.SignatureData,
	)

	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "profile not found"})
	}

	// 2. Aggregate Stats: Total Distance from runs
	err = h.db.QueryRow(ctx, "SELECT COALESCE(SUM(distance_km), 0) FROM runs WHERE user_id = $1", userID).Scan(&p.TotalDistance)
	if err != nil {
		p.TotalDistance = 0
	}

	// 3. Aggregate Stats: Total Sectors from user_territories
	// Counting rows in user_territories for now (each row is a district conquest)
	// Or we could count total area
	err = h.db.QueryRow(ctx, "SELECT COUNT(*) FROM user_territories WHERE user_id = $1", userID).Scan(&p.TotalSectors)
	if err != nil {
		p.TotalSectors = 0
	}

	// 4. Fetch Rank from cache
	err = h.db.QueryRow(ctx, "SELECT COALESCE(rank, 0) FROM leaderboard_cache WHERE user_id = $1 AND sector_id = 'KEC-GLOBAL'", userID).Scan(&p.GlobalRank)
	if err != nil {
		p.GlobalRank = 0
	}

	return c.JSON(http.StatusOK, p)
}

type UpdateProfileRequest struct {
	DisplayName   *string `json:"display_name"`
	Bio           *string `json:"bio"`
	PublicProfile *bool   `json:"public_profile"`
	GhostMode     *bool   `json:"ghost_mode"`
	SignatureData *string `json:"signature_data"`
}

func (h *ProfileHandler) UpdateProfile(c echo.Context) error {
	userID := c.Param("id")
	if userID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "user id is required"})
	}

	req := new(UpdateProfileRequest)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request body"})
	}

	ctx := context.Background()

	// Build update query dynamically
	query := "UPDATE profiles SET updated_at = NOW()"
	var args []interface{}
	argCount := 1

	if req.DisplayName != nil {
		query += ", display_name = $" + strconv.Itoa(argCount+1)
		args = append(args, *req.DisplayName)
		argCount++
	}
	if req.Bio != nil {
		query += ", bio = $" + strconv.Itoa(argCount+1)
		args = append(args, *req.Bio)
		argCount++
	}
	if req.PublicProfile != nil {
		query += ", public_profile = $" + strconv.Itoa(argCount+1)
		args = append(args, *req.PublicProfile)
		argCount++
	}
	if req.GhostMode != nil {
		query += ", ghost_mode = $" + strconv.Itoa(argCount+1)
		args = append(args, *req.GhostMode)
		argCount++
	}
	if req.SignatureData != nil {
		query += ", signature_data = $" + strconv.Itoa(argCount+1)
		args = append(args, *req.SignatureData)
		argCount++
	}

	query += " WHERE id = $1"
	args = append([]interface{}{userID}, args...)

	_, err := h.db.Exec(ctx, query, args...)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to update profile"})
	}

	return c.JSON(http.StatusOK, map[string]string{"message": "profile updated successfully"})
}
