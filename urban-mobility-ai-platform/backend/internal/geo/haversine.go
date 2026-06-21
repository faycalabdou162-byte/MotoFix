package geo

import "math"

func DistanceM(lat1, lng1, lat2, lng2 float64) float64 {
	const R = 6371000.0
	phi1 := lat1 * (math.Pi / 180)
	phi2 := lat2 * (math.Pi / 180)
	dphi := (lat2 - lat1) * (math.Pi / 180)
	dlambda := (lng2 - lng1) * (math.Pi / 180)

	a := math.Sin(dphi/2)*math.Sin(dphi/2) + math.Cos(phi1)*math.Cos(phi2)*math.Sin(dlambda/2)*math.Sin(dlambda/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return R * c
}

