# 07 — Make the MVP deployable and portfolio-ready

**What to build:** A finished Briefly MVP can be deployed safely to the selected free hosting arrangement and understood by a recruiter even when the host is cold or live processing is unavailable.

**Blocked by:** 01 — Create the protected Briefly workbench; 03 — Generate and open a source-faithful Brief; 04 — Make Analysis Request failures recoverable; 05 — Browse and manage the Personal Brief Library; 06 — Publish the read-only Demo Library.

**Status:** ready-for-agent

- [ ] The app deploys as one Render web service with Neon Postgres; database, Rails, Gemini, and owner-password secrets are configured outside the repository.
- [ ] Production uses durable database storage rather than service local disk, and communicates cold-start and free-tier limitations honestly.
- [ ] A manual production smoke test covers owner submission, recoverable failure presentation, public read-only Demo Library access, and cold-start messaging.
- [ ] The project includes a concise README, architecture diagram, screenshots, and short walkthrough video explaining the completed product and its boundaries.
