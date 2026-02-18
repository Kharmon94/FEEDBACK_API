# frozen_string_literal: true

class CreatePlans < ActiveRecord::Migration[8.0]
  def change
    create_table :plans do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.integer :monthly_price_cents
      t.integer :yearly_price_cents
      t.integer :location_limit
      t.json :features, null: false, default: []
      t.string :cta
      t.boolean :highlighted, null: false, default: false
      t.integer :display_order, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :plans, :slug, unique: true
    add_index :plans, :active
    add_index :plans, :display_order
  end
end

