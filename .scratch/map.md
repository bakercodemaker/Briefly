## Destination

Reach a build-ready, one-week MVP specification for a personal YouTube-to-detailed-brief workspace that is genuinely useful to Bartosz and demonstrable as a completed public portfolio project.

## Notes

Plan only; implementation starts after this map is clear. Use `grilling` and `domain-modeling` for every human decision, `prototype` for the reading experience, and `research` against primary sources for Gemini and hosting facts. Rails + PostgreSQL + React/TypeScript are the intended stack. Preserve the terms in `CONTEXT.md`.

## Decisions so far

<!-- Resolved decision tickets are indexed here. -->

- [Verify Gemini YouTube ingestion](issues/01-verify-gemini-youtube-ingestion.md) — A server-side Gemini adapter can analyse a pasted public YouTube URL on the free tier, but the Preview capability requires queued status/retry handling and must not expose the API key.
- [Assess free deployment path](issues/02-assess-free-deployment-path.md) — Use a single Rails application with bundled React/TypeScript on Render Free Web Service and a persistent Neon Free Postgres database; accept cold starts and ephemeral local disk.
- [Assess Dockerized local development](issues/06-assess-dockerized-local-development.md) — Docker-first development needs no host Ruby/Rails and should use modern Compose conventions; deploy source directly to the free host rather than treating Docker as a hosting requirement.
- [Prototype on-demand Brief flow](issues/03-prototype-on-demand-brief-flow.md) — Use the workbench layout: persistent URL submission and compact saved library frame the currently open Brief, which remains the dominant reading surface.
- [Define MVP product and data contract](issues/04-define-mvp-product-and-data-contract.md) — Save immutable, detailed source-faithful Briefs from one public YouTube URL with explicit lifecycle and retry states; organise completed Briefs by channel and show a persistent source-and-safety notice.

## Not yet specified

- The minimum production checks, demo content, README, screenshots, and walkthrough that make the project publishable.

## Out of scope

- Channel monitoring and scheduled creation of Briefs — defer until the manual workflow proves useful.
- Sources beyond YouTube, including X posts and text articles — defer until the YouTube ingestion boundary is proven.
- Brief conversation and source-linked saved extractions — defer until after the MVP.
- Multi-user accounts and public interactive summarisation — defer to avoid SaaS operations, shared API-cost exposure, and privacy scope.
