# frozen_string_literal: true

class CreateLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :locations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug
      t.json :review_platforms, default: {}
      t.string :logo_url

      t.timestamps
    end
    add_index :locations, :slug, unique: true
  end
end
