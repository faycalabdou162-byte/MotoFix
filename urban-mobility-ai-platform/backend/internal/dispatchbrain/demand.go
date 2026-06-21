package dispatchbrain

import (
	"math"
	"time"
)

type DemandKey struct {
	CityID string
	ZoneID string
	Hour   int
}

type DemandPredictor struct {
	alpha float64
	state map[DemandKey]float64
}

func NewDemandPredictor(alpha float64) *DemandPredictor {
	if alpha <= 0 || alpha >= 1 {
		alpha = 0.2
	}
	return &DemandPredictor{alpha: alpha, state: map[DemandKey]float64{}}
}

func (p *DemandPredictor) Observe(cityID, zoneID string, t time.Time, count float64) {
	k := DemandKey{CityID: cityID, ZoneID: zoneID, Hour: t.UTC().Hour()}
	prev := p.state[k]
	if prev == 0 {
		p.state[k] = count
		return
	}
	p.state[k] = (p.alpha * count) + ((1 - p.alpha) * prev)
}

func (p *DemandPredictor) Predict(cityID, zoneID string, t time.Time) float64 {
	k := DemandKey{CityID: cityID, ZoneID: zoneID, Hour: t.UTC().Hour()}
	v := p.state[k]
	if v < 0 {
		return 0
	}
	return math.Min(v, 1e9)
}

