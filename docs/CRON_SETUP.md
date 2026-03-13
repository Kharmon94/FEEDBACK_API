# Cron Jobs Setup

## Trial Reminder Emails

The trial reminder emails (15, 7, 3, 1 day before expiry, and on expiry) are sent via the cron endpoint. You must trigger it daily (e.g. via Railway Cron or an external scheduler).

**Endpoint:** `POST /api/v1/cron/trial_reminders`

**Authentication:** Set `CRON_SECRET` in your environment. Requests must include either:

- Header: `Authorization: Bearer <CRON_SECRET>`
- Query param: `?secret=<CRON_SECRET>`

**Example (Railway Cron or curl):**
```bash
curl -X POST "https://your-api.up.railway.app/api/v1/cron/trial_reminders" \
  -H "Authorization: Bearer $CRON_SECRET"
```

**Railway:** Add a Cron service that runs daily (e.g. `0 9 * * *` for 9am UTC) with the above command. Set `CRON_SECRET` in the Cron service's environment variables.
