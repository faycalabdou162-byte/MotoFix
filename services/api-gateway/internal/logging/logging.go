package logging

import "log/slog"

func WithRequest(logger *slog.Logger, requestID, route string) *slog.Logger {
	return logger.With("request_id", requestID, "route", route)
}
