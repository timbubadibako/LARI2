# Installation Guide

## Backend
1. Ensure PostgreSQL with PostGIS extension is installed.
2. Configure `backend/.env` with your database credentials.
3. Run `go run cmd/server/main.go`.

## Frontend
1. Ensure Flutter SDK is installed.
2. Run `flutter pub get`.
3. Configure `frontend/lib/core/config/api_config.dart` with your tunnel URL.
4. Run `flutter run`.
