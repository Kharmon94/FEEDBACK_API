# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false, index: { unique: true }
      t.string :encrypted_password, null: false
      t.string :name
      t.string :business_name
      t.string :plan, default: "free"
      t.boolean :admin, default: false
      t.boolean :suspended, default: false
      t.string :provider
      t.string :uid

      t.timestamps
    end
  end
end
