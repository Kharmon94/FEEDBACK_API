# frozen_string_literal: true

class AddLocationCustomizationColumns < ActiveRecord::Migration[8.0]
  def change
    add_column :locations, :address, :string
    add_column :locations, :phone, :string
    add_column :locations, :email, :string
    add_column :locations, :custom_message, :text
    add_column :locations, :color_scheme, :json
    add_column :locations, :email_notifications, :boolean, default: true, null: false
    add_column :locations, :notification_emails, :json, default: [], null: false
  end
end
