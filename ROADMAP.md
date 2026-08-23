# Roadmap Técnico e Documentação de Arquitetura — Discourse Points Mall

## Resumo Executivo e Registro do Sistema

Este documento registra a arquitetura técnica, modelo de dados, controladores Rails/Ember, componentes de interface (Glimmer/GJS), regras SCSS/CSS responsivas, suporte a internacionalização (i18n trilingue) e o histórico de evoluções do plugin **Discourse Points Mall (Segredin)**.

---

## 1. Histórico de Versões e Alterações

| Versão | Data | Módulo Afetado | Resumo da Alteração |
| :--- | :--- | :--- | :--- |
| **v0.4.27** | 23/08/2026 | Ember Route & Controller / SCSS / i18n | **Persistência de Aba (`?tab=`) & Redesign do Inventário**: Implementação de query parameter `?tab=` para manter navegação ao recarregar, alteração de título para "Cosméticos Adquiridos" e redesign completo e responsivo dos cards de cosméticos. |
| **v0.4.26** | 23/08/2026 | Rails API / Admin Templates | **Nomenclatura Concisa "Aura Dourada"**: Remoção da palavra VIP do cosmético `gold_vip` (passando para "Aura Dourada"), reservando o benefício VIP exclusivo à "Aura Rubi" (`ruby_red`). |
| **v0.4.25** | 23/08/2026 | Rails API / Admin GJS / i18n | **Nomenclatura "Aura de Avatar"**: Padronização do termo "Aura de Avatar" (e "Brilho do Nome") nas categorias, seletores admin e i18n para melhor legibilidade nos cards e interface. |
| **v0.4.24** | 23/08/2026 | Rails API / JS Initializer / SCSS | **Moldura & Nickname VIP Automáticos (`apoiador`)**: Atribuição automática da Moldura de Avatar `ruby_red` e do Brilho de Nickname `ruby_red` para membros do grupo VIP `apoiador` via `public_cosmetics`. |
| **v0.4.23** | 23/08/2026 | Rails API / JS Initializer / SCSS | **Automação do Nickname VIP (`apoiador`)**: Suporte ao brilho vermelho (`ruby_red`) para membros do grupo `apoiador` via `public_cosmetics` + extensão do `applyCosmeticsToDom` para nicknames sem layout shift. |
| **v0.4.22** | 23/08/2026 | Localização i18n (`client.*.yml`) | **Cobertura Trilingue de i18n**: Resolução de chaves ausentes (`[pt_BR.points_mall.orders.types.cosmetic]`) e padronização dos tipos `cosmetic`, `avatar_frame` e `user_flair` em `pt_BR`, `en` e `zh_CN`. |
| **v0.4.21** | 23/08/2026 | SCSS Common / Ember Controller | **Inventário Compacto & Paginação de Cosméticos**: Redesign dos cards do inventário para grid denso (`minmax(170px, 1fr)`), thumbnails de 56px e paginação client-side (8 itens por página). |
| **v0.4.2** | 20/08/2026 | Ember Controller | Restauração da propriedade `hasFilteredOrders` no controller JS para validar o render de pedidos no template GJS. |
| **v0.4.1** | 20/08/2026 | SCSS Common / Ember JS | Compactação de altura nos cartões de pedidos no desktop e adição de paginação client-side com limite de 5 itens por página. |
| **v0.4.0** | 20/08/2026 | SCSS Mobile | Redesign das thumbnails de produtos para formato Badge de 36px com alinhamento flexbox e `object-fit: contain`. |
| **v0.3.9** | 20/08/2026 | JS Initializer / SCSS | Estabilização de ordem da navegação superior no Discourse (`forceAfter: true` + `order: 99 !important`). |
| **v0.3.8** | 20/08/2026 | SCSS Mobile | Refatoração de layout e responsividade da lista de histórico de pedidos no mobile. |
| **v0.3.7** | 20/08/2026 | SCSS Common | Restauração da linha do tempo (stepper de status de pedido) e bloco de cópia rápida de código. |
| **v0.3.6** | 20/08/2026 | SCSS Common | Ajuste de geometria (`border-radius: 8-10px`), eliminação de sombras duplas e alinhamento de cores do botão de check-in. |
| **v0.3.5** | 19/08/2026 | Rails Backend / GJS | Implementação do Ranking resiliente em 2 camadas (Gamification + SQL Fallback) e formatação de datas fixas (`DD/MM/YYYY`). |
| **v0.3.0** | 19/08/2026 | Rails DB / GJS / Admin | Arquitetura de produtos híbridos (Pontos da Comunidade ou Comprar em Reais R$ via Link Externo). |

