import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class AdminPluginsShowDiscoursePointsMallManageRoute extends Route {
  model() {
    return ajax("/admin/plugins/points-mall/products.json");
  }

  setupController(controller, model) {
    super.setupController(controller, model);
    controller.setProperties({
      products: model.products || [],
      groups: model.groups || [],
      makeup: model.makeup || {},
    });
  }
}
