# frozen_string_literal: true

module DiscoursePointsMall
  class Cosmetics
    CATALOG = {
      "cosmetic_avatar_frame_gold_vip_30d" => {
        kind: "avatar_frame",
        value: "gold_vip",
        duration_days: 30,
      },
      "cosmetic_avatar_frame_neon_pink_30d" => {
        kind: "avatar_frame",
        value: "neon_pink",
        duration_days: 30,
      },
      "cosmetic_avatar_frame_cyan_electric_30d" => {
        kind: "avatar_frame",
        value: "cyan_electric",
        duration_days: 30,
      },
      "cosmetic_avatar_frame_purple_deep_30d" => {
        kind: "avatar_frame",
        value: "purple_deep",
        duration_days: 30,
      },
      "cosmetic_avatar_frame_green_kenny_30d" => {
        kind: "avatar_frame",
        value: "green_kenny",
        duration_days: 30,
      },
      "cosmetic_avatar_frame_sakura_red_30d" => {
        kind: "avatar_frame",
        value: "sakura_red",
        duration_days: 30,
      },
      "cosmetic_avatar_frame_ruby_red_30d" => {
        kind: "avatar_frame",
        value: "ruby_red",
        duration_days: 30,
      },
      "cosmetic_avatar_frame_baby_blue_30d" => {
        kind: "avatar_frame",
        value: "baby_blue",
        duration_days: 30,
      },
      "cosmetic_avatar_frame_pinkish_purple_30d" => {
        kind: "avatar_frame",
        value: "pinkish_purple",
        duration_days: 30,
      },
      "cosmetic_avatar_frame_sparkling_pink_30d" => {
        kind: "avatar_frame",
        value: "sparkling_pink",
        duration_days: 30,
      },
      "cosmetic_avatar_frame_neon_blue_30d" => {
        kind: "avatar_frame",
        value: "neon_blue",
        duration_days: 30,
      },
      "cosmetic_avatar_frame_sparkling_green_30d" => {
        kind: "avatar_frame",
        value: "sparkling_green",
        duration_days: 30,
      },
      "cosmetic_title_vip_30d" => {
        kind: "title",
        title: "Membro VIP",
        value: "Membro VIP",
        duration_days: 30,
      },
      "cosmetic_title_explorador_30d" => {
        kind: "title",
        title: "Explorador",
        value: "Explorador",
        duration_days: 30,
      },
      "cosmetic_title_guardiao_30d" => {
        kind: "title",
        title: "Guardião das Águas",
        value: "Guardião das Águas",
        duration_days: 30,
      },
      # Legacy keys
      "cosmetic_title_launch_trainer_30d" => { kind: "title", title: "Membro Fundador", value: "Membro Fundador", duration_days: 30 },
      "cosmetic_title_shiny_collector_30d" => { kind: "title", title: "Colecionador", value: "Colecionador", duration_days: 30 },
      "cosmetic_title_zenless_resident_30d" => { kind: "title", title: "Residente", value: "Residente", duration_days: 30 },
      "cosmetic_avatar_frame_neon_30d" => { kind: "avatar_frame", value: "neon_pink", duration_days: 30 },
      "cosmetic_card_border_holo_30d" => { kind: "card_border", value: "gold_vip", duration_days: 30 },
      "cosmetic_profile_bg_zzz_30d" => { kind: "profile_background", value: "cyan_electric", duration_days: 30 },
      "cosmetic_post_signature_sakura_30d" => { kind: "post_signature", value: "sakura_red", duration_days: 30 },
      "cosmetic_svip_glow_30d" => { kind: "svip_glow", value: "gold_vip", duration_days: 30, requires_group: "SVIP" },
      "cosmetic_theme_skin_ticket" => { kind: "theme_skin", value: "gold_vip", duration_days: nil },
    }.freeze

    def self.find_config(product)
      return nil unless product
      key = product.respond_to?(:product_key) ? product.product_key.to_s.strip : ""
      return CATALOG[key] if CATALOG.key?(key)

      if key.start_with?("cosmetic_avatar_frame_")
        val = key.sub(/\Acosmetic_avatar_frame_/, "").sub(/_\d+d\z/, "")
        return { kind: "avatar_frame", value: val, duration_days: 30 }
      elsif key.start_with?("cosmetic_title_")
        val = key.sub(/\Acosmetic_title_/, "").sub(/_\d+d\z/, "")
        title_name = product.name.presence || val.tr("_", " ").titleize
        return { kind: "title", title: title_name, value: title_name, duration_days: 30 }
      elsif product.product_type == "cosmetic"
        val = key.presence || product.name
        return { kind: "avatar_frame", value: val, duration_days: 30 }
      end

      nil
    end

    def self.cosmetic?(product)
      !find_config(product).nil?
    end
  end
end
