Type: research
Status: resolved
Assigned to: Codex
Labels: wayfinder:research
Parent: ../map.md
Blocked by: —

## Question

How should the provided Dockerized Rails setup be modernised for this Rails + React/TypeScript MVP, and does Docker change the recommended free hosting path or cost?

## Answer

Use Docker-first local development: it removes any need to install Ruby or Rails on the host and is well suited to this MVP. Modernise the guide with a pinned Debian-based Ruby image compatible with Rails 8, `docker compose`, a Postgres healthcheck with `service_healthy`, a local `.env` file, and Node in the development container. Use a Rails monolith with React/TypeScript bundled through `jsbundling-rails`/esbuild rather than a separate SPA. Docker does not change the recommended $0 deployment: deploy the source as a Render Free Web Service with Neon Free Postgres, rather than relying on Docker hosting. Treat the credential-store edit as machine-specific troubleshooting, not a normal setup step. Research: [Dockerized local development](../research/docker-local-development.md).
