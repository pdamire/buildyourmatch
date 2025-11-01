# Build Your Match — Final Starter (Flutter + Supabase)

This package contains the full app starter, SQL, a sample Challenges CSV, **Daily Dice**, **Points + Consent gates**, an **Admin page**, and a **Points Store (RevenueCat wiring)**.

---

## 0) You need these installed
- Flutter (stable), Android Studio, Xcode (for iOS)
- A Supabase project (copy your `SUPABASE_URL` and `SUPABASE_ANON_KEY`)
- Optional: RevenueCat account (for in-app purchases)

---

## 1) Set up Supabase (DB + RPC)
Open Supabase → **SQL Editor** and run these files **in order** (copy-paste contents from this repo):

1. `supabase/sql/1_schema.sql`
2. `supabase/sql/2_rpc.sql`

This creates:
- Auth-safe tables (messages, conversations)
- **Points** tables + ledger
- **Daily Dice** tables + RPC
- **Consent** gates for photo/video

**Security**: RLS is enabled. Do not expose `service_role` keys in your app.

---

## 2) Seed challenges
Create a table `challenges` in Supabase (columns matching `assets/challenges_100.csv`) and import the CSV file.
Set `active = true` for rows you want visible.

---

## 3) Configure RevenueCat (optional, for paid points)
- Create products in App Store / Play Console: `bym_points_100`, `bym_points_300`, `bym_points_1000`
- Connect them in RevenueCat and grab your **RC SDK key** per platform
- Pass the key to the app at runtime:
```
flutter run   --dart-define=SUPABASE_URL=YOUR_URL   --dart-define=SUPABASE_ANON_KEY=YOUR_KEY   --dart-define=RC_SDK_KEY=YOUR_REVENUECAT_KEY
```
**Production crediting**: handle RevenueCat webhooks server-side → call `credit_purchase_points(uid, amount, ref)` after verifying receipts.

---

## 4) Run the app
From the project root:
```
flutter pub get
flutter run   --dart-define=SUPABASE_URL=YOUR_URL   --dart-define=SUPABASE_ANON_KEY=YOUR_KEY
```
Log in with a magic link (AuthGate).

---

## 5) What’s in the app (routes)
- `/home` — Home + **Daily Dice** + challenges
- `/challenge` — Complete a challenge (+XP)
- `/progress` — Generate a simple progress PDF
- `/store` — **Points Store** (RevenueCat wired; DEV credits directly via RPC)
- `/admin` — **Admin tools**: toggle & invoke `match_builder` Edge Function (you implement), check your points
- `/match`, `/chat`, `/coach` — placeholders (connect to your tables/edge functions)

---

## 6) Optional Edge Functions
Create these in **Supabase Edge Functions** later for full power:
- `match_builder` — computes candidates & scores
- `moderate_message` — classifies messages (allow/warn/block)
- `coach_proxy` — AI rewrite/repair
- `rc_webhook` — RevenueCat → `credit_purchase_points`

---

## 7) Build for stores
- **Android**: update `android/app/build.gradle` (appId), run `flutter build appbundle`, upload `.aab` to Google Play.
- **iOS**: open `ios/Runner.xcworkspace`, set your team & bundle ID, run Archive in Xcode, upload to App Store Connect.
- Add app icons, splash, and store listing text.


## 8) Security best practices
- Keep RLS ON and tight.
- Use signed short-lived URLs for any media.
- Never ship `service_role` keys in the app.
- Consider 2FA and rate limiting.

---

## 9) Business tools
In this folder you’ll also find a **Revenue Simulator workbook** you can upload to Google Sheets.
