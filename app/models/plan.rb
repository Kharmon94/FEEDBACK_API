# frozen_string_literal: true

class Plan < ApplicationRecord
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_]+\z/ }
  validates :name, presence: true
  validates :monthly_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :yearly_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :location_limit, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :display_order, numericality: { only_integer: true }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(display_order: :asc, id: :asc) }

  def unlimited_locations?
    location_limit.nil?
  end
end

