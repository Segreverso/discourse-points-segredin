import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";

export default class PointsMallRoute extends DiscourseRoute {
  beforeModel() {
    if (!this.currentUser) {
      this.transitionTo("login");
    }
  }

  async model() {
    const [checkins, products, orders, addresses, ledger, inventory] = await Promise.all([
      ajax("/loja/checkins/summary").catch(() => ({
        checkins: [],
        summary: {},
      })),
      ajax("/loja/products").catch(() => ({ products: [] })),
      ajax("/loja/orders").catch(() => ({ orders: [] })),
      ajax("/loja/addresses").catch(() => ({ addresses: [] })),
      ajax("/loja/points/ledger").catch(() => ({ summary: {}, events: [] })),
      ajax("/loja/inventory").catch(() => ({ inventory: { items: [], equipped: {} } })),
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
}
