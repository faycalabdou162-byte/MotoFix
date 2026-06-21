package firestorex

import (
	"context"
	"os"

	"cloud.google.com/go/firestore"
	"google.golang.org/api/option"
)

func NewClient(ctx context.Context) (*firestore.Client, error) {
	projectID := os.Getenv("FIREBASE_PROJECT_ID")
	credentials := os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")
	if credentials != "" {
		return firestore.NewClient(ctx, projectID, option.WithCredentialsFile(credentials))
	}
	return firestore.NewClient(ctx, projectID)
}
