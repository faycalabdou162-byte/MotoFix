package events

import (
	"time"
)

type EventEnvelope[T any] struct {
	EventID     string    `json:"eventId"`
	EventType   string    `json:"eventType"`
	OccurredAt  time.Time `json:"occurredAt"`
	CityID      string    `json:"cityId"`
	AggregateID string    `json:"aggregateId"`
	Data        T         `json:"data"`
}

const (
	EventTripRequested      = "trip.requested"
	EventTripAccepted       = "trip.accepted"
	EventDriverLocation     = "driver.location.updated"
	EventDriverAvailability = "driver.availability.updated"
	EventDispatchOffered    = "dispatch.offered"
	EventPaymentAuthorized  = "payment.authorized"
	EventPaymentFailed      = "payment.failed"
	EventFraudSignal        = "fraud.signal"
)
