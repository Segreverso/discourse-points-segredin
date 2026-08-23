import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class AdminPluginsShowDiscoursePointsMallManageRoute extends Route {
  async model() {
    try {
      return await ajax("/admin/plugins/discourse-points-mall/manage/products.json");
    } catch (e) {
      try {
        return await ajax("/admin/plugins/points-mall/products.json");
      } catch (err) {
        console.error("Failed to load points mall products", err);
        return { products: [], groups: [], makeup: {} };
      }
    }
  }

  setupController(controller, model) {
    super.setupController(controller, model);
    controller.setProperties({
      products: model?.products || [],
      groups: model?.groups || [],
      makeup: model?.makeup || {},
    });
  }
}
