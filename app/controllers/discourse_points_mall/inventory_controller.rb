# frozen_string_literal: true

require "json"

module DiscoursePointsMall
  class InventoryController < ::ApplicationController
    requires_plugin DiscoursePointsMall::PLUGIN_NAME

    before_action :ensure_logged_in, except: [:public_cosmetics]

    skip_before_action :ensure_logged_in, only: [:public_cosmetics]

    rescue_from StandardError do |error|
      Rails.logger.error("[points-mall] InventoryController error: #{error.full_message}")
      render json: {
        inventory: {
          items: [],
          equipped: {},
          theme_skin_ticket_count: 0,
        },
        error: error.message,
      }, status: 200
    end

    def public_cosmetics
      frames = UserCustomField
        .where(name: "jn_cosmetic_avatar_frame")
        .where.not(value: [nil, ""])
        .joins(:user)
        .pluck("users.username_lower", "user_custom_fields.value")
        .to_h

      flairs = UserCustomField
        .where(name: ["jn_cosmetic_svip_glow", "jn_cosmetic_card_border"])
        .where.not(value: [nil, ""])
        .joins(:user)
        .pluck("users.username_lower", "user_custom_fields.value")
        .to_h

      # Membros do grupo 'apoiador' (VIP) ganham a moldura de avatar e o brilho de nickname em Vermelho Ruby automaticamente
      vip_group = Group.find_by("LOWER(name) = ?", "apoiador")
      if vip_group
        GroupUser.where(group_id: vip_group.id).joins(:user).pluck("users.username_lower").each do |uname|
          flairs[uname] ||= "ruby_red"
          frames[uname] ||= "ruby_red"
        end
      end

      render json: { frames: frames, flairs: flairs }
    end

    KIND_FIELDS = {
      "title" => {
        value: "jn_cosmetic_title",
        expires: "jn_cosmetic_title_expires_at",
      },
      "avatar_frame" => {
        value: "jn_cosmetic_avatar_frame",
        expires: "jn_cosmetic_avatar_frame_expires_at",
      },
      "card_border" => {
        value: "jn_cosmetic_card_border",
        expires: "jn_cosmetic_card_border_expires_at",
      },
      "profile_background" => {
        value: "jn_cosmetic_profile_background",
        expires: "jn_cosmetic_profile_background_expires_at",
      },
      "post_signature" => {
        value: "jn_cosmetic_post_signature",
        expires: "jn_cosmetic_post_signature_expires_at",
      },
      "svip_glow" => {
        value: "jn_cosmetic_svip_glow",
        expires: "jn_cosmetic_svip_glow_expires_at",
      },
      "theme_skin" => {
        value: "jn_cosmetic_theme_skin",
        expires: "jn_cosmetic_theme_skin_expires_at",
      },
    }.freeze

    KIND_LABELS = {
      "title" => "Título Especial",
      "avatar_frame" => "Aura de Avatar",
      "card_border" => "Borda de Perfil",
      "profile_background" => "Fundo de Perfil",
      "post_signature" => "Assinatura de Post",
      "svip_glow" => "Brilho SVIP",
      "theme_skin" => "Skin de Tema",
    }.freeze

    def index
      render json: inventory_payload
    end

    def equip
      order = cosmetic_order(params[:order_id])
      return render_json_error("Item de cosmético não encontrado", status: 404) unless order

      config = DiscoursePointsMall::Cosmetics.find_config(order.product)
      return render_json_error("Este item de cosmético já expirou", status: 422) if expired_order?(order, config)

      apply_cosmetic!(current_user, config, expires_at_for(order, config))
      render json: inventory_payload
    rescue StandardError => e
      Rails.logger.warn("[points-mall] inventory equip failed: #{e.class}: #{e.message}")
      render_json_error("Falha ao equipar o item. Tente novamente em instantes.", status: 422)
    end

    def unequip
      kind = params[:kind].to_s
      return render_json_error("Tipo de cosmético não suportado", status: 422) unless KIND_FIELDS.key?(kind)

      remove_cosmetic!(current_user, kind)
      render json: inventory_payload
    rescue StandardError => e
      Rails.logger.warn("[points-mall] inventory unequip failed: #{e.class}: #{e.message}")
      render_json_error("Falha ao desequipar o item. Tente novamente em instantes.", status: 422)
    end

    private

    def inventory_payload
      orders =
        ::PointsMallOrder
          .where(user_id: current_user.id, status: "completed")
          .includes(:product)
          .select { |order| order.product && DiscoursePointsMall::Cosmetics.cosmetic?(order.product) }

      items =
        orders.map { |order| item_payload(order) }
          .compact
          .sort_by { |item| [item[:expired] ? 1 : 0, item[:equipped] ? 0 : 1, -(parse_time(item[:granted_at])&.to_i || 0)] }

      {
        inventory: {
          items: items,
          equipped: equipped_payload,
          theme_skin_ticket_count: theme_skin_ticket_count(orders),
        },
      }
    end

    def item_payload(order)
      product = order.product
      return nil unless product

      config = DiscoursePointsMall::Cosmetics.find_config(product)
      return nil unless config

      expires_at = expires_at_for(order, config)
      expired = expires_at.present? && expires_at <= Time.zone.now
      value = cosmetic_value(config)

      {
        order_id: order.id,
        product_id: product.id,
        product_key: product.product_key,
        name: product.name,
        description: product.description,
        image_url: product.image_url,
        kind: config[:kind],
        kind_label: KIND_LABELS[config[:kind]] || config[:kind],
        value: value,
        display_value: display_value_for(config[:kind], value, product.name),
        preview_class: preview_class_for(config[:kind], value),
        granted_at: granted_at_for(order).iso8601,
        expires_at: expires_at&.iso8601,
        granted_display: display_time(granted_at_for(order)),
        expires_display: display_time(expires_at),
        remaining_text: remaining_text(expires_at),
        expired: expired,
        equipped: !expired && equipped?(config[:kind], value),
        equippable: !expired,
      }
    rescue StandardError => e
      Rails.logger.warn("[points-mall] item_payload error for order #{order&.id}: #{e.class} #{e.message}")
      nil
    end

    def theme_skin_ticket_count(orders)
      order_count =
        orders.count do |order|
          config = DiscoursePointsMall::Cosmetics.find_config(order.product)
          config&.dig(:kind) == "theme_skin"
        end

      [current_user.custom_fields["jn_theme_skin_ticket_count"].to_i, order_count].max
    end

    def equipped_payload
      KIND_FIELDS.each_with_object({}) do |(kind, fields), payload|
        value = current_user.custom_fields[fields[:value]].presence
        next unless value

        payload[kind] = {
          kind: kind,
          kind_label: KIND_LABELS[kind] || kind,
          value: value,
          display_value: display_value_for(kind, value),
          preview_class: preview_class_for(kind, value),
          expires_at: current_user.custom_fields[fields[:expires]].presence,
          expires_display: display_time(parse_time(current_user.custom_fields[fields[:expires]].presence)),
          remaining_text: remaining_text(parse_time(current_user.custom_fields[fields[:expires]].presence)),
        }
      end
    end

    def cosmetic_order(order_id)
      return nil if order_id.blank?

      ::PointsMallOrder
        .where(user_id: current_user.id, status: "completed")
        .includes(:product)
        .find_by(id: order_id)
        .tap do |order|
          return nil unless order && DiscoursePointsMall::Cosmetics.cosmetic?(order.product)
        end
    end

    def order_notes(order)
      JSON.parse(order.notes.to_s.presence || "{}")
    rescue JSON::ParserError
      {}
    end

    def granted_at_for(order)
      Time.zone.parse(order_notes(order)["granted_at"].to_s) rescue order.created_at
    end

    def expires_at_for(order, config)
      note_expires = order_notes(order)["expires_at"].presence
      return Time.zone.parse(note_expires) if note_expires
      return nil unless config && config[:duration_days]

      order.created_at + config[:duration_days].days
    rescue StandardError
      nil
    end

    def expired_order?(order, config)
      expires_at = expires_at_for(order, config)
      expires_at.present? && expires_at <= Time.zone.now
    end

    def cosmetic_value(config)
      config[:value] || config[:title]
    end

    def parse_time(value)
      return nil if value.blank?

      Time.zone.parse(value.to_s)
    rescue StandardError
      nil
    end

    def display_time(time)
      return nil unless time

      time.in_time_zone.strftime("%d/%m/%Y %H:%M")
    end

    def remaining_text(time)
      return nil unless time

      seconds = (time - Time.zone.now).to_i
      return "Expirado" if seconds <= 0

      days = seconds / 1.day
      return "Resta #{days} dia" if days == 1
      return "Restam #{days} dias" if days.positive?

      hours = [seconds / 1.hour, 1].max
      return "Resta #{hours} hora" if hours == 1
      "Restam #{hours} horas"
    end

    def display_value_for(kind, value, fallback = nil)
      named = DiscoursePointsMall::Cosmetics::CATALOG.values.find { |config| config[:kind].to_s == kind.to_s && cosmetic_value(config).to_s == value.to_s }
      return fallback if fallback.present?
      return named[:title] if named&.dig(:title).present?

      case value.to_s
      when "gold_vip"
        "Aura Dourada"
      when "ruby_red"
        "Aura Rubi"
      when "neon_pink"
        "Aura Rosa Neon"
      when "cyan_electric"
        "Aura Ciano Elétrico"
      when "purple_deep"
        "Aura Roxo Abissal"
      when "green_kenny"
        "Aura Verde Esmeralda"
      when "sakura_red"
        "Aura Cerejeira"
      when "baby_blue"
        "Aura Azul Bebê"
      when "soft_blue"
        "Aura Azul Suave"
      when "pinkish_purple"
        "Aura Magenta"
      when "sparkling_pink"
        "Aura Rosa Estelar"
      when "sparkling_green"
        "Aura Verde Jade"
      when "neon_blue"
        "Aura Azul Névoa"
      when "Membro VIP"
        "Membro VIP"
      when "Explorador"
        "Explorador"
      when "Guardião das Águas"
        "Guardião das Águas"
      else
        value.to_s.tr("_", " ").titleize
      end
    end

    def preview_class_for(kind, value)
      "inventory-preview-#{kind.to_s.dasherize}-#{value.to_s.dasherize}"
    end

    def equipped?(kind, value)
      fields = KIND_FIELDS[kind]
      return false unless fields

      current_user.custom_fields[fields[:value]].to_s == value.to_s
    end

    def apply_cosmetic!(user, config, expires_at)
      kind = config[:kind]
      value = cosmetic_value(config)
      fields = KIND_FIELDS[kind]
      raise "unsupported cosmetic kind" unless fields

      if kind == "title"
        if user.custom_fields["jn_cosmetic_title"].blank?
          user.custom_fields["jn_previous_title_before_cosmetic"] = user.title.to_s
        end
        user.title = value
      end

      user.custom_fields[fields[:value]] = value
      user.custom_fields[fields[:expires]] = expires_at&.iso8601.to_s
      user.save_custom_fields(true)
      user.save!
    end

    def remove_cosmetic!(user, kind)
      fields = KIND_FIELDS[kind]
      raise "unsupported cosmetic kind" unless fields

      if kind == "title"
        user.title = user.custom_fields["jn_previous_title_before_cosmetic"].to_s.presence
        user.custom_fields.delete("jn_previous_title_before_cosmetic")
        user.save!
      end

      user.custom_fields.delete(fields[:value])
      user.custom_fields.delete(fields[:expires])
      user.save_custom_fields(true)
    end
  end
end
