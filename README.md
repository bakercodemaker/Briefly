# Briefly

Briefly is a private Personal Workspace for creating detailed, source-faithful Briefs from selected public YouTube videos.

## Local development

Briefly is a localhost-only Rails application. The supported runtime is Docker Compose with the app's Ruby, Rails, SQLite, Tailwind CSS, and Solid Queue worker process inside the container.

Configure the local owner password and optional Gemini key:

```sh
cp .env.example .env
docker compose up --build
```

The container installs dependencies, prepares the SQLite database, and starts the development processes.

Open <http://localhost:3000>.

Run one-off Rails commands inside the same app runtime:

```sh
docker compose run --rm web bin/rails test
```

Inside the container, `bin/dev` runs the Rails server, CSS build watcher, and `bin/jobs start` as the explicit Solid Queue worker:

```text
Browser
  |
Rails web process
  |
SQLite database
  |
Solid Queue jobs process
  |
Gemini API, when GEMINI_API_KEY is configured
```

Run the automated checks with:

```sh
docker compose run --rm web bin/rails test
```

Gemini is only required to generate new Briefs. The existing workspace and saved Briefs remain readable without `GEMINI_API_KEY`; new submissions show a configuration message until the key is present.

## Portfolio Evidence

Screenshots of the locked workspace, unlocked workspace, and a completed Brief are tracked with ticket 06.
