package logx

import (
	"log/slog"
	"os"
)

func New(serviceName string) *slog.Logger {
	return slog.New(
		slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
			AddSource: true,
		}),
	).With("service", serviceName)
}
