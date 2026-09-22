# frozen_string_literal: true

require "net/http"
require "openssl"
require "base64"
require "json"

module ::Jobs
  class PointsMallFulfillExternalOrder < ::Jobs::Base
    def execute(args)
      order_id = args[:order_id]
      return if order_id.blank?

      order = ::PointsMallOrder.includes(:product, :user).find_by(id: order_id)
      return if order.blank?
      return unless order.status == "pending"

      user = order.user
      product = order.product
      return if user.blank? || product.blank?

      success = false
      error_message = nil
      notes_payload = nil

      if game_voucher_product?(product)
        success, error_message, notes_payload = fulfill_game_voucher(user, product, order)
      elsif netdisk_traffic_product?(product)
        success, error_message, notes_payload = fulfill_netdisk_traffic(user, product, order)
      else
        return
      end

      if success
        order.update!(
          status: "completed",
          notes: notes_payload.present? ? notes_payload.to_json : order.notes,
        )
      else
        Rails.logger.warn("[points-mall] FulfillExternalOrder failed for order ##{order.id}: #{error_message}")
        order.update!(
          status: "failed",
          notes: "Falha na integração externa: #{error_message}",
        )

        # Estorno seguro de pontos em caso de falha permanente na entrega
        DiscoursePointsMall::PointsManager.add_points!(
          user: user,
          points: order.points_spent,
          description: "Estorno de pedido ##{order.id} (falha no resgate)",
        )
      end
    rescue StandardError => e
      Rails.logger.error("[points-mall] FulfillExternalOrder unexpected exception: #{e.class}: #{e.message}")
      raise e
    end

    private

    def game_voucher_product?(product)
      product.respond_to?(:product_key) && DiscoursePointsMall::OrdersController::GAME_VOUCHERS.key?(product.product_key)
    end

    def netdisk_traffic_product?(product)
      product.respond_to?(:product_key) && product.product_key.to_s.match?(DiscoursePointsMall::OrdersController::NETDISK_TRAFFIC_KEY)
    end

    def fulfill_game_voucher(user, product, order)
      endpoint = SiteSetting.points_mall_game_voucher_endpoint.to_s.strip
      secret = SiteSetting.points_mall_game_voucher_secret.to_s.strip
      return [false, "Serviço de vouchers não configurado", nil] if endpoint.blank? || secret.blank?

      config = DiscoursePointsMall::OrdersController::GAME_VOUCHERS[product.product_key]
      return [false, "Configuração de voucher inválida", nil] if config.blank?

      payload = {
        external_id: "points_mall_order:#{order.id}",
        discourse_id: user.id.to_s,
        voucher_type: config[:voucher_type],
        count: config[:count],
        timestamp: Time.now.to_i,
      }
      signing_payload = [
        payload[:external_id],
        payload[:discourse_id],
        payload[:voucher_type],
        payload[:count],
        payload[:timestamp],
      ].join(":")
      payload[:signature] = Base64.urlsafe_encode64(
        OpenSSL::HMAC.digest("SHA256", secret, signing_payload),
        padding: false,
      )

      post_json(endpoint, payload)
    end

    def fulfill_netdisk_traffic(user, product, order)
      endpoint = SiteSetting.points_mall_netdisk_endpoint.to_s.strip
      secret = SiteSetting.points_mall_netdisk_secret.to_s.strip
      return [false, "Serviço de nuvem não configurado", nil] if endpoint.blank? || secret.blank?

      m = DiscoursePointsMall::OrdersController::NETDISK_TRAFFIC_KEY.match(product.product_key.to_s)
      return [false, "Configuração de tráfego inválida", nil] unless m

      amount = m[1].to_i
      mb = m[2].downcase == "gb" ? amount * 1024 : amount
      return [false, "Quantidade de tráfego inválida", nil] if mb <= 0

      payload = {
        external_id: "points_mall_order:#{order.id}",
        discourse_id: user.id.to_s,
        mb: mb,
        valid_days: m[3].to_i,
        timestamp: Time.now.to_i,
      }
      signing_payload = [
        payload[:external_id],
        payload[:discourse_id],
        payload[:mb],
        payload[:valid_days],
        payload[:timestamp],
      ].join(":")
      payload[:signature] = Base64.urlsafe_encode64(
        OpenSSL::HMAC.digest("SHA256", secret, signing_payload),
        padding: false,
      )

      post_json(endpoint, payload)
    end

    def post_json(endpoint_url, payload)
      uri = URI.parse(endpoint_url)
      return [false, "URL de endpoint inválida", nil] unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.open_timeout = 5
      http.read_timeout = 10

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      request["User-Agent"] = "DiscoursePointsMall/#{DiscoursePointsMall::PLUGIN_NAME}"
      request.body = payload.to_json

      response = http.request(request)

      if response.is_a?(Net::HTTPSuccess)
        parsed = JSON.parse(response.body) rescue {}
        [true, nil, parsed]
      else
        [false, "Resposta HTTP #{response.code}: #{response.body.to_s.truncate(100)}", nil]
      end
    rescue StandardError => e
      [false, "#{e.class}: #{e.message}", nil]
    end
  end
end
