Type: research
Status: resolved
Assigned to: Codex
Labels: wayfinder:research
Parent: ../map.md
Blocked by: —

## Question

What official Gemini API capability, request shape, free-tier limits, security constraints, and failure cases govern analysing a user-pasted public YouTube URL for this MVP, and what is the smallest reliable implementation path?

## Answer

Gemini API accepts a public YouTube URL as a video input, so the manual MVP is feasible. This capability is Preview and free-tier limits and pricing can change; public video access, quotas, and processing errors therefore need explicit queued status and retry treatment. Keep the key and request logic in a server-side adapter, never in React. Research: [Gemini YouTube ingestion](../research/gemini-youtube-ingestion.md).
