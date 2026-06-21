package eta

import "math"

func Predict(distanceMeters float64, trafficFactor float64) int {
	effectiveSpeedMetersPerSecond := 7.5 / math.Max(trafficFactor, 0.6)
	if effectiveSpeedMetersPerSecond <= 0 {
		effectiveSpeedMetersPerSecond = 4
	}
	return int(math.Ceil(distanceMeters / effectiveSpeedMetersPerSecond))
}
