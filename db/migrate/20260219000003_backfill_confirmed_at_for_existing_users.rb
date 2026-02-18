# frozen_string_literal: true

class BackfillConfirmedAtForExistingUsers < ActiveRecord::Migration[8.0]
  def up
    User.unscoped.where(confirmed_at: nil).update_all(confirmed_at: Time.current)
  end

  def down
  end
end
