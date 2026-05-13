# ShowLog iOS — Roadmap & Feature Tracker

**Last updated:** May 11, 2026 | Part of [showlogd.netlify.app](https://showlogd.netlify.app) | Stack: SwiftUI + iOS 16+

---

## Latest — v1.1.1
<sub>Published 2026-05-11</sub>

**Account deletion and sign-up fixes for App Store compliance.**

### Features
- **Account Deletion** — "Delete Account" button added to the Profile tab below Sign Out. Tapping it reveals a confirmation panel requiring the user to type `DELETE` before proceeding. On confirm, a `POST` request is sent to the shared `/api/delete-account` Netlify Function with the user's Bearer token, which deletes all Supabase data and the auth user server-side. The app then clears local state. Added to satisfy App Store Review Guidelines requirement for in-app account deletion.

### Fixes
- **BUG-05: Sign-up decoding crash** — `SupabaseService.signUp` was decoding the response as `AuthResponse` in all cases. When email confirmation is required, Supabase returns a bare user object with no `access_token`, causing a "missing key" decode error. Fixed by manually performing the request and attempting `AuthResponse` decode only when `access_token` is present; returns `nil` (confirmation required) otherwise.
- **BUG-06: Auth errors not surfaced** — `signIn` and other auth calls threw generic `URLError(.badServerResponse)` (-1011) on 4xx responses, hiding the actual Supabase error message (e.g. "Email not confirmed", "Invalid login credentials"). Fixed by decoding Supabase's `{ "message": "..." }` / `{ "msg": "..." }` error body and throwing a `SupabaseAuthError` with the human-readable message.

---

## 🔮 Future

### Feature

| ID | Item | Priority | Details |
|----|------|----------|---------|
| FEA-08 | **Year in Review / Stats Page** | High | Annual wrapped-style stats: total shows watched, total episodes, top genres, most-watched network, average rating, watching streaks, first and last log of the year. Shareable as an image card. |
| FEA-09 | **AI Recommendations** | Medium | Use Claude to recommend shows based on the user's diary and ratings. Personalized picks with explanations, powered by a backend endpoint that pulls the user's Supabase data as context. |
| FEA-10 | **Import from Trakt / IMDb** | Medium | Let users migrate existing watch history from Trakt (JSON export) or IMDb (CSV export). Preview with New/Existing badges before committing. |
| FEA-11 | **Social / Friends Feed** | Medium | Follow other users and see their recent diary entries in a feed. Friends' ratings on show detail pages. "Popular with friends" section on Home. |
| FEA-12 | **Show Lists** | Medium | Create and share curated lists (e.g. "Best HBO Shows", "Comfort Watches"). Ordered, titled, with description. Public lists are discoverable. |
| FEA-13 | **Streaming Availability** | Medium | Show which platforms a show is on via TMDB `watch/providers`. Platform logos on show cards. Filter watchlist by platform. |
| FEA-14 | **Reviews & Notes** | Low | Longer-form reviews per show beyond a star rating. Public or private. |
| FEA-17 | **Recent Searches** | Low | In the Search tab, show a list of the user's most recent search keywords when the search field is empty or first focused. Tapping a keyword repopulates the field and triggers the search immediately. Keywords stored in `UserDefaults` (max 10 entries, newest first). A "Clear" button removes all entries. No account required. |
| FEA-18 | **Settings Menu** | Medium | Dedicated Settings screen pushed from the Profile tab (gear icon or "Settings" row). Organizes account actions and app preferences in one place. **Account** section: Sign Out and Delete Account (moved from the main Profile screen). **Preferences** section: placeholder for future app-level settings (e.g. default rating scale, diary sort order). Keeps the Profile screen focused on user stats and identity. |
| FEA-19 | **Profile Picture** | Low | Users can upload a profile picture from the Settings screen. Image is stored in a Supabase Storage bucket (`avatars/`) and the public URL saved to user metadata. The avatar is displayed on the Profile tab and in any future social-facing surfaces. Falls back to the initial letter badge if no avatar is set. Tapping the avatar on the Profile screen opens the system photo picker (`PhotosUI`). |
| FEA-20 | **Localization** | Medium | Translate the app UI into multiple languages, automatically matching the device language set in iOS Settings. All static strings extracted into `Localizable.strings` / `Localizable.xcstrings`. Locale-aware date and number formatting via `DateFormatter` and `NumberFormatter`. Falls back to English for unsupported locales. |
| FEA-21 | **Light Mode & System Appearance** | Low | Add a light mode theme and a per-user appearance preference (Dark / Light / System). "System" follows the iOS appearance setting via `.preferredColorScheme`. Color tokens defined as `Color` assets with light/dark variants in the asset catalog. Preference stored in `UserDefaults` and applied at the root `App` level. |
| FEA-22 | **Adaptive App Icon** | Low | Support iOS 18 home screen appearance variants for the app icon. Three icon variants provided in the asset catalog: **Dark** — same artwork on a black background; **Tinted (clear)** — monochrome version of the icon artwork, rendered by iOS with a glass-like translucent tint; **Tinted (color)** — same monochrome artwork, allowing iOS to apply the user's chosen home screen accent color automatically. All three variants are registered under the primary `AppIcon` asset catalog entry alongside the existing default (light) icon, so iOS picks the correct variant without any in-app code. |
| FEA-23 | **Social Sign-In** | Medium | Add one-tap sign-in via Google, Apple, and Facebook as alternatives to email + password. Powered by Supabase OAuth providers. Provider buttons appear on the `AuthView` above the email form with a divider. Apple Sign-In uses `AuthenticationServices` (`ASAuthorizationAppleIDButton`) natively; Google and Facebook use their respective iOS SDKs or a Supabase OAuth web flow via `ASWebAuthenticationSession`. Apple Sign-In is mandatory per App Store Guidelines when other third-party sign-in options are offered. |

### UI

| ID | Item | Priority | Details |
|----|------|----------|---------|
| UI-01 | **Public Profile** | Medium | Public profile showing watch stats, recent diary entries, top shows, and ratings distribution. Private by default. |

---

## ✅ Completed

| ID | Item | Type | Completed |
|----|------|------|-----------|
| INF-05 | **Account Deletion** — Profile tab delete flow with typed `DELETE` confirmation. Calls shared `/api/delete-account` Netlify Function to wipe all Supabase data and auth user. App Store compliance. | Infra → Done | May 11 |
| BUG-05 | **Sign-up Decoding Crash** — `signUp` now handles both response shapes: full `AuthResponse` (email confirmation disabled) and bare user object (confirmation required). Returns `nil` for the latter so `AuthView` shows the confirmation message. | Bug → Fixed | May 11 |
| BUG-06 | **Auth Errors Not Surfaced** — `post` helper now decodes Supabase `message`/`msg` error body on 4xx and throws `SupabaseAuthError` with the human-readable string instead of generic `-1011`. | Bug → Fixed | May 11 |
| INF-02 | **TMDB Integration** — `TMDBService` with trending, popular, top-rated, search, show detail + credits, and season/episode endpoints. `AsyncImage` poster loading throughout. | Infra → Done | Apr 2026 |
| INF-03 | **Supabase Backend** — `SupabaseService` with direct REST API calls. Tables: `watchlist_entries`, `diary_entries`, `watched_shows`, `show_progress`. Mirrors web app schema. | Infra → Done | Apr 2026 |
| INF-04 | **User Authentication** — Supabase Auth email + password sign-up/sign-in. Auth-gated Watchlist, Diary, rating, and episode tracking actions. Username editing in profile. | Infra → Done | Apr 2026 |
| FEA-07 | **Season & Episode Tracking** — Expandable season accordion in `ShowDetailView`. Per-episode checkboxes. Season-level bulk mark. Progress bars and "Up to SxEx" labels on `ShowCard`. `show_progress` Supabase table. | Feature → Done | Apr 2026 |
| FEA-01 | **App Scaffold** — SwiftUI app with Home, Search, Watchlist, Diary, Profile tabs. Dark theme with green accent matching web app. Generated via XcodeGen. | Feature → Done | Apr 2026 |
| FEA-02 | **Show Detail Sheet** — Backdrop, title, genres, season count, episode progress. About / Cast / Seasons tabs. Log / Review form with date picker. | Feature → Done | Apr 2026 |
| FEA-03 | **Real-time Search** — Debounced search via TMDB, results grid with tap-to-detail. | Feature → Done | Apr 2026 |
| FEA-04 | **Star Ratings** — 1–10 scale (displayed as 1–5 stars). Interactive picker in log + edit forms. | Feature → Done | Apr 2026 |
| FEA-05 | **Diary** — Sorted by date watched. Swipe left to reveal Edit and Delete (red, with confirmation). Log form saves and persists to Supabase. Rating stored on 0.5–5 scale to match web. | Feature → Done | Apr 2026 |
| FEA-06 | **Continue Watching** — Home card row for watchlist shows with episode progress. | Feature → Done | Apr 2026 |
| BUG-01 | **Session Persistence** — Refresh token stored in UserDefaults. On launch, `restoreSession()` exchanges it for a fresh access token before loading user data. | Bug → Fixed | Apr 2026 |
| BUG-02 | **Data Loading from Supabase** — Fixed watchlist 400 (invalid `created_at` order), progress null decode, season ID fallback, genre/network format flexibility, and missing RLS policies for INSERT/UPDATE/DELETE on all tables. | Bug → Fixed | Apr 2026 |
| BUG-03 | **Episode Progress Save** — Added RLS INSERT/UPDATE policy on `show_progress`. Progress now saves and persists across sessions. Season watched count computed from progress dict (no longer requires episodes loaded). | Bug → Fixed | Apr 2026 |
| BUG-04 | **Rating Scale** — Unified to 0.5–5 web scale in DB. Decoder always reads as Double × 2 for internal 1–10 display. Fixes all web-logged entries showing as 2.5 stars. | Bug → Fixed | Apr 2026 |
| FEA-15 | **Recently Watched** — Home and Profile tabs show up to 6 recently watched shows loaded from `watched_shows` table with full show data. | Feature → Done | Apr 2026 |
| FEA-16 | **Unmark Watched** — Tapping "Watched" on a show that is already marked watched removes it from `watched_shows`. | Feature → Done | Apr 2026 |

---

## 🚀 Version History

### v1.1 — Apr 2026

---

#### v1.1.0
<sub>Published 2026-04-27 | Submitted to App Store 2026-04-28</sub>

**Supabase sync, data fixes, and diary improvements.**

##### Features
- **FEA-15: Recently Watched** — Home and Profile tabs now show a "Recently Watched" row of up to 6 shows, loaded from `watched_shows` with full `show_data`. Updates immediately when a show is marked watched.
- **FEA-16: Unmark Watched** — Tapping "Watched" on an already-watched show removes it from `watched_shows` and clears the local state.
- **Diary edit & delete** — Swipe left on any diary row to reveal a blue Edit button and a red Delete button. Delete shows a confirmation dialog. Edit opens a full form with date picker, star rating, and notes.
- **Diary sorted by date watched** — Diary list and new entries are always sorted by `watched_at` descending, matching the web app.

##### Fixes
- **BUG-01: Session persistence** — Refresh token persisted to `UserDefaults`. On launch, `restoreSession()` exchanges it for a fresh access token before loading user data. Users stay signed in across app restarts.
- **BUG-02: Data loading** — Fixed 400 error on watchlist query (invalid `created_at` order column). Fixed null-decode crash on `show_progress.total_episodes`. Fixed season missing `id` field. Added flexible genre/network decoding to handle TMDB objects, stored string arrays, and genre ID integers interchangeably.
- **BUG-03: Episode progress save** — Added missing Supabase RLS INSERT/UPDATE policies on `show_progress`, `watchlist_entries`, `watched_shows`, and `diary_entries`. Upsert and delete HTTP methods now check status codes and log errors.
- **BUG-04: Rating scale** — Unified storage to 0.5–5 web scale. Decoder always reads rating as `Double` and multiplies by 2 for internal 1–10 display. Fixes all web-logged entries displaying as 2.5 stars.
- **Episode progress display** — Season watched count now computed directly from the `watchedEpisodes` dict rather than loaded episode objects, so counts are correct before a season is expanded.
- **Debug logging** — All Supabase HTTP methods (`GET`, `POST`, `UPSERT`, `DELETE`) now log status codes and error response bodies in debug builds.

---

### v1.0 — Apr 2026

---

#### v1.0.0
<sub>Published 2026-04-20</sub>

**Initial release — full-featured SwiftUI app.**

##### Features
- **INF-02: TMDB Integration** — `TMDBService` with trending, popular, top-rated, search, show detail + credits, and season/episode endpoints. `AsyncImage` poster loading throughout.
- **INF-03: Supabase Backend** — `SupabaseService` with direct REST API calls (no SDK). Tables: `watchlist_entries`, `diary_entries`, `watched_shows`, `show_progress`. Mirrors web app schema.
- **INF-04: User Authentication** — Supabase Auth email + password sign-up/sign-in. Auth-gated Watchlist, Diary, rating, and episode tracking. Username editing in Profile.
- **FEA-01: App Scaffold** — SwiftUI app with Home, Search, Watchlist, Diary, and Profile tabs. Dark theme with green accent matching web app. Generated via XcodeGen.
- **FEA-02: Show Detail Sheet** — Backdrop, title, genres, season count, episode progress. About / Cast / Seasons tabs. Log form with date picker, star rating, and notes.
- **FEA-03: Real-time Search** — Debounced TMDB search with results grid and tap-to-detail.
- **FEA-04: Star Ratings** — 1–10 internal scale displayed as 1–5 stars with half-star increments.
- **FEA-05: Diary** — Per-show log entries with date watched, rating, and notes.
- **FEA-06: Continue Watching** — Home row for watchlist shows that have episode progress tracked.
- **FEA-07: Season & Episode Tracking** — Expandable season accordion. Per-episode checkboxes. Season-level bulk mark. Progress bars and "Up to SxEx" labels on `ShowCard`. `show_progress` Supabase table.
- **Custom app icon** — Bespoke SVG icon (TV monitor with green log row), exported as 1024×1024 RGB PNG and wired into the asset catalog via XcodeGen.

---
