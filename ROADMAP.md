# Roadmap Técnico e Documentação de Arquitetura — Discourse Points Mall

## Resumo Executivo e Registro do Sistema

Este documento registra a arquitetura técnica, modelo de dados, controladores Rails/Ember, componentes de interface (Glimmer/GJS), regras SCSS/CSS responsivas, suporte a internacionalização (i18n trilingue) e o histórico de evoluções do plugin **Discourse Points Mall (Segredin)**.

---

## 1. Histórico de Versões e Alterações

| Versão | Data | Módulo Afetado | Resumo da Alteração |
| :--- | :--- | :--- | :--- |
| **v0.5.1** | 30/09/2026 | Rails Model / Rails Controllers / DB Migration / Admin GJS / i18n (pt\_BR, en) | **Correção Crítica de Sequências de Check-in (Bugfix Makeup Streak)**: Diagnóstico e correção de 4 falhas encadeadas que destruíam a sequência (`streak_days`) de membros que usaram o Cartão de Reposição após indisponibilidade do plugin (27/09/2026). Inclui: (1) novo algoritmo de recálculo em cascata `PointsMallCheckin.recalculate_streaks_for_user`, (2) remoção do `streak_days: 1` hardcoded na ação `perform_makeup`, (3) correção do cálculo de `current_streak` no `summary_payload` (não zerando mais antes do check-in do dia), (4) migration de reparo de dados históricos (`20260930000024`), (5) endpoint administrativo protegido `POST /manage/checkins/recalculate` com botão no painel Admin. Auditoria de segurança concluída com conformidade total às Regras 04, 05, 06, 08, 09 do DiscourseSkill. |
| **v0.5.0** | 22/09/2026 | Backend Rails / Segurança / Sidekiq / i18n / Testes | **Auditoria Estrutural de Conformidade Discourse (Discourse Skill Protocol)**: Refatoração integral de segurança e conformidade baseada nas 30 Regras do protocolo *Discourse Extension Review*. Eliminação de endpoints legados (`pan.justnainai.com`), remoção de bypass SSL (`VERIFY_NONE` -> `VERIFY_PEER`), desacoplamento de transações de banco com criação do Sidekiq Job assíncrono `PointsMallFulfillExternalOrder`, implementação da action `orders#show` com controle `Guardian`, cobertura trilingue de i18n em português e adição de suite de testes RSpec (`spec/requests/orders_controller_spec.rb`). |
| **v0.4.33** | 02/09/2026 | JS Initializers (`points-mall.js`) / i18n | **Restauração do Atalho "Loja" no Menu Superior (`#navigation-bar`)**: Reativada a injeção via `api.addNavigationBarItem` com redirecionamento para `/loja`, filtrado para usuários autenticados (`currentUser`), e renomeado no menu de "Loja de Pontos" para apenas "Loja" (`points_mall.nav_title`). |
| **v0.4.32** | 26/08/2026 | JS Initializers (`points-mall.js`) | **Remoção do Item no Top Navigation Bar (`#navigation-bar`)**: Removida a chamada `api.addNavigationBarItem` para desativar a injeção do botão "Loja de Pontos" na barra superior de navegação (`nav-pills`), permitindo que a navegação seja gerenciada customizadamente na barra lateral (`sidebar`). |
| **v0.4.31** | 26/08/2026 | Ember Route Map & Admin Routes | **Isolamento Estrito das Rotas Admin (`/admin/plugins`)**: Alterado o caminho em `admin-discourse-points-mall-plugin-route-map.js` de `{ path: "/" }` para `{ path: "/discourse-points-mall" }` e inserida verificação em `beforeModel` para impedir que o painel de admin da loja seja indevidamente renderizado ao visualizar outros plugins no painel do Discourse (`segredin.com`). |
| **v0.4.30** | 25/08/2026 | JS Initializers | **Compatibilidade Discourse v3.5+ (`addTrackedPostProperties`)**: Substituição do método obsoleto `api.includePostAttributes` por `api.addTrackedPostProperties` com fallback retrocompatível para versões anteriores do Discourse. |
| **v0.4.29** | 23/08/2026 | GJS / SCSS Common | **Layout Vertical Proporcional do Inventário**: Correção de sobreposição de texto flexbox no inventário. Redesenho para card vertical com imagem container de 110px (`object-fit: contain`), badges organizadas e botão de ação sem colisão. |
| **v0.4.28** | 23/08/2026 | Ember Route & Controller / GJS / SCSS | **Garantia de Persistência em Refresh + Card Horizontal Bento**: Implementação de `setupController` com fallback triplo (QueryParam + LocalStorage + ReplaceState) e refatoração do layout do card do inventário para formato Bento horizontal (64x64px lateral), otimizando o aproveitamento de espaço. |
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

