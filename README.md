# Briefly

Briefly is a private Personal Workspace for creating detailed, source-faithful Briefs from selected public YouTube videos. A read-only Demo Library gives recruiters a safe public view of the finished reading experience.

## Local development

For the complete setup, testing, logging, debugging, and container lifecycle guide, see [the developer guide](docs/DEVELOPMENT.md).

Docker Desktop is the only required host dependency.

```sh
cp .env.example .env
docker compose up --build
```

Open <http://localhost:3000>. In a second terminal, prepare the database once:

```sh
docker compose run --rm web bin/rails db:prepare
```

Run the automated checks with:

```sh
docker compose run --rm -e RAILS_ENV=test web bin/rails test
docker compose run --rm web yarn typecheck
```

## Production deployment

Briefly deploys as one Render Free Ruby web service with a Neon Free Postgres database. Render builds the Rails and bundled React/Tailwind assets, runs database migrations during the build (Free services do not support a pre-deploy command), and seeds the read-only Demo Library once after the first successful deployment. All persisted data, including Solid Queue data, uses Neon; Render's local disk is never used for application state.

```text
Browser (owner or public demo reader)
                 |
         Render Rails web service
      Rails + React/TypeScript assets
          |                 |
    Neon Postgres       Gemini API
 briefs, queue, cache   private server-side key
```

1. Create a Neon project in the region closest to your chosen Render region and copy its pooled `DATABASE_URL`.
2. Push this repository to GitHub, GitLab, or Bitbucket. Render needs a connected Git provider; this local repository does not include a remote.
3. In Render, create a Blueprint from the repository. It reads [`render.yaml`](render.yaml) and creates the Free `briefly` web service.
4. Provide these Blueprint secrets when prompted: `DATABASE_URL`, `RAILS_MASTER_KEY`, `GEMINI_API_KEY`, and a long random `OWNER_PASSWORD`. Never commit any of them. The Blueprint defaults `ALLOWED_HOSTS` to `briefly.onrender.com`; add a custom domain there before serving it.
5. After the first deployment, verify `https://<service>.onrender.com/up`, `/demo`, and the password-gated `/workspace`. The Demo Library seed hook runs once; later deployments preserve both public and private records.

The Free web service can sleep after inactivity, so its first request may take about a minute. The public landing page communicates this explicitly. This is a low-volume personal workspace and portfolio demo, not a public summarisation service: the owner-only workflow is the only path that can call Gemini. Gemini's YouTube analysis remains a Preview/free-tier capability, so availability, quotas, and data-use terms can change; provider failures are presented honestly and source material should be submitted only with that boundary understood.

### Production smoke test

After each first deployment or significant infrastructure change:

1. Open `/` and confirm the cold-start notice is visible.
2. Open `/demo` in a private browser window. Confirm it contains only the read-only curated Briefs and no form.
3. Unlock `/workspace` with `OWNER_PASSWORD`, submit a public YouTube URL, and confirm the request transitions through its visible lifecycle.
4. Force or wait for a recoverable provider failure and confirm the retry presentation, then confirm a successful Brief remains private and does not appear in `/demo`.

### Portfolio evidence after launch

Once the public URL is available, add three screenshots (landing page, public Demo Library, and unlocked Personal Workspace) and a short walkthrough video to the repository or README. Capture the public Demo Library in a private browser window and include the cold-start notice so the evidence remains useful when the free host or Gemini is temporarily unavailable.
