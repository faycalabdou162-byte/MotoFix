package outbox

import "time"

type Message struct {
	ID          string
	Topic       string
	Key         string
	Payload     []byte
	CreatedAt   time.Time
	PublishedAt *time.Time
}
