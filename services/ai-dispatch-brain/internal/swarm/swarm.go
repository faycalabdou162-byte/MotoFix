package swarm

type Recommendation struct {
	ZoneID        string  `json:"zone_id"`
	TargetDrivers int     `json:"target_drivers"`
	HeatScore     float64 `json:"heat_score"`
}

func Reposition(targetZone string, currentGap int, demandScore float64) Recommendation {
	targetDrivers := currentGap
	if targetDrivers < 0 {
		targetDrivers = 0
	}
	return Recommendation{
		ZoneID:        targetZone,
		TargetDrivers: targetDrivers,
		HeatScore:     demandScore,
	}
}
