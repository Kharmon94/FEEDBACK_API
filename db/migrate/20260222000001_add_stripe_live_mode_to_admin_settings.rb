# frozen_string_literal: true

class AddStripeLiveModeToAdminSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :admin_settings, :stripe_live_mode, :boolean, default: false, null: false
  end
end
