# frozen_string_literal: true

class AddEmailPreferencesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :email_notifications_enabled, :boolean, default: true, null: false
    add_column :users, :email_marketing_opt_out, :boolean, default: false, null: false
  end
end
