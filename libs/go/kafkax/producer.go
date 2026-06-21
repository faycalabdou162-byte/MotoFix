package kafkax

import (
	"os"
	"strings"

	"github.com/IBM/sarama"
)

func NewSyncProducer() (sarama.SyncProducer, error) {
	brokers := os.Getenv("KAFKA_BROKERS")
	if brokers == "" {
		brokers = "localhost:9092"
	}

	cfg := sarama.NewConfig()
	cfg.Producer.Return.Successes = true
	cfg.Producer.RequiredAcks = sarama.WaitForAll
	return sarama.NewSyncProducer(strings.Split(brokers, ","), cfg)
}
