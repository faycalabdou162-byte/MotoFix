package firebase

import (
	"context"
	"errors"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"google.golang.org/api/option"
)

type AuthVerifier struct {
	client *auth.Client
}

func NewAuthVerifier(ctx context.Context, projectID string, credentialsJSON []byte) (*AuthVerifier, error) {
	if projectID == "" {
		return nil, errors.New("missing firebase project id")
	}
	var app *firebase.App
	var err error
	if len(credentialsJSON) > 0 {
		app, err = firebase.NewApp(ctx, &firebase.Config{ProjectID: projectID}, option.WithCredentialsJSON(credentialsJSON))
	} else {
		app, err = firebase.NewApp(ctx, &firebase.Config{ProjectID: projectID})
	}
	if err != nil {
		return nil, err
	}
	c, err := app.Auth(ctx)
	if err != nil {
		return nil, err
	}
	return &AuthVerifier{client: c}, nil
}

func (v *AuthVerifier) VerifyIDToken(ctx context.Context, idToken string) (*auth.Token, error) {
	return v.client.VerifyIDToken(ctx, idToken)
}

