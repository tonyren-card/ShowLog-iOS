# ShowLog iOS — Roadmap & Feature Tracker

**Last updated:** Apr 20, 2026 | Part of [showlogd.netlify.app](https://showlogd.netlify.app) | Stack: SwiftUI + iOS 17

---

## 🔮 Future

| ID | Item | Type | Priority | Details |
|----|------|------|----------|---------|
| INF-02 | **TMDB Integration** | Infra | High | Replace sample data with real TMDB API calls. Endpoints: trending, top rated, search, show detail, credits. Real poster images. |
| INF-03 | **Supabase Backend** | Infra | High | Persist watchlist, diary, and ratings to Supabase so data syncs across devices and with the web app. Schema mirrors web: `watchlist_entries`, `diary_entries`, `watched_shows`. |
| INF-04 | **User Authentication** | Infra | High | Supabase Auth with email + password. Auth-gated Watchlist/Diary/rating actions. Username support. Profile page with stats. |
| FEA-07 | **Season & Episode Tracking** | Feature | High | Season accordion in show detail with per-episode checkboxes. Season-level and series-level bulk mark. Progress bars on watchlist cards. "Up to SxEx" label. Mirrors `show_progress` Supabase table from web. |
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
| FEA-01 | **App Scaffold** — SwiftUI app with Home, Diary, Watchlist, and Profile tabs. Dark theme with green accent matching web app. Generated via XcodeGen. | Feature → Done | Apr 2026 |
| FEA-02 | **Watch Status** — Watching, Completed, Queue, Dropped statuses with icons and colors. | Feature → Done | Apr 2026 |
| FEA-03 | **Star Ratings** — 1–5 star ratings per show displayed in Home and Diary. | Feature → Done | Apr 2026 |
| FEA-04 | **Continue Watching** — Horizontal scroll card row on Home showing in-progress shows with S×E badge. | Feature → Done | Apr 2026 |
| FEA-05 | **Diary View** — List of all non-queued shows with status and rating. | Feature → Done | Apr 2026 |
| FEA-06 | **Watchlist View** — Queue list with empty state. | Feature → Done | Apr 2026 |
