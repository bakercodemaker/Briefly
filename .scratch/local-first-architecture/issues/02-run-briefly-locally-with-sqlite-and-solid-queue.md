# 02 — Run Briefly locally with SQLite and Solid Queue

**What to build:** Let the owner start Briefly natively with one SQLite database and an explicit local jobs process, so queued Brief generation is durable without Docker or PostgreSQL.

**Blocked by:** 01 — Reconcile the current Brief-generation worktree.

**Status:** completed

- [x] Native setup creates the application and Solid Queue data required for the Personal Workspace.
- [x] A separately visible local jobs process completes an enqueued Brief-generation job.
- [x] The supported test workflow uses SQLite and needs neither Docker nor a Gemini network call.

## Comments

- Completed 2026-08-26. SQLite and Solid Queue share the primary local database; `Procfile.dev` exposes `bin/jobs start`. Docker-only verification confirms durable queueing without a database service or Gemini call.
