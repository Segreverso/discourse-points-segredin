# frozen_string_literal: true

module ::DiscoursePointsMall
  class PointsManager
    def self.enabled?
      defined?(::DiscourseGamification::GamificationScoreEvent) &&
        (new_api? || legacy_api?)
    end

    def self.new_api?
      defined?(::DiscourseGamification::GamificationLeaderboardScore)
    end

    def self.legacy_api?
      defined?(::DiscourseGamification::GamificationScore)
    end

    def self.default_leaderboard
      return nil unless defined?(::DiscourseGamification::GamificationLeaderboard)
      ::DiscourseGamification::GamificationLeaderboard.order(:id).first
    end

    def self.balance_for(user)
      return 0 if user.blank?

      if new_api?
        leaderboard = default_leaderboard
        return 0 if leaderboard.blank?

        ::DiscourseGamification::GamificationLeaderboardScore
          .where(leaderboard_id: leaderboard.id, user_id: user.id)
          .sum(:score)
          .to_i
      elsif legacy_api?
        ::DiscourseGamification::GamificationScore.where(user_id: user.id).sum(:score).to_i
      else
        0
      end
    rescue StandardError
      0
    end

    def self.add_points!(user:, points:, description:)
      return false if user.blank?
      points = points.to_i
      return false if points.zero?
      return false unless enabled?

      today = Date.today
      ::DiscourseGamification::GamificationScoreEvent.create!(
        user_id: user.id,
        date: today,
        points: points,
        description: description,
      )

      if new_api?
        ::DiscourseGamification::GamificationLeaderboardScore.calculate_all(since_date: today)
      elsif legacy_api?
        ::DiscourseGamification::GamificationScore.calculate_scores(since_date: today)
      end
      true
    rescue => e
      Rails.logger.warn("DiscoursePointsMall: 积分写入失败 - #{e.class}: #{e.message}")
      false
    end
  end
end
