# frozen_string_literal: true
class AddColorToPointsMallShouts < ActiveRecord::Migration[7.0]
  def change
    add_column :points_mall_shouts, :color, :string, limit: 20
  end
end
