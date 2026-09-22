# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscoursePointsMall::OrdersController, type: :request do
  fab!(:user) { Fabricate(:user) }
  fab!(:admin) { Fabricate(:admin) }
  fab!(:other_user) { Fabricate(:user) }

  before do
    SiteSetting.points_mall_enabled = true
  end

  describe "#index" do
    it "requires authentication" do
      get "/loja/pedidos.json"
      expect(response.status).to eq(403)
    end
  end

  describe "#show" do
    fab!(:product) do
      ::PointsMallProduct.create!(
        name: "Produto Teste",
        points_cost: 50,
        product_type: "virtual",
        enabled: true,
      )
    end

    fab!(:order) do
      ::PointsMallOrder.create!(
        user_id: user.id,
        product_id: product.id,
        points_spent: 50,
        status: "completed",
      )
    end

    it "blocks anonymous access" do
      get "/loja/pedidos/#{order.id}.json"
      expect(response.status).to eq(403)
    end

    it "permits the owner of the order to view" do
      sign_in(user)
      get "/loja/pedidos/#{order.id}.json"
      expect(response.status).to eq(200)
      json = response.parsed_body
      expect(json["order"]["id"]).to eq(order.id)
    end

    it "denies non-owners who are not staff" do
      sign_in(other_user)
      get "/loja/pedidos/#{order.id}.json"
      expect(response.status).to eq(403)
    end

    it "permits staff members to view any order" do
      sign_in(admin)
      get "/loja/pedidos/#{order.id}.json"
      expect(response.status).to eq(200)
    end

    it "returns 404 for non-existent orders" do
      sign_in(user)
      get "/loja/pedidos/999999.json"
      expect(response.status).to eq(404)
    end
  end

  describe "#create with disabled external service" do
    fab!(:voucher_product) do
      ::PointsMallProduct.create!(
        name: "Voucher Jogo",
        points_cost: 100,
        product_type: "virtual",
        product_key: "pokerogue_voucher_regular",
        enabled: true,
      )
    end

    it "rejects checkout immediately if external service is disabled in SiteSetting" do
      sign_in(user)
      SiteSetting.points_mall_game_voucher_enabled = false

      post "/loja/pedidos.json", params: { product_id: voucher_product.id }
      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"]).to be_present
    end
  end
end
