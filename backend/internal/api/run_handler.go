package api

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/labstack/echo/v4"
	"lari-backend/internal/service"
)

type RunHandler struct {
	db      *pgxpool.Pool
	algo    *service.AlgorithmService
	spatial *service.SpatialEngine
	hub     *Hub
}

func NewRunHandler(db *pgxpool.Pool, hub *Hub) *RunHandler {
	return &RunHandler{
		db:      db,
		algo:    service.NewAlgorithmService(),
		spatial: service.NewSpatialEngine(db),
		hub:     hub,
	}
}

type SyncRunRequest struct {
	ID          string          `json:"id"`
	UserID      string          `json:"user_id"`
	GuildID     *string         `json:"guild_id"` // Nullable
	DistanceKm  float64         `json:"distance_km"`
	DurationSec int             `json:"duration_sec"`
	Points      []service.Point `json:"points"`
	Status      string          `json:"status"`
	CreatedAt   time.Time       `json:"created_at"`
}

type SyncRunResponse struct {
	Message             string                  `json:"message"`
	Summary             service.ActivitySummary `json:"summary"`
	NewlyCapturedAreaM2 float64                 `json:"newly_captured_area"`
}

// SyncRun godoc
// @Summary Sync running data and process conquest
// @Description Receives raw GPS points, calculates Strava-level metrics, and merges territories via Integrity Protocol.
// @Tags run
// @Accept  json
// @Produce  json
// @Param request body SyncRunRequest true "Running Data"
// @Success 200 {object} SyncRunResponse
// @Failure 400 {object} map[string]string
// @Router /sync/run [post]
func (h *RunHandler) SyncRun(c echo.Context) error {
	authUserID, _ := c.Get("user_id").(string)
	req := new(SyncRunRequest)
	if err := c.Bind(req); err != nil {
		log.Printf("SYNC_ERROR: Bind failed: %v", err)
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request format"})
	}

	guildIDStr := ""
	if req.GuildID != nil {
		guildIDStr = *req.GuildID
	}

	log.Printf(
		"SYNC_REQUEST: auth_user=%s payload_user=%s guild=%s points=%d payload_matches_claim=%t",
		authUserID,
		req.UserID,
		guildIDStr,
		len(req.Points),
		authUserID != "" && authUserID == req.UserID,
	)

	if len(req.Points) < 2 {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "insufficient points for sync"})
	}

	ctx := context.Background()

	// 1. Calculate Metrics (Algorithm Service)
	summary := h.algo.CalculateSummary(req.Points)

	// TODO(production): re-enable backend velocity anomaly check before release candidate.
	// 🔥 PRODUCTION SPEED LIMITER: Anti-Spoofing: Velocity Check (Max 40 km/h)
	// if summary.MovingDurationSec > 0 {
	// 	velocityKmh := (summary.TotalDistanceMeters / 1000.0) / (float64(summary.MovingDurationSec) / 3600.0)
	// 	if velocityKmh > 40.0 {
	// 		log.Printf("ANTI_SPOOFING: Velocity anomaly detected for user %s: %.2f km/h", req.UserID, velocityKmh)
	// 		return c.JSON(http.StatusBadRequest, map[string]string{"error": "velocity anomaly detected: speed exceeds human limits"})
	// 	}
	// }

	// 2. Process Conquest & Integrity Protocol (Spatial Engine)
	capturedArea, err := h.spatial.ProcessConquest(ctx, req.UserID, guildIDStr, req.Points)
	if err != nil {
		log.Printf("SYNC_ERROR: Conquest processing failed for user %s: %v", req.UserID, err)
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "conquest processing failed: " + err.Error()})
	}

	// Override status if conquest occurred
	runStatus := req.Status
	if capturedArea > 0 {
		runStatus = "captured"
	}

	// 3. Persist the Run record (Historical)
	var guildIDPtr interface{}
	if req.GuildID != nil && *req.GuildID != "" {
		guildIDPtr = *req.GuildID
	} else {
		guildIDPtr = nil
	}

	wktPath := h.pointsToWKT(req.Points)
	_, err = h.db.Exec(ctx, `
		INSERT INTO runs (id, user_id, guild_id, distance_km, duration_sec, calories, status, path_geometry, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, ST_GeomFromText($8, 4326), $9)
		ON CONFLICT (id) DO UPDATE SET
			distance_km = EXCLUDED.distance_km,
			duration_sec = EXCLUDED.duration_sec,
			status = EXCLUDED.status,
			path_geometry = EXCLUDED.path_geometry,
			guild_id = EXCLUDED.guild_id
	`, req.ID, req.UserID, guildIDPtr, summary.TotalDistanceMeters/1000.0, summary.MovingDurationSec, 0, runStatus, wktPath, req.CreatedAt)

	if err != nil {
		log.Printf("SYNC_ERROR: Persistence failed for run %s: %v", req.ID, err)
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to persist run data: " + err.Error()})
	}

	// Broadcast WS event for Real-time feed
	if h.hub != nil {
		wsEvent := map[string]interface{}{
			"type":    "NEW_GLOBAL_ACTIVITY",
			"user_id": req.UserID,
		}
		if msgBytes, err := json.Marshal(wsEvent); err == nil {
			h.hub.BroadcastMessage(msgBytes)
		}
	}

	return c.JSON(http.StatusOK, SyncRunResponse{
		Message:             "Grid synchronization complete.",
		Summary:             summary,
		NewlyCapturedAreaM2: capturedArea,
	})
}

