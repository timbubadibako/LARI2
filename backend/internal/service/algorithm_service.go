package service

import (
	"math"
	"strconv"
	"time"
)

type Point struct {
	Lat            float64   `json:"lat"`
	Lng            float64   `json:"lng"`
	Timestamp      time.Time `json:"timestamp"`
	AccuracyMeters float64   `json:"accuracy"`
}

type ActivitySummary struct {
	TotalDistanceMeters float64 `json:"total_distance"`
	ElapsedDurationSec  int     `json:"elapsed_duration"`
	MovingDurationSec   int     `json:"moving_duration"`
	AveragePaceSecPerKm float64 `json:"average_pace"`
}

type AlgorithmService struct{}

func NewAlgorithmService() *AlgorithmService {
	return &AlgorithmService{}
}

// CalculateSummary processes raw points to generate Strava-level metrics.
func (s *AlgorithmService) CalculateSummary(points []Point) ActivitySummary {
	if len(points) < 2 {
		return ActivitySummary{}
	}

	// 1. Filter by accuracy
	validPoints := s.filterPoints(points)
	if len(validPoints) < 2 {
		return ActivitySummary{}
	}

	// 2. Calculations
	distance := s.calculateTotalDistance(validPoints)
	elapsed := int(validPoints[len(validPoints)-1].Timestamp.Sub(validPoints[0].Timestamp).Seconds())
	moving := s.calculateMovingTime(validPoints)

	// Pace calculation (seconds per km)
	var pace float64
	if distance > 0 {
		pace = float64(moving) / (distance / 1000.0)
	}

	return ActivitySummary{
		TotalDistanceMeters: distance,
		ElapsedDurationSec:  elapsed,
		MovingDurationSec:   moving,
		AveragePaceSecPerKm: pace,
	}
}

func (s *AlgorithmService) filterPoints(points []Point) []Point {
	var filtered []Point
	for _, p := range points {
		// Ignore points with accuracy > 30 meters
		if p.AccuracyMeters <= 30.0 {
			filtered = append(filtered, p)
		}
	}
	return filtered
}

func (s *AlgorithmService) calculateTotalDistance(points []Point) float64 {
	var total float64
	for i := 0; i < len(points)-1; i++ {
		total += s.Haversine(points[i], points[i+1])
	}
	return total
}

// calculateMovingTime implements the 15-second stationary filter.
func (s *AlgorithmService) calculateMovingTime(points []Point) int {
	movingSec := 0
	const speedThreshold = 0.5    // meters per second
	const stationaryThreshold = 15 // seconds

	currentStationarySec := 0

	for i := 0; i < len(points)-1; i++ {
		dist := s.Haversine(points[i], points[i+1])
		duration := points[i+1].Timestamp.Sub(points[i].Timestamp).Seconds()
		
		if duration <= 0 {
			continue
		}

		speed := dist / duration

		if speed < speedThreshold {
			currentStationarySec += int(duration)
		} else {
			// If we were stationary but for less than 15s, add it back to moving time
			if currentStationarySec > 0 && currentStationarySec <= stationaryThreshold {
				movingSec += currentStationarySec
			}
			movingSec += int(duration)
			currentStationarySec = 0
		}
	}

	return movingSec
}

// Haversine calculates the great-circle distance between two points.
func (s *AlgorithmService) Haversine(p1, p2 Point) float64 {
	const earthRadius = 6371000 // meters
	lat1 := p1.Lat * math.Pi / 180
	lng1 := p1.Lng * math.Pi / 180
	lat2 := p2.Lat * math.Pi / 180
	lng2 := p2.Lng * math.Pi / 180

	dLat := lat2 - lat1
	dLng := lng2 - lng1

	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1)*math.Cos(lat2)*
			math.Sin(dLng/2)*math.Sin(dLng/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))

	return earthRadius * c
}

func FormatFloat(f float64) string {
	return strconv.FormatFloat(f, 'f', 8, 64)
}
