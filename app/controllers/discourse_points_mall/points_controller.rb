# frozen_string_literal: true

module DiscoursePointsMall
  class PointsController < ::ApplicationController
    requires_plugin DiscoursePointsMall::PLUGIN_NAME

    before_action :ensure_logged_in

    MAX_EVENTS = 200
    SCORABLE_LOOKBACK_DAYS = 90

    SCORABLE_LABELS = {
      "post_created" => "发布回复",
      "topic_created" => "发布主题",
      "like_received" => "获得点赞",
      "like_given" => "送出点赞",
      "day_visited" => "每日访问",
      "post_read" => "阅读帖子",
      "time_read" => "阅读时长",
      "solutions" => "最佳答案",
      "flag_created" => "有效举报",
      "user_invited" => "邀请用户",
      "chat_message_created" => "聊天消息",
      "chat_reaction_given" => "聊天送出表情",
      "chat_reaction_received" => "聊天获得表情",
      "reaction_given" => "送出表情",
      "reaction_received" => "获得表情",
    }.freeze

    def ledger
      entries = (load_events.map { |e| serialize_event(e) } + load_scorable_entries)
      entries.sort_by! { |e| [e[:date].to_s, e[:created_at].to_s] }
      entries.reverse!
      entries = entries.first(MAX_EVENTS)

      render json: {
        summary: ledger_summary(entries),
        events: entries,
      }
    end

    private

    def load_events
      return [] unless defined?(::DiscourseGamification::GamificationScoreEvent)

      ::DiscourseGamification::GamificationScoreEvent
        .where(user_id: current_user.id)
        .order(date: :desc, created_at: :desc)
        .limit(MAX_EVENTS)
        .to_a
    rescue StandardError => e
      Rails.logger.warn("[points-mall] load ledger events failed: #{e.class} #{e.message}")
      []
    end

    # 把 gamification 的自动积分（发帖、点赞等 scorable）合并进明细
    def load_scorable_entries
      return [] unless defined?(::DiscourseGamification::Scorable)

      leaderboard = PointsManager.default_leaderboard
      return [] if leaderboard.blank?

      since = SCORABLE_LOOKBACK_DAYS.days.ago.to_date
      entries = []

      ::DiscourseGamification::Scorable.subclasses.each do |scorable|
        next unless scorable.enabled?(leaderboard: leaderboard)

        key = scorable.scorable_key
        label = SCORABLE_LABELS[key] || key

        begin
          rows = DB.query(<<~SQL, since: since, current_user_id: current_user.id)
            SELECT s.date, s.points
            FROM ( #{scorable.query(leaderboard: leaderboard)} ) AS s
            WHERE s.user_id = :current_user_id
          SQL

          rows.each do |row|
            points = row.points.to_i
            next if points.zero?

            entries << {
              id: nil,
              date: row.date.to_date,
              created_at: row.date,
              points: points,
              description: label,
              category: "community",
              direction: points.negative? ? "expense" : "income",
            }
          end
        rescue StandardError => e
          Rails.logger.warn("[points-mall] scorable #{key} ledger failed: #{e.class} #{e.message}")
        end
      end

      entries
    rescue StandardError => e
      Rails.logger.warn("[points-mall] load scorable entries failed: #{e.class} #{e.message}")
      []
    end

    def ledger_summary(entries)
      category_counts = Hash.new(0)
      income_count = 0
      expense_count = 0

      entries.each do |entry|
        category_counts[entry[:category]] += 1
        points = entry[:points].to_i
        income_count += 1 if points.positive?
        expense_count += 1 if points.negative?
      end

      {
        current_points: current_user.points_balance.to_i,
        total_count: entries.length,
        income_count: income_count,
        expense_count: expense_count,
        checkin_count: category_counts["checkin"],
        shop_count: category_counts["shop"],
        community_count: category_counts["community"],
        other_count: category_counts["other"],
      }
    end

    def serialize_event(event)
      points = event.points.to_i
      category = event_category(event.description)

      {
        id: event.id,
        date: event.date,
        created_at: event.created_at,
        points: points,
        description: event.description.presence || I18n.t("points_mall.points.unknown_description"),
        category: category,
        direction: points.negative? ? "expense" : "income",
      }
    end

    def event_category(description)
      text = description.to_s.downcase

      return "checkin" if text.include?("签到") || text.include?("check-in") || text.include?("checkin") || text.include?("每日")
      return "shop" if text.include?("商城") || text.include?("兑换商品") || text.include?("补签卡")
      return "community" if text.include?("社区") || text.include?("topic") || text.include?("reply") || text.include?("like") || text.include?("点赞")

      "other"
    end
  end
end
