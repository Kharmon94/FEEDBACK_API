# Email Template Mapping: Design Repo → ActionMailer

This document maps each design email template to its purpose and the corresponding Rails mailer/action that should send it. The design repo's `email-templates/` folder is the **source of truth** for email content.

**Sync templates:** Run `feedback_api/scripts/sync-email-templates.ps1` to fetch all 20 templates from the design repo.

---

## Design Template Inventory

### Auth (Authentication & Onboarding)

| Template | Purpose | Current Rails Mailer | Notes |
|----------|---------|----------------------|-------|
| `auth/welcome.html` | Welcome new users after signup | `UserMailer#welcome` | Sent when user signs up or confirms email |
| `auth/email-verification.html` | Confirm email address (link with token) | `UserMailer#confirmation_instructions` | Sent when user registers with email verification enabled |
| `auth/password-reset.html` | Reset password (forgot password flow) | `UserMailer#reset_password_instructions` | Sent when user requests password reset |

### Trial Management

| Template | Purpose | Rails Mailer | Notes |
|----------|---------|--------------|-------|
| `trial/trial-15-days.html` | Trial reminder at 15 days left | `TrialMailer#trial_15_days_reminder` | Call from scheduled job |
| `trial/trial-7-days.html` | Trial reminder at 7 days left | `TrialMailer#trial_7_days_reminder` | Call from scheduled job |
| `trial/trial-3-days.html` | Trial reminder at 3 days left | `TrialMailer#trial_3_days_reminder` | Call from scheduled job |
| `trial/trial-last-day.html` | Trial ends tomorrow | `TrialMailer#trial_last_day_reminder` | Call from scheduled job |
| `trial/trial-expired.html` | Trial has ended, access lost | `TrialMailer#trial_expired` | Call from scheduled job |

### Billing

| Template | Purpose | Rails Mailer | Notes |
|----------|---------|--------------|-------|
| `billing/payment-successful-first.html` | First payment successful | `BillingMailer#payment_successful_first` | Call from Stripe webhook |
| `billing/payment-successful-recurring.html` | Recurring payment successful | `BillingMailer#payment_successful_recurring` | Call from Stripe webhook |
| `billing/payment-failed.html` | Payment failed, retry needed | `BillingMailer#payment_failed` | Call from Stripe webhook |
| `billing/subscription-upgraded.html` | Plan upgraded | `UserMailer#plan_changed` (upgrade case) | ✓ Wired |
| `billing/subscription-downgraded.html` | Plan downgraded | `UserMailer#plan_changed` (downgrade case) | ✓ Wired |
| `billing/subscription-cancelled.html` | Subscription cancelled | `BillingMailer#subscription_cancelled` | Call from cancel flow |
| `billing/renewal-reminder.html` | Upcoming renewal reminder | `BillingMailer#renewal_reminder` | Call from scheduled job |

### Feedback Notifications (To Business Owners)

| Template | Purpose | Current Rails Mailer | Notes |
|----------|---------|----------------------|-------|
| `feedback/new-negative-feedback.html` | New low-rating feedback (1–3 stars) | `FeedbackMailer#new_feedback` | ✓ Wired (rating ≤ 3 only) |
| `feedback/new-suggestion.html` | New suggestion from customer | `SuggestionMailer#new_suggestion` | ✓ Wired |
| `feedback/new-optin.html` | New newsletter/opt-in signup | `OptInMailer#new_optin` | ✓ Wired |

### Customer-Facing (To End Customers)

| Template | Purpose | Current Rails Mailer | Notes |
|----------|---------|----------------------|-------|
| `customer/feedback-confirmation.html` | "We received your feedback" | `FeedbackMailer#contact_me_acknowledgment` | ✓ Wired |
| `customer/optin-confirmation.html` | "Thanks for signing up" after opt-in | `OptInMailer#optin_confirmation` | ✓ Wired |

### Admin / Account (No Direct Design Template)

| Scenario | Purpose | Current Rails Mailer | Notes |
|----------|---------|----------------------|-------|
| Admin created account | New user created by admin with temp password | `UserMailer#admin_created_account` | Design has no template – keep current or create one |
| Account suspended | User account suspended | `UserMailer#account_suspended` | Design has no template |
| Account activated | User account reactivated | `UserMailer#account_activated` | Design has no template |

---

## Implementation Approach

### 1. Template Location

- **Source of truth:** `feedback_frontend/.figma-design-repo/email-templates/` (design repo)
- **Rails usage:** Copy or symlink `email-templates/` into `feedback_api/` (e.g. `feedback_api/email-templates/`) so Rails can read them. Alternatively, add a sync step (`figma:sync` or similar) that copies design templates into the API project.

### 2. Variable Syntax

- Design templates use `{{variable_name}}` placeholders.
- Rails mailers use ERB `<%= @variable %>` or instance variables.
- **Adapter:** Add a helper that loads the HTML file, replaces `{{key}}` with values from a hash, and returns the final HTML. Mailers pass a hash of variables.

### 3. Layout

- Design templates are **standalone HTML** (full document with header/footer).
- Current Rails mailer uses a shared `layouts/mailer.html.erb` that wraps content.
- **Option A:** Use design templates as-is (layout: false in mailer) – they are self-contained.
- **Option B:** Extract design template body only and wrap with shared layout for consistency.

**Recommendation:** Option A – use design templates as full documents. They already have header/footer and match design team intent.

### 4. Mailer Changes

Each mailer action should:

1. Build a variables hash from context (user, submission, etc.).
2. Call `render_design_template('path/to/template', variables)`.
3. Send mail with `html: rendered_html`.

Example:

```ruby
# UserMailer
def reset_password_instructions(user, raw_token)
  variables = {
    user_name: user.name.presence || user.email.split('@').first,
    reset_url: reset_password_url(raw_token)
  }
  html = render_design_template('auth/password-reset', variables)
  mail(to: user.email, subject: 'Reset your password', body: nil) do |format|
    format.html { render html: html.html_safe }
  end
end
```

---

## Quick Reference: Template → Scenario

| Template | When It's Sent |
|----------|----------------|
| `auth/welcome` | After signup (or after email confirmation) |
| `auth/email-verification` | When user must verify email (confirmation link) |
| `auth/password-reset` | User clicks "Forgot password" |
| `trial/trial-15-days` | 15 days left in free trial |
| `trial/trial-7-days` | 7 days left in free trial |
| `trial/trial-3-days` | 3 days left in free trial |
| `trial/trial-last-day` | Last day of trial |
| `trial/trial-expired` | Trial has ended |
| `billing/payment-successful-first` | First successful Stripe payment |
| `billing/payment-successful-recurring` | Recurring Stripe payment success |
| `billing/payment-failed` | Stripe payment failed |
| `billing/subscription-upgraded` | User upgrades plan |
| `billing/subscription-downgraded` | User downgrades plan |
| `billing/subscription-cancelled` | User cancels subscription |
| `billing/renewal-reminder` | Renewal coming soon (e.g. 3 days before) |
| `feedback/new-negative-feedback` | New feedback with rating 1–3 |
| `feedback/new-suggestion` | New suggestion submitted |
| `feedback/new-optin` | New opt-in/newsletter signup |
| `customer/feedback-confirmation` | Customer submitted feedback with "Contact me" checked |
| `customer/optin-confirmation` | Customer signed up for newsletter/rewards |
