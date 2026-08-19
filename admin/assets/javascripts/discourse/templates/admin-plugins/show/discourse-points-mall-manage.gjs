import { Input, Textarea } from "@ember/component";
import { concat, fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

function formatDateFixed(dateVal) {
  if (!dateVal) return "-";
  if (typeof dateVal === "string" && dateVal.match(/^\d{4}-\d{2}-\d{2}$/)) {
    const parts = dateVal.split("-");
    return `${parts[2]}/${parts[1]}/${parts[0]}`;
  }
  const d = new Date(dateVal);
  if (isNaN(d.getTime())) return String(dateVal);
  const day = String(d.getDate()).padStart(2, "0");
  const month = String(d.getMonth() + 1).padStart(2, "0");
  const year = d.getFullYear();
  return `${day}/${month}/${year}`;
}

export default <template>
  <div class="admin-detail points-mall-admin">
    <header class="points-mall-admin-header">
      <h1>{{i18n "points_mall.admin.manage"}}</h1>
    </header>

    {{! SEÇÃO 1: VISÃO GERAL & METRICAS }}
    <section class="points-mall-admin-section">
      <div class="points-mall-admin-overview-head">
        <div>
          <h2>{{i18n "points_mall.admin.overview.title"}}</h2>
          <p>{{i18n "points_mall.admin.overview.help"}}</p>
        </div>
        <DButton
          @icon="rotate-right"
          @label="points_mall.admin.checkins.refresh"
          @action={{@controller.reloadCheckinSummary}}
          class="btn-default"
        />
      </div>

      <div class="points-mall-admin-overview-grid">
        <article class="points-mall-admin-stat-card">
          <h3>{{i18n "points_mall.admin.overview.cards.products"}}</h3>
          <p>{{@controller.model.dashboardStats.products}}</p>
        </article>
        <article class="points-mall-admin-stat-card">
          <h3>{{i18n "points_mall.admin.overview.cards.total_orders"}}</h3>
          <p>{{@controller.model.dashboardStats.totalOrders}}</p>
        </article>
        <article class="points-mall-admin-stat-card">
          <h3>{{i18n "points_mall.admin.overview.cards.physical_orders"}}</h3>
          <p>{{@controller.model.dashboardStats.physicalOrders}}</p>
        </article>
        <article class="points-mall-admin-stat-card">
          <h3>{{i18n "points_mall.admin.overview.cards.virtual_orders"}}</h3>
          <p>{{@controller.model.dashboardStats.virtualOrders}}</p>
        </article>
        <article class="points-mall-admin-stat-card">
          <h3>{{i18n "points_mall.admin.overview.cards.pending_orders"}}</h3>
          <p>{{@controller.model.dashboardStats.pendingOrders}}</p>
        </article>
        <article class="points-mall-admin-stat-card">
          <h3>{{i18n "points_mall.admin.overview.cards.today_checkins"}}</h3>
          <p>{{@controller.model.dashboardStats.todayCheckins}}</p>
        </article>
        <article class="points-mall-admin-stat-card">
          <h3>{{i18n "points_mall.admin.overview.cards.today_checkin_points"}}</h3>
          <p>{{@controller.model.dashboardStats.todayCheckinPoints}}</p>
        </article>
      </div>
    </section>

    {{! SEÇÃO 2: CHECK-INS E FREQUÊNCIA }}
    <section class="points-mall-admin-section">
      <h2>{{i18n "points_mall.admin.checkins.title"}}</h2>
      <p>{{i18n "points_mall.admin.checkins.help"}}</p>

      <div class="points-mall-admin-overview-grid points-mall-admin-overview-grid-checkin">
        <article class="points-mall-admin-stat-card">
          <h3>{{i18n "points_mall.admin.checkins.cards.total_checkins"}}</h3>
          <p>{{@controller.model.checkinSummary.total_checkins}}</p>
        </article>
        <article class="points-mall-admin-stat-card">
          <h3>{{i18n "points_mall.admin.checkins.cards.total_points"}}</h3>
          <p>{{@controller.model.checkinSummary.total_points}}</p>
        </article>
        <article class="points-mall-admin-stat-card">
          <h3>{{i18n "points_mall.admin.checkins.cards.today_checkins"}}</h3>
          <p>{{@controller.model.checkinSummary.today_checkins}}</p>
        </article>
        <article class="points-mall-admin-stat-card">
          <h3>{{i18n "points_mall.admin.checkins.cards.today_points"}}</h3>
          <p>{{@controller.model.checkinSummary.today_points}}</p>
        </article>
        <article class="points-mall-admin-stat-card">
          <h3>{{i18n "points_mall.admin.checkins.cards.active_users_7d"}}</h3>
          <p>{{@controller.model.checkinSummary.active_users_7d}}</p>
        </article>
      </div>

      <div class="points-mall-admin-subgrid">
        <article class="points-mall-admin-card">
          <h3>{{i18n "points_mall.admin.checkins.trend_title"}}</h3>
          <table class="d-admin-table points-mall-admin-table">
            <thead>
              <tr>
                <th>{{i18n "points_mall.admin.checkins.fields.date"}}</th>
                <th>{{i18n "points_mall.admin.checkins.fields.checkins"}}</th>
                <th>{{i18n "points_mall.admin.checkins.fields.points"}}</th>
              </tr>
            </thead>
            <tbody>
              {{#each @controller.model.checkinTrend as |day|}}
                <tr>
                  <td>{{formatDateFixed day.date}}</td>
                  <td>{{day.checkins}}</td>
                  <td>{{day.points}}</td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        </article>

        <article class="points-mall-admin-card">
          <h3>{{i18n "points_mall.admin.checkins.top_users_title"}}</h3>
          <table class="d-admin-table points-mall-admin-table">
            <thead>
              <tr>
                <th>{{i18n "points_mall.admin.checkins.fields.user"}}</th>
                <th>{{i18n "points_mall.admin.checkins.fields.checkins"}}</th>
                <th>{{i18n "points_mall.admin.checkins.fields.points"}}</th>
                <th>{{i18n "points_mall.admin.checkins.fields.current_streak"}}</th>
              </tr>
            </thead>
            <tbody>
              {{#each @controller.model.checkinTopUsers as |row|}}
                <tr>
                  <td>{{row.username}}</td>
                  <td>{{row.checkins}}</td>
                  <td>{{row.points}}</td>
                  <td>{{row.current_streak}}</td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        </article>
      </div>

      <article class="points-mall-admin-card">
        <h3>{{i18n "points_mall.admin.checkins.recent_title"}}</h3>
        <table class="d-admin-table points-mall-admin-table">
          <thead>
            <tr>
              <th>{{i18n "points_mall.admin.checkins.fields.user"}}</th>
              <th>{{i18n "points_mall.admin.checkins.fields.date"}}</th>
              <th>{{i18n "points_mall.admin.checkins.fields.points"}}</th>
              <th>{{i18n "points_mall.admin.checkins.fields.current_streak"}}</th>
            </tr>
          </thead>
          <tbody>
            {{#each @controller.model.recentCheckins as |checkin|}}
              <tr>
                <td>{{checkin.username}}</td>
                <td>{{formatDateFixed checkin.checkin_date}}</td>
                <td>{{checkin.points_earned}}</td>
                <td>{{if checkin.streak_days checkin.streak_days "-"}}</td>
              </tr>
            {{/each}}
          </tbody>
        </table>
      </article>
    </section>

    {{! SEÇÃO 3: PRODUTOS & AUTOMAÇÃO VIP }}
    <section class="points-mall-admin-section">
      <h2>{{i18n "points_mall.admin.products.title"}}</h2>
      <p>{{i18n "points_mall.admin.products.help"}}</p>

      {{! CARTÃO 3.1: CONFIGURAÇÃO DE CARTÃO DE MAQUIAGEM / RECUPERAÇÃO }}
      <article class="points-mall-admin-card">
        <h3>{{i18n "points_mall.admin.products.makeup.title"}}</h3>
        <p>{{i18n "points_mall.admin.products.makeup.help"}}</p>
        <div class="points-mall-admin-makeup-config">
          <div class="points-mall-admin-makeup-field">
            <label>{{i18n "points_mall.admin.products.makeup.tier_1"}}</label>
            <Input
              @value={{@controller.model.makeupConfig.tier_1}}
              @type="number"
              class="points-mall-admin-input --number"
              {{on "input" (fn @controller.setMakeupTier "tier_1")}}
            />
          </div>
          <div class="points-mall-admin-makeup-field">
            <label>{{i18n "points_mall.admin.products.makeup.tier_2"}}</label>
            <Input
              @value={{@controller.model.makeupConfig.tier_2}}
              @type="number"
              class="points-mall-admin-input --number"
              {{on "input" (fn @controller.setMakeupTier "tier_2")}}
            />
          </div>
          <div class="points-mall-admin-makeup-field">
            <label>{{i18n "points_mall.admin.products.makeup.tier_3"}}</label>
            <Input
              @value={{@controller.model.makeupConfig.tier_3}}
              @type="number"
              class="points-mall-admin-input --number"
              {{on "input" (fn @controller.setMakeupTier "tier_3")}}
            />
          </div>
          <DButton
            @icon="floppy-disk"
            @label="points_mall.admin.products.makeup.save"
            @action={{@controller.saveMakeupConfig}}
            class="btn-primary"
          />
        </div>
      </article>

      {{! FORMULÁRIO DENSO & RESPONSIVO: NOVO PRODUTO }}
      <article class="points-mall-admin-card points-mall-admin-create-card">
        <header class="create-card-header">
          <h3>{{i18n "points_mall.admin.products.new"}}</h3>
          <span class="create-card-subtitle">Cadastre itens físicos, digitais ou automações VIP por grupo</span>
        </header>

        <div class="points-mall-admin-grid-form">
          <div class="form-group col-span-2">
            <label>Nome do Produto *</label>
            <Input
              @value={{@controller.model.newProduct.name}}
              placeholder="Ex: VIP Bronze 30 Dias"
              class="points-mall-admin-input"
            />
          </div>

          <div class="form-group">
            <label>Custo (Pontos) *</label>
            <Input
              @value={{@controller.model.newProduct.points_cost}}
              @type="number"
              placeholder="100"
              class="points-mall-admin-input --number"
            />
          </div>

          <div class="form-group">
            <label>Estoque (-1 = ilimitado)</label>
            <Input
              @value={{@controller.model.newProduct.stock}}
              @type="number"
              placeholder="-1"
              class="points-mall-admin-input --number"
            />
          </div>

          <div class="form-group">
            <label>Tipo de Produto</label>
            <select
              class="points-mall-admin-select"
              {{on "change" (fn @controller.setProductType @controller.model.newProduct)}}
            >
              {{#each @controller.model.productTypes as |type|}}
                <option
                  selected={{eq @controller.model.newProduct.product_type type}}
                  value={{type}}
                >{{type}}</option>
              {{/each}}
            </select>
          </div>

          <div class="form-group">
            <label>Conceder Grupo (VIP)</label>
            <select
              class="points-mall-admin-select"
              {{on "change" (fn @controller.setProductGroup @controller.model.newProduct)}}
            >
              <option value="">Nenhum (Sem grupo)</option>
              {{#each @controller.model.groups as |grp|}}
                <option
                  selected={{eq @controller.model.newProduct.grant_group_id grp.id}}
                  value={{grp.id}}
                >{{grp.name}}</option>
              {{/each}}
            </select>
          </div>

          <div class="form-group">
            <label>Duração VIP (Dias)</label>
            <Input
              @value={{@controller.model.newProduct.grant_duration_days}}
              @type="number"
              placeholder="14, 30... (0 = permanente)"
              class="points-mall-admin-input --number"
            />
          </div>

          <div class="form-group">
            <label>Categoria</label>
            <Input
              @value={{@controller.model.newProduct.category}}
              placeholder="Ex: VIP / Cosméticos"
              class="points-mall-admin-input"
            />
          </div>

          <div class="form-group">
            <label>Rótulo / Badge</label>
            <Input
              @value={{@controller.model.newProduct.badge_text}}
              placeholder="Ex: HOT, NOVO, -20%"
              class="points-mall-admin-input --tag"
            />
          </div>

          <div class="form-group">
            <label>Ordem de Exibição</label>
            <Input
              @value={{@controller.model.newProduct.sort_order}}
              @type="number"
              placeholder="0"
              class="points-mall-admin-input --number"
            />
          </div>

          <div class="form-group col-span-2">
            <label>Descrição</label>
            <Input
              @value={{@controller.model.newProduct.description}}
              placeholder="Breve explicação exibida na loja para os membros"
              class="points-mall-admin-input --wide"
            />
          </div>

          <div class="form-group col-span-2">
            <label>URL da Imagem</label>
            <Input
              @value={{@controller.model.newProduct.image_url}}
              placeholder="https://..."
              class="points-mall-admin-input --wide"
            />
          </div>

          <div class="form-group">
            <label>Preço Equivalente (R$)</label>
            <Input
              @value={{@controller.model.newProduct.price_brl}}
              @type="number"
              step="0.01"
              placeholder="R$ 0,00"
              class="points-mall-admin-input --number"
            />
          </div>

          <div class="form-group col-span-2">
            <label>URL Externa / Link de Resgate</label>
            <Input
              @value={{@controller.model.newProduct.external_url}}
              placeholder="https://..."
              class="points-mall-admin-input --wide"
            />
          </div>

          <div class="form-group form-checkboxes col-span-2">
            <label class="checkbox-label">
              <Input
                @type="checkbox"
                @checked={{@controller.model.newProduct.featured}}
                {{on "change" (fn @controller.setProductFeatured @controller.model.newProduct)}}
              />
              <span>Destaque na Loja</span>
            </label>
            <label class="checkbox-label">
              <Input
                @type="checkbox"
                @checked={{@controller.model.newProduct.enabled}}
                {{on "change" (fn @controller.setProductEnabled @controller.model.newProduct)}}
              />
              <span>Ativo (Visível)</span>
            </label>
          </div>

          <div class="form-actions col-span-full">
            <DButton
              @label="points_mall.admin.actions.add"
              @icon="plus"
              @action={{@controller.createProduct}}
              class="btn-primary btn-large"
            />
          </div>
        </div>
      </article>

      {{! TABELA DE GERENCIAMENTO DE PRODUTOS }}
      <div class="points-mall-admin-table-wrap">
        <table class="d-admin-table points-mall-admin-table">
          <thead>
            <tr>
              <th>{{i18n "points_mall.admin.products.fields.name"}}</th>
              <th>{{i18n "points_mall.admin.products.fields.description"}}</th>
              <th>{{i18n "points_mall.admin.products.fields.cost"}}</th>
              <th>{{i18n "points_mall.admin.products.fields.stock"}}</th>
              <th>{{i18n "points_mall.admin.products.fields.type"}}</th>
              <th>Grupo VIP</th>
              <th>Dias VIP</th>
              <th>{{i18n "points_mall.admin.products.fields.category"}}</th>
              <th>{{i18n "points_mall.admin.products.fields.badge_text"}}</th>
              <th>{{i18n "points_mall.admin.products.fields.sort_order"}}</th>
              <th>{{i18n "points_mall.admin.products.fields.redeemed_count"}}</th>
              <th>{{i18n "points_mall.admin.products.fields.featured"}}</th>
              <th>{{i18n "points_mall.admin.products.fields.image_url"}}</th>
              <th>{{i18n "points_mall.admin.products.fields.price_brl"}}</th>
              <th>{{i18n "points_mall.admin.products.fields.external_url"}}</th>
              <th>{{i18n "points_mall.admin.products.fields.enabled"}}</th>
              <th>{{i18n "points_mall.admin.products.fields.actions"}}</th>
            </tr>
          </thead>
          <tbody>
            {{#each @controller.model.products as |product|}}
              <tr class={{if product.is_makeup_card "is-system-product"}}>
                <td>
                  <Input
                    @value={{product.name}}
                    class="points-mall-admin-input"
                  />
                  {{#if product.is_makeup_card}}
                    <span class="points-mall-admin-system-badge">
                      {{i18n "points_mall.admin.products.makeup.badge"}}
                    </span>
                  {{/if}}
                </td>
                <td>
                  <Input
                    @value={{product.description}}
                    class="points-mall-admin-input --wide"
                    placeholder={{i18n "points_mall.admin.products.fields.description"}}
                  />
                </td>
                <td>
                  <Input
                    @value={{product.points_cost}}
                    @type="number"
                    class="points-mall-admin-input --number"
                    disabled={{product.is_makeup_card}}
                  />
                </td>
                <td>
                  <Input
                    @value={{product.stock}}
                    @type="number"
                    class="points-mall-admin-input --number"
                    disabled={{product.is_makeup_card}}
                  />
                </td>
                <td>
                  <select
                    class="points-mall-admin-select"
                    {{on "change" (fn @controller.setProductType product)}}
                    disabled={{product.is_makeup_card}}
                  >
                    {{#each @controller.model.productTypes as |type|}}
                      <option
                        selected={{eq product.product_type type}}
                        value={{type}}
                      >{{type}}</option>
                    {{/each}}
                  </select>
                </td>
                <td>
                  <select
                    class="points-mall-admin-select"
                    {{on "change" (fn @controller.setProductGroup product)}}
                    disabled={{product.is_makeup_card}}
                  >
                    <option value="">Nenhum</option>
                    {{#each @controller.model.groups as |grp|}}
                      <option
                        selected={{eq product.grant_group_id grp.id}}
                        value={{grp.id}}
                      >{{grp.name}}</option>
                    {{/each}}
                  </select>
                </td>
                <td>
                  <Input
                    @value={{product.grant_duration_days}}
                    @type="number"
                    class="points-mall-admin-input --number"
                    disabled={{product.is_makeup_card}}
                    placeholder="Dias"
                  />
                </td>
                <td>
                  <Input
                    @value={{product.category}}
                    class="points-mall-admin-input"
                    placeholder={{i18n "points_mall.admin.products.fields.category"}}
                  />
                </td>
                <td>
                  <Input
                    @value={{product.badge_text}}
                    class="points-mall-admin-input --tag"
                    placeholder={{i18n "points_mall.admin.products.fields.badge_text"}}
                  />
                </td>
                <td>
                  <Input
                    @value={{product.sort_order}}
                    @type="number"
                    class="points-mall-admin-input --number"
                  />
                </td>
                <td>
                  <span class="points-mall-admin-metric">{{product.redeemed_count}}</span>
                </td>
                <td>
                  <Input
                    @type="checkbox"
                    @checked={{product.featured}}
                    {{on "change" (fn @controller.setProductFeatured product)}}
                  />
                </td>
                <td>
                  <Input
                    @value={{product.image_url}}
                    class="points-mall-admin-input --wide"
                  />
                </td>
                <td>
                  <Input
                    @value={{product.price_brl}}
                    @type="number"
                    step="0.01"
                    placeholder="R$ 0,00"
                    class="points-mall-admin-input --number"
                  />
                </td>
                <td>
                  <Input
                    @value={{product.external_url}}
                    placeholder="https://..."
                    class="points-mall-admin-input --wide"
                  />
                </td>
                <td>
                  <Input
                    @type="checkbox"
                    @checked={{product.enabled}}
                    {{on "change" (fn @controller.setProductEnabled product)}}
                  />
                </td>
                <td>
                  <div class="row-actions">
                    <DButton
                      @icon="floppy-disk"
                      @action={{fn @controller.saveProduct product}}
                      class="btn-primary"
                    />
                    {{#unless product.is_makeup_card}}
                      <DButton
                        @icon="trash-can"
                        @action={{fn @controller.deleteProduct product}}
                        class="btn-danger"
                      />
                    {{#endunless}}
                  </div>
                </td>
              </tr>
            {{/each}}
          </tbody>
        </table>
      </div>
    </section>

    {{! SEÇÃO 4: PEDIDOS DOS USUÁRIOS (TABELA COMPACTA E MODERNA) }}
    <section class="points-mall-admin-section">
      <div class="points-mall-admin-orders-head">
        <div>
          <h2>{{i18n "points_mall.admin.orders.title"}}</h2>
          <p>{{i18n "points_mall.admin.orders.help"}}</p>
        </div>

        <div class="points-mall-admin-order-filters">
          <div class="points-mall-admin-order-filter">
            <span class="points-mall-admin-filter-label">
              {{i18n "points_mall.admin.orders.filters.type_label"}}
            </span>
            <div class="points-mall-admin-chip-row">
              {{#each @controller.model.orderTypes as |type|}}
                <button
                  type="button"
                  class="points-mall-admin-chip {{if (eq @controller.adminOrderTypeFilter type) 'active'}}"
                  {{on "click" (fn @controller.setAdminOrderTypeFilter type)}}
                >
                  {{i18n (concat "points_mall.admin.orders.filters.type." type)}}
                </button>
              {{/each}}
            </div>
          </div>

          <div class="points-mall-admin-order-filter">
            <label class="points-mall-admin-filter-label" for="pm-admin-order-status-filter">
              {{i18n "points_mall.admin.orders.filters.status_label"}}
            </label>
            <select
              id="pm-admin-order-status-filter"
              class="points-mall-admin-select"
              {{on "change" @controller.setAdminOrderStatusFilter}}
            >
              {{#each @controller.adminOrderStatuses as |status|}}
                <option
                  selected={{eq @controller.adminOrderStatusFilter status}}
                  value={{status}}
                >
                  {{i18n (concat "points_mall.admin.orders.filters.status." status)}}
                </option>
              {{/each}}
            </select>
          </div>
        </div>
      </div>

      {{#if @controller.filteredAdminOrders.length}}
        <div class="points-mall-admin-table-wrap">
          <table class="d-admin-table points-mall-admin-table points-mall-admin-orders-table">
            <thead>
              <tr>
                <th class="col-id">#ID / Data</th>
                <th class="col-user">Usuário</th>
                <th class="col-product">Produto</th>
                <th class="col-type">Tipo & Custo</th>
                <th class="col-shipping">Endereço / Dados</th>
                <th class="col-status">Status</th>
                <th class="col-notes">Anotações Admin</th>
                <th class="col-actions">Ações</th>
              </tr>
            </thead>
            <tbody>
              {{#each @controller.filteredAdminOrders as |order|}}
                <tr class="order-row status-{{order.status}}">
                  <td class="col-id">
                    <span class="order-id-badge">#{{order.id}}</span>
                    <span class="order-date-text">{{formatDateFixed order.created_at}}</span>
                  </td>

                  <td class="col-user">
                    <div class="order-user-cell">
                      <div class="avatar-wrap">
                        {{#if order.avatar_url}}
                          <img src={{order.avatar_url}} class="user-avatar" alt={{order.username}} />
                        {{else}}
                          {{dIcon "user"}}
                        {{/if}}
                      </div>
                      <div class="user-info">
                        <strong class="username">{{order.username}}</strong>
                        <div class="meta-row">
                          <span class="points-mall-admin-role-badge {{order.user_role_class}}">
                            {{i18n order.user_role_label_key}}
                          </span>
                          <span class="trust-level">TL{{order.trust_level}}</span>
                        </div>
                      </div>
                    </div>
                  </td>

                  <td class="col-product">
                    <div class="order-product-cell">
                      {{#if order.product_image_url}}
                        <img src={{order.product_image_url}} class="product-thumb" alt={{order.product_name}} />
                      {{/if}}
                      <strong class="product-name">{{order.product_name}}</strong>
                    </div>
                  </td>

                  <td class="col-type">
                    <div class="type-cell">
                      <span class="points-mall-admin-order-type type-{{order.display_product_type}}">
                        {{i18n (concat "points_mall.orders.types." order.display_product_type)}}
                      </span>
                      <span class="points-badge">{{order.points_spent}} pts</span>
                    </div>
                  </td>

                  <td class="col-shipping">
                    <div class="shipping-info-cell" title={{order.shipping_info}}>
                      {{if order.shipping_info order.shipping_info "-"}}
                    </div>
                  </td>

                  <td class="col-status">
                    <select
                      class="points-mall-admin-select status-select status-{{order.status}}"
                      {{on "change" (fn @controller.setOrderStatus order)}}
                    >
                      {{#each @controller.model.orderStatuses as |status|}}
                        <option selected={{eq order.status status}} value={{status}}>
                          {{i18n (concat "points_mall.orders.status." status)}}
                        </option>
                      {{/each}}
                    </select>
                  </td>

                  <td class="col-notes">
                    <Input
                      @value={{order.notes}}
                      class="points-mall-admin-input --notes"
                      placeholder="Anotações internas..."
                      {{on "input" (fn @controller.setOrderNotes order)}}
                      {{on "change" (fn @controller.setOrderNotes order)}}
                    />
                  </td>

                  <td class="col-actions">
                    <div class="actions-cell">
                      <button
                        type="button"
                        class="btn btn-primary btn-small"
                        {{on "click" (fn @controller.saveOrder order)}}
                      >
                        {{i18n "points_mall.admin.actions.save"}}
                      </button>
                      {{#if (@controller.isOrderDirty order)}}
                        <button
                          type="button"
                          class="btn btn-default btn-small"
                          {{on "click" (fn @controller.cancelOrderEdit order)}}
                        >
                          {{i18n "points_mall.admin.actions.cancel"}}
                        </button>
                      {{/if}}
                    </div>
                  </td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        </div>
      {{else}}
        <div class="points-mall-admin-empty">
          {{i18n "points_mall.admin.orders.empty"}}
        </div>
      {{/if}}
    </section>
  </div>
</template>
