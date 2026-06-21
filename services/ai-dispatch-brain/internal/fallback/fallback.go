package fallback

func BandwidthSafeMode(isModelHealthy bool, latencyMs int) string {
	if !isModelHealthy || latencyMs > 120 {
		return "heuristic_fallback"
	}
	return "ml_primary"
}
