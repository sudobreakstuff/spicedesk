# SpiceDesk

Business management suite for savories shops, bakeries, and small food businesses.

Built by **Shahid Singh**

## Features

- **Point of Sale** — Quick cart, checkout, receipt printing (Niimbot B21/B1/D11/D110)
- **Inventory Management** — Stock tracking, low-stock alerts, barcode support
- **Customer CRM** — Contacts, WhatsApp quick-chat, order history
- **Orders Hub** — Unified view of walk-in, WhatsApp, and phone orders
- **Invoices** — PDF generation, print or share via WhatsApp
- **Expense Tracker** — Log expenses, attach receipts, categorize
- **Bank Accounts** — Manual or SMS-based transaction tracking
- **Reports** — Daily P&L, sales trends, VAT summaries (SARS-friendly)
- **Multi-device Sync** — Local-first SQLite + optional Supabase cloud sync
- **Offline-first** — Works without internet, syncs when connected

## Quick Start

### Prerequisites
- Flutter SDK 3.27+ 
- Android Studio or VS Code
- A Supabase account (free tier)

### 1. Clone the repo
```bash
git clone https://github.com/sudobreakstuff/spicedesk.git
cd spicedesk
```

### 2. Set up Supabase
1. Go to [supabase.com](https://supabase.com) and create a free project
2. Go to SQL Editor → paste the contents of `sql/migration.sql` → Run
3. Go to Project Settings → API → copy the **Project URL** and **anon public key**

### 3. Run the app
```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=your_project_url \
            --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

### 4. Build APK
```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=your_project_url \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`

## For Other Businesses

Anyone can use SpiceDesk:
1. Download the APK from GitHub Releases
2. Open → Sign Up → Set up their shop
3. Optionally connect their own Supabase project for cloud sync

## Tech Stack

| Layer | Tech |
|-------|------|
| App | Flutter 3.27 |
| State | Provider |
| Local DB | SQLite (sqflite) |
| Cloud Sync | Supabase (PostgreSQL + Auth) |
| Printer | niimbot_print (B21/B1/D11/D110) |
| PDF | pdf + printing packages |
| Auth | Supabase Auth (Email + Google + Biometrics) |

## Project Structure

```
lib/
  core/           — Config, theme, constants
  models/         — Data models (Business, Product, Customer, etc.)
  services/       — Database, Auth, Business services
  providers/      — State management (Provider)
  screens/
    auth/         — Login, SignUp
    setup/        — Business setup wizard
    dashboard/    — Main app shell + dashboard
  widgets/        — Reusable components
sql/
  migration.sql   — Supabase database schema + RLS policies
```

## Printer Support

The Niimbot B21 portable thermal printer is supported out of the box via Bluetooth BLE. Also works with:
- Niimbot B1, B18, D11, D110
- Standard ESC/POS thermal printers
- Android system print service (for A4 invoices)

## Security

- Row-Level Security (RLS) on all Supabase tables
- Each business isolated to their own data
- Google Sign-In + biometric authentication
- Secure credential storage (flutter_secure_storage)
- Offline-first — data never leaves your device without permission

## License

MIT — Free for personal and commercial use.

---

Built with love for Mum's savories shop. 🇿🇦
