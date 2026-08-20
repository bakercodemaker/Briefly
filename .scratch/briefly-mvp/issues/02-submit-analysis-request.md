# 02 — Submit an Analysis Request

**What to build:** An owner can paste one public YouTube URL in the Personal Workspace and receive a durable, visible queued Analysis Request instead of a synchronous provider call.

**Blocked by:** 01 — Create the protected Briefly workbench.

**Status:** ready-for-agent

- [ ] A valid public YouTube URL creates one persisted Analysis Request with the `queued` lifecycle state.
- [ ] Malformed or unsupported URLs receive clear validation feedback and do not create a request.
- [ ] The workbench makes the queued state visible while retaining the compact composer-first interaction.
- [ ] Application-boundary tests cover owner submission, rejected anonymous submission, persistence, and validation behavior.
