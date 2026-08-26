# 04 — Simplify Analysis Request generation lifecycle

**What to build:** Give the owner one clear active Analysis Request lifecycle: one request at a time, one automatic retry for a Recoverable Failure, then a visible manual retry, with state rules concentrated in the existing Rails modules.

**Blocked by:** 02 — Run Briefly locally with SQLite and Solid Queue.

**Status:** completed

- [x] A second queued or processing Analysis Request is rejected as a durable product rule.
- [x] A temporary Gemini failure receives exactly one automatic retry before manual retry becomes available.
- [x] Terminal source failures remain visible and do not offer retry.
- [x] Overlapping PostgreSQL advisory locking and job-level concurrency controls are absent.

## Comments

- Completed 2026-08-26. A nullable `active_slot` with a unique SQLite index guards the one-active-request rule. The job has one automatic retry and terminal source failures remain non-retryable.
