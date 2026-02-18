# Seeds for Feedback API (idempotent). Run: bin/rails db:seed
# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Admin user for the admin panel:
#   In production, set ADMIN_SEED_EMAIL and ADMIN_SEED_PASSWORD (e.g. in your deploy env).
#   Change the password after first login. For dev, defaults to admin@example.com / password.
#
email = ENV.fetch("ADMIN_SEED_EMAIL", "admin@example.com")
password = ENV.fetch("ADMIN_SEED_PASSWORD", "password")
admin = User.find_or_initialize_by(email: email)
admin.assign_attributes(
  name: admin.name.presence || "Admin",
  password: password,
  password_confirmation: password,
  admin: true
)
admin.save!
puts "Admin user: #{admin.email} (admin: #{admin.admin})"

# Default Plans (idempotent)
default_plans = [
  {
    slug: "free",
    name: "Free",
    monthly_price_cents: 0,
    yearly_price_cents: 0,
    location_limit: 1,
    features: [
      "1 location",
      "Unlimited feedback",
      "Basic analytics"
    ],
    cta: "Get Started",
    highlighted: false,
    display_order: 0,
    active: true
  },
  {
    slug: "starter",
    name: "Starter",
    monthly_price_cents: 2900,
    yearly_price_cents: 29700,
    location_limit: 1,
    features: [
      "1 location",
      "Unlimited feedback",
      "Advanced analytics",
      "Priority email support",
      "Custom branding",
      "CSV export"
    ],
    cta: "Start Free Trial",
    highlighted: false,
    display_order: 10,
    active: true
  },
  {
    slug: "pro",
    name: "Pro",
    monthly_price_cents: 5900,
    yearly_price_cents: 59700,
    location_limit: 5,
    features: [
      "Up to 5 locations",
      "Unlimited feedback",
      "Advanced analytics",
      "Priority support",
      "Custom branding",
      "CSV export"
    ],
    cta: "Start Free Trial",
    highlighted: true,
    display_order: 20,
    active: true
  },
  {
    slug: "business",
    name: "Business",
    monthly_price_cents: 9900,
    yearly_price_cents: 99700,
    location_limit: 15,
    features: [
      "Up to 15 locations",
      "Unlimited feedback",
      "Advanced analytics",
      "Priority support",
      "Custom branding",
      "CSV export",
      "White label options"
    ],
    cta: "Start Free Trial",
    highlighted: false,
    display_order: 30,
    active: true
  },
  {
    slug: "enterprise",
    name: "Enterprise",
    monthly_price_cents: nil,
    yearly_price_cents: nil,
    location_limit: nil,
    features: [
      "Unlimited locations",
      "Unlimited feedback",
      "Advanced analytics",
      "Dedicated support",
      "Custom branding",
      "CSV export",
      "White label options"
    ],
    cta: "Contact Sales",
    highlighted: false,
    display_order: 40,
    active: true
  }
]

default_plans.each do |attrs|
  plan = Plan.find_or_initialize_by(slug: attrs[:slug])
  plan.assign_attributes(attrs)
  plan.save!
end
puts "Seeded #{Plan.count} plans"
