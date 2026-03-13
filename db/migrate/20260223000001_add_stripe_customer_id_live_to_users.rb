# frozen_string_literal: true

class AddStripeCustomerIdLiveToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :stripe_customer_id_live, :string
    add_index :users, :stripe_customer_id_live
  end
end
