package surge

func PriceMultiplier(demandFactor float64, trafficFactor float64, supplyFactor float64) float64 {
	multiplier := demandFactor * trafficFactor * supplyFactor
	if multiplier < 1 {
		return 1
	}
	if multiplier > 3 {
		return 3
	}
	return multiplier
}