// GetRuns godoc
// @Summary Get run history for a user
// @Description Fetches historical runs for a specific user ID.
// @Tags run
// @Produce  json
// @Param user_id query string true "User ID"
// @Success 200 {array} map[string]interface{}
// @Router /runs [get]
func (h *RunHandler) GetRuns(c echo.Context) error {
	userID := c.QueryParam("user_id")
	if userID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "user_id is required"})
	}

	rows, err := h.db.Query(context.Background(), `
		SELECT id, user_id, distance_km, duration_sec, status, ST_AsText(path_geometry), created_at 
		FROM runs 
		WHERE user_id = $1 
		ORDER BY created_at DESC
	`, userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	defer rows.Close()

	var runs []map[string]interface{}
	for rows.Next() {
		var id, uid, status, pathWKT string
		var distance float64
		var duration int
		var createdAt time.Time
		err := rows.Scan(&id, &uid, &distance, &duration, &status, &pathWKT, &createdAt)
		if err != nil {
			continue
		}
		runs = append(runs, map[string]interface{}{
			"id":            id,
			"user_id":       uid,
			"distance_km":   distance,
			"duration_sec":  duration,
			"status":        status,
			"path_geometry": pathWKT,
			"created_at":    createdAt,
		})
	}

	if runs == nil {
		runs = []map[string]interface{}{}
	}

	return c.JSON(http.StatusOK, runs)
}

// DeleteRuns godoc
// @Summary Clear run history
// @Description Deletes all run records for a specific user ID.
// @Tags run
// @Param user_id query string true "User ID"
// @Success 200 {object} map[string]string
// @Router /runs [delete]
func (h *RunHandler) DeleteRuns(c echo.Context) error {
	userID := c.QueryParam("user_id")
	if userID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "user_id is required"})
	}

	_, err := h.db.Exec(context.Background(), "DELETE FROM runs WHERE user_id = $1", userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}

	return c.JSON(http.StatusOK, map[string]string{"message": "mission archives erased"})
}

// GetGlobalRuns fetches the latest 3 captured runs for the social feed
func (h *RunHandler) GetGlobalRuns(c echo.Context) error {
	rows, err := h.db.Query(context.Background(), `
		SELECT 
			r.id, 
			r.user_id, 
			p.display_name, 
			p.territory_color,
			r.distance_km, 
			r.duration_sec, 
			r.status, 
			ST_AsText(r.path_geometry) as path_geometry,
			r.created_at 
		FROM runs r
		JOIN profiles p ON r.user_id = p.id
		WHERE r.status = 'captured'
		ORDER BY r.created_at DESC
		LIMIT 3
	`)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	defer rows.Close()

	var runs []map[string]interface{}
	for rows.Next() {
		var id, uid, displayName, color, status, pathWKT string
		var distance float64
		var duration int
		var createdAt time.Time
		err := rows.Scan(&id, &uid, &displayName, &color, &distance, &duration, &status, &pathWKT, &createdAt)
		if err != nil {
			continue
		}
		runs = append(runs, map[string]interface{}{
			"id":              id,
			"user_id":         uid,
			"display_name":    displayName,
			"territory_color": color,
			"distance_km":     distance,
			"duration_sec":    duration,
			"status":          status,
			"path_geometry":   pathWKT,
			"created_at":      createdAt,
		})
	}

	if runs == nil {
		runs = []map[string]interface{}{}
	}

	return c.JSON(http.StatusOK, runs)
}

func (h *RunHandler) pointsToWKT(points []service.Point) string {
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
