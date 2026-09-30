# frozen_string_literal: true

class PointsMallCheckin < ActiveRecord::Base
  self.table_name = 'points_mall_checkins'

  belongs_to :user

  validates :user_id, presence: true
  validates :checkin_date, presence: true, uniqueness: { scope: :user_id }
  validates :points_earned, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :recent, -> { order(checkin_date: :desc) }
  scope :today, -> { where(checkin_date: Time.zone.today) }

  after_create :award_points

  def self.checkin_for_user(user)
    return nil if where(user_id: user.id, checkin_date: Time.zone.today).exists?

    last_checkin = where(user_id: user.id).order(checkin_date: :desc).first
    streak = calculate_streak(last_checkin)

    base_points = SiteSetting.points_mall_checkin_points
    bonus_points = streak > 1 ? SiteSetting.points_mall_checkin_streak_bonus : 0
    total_points = base_points + bonus_points

    create!(
      user_id: user.id,
      checkin_date: Time.zone.today,
      points_earned: total_points,
      streak_days: streak
    )
  end

  def self.calculate_streak(last_checkin)
    return 1 unless last_checkin

    if last_checkin.checkin_date == Time.zone.yesterday
      last_checkin.streak_days + 1
    else
      1
    end
  end

  def self.recalculate_streaks_for_user(user_id)
    records = where(user_id: user_id).order(checkin_date: :asc)
    return 0 if records.empty?

    current_streak = 0
    previous_date = nil

    records.each do |record|
      if previous_date && record.checkin_date == (previous_date + 1.day)
        current_streak += 1
      else
        current_streak = 1
      end

      if record.streak_days != current_streak
        record.update_columns(streak_days: current_streak, updated_at: Time.zone.now)
      end

      previous_date = record.checkin_date
    end

    current_streak
  end

  def self.recalculate_all_streaks!
    user_ids = distinct.pluck(:user_id)
    user_ids.each do |uid|
      recalculate_streaks_for_user(uid)
    end
    user_ids.size
  end

  private

  def award_points
    return unless user
    return unless points_earned.to_i.positive?

    DiscoursePointsMall::PointsManager.add_points!(
      user: user,
      points: points_earned,
      description: "Recompensa de Check-in Diário",
    )
  end
end
