# Docker-first Rails development research

## Question

Can the Personal News Workspace be built locally without installing Ruby or
Rails on the host, using Docker; what needs updating in the existing Rails 8
guide; how should that work with React/TypeScript; and does Docker change the
free hosting plan?

## Conclusion

Yes. Use Docker Desktop plus Compose for **local development**, and keep the
Rails-generated production `Dockerfile` for deployment. This is a good fit for
the project: the host only needs Docker Desktop (and Git/an editor), while
Ruby, Bundler, PostgreSQL, Node, and the JavaScript toolchain live in
containers.

The recommended application shape is a **Rails monolith with React/TypeScript
inside it**, not a separately deployed React SPA: Rails owns routes,
authentication, database access, and the Gemini API key; React renders the
interactive brief creation and reading UI. This is both the fastest MVP route
and the clearest portfolio story.

Docker does not itself add hosting cost. It standardises the artifact a host
runs. The relevant costs are an always-on application service, database, and
Gemini usage. For the portfolio MVP, Render Free web service + Neon Free
Postgres remains a viable $0 starting point, with deliberate cold-start and
quota trade-offs. It should not be described as production hosting.

## Assessment of the supplied guide

The guide's core approach is sound: bootstrap Rails in a disposable Ruby
container, bind-mount the source for development, and run PostgreSQL in
Compose. Its `ruby:4.0` tag is valid today, but the tutorial should be
modernised before using it.

