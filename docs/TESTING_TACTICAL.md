# LARI Tactical Testing & Verification Guide

This document defines the complex test cases and automated verification procedures for the LARI V3 core engine.

---

## 1. Complex Test Scenarios

### 1.1 Geospatial & Territorial Conquest
| ID | Scenario | Algorithm | Success Criteria |
|:---|:---|:---|:---|
| **T-01** | **Perfect Loop (A ➔ A)** | `checkClosedLoop` | Status `CAPTURED`, WKT Polygon generated, Post-run Glow active. |
| **T-02** | **Recon Mission (A ➔ B)** | `linearDistance` | Status `PENDING`, No polygon, Distance >= 5km verified. |

### 1.2 Algorithmic Optimization
| ID | Scenario | Algorithm | Success Criteria |
|:---|:---|:---|:---|
| **T-03** | **Stationary Agent (Noise)** | `15s Jitter Filter` | Distance increment < 0.01km during 5min stationary period. |
| **T-04** | **Deep Recon (Optimization)** | `Chain-Code` | Points reduced by > 80% on straight lines while maintaining accuracy. |

### 1.3 Data Pipeline & Resilience
| ID | Scenario | Mechanism | Success Criteria |
|:---|:---|:---|:---|
| **T-05** | **Signal Jam (Offline)** | `Hive Sync Queue` | Data saved in `workouts` box, status `pending` in `sync_queue`. |
| **T-06** | **Resops Recovery (Sync)** | `processQueue()` | HTTP 201 on reconnect, status flips to `synced`, stats increment. |

### 1.4 Real-time Intelligence
| ID | Scenario | Mechanism | Success Criteria |
|:---|:---|:---|:---|
| **T-07** | **War Room Broadcast** | `WebSocket Hub` | Event broadcast to all connected clients, UI auto-refresh triggered. |

---

## 2. Running Automated Tests

### 2.1 Backend (Go)
Run all backend tests with verbosity:
```bash
cd backend
go test -v ./...
```

To filter for specific handler failures using `grep`:
```bash
go test -v ./internal/api | grep -E "FAIL|RUN|PASS"
```

To verify a specific scenario (e.g., Guilds):
```bash
go test -v ./internal/api -run TestJoinGuild
```

### 2.2 Frontend (Flutter)
Run all unit and widget tests:
```bash
cd frontend
flutter test
```

To run a specific test file and filter for "PASS" or "FAIL" markers:
```bash
flutter test test/features/profile/guild_controller_test.dart | grep -E "PASS|FAIL"
```

To run a specific scenario by name:
```bash
flutter test --plain-name "Perfect Loop" | grep "All tests passed"
```

---

## 3. Manual Verification Tools
*   **Debug Console 2.0:** Access via `Profile -> Version (Long Press)`. Use it to inspect the Hive `sync_queue` and manually trigger `FORCE_SYNC`.
*   **Fake GPS:** Toggle in the Dev Menu to simulate movement patterns (Circular, Linear, Noise) without leaving the workstation.
*   **Log Inspector:** Review real-time system events in the `SYSTEM_LOGS` section of the Debug Screen.
