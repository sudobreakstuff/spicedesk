# SpiceDesk

**Business Suite — Point of Sale, Inventory, CRM, Reports, Expenses**

Dedicated to Mum and Dad.

---

## Features

- **Point of Sale** — Product grid, cart, checkout with invoice generation
- **Inventory** — Stock tracking with low-stock alerts and adjustments
- **Customers** — CRM with purchase history, loyalty tracking
- **Reports** — Transaction history with date range filtering and stats
- **Expenses** — Cost tracking with categories (rent, utilities, supplies, marketing)
- **Pending Orders** — Quote management (draft/sent/accepted/rejected)
- **Raw Materials** — Separate tracking via expenses tab
- **Multi-platform** — Linux, Windows, Android

## Tech Stack

- **Frontend:** Flutter (Dart) with Riverpod state management
- **Backend:** Supabase (PostgreSQL + Auth + Realtime)
- **Navigation:** GoRouter
- **UI:** Custom dark theme with modern design

## Getting Started

### Prerequisites
- Flutter SDK 3.44+
- Supabase project

### Setup
1. Clone the repo
2. Run `flutter pub get`
3. Create a Supabase project and run the SQL migrations in `supabase/migrations/`
4. Update `lib/bootstrap.dart` with your Supabase URL and anon key
5. Run `flutter run`

### Build
```bash
# Linux
flutter build linux --release

# Android
flutter build apk --release

# Windows (requires Windows host)
flutter build windows --release
```

## Database

All SQL migrations are in `supabase/migrations/`. Run them in order:
1. `000001_initial_schema.sql` — Core tables (workspaces, products, inventory, sales, customers)
2. `000002_fix_auth_trigger.sql` — Auto-create workspace on signup
3. `000003_raw_materials_cost_price.sql` — Raw materials, recipes, purchase orders
4. `000004_fix_create_sale.sql` — Fix RPC function
5. `000005_auto_invoice.sql` — Auto-generate invoices on sale
6. `000006_fix_payment_checkout.sql` — Payment method constraint fix
7. `000007_loyalty.sql` — Customer loyalty tracking
8. `000008_fix_workspace_rls.sql` — Workspace RLS policies
9. `000009_fix_workspace_again.sql` — Workspace RLS fix v2
10. `000010_add_order_type_to_sale.sql` — Order type field

## Architecture

```
lib/
  core/
    theme/          — Dark theme with SpiceColors
    router/         — GoRouter configuration
    network/        — Supabase client
    widgets/        — Reusable widgets (sidebar, glass cards)
  features/
    auth/           — Login, register, password reset
    workspace/      — Workspace management
    dashboard/      — Home screen with stats
    pos/            — Point of sale
    inventory/      — Stock management
    customers/      — CRM
    reports/        — Transaction history and analytics
    expenses/       — Cost tracking
    pending/        — Quote management
    marketing/      — Content planner
    about/          — About page
    settings/       — App settings
```

## Author

Made by Shahid Singh — 2026
