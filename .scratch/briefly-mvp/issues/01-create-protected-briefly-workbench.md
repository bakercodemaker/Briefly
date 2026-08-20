# 01 — Create the protected Briefly workbench

**What to build:** A Docker-first Briefly application that the owner can unlock as a Personal Workspace while a recruiter can reach a separate public demo entry. It establishes the responsive workbench shell and the application-boundary test harness without introducing user accounts.

**Blocked by:** None — can start immediately.

**Status:** completed

- [x] The app boots locally with its required services and presents an English workbench shell.
- [x] A single environment-held owner password protects Personal Workspace routes; unauthenticated visitors cannot reach private reads or actions.
- [x] A public entry remains accessible without credentials and does not reveal private content.
- [x] Application-boundary tests prove the owner/public authorization split.
