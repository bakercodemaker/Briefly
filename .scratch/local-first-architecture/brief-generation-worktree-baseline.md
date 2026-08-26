# Brief-generation worktree baseline

Recorded: 2026-08-26

This record reconciles the uncommitted Brief-generation worktree against
`.scratch/local-first-architecture/spec.md` and ADR-0001. It deliberately
does not discard or rewrite pending work; later tickets own the identified
local-first changes.

## Compatible behavior retained

- The domain vocabulary now describes one password-gated Personal Workspace,
  removes the Demo Library, and makes Polish the default Brief language.
- An owner can have only one active queued or processing Analysis Request.
- Gemini retryable errors can carry a provider-provided delay, and the job
  schedules its next attempt using that delay when present.
- Integration coverage continues to exercise persisted asynchronous Brief
  generation, terminal source failures, recoverable failures, manual retry,
  and private Brief access. Adapter tests remain isolated from external HTTP.

## Pending work intentionally preserved

- `GenerateBriefJob::MAX_AUTOMATIC_RETRIES` is still `2`, whereas the approved
  Recoverable Failure contract requires exactly one automatic retry. The
  existing tests that assert a count of two record the current behavior; ticket
  04 will change the behavior and its tests together.
- `AnalysisRequest.reserve_active_request_slot` still uses PostgreSQL advisory
  locking, and `GenerateBriefJob` still declares Solid Queue concurrency
  limits. Both conflict with the approved SQLite local-first runtime and are
  explicitly owned by ticket 04 after ticket 02 establishes SQLite.
- The pending `db/schema.rb` edit merely rewrites PostgreSQL check-constraint
  serialization. It does not move the schema toward SQLite, so ticket 02 must
  regenerate it from the SQLite migrations rather than preserve this diff.
- The default Gemini model changed from `gemini-3.7-flash` to
  `gemini-3.6-flash`. The local-first specification neither requires nor
  evaluates that provider-model choice, so it is preserved as unscoped pending
  work for its author to decide.

## Verified behavioral baseline

The relevant focused suite passed through the repository's Docker test
environment on 2026-08-26:

```sh
docker compose run --rm -e RAILS_ENV=test web bin/rails test \
  test/integration/brief_generation_test.rb \
  test/integration/analysis_requests_test.rb \
  test/models/analysis_request_test.rb \
  test/services/gemini_adapter_test.rb
```

Result: 35 runs, 227 assertions, 0 failures, 0 errors, 0 skips.
