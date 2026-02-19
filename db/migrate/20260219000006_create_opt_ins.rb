# frozen_string_literal: true

class CreateOptIns < ActiveRecord::Migration[8.0]
  def change
    create_table :opt_ins do |t|
      t.references :location, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.integer :rating

      t.timestamps
    end

    add_index :opt_ins, [:location_id, :email]
  end
end
