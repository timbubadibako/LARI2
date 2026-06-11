package worker

import (
	"context"
	"log"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type CleanupWorker struct {
	db *pgxpool.Pool
}

func NewCleanupWorker(db *pgxpool.Pool) *CleanupWorker {
	return &CleanupWorker{db: db}
}

func (w *CleanupWorker) Start(ctx context.Context) {
	log.Println("Trail Integrity Cleanup Worker started.")
	
	ticker := time.NewTicker(1 * time.Hour)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			w.cleanup(ctx)
		}
	}
}

func (w *CleanupWorker) cleanup(ctx context.Context) {
	log.Println("Executing trail cleanup...")
	
	query := "DELETE FROM pending_trails WHERE expires_at < NOW()"
	tag, err := w.db.Exec(ctx, query)
	if err != nil {
		log.Printf("Cleanup failed: %v", err)
		return
	}
	
	if tag.RowsAffected() > 0 {
		log.Printf("Cleanup complete: purged %d expired trails.", tag.RowsAffected())
	}
}
