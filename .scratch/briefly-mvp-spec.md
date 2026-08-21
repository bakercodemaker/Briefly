# Briefly MVP — build specification

**Status:** ready-for-agent

**Labels:** ready-for-agent

**Source:** [Wayfinder map](map.md)

## Problem Statement

Bartosz wants to catch up on selected public YouTube videos without watching each one in full, while retaining the speaker's concrete claims, figures, names, caveats, and reasoning. Existing short summaries are too shallow and a generic AI demo would not be credible as a personal portfolio project. The product must remain a private, single-owner Personal Workspace while allowing recruiters to inspect a safe, useful public demonstration without creating accounts or consuming Gemini API budget.

## Solution

Build Briefly as one Rails application with bundled React/TypeScript. The owner pastes one public YouTube URL into the password-gated Personal Workspace. The app records an Analysis Request, asynchronously asks Gemini to create a detailed source-faithful Brief, and saves the completed Brief immutably for later reading in the Brief Library.

The same deployment exposes a separate public Demo Library of seeded, English Briefs. It is read-only, contains no personal reading history or live generation form, and makes the completed product understandable through a concise walkthrough. The deployed app runs on a Render Free Web Service with Neon Postgres; all secrets remain server-side.

## User Stories

1. As the owner, I want to unlock the Personal Workspace with one private password, so that my reading history and Gemini-powered actions remain private without maintaining user accounts.
2. As a recruiter, I want to open the Demo Library without credentials, so that I can inspect the product without asking for access.
3. As the owner, I want to paste one public YouTube URL, so that I can request a Brief from a source I chose.
4. As the owner, I want clear validation feedback for a malformed or unsupported URL, so that I know when an Analysis Request cannot start.
5. As the owner, I want each Analysis Request to visibly move through queued, processing, completed, or failed states, so that provider work never feels lost or synchronous.
6. As the owner, I want a temporary provider or quota failure to retry a small bounded number of times, so that ordinary transient failures recover without my intervention.
7. As the owner, I want an exhausted temporary failure to offer an explicit retry, so that I retain control without the system retrying forever.
8. As the owner, I want invalid, private, unlisted, or inaccessible sources to fail clearly without pointless retrying, so that I understand the source boundary.
9. As the owner, I want the completed Brief to open in the same work session, so that the on-demand summary flow remains action-first.
10. As the owner, I want a detailed Polish Brief by default, so that I can catch up quickly in my preferred reading language.
11. As the owner, I want each Brief to preserve source claims, figures, names, caveats, attribution, and reasoning, so that it remains source-faithful rather than becoming generic commentary.
12. As the owner, I want each Brief to include thematic sections and five to ten key conclusions, so that a long source has both structured depth and a quick scan path.
13. As the owner, I want the source URL and captured source metadata retained with the Brief, so that I can judge and revisit its origin.
14. As the owner, I want completed Briefs to remain immutable, so that the saved reading record remains a faithful generated artifact.
15. As the owner, I want to archive a Brief and later request a new generation, so that I can remove unwanted material from active history without editing generated content in place.
16. As the owner, I want the Brief Library grouped by source channel and ordered newest-first within each channel, so that I can find prior reading naturally.
17. As the owner, I want a compact Brief preview in the library, so that I can decide which saved Brief to open.
18. As the owner, I want the URL composer and saved library to remain visible around the open Brief, so that creation and retrieval stay secondary to focused reading rather than becoming a dashboard.
19. As any Brief reader, I want a persistent source-and-safety notice, so that I understand the content is generated from a linked source and is not verified advice.
20. As a recruiter, I want three to five curated English Demo Library Briefs drawn from genuinely public YouTube videos, so that I can assess the complete reading experience.
21. As a recruiter, I want Demo Library Briefs to be source-linked and clearly labelled as generated, so that I can assess their provenance and limitations.
22. As a recruiter, I want the public product to explain the private workflow without offering public generation, so that I understand the value proposition without being able to spend the owner's API quota.
23. As a visitor to the deployed product, I want a clear expectation when the free host is waking from a cold start, so that a temporary delay is not mistaken for a broken demo.
24. As the owner, I want deployment configuration and Gemini credentials held only in server-side environment variables, so that the browser and repository never expose the API key.
25. As the portfolio author, I want a README, architecture diagram, screenshots, and short walkthrough video, so that the product remains understandable even when the demo is cold or the provider is unavailable.

## Implementation Decisions

