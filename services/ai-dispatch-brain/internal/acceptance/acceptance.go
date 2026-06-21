package acceptance

func Probability(rating float64, completionRate float64, recentAcceptanceRate float64) float64 {
	score := (rating/5)*0.35 + completionRate*0.25 + recentAcceptanceRate*0.40
	if score < 0 {
		return 0
	}
	if score > 1 {
		return 1
	}
	return score
}
