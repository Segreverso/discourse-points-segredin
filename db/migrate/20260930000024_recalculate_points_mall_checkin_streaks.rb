# frozen_string_literal: true

class RecalculatePointsMallCheckinStreaks < ActiveRecord::Migration[7.0]
  def up
    return unless table_exists?(:points_mall_checkins)

    user_ids = DB.query_single("SELECT DISTINCT user_id FROM points_mall_checkins")
    user_ids.each do |user_id|
      records = DB.query(
        "SELECT id, checkin_date, streak_days FROM points_mall_checkins WHERE user_id = :user_id ORDER BY checkin_date ASC",
        user_id: user_id,
      )
      next if records.empty?

      current_streak = 0
      previous_date = nil

      records.each do |row|
        checkin_date = row.checkin_date.to_date rescue Date.parse(row.checkin_date.to_s)
        if previous_date && checkin_date == (previous_date + 1)
          current_streak += 1
        else
          current_streak = 1
        end

        if row.streak_days.to_i != current_streak
          DB.exec(
            "UPDATE points_mall_checkins SET streak_days = :streak, updated_at = NOW() WHERE id = :id",
            streak: current_streak,
            id: row.id,
          )
        end

        previous_date = checkin_date
      end
    end
  end

  def down
    # Irreversible data repair; no down action needed
  end
end
