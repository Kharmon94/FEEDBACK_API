# frozen_string_literal: true

class AddNotifyOnNewSuggestionToAdminSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :admin_settings, :notify_on_new_suggestion, :boolean, default: true, null: false
  end
end