### 2.0-A. Correção Crítica de Sequências de Check-in (v0.5.1)

> **Contexto Operacional:**
> Em 27/09/2026, o plugin foi temporariamente desativado para manutenção técnica. Ao ser reativado, verificou-se que membros que usaram a moeda de reposição (Cartão de Reposição / 补签卡) para preencher o dia 27 perderam suas sequências históricas, enquanto outros membros mantiveram suas sequências normalmente. Esta seção documenta a investigação forense, as 4 falhas identificadas, a solução implementada e a auditoria de segurança conduzida.

#### 1. Diagnóstico: Por que alguns perderam e outros não?

A distinção entre usuários afetados e não afetados foi determinada pelo **momento do check-in em relação à janela de indisponibilidade**:

| Cenário | Resultado |
| :--- | :--- |
| Fez check-in **antes** da desativação no dia 27 | ✅ Sequência mantida (registro do dia 27 já existia no banco) |
| **Não** fez check-in no dia 27 (plugin estava offline) + usou Reposição nos dias seguintes | ❌ Sequência quebrada (4 falhas encadeadas) |

#### 2. As 4 Falhas Encadeadas Identificadas

##### Falha A — `streak_days` fixo em `1` na criação da reposição

**Arquivo:** `app/controllers/discourse_points_mall/checkins_controller.rb` — método `perform_makeup`

```ruby
# ❌ ANTES (código defeituoso)
::PointsMallCheckin.create!(
  user_id: locked_user.id,
  checkin_date: target_date,
  points_earned: 0,
  streak_days: 1,  # ← hardcoded, ignora toda a sequência histórica
)
```

Ao registrar a reposição do dia 27, o banco recebia `streak_days: 1`, independentemente de o membro ter 7, 30 ou 60 dias consecutivos antes daquela data.

##### Falha B — Ausência de propagação em cascata (Forward Propagation)

Ao usar a reposição **depois** de já ter feito check-in nos dias 28, 29 e 30, os registros existentes (28 → `streak_days: 1`, 29 → `streak_days: 2`, 30 → `streak_days: 3`) permaneciam congelados. Nenhum recálculo retroativo era disparado, desconectando o passado do presente permanentemente.

##### Falha C — Ranking lê `streak_days` estático do banco

**Arquivo:** `app/controllers/discourse_points_mall/checkins_controller.rb` — método `ranking_payload`

```ruby
# O ranking não calculava dinamicamente; lia o valor fixo no banco:
streak_by_user[c.user_id] ||= c.streak_days.to_i
```

Como o registro mais recente tinha `streak_days` baixo (1, 2 ou 3), o ranking exibia o membro com sequência mínima, mesmo que historicamente ele tivesse uma grande sequência.

##### Falha D — `current_streak` zerando antes do check-in do dia atual

**Arquivo:** `app/controllers/discourse_points_mall/checkins_controller.rb` — método `summary_payload`

