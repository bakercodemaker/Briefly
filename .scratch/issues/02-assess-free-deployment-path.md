Type: research
Status: resolved
Assigned to: Codex
Labels: wayfinder:research
Parent: ../map.md
Blocked by: —

## Question

Which currently available free hosting arrangement can run a small Rails/PostgreSQL plus React/TypeScript personal workspace securely enough for a portfolio demo, including secrets, database persistence, and a read-only seeded public demo?

## Answer

Deploy one Rails monolith with bundled React/TypeScript as a Render Free Web Service and persist Briefs in Neon Free Postgres. This supports secrets and seeded public content without Render Free Postgres's limited free period; accept approximately one-minute cold starts, an ephemeral service filesystem, and free-tier usage limits. Research: [Free deployment](../research/free-deployment.md).
