# Installation Guide

## 1. Prerequisites
- **Git** installed.
- **Flutter SDK** (3.x recommended).
- **Go** (1.26+ recommended).
- **PostgreSQL** (15+) with **PostGIS** extension enabled.

## 2. Clone Repository
```bash
git clone https://github.com/timbubadibako/LARI2.git
cd LARI2
```

## 3. Backend Setup
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Set up your `.env` file (create one if not exists):
   ```env
   DATABASE_URL=postgresql://user:password@localhost:5432/LARI2?sslmode=disable
   PORT=8080
   BASE_URL=http://localhost:8080
   ```
3. Initialize the database:
   ```bash
   # Connect to your database
   psql -d LARI2 -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
   psql -d LARI2 -c "CREATE EXTENSION IF NOT EXISTS postgis;"
   
   # Execute schema
   psql -d LARI2 -f internal/db/SCHEMA_LARI2.sql
   psql -d LARI2 -f internal/db/SEED_GUILDS.sql
   ```
4. Run the server:
   ```bash
   go run cmd/server/main.go
   ```

## 4. Frontend Setup
1. Navigate to the frontend directory:
   ```bash
   cd ../frontend
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Configure your API base URL in `lib/core/config/api_config.dart` if using a tunneling service.
4. Build and run:
   ```bash
   # For Android
   flutter run --release
   ```
EOF
