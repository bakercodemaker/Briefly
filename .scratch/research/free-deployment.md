# Free deployment research

Researched 2026-08-18. This compares genuinely $0 currently available paths for a small Rails/Postgres application with a React/TypeScript UI, a private write path, and a public read-only demo. It assumes React is bundled into the Rails app, rather than deployed as a separately hosted SPA.

## Recommendation: Render Free web service + Neon Free Postgres

Deploy a single Rails web app (including the React/TypeScript client assets) as a **Render Free Web Service**, and use a **Neon Free** Postgres project for all persisted briefs and demo data. Store `DATABASE_URL`, the Gemini key, Rails credentials/master key, and any simple private-demo password only as Render environment variables. Render documents both Rails support and its environment-variable/secret facility. [Render free deployment](https://render.com/docs/free) · [Render environment variables and secrets](https://render.com/docs/configure-environment-variables)

Why this is the best MVP route:

- It is one deployed application and one URL, so there is no API/CORS/auth split to build just to host React separately.
- The database remains free without a fixed 30-day expiry: Neon’s Free plan is $0 with no time limit or card required, includes 0.5 GB storage and 100 CU-hours/month per project, and scales compute to zero after five minutes idle. [Neon pricing](https://neon.com/pricing)
- Render explicitly supports Rails web services, public `onrender.com` URLs, custom domains and managed TLS on Free. [Render web services](https://render.com/docs/web-services) · [Render free deployment](https://render.com/docs/free)
- A single persisted Rails database can safely hold both a private user’s briefs and 3–5 seeded read-only public examples, distinguished by an explicit visibility/owner field. No extra hosting service is necessary.

### Operational constraints to accept explicitly

- The app sleeps after 15 minutes without inbound traffic. The next request takes about one minute to wake it, so the public demo needs a small “waking up” expectation. [Render free deployment](https://render.com/docs/free)
- Render’s filesystem is ephemeral; never store briefs, uploads, SQLite, or generated artifacts only on disk. Store relational data in Neon and avoid file uploads in this MVP. [Render free deployment](https://render.com/docs/free)
- A Render workspace gets 750 free service-hours/month. It also has included bandwidth/build limits; external calls (including to Neon and Gemini) count as service-initiated public traffic and unusually high traffic can trigger suspension. This is acceptable for single-user/ad-hoc generation and a low-traffic recruiter demo, not a public summarisation service. [Render free deployment](https://render.com/docs/free)
- Neon has 0.5 GB storage and 100 CU-hours per project each month. This is ample for text briefs but usage should be monitored; it is not a promise of unlimited production capacity. [Neon pricing](https://neon.com/pricing)
- Keep Gemini calls behind the authenticated/private create route. The public demo should expose only already-seeded briefs and never the API key or a form that can spend the owner’s Gemini quota.

## Viable alternatives

| Path | What is free | Why not the primary MVP choice |
| --- | --- | --- |
| **Render Web Service + Render Postgres** | Rails web service and 1 GB Postgres are free. | The free Postgres database expires 30 days after creation, has no backups, and is deleted after a further 14-day grace period unless upgraded. This is unsuitable for a portfolio URL and personal reading history that should last. [Render free deployment](https://render.com/docs/free) |
| **Render Web Service + Supabase Free Postgres** | Render hosts Rails; Supabase gives 500 MB database on Free. | It can work, but Supabase pauses Free projects that have insufficient database activity over seven days; recovery requires dashboard action. The on-demand use case may trigger this, so Neon has the gentler default for this project. [Supabase pricing](https://supabase.com/pricing) · [Supabase project pausing](https://supabase.com/docs/guides/platform/free-project-pausing) |
| **Koyeb Free Web Service + Koyeb Free Postgres** | One 512 MB/0.1 vCPU web service and one 0.25 vCPU/1 GB-RAM Postgres instance; database allows 1 GB stored data. | It is a credible all-in-one backup option, including encrypted secret storage. But the web instance sleeps after one hour, has only 0.1 vCPU, and the free database is limited to **five compute hours/month**. That makes it less forgiving for Rails builds/requests and demo visits. [Koyeb instances](https://www.koyeb.com/docs/reference/instances) · [Koyeb databases](https://www.koyeb.com/docs/databases) · [Koyeb secrets](https://www.koyeb.com/docs/reference/secrets) |
| **Fly.io** | No current generally available ongoing free path. | Fly.io says the former plans/free allowances are deprecated; the cited $5 trial credit is attached to a $5/month Hobby plan. Do not select it for a “free to publish” MVP. [Fly.io billing](https://fly.io/docs/about/billing/) |

## Deployment shape to carry into architecture planning

```text
Browser (private writer / public demo reader)
                 |
       one Render Rails web service
       (React/TS assets bundled with Rails)
          |                     |
     Neon Postgres       Gemini API
  briefs + demo data     key in Render secret
```

Use production migrations during deploy/release, seed the public briefs from a controlled Rails seed task, and make the demo library read-only in application authorization. No background worker, scheduler, Redis, object storage, separate React deployment, or persistent disk belongs in this MVP.

## Decision

Choose **Render Free Web Service + Neon Free Postgres**, with a Rails-monolith deployment and React/TypeScript compiled into it. Document the cold-start and free-tier limits prominently in the README/demo; reassess a paid host only when the tool needs reliable instant access, background channel monitoring, or public user-generated summaries.
