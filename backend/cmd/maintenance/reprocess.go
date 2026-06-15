package main

import (
	"context"
	"log"
	"strings"
	"strconv"
	"lari-backend/internal/config"
	"lari-backend/internal/db"
	"lari-backend/internal/service"
)

func main() {
	cfg := config.LoadConfig()
	dbPool, err := db.InitDB(cfg)
	if err != nil {
		log.Fatal(err)
	}

	runID := "e97a4e90-bab6-4aae-bb33-d5b545b1b8e4"
	var userID, wkt string
	err = dbPool.QueryRow(context.Background(), "SELECT user_id, ST_AsText(path_geometry) FROM public.runs WHERE id = $1", runID).Scan(&userID, &wkt)
	if err != nil {
		log.Fatal(err)
	}

	// Parse WKT to []service.Point
	content := strings.ReplaceAll(strings.ReplaceAll(wkt, "LINESTRING(", ""), ")", "")
	pairs := strings.Split(content, ",")
	points := []service.Point{}
	for _, pair := range pairs {
		parts := strings.Split(strings.TrimSpace(pair), " ")
		lng, _ := strconv.ParseFloat(parts[0], 64)
		lat, _ := strconv.ParseFloat(parts[1], 64)
		points = append(points, service.Point{Lat: lat, Lng: lng})
	}

	engine := service.NewSpatialEngine(dbPool)
	area, err := engine.ProcessConquest(context.Background(), userID, "", points)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("Processed run, area captured: %f", area)
}
