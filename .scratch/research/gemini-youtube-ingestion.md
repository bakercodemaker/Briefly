# Gemini YouTube ingestion — feasibility research

Checked 2026-08-18. Sources below are Google’s official Gemini API documentation.

## Decision-ready conclusion

The personal MVP can accept a pasted **public YouTube URL** and ask Gemini to generate the saved brief. Google documents this as a direct video input, so the MVP does not need to download video or independently obtain a transcript. This integration is currently **Preview** and free of charge, however Google explicitly says its pricing and rate limits are likely to change. It is therefore suitable for a private, limited-use MVP—not a public arbitrary-submission feature whose availability or cost is promised.

## Capability and request shape

- Gemini supports extracting information from video, answering questions about its content, and referring to timestamps. It processes audio and visual streams; it is not documented as a transcript-only integration. [Video understanding](https://ai.google.dev/gemini-api/docs/video-understanding)
- A direct YouTube URL is a supported video input method specifically for public YouTube videos. Send the URL as a `video` input part with a `uri`, accompanied by the brief-generation prompt, to `POST https://generativelanguage.googleapis.com/v1beta/interactions`. The official example uses `interactions.create` with a Flash model. [Official request example](https://ai.google.dev/gemini-api/docs/video-understanding#youtube)
- For this Rails app, make that request from a server-side service/background job, then persist the response and application-owned metadata. The API response is not a durable application record.
- Use one video per generation request. Although Gemini 2.5+ accepts up to ten videos in one request, Google identifies one video per prompt as the best practice for optimal results. [Video understanding best practices](https://ai.google.dev/gemini-api/docs/video-understanding)

## Free tier, price, and quota constraints

- The YouTube URL feature is Preview and presently available at no charge; Google says pricing and rate limits are likely to change. [YouTube URL feature note](https://ai.google.dev/gemini-api/docs/video-understanding#youtube)
- On the free tier, no more than **eight hours of YouTube video per day** can be submitted. Paid tier has no video-length cap. [YouTube URL limitations](https://ai.google.dev/gemini-api/docs/video-understanding#youtube)
- Free-tier availability is model-specific. Current request limits are controlled per Google Cloud project (not per API key) and measured across requests per minute, input tokens per minute, and requests per day; daily limits reset at midnight Pacific. Google directs developers to AI Studio to see the active limits, so do not hard-code or market a numerical request quota. [Rate limits](https://ai.google.dev/gemini-api/docs/rate-limits)
- Free-tier input/output tokens are free only for models currently available on that tier, and Google says free-tier content is used to improve its products; paid-tier content is not. This reinforces keeping the initial tool private and disclosing the data-handling choice. [Gemini API pricing](https://ai.google.dev/gemini-api/docs/pricing)

## API-key security

- Keep `GEMINI_API_KEY` exclusively on the Rails server (environment variable locally; deployment secret store in production). Never send it to React/browser code and never commit it. Google explicitly says client-side keys can be extracted and recommends a backend proxy for web/mobile apps. [API-key security guidance](https://ai.google.dev/gemini-api/docs/api-key#security-and-secret-management)
- New AI Studio keys are authorization keys, restricted to the Gemini API by default. Apply suitable origin/IP restrictions where deployment infrastructure allows, set billing alerts, and rotate/disable an exposed key. [API key types and restrictions](https://ai.google.dev/gemini-api/docs/api-key)

## Expected failures and product handling

| Condition | Constraint / likely result | MVP handling |
| --- | --- | --- |
| Private or unlisted video | Unsupported: only public videos are accepted. | Validate URL shape; on API rejection, retain no brief and present a clear “public videos only” message. |
| Free-tier video allowance consumed | At most eight hours of YouTube video/day. | Return a retry-later state; do not create a completed brief. |
| Project rate limit | Any RPM, input-TPM, or RPD limit can cause a rate-limit failure. | Run one background job per submission; use bounded retry/backoff for `429 RESOURCE_EXHAUSTED`, then show a recoverable quota error. |
| Preview feature/model behavior changes | Google says pricing/rate limits are likely to change. | Centralize the Gemini client/model choice; display a generic provider failure and log enough context to update the adapter. |
| Fine visual detail / quick cuts | Default video understanding samples one frame per second and may miss rapid visual changes. | Do not claim exhaustive visual fidelity; the product prompt should frame the result as a model-generated summary of source content. |
| Model safety or generation quality | Google cautions that generated output may be inaccurate, biased, or offensive and recommends post-processing/human evaluation. | Allow the owner to review/delete a brief; avoid treating generated financial, health, or political material as verified advice. |

Sources for the last two rows: [Video technical details](https://ai.google.dev/gemini-api/docs/video-understanding#technical-details-about-videos) and [Gemini safety guidance linked from the video documentation](https://ai.google.dev/gemini-api/docs/safety-guidance).

## MVP recommendation

Proceed with direct public-URL ingestion, one video/job, on the free tier. Use a single server-owned Gemini key, no public generation route, and a durable job state (`queued`, `processing`, `completed`, `failed`) so quota/provider errors remain visible and retryable. Treat the Gemini integration as an adapter behind an application service because the current YouTube capability is Preview.
