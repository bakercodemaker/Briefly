# 03 — Retire the hosted and container runtime

**What to build:** Make the local SQLite/Solid Queue workflow the only supported way to run Briefly, removing hosted deployment paths while keeping Docker Compose as the local Ruby/Rails runtime.

**Blocked by:** 02 — Run Briefly locally with SQLite and Solid Queue.

**Status:** completed

- [x] Briefly no longer contains Render/Neon or hosted-production runtime paths.
- [x] Docker Compose runs Briefly locally without requiring Ruby, Rails, or a database server on the host machine.
- [x] Dependencies and configuration retained by the application have a direct local product purpose.
- [x] The local development command remains a complete, documented replacement for the retired runtime.

## Comments

- Completed 2026-08-27. Removed the Render/Neon runtime, hosted production configuration, obsolete hosted tests, PostgreSQL CI service wiring, and the unused React/TypeScript mount. The supported documented runtime is `docker compose up --build`, which runs Ruby, Rails, SQLite, Tailwind CSS, and the explicit `bin/jobs start` Solid Queue worker inside the app container.