```ruby
# ❌ ANTES: se o usuário não fez o check-in de hoje, retorna 0
current_streak = calculate_streak_for(today, checkin_dates)
# calculate_streak_for tenta encontrar 'today' no date_map;
# se hoje não consta (check-in ainda não feito), o loop para na 1ª iteração → retorna 0
```

Todo membro ao abrir o painel pela manhã via um `current_streak: 0`, mesmo tendo uma sequência ativa de ontem, gerando confusão e falsa percepção de sequência quebrada.

#### 3. A Solução: 5 Camadas de Correção

##### Camada 1 — Novo algoritmo determinístico de recálculo em cascata

**Arquivo:** `app/models/points_mall_checkin.rb`

Adicionados dois métodos de classe ao modelo:

```ruby
# Recalcula os streak_days de um único usuário em ordem cronológica estrita
def self.recalculate_streaks_for_user(user_id)
  records = where(user_id: user_id).order(checkin_date: :asc)
  return 0 if records.empty?

  current_streak = 0
  previous_date = nil

  records.each do |record|
    if previous_date && record.checkin_date == (previous_date + 1.day)
      current_streak += 1  # consecutivo → incrementa
    else
      current_streak = 1   # gap real → reinicia
    end
    # Atualiza apenas registros com valores divergentes (zero writes desnecessários)
    record.update_columns(streak_days: current_streak, updated_at: Time.zone.now) if record.streak_days != current_streak
    previous_date = record.checkin_date
  end
  current_streak
end

# Executa recalculate_streaks_for_user para todos os usuários com check-ins
def self.recalculate_all_streaks!
  user_ids = distinct.pluck(:user_id)
  user_ids.each { |uid| recalculate_streaks_for_user(uid) }
  user_ids.size
end
```

##### Camada 2 — Remoção do `streak_days: 1` hardcoded na reposição

**Arquivo:** `app/controllers/discourse_points_mall/checkins_controller.rb` — método `perform_makeup`

```ruby
# ✅ DEPOIS: calcula o streak real antes de persistir
prev_checkin = ::PointsMallCheckin.find_by(user_id: locked_user.id, checkin_date: target_date - 1.day)
initial_streak = prev_checkin ? (prev_checkin.streak_days.to_i + 1) : 1

checkin = ::PointsMallCheckin.create!(
  user_id: locked_user.id,
  checkin_date: target_date,
  points_earned: 0,
  streak_days: initial_streak,
)

# Propagação em cascata: recalcula todos os check-ins posteriores do usuário
::PointsMallCheckin.recalculate_streaks_for_user(locked_user.id)
checkin.reload  # recarrega o valor final pós-propagação
```

O resultado imediato: ao registrar o dia 27, os dias 28, 29 e 30 existentes têm seus `streak_days` **atualizados em cascata**, reconectando a sequência histórica completa automaticamente.

##### Camada 3 — Correção do cálculo de `current_streak` no resumo

**Arquivo:** `app/controllers/discourse_points_mall/checkins_controller.rb` — método `summary_payload`

```ruby
# ✅ DEPOIS: sequência ativa se o usuário fez check-in ontem (mesmo sem fazer hoje ainda)
current_streak =
  if checked_in_today
    calculate_streak_for(today, checkin_dates)       # fez hoje → conta da data de hoje
  elsif date_map[today - 1.day]
    calculate_streak_for(today - 1.day, checkin_dates)  # fez ontem → mantém ativa
  else
    0                                                # nenhum → sequência inativa
  end
```

Efeito: o membro acorda, abre o painel e vê sua sequência ativa. Ela só **aparecerá como 0** se realmente houver um gap não coberto.

##### Camada 4 — Migration de reparo histórico automático

**Arquivo:** `db/migrate/20260930000024_recalculate_points_mall_checkin_streaks.rb`

Uma migration Rails em SQL nativo (via `DB.query` / `DB.exec` do Discourse) que, ao ser executada durante o `launcher rebuild app`, percorre **todos os usuários** e corrige os `streak_days` em ordem cronológica:

