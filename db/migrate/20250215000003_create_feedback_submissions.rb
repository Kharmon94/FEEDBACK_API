# frozen_string_literal: true

class CreateFeedbackSubmissions < ActiveRecord::Migration[8.0]
  def change
    create_table :feedback_submissions do |t|
      t.references :location, null: false, foreign_key: true
      t.integer :rating, null: false
      t.text :comment
      t.string :customer_name
      t.string :customer_email
      t.string :phone_number
      t.boolean :contact_me, default: false

      t.timestamps
    end
  end
end
