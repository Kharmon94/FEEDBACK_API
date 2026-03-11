# frozen_string_literal: true

class AddNotifyOnNewOptinToAdminSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :admin_settings, :notify_on_new_optin, :boolean, default: true, null: false
  end
end