```ruby
class RecalculatePointsMallCheckinStreaks < ActiveRecord::Migration[7.0]
  def up
    return unless table_exists?(:points_mall_checkins)
    user_ids = DB.query_single("SELECT DISTINCT user_id FROM points_mall_checkins")
    user_ids.each do |user_id|
      records = DB.query("SELECT id, checkin_date, streak_days FROM points_mall_checkins "\
                         "WHERE user_id = :user_id ORDER BY checkin_date ASC", user_id: user_id)
      # ... lógica de recalculo com update direto por SQL parametrizado
    end
  end

  def down
    # Irreversível por design (reparação de dados; sem down necessário)
  end
end
```

**Propriedades de segurança da migration:**
- Guard clause: `return unless table_exists?` — não falha em instâncias sem o plugin.
- Idempotente: pode ser reexecutada sem corromper dados.
- Independente de código Ruby: usa apenas a API `DB` do Discourse (resistente a renomeações futuras de modelo).
- Não destrói nem renomeia colunas: operação de escrita mínima e segura.

##### Camada 5 — Endpoint Administrativo de Reparo Imediato

**Rota:** `POST /admin/plugins/discourse-points-mall/manage/checkins/recalculate`

**Autorização:** Dupla camada — `AdminConstraint` na rota + herança de `::Admin::AdminController` no controller + `requires_plugin`.

**Controller:** `app/controllers/discourse_points_mall/admin_checkins_controller.rb`

```ruby
def recalculate
  count = ::PointsMallCheckin.recalculate_all_streaks!
  render json: { success: true, recalculated_users: count }
rescue StandardError => e
  Rails.logger.error("[points-mall] recalculate streaks failed: #{e.class} #{e.message}")
  render_json_error(e.message, status: 500)
end
```

O botão **"Recalcular Sequências"** foi adicionado ao cabeçalho da aba **Check-ins** no painel administrativo do plugin (`Admin → Plugins → Loja de Pontos → Check-ins`), permitindo disparo manual sem rebuild do container.

#### 4. Fluxo de Recuperação Completo (Diagrama)

```
[Dia 26] streak: N  ─→  [Dia 27] REPOSIÇÃO  ─→  [Dia 28] streak: N+2
                              ↓
                   recalculate_streaks_for_user()
                              ↓
            Percorre 26 → 27 → 28 → 29 → 30 em ordem crescente
                              ↓
              Atualiza streak_days de forma contínua e conectada
                              ↓
            [Dia 26] N  →  [Dia 27] N+1  →  [Dia 28] N+2  →  ...
```

#### 5. Auditoria de Segurança e Conformidade (DiscourseSkill — Regras Verificadas)

| Regra | Descrição | Status |
| :---: | :--- | :---: |
| **04** | Migrations seguras, idempotentes e sem dependência de código externo | ✅ **Conforme** |
| **05** | Endpoint de recálculo protegido por `AdminConstraint` + `Admin::AdminController` | ✅ **Conforme** |
| **06** | Nenhuma interpolação de input externo em SQL — uso de bind parametrizado `(:id, :streak)` | ✅ **Conforme** |
| **08** | Resposta do endpoint retorna apenas `{ success, recalculated_users }` — zero vazamento de PII | ✅ **Conforme** |
| **09** | Operação síncrona adequada ao volume atual; recomendação de migração para Sidekiq se base > 100k usuários | ℹ️ **Observação Futura** |
| **14** | Botão e labels de recálculo devidamente cadastrados nos locales `pt_BR` e `en` | ✅ **Conforme** |

**Veredito:** Zero vulnerabilidades introduzidas. Zero vazamento de informações privadas.

---


### 2.0. Auditoria Estrutural e Conformidade Discourse (v0.5.0)