| Guide item | Decision / correction |
| --- | --- |
| `ruby:4.0` | Pin both Ruby and Debian suite, for example `ruby:3.4.10-bookworm` (or `4.0.6-bookworm` if deliberately adopting Ruby 4). A floating major tag changes under a tutorial; keep `.ruby-version`, generation image, and development image aligned. Rails 8 requires Ruby 3.2 or newer. [Rails compatibility](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html) · [Ruby official image](https://hub.docker.com/_/ruby/) · [Ruby releases](https://www.ruby-lang.org/en/downloads/) |
| `docker-compose` | Use the current Docker Compose v2 command: `docker compose`. [Docker Compose quickstart](https://docs.docker.com/compose/gettingstarted/) |
| `depends_on: - db` | Add a Postgres `healthcheck` and depend on `condition: service_healthy`. Plain `depends_on` waits only for a container to run, not for Postgres to accept connections. [Docker Compose startup ordering](https://docs.docker.com/compose/how-tos/startup-order/) |
| Database password in YAML | Put local-only values in `.env` (committed `.env.example`, ignored `.env`), then use `DATABASE_URL` in Rails configuration. It is fine for a local dev password, never for a production secret. |
| `Dockerfile.dev` installs Bundler separately | The official Ruby image already includes Bundler. Retain `bundle install` after copying `Gemfile` and `Gemfile.lock`; do not add an unpinned redundant Bundler installation unless the app explicitly needs a version. [Ruby official image](https://hub.docker.com/_/ruby/) |
| only Ruby and PostgreSQL | Add Node to the **development** image because React/TypeScript must be compiled/bundled. Do not install Node, Ruby, or Rails on macOS. |
| duplicate PID removal | Keep PID removal once in the entrypoint; remove it from the Compose `command`. |
| published `5432` port | Optional. Omit it unless a host tool needs direct database access; Rails reaches `db:5432` on Compose's internal network. |
| Docker Desktop credential-store edit | Remove this from normal setup. It is a machine-specific Docker Desktop troubleshooting action, not a Rails setup step, and changing credential handling should be a last resort. |

## Recommended local setup

### 1. Generate the Rails app in Docker

Use an empty application directory and a pinned container. The exact Rails
minor will be pinned in `Gemfile.lock`; `~> 8.1` selects the current Rails 8.1
series at generation time. Rails 8 includes a production-ready Dockerfile, so
keep the generated `Dockerfile` rather than replacing it with the development
file. Rails describes that Dockerfile as the image used by its Kamal deployment
flow and notes that it includes Thruster in production. [Rails getting
started](https://guides.rubyonrails.org/getting_started.html) · [Rails 8 release
notes](https://guides.rubyonrails.org/8_0_release_notes.html)

The bootstrap container needs Node only if the generator is asked to install a
JavaScript bundler. The simplest Docker-only path is: generate the Rails app
with PostgreSQL and no JavaScript choice, bring up the dev image below (which
contains Node), then install the JavaScript bundle there:

```sh
# From an empty project directory; no host Ruby/Rails installation is needed.
docker run --rm -v "$PWD:/app" -w /app ruby:3.4.10-bookworm \
  sh -lc 'gem install rails -v "~> 8.1" && rails new . --force --database=postgresql --skip-javascript'

# Once compose is available and the dev image has been built:
docker compose run --rm web bin/rails javascript:install:esbuild
docker compose run --rm web npm install react react-dom
docker compose run --rm web npm install --save-dev typescript @types/react @types/react-dom
```

This deliberately avoids a local Node installation as well. Exact commands may
need a small adjustment if the chosen Rails release changes its generator
options; the design choice is stable: JS tooling runs inside `web`.

### 2. Use React and TypeScript within Rails

Install `jsbundling-rails` with esbuild and place the React entry point and
components under `app/javascript/` (for example,
`app/javascript/application.tsx` and `app/javascript/components/`). Rails
serves the compiled assets and the Rails controller serves the application
page. The brief-creation request can initially be a normal Rails form or a
small JSON endpoint used by React.

This is the appropriate Rails-supported bundling route because React JSX and
TypeScript need transpilation. Rails identifies `jsbundling-rails` as the fit
for applications using TypeScript or React; its official repository documents
the supported Bun, esbuild, Rollup, and webpack installers, `bin/dev` for the
Rails server plus watcher, and automatic JavaScript builds during production
asset precompilation. [Rails asset pipeline guide](https://guides.rubyonrails.org/asset_pipeline.html) · [jsbundling-rails](https://github.com/rails/jsbundling-rails)

For this MVP, choose **esbuild** rather than a separate Vite/React application:
one repo, one deployment, no CORS/session split, and no extra environment or
hosting bill. Add a dedicated SPA only if later requirements genuinely need an
independent frontend.

### 3. Compose requirements

The development container must contain the project's Node runtime, PostgreSQL
client headers (for the `pg` gem), and build tools. Persist database data in a
named volume and avoid bind-mounting over container-managed dependencies:

```yaml
# compose.yaml — outline, not a production deployment file
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-postgres}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
      POSTGRES_DB: ${POSTGRES_DB:-news_workspace_development}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      interval: 5s
      timeout: 5s
      retries: 10
      start_period: 10s

  web:
    build:
      context: .
      dockerfile: Dockerfile.dev
    command: bin/dev
    volumes:
      - .:/app
      - bundle_cache:/usr/local/bundle
      - node_modules:/app/node_modules
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER:-postgres}:${POSTGRES_PASSWORD:-postgres}@db:5432/${POSTGRES_DB:-news_workspace_development}
    depends_on:
      db:
        condition: service_healthy

volumes:
  postgres_data:
  bundle_cache:
  node_modules:
```

The `healthcheck` is the important correction: Docker documents that Compose
otherwise starts dependencies in order but does not wait for them to be ready;
`service_healthy` makes it wait for the named health check. [Docker Compose
startup ordering](https://docs.docker.com/compose/how-tos/startup-order/)

`Dockerfile.dev` should use the same pinned Ruby base, install OS build
dependencies plus Node, copy the Gemfiles before `bundle install` for build
cache efficiency, and then use the PID-cleaning entrypoint. A named
`node_modules` volume prevents the source bind mount from hiding the
container-installed React/TypeScript packages. Use `bin/dev` only after the
generated `Procfile.dev` is set to run Rails and the esbuild watcher.

### 4. Normal local commands

```sh
docker compose build
docker compose up
docker compose exec web bin/rails db:prepare
docker compose exec web bin/rails test
docker compose exec web bin/rails console
docker compose down                 # keeps the database volume
```

Open `http://localhost:3000`. Use `docker compose down -v` only when
intentionally deleting all local database data.

## Deployment and cost implications

Local Compose is **not** the production deployment. Do not ship its bind
mounts, development command, or Postgres container to a free host. Commit the
Rails-generated production `Dockerfile`, set production secrets in the host's
dashboard, and run migrations as a deploy/release step.

| Option | Cost / behaviour verified from official docs | Recommendation |
| --- | --- | --- |
| Render Free web service + Neon Free Postgres | Render allows free Rails web services but gives 750 instance-hours per workspace/month and restricts persistent disks on free web services. Neon Free is $0 with 0.5 GB storage and 100 CU-hours/month, scaling to zero when idle. [Render Free](https://render.com/docs/free) · [Neon pricing](https://neon.com/pricing) | Recommended public portfolio/demo deployment. Expect cold starts from both services; database data remains in Neon rather than the container filesystem. |
| Render Free web + Render Free Postgres | Render's free Postgres has 1 GB but **expires after 30 days** and is then deleted after its grace period unless upgraded. [Render Free](https://render.com/docs/free) | Suitable only for a short demo, not the saved-brief library. |
| Railway or Fly.io | Railway's free use is a time-/credit-limited trial, then $1 monthly credit; Fly.io's legacy free allowances are not offered to new accounts. [Railway free trial](https://docs.railway.com/pricing/free-trial) · [Fly.io pricing](https://www.fly.io/docs/about/pricing/) | Do not present either as the dependable $0 path. |
| Rails/Kamal on a VPS | Rails' documented Kamal route needs a Docker-enabled Ubuntu LTS server (1 GB RAM+) and an image registry account. [Rails getting started](https://guides.rubyonrails.org/getting_started.html) | A good paid follow-up, not this MVP's free deployment plan. |

The Gemini API usage quota is independent of Docker and hosting. Keep the key
only in server-side environment variables; the React bundle must never contain
it. The public demo should be read-only seeded briefs, so no visitor can spend
the user's Gemini quota.

## Decision proposed for the map

Adopt Docker Desktop + `docker compose` for local development. Build a Rails
8.1 monolith with React/TypeScript via `jsbundling-rails` and esbuild. Preserve
the generated production Dockerfile for deployment. Publish a read-only demo
on Render Free backed by Neon Free, acknowledging cold starts and limits; this
does not alter the project's $0 MVP target.
