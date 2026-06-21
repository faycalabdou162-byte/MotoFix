package authz

type Role string

const (
	RoleUser     Role = "user"
	RoleDriver   Role = "driver"
	RoleMechanic Role = "mechanic"
	RoleAdmin    Role = "admin"
)

func Allowed(role Role, accepted ...Role) bool {
	for _, candidate := range accepted {
		if candidate == role {
			return true
		}
	}
	return false
}
