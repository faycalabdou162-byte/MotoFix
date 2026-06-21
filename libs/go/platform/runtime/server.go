package runtime

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"time"

	"github.com/urbanmobilityai/platform/libs/go/platform/config"
)

func NewHTTPServer(cfg config.App, handler http.Handler) *http.Server {
	return &http.Server{
		Addr:              fmt.Sprintf(":%d", cfg.Port),
		Handler:           handler,
		ReadHeaderTimeout: cfg.ReadTimeout,
	}
}

func Shutdown(ctx context.Context, logger *slog.Logger, server *http.Server) error {
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	logger.Info("shutting down http server")
	return server.Shutdown(ctx)
}
