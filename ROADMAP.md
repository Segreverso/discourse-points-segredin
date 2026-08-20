# 🗺️ Roadmap Detalhado & Registro Completo de Arquitetura — Points Mall (Segredin)

> **Documento Oficial de Registro de Alterações e Arquitetura**  
> Este documento registra de forma exaustiva todas as modificações, refatorações de backend, modelos de banco de dados, regras de interface (UI/UX), correções de bugs e decisões arquiteturais implementadas no plugin **Discourse Points Mall (Segredin)**.

---

## 📅 Histórico de Versões & Marcos Alcançados

| Versão | Data | Principais Mudanças / Foco |
| :--- | :--- | :--- |
| **v0.4.2** | 20/08/2026 | Correção do getter `hasFilteredOrders` no Controller Ember (restauração da renderização dos pedidos). |
| **v0.4.1** | 20/08/2026 | Compactação de altura de cards no desktop e implementação de Paginação Client-side (5 pedidos/pág). |
| **v0.4.0** | 20/08/2026 | Redesign da thumbnail no mobile para formato Badge Compacto de 36px com `object-fit: contain`. |
| **v0.3.9** | 20/08/2026 | Trava de posição do menu "Loja de Pontos" no header (`forceAfter: true` + `order: 99 !important`). |
| **v0.3.8** | 20/08/2026 | Refatoração flexbox do layout de histórico de pedidos no mobile. |
| **v0.3.7** | 20/08/2026 | Restauração da linha do tempo (stepper gráfico) e detalhes de entrega nos cartões de pedidos. |
| **v0.3.6** | 20/08/2026 | Polimento sutil de bordas (`8-10px`), redução de sombras pesadas e ajuste do botão de check-in. |
| **v0.3.5** | 19/08/2026 | Ranking resiliente em 2 camadas (Gamification + Fallback SQL) e datas estáticas `DD/MM/YYYY`. |
| **v0.3.0** | 19/08/2026 | Lógica de Produtos Híbridos (Pontos + Compras em R$ via Link Externo). |

---

## 🛠️ Detalhamento Técnico das Modificações

### 1. 💳 Sistema de Pagamento Híbrido (Pontos + R$ / Link Externo)

#### 🗄️ Alterações de Banco de Dados & Backend
* **Campos Adicionados (`points_mall_products`):**
  * `price_brl` (`decimal`, 10 posições, 2 decimais): Guarda o preço do produto em Reais (R$).
  * `external_url` (`text`): Guarda o link de checkout externo (Hotmart, Kiwify, Mercado Pago, etc.).
* **Controlador Administrativo (`app/controllers/discourse_points_mall/admin_products_controller.rb`):**
  * Atualizada a whitelist de parâmetros permitidos para incluir `:price_brl` e `:external_url`.
* **Serializador JSON (`app/serializers/points_mall_product_serializer.rb`):**
  * Exposição dos atributos `:price_brl` e `:external_url` na API pública e administrativa do Discourse.

#### 🎨 Interface da Loja (`assets/javascripts/discourse/templates/points-mall.gjs`)
* **Lógica do Botão de Compra (`.featured-card` e `.shop-product-card`):**
  * Se o produto contiver `external_url` preenchido:
    * O botão tradicional de resgate de pontos é substituído por um link estético com tag `<a>` e classe `.btn-external-buy`.
    * O rótulo exibe automaticamente o valor em R$ (ex: `Comprar (R$ 29,90)`).
    * O clique abre a URL em uma nova aba (`target="_blank" rel="noopener noreferrer"`), **sem deduzir nenhum ponto do saldo do usuário**.
  * Se o produto for tradicional por pontos, mantém o fluxo normal de resgate.

---

### 2. 🏆 Sistema de Ranking Resiliente com Multicamadas

#### 🧠 Lógica de Fallback no Backend (`app/controllers/discourse_points_mall/checkins_controller.rb`)
Anteriormente, o ranking dependia exclusivamente do plugin `discourse-gamification` no ID `#2`. Se o ID não existisse ou a view estivesse desatualizada, retornava uma lista vazia (*"Sem dados de ranking"*).

* **Camada 1 (Gamification Integration):**
  * Busca pelo `PREFERRED_LEADERBOARD_ID` (2) ou pela primeira lista encontrada (`GamificationLeaderboard.first`).
* **Camada 2 (Fallback Nativo SQL):**
  * Se o Gamification não estiver instalado ou não retornar usuários, o sistema executa um agendamento dinâmico SQL direto na tabela `PointsMallCheckin`.
  * Soma os pontos acumulados por usuário (`group(:user_id).sum(:points_earned)`) e ordena os TOP 10.
* **Resultado:**
  * O ranking funciona **instantaneamente** após o check-in de qualquer usuário, sem depender de tarefas assíncronas lentas do Discourse.

---

### 3. 📅 Formatação de Data Estática (`DD/MM/YYYY`)

#### 🐛 O Problema Encontrado
O Discourse utiliza o helper `<span class="relative-date">` por padrão. No navegador do cliente, um script JS global intercepta essas tags e força o texto para tempo decorrido relativo (ex: *"18 horas"*, *"5 dias"*), mesmo que o backend envie a data correta.

#### 💡 A Solução Aplicada
Substituímos o helper do Discourse por uma função auxiliar pura em JavaScript (`formatDateFixed`) declarada diretamente nos módulos de template `.gjs`:

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

