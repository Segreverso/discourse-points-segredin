import Controller from "@ember/controller";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

function emptyProductForm() {
  return {
    id: null,
    name: "",
    description: "",
    points_cost: 1000,
    stock: -1,
    product_type: "cosmetic",
    product_key: "cosmetic_avatar_frame_gold_vip_30d",
    category: "molduras",
    badge_text: "",
    image_url: "",
    enabled: true,
    price_brl: "",
    external_url: "",
    sort_order: 0,
  };
}

export default class AdminPluginsShowDiscoursePointsMallManageController extends Controller {
  @tracked products = [];
  @tracked groups = [];
  @tracked makeup = {};

  @tracked modalOpen = false;
  @tracked isSaving = false;
  @tracked form = emptyProductForm();

  @action
  openNewProductModal() {
    this.form = emptyProductForm();
    this.modalOpen = true;
  }

  @action
  editProduct(product) {
    this.form = {
      id: product.id,
      name: product.name || "",
      description: product.description || "",
      points_cost: product.points_cost || 0,
      stock: product.stock !== undefined ? product.stock : -1,
      product_type: product.product_type || "virtual",
      product_key: product.product_key || "",
      category: product.category || "",
      badge_text: product.badge_text || "",
      image_url: product.image_url || "",
      enabled: product.enabled !== false,
      price_brl: product.price_brl || "",
      external_url: product.external_url || "",
      sort_order: product.sort_order || 0,
    };
    this.modalOpen = true;
  }

  @action
  closeModal() {
    this.modalOpen = false;
  }

  @action
  setProductType(event) {
    this.form = { ...this.form, product_type: event.target.value };
  }

  @action
  setProductKey(event) {
    this.form = { ...this.form, product_key: event.target.value };
  }

  @action
  async saveProduct() {
    if (!this.form.name) {
      return alert("Por favor, preencha o nome do produto.");
    }

    this.isSaving = true;
    try {
      const payload = {
        name: this.form.name,
        description: this.form.description,
        points_cost: Number(this.form.points_cost || 0),
        stock: Number(this.form.stock),
        product_type: this.form.product_type,
        product_key: this.form.product_key,
        category: this.form.category,
        badge_text: this.form.badge_text,
        image_url: this.form.image_url,
        enabled: this.form.enabled,
        price_brl: this.form.price_brl,
        external_url: this.form.external_url,
        sort_order: Number(this.form.sort_order || 0),
      };

      if (this.form.id) {
        const res = await ajax(`/admin/plugins/points-mall/products/${this.form.id}.json`, {
          type: "PUT",
          data: payload,
        });
        const index = this.products.findIndex((p) => p.id === this.form.id);
        if (index !== -1 && res.product) {
          this.products[index] = res.product;
          this.products = [...this.products];
        }
      } else {
        const res = await ajax("/admin/plugins/points-mall/products.json", {
          type: "POST",
          data: payload,
        });
        if (res.product) {
          this.products = [res.product, ...this.products];
        }
      }

      this.modalOpen = false;
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.isSaving = false;
    }
  }

  @action
  async deleteProduct(product) {
    if (!confirm(`Tem certeza que deseja excluir o produto "${product.name}"?`)) {
      return;
    }

    try {
      await ajax(`/admin/plugins/points-mall/products/${product.id}.json`, {
        type: "DELETE",
      });
      this.products = this.products.filter((p) => p.id !== product.id);
    } catch (e) {
      popupAjaxError(e);
    }
  }
}
