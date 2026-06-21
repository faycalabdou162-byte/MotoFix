package dispatchbrain

import (
	"math"
)

type ScoringWeights struct {
	DistanceWeight     float64
	DriverRatingWeight float64
	AvailabilityWeight float64
	TrafficWeight      float64
	VehicleMatchWeight float64
}

type Candidate struct {
	DriverID      string
	DistanceM     float64
	DriverRating  float64
	Availability  float64
	TrafficFactor float64
	VehicleMatch  float64
}

type ScoredCandidate struct {
	Candidate
	Score float64
}

func Score(weights ScoringWeights, c Candidate) float64 {
	d := 1.0 / (1.0 + math.Max(0, c.DistanceM))
	return (d * weights.DistanceWeight) +
		(c.DriverRating * weights.DriverRatingWeight) +
		(c.Availability * weights.AvailabilityWeight) +
		((1.0/c.TrafficFactor)*weights.TrafficWeight) +
		(c.VehicleMatch * weights.VehicleMatchWeight)
}

