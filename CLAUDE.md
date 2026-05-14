# ShowLog iOS — TV Show Tracker

## Tech Stack
- Swift 5.9, iOS 16.0+
- SwiftUI (no UIKit)
- Xcode 16, XcodeGen (`project.yml` generates `.xcodeproj`)
- Supabase (auth + PostgreSQL via REST)
- TMDB API (show search, browse, details)
- URLSession (no third-party networking)

## Architecture
- **MVVM-lite:** `AppState` (single `ObservableObject` / `@MainActor`) is the central state manager, passed as `@EnvironmentObject` to all views
- **Actor pattern:** `SupabaseService` and `TMDBService` are Swift actors for thread-safe async access
- **Swift Concurrency:** All async work uses `async/await` and `Task`
- **No external state library** (no Redux, TCA, etc.)

## Project Structure
```
ShowLog/Sources/
├── Models/          # Show, DiaryEntry, ShowProgress, WatchStatus
├── Services/        # SupabaseService, TMDBService
├── Views/
│   ├── Components/  # ShowCard, StarRating, SectionHeader
│   ├── HomeView, SearchView, WatchlistView, DiaryView, ProfileView
│   ├── ShowDetailView, AuthView
├── AppState.swift   # Central state + all business logic methods
├── ContentView.swift
├── ShowLogApp.swift
├── Config.swift     # Keys loaded from Info.plist / Secrets.xcconfig
└── Theme.swift      # Colors, dark theme
```

## Conventions
- camelCase Swift, snake_case JSON (mapped via `CodingKeys`)
- Dark theme, green accent (`#00E054`) — matches web app branding
- Typography: SF Pro (system font)
- `#if DEBUG` guards around print/logging statements
- API keys injected via `Secrets.xcconfig` → `Info.plist` → `Config.swift` (never hardcode keys)

## Supabase Tables
| Table | Key Columns |
|-------|-------------|
| `watchlist_entries` | `user_id`, `show_id`, `show_data` (JSONB) |
| `watched_shows` | `user_id`, `show_id`, `show_data` (JSONB) |
| `diary_entries` | `id` (UUID), `user_id`, `show_id`, `show_data` (JSONB), `watched_at`, `notes`, `rating` (0.5–5) |
| `show_progress` | `user_id`, `show_id`, `watched_episodes` (JSONB), `total_episodes` |

Show metadata is stored as JSONB (`show_data`) alongside every row — no separate shows table.

## Ratings Convention
- **Storage / API:** 0.5–5 scale (matching web app format)
- **UI display:** 1–5 stars (`StarRating` component)
- **Internal (Supabase):** 1–10 integer scale — `SupabaseService` handles the conversion

## Supabase — New Table Boilerplate (effective May 30, 2026)

New tables in the `public` schema are **not** exposed to the Data API by default. Every new `public` table that needs to be accessible via supabase-js or PostgREST must include explicit grants and RLS in the same migration:

```sql
grant select on public.<table> to anon;
grant select, insert, update, delete on public.<table> to authenticated;
grant select, insert, update, delete on public.<table> to service_role;

alter table public.<table> enable row level security;

create policy "users can read their own rows"
  on public.<table> for select to authenticated
  using (auth.uid() = user_id);
```

Adjust grants and policies to match the actual access requirements. Never create a table in `public` without this boilerplate if it needs API access.

## Building
1. Copy `Secrets.xcconfig.example` → `Secrets.xcconfig` and fill in API keys
2. Run `xcodegen generate` to regenerate the `.xcodeproj`
3. Open `ShowLog.xcodeproj` and build/run on simulator or device
