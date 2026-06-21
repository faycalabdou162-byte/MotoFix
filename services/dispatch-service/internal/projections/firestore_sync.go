package projections

type ActiveTripProjection struct {
	TripID         string `json:"trip_id"`
	Status         string `json:"status"`
	DriverID       string `json:"driver_id"`
	UserID         string `json:"user_id"`
	ETASeconds     int    `json:"eta_seconds"`
	LastLocationAt string `json:"last_location_at"`
}
