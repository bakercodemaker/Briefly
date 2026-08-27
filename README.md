# Briefly

Briefly is a private, single-owner workspace for turning public YouTube videos into detailed, source-faithful Briefs. The interface is English; generated Briefs default to Polish so the owner can read them quickly.

## See the product

The application has one product mode: a password-gated Personal Workspace.

![Locked workspace](docs/screenshots/locked-workspace.png)

![Unlocked Personal Workspace](docs/screenshots/unlocked-workspace.png)

![Completed Brief](docs/screenshots/completed-brief.png)

## Run locally

Briefly uses native Rails, SQLite, and Solid Queue. Ruby, Node, and Yarn must be installed locally.

```sh
cp .env.example .env
bundle install
yarn install
bin/rails db:prepare
yarn build:css
```

Set `OWNER_PASSWORD` in `.env`. `GEMINI_API_KEY` is optional for reading existing Briefs and required only when submitting a new source.

For the simplest local start, use the convenience command, which runs the web process, CSS watcher, and jobs process together:

```sh
bin/dev
```

To see each process separately, run the web server and CSS watcher in separate terminals:

```sh
bin/rails server
```

```sh
yarn build:css:watch
```

In another terminal, start the explicit durable jobs process:

```sh
bin/jobs start
```

Open <http://localhost:3000>, unlock the workspace, and paste a public YouTube URL.

Run the test suite with:

```sh
bin/rails test
```

## How it works

1. The owner submits a public YouTube URL. The request is persisted as `queued` before any provider call.
2. Solid Queue stores the job in the same SQLite database and the separate jobs process claims it as `processing`.
3. `GenerateBriefJob` orchestrates the replaceable `GeminiAdapter` seam. A temporary provider failure receives one automatic retry, followed by one explicit manual retry option.
4. A completed Brief is immutable and remains in the Personal Brief Library. Archiving moves the request and Brief to Archived Briefs.

Only one queued or processing Analysis Request is allowed at a time. Invalid URLs, inaccessible sources, provider failures, and missing configuration produce visible product feedback rather than a request that stays mysteriously active.

## Local-first trade-offs

SQLite keeps setup portable and inspectable for a single owner. Solid Queue keeps generation durable across web-process restarts while remaining understandable as a local jobs process. This is intentionally not a hosted multi-user product: there is no public library, account system, external database, Redis service, dashboard, or horizontal worker runtime.

The Gemini adapter is tested at its HTTP boundary with controlled responses; integration tests exercise the user-visible Rails flow without network access or a provider key.
