# frozen_string_literal: true

module DiscoursePointsMall
  class ShoutsController < ::ApplicationController
    requires_plugin DiscoursePointsMall::PLUGIN_NAME

    before_action :ensure_logged_in, only: %i[create destroy]

    MAX_LEN = 200
    FETCH_LIMIT = 30
    SVIP_GROUP = "SVIP"
    COLOR_RE = /\A#[0-9a-fA-F]{6}\z/

    def index
      shouts =
        PointsMallShout.includes(:user).order(created_at: :desc).limit(FETCH_LIMIT).to_a
      render json: {
        shouts: shouts.map { |s| serialize_shout(s) },
        cost: shout_cost,
        viewer: {
          logged_in: current_user.present?,
          is_svip: viewer_svip?,
        },
      }
    end

    def create
      message = params[:message].to_s.strip
      return render_json_error("内容不能为空") if message.blank?
      return render_json_error("内容过长（最多 #{MAX_LEN} 字）") if message.length > MAX_LEN

      # 颜色仅 SVIP 可用，且必须是合法十六进制
      color = params[:color].to_s.strip
      color = nil unless viewer_svip? && color.match?(COLOR_RE)

      cost = shout_cost
      if cost.positive?
        balance = current_user.points_balance.to_i
        return render_json_error("积分不足，发言需要 #{cost} 积分") if balance < cost
        ok =
          DiscoursePointsMall::PointsManager.add_points!(
            user: current_user,
            points: -cost,
            description: "小喇叭发言",
          )
        return render_json_error("扣分失败，请稍后再试") unless ok
      end

      shout =
        PointsMallShout.create!(user_id: current_user.id, message: message, color: color)

      notify_mentions(current_user, message)

      render json: {
        shout: serialize_shout(shout),
        balance: current_user.points_balance.to_i,
      }
    end

    def destroy
      shout = PointsMallShout.find_by(id: params[:id])
      return render_json_error("留言不存在", status: 404) if shout.nil?

      unless shout.user_id == current_user.id || current_user.staff?
        return render_json_error("无权删除", status: 403)
      end

      # 删除不退积分
      shout.destroy!
      render json: success_json
    end

    private

    # 小喇叭 @提及：给被提到的用户(最多3人,不含自己)发一条系统私信，产生原生通知
    def notify_mentions(sender, message)
      names = message.scan(/@([\p{Alnum}_\-\.]+)/).flatten.uniq.first(3)
      return if names.empty?

      users =
        names
          .filter_map { |n| ::User.find_by_username(n) }
          .reject { |u| u.id == sender.id || u.bot? }
      return if users.empty?

      ::PostCreator.create!(
        Discourse.system_user,
        title: "📢 小喇叭里有人提到了你",
        raw:
          "@#{sender.username} 在首页小喇叭提到了你：\n\n> #{message}\n\n" \
            "[点我回首页看小喇叭](#{Discourse.base_url}/)",
        archetype: Archetype.private_message,
        target_usernames: users.map(&:username).join(","),
        skip_validations: true,
      )
    rescue StandardError => e
      Rails.logger.warn("[points-mall] shout mention notify failed: #{e.class}: #{e.message}")
    end

    def viewer_svip?
      return false unless current_user
      current_user.groups.exists?(name: SVIP_GROUP)
    end

    def can_delete_shout?(shout)
      return false unless current_user
      shout.user_id == current_user.id || current_user.staff?
    end

    def shout_cost
      SiteSetting.points_mall_shout_cost.to_i
    end

    def author_svip?(user)
      return false unless user
      user.groups.exists?(name: SVIP_GROUP)
    end

    def serialize_shout(shout)
      user = shout.user
      {
        id: shout.id,
        message: shout.message,
        username: user&.username,
        name: user&.name.presence || user&.username,
        avatar_url: user ? user.avatar_template.gsub("{size}", "48") : nil,
        primary_group_name: user&.primary_group&.name,
        color: shout.color.presence,
        is_svip: author_svip?(user),
        created_at: shout.created_at,
        can_delete: can_delete_shout?(shout),
      }
    end
  end
end
