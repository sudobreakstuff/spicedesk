# SpiceDesk

**Open-source business suite with POS, inventory, CRM, reports, and expenses.**

Dedicated to Mum and Dad.

<p align="center">
  <img src="assets/icons/app_icon.png" width="120" alt="SpiceDesk Logo">
</p>

---

## Features

| Module | Description |
|---|---|
| Point of Sale | Product grid, cart, checkout with invoice generation |
| Inventory | Stock tracking, low-stock alerts, adjustments |
| Customers | CRM with purchase history, loyalty tracking |
| Reports | Transaction history with analytics and profit tracking |
| Expenses | Cost tracking with categories |
| Pending Orders | Quote management (draft/sent/accepted/rejected) |
| Marketing | Content planner for adverts and campaigns |

**Cross-platform:** Linux, Windows, Android

## Privacy

Your data stays yours. SpiceDesk connects directly to your Supabase database. We never access or share your business information.

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) + Riverpod |
| Backend | Supabase (PostgreSQL + Auth + Realtime) |
| Navigation | GoRouter |
| PDF | pdf + printing packages |
| Charts | fl_chart |

## Getting Started

### Prerequisites
- Flutter SDK 3.44+
- A Supabase project

### Setup
```bash
git clone https://github.com/sudobreakstuff/spicedesk.git
cd spicedesk
flutter pub get
```

1. Create a [Supabase](https://supabase.com) project
2. Run the SQL migrations in `supabase/migrations/`
3. Update `lib/bootstrap.dart` with your Supabase URL and anon key
4. Run: `flutter run`

### Build
```bash
# Linux
flutter build linux --release

# Android
flutter build apk --release

# Windows
flutter build windows --release
```

## Architecture

```
lib/
├── core/
│   ├── theme/       — App theme and colors
│   ├── router/      — GoRouter configuration
│   ├── network/     — Supabase client
│   └── widgets/     — Shared widgets
├── features/
│   ├── auth/         — Login, register, password reset
│   ├── workspace/    — Workspace management
│   ├── dashboard/    — Home screen
│   ├── pos/          — Point of sale
│   ├── inventory/    — Stock management
│   ├── customers/    — CRM
│   ├── reports/      — Analytics
│   ├── expenses/     — Cost tracking
│   ├── pending/      — Quote management
│   ├── marketing/    — Content planner
│   ├── about/        — About page
│   └── settings/     — App settings
└── supabase/
    └── migrations/   — Database schema
```

## Database

All SQL migrations are in `supabase/migrations/`. Run them in order:

```
000001_initial_schema.sql
000002_fix_auth_trigger.sql
000003_raw_materials_cost_price.sql
000004_fix_create_sale.sql
000005_auto_invoice.sql
000006_fix_payment_checkout.sql
000007_loyalty.sql
000008_fix_workspace_rls.sql
000009_fix_workspace_again.sql
000010_add_order_type_to_sale.sql
```

## License

MIT — see [LICENSE](LICENSE)

## Author

Made by Shahid Singh — 2026
