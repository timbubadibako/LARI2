package main

import (
	"context"
	"log"
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	echoSwagger "github.com/swaggo/echo-swagger"
	"lari-backend/internal/api"
	"lari-backend/internal/config"
	"lari-backend/internal/db"
	"lari-backend/internal/worker"
	_ "lari-backend/docs" // This will be the generated docs package
)

// @title LARI API
// @version 1.0
// @description High-performance territorial conquest API for LARI agents.
// @termsOfService http://swagger.io/terms/

// @contact.name API Support
// @contact.url http://www.swagger.io/support
// @contact.email support@swagger.io

// @license.name Apache 2.0
// @license.url http://www.apache.org/licenses/LICENSE-2.0.html

// @host localhost:8080
// @BasePath /
func main() {
	// Load configuration
	cfg := config.LoadConfig()

	// Initialize database
	dbPool, err := db.InitDB(cfg)
	if err != nil {
		log.Fatalf("Database initialization failed: %v", err)
	}
	defer dbPool.Close()

	// Initialize Hub
	wsHub := api.NewHub()
	go wsHub.Run()

	// Initialize Handlers
	authHandler := api.NewAuthHandler(dbPool)
	runHandler := api.NewRunHandler(dbPool, wsHub)
	leaderboardHandler := api.NewLeaderboardHandler(dbPool)
	guildHandler := api.NewGuildHandler(dbPool)
	profileHandler := api.NewProfileHandler(dbPool)
	territoryHandler := api.NewTerritoryHandler(dbPool)
	wsHandler := api.NewWebSocketHandler(wsHub)

	// Initialize Workers
	cleanupWorker := worker.NewCleanupWorker(dbPool)
	go cleanupWorker.Start(context.Background())

	// Initialize Echo
	e := echo.New()

	// Middleware
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())
	e.Use(middleware.CORS())

	// WebSocket Route
	e.GET("/ws", wsHandler.HandleWS)

	// Swagger Route
	e.GET("/swagger/*", echoSwagger.WrapHandler)

	// Routes
	e.GET("/health", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{
			"status": "up",
		})
	})

	// Auth Routes
	e.POST("/auth/register", authHandler.Register)
	e.POST("/auth/login", authHandler.Login)

	// Run Routes
	e.POST("/sync/run", runHandler.SyncRun)
	e.GET("/runs", runHandler.GetRuns)
	e.GET("/runs/global", runHandler.GetGlobalRuns)
	e.DELETE("/runs", runHandler.DeleteRuns)

	// Leaderboard Routes
	e.GET("/leaderboard/:district", leaderboardHandler.GetLeaderboard)
	e.POST("/leaderboard/:district/refresh", leaderboardHandler.RefreshLeaderboardCache)

	// Guild Routes
	e.GET("/guilds", guildHandler.GetGuilds)
	e.GET("/guilds/dominion", guildHandler.GetFactionDominion)
	e.POST("/guilds/join", guildHandler.JoinGuild)

	// Profile Routes
	e.GET("/profiles/:id", profileHandler.GetProfile)

	// Territory Routes
	e.GET("/territories", territoryHandler.GetAllTerritories)
	e.GET("/territories/:userId", territoryHandler.GetUserTerritories)

	// Start server
	log.Printf("Starting server on port %s", cfg.Port)
	if err := e.Start(":" + cfg.Port); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}
