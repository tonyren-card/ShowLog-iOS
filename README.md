# ShowLog iOS

Native SwiftUI iOS app for [ShowLog](https://showlogd.netlify.app) — a TV show tracker with watchlist, diary, and ratings.

Part of the v1.1.0 release alongside a branding refresh. The web app (React + Vite + Supabase + TMDB) lives in a separate repo.

## Features

- **Home** — Continue watching cards and recently completed shows
- **Diary** — Full log of watched shows with status and star ratings
- **Watchlist** — Queue of shows to watch next
- **Profile** — Stats summary (completed, watching, average rating)

Watch statuses: Watching, Completed, Queue, Dropped

Matches the web app's dark theme and green (`#00E054`) accent.

## Requirements

- iOS 17.0+
- Xcode 16
- Swift 5.9

## Setup

The project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the `.xcodeproj` from `project.yml`.

```bash
# Install XcodeGen if needed
brew install xcodegen

# Generate the Xcode project
xcodegen generate

# Open in Xcode
open ShowLog.xcodeproj
```

## Roadmap

See [`references/showlog-ios-roadmap.md`](references/showlog-ios-roadmap.md).
