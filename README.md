# Feedback API

Rails 8.0.3 API (Ruby 3.3.0). Devise + JWT + OmniAuth, CORS, health, auth, locations, feedback, suggestions, onboarding, dashboard, admin.

## Setup (WSL)

Use Ruby 3.3.0 (e.g. `rbenv install 3.3.0` then `rbenv local 3.3.0`). In a new WSL terminal:

```bash
source ~/.bashrc
cd feedback_api
bundle install
rails db:migrate
rails server
```

Health: `GET /up`. API: `GET /api/v1/up`. Auth: `POST /api/v1/auth/sign_in`, `POST /api/v1/auth/sign_up`, `GET /api/v1/auth/me`.

## Production env

- `DATABASE_URL` — PostgreSQL (required in production)
- `FRONTEND_ORIGIN` — Allowed CORS origin(s)
- `RAILS_MASTER_KEY` or credentials
- `PORT` — Server port (default 3000)
- Optional: `REDIS_URL`, `RAILS_LOG_LEVEL`, `JOB_CONCURRENCY`, `RAILS_MAX_THREADS`
- OAuth: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`
- S3 (Active Storage): `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_BUCKET` (omit for local disk storage)

## Docker

Build and run with Ruby 3.3.0; expects `DATABASE_URL`, `RAILS_MASTER_KEY`, `PORT` at runtime.
