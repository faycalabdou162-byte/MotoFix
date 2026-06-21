package demand

func Forecast(baseHourlyDemand float64, seasonalFactor float64, eventFactor float64) float64 {
	return baseHourlyDemand * seasonalFactor * eventFactor
}
