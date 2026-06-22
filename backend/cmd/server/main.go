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
	_ "lari-backend/docs"
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
	authHandler := api.NewAuthHandler(dbPool, cfg.JWTSecret)
	runHandler := api.NewRunHandler(dbPool, wsHub)
	leaderboardHandler := api.NewLeaderboardHandler(dbPool)
	guildHandler := api.NewGuildHandler(dbPool)
	profileHandler := api.NewProfileHandler(dbPool)
	territoryHandler := api.NewTerritoryHandler(dbPool)
	graffitiHandler := api.NewGraffitiHandler(dbPool)
	wsHandler := api.NewWebSocketHandler(wsHub)
	friendsHandler := api.NewFriendsHandler(dbPool)
	seasonHandler := api.NewSeasonHandler(dbPool)

	// Initialize Workers
	cleanupWorker := worker.NewCleanupWorker(dbPool)
	go cleanupWorker.Start(context.Background())

	seasonWorker := worker.NewSeasonWorker(dbPool)
	go seasonWorker.Start(context.Background())

	// Initialize Echo
	e := echo.New()

	// Global Middleware
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())
	e.Use(middleware.CORS())

	// ── Public Routes (Tidak perlu login) ─────────────────────────────────────
	e.GET("/health", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{"status": "up"})
	})
	e.GET("/swagger/*", echoSwagger.WrapHandler)
	e.GET("/ws", wsHandler.HandleWS)

	// Auth — public
	e.POST("/auth/register", authHandler.Register)
	e.POST("/auth/login", authHandler.Login)

	// Public data (bisa dilihat tanpa login)
	e.GET("/territories", territoryHandler.GetAllTerritories)
	e.GET("/guilds", guildHandler.GetGuilds)
	e.GET("/guilds/dominion", guildHandler.GetGuildDominion)
	e.GET("/leaderboard/:district", leaderboardHandler.GetLeaderboard)
	e.GET("/seasons", seasonHandler.GetSeasons)
	e.GET("/graffiti", graffitiHandler.GetRecentGraffiti)

	// ── Protected Routes (Wajib JWT) ───────────────────────────────────────────
	protected := e.Group("")
	protected.Use(api.JWTMiddleware(cfg.JWTSecret))

	// Run Routes
	protected.POST("/sync/run", runHandler.SyncRun)
	protected.GET("/runs", runHandler.GetRuns)
	protected.GET("/runs/global", runHandler.GetGlobalRuns)
	protected.DELETE("/runs", runHandler.DeleteRuns)

	// Leaderboard refresh (admin action)
	protected.POST("/leaderboard/:district/refresh", leaderboardHandler.RefreshLeaderboardCache)

	// Guild Routes
	protected.POST("/guilds/join", guildHandler.JoinGuild)
	protected.POST("/guilds/leave", guildHandler.LeaveGuild)

	// Profile Routes
	protected.GET("/profiles/:id", profileHandler.GetProfile)
	protected.PUT("/profiles/:id", profileHandler.UpdateProfile)
	protected.GET("/profiles/:id/badges", seasonHandler.GetUserBadges)

	// Territory Routes (user-specific)
	protected.GET("/territories/:userId", territoryHandler.GetUserTerritories)

	// Graffiti
	protected.POST("/graffiti", graffitiHandler.PostGraffiti)

	// Friends Routes
	protected.POST("/friends/request", friendsHandler.SendFriendRequest)
	protected.PUT("/friends/:friendId/accept", friendsHandler.AcceptFriendRequest)
	protected.DELETE("/friends/:friendId", friendsHandler.RemoveFriend)
	protected.GET("/friends", friendsHandler.GetFriends)
	protected.GET("/friends/pending", friendsHandler.GetPendingRequests)

	// Start server
	log.Printf("Starting server on port %s", cfg.Port)
	if err := e.Start(":" + cfg.Port); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}
