# frozen_string_literal: true

class AddStripeLivePriceIdsToPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :plans, :stripe_price_id_monthly_live, :string
    add_column :plans, :stripe_price_id_yearly_live, :string
  end
end
