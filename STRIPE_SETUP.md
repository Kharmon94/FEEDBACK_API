# Stripe Products & Prices Setup

The "Plan does not have a Stripe price configured" error means your plans exist in the database but do not have Stripe Price IDs linked. Run the sync task to create Products and Prices in Stripe and update your plans.

## Prerequisites

- Ruby 3.3.0 (match your Gemfile)
- Stripe secret key available via one of:
  - **Environment variable:** `STRIPE_SECRET_KEY` (test) or `STRIPE_SECRET_KEY_LIVE` (live)
  - **Rails credentials:** add under `stripe:` in `rails credentials:edit`:
    ```yaml
    stripe:
      secret_key: sk_test_xxxx
      secret_key_live: sk_live_xxxx
    ```
- Plans seeded in the database (`rails db:seed`)

## Commands

### Test mode (default)
```bash
cd feedback_api
bundle exec rake stripe:sync_plans mode=test
```

Or pass key inline:
```bash
STRIPE_SECRET_KEY=sk_test_xxxx bundle exec rake stripe:sync_plans mode=test
```

### Live mode
```bash
bundle exec rake stripe:sync_plans mode=live
```

Or pass key inline:
```bash
STRIPE_SECRET_KEY_LIVE=sk_live_xxxx bundle exec rake stripe:sync_plans mode=live
```

## What it does

- Creates a Stripe Product for each plan (Starter, Pro, Business) with `metadata.plan_slug`
- Creates monthly and yearly recurring Prices using `monthly_price_cents` and `yearly_price_cents` from your plans
- Saves the Price IDs to your Plan records (`stripe_price_id_monthly`, `stripe_price_id_yearly`, or `_live` variants)

The task skips `free` and `enterprise` plans (they have no prices).

## On Railway / Production

Run the task once after deploy or when adding new plans:

```bash
# In Railway shell or a one-off command
bundle exec rake stripe:sync_plans mode=test
# or for live:
bundle exec rake stripe:sync_plans mode=live
```

Ensure `STRIPE_SECRET_KEY` (and `STRIPE_SECRET_KEY_LIVE` if using live) are set in your deploy environment variables.
