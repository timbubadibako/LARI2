package worker

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// SeasonWorker bertanggung jawab untuk menjalankan reset season otomatis setiap Senin jam 00:00.
// Alurnya: Hitung pemenang → Simpan ke season_history → Beri badge → Hapus data minggu lalu.
type SeasonWorker struct {
	db *pgxpool.Pool
}

func NewSeasonWorker(db *pgxpool.Pool) *SeasonWorker {
	return &SeasonWorker{db: db}
}

// Start menjalankan loop yang menunggu hingga hari Senin jam 00:00 berikutnya,
// lalu mengeksekusi reset season secara otomatis.
func (w *SeasonWorker) Start(ctx context.Context) {
	log.Println("Season Reset Worker started. Waiting for next Monday 00:00...")

	for {
		now := time.Now()
		// Hitung waktu Senin berikutnya jam 00:01 (beri toleransi 1 menit)
		nextMonday := nextMondayMidnight(now)
		waitDuration := time.Until(nextMonday)

		log.Printf("Season Reset: next execution in %v (at %s)", waitDuration.Round(time.Minute), nextMonday.Format("2006-01-02 15:04:05"))

		select {
		case <-ctx.Done():
			log.Println("Season Reset Worker stopped.")
			return
		case <-time.After(waitDuration):
			w.executeSeasonReset(ctx)
		}
	}
}

// nextMondayMidnight menghitung waktu Senin jam 00:01 berikutnya.
func nextMondayMidnight(from time.Time) time.Time {
	loc := from.Location()
	// Hitung berapa hari hingga Senin berikutnya
	daysUntilMonday := (int(time.Monday) - int(from.Weekday()) + 7) % 7
	if daysUntilMonday == 0 && from.Hour() >= 0 {
		daysUntilMonday = 7 // Kalau sudah Senin, tunggu Senin depan
	}
	next := time.Date(from.Year(), from.Month(), from.Day()+daysUntilMonday, 0, 1, 0, 0, loc)
	return next
}

// getSeasonID mengembalikan ID season dalam format "YYYY-WNN" (misal: "2026-W25").
func getSeasonID(t time.Time) string {
	year, week := t.ISOWeek()
	return fmt.Sprintf("%d-W%02d", year, week)
}

// executeSeasonReset adalah inti logika reset season.
func (w *SeasonWorker) executeSeasonReset(ctx context.Context) {
	// Gunakan waktu minggu lalu karena kita baru saja melewati tengah malam Senin
	lastWeek := time.Now().Add(-1 * time.Hour)
	seasonID := getSeasonID(lastWeek)
	log.Printf("Executing Season Reset for season: %s", seasonID)

	tx, err := w.db.Begin(ctx)
	if err != nil {
		log.Printf("SeasonReset: failed to begin transaction: %v", err)
		return
	}
	defer tx.Rollback(ctx)

	// ── LANGKAH 1: Temukan pemenang setiap sektor ──────────────────────────────
	// Pemenang = user dengan total_area_sqm terbesar per sektor
	winnerRows, err := tx.Query(ctx, `
		SELECT DISTINCT ON (sector_id)
			sector_id,
			user_id,
			guild_id,
			total_area_sqm
		FROM user_territories
		WHERE total_area_sqm > 0
		ORDER BY sector_id, total_area_sqm DESC
	`)
	if err != nil {
		log.Printf("SeasonReset: failed to query winners: %v", err)
		return
	}

	type Winner struct {
		SectorID     string
		UserID       string
		GuildID      *string
		TotalAreaSqm float64
	}

	var winners []Winner
	for winnerRows.Next() {
		var w Winner
		if err := winnerRows.Scan(&w.SectorID, &w.UserID, &w.GuildID, &w.TotalAreaSqm); err != nil {
			continue
		}
		winners = append(winners, w)
	}
	winnerRows.Close()

	log.Printf("SeasonReset: found %d sector winners", len(winners))

	// ── LANGKAH 2: Simpan ke season_history & beri badge ──────────────────────
	for _, winner := range winners {
		// Insert ke season_history
		_, err := tx.Exec(ctx, `
			INSERT INTO season_history (season_id, sector_id, winner_user_id, guild_id, total_area_sqm)
			VALUES ($1, $2, $3, $4, $5)
		`, seasonID, winner.SectorID, winner.UserID, winner.GuildID, winner.TotalAreaSqm)
		if err != nil {
			log.Printf("SeasonReset: failed to insert season_history for sector %s: %v", winner.SectorID, err)
			continue
		}

		// Beri badge kepada pemenang
		badgeID := fmt.Sprintf("RULER_%s_%s", winner.SectorID, seasonID)
		badgeName := fmt.Sprintf("Penguasa %s (%s)", winner.SectorID, seasonID)
		description := fmt.Sprintf("Memenangkan wilayah %s pada musim %s dengan luas %.0f m²", winner.SectorID, seasonID, winner.TotalAreaSqm)

		_, err = tx.Exec(ctx, `
			INSERT INTO user_badges (user_id, badge_id, badge_name, description)
			VALUES ($1, $2, $3, $4)
			ON CONFLICT (user_id, badge_id) DO NOTHING
		`, winner.UserID, badgeID, badgeName, description)
		if err != nil {
			log.Printf("SeasonReset: failed to award badge for user %s: %v", winner.UserID, err)
		}
	}

	// ── LANGKAH 3: Hapus data wilayah dan rute lari minggu lalu ───────────────
	tagTerritories, err := tx.Exec(ctx, "DELETE FROM user_territories")
	if err != nil {
		log.Printf("SeasonReset: failed to clear user_territories: %v", err)
		return
	}

	tagRuns, err := tx.Exec(ctx, "DELETE FROM runs")
	if err != nil {
		log.Printf("SeasonReset: failed to clear runs: %v", err)
		return
	}

	tagLeaderboard, err := tx.Exec(ctx, "DELETE FROM leaderboard_cache")
	if err != nil {
		log.Printf("SeasonReset: failed to clear leaderboard_cache: %v", err)
		return
	}

	if err := tx.Commit(ctx); err != nil {
		log.Printf("SeasonReset: failed to commit transaction: %v", err)
		return
	}

	log.Printf("✅ Season Reset COMPLETE for %s: %d winners recorded, %d territories cleared, %d runs cleared, %d leaderboard entries cleared",
		seasonID,
		len(winners),
		tagTerritories.RowsAffected(),
		tagRuns.RowsAffected(),
		tagLeaderboard.RowsAffected(),
	)
}