---

## 2. Detalhamento Arquitetural das Funcionalidades

### 2.1. Arquitetura de Produtos Híbridos (Pontos vs. Venda Externa R$)

#### Modelagem de Dados e Backend Rails
- **Campos Adicionados (`points_mall_products`)**:
  - `price_brl` (`decimal`, precision: 10, scale: 2): Armazena o valor monetário do produto em Reais.
  - `external_url` (`text`): URL de checkout externo de plataformas parceiras (Hotmart, Kiwify, Mercado Pago).
  - `grant_group_id` (`integer`): ID do grupo Discourse concedido automaticamente na aquisição do produto (ex: Grupo VIP `apoiador`).
- **Permissões Administrativas (`AdminProductsController`)**:
  - Whitelist de parâmetros `:price_brl`, `:external_url` e `:grant_group_id` atualizada nos métodos `create` e `update`.
- **Serialização da API (`PointsMallProductSerializer`)**:
  - Exposição direta dos campos no JSON consumido pelo frontend Ember.

#### Comportamento da Interface (`points-mall.gjs`)
- Quando a propriedade `external_url` está preenchida no objeto do produto:
  - O botão de resgate por pontos é desativado.
  - É renderizado um elemento de âncora `<a>` estilizado como `.btn-external-buy`, exibindo o valor em Reais (ex: `Comprar (R$ 29,90)`).
  - A ação abre o destino em nova aba (`target="_blank" rel="noopener noreferrer"`), sem debitar pontos do saldo do usuário no Discourse.
- Quando o campo `external_url` é nulo ou vazio, mantém-se a transação nativa por pontos.

---

### 2.2. Ranking Resiliente em Duas Camadas (Gamification + SQL Fallback)

#### Resiliência no Controller (`CheckinsController`)
A dependência única da tabela `gamification_score` era vulnerável a cenários onde a lista `#2` não existia ou não havia sido recalculada pelas tarefas assíncronas do Discourse.

1. **Camada Primária (Gamification Integration)**:
   - Tentativa de leitura do `GamificationLeaderboard` configurado no ID 2 ou do primeiro registro existente na tabela.
2. **Camada Secundária (Fallback SQL Nativo)**:
   - Caso a Camada 1 retorne vazia ou nula, o controller executa uma consulta direta na tabela `PointsMallCheckin`:
     `PointsMallCheckin.group(:user_id).sum(:points_earned)`
   - O resultado é ordenado e formatado nos TOP 10 usuários com maior saldo de pontos acumulados.
   - Isso garante atualização instantânea do ranking após cada check-in individual.

---

### 2.3. Sistema de Cosméticos Públicos e Decoração de Nicknames (`v0.4.23`)

#### Separação Conceitual: Itens de Grupo vs. Cosméticos Equipáveis
- **Itens da Loja (ex: Grupo VIP `apoiador`)**: Produtos comprados na loja que concedem associação a um grupo nativo do Discourse. Não exigem ação manual no inventário; ao ser adicionado ao grupo, os benefícios entram em vigor imediatamente.
- **Cosméticos Equipáveis (Molduras, Títulos, Card Borders, Skins)**: Produtos resgatados que ficam salvos no inventário do usuário (`UserCustomField`), podendo ser equipados ou desequipados a qualquer momento.

#### Endpoint Público (`/loja/cosmeticos` — `InventoryController`)
Para garantir que molduras e a coloração dos nicknames funcionem de forma universal para **visitantes anônimos, deslogados, moderadores e administradores**:
- O endpoint `/loja/cosmeticos` é liberado para acesso sem autenticação (`skip_before_action :ensure_logged_in`).
- Retorna um payload JSON com dois dicionários:
  - `frames`: Usuários com molduras de avatar ativas.
  - `flairs`: Usuários com brilhos de nickname ativos.
- **Automação VIP**: O controller verifica automaticamente a tabela `GroupUser` do grupo `apoiador` e injeta a chave `"ruby_red"` no dicionário `flairs` para todos os seus membros ativos.

