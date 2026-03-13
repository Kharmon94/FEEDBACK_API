# frozen_string_literal: true

class AddStripePriceIdsToPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :plans, :stripe_price_id_monthly, :string
    add_column :plans, :stripe_price_id_yearly, :string
  end
end
