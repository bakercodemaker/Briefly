# 04 — Make Analysis Request failures recoverable

**What to build:** The owner receives honest, actionable handling when an Analysis Request cannot complete: terminal source errors stop clearly, while temporary provider or quota errors use bounded automatic recovery and an eventual manual retry.

**Blocked by:** 02 — Submit an Analysis Request.

**Status:** ready-for-agent

- [ ] Invalid, private, unlisted, or inaccessible source failures are clearly presented as terminal and are not retried.
- [ ] Temporary provider and rate-limit failures use a small bounded automatic retry policy and retain visible lifecycle/error state.
- [ ] Once recoverable retries are exhausted, the owner can explicitly retry; endless or silent retrying is impossible.
- [ ] Application-boundary tests use the fake provider to prove terminal and recoverable behavior.
