# ShowLog iOS — Roadmap & Feature Tracker

**Last updated:** Apr 27, 2026 | Part of [showlogd.netlify.app](https://showlogd.netlify.app) | Stack: SwiftUI + iOS 17

---

## 🚀 Releases

### v1.1 — Apr 2026

---

#### v1.1.0
<sub>Published 2026-04-27</sub>

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

## 🔮 Future

| ID | Item | Type | Priority | Details |
|----|------|------|----------|---------|
| FEA-08 | **Year in Review / Stats Page** | Feature | High | Annual wrapped-style stats: total shows watched, total episodes, top genres, most-watched network, average rating, watching streaks, first and last log of the year. Shareable as an image card. |
| FEA-09 | **AI Recommendations** | Feature | Medium | Use Claude to recommend shows based on the user's diary and ratings. Personalized picks with explanations, powered by a backend endpoint that pulls the user's Supabase data as context. |
| FEA-10 | **Import from Trakt / IMDb** | Feature | Medium | Let users migrate existing watch history from Trakt (JSON export) or IMDb (CSV export). Preview with New/Existing badges before committing. |
| FEA-11 | **Social / Friends Feed** | Feature | Medium | Follow other users and see their recent diary entries in a feed. Friends' ratings on show detail pages. "Popular with friends" section on Home. |
| FEA-12 | **Show Lists** | Feature | Medium | Create and share curated lists (e.g. "Best HBO Shows", "Comfort Watches"). Ordered, titled, with description. Public lists are discoverable. |
| FEA-13 | **Streaming Availability** | Feature | Medium | Show which platforms a show is on via TMDB `watch/providers`. Platform logos on show cards. Filter watchlist by platform. |
| UI-01 | **Public Profile** | UI | Medium | Public profile showing watch stats, recent diary entries, top shows, and ratings distribution. Private by default. |
| FEA-14 | **Reviews & Notes** | Feature | Low | Longer-form reviews per show beyond a star rating. Public or private. |

---

## ✅ Completed

| ID | Item | Type | Completed |
|----|------|------|-----------|
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
