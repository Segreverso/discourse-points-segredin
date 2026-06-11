# Discourse Points Mall Plugin

A comprehensive points mall plugin for Discourse that integrates with discourse-gamification. Points earned through community activity (posts, replies, likes, daily visits) and check-ins can be spent on virtual cosmetics or physical products.

## Features

### 1. Daily Check-in (签到)
- Users check in daily to earn points
- Consecutive check-in streaks earn bonus points
- Monthly check-in calendar, history and ranking
- Makeup cards to backfill missed days (up to 3 per month, tiered pricing, monthly reset)

### 2. Points Shop (积分商店)
- Exchange points for virtual cosmetics or physical products
- Product categories, featured products and storefront sections
- Stock management and order tracking
- Built-in makeup card product with tiered pricing (1000 / 3000 / 5000, configurable)

### 3. Inventory (背包)
- Virtual cosmetics live in the user's inventory and can be equipped / unequipped:
  - Custom title (头衔)
  - Avatar frame (头像框)
  - Card border (卡片边框)
  - Profile background (主页背景)
  - Post signature (帖子签名)
  - SVIP glow (SVIP 光效)
  - Theme skin (主题皮肤)
- Time-limited cosmetics expire automatically via a daily scheduled job

### 4. Orders & Addresses (订单与地址)
- Order history with status tracking
- Shipping address book for physical products

### 5. Points Ledger (积分明细)
- Every points income and expense in one timeline
- Includes automatic community points from discourse-gamification scorables
  (posts, replies, likes received/given, daily visits, etc. — last 90 days)
- Filter by income / expense / check-in / shop / community

### 6. Admin Panel (管理后台)
- Manage products (create / edit / delete, stock, categories, storefront fields)
- Review and update orders
- Browse check-in records
- Configure makeup card pricing tiers

## Installation

1. Add the plugin to your Discourse installation:
```bash
cd /var/discourse
git clone https://github.com/VegaMonika/discourse-points-mall.git plugins/discourse-points-mall
```

2. Rebuild your Discourse container:
```bash
./launcher rebuild app
```

## Configuration

Enable the plugin in Admin > Settings > Plugins > discourse-points-mall

Available settings:

| Setting | Default | Description |
| --- | --- | --- |
| `points_mall_enabled` | `true` | Enable/disable the plugin |
| `points_mall_checkin_points` | `10` | Points awarded for daily check-in |
| `points_mall_checkin_streak_bonus` | `5` | Bonus points for consecutive check-ins |
| `points_mall_makeup_price_tier_1` | `1000` | Price of the 1st makeup card each month |
| `points_mall_makeup_price_tier_2` | `3000` | Price of the 2nd makeup card each month |
| `points_mall_makeup_price_tier_3` | `5000` | Price of the 3rd makeup card each month |

## Requirements

- Discourse 2.7.0 or higher
- [discourse-gamification](https://github.com/discourse/discourse-gamification) plugin (points backend)

The plugin supports both the current gamification API (`GamificationLeaderboardScore`)
and the legacy one (`GamificationScore`); the user's balance is read live from the
first leaderboard, so it always matches the leaderboard totals.

## Usage

After installation, users can access the Points Mall at `/points-mall`. The mall includes:

- **Check-in** (签到): daily check-in with streak tracking and calendar
- **Shop** (商店): browse and purchase products with points
- **Inventory** (背包): equip / unequip owned cosmetics
- **Orders** (我的订单): order history and shipping addresses
- **Ledger** (积分明细): full income / expense timeline

## Database Schema

The plugin creates the following tables:

- `points_mall_products` — product catalog (categories, storefront fields, stock)
- `points_mall_orders` — user orders
- `points_mall_checkins` — check-in records
- `points_mall_addresses` — shipping addresses
- `points_mall_makeup_cards` — monthly makeup card purchase/usage status

Cosmetics and their expiry times are stored as user custom fields and cleaned up daily.

## License

MIT License
