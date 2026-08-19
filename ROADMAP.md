# 🗺️ Roadmap & Histórico de Funcionalidades — Points Mall (Segredin)

> Documentação completa e linha do tempo de todas as funcionalidades, refatorações backend e ajustes de interface (UI/UX) implementados no plugin **Discourse Points Mall**.

---

## 📌 Visão Geral do Projeto
O **Discourse Points Mall (Segredin)** é um plugin customizado para Discourse que gerencia um ecossistema completo de gamificação, compras com pontos, check-ins diários e produtos híbridos (pontos + moeda real / links externos).

---

## ✅ Funcionalidades Concluídas

### 1. 💳 Sistema de Pagamento Híbrido (Pontos + BRL / Compra Externa)
- **Atributos no Banco de Dados & Backend:**
  - Adicionados os campos `price_brl` (decimal) e `external_url` (string) na tabela e modelo `PointsMallProduct`.
  - Atualizados os controladores administrativos (`AdminProductsController`) e serializadores para receber e expor preços em BRL e URLs de compra.
- **Interface da Loja (Storefront):**
  - Renderização dinâmica nos cards normais e de destaque (`featured`).
  - Quando um produto possui `external_url`, o botão "Comprar" se transforma em um link estilizado indicando o valor em R$ (ex: `Comprar (R$ 29,90)`), redirecionando o usuário sem deduzir pontos do saldo.
- **Painel Administrativo:**
  - Adicionados inputs para inclusão/edição rápida de preço em R$ e link de checkout externo para novos produtos ou produtos existentes.

---

### 2. 🏆 Sistema de Ranking Resiliente com Fallback em Tempo Real
- **Integração Gamification & Fallback Nativo:**
  - O sistema tenta consultar o leaderboard do `DiscourseGamification` (ID prioritário ou primeira lista ativa).
  - **Fallback Inteligente:** Caso o Gamification não esteja instalado, esteja com visão materializada desatualizada ou sem dados, o backend calcula o ranking em tempo real a partir do somatório de pontos das tabelas nativas (`PointsMallCheckin` / `DiscourseDailyCheckin`).
- **Atualização Instantânea:**
  - Garante que usuários que acabaram de realizar o check-in apareçam imediatamente no ranking sem depender de rotinas de background lentas.

---

### 3. 📅 Padronização de Formatação de Data Estática (`DD/MM/YYYY`)
- **Independência de Scripts Relativos do Core:**
  - Substituição da chamada `<span class="relative-date">` do Discourse por um helper estático puro em JavaScript (`formatDateFixed`).
- **Eliminação de Glitches de Tempo Relativo:**
  - Garante a exibição estática e precisa (ex: `19/08/2026` ou `18/08/2026`) nas tabelas do Admin, Extrato de Pontos e Histórico de Check-ins, eliminando exibições confusas como *"18 horas"*.

---

### 4. 🎨 Polimento Visual & Correções de Layout (UI/UX)
- **Correção da Barra de Ferramentas (`shop-toolbar`):**
  - Removido o posicionamento `sticky` que fazia a barra sobrepor produtos e cards durante a rolagem no desktop e mobile.
- **Alinhamento Simétrico de Cards no Desktop:**
  - Padronização das colunas da grade (`checkin-overview-grid` e `checkin-main-grid`) para a proporção `1.6fr 1fr`.
  - O card de **"Progresso de Nível"** agora alinha com precisão de pixels na borda direita em relação ao card de **"Ranking de Pontos"**.
- **Padronização da Aba de Extrato:**
  - Layout e estilos visualmente harmonizados com o resto da loja.

---

### 5. 🛡️ Estabilidade & Modo Estrito Ember/Glimmer (`.gjs`)
- **Gerenciamento Estrito de Escopo:**
  - Mantidas todas as importações necessárias (`dIcon`, `i18n`, `DButton`) no topo dos arquivos `.gjs` para total compatibilidade com o compilador de Strict Mode do Discourse/Ember.

---

## 🔮 Futuras Expansões Sugeridas (Backlog / Ideas)
1. **Integração Direta de Checkout BRL:**
   - Adicionar suporte a webhook para confirmação automática de pagamentos via Mercado Pago / Pix.
2. **Notificações em Tempo Real:**
   - Notificações de fórum para atualizações de status de pedidos de produtos físicos/virtuais.
3. **Filtros Avançados no Admin:**
   - Exportação de relatório em CSV das transações e resgates de produtos.
