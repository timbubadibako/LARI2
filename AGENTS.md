# AGENTS.md

This file defines the default workflow for agents working in this repository.

## 1. Read Context First

Before making changes, read the minimum relevant context:

- `README.md`
- `PRODUCT_CONTEXT.md`
- `.local_docs/ISSUES.md`
- `.local_docs/GAME_DESIGN.md`
- `.local_docs/GEMINI.md`
- Feature files directly related to the task

If the task touches backend data, schema, auth, sync, or Supabase-facing flows, do not guess contracts or database structure. Inspect the backend code and schema files first.

## 2. Default Working Style

- Prefer small, atomic changes.
- Follow existing code structure and naming instead of introducing a new pattern.
- Preserve the current tactical/cyber UI language unless the task explicitly asks for redesign.
- Keep frontend and backend behavior aligned; do not patch one side while ignoring an obvious contract mismatch.
- When something is unclear, inspect the implementation and choose the smallest safe change.

## 3. Repo Shape

- `frontend/`: Flutter application
- `backend/`: Go API, workers, spatial engine, and DB schema
- `.local_docs/`: local source of truth for product notes, backlog, and dev toggles
- `docs/`: public-facing project documentation and assets

## 4. Workflow

1. Read the relevant docs and feature files.
2. Inspect existing patterns in adjacent code before editing.
3. Implement the smallest safe change that solves the task.
4. Run targeted verification:
   - `flutter test` / specific Flutter tests for frontend work
   - `flutter analyze` when the change is broad enough to justify it
   - `go test ./...` or targeted Go tests for backend work
5. Summarize what changed, what was verified, and any remaining risk.

## 5. Task-Specific Rules

### Frontend

- Main stack: Flutter, Dart, Riverpod, MapLibre, Supabase client integrations.
- Prefer editing existing controllers/providers/screens over creating parallel flows.
- Preserve the current terminology used in-app unless the task is explicitly copy-focused.
- Be careful with workout tracking, map rendering, and derived metrics; these areas are stateful and easy to regress.

### Backend

- Main stack: Go, PostGIS-oriented spatial logic, HTTP/WebSocket handlers, workers.
- Inspect API handlers, services, and schema together before changing request/response behavior.
- Territory and anti-spoofing logic are sensitive; avoid silent behavioral changes.

## 6. Production Toggle Checks

Before changing workout completion, validation, or backend run ingestion, inspect `.local_docs/GEMINI.md`.

Known dev-mode differences already documented there include:

- minimum distance save validation disabled
- GPS jump speed limiter disabled in frontend
- velocity anomaly check disabled in backend
- finish-button hold duration reduced from production value

Do not accidentally normalize these into permanent behavior without an explicit decision.

## 7. Issue-Driven Work

If the task is based on backlog/issues, use `.local_docs/ISSUES.md` as the operational source of truth.

Expected pattern:

1. Read backlog context first.
2. Work in an atomic change set.
3. Add or update relevant tests.
4. If the workflow includes issue/PR handling, update the related checklist and notes after implementation.

If no issue workflow is requested, do not invent one.

## 8. Verification Standard

Never claim a fix without running a relevant verification step when one is available locally.

If verification cannot be run, state that clearly and explain why.

## 9. Output Expectations

When handing work back:

- state what changed
- state what was verified
- state any remaining assumptions, gaps, or follow-up items

Keep summaries concise and concrete.
