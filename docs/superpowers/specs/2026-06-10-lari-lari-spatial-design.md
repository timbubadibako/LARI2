# LARI-LARI Spatial Intelligence Design Spec

**Date:** 2026-06-10
**Status:** Draft (Brainstormed)
**Goal:** Transform solitary running into a real-time territory conquest game using native GPS data and high-performance spatial validation.

---

## 1. System Overview

The system follows a **"Thick Client, Thin Validating Server"** architecture. 
- **Frontend (Flutter):** Handles live rendering, local buffering, and user interaction.
- **Backend (Go + PostGIS):** Acts as the "Sentinel" that validates claims using advanced geometric algorithms to prevent spoofing and ensure data integrity.

## 2. Mathematical Engine (The Core)

The system relies on three primary mathematical models extracted from the research paper:

### 2.1. Data Smoothing (3rd Order Polynomial Regression)
To mitigate GPS multipath interference (signal jumps in urban areas), incoming coordinate streams are filtered using a third-order polynomial regression model.
- **Input:** Raw GPS coordinate stream.
- **Output:** Smoothed polyline for visualization and validation.

### 2.2. Conflict Detection (Line Intersection)
Detects when a runner's path intersects with their own previous path or a competitor's boundary.
- **Algorithm:** Determinant-based intersection check.
- **Event:** Triggers an interruption or claim invalidation if a conflict is detected.

### 2.3. Area Calculation (Shoelace Formula)
Used to calculate the exact square meters of a conquered zone upon path loop completion.
- **Logic:** `Area = 0.5 * |Σ(xi*yi+1 - xi+1*yi)|`
- **Output:** Points awarded to the user based on the calculated area.

## 3. Tech Stack

### Frontend (Client)
- **Framework:** Flutter
- **Map Engine:** MapLibre GL (Vector-based rendering)
- **Local Storage:** Hive (Buffer for offline coordinates)

### Backend (Server)
- **Language:** Go (Golang)
- **API Framework:** Gin or Echo
- **Database:** PostgreSQL 16+ with PostGIS 3+ extension

## 4. Database Schema (PostGIS)

### `users`
- `id`: UUID (PK)
- `display_name`: VARCHAR
- `total_area_claimed`: DOUBLE PRECISION

### `activities`
- `id`: UUID (PK)
- `user_id`: UUID (FK)
- `route`: GEOMETRY(LineString, 4326)
- `started_at`: TIMESTAMP

### `territories`
- `id`: UUID (PK)
- `user_id`: UUID (FK)
- `boundary`: GEOMETRY(Polygon, 4326)
- `area_sqm`: DOUBLE PRECISION
- `created_at`: TIMESTAMP

## 5. Data Flow (The Sync Protocol)

1. **Start:** User begins a workout in Flutter.
2. **Streaming:** Coordinates are buffered locally.
3. **Loop Detection:** Flutter detects a potential loop completion.
4. **Sync:** Flutter sends the `LineString` to `POST /v1/claims`.
5. **Validation:** Go Backend:
    - Applies Polynomial Smoothing.
    - Checks for self-intersection (Line Intersection).
    - Checks for boundary conflicts with other users.
    - Calculates area via `ST_Area` (Shoelace).
6. **Result:** If valid, Go updates the `territories` table and returns a success response.

---

## 6. Success Criteria
- [ ] Real-time rendering of smoothed paths on MapLibre.
- [ ] Accurate area calculation (+/- 1% variance).
- [ ] Prevention of GPS spoofing through velocity and regression checks.
- [ ] Low-latency sync ( < 2s for claim validation).
