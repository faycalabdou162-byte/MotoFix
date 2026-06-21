package dispatchbrain

import "sort"

func Rank(weights ScoringWeights, candidates []Candidate) []ScoredCandidate {
	out := make([]ScoredCandidate, 0, len(candidates))
	for _, c := range candidates {
		out = append(out, ScoredCandidate{Candidate: c, Score: Score(weights, c)})
	}
	sort.Slice(out, func(i, j int) bool {
		return out[i].Score > out[j].Score
	})
	return out
}

