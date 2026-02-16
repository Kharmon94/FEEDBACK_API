# frozen_string_literal: true

class CreateSuggestions < ActiveRecord::Migration[8.0]
  def change
    create_table :suggestions do |t|
      t.references :location, null: true, foreign_key: true
      t.text :content, null: false
      t.string :submitter_email

      t.timestamps
    end
  end
end
