# API Routes

## Root-level (no /api/v1 prefix)

| Method | Path | Controller#Action |
|--------|------|-------------------|
| GET | /auth | OmniAuth (google_oauth2, callback, failure) |
| POST | /auth/password | api/v1/auth#request_password_reset |
| PUT | /auth/password | api/v1/auth#reset_password |
| POST | /auth/confirm/resend | api/v1/auth#resend_confirmation |

## /api/v1

| Method | Path | Controller#Action |
|--------|------|-------------------|
| POST | /api/v1/auth/sign_in | auth#sign_in |
| POST | /api/v1/auth/sign_up | auth#sign_up |
| POST | /api/v1/auth/password | auth#request_password_reset |
| PUT | /api/v1/auth/password | auth#reset_password |
| GET | /api/v1/auth/confirm | auth#confirm_email |
| POST | /api/v1/auth/confirm/resend | auth#resend_confirmation |
| GET | /api/v1/auth/me | auth#me |
| GET | /api/v1/auth/:provider/callback | auth#omniauth_callback |
| GET | /api/v1/auth/failure | auth#failure |
| POST | /api/v1/admin/users | admin/users#create |
| GET | /api/v1/admin/users | admin/users#index |
| GET | /api/v1/admin/users/:id | admin/users#show |
| PATCH/PUT | /api/v1/admin/users/:id | admin/users#update |
