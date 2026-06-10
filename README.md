# Me0w 📱

An iOS app for discovering movies and TV shows, built with SwiftUI and the TMDB API. Browse trending content, search by title, browse by genre, and track what you're watching.

## Features

- **Home** — Featured banner, trending movies & shows, continue watching, and popular picks
- **Browse by Genre** — 12 genre categories (Action, Comedy, Drama, Horror, Sci-Fi, etc.)
- **Search** — Search movies and shows with persistent search history
- **Movies & TV Shows tabs** — Paginated grids for browsing popular content independently
- **Detail views** — Full info, backdrop images, ratings, and episode lists for TV shows
- **My List** — Save titles to watch later
- **Continue Watching** — Pick up where you left off
- **Dark theme** — Netflix-inspired dark UI throughout

## Tech Stack

- **SwiftUI** — declarative UI, tab navigation, lazy grids
- **TMDB API** — movie/TV data, trending, genre endpoints
- **Kingfisher** — async image loading and caching
- **WebKit** — embedded video streaming

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+
- CocoaPods or Swift Package Manager (for Kingfisher)

## Setup

1. Clone the repo
```bash
git clone https://github.com/ChiefChriss/me0w.git
cd me0w
```

2. Get a TMDB API key at [themoviedb.org/settings/api](https://www.themoviedb.org/settings/api)

3. Copy the example secrets file and add your key:
```bash
cp Secrets.example.plist Secrets.plist
# Then edit Secrets.plist and replace YOUR_TMDB_API_KEY with your actual key
```

4. Install Kingfisher via Swift Package Manager or CocoaPods

5. Open `Me0w.xcodeproj` in Xcode and build

## Architecture

- **`ContentView.swift`** — Main app entry, tab controller, and all view models/views
- **`Me0wApp.swift`** — SwiftUI app lifecycle
- **`EmbedItem`** — Core data model shared across the app
- **`ContentViewModel`** — `@MainActor` ObservableObject managing all API calls and state

## License

MIT