```ruby
def public_cosmetics
  frames = UserCustomField.where(name: "jn_cosmetic_avatar_frame").where.not(value: [nil, ""]).joins(:user).pluck("users.username_lower", "user_custom_fields.value").to_h
  flairs = UserCustomField.where(name: ["jn_cosmetic_svip_glow", "jn_cosmetic_card_border"]).where.not(value: [nil, ""]).joins(:user).pluck("users.username_lower", "user_custom_fields.value").to_h

  vip_group = Group.find_by("LOWER(name) = ?", "apoiador")
  if vip_group
    GroupUser.where(group_id: vip_group.id).joins(:user).pluck("users.username_lower").each do |uname|
      flairs[uname] ||= "ruby_red"
      frames[uname] ||= "ruby_red"
    end
  end

  render json: { frames: frames, flairs: flairs }
end
```

#### Frontend DOM Observer e Isolamento Estrito de CSS (`points-mall.js` / `points-mall.scss`)
- O inicializador JS escuta mutações no DOM (`MutationObserver`) e decora elementos de username (`.names a`, `.names .username`, `a.mention`, `.user-card .username`) com a classe `jn-user-flair-<valor>`.
- **Prevenção Total de Layout Shift**:
  - Os seletores `jn-user-flair-*` são estritamente limitados às propriedades de renderização de texto (`color`, `font-weight`, `text-shadow`).
  - É proibida qualquer alteração em `display`, `padding`, `margin`, `width` ou `height` nesses seletores, protegendo as células das tabelas de tópicos (`.topic-list .posters`) contra desalinhamentos.

---

### 2.4. Matriz de Internacionalização (i18n Trilingue — `v0.4.22`)

#### Arquitetura de Chaves de Tradução
Todos os componentes visuais de filtro, resumos de estatísticas e detalhes do pedido utilizam chaves sincronizadas em 3 idiomas (`pt_BR`, `en`, `zh_CN`):

```yaml
# client.pt_BR.yml / client.en.yml / client.zh_CN.yml
points_mall:
  orders:
    types:
      product: "Produto"
      item: "Item da Loja"
      cosmetic: "Cosmético"
      avatar_frame: "Moldura de Avatar"
      user_flair: "Brilho de Usuário"
    summary:
      cosmetic: "Cosméticos"
    filters:
      cosmetic: "Cosméticos"
  shop:
    type:
      cosmetic: "Cosmético"
  admin:
    orders:
      filters:
        type:
          cosmetic: "Cosmético"
```

---

### 2.5. Design de Inventário Compacto & Paginação (v0.4.21)

#### Grid Bento Denso
- Os cards da aba **Inventário** foram compactados usando `grid-template-columns: repeat(auto-fill, minmax(170px, 1fr))`.
- As thumbnails foram padronizadas em `56px × 56px` centralizadas em caixas de `85px` de altura.
- Badges flutuantes de tipo e validade posicionadas em formato de pílula (`top: 6px`, `right: 6px`, `font-size: 0.68em`).

#### Controller Ember Paginado
- Gerenciamento de estado com `@tracked inventoryPage = 1` e `@tracked inventoryPerPage = 8`.
- Getters reativos `paginatedInventoryItems`, `inventoryTotalPages` e `hasMultipleInventoryPages` para navegar suavemente entre páginas de cosméticos resgatados.

---

### 2.6. Formatação de Data Estática (`DD/MM/YYYY`)

#### Resolução do Conflito com Script Global do Discourse
O Discourse força a alteração dinâmica de tags de data para tempo relativo ("há 2 horas", "há 5 dias"). Para dados transacionais e histórico de pedidos, é mandatória a exibição da data civil fixa.

#### Função Auxiliar de Conversão (`formatDateFixed`)
```javascript
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
```

---

### 2.7. Estabilização do Item de Navegação no Header

#### Solução em Duas Camadas
1. **Camada Lógica (Initializer JS)**: Injeção do argumento `forceAfter: true` na chamada `addNavigationBarItem` dentro de `initializers/points-mall.js`.
2. **Camada Estética (Flexbox CSS)**: Aplicação da regra `.points-mall-nav { order: 99 !important; }` no SCSS global (`common/points-mall.scss`), travando o item deterministicamente na ponta direita do contêiner flex.

---

