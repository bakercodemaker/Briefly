# Briefly

Briefly is a private Personal Workspace for creating detailed, source-faithful Briefs from selected public YouTube videos. A read-only Demo Library gives recruiters a safe public view of the finished reading experience.

## Local development

For the complete setup, testing, logging, debugging, and container lifecycle guide, see [DEVELOPMENT.md](DEVELOPMENT.md).

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