> **Base Normativa e Créditos Técnicos:**
> Esta grande atualização de conformidade, estabilidade e segurança foi auditada e implementada com base rigorosa nas 30 diretrizes do **Discourse Extension Review Protocol (Discourse Skill)**. O protocolo forneceu os critérios objetivos para erradicação de vulnerabilidades, auditoria de ciclo de vida de dados e desacoplamento de requisições de rede.

#### 1. Segurança de Transporte e Erradicação de Domínios Fantasma (Regras 06 e 07)
- **Eliminação de `pan.justnainai.com` e `game.justnainai.com`:** Removidas todas as chamadas hardcoded herdadas da comunidade de origem chinesa (`JustNaiNai`).
- **Remoção de Bypass SSL:** Extinta a diretiva vulnerável `http.verify_mode = OpenSSL::SSL::VERIFY_NONE`. Toda comunicação externa agora exige validação estrita de autoridade certificadora (`OpenSSL::SSL::VERIFY_PEER`).
- **Parametrização Opcional em SiteSettings:** Criadas configurações administrativas (`points_mall_netdisk_enabled`, `points_mall_netdisk_endpoint`, `points_mall_game_voucher_enabled`, etc.) com valores padrão seguros (desativados). Se o serviço não estiver configurado, o pedido é rejeitado na camada de validação antes de qualquer transação de banco.

#### 2. Desacoplamento Transacional e Resiliência com Sidekiq (Regras 04, 09 e 10)
- **Fim das Threads Bloqueadas no Puma:** Removidas as chamadas HTTP síncronas de até 20 segundos que ocorriam dentro do bloco `::PointsMallOrder.transaction` sob bloqueio pessimista (`User.lock`).
- **Novo Job Assíncrono (`::Jobs::PointsMallFulfillExternalOrder`):** A action `create` apenas valida o saldo, deduz os pontos e cria o pedido com status `pending`, despachando a entrega externa para a fila do Sidekiq.
- **Idempotência e Estorno Automático:** O job utiliza `order.id` como chave de idempotência. Se a entrega externa falhar de forma definitiva, o pedido é marcado como `failed` e os pontos são estornados automaticamente para a carteira do usuário com registro no extrato.

#### 3. Integridade da API e Rota `orders#show` (Regras 02, 05 e 15)
- **Ação `show` Implementada:** Sanada a divergência da rota `resources :orders, only: [:index, :create, :show]`.
- **Autorização Robusta (Guardian):** Usuários comuns só podem consultar pedidos de sua própria autoria (`order.user_id == current_user.id`), enquanto administradores e moderadores (`current_user.staff?`) possuem permissão de auditoria global.

#### 4. Internacionalização (i18n) e Limpeza de Código (Regras 11 e 25)
- **100% em Português Brasileiro:** Erradicadas todas as mensagens chinesas (`该订单已发过货...`) e strings corrompidas (`???????`) dos arquivos Ruby.
- **Dicionário Unificado:** Centralizadas todas as mensagens de erro e descrições de extrato em `config/locales/server.pt_BR.yml`.

#### 5. Suite de Testes Automatizados (Regras 16 e 17)
- **Criação de `spec/requests/discourse_points_mall/orders_controller_spec.rb`:** Testes de requisição cobrindo autenticação, autorização de acesso ao pedido (próprio vs. terceiros vs. staff) e rejeição limpa quando o serviço externo está desativado.

#### 6. Correção do Ciclo de Vida e Expiração de Cosméticos (Bugfix Inventário & Auras)
- **Causa Raiz Identificada:** O item no card do inventário indicava `EXPIRADO` corretamente porque `item_payload` calculava a validade baseada no pedido, mas o cosmético continuava visível no avatar do cabeçalho e posts. Os motivos eram:
  1. `equipped_payload` retornava o cosmético equipado lendo apenas a presença da chave em `current_user.custom_fields`, sem validar a data de expiração.
  2. Ausência de limpeza Just-in-Time (JIT): `cleanup_expired_cosmetics!` não estava implementada no controller.
  3. O job `PointsMallExpireCosmetics` rodava apenas uma vez a cada 24 horas (`every 1.day`), mantendo o cosmético equipado no banco por horas após vencer.
  4. Os serializadores (`basic_user`, `user_card`, `post`) e o endpoint `public_cosmetics` não filtravam `expires_at` em tempo real.
  5. No frontend, o mapa `userFrameCache` em `points-mall.js` não expurgava usuários expirados ao receber o payload público atualizado.
