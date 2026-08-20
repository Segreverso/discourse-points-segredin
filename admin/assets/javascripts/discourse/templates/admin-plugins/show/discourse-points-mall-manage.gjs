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

function formatBrl(val) {
  if (val === null || val === undefined || val === "") return "";
  const num = Number(val);
  if (isNaN(num)) return String(val);
  if (Number.isInteger(num)) {
    return num.toString();
  }
  return num.toFixed(2).replace(".", ",");
}

export default <template>
  <div class="admin-detail points-mall-admin">
    {{! CABEÇALHO DO PAINEL }}
    <header class="points-mall-admin-header-main">
      <div class="header-title-group">
        <div class="header-icon-badge">
          {{dIcon "store"}}
        </div>
        <div>
          <h1>{{i18n "points_mall.admin.manage"}}</h1>
          <p class="header-description">Gerencie a loja de pontos, produtos VIP por grupo, acompanhe estatísticas de check-in e pedidos dos membros.</p>
        </div>
      </div>
      <DButton
        @icon="rotate-right"
        @label="points_mall.admin.checkins.refresh"
        @action={{@controller.reloadCheckinSummary}}
        class="btn-default btn-refresh-summary"
      />
    </header>

    {{! SEÇÃO 1: VISÃO GERAL & MÉTRICAS }}
    <section class="points-mall-admin-section">
      <div class="points-mall-admin-section-header">
        <h2>
          {{dIcon "chart-line"}}
          <span>{{i18n "points_mall.admin.overview.title"}}</span>
        </h2>
        <p>{{i18n "points_mall.admin.overview.help"}}</p>
      </div>

      <div class="points-mall-admin-overview-grid">
        <article class="points-mall-admin-stat-card card-cyan">
          <div class="stat-icon-wrap">{{dIcon "box"}}</div>
          <div class="stat-content">
            <h3>{{i18n "points_mall.admin.overview.cards.products"}}</h3>
            <p>{{@controller.model.dashboardStats.products}}</p>
          </div>
        </article>

        <article class="points-mall-admin-stat-card card-purple">
          <div class="stat-icon-wrap">{{dIcon "cart-shopping"}}</div>
          <div class="stat-content">
            <h3>{{i18n "points_mall.admin.overview.cards.total_orders"}}</h3>
            <p>{{@controller.model.dashboardStats.totalOrders}}</p>
          </div>
        </article>

        <article class="points-mall-admin-stat-card card-blue">
          <div class="stat-icon-wrap">{{dIcon "truck"}}</div>
          <div class="stat-content">
            <h3>{{i18n "points_mall.admin.overview.cards.physical_orders"}}</h3>
            <p>{{@controller.model.dashboardStats.physicalOrders}}</p>
          </div>
        </article>

        <article class="points-mall-admin-stat-card card-green">
          <div class="stat-icon-wrap">{{dIcon "gem"}}</div>
          <div class="stat-content">
            <h3>{{i18n "points_mall.admin.overview.cards.virtual_orders"}}</h3>
            <p>{{@controller.model.dashboardStats.virtualOrders}}</p>
          </div>
        </article>

        <article class="points-mall-admin-stat-card card-amber">
          <div class="stat-icon-wrap">{{dIcon "clock"}}</div>
          <div class="stat-content">
            <h3>{{i18n "points_mall.admin.overview.cards.pending_orders"}}</h3>
            <p>{{@controller.model.dashboardStats.pendingOrders}}</p>
          </div>
        </article>

        <article class="points-mall-admin-stat-card card-teal">
          <div class="stat-icon-wrap">{{dIcon "calendar-check"}}</div>
          <div class="stat-content">
            <h3>{{i18n "points_mall.admin.overview.cards.today_checkins"}}</h3>
            <p>{{@controller.model.dashboardStats.todayCheckins}}</p>
          </div>
        </article>

        <article class="points-mall-admin-stat-card card-gold">
          <div class="stat-icon-wrap">{{dIcon "coins"}}</div>
          <div class="stat-content">
            <h3>{{i18n "points_mall.admin.overview.cards.today_checkin_points"}}</h3>
            <p>{{@controller.model.dashboardStats.todayCheckinPoints}}</p>
          </div>
        </article>
      </div>
    </section>

    {{! SEÇÃO 2: CHECK-INS E RECOMPOSIÇÃO }}
    <section class="points-mall-admin-section">
      <div class="points-mall-admin-section-header">
        <h2>
          {{dIcon "calendar-days"}}
          <span>{{i18n "points_mall.admin.checkins.title"}}</span>
        </h2>
        <p>{{i18n "points_mall.admin.checkins.help"}}</p>
      </div>

      <div class="points-mall-admin-overview-grid points-mall-admin-overview-grid-checkin">
        <article class="points-mall-admin-stat-card">
          <div class="stat-content">
            <h3>{{i18n "points_mall.admin.checkins.cards.total_checkins"}}</h3>
            <p>{{@controller.model.checkinSummary.total_checkins}}</p>
          </div>
        </article>
        <article class="points-mall-admin-stat-card">
          <div class="stat-content">
            <h3>{{i18n "points_mall.admin.checkins.cards.total_points"}}</h3>
            <p>{{@controller.model.checkinSummary.total_points}}</p>
          </div>
        </article>
        <article class="points-mall-admin-stat-card">
          <div class="stat-content">
            <h3>{{i18n "points_mall.admin.checkins.cards.today_checkins"}}</h3>
            <p>{{@controller.model.checkinSummary.today_checkins}}</p>
          </div>
        </article>
        <article class="points-mall-admin-stat-card">
          <div class="stat-content">
            <h3>{{i18n "points_mall.admin.checkins.cards.today_points"}}</h3>
            <p>{{@controller.model.checkinSummary.today_points}}</p>
          </div>
        </article>
        <article class="points-mall-admin-stat-card">
          <div class="stat-content">
            <h3>{{i18n "points_mall.admin.checkins.cards.active_users_7d"}}</h3>
            <p>{{@controller.model.checkinSummary.active_users_7d}}</p>
          </div>
        </article>
      </div>

      <div class="points-mall-admin-subgrid">
        <article class="points-mall-admin-card">
          <div class="card-title-row">
            {{dIcon "chart-column"}}
            <h3>{{i18n "points_mall.admin.checkins.trend_title"}}</h3>
          </div>
          <div class="table-container-compact">
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
                    <td><span class="badge-number">{{day.checkins}}</span></td>
                    <td><span class="badge-points">+{{day.points}} pts</span></td>
                  </tr>
                {{/each}}
              </tbody>
            </table>
          </div>
        </article>

        <article class="points-mall-admin-card">
          <div class="card-title-row">
            {{dIcon "trophy"}}
            <h3>{{i18n "points_mall.admin.checkins.top_users_title"}}</h3>
          </div>
          <div class="table-container-compact">
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
                    <td><strong class="username-text">{{row.username}}</strong></td>
                    <td>{{row.checkins}}</td>
                    <td><span class="badge-points">{{row.points}} pts</span></td>
                    <td><span class="streak-pill">🔥 {{row.current_streak}}d</span></td>
                  </tr>
                {{/each}}
              </tbody>
            </table>
          </div>
        </article>
      </div>

      <article class="points-mall-admin-card">
        <div class="card-title-row">
          {{dIcon "clock-rotate-left"}}
          <h3>{{i18n "points_mall.admin.checkins.recent_title"}}</h3>
        </div>
        <div class="table-container-compact">
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
                  <td><strong class="username-text">{{checkin.username}}</strong></td>
                  <td>{{formatDateFixed checkin.checkin_date}}</td>
                  <td><span class="badge-points">+{{checkin.points_earned}} pts</span></td>
                  <td>{{if checkin.streak_days (concat "🔥 " checkin.streak_days "d") "-"}}</td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        </div>
      </article>
    </section>

    {{! SEÇÃO 3: PRODUTOS & AUTOMAÇÃO VIP }}
    <section class="points-mall-admin-section">
      <div class="points-mall-admin-section-header">
        <h2>
          {{dIcon "boxes-stacked"}}
          <span>{{i18n "points_mall.admin.products.title"}}</span>
        </h2>
        <p>{{i18n "points_mall.admin.products.help"}}</p>
      </div>

      {{! CARTÃO 3.1: CONFIGURAÇÃO DE CARTÃO DE REPOSIÇÃO / MAQUIAGEM }}
      <article class="points-mall-admin-card points-mall-admin-makeup-card">
        <div class="card-title-row">
          {{dIcon "life-ring"}}
          <div>
            <h3>{{i18n "points_mall.admin.products.makeup.title"}}</h3>
            <p class="card-subtitle">{{i18n "points_mall.admin.products.makeup.help"}}</p>
          </div>
        </div>

        <div class="points-mall-admin-makeup-config">
          <div class="points-mall-admin-makeup-field">
            <label>{{i18n "points_mall.admin.products.makeup.tier_1"}}</label>
            <div class="input-with-icon">
              {{dIcon "coins"}}
              <Input
                @value={{@controller.model.makeupConfig.tier_1}}
                @type="number"
                class="points-mall-admin-input --number"
                {{on "input" (fn @controller.setMakeupTier "tier_1")}}
              />
            </div>
          </div>
          <div class="points-mall-admin-makeup-field">
            <label>{{i18n "points_mall.admin.products.makeup.tier_2"}}</label>
            <div class="input-with-icon">
              {{dIcon "coins"}}
              <Input
                @value={{@controller.model.makeupConfig.tier_2}}
                @type="number"
                class="points-mall-admin-input --number"
                {{on "input" (fn @controller.setMakeupTier "tier_2")}}
              />
            </div>
          </div>
          <div class="points-mall-admin-makeup-field">
            <label>{{i18n "points_mall.admin.products.makeup.tier_3"}}</label>
            <div class="input-with-icon">
              {{dIcon "coins"}}
              <Input
                @value={{@controller.model.makeupConfig.tier_3}}
                @type="number"
                class="points-mall-admin-input --number"
                {{on "input" (fn @controller.setMakeupTier "tier_3")}}
              />
            </div>
          </div>
          <DButton
            @icon="floppy-disk"
            @label="points_mall.admin.products.makeup.save"
            @action={{@controller.saveMakeupConfig}}
            class="btn-primary btn-save-makeup"
          />
        </div>
      </article>

      {{! FORMULÁRIO DENSO & ESTRUTURADO: NOVO PRODUTO }}
      <article class="points-mall-admin-card points-mall-admin-create-card">
        <header class="create-card-header">
          <div class="header-icon">{{dIcon "circle-plus"}}</div>
          <div>
            <h3>{{i18n "points_mall.admin.products.new"}}</h3>
            <span class="create-card-subtitle">Cadastre itens físicos, digitais ou automações de grupo VIP</span>
          </div>
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
            <label>Custo em Pontos *</label>
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
            <label>URL da Imagem</label>
            <Input
              @value={{@controller.model.newProduct.image_url}}
              placeholder="https://exemplo.com/imagem.png"
              class="points-mall-admin-input"
            />
          </div>

          <div class="form-group col-span-2">
            <label>URL Externa / Link de Resgate</label>
            <Input
              @value={{@controller.model.newProduct.external_url}}
              placeholder="https://exemplo.com/link-resgate"
              class="points-mall-admin-input"
            />
          </div>

          <div class="form-group col-span-full">
            <label>Descrição Curta</label>
            <Textarea
              @value={{@controller.model.newProduct.description}}
              placeholder="Breve explicação exibida na loja para os membros"
              class="points-mall-admin-textarea"
              rows="2"
            />
          </div>

          <div class="form-group form-checkboxes col-span-full">
            <label class="checkbox-label">
              <Input
                @type="checkbox"
                @checked={{@controller.model.newProduct.featured}}
                {{on "change" (fn @controller.setProductFeatured @controller.model.newProduct)}}
              />
              <span>⭐ Destaque na Loja</span>
            </label>
            <label class="checkbox-label">
              <Input
                @type="checkbox"
                @checked={{@controller.model.newProduct.enabled}}
                {{on "change" (fn @controller.setProductEnabled @controller.model.newProduct)}}
              />
              <span>✅ Ativo (Visível para Resgate)</span>
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

      {{! LISTA MODERNA DE PRODUTOS CADASTRADOS }}
      <div class="points-mall-admin-products-list-wrap">
        <header class="products-list-header">
          <h3>Catálogo de Produtos Cadastrados ({{@controller.model.products.length}})</h3>
          <span class="header-hint">Clique em "Editar" para modificar parâmetros de um produto.</span>
        </header>

        <div class="points-mall-products-grid">
          {{#each @controller.model.products as |product|}}
            <article class="points-mall-product-row-card {{if product.is_makeup_card 'is-system'}} {{if (eq @controller.editingProductId product.id) 'is-editing'}}">
              <div class="product-row-summary">
                <div class="product-info-primary">
                  {{#if product.image_url}}
                    <img src={{product.image_url}} class="product-thumbnail" alt={{product.name}} />
                  {{else}}
                    <div class="product-icon-fallback">
                      {{if (eq product.product_type "physical") (dIcon "box") (dIcon "gem")}}
                    </div>
                  {{/if}}

                  <div class="product-title-group">
                    <strong class="product-name">{{product.name}}</strong>
                    <div class="product-tags">
                      <span class="type-pill type-{{product.product_type}}">
                        {{if (eq product.product_type "physical") "Físico" "Virtual"}}
                      </span>
                      {{#if product.is_makeup_card}}
                        <span class="system-pill">Sistema</span>
                      {{/if}}
                      {{#if product.featured}}
                        <span class="featured-pill">⭐ Destaque</span>
                      {{/if}}
                      {{#if product.badge_text}}
                        <span class="badge-pill">{{product.badge_text}}</span>
                      {{/if}}
                      {{#unless product.enabled}}
                        <span class="disabled-pill">Inativo</span>
                      {{/unless}}
                    </div>
                  </div>
                </div>

                <div class="product-meta-item">
                  <span class="meta-label">Custo</span>
                  <span class="meta-value points-val">{{product.points_cost}} pts</span>
                  {{#if product.price_brl}}
                    <span class="meta-sub">R$ {{formatBrl product.price_brl}}</span>
                  {{/if}}
                </div>

                <div class="product-meta-item">
                  <span class="meta-label">Automação VIP</span>
                  {{#if product.grant_group_id}}
                    <span class="meta-value vip-val">
                      {{dIcon "shield-halved"}}
                      <span>Grupo #{{product.grant_group_id}}</span>
                    </span>
                    <span class="meta-sub">
                      {{if product.grant_duration_days (concat product.grant_duration_days " dias") "Permanente"}}
                    </span>
                  {{else}}
                    <span class="meta-value text-muted">-</span>
                  {{/if}}
                </div>

                <div class="product-meta-item">
                  <span class="meta-label">Estoque</span>
                  <span class="meta-value">
                    {{if (eq product.stock -1) "Ilimitado" (concat product.stock " uni")}}
                  </span>
                  <span class="meta-sub">{{product.redeemed_count}} resgates</span>
                </div>

                <div class="product-row-actions">
                  <button
                    type="button"
                    class="btn btn-default btn-edit-toggle {{if (eq @controller.editingProductId product.id) 'active'}}"
                    {{on "click" (fn @controller.toggleEditProduct product)}}
                  >
                    {{dIcon "pen-to-square"}}
                    <span>{{if (eq @controller.editingProductId product.id) "Fechar" "Editar"}}</span>
                  </button>

                  {{#unless product.is_makeup_card}}
                    <button
                      type="button"
                      class="btn btn-danger btn-icon-only"
                      title="Excluir produto"
                      {{on "click" (fn @controller.deleteProduct product)}}
                    >
                      {{dIcon "trash-can"}}
                    </button>
                  {{/unless}}
                </div>
              </div>

              {{! DRAWER INLINE DE EDIÇÃO DO PRODUTO }}
              {{#if (eq @controller.editingProductId product.id)}}
                <div class="product-edit-drawer">
                  <div class="drawer-header">
                    <h4>{{dIcon "sliders"}} Editar Produto: {{product.name}}</h4>
                  </div>

                  <div class="points-mall-admin-grid-form">
                    <div class="form-group col-span-2">
                      <label>Nome do Produto</label>
                      <Input @value={{product.name}} class="points-mall-admin-input" />
                    </div>

                    <div class="form-group">
                      <label>Custo (Pontos)</label>
                      <Input
                        @value={{product.points_cost}}
                        @type="number"
                        class="points-mall-admin-input --number"
                        disabled={{product.is_makeup_card}}
                      />
                    </div>

                    <div class="form-group">
                      <label>Estoque (-1 = ilimitado)</label>
                      <Input
                        @value={{product.stock}}
                        @type="number"
                        class="points-mall-admin-input --number"
                        disabled={{product.is_makeup_card}}
                      />
                    </div>

                    <div class="form-group">
                      <label>Tipo</label>
                      <select
                        class="points-mall-admin-select"
                        {{on "change" (fn @controller.setProductType product)}}
                        disabled={{product.is_makeup_card}}
                      >
                        {{#each @controller.model.productTypes as |type|}}
                          <option selected={{eq product.product_type type}} value={{type}}>{{type}}</option>
                        {{/each}}
                      </select>
                    </div>

                    <div class="form-group">
                      <label>Conceder Grupo (VIP)</label>
                      <select
                        class="points-mall-admin-select"
                        {{on "change" (fn @controller.setProductGroup product)}}
                        disabled={{product.is_makeup_card}}
                      >
                        <option value="">Nenhum (Sem grupo)</option>
                        {{#each @controller.model.groups as |grp|}}
                          <option selected={{eq product.grant_group_id grp.id}} value={{grp.id}}>{{grp.name}}</option>
                        {{/each}}
                      </select>
                    </div>

                    <div class="form-group">
                      <label>Duração VIP (Dias)</label>
                      <Input
                        @value={{product.grant_duration_days}}
                        @type="number"
                        class="points-mall-admin-input --number"
                        disabled={{product.is_makeup_card}}
                        placeholder="Dias"
                      />
                    </div>

                    <div class="form-group">
                      <label>Categoria</label>
                      <Input @value={{product.category}} class="points-mall-admin-input" />
                    </div>

                    <div class="form-group">
                      <label>Rótulo / Badge</label>
                      <Input @value={{product.badge_text}} class="points-mall-admin-input --tag" />
                    </div>

                    <div class="form-group">
                      <label>Ordem Exibição</label>
                      <Input @value={{product.sort_order}} @type="number" class="points-mall-admin-input --number" />
                    </div>

                    <div class="form-group">
                      <label>Preço Equivalente (R$)</label>
                      <Input @value={{product.price_brl}} @type="number" step="0.01" class="points-mall-admin-input --number" />
                    </div>

                    <div class="form-group col-span-2">
                      <label>URL Imagem</label>
                      <Input @value={{product.image_url}} class="points-mall-admin-input" />
                    </div>

                    <div class="form-group col-span-2">
                      <label>URL Externa</label>
                      <Input @value={{product.external_url}} class="points-mall-admin-input" />
                    </div>

                    <div class="form-group col-span-full">
                      <label>Descrição</label>
                      <Textarea @value={{product.description}} class="points-mall-admin-textarea" rows="2" />
                    </div>

                    <div class="form-group form-checkboxes col-span-full">
                      <label class="checkbox-label">
                        <Input
                          @type="checkbox"
                          @checked={{product.featured}}
                          {{on "change" (fn @controller.setProductFeatured product)}}
                        />
                        <span>⭐ Destaque</span>
                      </label>

                      <label class="checkbox-label">
                        <Input
                          @type="checkbox"
                          @checked={{product.enabled}}
                          {{on "change" (fn @controller.setProductEnabled product)}}
                        />
                        <span>✅ Ativo</span>
                      </label>
                    </div>

                    <div class="form-actions col-span-full">
                      <DButton
                        @icon="floppy-disk"
                        @label="points_mall.admin.actions.save"
                        @action={{fn @controller.saveProduct product}}
                        class="btn-primary"
                      />
                      <button
                        type="button"
                        class="btn btn-default"
                        {{on "click" (fn @controller.toggleEditProduct product)}}
                      >
                        Fechar
                      </button>
                    </div>
                  </div>
                </div>
              {{/if}}
            </article>
          {{/each}}
        </div>
      </div>
    </section>

    {{! SEÇÃO 4: PEDIDOS DOS USUÁRIOS (TABELA MODERNA) }}
    <section class="points-mall-admin-section">
      <div class="points-mall-admin-orders-head">
        <div>
          <h2>
            {{dIcon "receipt"}}
            <span>{{i18n "points_mall.admin.orders.title"}}</span>
          </h2>
          <p>{{i18n "points_mall.admin.orders.help"}}</p>
        </div>

        <div class="points-mall-admin-order-filters">
          <div class="points-mall-admin-order-filter">
            <span class="points-mall-admin-filter-label">Buscar Pedido</span>
            <Input
              @value={{@controller.adminOrderQuery}}
              placeholder="Digite #ID, usuário ou produto..."
              class="points-mall-admin-input --search"
              {{on "input" @controller.updateAdminOrderQuery}}
            />
          </div>

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
                      {{#each @controller.adminOrderStatuses as |status|}}
                        {{#unless (eq status "all")}}
                          <option selected={{eq order.status status}} value={{status}}>
                            {{i18n (concat "points_mall.orders.status." status)}}
                          </option>
                        {{/unless}}
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
                        title="Salvar alterações"
                      >
                        {{i18n "points_mall.admin.actions.save"}}
                      </button>

                      {{#if (eq order.status "refunded")}}
                        <span class="badge-refunded-text" title="Pedido já reembolsado">
                          {{dIcon "arrow-rotate-left"}} Reembolsado
                        </span>
                      {{else}}
                        <button
                          type="button"
                          class="btn btn-danger btn-small btn-refund"
                          {{on "click" (fn @controller.refundOrder order)}}
                          title="Reembolsar pontos ao usuário"
                        >
                          {{dIcon "rotate-left"}}
                          <span>Reembolsar</span>
                        </button>
                      {{/if}}

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
