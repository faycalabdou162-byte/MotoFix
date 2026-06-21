package matching

type FallbackStage struct {
	Name          string `json:"name"`
	MaxCandidates int    `json:"max_candidates"`
	TimeoutMs     int    `json:"timeout_ms"`
}

func DefaultFallbackChain() []FallbackStage {
	return []FallbackStage{
		{Name: "primary_nearest_same_vehicle", MaxCandidates: 3, TimeoutMs: 8000},
		{Name: "secondary_same_vehicle_expanded_radius", MaxCandidates: 5, TimeoutMs: 10000},
		{Name: "tertiary_cross_supply_balancing", MaxCandidates: 7, TimeoutMs: 12000},
	}
}
