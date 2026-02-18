# frozen_string_literal: true

class CreateAdminSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_settings do |t|
      t.string :site_name, default: "Feedback Page", null: false
      t.string :support_email, default: "support@feedbackpage.com", null: false
      t.integer :max_locations_per_user, default: 100, null: false
      t.boolean :enable_user_registration, default: true, null: false
      t.boolean :enable_email_verification, default: false, null: false
      t.boolean :enable_social_login, default: true, null: false

      t.timestamps
    end
  end
end
