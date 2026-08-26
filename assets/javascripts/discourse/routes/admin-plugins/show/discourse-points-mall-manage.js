import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class AdminPluginsShowDiscoursePointsMallManageRoute extends Route {
  beforeModel(transition) {
    super.beforeModel?.(transition);
    const plugin = this.modelFor("adminPlugins.show");
    if (plugin && plugin.id && plugin.id !== "discourse-points-mall" && plugin.id !== "points-mall") {
      transition?.abort?.();
      return;
    }
  }

  async model() {
    const plugin = this.modelFor("adminPlugins.show");
    if (plugin && plugin.id && plugin.id !== "discourse-points-mall" && plugin.id !== "points-mall") {
      return { products: [], groups: [], makeup: {} };
    }
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
