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
