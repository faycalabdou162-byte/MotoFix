package main

import (
	"context"
	"os/signal"
	"syscall"

	"github.com/urbanmobilityai/platform/libs/go/observability"
	"github.com/urbanmobilityai/platform/libs/go/platform/config"
	"github.com/urbanmobilityai/platform/libs/go/platform/logx"
	platformruntime "github.com/urbanmobilityai/platform/libs/go/platform/runtime"
	gatewayconfig "github.com/urbanmobilityai/platform/services/api-gateway/internal/config"
	"github.com/urbanmobilityai/platform/services/api-gateway/internal/http"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGTERM, syscall.SIGINT)
	defer stop()

	appCfg := config.Load("api-gateway", 8080)
	logger := logx.New(appCfg.Name)
	shutdownTracing, err := observability.Setup(ctx, appCfg.Name)
	if err != nil {
		logger.Error("failed to setup tracing", "error", err)
		return
	}
	defer func() { _ = shutdownTracing(context.Background()) }()

	gatewayCfg := gatewayconfig.Load()
	router := http.NewRouter(logger, gatewayCfg)
	server := platformruntime.NewHTTPServer(appCfg, router)

	go func() {
		logger.Info("api gateway listening", "port", appCfg.Port)
		if err := server.ListenAndServe(); err != nil && err.Error() != "http: Server closed" {
			logger.Error("gateway stopped unexpectedly", "error", err)
		}
	}()

	<-ctx.Done()
	_ = platformruntime.Shutdown(context.Background(), logger, server)
}
