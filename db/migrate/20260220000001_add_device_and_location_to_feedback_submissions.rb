# frozen_string_literal: true

class AddDeviceAndLocationToFeedbackSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :feedback_submissions, :device_type, :string
    add_column :feedback_submissions, :country, :string
    add_column :feedback_submissions, :region, :string
  end
end
