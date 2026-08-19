# 🗺️ Roadmap Detalhado & Registro Completo de Arquitetura — Points Mall (Segredin)

> **Documento Oficial de Registro de Alterações e Arquitetura**  
> Este documento registra de forma exaustiva todas as modificações, refatorações de backend, modelos de banco de dados, regras de interface (UI/UX), correções de bugs e decisões arquiteturais implementadas no plugin **Discourse Points Mall (Segredin)**.

---

## 📅 Resumo Geral das Implementações

| Categoria | Descrição Resumida |
| :--- | :--- |
| **Monetização Híbrida** | Suporte a produtos comprados com Pontos do Fórum ou Moeda Real (R$) via Link Externo. |
| **Resiliência do Ranking** | Ranking dinâmico em 2 camadas (Plugin Gamification + Fallback nativo em SQL de Check-ins). |
| **Formatação de Datas** | Eliminação de contadores relativos ("18 horas") substituídos por datas fixas `DD/MM/YYYY`. |
| **Polimento Visual (UI/UX)** | Geometria de bordas (6-8px), alinhamento de grids no desktop e remoção de bug de scroll sticky. |
| **Extrato & Histórico** | Tradução completa de transações, paginação otimizada e layout responsivo mobile. |
| **Compilação Strict Mode** | Resolução de escopo de componentes Glimmer (`.gjs`) como `dIcon`, `i18n` e `DButton`. |

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

#### ⚙️ Painel de Administração (`admin/assets/javascripts/discourse/templates/admin-plugins/show/discourse-points-mall-manage.gjs`)
* Adicionados campos de entrada `<Input>` para **Preço R$** (passo `0.01`) e **URL Externa** tanto no formulário de criação de novos produtos quanto na tabela de edição rápida de produtos existentes.

---

### 2. 🏆 Sistema de Ranking Resiliente com Multicamadas

#### 🧠 Lógica de Fallback no Backend (`app/controllers/discourse_points_mall/checkins_controller.rb`)
Anteriormente, o ranking dependia exclusivamente do plugin `discourse-gamification` no ID `#2`. Se o ID não existisse ou a view estivesse desatualizada, retornava uma lista vazia (*"Sem dados de ranking"*).

* **Camada 1 (Gamification Integration):**
  * Busca pelo `PREFERRED_LEADERBOARD_ID` (2) ou pela primeira lista encontrada (`GamificationLeaderboard.first`).
* **Camada 2 (Fallback Nativo SQL):**
  * Se o Gamification não estiver instalado ou não retornar usuários, o sistema executa um agendamento dinâmico SQL direto na tabela `PointsMallCheckin` (ou `DiscourseDailyCheckin::Checkin`).
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

#### 📍 Onde foi aplicado:
1. `discourse-points-mall-manage.gjs` (Tabela de tendência de check-ins, check-ins recentes e lista de pedidos do Admin).
2. `points-mall.gjs` (Histórico de check-ins da loja, extrato de transações e lista de pedidos do usuário).
3. `points-mall/checkin.gjs` & `points-mall/orders.gjs`.

---

### 4. 🎨 Design System, Geometria e Polimento de UI/UX

#### 📐 Alinhamento de Grids no Desktop
* **Correção de Desalinhamento:**
  * O bloco superior (`checkin-overview-grid`) usava a proporção `1.3fr 1fr`.
  * O bloco inferior (`checkin-main-grid`) usava a proporção `1.6fr 1fr`.
* **Ajuste:** Padronizamos ambos os blocos com `grid-template-columns: 1.6fr 1fr;` e `align-items: stretch;`.
* **Efeito:** O card **"Progresso de Nível"** agora possui a exata mesma largura e alinhamento de borda direita do card **"Ranking de Pontos"**.

#### 📱 Barra de Ferramentas da Loja (`.shop-toolbar`)
* **Remoção do Bug de Scroll Sticky:**
  * Removido o estilo `position: sticky` que fazia a barra de categorias acompanhar o scroll de maneira desalinhada e sobrepor os cards de produtos.
  * Definido fundo sólido (`--secondary`) e posicionamento relativo para fluidez total em telas mobile e desktop.

#### 📊 Extrato / Histórico de Transações (`.ledger-event-item`)
* **Tradução e Paginação:**
  * Removidos textos de fallback em chinês/inglês das transações de pontos.
  * Implementada paginação client-side para evitar lentidão no DOM quando o usuário possui histórico extenso.
  * Layout responsivo otimizado para dispositivos móveis.

---

### 5. 🛡️ Estabilidade & Compilação Strict Mode Ember/Glimmer (`.gjs`)

#### ⚠️ Correção do Erro de Compilação
No Ember Glimmer Strict Mode, todos os componentes e helpers utilizados dentro do bloco `<template>` precisam estar explicitamente importados no topo do arquivo.

* **Importações Restauradas:**
  * `import dIcon from "discourse/ui-kit/helpers/d-icon";`
  * `import { i18n } from "discourse-i18n";`
  * `import DButton from "discourse/ui-kit/d-button";`
* **Arquivos Protegidos:**
  * `discourse-points-mall-manage.gjs`
  * `points-mall.gjs`
  * `points-mall/checkin.gjs`
  * `points-mall/orders.gjs`

---

## 📁 Arquivos Modificados no Projeto

```
discourse-points-segredin/
├── ROADMAP.md                                                    # Documentação e Roadmap Oficial
├── app/
│   └── controllers/
│       └── discourse_points_mall/
│           ├── admin_products_controller.rb                      # Permissões de campos price_brl e external_url
│           └── checkins_controller.rb                            # Ranking com Fallback nativo em SQL
├── admin/
│   └── assets/javascripts/discourse/templates/admin-plugins/show/
│       └── discourse-points-mall-manage.gjs                     # Admin UI (Campos BRL + Datas Fixas)
└── assets/
    ├── javascripts/discourse/templates/
    │   ├── points-mall.gjs                                       # Loja Principal, Botão Híbrido, Extrato
    │   └── points-mall/
    │       ├── checkin.gjs                                       # Datas estáticas no checkin
    │       └── orders.gjs                                        # Datas estáticas nos pedidos
    └── stylesheets/
        ├── common/points-mall.scss                               # Grids 1.6fr 1fr, Botão BRL, Toolbar fix
        └── mobile/points-mall.scss                               # Responsividade mobile da barra e cards
```

---

## 🚀 Próximas Passos Recomendados (Backlog Futuro)

1. **Gateway Automático Pix/BRL:** Integração via webhook para aprovação e liberação imediata ao comprar via link externo.
2. **Notificações Push no Fórum:** Notificar o usuário quando um pedido físico mudar para "Enviado".
3. **Exportação CSV no Admin:** Botão para baixar relatório de check-ins e resgates de produtos.