- **Solução em 6 Camadas de Defesa:**
  1. **Limpeza JIT (`cleanup_expired_cosmetics!`):** Executada automaticamente no `index`, `equip` e `unequip`, removendo imediatamente chaves expiradas e restaurando títulos anteriores.
  2. **Validação Estrita em `equipped_payload`:** Itens com validade vencida são ignorados na montagem do JSON de cosméticos equipados.
  3. **Filtro SQL em `public_cosmetics`:** Cláusula `WHERE` rejeita qualquer moldura ou flair cujo campo `_expires_at` seja anterior ao horário atual.
  4. **Guarda nos Serializadores:** Serializadores Discourse checam `_expires_at <= Time.zone.now` antes de enviar as classes de moldura.
  5. **Job de Expiração Otimizado:** Intervalo reduzido para `every 10.minutes` com limpeza explícita do cache ActiveRecord de `custom_fields`.
  6. **Sincronização de Cache Client-Side:** `points-mall.js` sincroniza o `userFrameCache` limpando chaves obsoletas.
  7. **Cobertura de Testes:** Criação de `spec/requests/discourse_points_mall/inventory_controller_spec.rb` validando limpeza JIT, filtragem pública e bloqueio de re-equipamento de itens expirados.

---

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

### 3.1. Incidente de Compilação SCSS (`Discourse::ScssError: unmatched "}")`
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
├── ROADMAP.md                                                    # Documentação Técnica e Roadmap Oficial (v0.5.1)
├── plugin.rb                                                     # Registro da versão v0.5.1 + rota recalculate
├── config/
│   └── locales/
│       ├── client.pt_BR.yml                                      # Localização Português (Brasil) + chaves recalculate v0.5.1
│       ├── client.en.yml                                         # Localização Inglês + chaves recalculate v0.5.1
│       └── client.zh_CN.yml                                      # Localização Chinês (Simplificado)
├── app/
│   ├── models/
│   │   └── points_mall_checkin.rb                                # [v0.5.1] recalculate_streaks_for_user + recalculate_all_streaks!
│   └── controllers/
│       └── discourse_points_mall/
│           ├── admin_checkins_controller.rb                       # [v0.5.1] Endpoint de recálculo administrativo
│           ├── admin_products_controller.rb                       # Whitelist price_brl, external_url e grant_group_id
│           ├── checkins_controller.rb                             # [v0.5.1] perform_makeup com propagação em cascata + current_streak fix
│           └── inventory_controller.rb                            # Public Cosmetics API com automação VIP apoiador
├── db/
│   └── migrate/
│       └── 20260930000024_recalculate_points_mall_checkin_streaks.rb  # [v0.5.1] Migration de reparo histórico de sequências
├── admin/assets/javascripts/discourse/
│   ├── controllers/admin-plugins/show/discourse-points-mall-manage.js  # [v0.5.1] Action recalculateCheckinStreaks
│   └── templates/admin-plugins/show/discourse-points-mall-manage.gjs   # [v0.5.1] Botão "Recalcular Sequências" na aba Check-ins
├── assets/
│   ├── javascripts/discourse/
│   │   ├── initializers/points-mall.js                            # Public Cosmetics DOM Observer (Frames & Flairs)
│   │   ├── controllers/points-mall.js                             # Paginação de pedidos e inventário
│   │   ├── controllers/admin-plugins/show/discourse-points-mall-manage.js  # [v0.5.1] Action recalculateCheckinStreaks (mirror)
│   │   └── templates/
│   │       ├── points-mall.gjs                                    # Layout principal da loja, inventário e pedidos
│   │       ├── admin-plugins/show/discourse-points-mall-manage.gjs  # [v0.5.1] Botão de recálculo no painel admin (mirror)
│   │       └── points-mall/
│   │           ├── checkin.gjs                                    # Ranking e módulo de check-in diário
│   │           └── orders.gjs                                     # Histórico de pedidos e estatísticas
│   └── stylesheets/
│       ├── common/points-mall.scss                                # Scss global, jn-avatar-frame e jn-user-flair
│       └── mobile/points-mall.scss                                # Estilos responsivos para telas compactas
└── spec/
    └── requests/discourse_points_mall/
        ├── inventory_controller_spec.rb                           # Testes de inventário e expiração de cosméticos
        └── orders_controller_spec.rb                              # Testes de autorização de pedidos
