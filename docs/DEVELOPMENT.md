# Briefly developer guide

Briefly is a Rails 8 application with PostgreSQL, a small React/TypeScript entry point, and Tailwind CSS. Docker Compose runs the application stack. The `web` container runs three development processes together: Rails, the JavaScript watcher, and the CSS watcher.

## Prerequisites and first-time setup

Install and start Docker Desktop. No host Ruby, Node, Rails, or PostgreSQL installation is needed.

Create your local secrets file once:

```sh
cp .env.example .env
```

Set a private `OWNER_PASSWORD`. Set `GEMINI_API_KEY` when you want real Brief generation; never commit `.env` or expose that key in browser code.

## Start the application

If the image has already been built and only the database is running, start the web application with:

```sh
docker compose up -d web
```

This starts the `web` container in the background, reuses the running `db` container, and publishes the application at <http://localhost:3000>. To watch its startup output immediately:

```sh
docker compose logs -f web
```

If neither service is running, this also works and starts both services:

```sh
docker compose up -d
```

Use the foreground form when you want the startup and live logs in the current terminal:

```sh
docker compose up
```

Run `docker compose up -d --build` instead only after changing container dependencies or when the image does not exist yet.

Confirm that it is ready:

```sh
docker compose ps
curl -I http://localhost:3000/up
```

The expected `docker compose ps` output includes a `web` row with `0.0.0.0:3000->3000/tcp`.

## First-time build and database setup

Build and start the stack, then prepare the development database:

```sh
docker compose up --build
docker compose run --rm web bin/rails db:prepare
```

The first command runs in the foreground and prints Rails, JavaScript, and CSS logs. Leave it running while developing. Once it reports that Puma is listening, open <http://localhost:3000>.

To run in the background instead:

```sh
docker compose up -d --build
docker compose run --rm web bin/rails db:prepare
```

The database is intentionally not published to the host; Rails reaches it as `db` inside the Compose network.

## Using the local app

1. Open <http://localhost:3000> and follow the Personal Workspace link.
2. Unlock it with `OWNER_PASSWORD` from `.env`.
3. Paste a public YouTube URL to queue a Polish Brief. A real request needs `GEMINI_API_KEY`.
4. Browse saved Briefs in the Personal Brief Library. The public, read-only demo route is <http://localhost:3000/demo>.

For quick UI work without a real Gemini request, use the existing integration tests or create records from the Rails console.

## Everyday development

Rails reloads Ruby, ERB, and configuration changes in development. The `js` and `css` watcher processes rebuild the React/TypeScript and Tailwind assets after source changes. You normally do not need to restart `web` after editing application code.

Run a Rails console inside the application container:

```sh
docker compose exec web bin/rails console
```

Useful console examples:

```ruby
AnalysisRequest.order(created_at: :desc).first
Brief.order(created_at: :desc).first
```

Run database tasks in the container:

```sh
docker compose exec web bin/rails db:migrate
docker compose exec web bin/rails db:prepare
docker compose exec web bin/rails routes
```

### Apply a new migration

After pulling or adding a migration, run it once against the development database:

```sh
docker compose run --rm web bin/rails db:migrate
```

`run` starts a one-off container from the `web` service definition, so it has the same Ruby version, gems, mounted project files, and Compose-network access to the `db` service as the application. `--rm` deletes that temporary command container once Rails finishes. The database data remains in its named volume.

You do not need to rebuild the image or restart `web` for a migration alone. Rebuild only after changing the Dockerfile or dependencies. Restart `web` only if you want to refresh a running process; Rails normally reloads application code during development.

After changing dependencies, rebuild the image and restart the stack:

```sh
docker compose up -d --build
```

## Tests and quality checks

The primary test seam is Rails integration tests: assert visible HTTP behavior, authorization, persisted state, and rendered responses rather than React internals or Gemini SDK calls.

Run one test file while iterating:

```sh
docker compose run --rm -e RAILS_ENV=test web bin/rails test test/integration/brief_generation_test.rb
```

Run one named test:

```sh
docker compose run --rm -e RAILS_ENV=test web bin/rails test test/integration/analysis_requests_test.rb -n /archives_a_completed_request/
```

Run the complete Rails suite before handing off work:

```sh
docker compose run --rm -e RAILS_ENV=test web bin/rails test
```

Run TypeScript and Ruby style checks:

```sh
docker compose run --rm web yarn typecheck
docker compose run --rm web bin/rubocop
```

`docker compose run --rm` starts a disposable command container and removes it when the command finishes. It does not stop your running `web` container.

## Logs and debugging

The `web` service owns Rails, esbuild, and Tailwind processes, so its Compose logs contain server requests/errors plus JavaScript and CSS build errors:

```sh
docker compose logs -f web
docker compose logs --tail=200 web
```

Rails also writes its development log to the mounted workspace:

```sh
docker compose exec web tail -n 200 -f log/development.log
```

For React/TypeScript runtime errors, use the browser's Developer Tools Console and Network panels. For TypeScript compile errors and asset-watch failures, use `docker compose logs -f web`; esbuild and Tailwind run there, not as separate Compose services.

For database inspection, open PostgreSQL's client inside its container:

```sh
docker compose exec db psql -U briefly -d briefly_development
```

Helpful SQL commands:

```sql
\dt
SELECT id, lifecycle_state, source_url, created_at FROM analysis_requests ORDER BY created_at DESC;
SELECT id, source_title, source_channel, created_at FROM briefs ORDER BY created_at DESC;
```

If a request appears stuck, inspect the associated `AnalysisRequest` in the Rails console or database and then read the `web` logs. In development the Rails process executes queued work; production uses the configured database-backed queue.

## Stop and restart containers

Stop the stack but preserve PostgreSQL data and named volumes:

```sh
docker compose stop
```

Start the stopped containers again:

```sh
docker compose start
```

Recreate only the application container after a configuration, dependency, or process problem:

```sh
docker compose up -d --build --force-recreate web
```

Recreate the whole stack while preserving the database volume:

```sh
docker compose down
docker compose up -d --build
```

`docker compose down -v` also deletes named volumes, including the local PostgreSQL data. Use it only when you intentionally want a clean local database; afterwards run `docker compose run --rm web bin/rails db:prepare`.

## A simple debugging loop

1. Reproduce the behavior in the browser or with one focused integration test.
2. Read `docker compose logs -f web` and, for request/database detail, `log/development.log`.
3. Inspect state with `bin/rails console` or `psql`.
4. Add or update a focused application-boundary test before changing behavior.
5. Run that file repeatedly, then run the full Rails suite, TypeScript check, and RuboCop before committing.

For a failure that follows an environment or dependency change, restart/rebuild `web` first. For a migration error, run `docker compose exec web bin/rails db:migrate` (or `db:prepare` for initial setup).
