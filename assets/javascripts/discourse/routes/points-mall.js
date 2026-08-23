import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";

export default class PointsMallRoute extends DiscourseRoute {
  queryParams = {
    tab: { refreshModel: false },
  };

  beforeModel() {
    if (!this.currentUser) {
      this.transitionTo("login");
    }
  }

  async model() {
    const [checkins, products, orders, addresses, ledger, inventory] = await Promise.all([
      ajax("/loja/checkin/resumo").catch(() => ({
        checkins: [],
        summary: {},
      })),
      ajax("/loja/produtos").catch(() => ({ products: [] })),
      ajax("/loja/pedidos").catch(() => ({ orders: [] })),
      ajax("/loja/enderecos").catch(() => ({ addresses: [] })),
      ajax("/loja/extrato").catch(() => ({ summary: {}, events: [] })),
      ajax("/loja/inventario").catch(() => ({ inventory: { items: [], equipped: {} } })),
    ]);

    return {
      checkins: checkins.checkins || [],
      summary: checkins.summary || {},
      products: products.products || [],
      orders: orders.orders || [],
      addresses: addresses.addresses || [],
      ledgerSummary: ledger.summary || {},
      ledgerEvents: ledger.events || [],
      inventory: inventory.inventory || { items: [], equipped: {} },
    };
  }

  setupController(controller, model, transition) {
    super.setupController(controller, model, transition);

    const validTabs = ["checkin", "shop", "inventory", "orders", "ledger"];
    const urlParams = new URLSearchParams(window.location.search);
    const queryTab = transition?.to?.queryParams?.tab || urlParams.get("tab");
    const savedTab = localStorage.getItem("pm_active_tab");

    let tabToUse = "checkin";
    if (queryTab && validTabs.includes(queryTab)) {
      tabToUse = queryTab;
    } else if (savedTab && validTabs.includes(savedTab)) {
      tabToUse = savedTab;
    }

    controller.activeTab = tabToUse;
    localStorage.setItem("pm_active_tab", tabToUse);

    if (urlParams.get("tab") !== tabToUse) {
      try {
        const newUrl = new URL(window.location.href);
        newUrl.searchParams.set("tab", tabToUse);
        window.history.replaceState(null, "", newUrl.toString());
      } catch (e) {
        // ignore
      }
    }
  }
}
