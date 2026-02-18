# frozen_string_literal: true

class AddNotifyOnNewFeedbackToAdminSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :admin_settings, :notify_on_new_feedback, :boolean, default: true, null: false
  end
end
