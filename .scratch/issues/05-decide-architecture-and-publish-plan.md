Type: grilling
Status: resolved
Assigned to: Codex
Labels: wayfinder:grilling
Parent: ../map.md
Blocked by: Verify Gemini YouTube ingestion; Assess free deployment path; Define MVP product and data contract; Prototype on-demand Brief flow

## Question

What architecture and release plan should make the agreed MVP fast to build, safe to operate privately, easy to demonstrate publicly, and credible as a completed portfolio project within its one-week timebox?

## Answer

Build one Rails monolith with bundled React/TypeScript, deployed as a Render Free Web Service with Neon Postgres. Keep the public Demo Library at `/demo`; protect every personal create, retry, delete, and library route behind one application-level owner password stored only in deployment environment variables. Do not create user accounts.

An Analysis Request is persisted first and processed asynchronously through a database-backed queue running within the single Rails web service. This retains the `queued`, `processing`, `completed`, and `failed` lifecycle and bounded retry behavior without Redis, a separate worker service, or a scheduler; deployments or restarts may delay work, but the persisted status remains visible and recoverable.

Build the vertical slice first: protected URL submission through Gemini to an immutable saved Brief, then reading/retrieval, then public demo seeding and release polish. Publish three to five English, source-linked, clearly generated Briefs from genuinely public YouTube videos; never expose the owner's private reading history or a public generation route.

The release bar is automated coverage of lifecycle transitions, authorization, and Gemini failure mapping, plus a manual production smoke test of owner submission, public read-only access, and cold-start messaging. Ship a README, concise architecture diagram, screenshots, and short demo video. If time runs short, preserve the working private vertical slice and seeded Demo Library before visual refinement, extra sample Briefs, or video polish.
