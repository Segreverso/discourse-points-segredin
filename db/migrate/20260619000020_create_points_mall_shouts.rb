# frozen_string_literal: true

class CreatePointsMallShouts < ActiveRecord::Migration[7.2]
  def change
    create_table :points_mall_shouts do |t|
      t.integer :user_id, null: false
      t.string :message, null: false, limit: 200
      t.timestamps
    end
    add_index :points_mall_shouts, :created_at
  end
end
