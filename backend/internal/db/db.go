package db

import (
	"context"
	"fmt"
	"log"

	"github.com/jackc/pgx/v5/pgxpool"
	"lari-backend/internal/config"
)

func InitDB(cfg *config.Config) (*pgxpool.Pool, error) {
	dbPool, err := pgxpool.New(context.Background(), cfg.DatabaseURL)
	if err != nil {
		return nil, fmt.Errorf("unable to create connection pool: %v", err)
	}

	// Test connection
	if err := dbPool.Ping(context.Background()); err != nil {
		return nil, fmt.Errorf("unable to ping database: %v", err)
	}

	log.Println("Connected to PostgreSQL successfully")
	return dbPool, nil
}
