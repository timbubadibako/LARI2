package api

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/labstack/echo/v4"
)

func TestSyncRunRejectsUserMismatch(t *testing.T) {
	e := echo.New()
	req := httptest.NewRequest(http.MethodPost, "/sync/run", bytes.NewBufferString(`{
		"id":"run-1",
		"user_id":"payload-user",
		"distance_km":1.2,
		"duration_sec":600,
		"points":[
			{"lat":-6.2,"lng":106.8,"timestamp":"2026-07-01T00:00:00Z","accuracy":5},
			{"lat":-6.21,"lng":106.81,"timestamp":"2026-07-01T00:10:00Z","accuracy":5}
		],
		"status":"finished",
		"created_at":"2026-07-01T00:00:00Z"
	}`))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.Set("user_id", "auth-user")

	handler := &RunHandler{}
	if err := handler.SyncRun(c); err != nil {
		t.Fatalf("SyncRun returned error: %v", err)
	}

	if rec.Code != http.StatusForbidden {
		t.Fatalf("expected status %d, got %d", http.StatusForbidden, rec.Code)
	}
}
