package trip

import (
	"time"

	"github.com/motofix/urban-mobility-ai-platform/backend/internal/domain"
)

type Trip struct {
	ID            string          `json:"id"`
	CityID        string          `json:"cityId"`
	UserID        string          `json:"userId"`
	DriverID      string          `json:"driverId"`
	VehicleType   domain.VehicleType `json:"vehicleType"`
	Status        domain.TripStatus  `json:"status"`
	Pickup        domain.LatLng    `json:"pickup"`
	Dropoff       domain.LatLng    `json:"dropoff"`
	CreatedAt     time.Time       `json:"createdAt"`
	UpdatedAt     time.Time       `json:"updatedAt"`
	SurgeFactor   float64         `json:"surgeFactor"`
	QuotedPrice   domain.Money    `json:"quotedPrice"`
}

