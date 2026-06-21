package domain

import "time"

type Role string

const (
	RoleUser     Role = "user"
	RoleDriver   Role = "driver"
	RoleAdmin    Role = "admin"
	RoleMechanic Role = "mechanic"
)

type VehicleType string

const (
	VehicleMoto VehicleType = "moto"
	VehicleCar  VehicleType = "car"
	VehicleTow  VehicleType = "tow"
)

type TripStatus string

const (
	TripRequested TripStatus = "requested"
	TripOffered   TripStatus = "offered"
	TripAccepted  TripStatus = "accepted"
	TripStarted   TripStatus = "started"
	TripCompleted TripStatus = "completed"
	TripCancelled TripStatus = "cancelled"
)

type LatLng struct {
	Lat float64 `json:"lat"`
	Lng float64 `json:"lng"`
}

type Money struct {
	Currency string `json:"currency"`
	Amount   int64  `json:"amount"`
}

type Timestamp struct {
	Time time.Time `json:"time"`
}

