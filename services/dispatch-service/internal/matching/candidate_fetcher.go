package matching

import "sort"

type Candidate struct {
	DriverID         string  `json:"driver_id"`
	DistanceMeters   float64 `json:"distance_meters"`
	Rating           float64 `json:"rating"`
	Availability     float64 `json:"availability"`
	TrafficPenalty   float64 `json:"traffic_penalty"`
	VehicleMatch     float64 `json:"vehicle_match"`
	AcceptanceProb   float64 `json:"acceptance_probability"`
	FraudPenalty     float64 `json:"fraud_penalty"`
	StaleGPSPenalty  float64 `json:"stale_gps_penalty"`
	ComputedDispatch float64 `json:"computed_dispatch_score"`
}

func Rank(candidates []Candidate) []Candidate {
	ranked := append([]Candidate(nil), candidates...)
	for index := range ranked {
		candidate := &ranked[index]
		candidate.ComputedDispatch =
			(1 / max(candidate.DistanceMeters, 1)) * 1000 +
				candidate.Rating*1.2 +
				candidate.Availability*2.0 +
				candidate.VehicleMatch*1.6 +
				candidate.AcceptanceProb*2.2 -
				candidate.TrafficPenalty -
				candidate.FraudPenalty -
				candidate.StaleGPSPenalty
	}

	sort.SliceStable(ranked, func(i, j int) bool {
		return ranked[i].ComputedDispatch > ranked[j].ComputedDispatch
	})
	return ranked
}

func max(value, fallback float64) float64 {
	if value < fallback {
		return fallback
	}
	return value
}
