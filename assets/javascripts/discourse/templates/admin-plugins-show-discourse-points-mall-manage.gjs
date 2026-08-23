import { Input } from "@ember/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import DButton from "discourse/ui-kit/d-button";

export default <template>
  <div class="points-mall-admin-manage">
    <div class="admin-controls">
      <h2>Gerenciador da Loja de Pontos & Molduras</h2>
      <DButton
        @action={{@controller.openNewProductModal}}
        @icon="plus"
        @label="points_mall.admin.create_product"
        class="btn-primary"
      />
    </div>

    <table class="grid points-mall-admin-table">
      <thead>
        <tr>
          <th>ID</th>
          <th>Nome</th>
          <th>Tipo</th>
          <th>Chave Cosmético (`product_key`)</th>
          <th>Pontos</th>
          <th>Preço (R$)</th>
          <th>Status</th>
          <th>Ações</th>
        </tr>
      </thead>
      <tbody>
        {{#each @controller.products as |product|}}
          <tr>
            <td>{{product.id}}</td>
            <td>
              <strong>{{product.name}}</strong>
              {{#if product.badge_text}}
                <span class="badge">{{product.badge_text}}</span>
              {{/if}}
            </td>
            <td>{{product.product_type}}</td>
            <td>
              <code>{{if product.product_key product.product_key "-"}}</code>
            </td>
            <td>{{product.points_cost}} pts</td>
            <td>{{if product.price_brl (concat "R$ " product.price_brl) "-"}}</td>
            <td>
              {{#if product.enabled}}
                <span class="status-active">Ativo</span>
              {{else}}
                <span class="status-disabled">Desativado</span>
              {{/if}}
            </td>
            <td class="actions">
              <DButton
                @action={{fn @controller.editProduct product}}
                @icon="pencil"
                class="btn-default btn-small"
              />
              <DButton
                @action={{fn @controller.deleteProduct product}}
                @icon="trash-can"
                class="btn-danger btn-small"
              />
            </td>
          </tr>
        {{else}}
          <tr>
            <td colspan="8" class="no-products">
              Nenhum produto cadastrado até o momento. Clique em "+ Criar Novo Produto / Moldura".
            </td>
          </tr>
        {{/each}}
      </tbody>
    </table>

    {{#if @controller.modalOpen}}
      <div class="d-modal fixed-modal points-mall-admin-modal">
        <div class="d-modal-container">
          <div class="d-modal-header">
            <h3>
              {{#if @controller.form.id}}
                Editar Produto #{{@controller.form.id}}
              {{else}}
                Criar Novo Produto / Moldura
              {{/if}}
            </h3>
            <button
              type="button"
              class="modal-close"
              {{on "click" @controller.closeModal}}
            >&times;</button>
          </div>

          <div class="d-modal-body">
            <div class="control-group">
              <label>Nome do Produto / Moldura:</label>
              <Input
                @value={{@controller.form.name}}
                class="input-large"
                placeholder="Ex: Dourado VIP Neon"
              />
            </div>

            <div class="control-group">
              <label>Descrição:</label>
              <Input
                @value={{@controller.form.description}}
                class="input-large"
                placeholder="Ex: Moldura animada com brilho neon dourado de 30 dias"
              />
            </div>

            <div class="control-group-row">
              <div class="control-group">
                <label>Preço em Pontos:</label>
                <Input
                  @value={{@controller.form.points_cost}}
                  @type="number"
                  placeholder="1500"
                />
              </div>

              <div class="control-group">
                <label>Preço em Reais (R$) [Opcional]:</label>
                <Input
                  @value={{@controller.form.price_brl}}
                  placeholder="19,90"
                />
              </div>
            </div>

            <div class="control-group-row">
              <div class="control-group">
                <label>Tipo de Produto:</label>
                <select
                  class="ember-select"
                  value={{@controller.form.product_type}}
                  {{on "change" (fn (mut @controller.form.product_type))}}
                >
                  <option value="cosmetic">Cosmético (Moldura / Título)</option>
                  <option value="virtual">Item Virtual</option>
                  <option value="physical">Item Físico</option>
                </select>
              </div>

              <div class="control-group">
                <label>Chave do Cosmético (`product_key`):</label>
                <select
                  class="ember-select"
                  value={{@controller.form.product_key}}
                  {{on "change" (fn (mut @controller.form.product_key))}}
                >
                  <option value="">Nenhum (Item normal)</option>
                  <option value="cosmetic_avatar_frame_gold_vip_30d">Dourado VIP Neon (gold_vip)</option>
                  <option value="cosmetic_avatar_frame_neon_pink_30d">Rosa Neon (neon_pink)</option>
                  <option value="cosmetic_avatar_frame_cyan_electric_30d">Cyan Elétrico (cyan_electric)</option>
                  <option value="cosmetic_avatar_frame_purple_deep_30d">Roxo Profundo (purple_deep)</option>
                  <option value="cosmetic_avatar_frame_green_kenny_30d">Verde Kenny (green_kenny)</option>
                  <option value="cosmetic_avatar_frame_sakura_red_30d">Vermelho Sakura (sakura_red)</option>
                  <option value="cosmetic_title_vip_30d">Título: Membro VIP</option>
                  <option value="cosmetic_title_explorador_30d">Título: Explorador</option>
                  <option value="cosmetic_title_guardiao_30d">Título: Guardião das Águas</option>
                </select>
              </div>
            </div>

            <div class="control-group">
              <label>URL da Imagem / Ícone da Loja:</label>
              <Input
                @value={{@controller.form.image_url}}
                placeholder="https://segredin.com/uploads/..."
              />
            </div>

            <div class="control-group">
              <label>Link Externo de Pagamento (PIX / Checkout R$):</label>
              <Input
                @value={{@controller.form.external_url}}
                placeholder="https://..."
              />
            </div>
          </div>

          <div class="d-modal-footer">
            <DButton
              @action={{@controller.saveProduct}}
              @label="points_mall.admin.save"
              @disabled={{@controller.isSaving}}
              class="btn-primary"
            />
            <DButton
              @action={{@controller.closeModal}}
              @label="points_mall.admin.cancel"
              class="btn-default"
            />
          </div>
        </div>
      </div>
    {{/if}}
  </div>
</template>
