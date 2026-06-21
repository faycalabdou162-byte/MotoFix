package matching

import "time"

type SLA struct {
	CandidateFetch time.Duration
	AIScoring      time.Duration
	DispatchTotal  time.Duration
}

func DefaultSLA() SLA {
	return SLA{
		CandidateFetch: 20 * time.Millisecond,
		AIScoring:      30 * time.Millisecond,
		DispatchTotal:  100 * time.Millisecond,
	}
}
