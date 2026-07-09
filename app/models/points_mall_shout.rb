# frozen_string_literal: true

class PointsMallShout < ::ActiveRecord::Base
  self.table_name = "points_mall_shouts"

  belongs_to :user

  validates :message, presence: true, length: { maximum: 200 }
end
