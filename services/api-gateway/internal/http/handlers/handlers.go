package handlers

import (
	"net/http"

	"github.com/urbanmobilityai/platform/libs/go/platform/httpx"
)

func Health(w http.ResponseWriter, _ *http.Request) {
	httpx.JSON(w, http.StatusOK, map[string]any{
		"status": "ok",
		"scope":  "gateway",
	})
}

func Ready(w http.ResponseWriter, _ *http.Request) {
	httpx.JSON(w, http.StatusOK, map[string]any{
		"status": "ready",
	})
}

func SessionExchange(w http.ResponseWriter, _ *http.Request) {
	httpx.JSON(w, http.StatusAccepted, map[string]any{
		"message": "firebase token exchange delegated to auth-service",
	})
}

func Me(w http.ResponseWriter, _ *http.Request) {
	httpx.JSON(w, http.StatusOK, map[string]any{
		"profile_source": "user-service",
	})
}

func TripQuote(w http.ResponseWriter, _ *http.Request) {
	httpx.JSON(w, http.StatusAccepted, map[string]any{
		"status": "quote_requested",
	})
}

func TripCreate(w http.ResponseWriter, _ *http.Request) {
	httpx.JSON(w, http.StatusAccepted, map[string]any{
		"status": "trip_requested",
	})
}