### 4. 📌 Estabilização da Barra de Navegação no Header (Fix de Jittering)

#### 🐛 O Problema
No desktop, o item "Loja de Pontos" ficava trocando de posição intermitentemente com os botões nativos "Categorias" ou "Recentes" na barra de navegação superior (`#navigation-bar.nav.nav-pills`).

#### 💡 Solução em Duas Camadas
1. **API Ember (`points-mall.js`)**: Injetada a flag `forceAfter: true` na chamada `addNavigationBarItem`.
2. **CSS Flexbox (`points-mall.scss`)**: Forçado `.points-mall-nav { order: 99 !important; }` para que o Flexbox trave o item à direita de forma determinística independente da ordem de carregamento assíncrono dos scripts.

---

### 5. 📱 Otimização Responsiva do Histórico de Pedidos no Mobile

#### 🐛 O Problema
Em telas móveis (< 480px), o container `.order-product-thumb` possuía dimensões fixas grandes (48px/72px). A imagem sobrepunha tags de categoria, status do pedido e os textos descritivos.

#### 💡 A Solução Aplicada (Badge de 36px)
- **Compactação**: A thumbnail foi adaptada para um **Badge Compacto de 36px × 36px** (`flex: 0 0 36px; border-radius: 8px; padding: 2px;`).
- **Escala Limpa**: Aplicado `object-fit: contain` na imagem interna e `align-items: center` no container flex `.order-card-header`.
- **Resultado**: Liberou **mais de 90% da largura útil do celular** para o título, tag de ID (`#4`), valor em pontos e o badge de status.

---

### 6. 📐 Compactação de Cards no Desktop & Paginação Client-Side

#### 🎨 Card Enxuto (`.order-card`)
- **Dimensões e Espaçamentos**: Reduzido o padding vertical de `18px` para `12px 16px`, e o gap vertical entre blocos de `16px` para `10px`.
- **Thumbnail no Desktop**: Padronizada em `44px × 44px`.
- **Linha do Tempo (Stepper)**: Círculos de etapas reduzidos de `32px` para `26px` (fonte `0.8em`), linhas de conexão reduzidas para `2px` de altura e padding do container ajustado para `8px 14px`.

#### 📄 Sistema de Paginação (`.orders-pagination`)
- **Limite por Página**: 5 pedidos por página.
- **Navegação Interativa**: Botões **Anterior** / **Próxima** com estados desabilitados nativamente na primeira/última página e indicador numérico central (`Página X de Y`).
- **Reset Dinâmico**: Ao trocar de aba/filtro ("Todos", "Físicos", "Virtuais"), a página reseta automaticamente para a página 1.

---

### 🚨 7. Catálogo de Erros de Compilação & Bugs Corrigidos

#### 🔴 Erro #1: Desbalanceamento de Chaves SCSS (`Discourse::ScssError: unmatched "}"`)
- **Causa**: Edição parcial em bloco SCSS que removeu um fechamento de chave `}` no arquivo `common/points-mall.scss`.
- **Prevenção**: Compilação local mandatória com `npx sass` antes de qualquer commit.

#### 🔴 Erro #2: Sobrescrita de Getter Ember (`hasFilteredOrders`)
- **Causa**: Durante a implementação da paginação no `controllers/points-mall.js`, a substituição de código removeu o getter `get hasFilteredOrders()`. O template `.gjs` lia a propriedade como `undefined` (falsy) e exibia a tela "Nenhum pedido realizado" mesmo existindo pedidos salvos.
- **Solução**: Restauração do getter boolean `get hasFilteredOrders() { return this.filteredOrders.length > 0; }` na versão `v0.4.2`.

---

## 📁 Arquivos Modificados no Projeto

```
discourse-points-segredin/
├── ROADMAP.md                                                    # Documentação e Roadmap Oficial (v0.4.2)
├── plugin.rb                                                     # Registro de versão v0.4.2 e SVG Icons
├── app/
│   └── controllers/
│       └── discourse_points_mall/
│           ├── admin_products_controller.rb                      # Whitelist price_brl e external_url
│           └── checkins_controller.rb                            # Ranking com Fallback nativo em SQL
├── assets/
│   ├── javascripts/discourse/
│   │   ├── initializers/points-mall.js                           # Topbar Nav (forceAfter: true)
│   │   ├── controllers/points-mall.js                            # Paginação de Pedidos e getters
│   │   └── templates/
│   │       ├── points-mall.gjs                                   # Template principal da Loja e Pedidos
│   │       └── points-mall/
│   │           ├── checkin.gjs                                   # Datas estáticas no check-in
│   │           └── orders.gjs                                    # Datas estáticas nos pedidos
│   └── stylesheets/
│       ├── common/points-mall.scss                               # order: 99 nav, cards compactos, paginação
│       └── mobile/points-mall.scss                               # Thumbnail 36px e flexbox mobile
```

---

## 🚀 Próximas Passos Recomendados (Backlog Futuro)

1. **Gateway Automático Pix/BRL:** Webhook para aprovação e liberação instantânea ao comprar via link externo.
2. **Notificações Push no Fórum:** Notificar o usuário quando um pedido físico mudar de status para "Enviado".
3. **Exportação CSV no Admin:** Botão para baixar relatório de check-ins e resgates de produtos em Excel/CSV.
