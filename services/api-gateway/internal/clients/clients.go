package clients

type Downstream struct {
	AuthServiceURL         string
	UserServiceURL         string
	DriverServiceURL       string
	TripServiceURL         string
	DispatchServiceURL     string
	AIDispatchBrainURL     string
	GeoServiceURL          string
	PaymentServiceURL      string
	NotificationServiceURL string
	AnalyticsServiceURL    string
}

func New() Downstream {
	return Downstream{
		AuthServiceURL:         "http://auth-service:8081",
		UserServiceURL:         "http://user-service:8082",
		DriverServiceURL:       "http://driver-service:8083",
		TripServiceURL:         "http://trip-service:8084",
		DispatchServiceURL:     "http://dispatch-service:8085",
		AIDispatchBrainURL:     "http://ai-dispatch-brain:8086",
		GeoServiceURL:          "http://geo-service:8087",
		PaymentServiceURL:      "http://payment-service:8088",
		NotificationServiceURL: "http://notification-service:8089",
		AnalyticsServiceURL:    "http://analytics-service:8090",
	}
}
