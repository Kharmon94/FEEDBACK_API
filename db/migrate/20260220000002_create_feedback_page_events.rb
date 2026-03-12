# frozen_string_literal: true

class CreateFeedbackPageEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :feedback_page_events do |t|
      t.references :location, null: false, foreign_key: true
      t.string :event_type, null: false
      t.integer :rating
      t.string :device_type
      t.string :country
      t.string :region

      t.timestamps
    end

    add_index :feedback_page_events, [:location_id, :event_type, :created_at],
              name: "index_feedback_page_events_on_location_event_created"
  end
end