## 3. Catálogo de Erros de Compilação e Mitigações Registradas

### 3.1. Incidente de Compilação SCSS (`Discourse::ScssError: unmatched "}"`)
- **Causa**: Edição parcial no bloco `.order-copy-action` dentro de `common/points-mall.scss` que resultou no fechamento incorreto de chaves aninhadas.
- **Impacto**: Aborto na tarefa `rake assets:precompile` durante o build do Docker no Discourse.
- **Protocolo de Mitigação**: Obrigatoriedade de execução prévia de compilação sintática via Dart Sass (`npx sass`) no ambiente local antes do envio para controle de versão.

### 3.2. Incidente de Ocultação de Pedidos por Ausência de Getter Ember
- **Causa**: Durante a implementação do fluxo de paginação no controller JS `points-mall.js`, o getter `hasFilteredOrders` foi sobrescrito involuntariamente.
- **Impacto**: O template `.gjs` lia `@controller.hasFilteredOrders` como valor indefinido (falso) e desviava o fluxo para o bloco alternativo.
- **Resolução (v0.4.2)**: Restauração imediata do método `get hasFilteredOrders() { return this.filteredOrders.length > 0; }`.

---

## 4. Estrutura Atualizada do Projeto

```
discourse-points-segredin/
├── ROADMAP.md                                                    # Documentação Técnica e Roadmap Oficial (v0.4.23)
├── plugin.rb                                                     # Registro da versão v0.4.23 e SVG Icons do Discourse
├── config/
│   └── locales/
│       ├── client.pt_BR.yml                                      # Localização Português (Brasil)
│       ├── client.en.yml                                         # Localização Inglês
│       └── client.zh_CN.yml                                      # Localização Chinês (Simplificado)
├── app/
│   └── controllers/
│       └── discourse_points_mall/
│           ├── admin_products_controller.rb                      # Whitelist price_brl, external_url e grant_group_id
│           ├── checkins_controller.rb                            # Algoritmo de ranking com Fallback SQL
│           └── inventory_controller.rb                           # Public Cosmetics API com automação VIP apoiador
├── assets/
│   ├── javascripts/discourse/
│   │   ├── initializers/points-mall.js                           # Public Cosmetics DOM Observer (Frames & Flairs)
│   │   ├── controllers/points-mall.js                            # Paginação de pedidos e inventário
│   │   └── templates/
│   │       ├── points-mall.gjs                                   # Layout principal da loja, inventário e pedidos
│   │       └── points-mall/
│   │           ├── checkin.gjs                                   # Ranking e módulo de check-in diário
│   │           └── orders.gjs                                    # Histórico de pedidos e estatísticas
│   └── stylesheets/
│       ├── common/points-mall.scss                               # Scss global, jn-avatar-frame e jn-user-flair
│       └── mobile/points-mall.scss                               # Estilos responsivos para telas compactas
```

---

## 5. Cronograma de Desenvolvimento Futuro (Backlog Expandido)

### 🎯 Fase 1: Automação de Checkout & Webhooks (Q3 2026)
- **Integração Pix Automática (PagHiper)**: Webhook assíncrono para dar baixa imediata nos pedidos da loja e liberar pontos ou o grupo VIP instantaneamente.
- **WebMCP Bridge / Bot**: Suporte a execução de comandos de compras via agentes interativos no fórum.

### 🔔 Fase 2: Notificações & Notificações de Expiração (Q4 2026)
- **Notificações Nativas do Discourse**: Enviar notificação de sistema no fórum quando um produto for entregue/concluído pelo administrador.
- **Alerta de Expiração de Cosmético**: Avisar o usuário 3 dias antes da expiração de sua moldura ou skin de tema.

### 📊 Fase 3: Analytics Administrativo e Exportação de Dados (Q1 2027)
- **Painel Financeiro / Extrato de Pontos**: Gráfico estatístico no painel admin mostrando movimentação diária de pontos emitidos e resgatados.
- **Exportação CSV/Excel**: Exportar histórico de pedidos e auditoria de resgates para relatórios externos.

### 🏆 Fase 4: Gamificação Avançada & Conquistas de Loja (Q2 2027)
- **Badges Dinâmicas por Compras**: Conceder conquistas automáticas do Discourse baseadas em metas de resgates na loja (ex: "Colecionador de Molduras", "Cliente Frequente").
