# Discourse Points Mall — Plugin da Loja de Pontos e Check-in Diário

## Visão Geral do Plugin

O **Discourse Points Mall** é um plugin completo de gamificação, loja de resgates e recompensas desenvolvido exclusivamente para o fórum **Segredin.com**. O plugin permite que usuários acumulem pontos através de check-ins diários e os troquem por produtos físicos ou virtuais, além de oferecer suporte a produtos híbridos com opção de compra em Reais (R$) via gateways externos.

---

## Principais Funcionalidades

- **Loja de Resgates Híbrida**: Produtos disponíveis para troca por pontos ou link direto para pagamento em R$.
- **Sistema de Check-in Diário**: Registro diário de presença com regras de pontuação progressiva e calendário visual.
- **Ranking Resiliente de Pontos**: Algoritmo em duas camadas (Integração com Discourse Gamification + Fallback nativo em consulta SQL).
- **Histórico e Paginação de Pedidos**: Interface de gerenciamento de compras para usuários com suporte a paginação client-side (5 itens por página) e linha do tempo de status de entrega.
- **Painel Administrativo Completo**: Interface de gerenciamento para criação de produtos, aprovação de pedidos e auditoria de pontos.

---

## Arquitetura Tecnológica

- **Backend**: Ruby on Rails 7+, PostgreSQL / SQLite
- **Frontend**: Ember.js (Strict Mode Glimmer Templates `.gjs`), Vanilla JS
- **Estilização**: SCSS modular (`common/points-mall.scss` e `mobile/points-mall.scss`)

---

## Documentação Técnica e Roadmap

Para informações detalhadas sobre as decisões de arquitetura, histórico de versões, correções de incidentes de compilação e plano de desenvolvimento, consulte o arquivo [ROADMAP.md](ROADMAP.md).
