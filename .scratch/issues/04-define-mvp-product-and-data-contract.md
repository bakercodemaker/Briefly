Type: grilling
Status: resolved
Assigned to: Codex
Labels: wayfinder:grilling
Parent: ../map.md
Blocked by: Verify Gemini YouTube ingestion

## Question

What exact MVP input, generated Brief structure, saved data, language handling, source-faithfulness guardrails, and error/retry behavior should the Rails application promise, given Gemini's actual YouTube capability?

## Answer

Accept one pasted public YouTube URL per Analysis Request. Persist the original URL; source title, channel, publication date, and duration; request time; output language; lifecycle status; and the full immutable generated Brief. Personal Briefs default to Polish; curated Demo Library Briefs are English. The generated output follows the supplied detailed, source-faithful Polish prompt: thematic Markdown sections and 5–10 key conclusions, preserving source claims, figures, names, caveats, and reasoning without external fact-checking.

Create each Brief asynchronously through a server-side Gemini adapter with `queued`, `processing`, `completed`, and `failed` states. Bounded automatic retries apply only to transient provider/rate-limit failures; an exhausted retry offers an explicit manual retry. Invalid, private, or inaccessible URLs fail clearly without retry. Completed Briefs are immutable in the MVP; the owner can archive them and later regenerate. Group the saved library by channel, newest first, without tags or search. Show a quiet persistent footer: “Generated from the linked source. It may contain errors and is not verified advice.”