```

---

## 5. Cronograma de Desenvolvimento Futuro (Backlog Expandido)

### ✅ Concluído — Fase 0: Estabilidade e Correções Críticas (Q3 2026)

| Item | Status | Versão |
| :--- | :---: | :---: |
| Auditoria estrutural de conformidade Discourse (30 regras) | ✅ Concluído | v0.5.0 |
| Remoção de bypass SSL e endpoints legados chineses | ✅ Concluído | v0.5.0 |
| Sidekiq Job assíncrono `PointsMallFulfillExternalOrder` | ✅ Concluído | v0.5.0 |
| Correção do ciclo de vida e expiração de cosméticos | ✅ Concluído | v0.5.0 |
| **Bugfix crítico de sequências de check-in (makeup streak reset)** | ✅ Concluído | **v0.5.1** |
| **Migration de reparo histórico de streak_days corrompidos** | ✅ Concluído | **v0.5.1** |
| **Endpoint administrativo de recálculo de sequências** | ✅ Concluído | **v0.5.1** |

---

### 🎯 Fase 1: Automação de Checkout & Webhooks (Q3–Q4 2026)
- **Integração Pix Automática (PagHiper)**: Webhook assíncrono para dar baixa imediata nos pedidos da loja e liberar pontos ou o grupo VIP instantaneamente.
- **WebMCP Bridge / Bot**: Suporte a execução de comandos de compras via agentes interativos no fórum.

### 🔔 Fase 2: Notificações & Alertas de Expiração (Q4 2026)
- **Notificações Nativas do Discourse**: Enviar notificação de sistema no fórum quando um produto for entregue/concluído pelo administrador.
- **Alerta de Expiração de Cosmético**: Avisar o usuário 3 dias antes da expiração de sua moldura ou skin de tema.
- **Notificação de Sequência em Risco**: Notificar o membro quando estiver próximo de perder a sequência (ex: alerta às 20h se ainda não fez check-in).

### 📊 Fase 3: Analytics Administrativo e Exportação de Dados (Q1 2027)
- **Painel Financeiro / Extrato de Pontos**: Gráfico estatístico no painel admin mostrando movimentação diária de pontos emitidos e resgatados.
- **Exportação CSV/Excel**: Exportar histórico de pedidos e auditoria de resgates para relatórios externos.
- **[Melhoria v0.5.1]** Migrar `recalculate_all_streaks!` para job Sidekiq assíncrono se a base de usuários exceder 100.000 membros ativos.

### 🏆 Fase 4: Gamificação Avançada & Conquistas de Loja (Q2 2027)
- **Badges Dinâmicas por Compras**: Conceder conquistas automáticas do Discourse baseadas em metas de resgates na loja (ex: "Colecionador de Molduras", "Cliente Frequente").
- **Conquistas de Sequência**: Badges automáticas ao atingir marcos de check-in consecutivo (ex: 7, 30, 100 dias).
- **Reposição Estendida**: Ampliar janela de reposição para meses anteriores (com custo progressivo) e suporte a lacunas por manutenção programada do fórum.