- Use a single Rails monolith, with React/TypeScript bundled into the application rather than a separately deployed SPA. Docker-first local development supplies Rails, Node, and Postgres without requiring host Ruby/Rails; production deploys source directly rather than Docker hosting.
- Model an Analysis Request separately from a completed Brief. An Analysis Request accepts exactly one pasted public YouTube URL and has the visible lifecycle `queued`, `processing`, `completed`, or `failed`.
- Persist the original URL; captured source title, channel, publication date, and duration; request time; output language; lifecycle state; failure/retry information; and the full immutable generated Brief. Store public/demo visibility separately from personal ownership so that public reads never expose private records.
- Submit provider work through a database-backed asynchronous queue running within the one Rails web service. Persist state before provider work; a restart or deploy may delay processing, but cannot silently discard the request. Do not add Redis, object storage, a separate worker service, or a scheduler for this MVP.
- Isolate Gemini behind a server-side adapter. It accepts one public YouTube URL per request, centralizes the Preview model/request choice, maps provider failures into application-owned outcomes, and never exposes the API key to React/browser code.
- Use bounded automatic retry only for temporary provider and rate-limit failures. Private, unlisted, invalid, and inaccessible videos are terminal failures. An explicit owner retry creates another attempt only after automatic recovery is exhausted.
- Generate a source-faithful Markdown Brief from the approved detailed Polish prompt. Do not add outside fact checking, invented context, or advice. Personal Workspace Briefs default to Polish; Demo Library Briefs are English; each Brief retains its chosen output language.
- Use the selected workbench interaction design: a persistent, compact URL composer and compact saved library frame the open Brief, which is the dominant reading surface. Preserve responsive behavior for narrow screens.
- Keep public `/demo` behavior distinct from the password-protected Personal Workspace. Protect all private creation, retry, archiving, and personal-library reads with one application-level owner password stored only in deployment environment variables. Do not build accounts, roles, registration, password reset, or public write endpoints.
- Seed three to five curated English Demo Library Briefs from public sources. They are read-only, source-linked, clearly generated, and never derived from the owner's personal history.
- Deploy to a Render Free Web Service backed by Neon Free Postgres. Store the database URL, Rails secrets, Gemini key, and owner password as deployment secrets. Treat service local disk as ephemeral. Describe cold starts and free-tier limits in public-facing project material.
- Build in vertical order: protected source submission through saved completed Brief first; then library/retrieval and failure/retry behavior; then seeded Demo Library and portfolio evidence. If time is constrained, retain the working owner flow and public seeded demo before visual refinements or extra samples.

## Testing Decisions

- The primary test seam is the Rails application boundary. Tests assert observable HTTP-visible behavior, authorization, persisted state, and rendered/public responses rather than React component internals, queue implementation details, or Gemini SDK calls.
- Replace the Gemini adapter with a fake at this seam. The fake must allow tests to drive a successful generation, a transient rate-limit/provider failure, and a terminal source failure deterministically.
- Verify owner-gated behavior end to end at the application boundary: unauthenticated users cannot create, retry, archive, or read personal Briefs; the owner can; and public readers can only see the seeded Demo Library.
- Verify the Analysis Request lifecycle as externally visible behavior: submission creates a queued request; processing leads to one immutable saved Brief; temporary failures use bounded retries; terminal failures do not retry; and manual retry is offered only where recoverable failure is exhausted.
- Verify the generated-brief contract at the application boundary: source metadata, output language, source link, structured content, key conclusions, and source-and-safety notice are present; completed Brief content cannot be edited.
- Verify Brief Library behavior: only completed personal Briefs appear, grouping is by channel, ordering is newest-first within a channel, and opening a preview reaches the full Brief.
- Verify `/demo` remains read-only and contains no live generation route or private data. Include a production smoke test for owner submission, public demo access, and cold-start/waking messaging.
- There is no existing application test prior art because the repository currently contains planning and prototype artifacts only. Establish Rails request/integration tests at this seam, supplementing them with a small number of focused adapter/service tests where provider failure classification cannot be expressed at the HTTP boundary alone.

## Out of Scope

- Channel monitoring, scheduled Brief creation, and subscriptions.
- Sources other than YouTube, including X posts and text articles.
- Brief conversation, saved source-linked extractions, owner-authored annotations, editing generated Briefs, tags, search, and inferred topic taxonomies.
- Multi-user accounts, public interactive summarisation, public API access, shared API costs, and SaaS operations.
- External fact checking, independent analysis, or advice beyond the source material.
- Redis, a separate worker or scheduler service, object storage, separate frontend deployment, and persistent service-disk storage.

## Further Notes

- Gemini public-YouTube analysis is a Preview capability. Free-tier limits, model availability, pricing, and behavior can change; present provider failures honestly and keep the integration concentrated in the adapter.
- The free tier accepts only public YouTube videos and limits submitted YouTube duration. It is suitable for the owner's low-volume manual workflow, not an unlimited public service.
- Google states that free-tier content may be used to improve its products. The product must retain its source-and-safety notice and keep the workflow private; the README should disclose the deployment and provider limitations succinctly.
- Release evidence consists of the deployed URL, concise README, architecture diagram, screenshots, and short walkthrough video. The Demo Library should provide value even if the host is waking or live Gemini processing is temporarily unavailable.
