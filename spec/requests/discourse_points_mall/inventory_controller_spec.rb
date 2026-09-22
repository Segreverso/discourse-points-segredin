# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscoursePointsMall::InventoryController, type: :request do
  fab!(:user) { Fabricate(:user) }
  fab!(:other_user) { Fabricate(:user) }

  before do
    SiteSetting.points_mall_enabled = true
  end

  describe "#public_cosmetics" do
    it "excludes users with expired cosmetics" do
      user.custom_fields["jn_cosmetic_avatar_frame"] = "neon_blue"
      user.custom_fields["jn_cosmetic_avatar_frame_expires_at"] = 1.hour.ago.iso8601
      user.save_custom_fields(true)

      other_user.custom_fields["jn_cosmetic_avatar_frame"] = "gold_vip"
      other_user.custom_fields["jn_cosmetic_avatar_frame_expires_at"] = 1.day.from_now.iso8601
      other_user.save_custom_fields(true)

      get "/loja/cosmeticos.json"
      expect(response.status).to eq(200)

      json = response.parsed_body
      expect(json["frames"][other_user.username_lower]).to eq("gold_vip")
      expect(json["frames"][user.username_lower]).to be_nil
    end
  end

  describe "#index" do
    it "requires authentication" do
      get "/loja/inventario.json"
      expect(response.status).to eq(403)
    end

    it "automatically cleans up expired cosmetics on access (JIT cleanup) and omits from equipped" do
      sign_in(user)

      user.custom_fields["jn_cosmetic_avatar_frame"] = "neon_blue"
      user.custom_fields["jn_cosmetic_avatar_frame_expires_at"] = 2.hours.ago.iso8601
      user.save_custom_fields(true)

      get "/loja/inventario.json"
      expect(response.status).to eq(200)

      json = response.parsed_body
      expect(json.dig("inventory", "equipped", "avatar_frame")).to be_nil

      user.reload
      expect(user.custom_fields["jn_cosmetic_avatar_frame"]).to be_blank
      expect(user.custom_fields["jn_cosmetic_avatar_frame_expires_at"]).to be_blank
    end

    it "maintains active cosmetics in equipped" do
      sign_in(user)

      user.custom_fields["jn_cosmetic_avatar_frame"] = "gold_vip"
      user.custom_fields["jn_cosmetic_avatar_frame_expires_at"] = 5.days.from_now.iso8601
      user.save_custom_fields(true)

      get "/loja/inventario.json"
      expect(response.status).to eq(200)

      json = response.parsed_body
      equipped = json.dig("inventory", "equipped", "avatar_frame")
      expect(equipped).to be_present
      expect(equipped["value"]).to eq("gold_vip")
    end
  end

  describe "#equip" do
    fab!(:cosmetic_product) do
      ::PointsMallProduct.create!(
        name: "Aura Azul Névoa",
        points_cost: 100,
        product_type: "virtual",
        product_key: "cosmetic_avatar_frame_neon_blue",
        enabled: true,
      )
    end

    it "rejects equipping an expired cosmetic order" do
      sign_in(user)

      order = ::PointsMallOrder.create!(
        user_id: user.id,
        product_id: cosmetic_product.id,
        points_spent: 100,
        status: "completed",
        notes: { granted_at: 35.days.ago.iso8601, expires_at: 5.days.ago.iso8601 }.to_json,
      )

      post "/loja/inventario/equipar.json", params: { order_id: order.id }
      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"]).to be_present
    end
  end
end
