package user

import "time"

type User struct {
	ID        string    `json:"id"`
	CityID    string    `json:"cityId"`
	Phone     string    `json:"phone"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
}

