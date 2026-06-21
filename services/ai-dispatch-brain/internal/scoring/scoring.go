package scoring

type RequestFeatures struct {
	DistanceWeight        float64 `json:"distance_weight"`
	DriverRating          float64 `json:"driver_rating"`
	Availability          float64 `json:"availability"`
	TrafficPrediction     float64 `json:"traffic_prediction"`
	VehicleMatch          float64 `json:"vehicle_match"`
	AcceptanceProbability float64 `json:"acceptance_probability"`
	FraudPenalty          float64 `json:"fraud_penalty"`
	StaleGPSPenalty       float64 `json:"stale_gps_penalty"`
}

func DispatchScore(input RequestFeatures) float64 {
	return input.DistanceWeight +
		input.DriverRating +
		input.Availability +
		input.TrafficPrediction +
		input.VehicleMatch +
		input.AcceptanceProbability -
		input.FraudPenalty -
		input.StaleGPSPenalty
}
