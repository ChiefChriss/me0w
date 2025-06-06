import SwiftUI
import WebKit
import UIKit
import Kingfisher

// MARK: - Models

struct EmbedItem: Identifiable, Codable {
    let id: Int
    let title: String
    let posterPath: String
    let isTV: Bool

    var streamURL: String {
        isTV ? "https://vidlink.pro/tv/\(id)/1/1?autoplay=true&nextbutton=true" : "https://vidlink.pro/movie/\(id)?autoplay=true&nextbutton=true"
    }

    var fullPosterURL: String {
        "https://image.tmdb.org/t/p/w500\(posterPath)"
    }
}

struct Episode: Identifiable {
    let id = UUID()
    let episodeNumber: Int
    let stillPath: String?
}

struct CategoryCard: Identifiable {
    let id = UUID()
    let title: String
    let gradient: LinearGradient
    let genreId: Int?

    static let categories = [
        CategoryCard(title: "Action", gradient: LinearGradient(colors: [.orange, .red.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 28),
        CategoryCard(title: "Comedy", gradient: LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 35),
        CategoryCard(title: "Drama", gradient: LinearGradient(colors: [.blue, .purple.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 18),
        CategoryCard(title: "Horror", gradient: LinearGradient(colors: [.purple, .black], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 27),
        CategoryCard(title: "Romance", gradient: LinearGradient(colors: [.pink, .red.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 10749),
        CategoryCard(title: "Sci-Fi", gradient: LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 878),
        CategoryCard(title: "Thriller", gradient: LinearGradient(colors: [.red, .black], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 53),
        CategoryCard(title: "Animation", gradient: LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 16),
        CategoryCard(title: "Documentary", gradient: LinearGradient(colors: [.gray, .blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 99),
        CategoryCard(title: "Family", gradient: LinearGradient(colors: [.green.opacity(0.7), .yellow.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 10751),
        CategoryCard(title: "Fantasy", gradient: LinearGradient(colors: [.purple.opacity(0.8), .pink.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 14),
        CategoryCard(title: "Crime", gradient: LinearGradient(colors: [.black, .red.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 80)
    ]
}

// MARK: - Helpers

struct PosterCard: View {
    let item: EmbedItem

    var body: some View {
        VStack(alignment: .leading) {
            KFImage(URL(string: item.fullPosterURL))
                .placeholder {
                    Color.gray.frame(height: 200)
                }
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipped()
                .cornerRadius(10)

            Text(item.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(1)
        }
    }
}

struct EpisodeCard: View {
    let showID: Int
    let selectedSeason: Int
    let episode: Episode

    var body: some View {
        let url = "https://vidlink.pro/tv/\(showID)/\(selectedSeason)/\(episode.episodeNumber)?autoplay=true&nextbutton=true"

        NavigationLink(destination: FullScreenVideoPlayerView(embedURL: url)) {
            VStack {
                if let path = episode.stillPath {
                    KFImage(URL(string: "https://image.tmdb.org/t/p/w500\(path)"))
                        .placeholder {
                            Color.gray.frame(width: 120, height: 70)
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 70)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    Color.gray.frame(width: 120, height: 70).cornerRadius(8)
                }
                Text("Ep \(episode.episodeNumber)")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
        }
    }
}
class ContentViewModel: ObservableObject {
    @Published var movies: [EmbedItem] = []
    @Published var shows: [EmbedItem] = []
    @Published var home: [EmbedItem] = []
    @Published var searchResults: [EmbedItem] = []
    @Published var categoryResults: [EmbedItem] = []
    @Published var searchHistory: [String] = []
    @Published var totalSeasons: Int = 1
    @Published var episodes: [Episode] = []

    let apiKey = "e316c59b24ce81a8f56c325a3ffd2554"
    private var moviePage = 1
    private var showPage = 1
    private let maxHistoryItems = 10
    private let searchHistoryKey = "searchHistory"

    init() {
        loadSearchHistory()
    }

    func fetchMovies() {
        guard let url = URL(string: "https://api.themoviedb.org/3/movie/popular?api_key=\(apiKey)&language=en-US&page=\(moviePage)") else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else { return }
            self.parse(data: data, isTV: false) { items in
                DispatchQueue.main.async {
                    self.movies += items
                    if self.moviePage == 1 && self.home.isEmpty {
                        self.home += items.prefix(10)
                    }
                }
            }
        }.resume()
    }

    func fetchTVShows() {
        guard let url = URL(string: "https://api.themoviedb.org/3/tv/popular?api_key=\(apiKey)&language=en-US&page=\(showPage)") else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self, let data = data else { return }
            self.parse(data: data, isTV: true) { items in
                DispatchQueue.main.async {
                    self.shows += items
                    if self.showPage == 1 && self.home.isEmpty {
                        self.home += items.prefix(10)
                    }
                }
            }
        }.resume()
    }

    func loadMoreMovies() {
        moviePage += 1
        fetchMovies()
    }

    func loadMoreTVShows() {
        showPage += 1
        fetchTVShows()
    }

    func fetchSeasonCount(showId: Int) {
        guard let url = URL(string: "https://api.themoviedb.org/3/tv/\(showId)?api_key=\(apiKey)&language=en-US") else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let count = json["number_of_seasons"] as? Int {
                DispatchQueue.main.async {
                    self.totalSeasons = count
                }
            }
        }.resume()
    }

    func fetchEpisodes(for showId: Int, season: Int) {
        guard let url = URL(string: "https://api.themoviedb.org/3/tv/\(showId)/season/\(season)?api_key=\(apiKey)&language=en-US") else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let epArr = json["episodes"] as? [[String: Any]] {
                let eps = epArr.compactMap { dict -> Episode? in
                    guard let epNum = dict["episode_number"] as? Int else { return nil }
                    return Episode(episodeNumber: epNum, stillPath: dict["still_path"] as? String)
                }
                DispatchQueue.main.async {
                    self.episodes = eps
                }
            }
        }.resume()
    }

    func search(query: String) {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://api.themoviedb.org/3/search/multi?api_key=\(apiKey)&language=en-US&query=\(encoded)") else { return }

        addSearchQuery(query)

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self, let data = data else { return }
            self.parse(data: data, isTV: nil) { items in
                DispatchQueue.main.async {
                    self.searchResults = items
                }
            }
        }.resume()
    }

    func fetchByGenre(genreId: Int) {
        guard let url = URL(string: "https://api.themoviedb.org/3/discover/movie?api_key=\(apiKey)&language=en-US&with_genres=\(genreId)") else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self, let data = data else { return }
            self.parse(data: data, isTV: false) { items in
                DispatchQueue.main.async {
                    self.categoryResults = items
                }
            }
        }.resume()
    }

    private func parse(data: Data, isTV: Bool?, completion: @escaping ([EmbedItem]) -> Void) {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let results = json["results"] as? [[String: Any]] {
            let items = results.compactMap { dict -> EmbedItem? in
                guard let id = dict["id"] as? Int,
                      let posterPath = dict["poster_path"] as? String else { return nil }

                let title = dict["title"] as? String ?? dict["name"] as? String ?? ""
                let isTVResult = dict["media_type"] as? String == "tv" || isTV == true
                return EmbedItem(id: id, title: title, posterPath: posterPath, isTV: isTVResult)
            }
            completion(items)
        }
    }

    func addSearchQuery(_ query: String) {
        var currentHistory = searchHistory.filter { $0.lowercased() != query.lowercased() }
        currentHistory.insert(query, at: 0)
        if currentHistory.count > maxHistoryItems {
            currentHistory = Array(currentHistory.prefix(maxHistoryItems))
        }
        searchHistory = currentHistory
        saveSearchHistory()
    }

    func loadSearchHistory() {
        if let saved = UserDefaults.standard.stringArray(forKey: searchHistoryKey) {
            searchHistory = saved
        }
    }

    func saveSearchHistory() {
        UserDefaults.standard.set(searchHistory, forKey: searchHistoryKey)
    }

    func clearSearchHistory() {
        searchHistory = []
        saveSearchHistory()
    }
}
struct FullScreenVideoPlayerView: UIViewControllerRepresentable {
    let embedURL: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        webView.scrollView.isScrollEnabled = false

        let viewController = UIViewController()
        webView.frame = viewController.view.bounds
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.view.addSubview(webView)

        if let url = URL(string: embedURL) {
            webView.load(URLRequest(url: url))
        }

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let js = """
            setTimeout(() => {
                let attempts = 0;
                let maxAttempts = 20;
                let interval = setInterval(() => {
                    let v = document.querySelector('video');
                    if (v) {
                        v.muted = false;
                        v.play().catch(e => console.log('Autoplay fail:', e));
                        clearInterval(interval);
                    } else {
                        attempts++;
                        if (attempts >= maxAttempts) {
                            clearInterval(interval);
                        }
                    }
                }, 500);
            }, 2000);
            """
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}
struct TVDetailView: View {
    let show: EmbedItem
    @State private var selectedSeason = 1
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                KFImage(URL(string: show.fullPosterURL))
                    .placeholder {
                        Color.gray.frame(height: 300)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)

                Text(show.title)
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)

                Picker("Season", selection: $selectedSeason) {
                    ForEach(1...viewModel.totalSeasons, id: \.self) { season in
                        Text("Season \(season)").tag(season)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedSeason) {
                    viewModel.fetchEpisodes(for: show.id, season: selectedSeason)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.episodes) { ep in
                            EpisodeCard(showID: show.id, selectedSeason: selectedSeason, episode: ep)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchSeasonCount(showId: show.id)
            viewModel.fetchEpisodes(for: show.id, season: 1)
        }
    }
}
struct GridView: View {
    @Binding var items: [EmbedItem]
    let loadMore: () -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                ForEach(items.indices, id: \.self) { index in
                    let item = items[index]
                    NavigationLink(destination: item.isTV ?
                        AnyView(TVDetailView(show: item)) :
                        AnyView(FullScreenVideoPlayerView(embedURL: item.streamURL))) {

                        PosterCard(item: item)
                    }
                    .onAppear {
                        if index == items.count - 1 {
                            loadMore()
                        }
                    }
                }
            }
            .padding([.horizontal, .bottom])
        }
        .background(Color.black)
        .ignoresSafeArea(edges: .top)
    }
}
struct CategoryGridView: View {
    @ObservedObject var viewModel: ContentViewModel
    let category: CategoryCard

    var body: some View {
        GridView(items: $viewModel.categoryResults) {}
            .navigationTitle(category.title)
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if let genreId = category.genreId {
                    viewModel.fetchByGenre(genreId: genreId)
                }
            }
    }
}
struct SearchView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var query = ""
    @State private var isSearching = false
    @FocusState private var searchBarIsFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 12)

                        TextField("Shows, Movies, and More", text: $query)
                            .foregroundColor(.white)
                            .font(.title3)
                            .frame(height: 50)
                            .focused($searchBarIsFocused)
                            .onSubmit {
                                if !query.isEmpty {
                                    isSearching = true
                                    viewModel.search(query: query)
                                    searchBarIsFocused = false
                                }
                            }

                        if !query.isEmpty {
                            Button(action: {
                                query = ""
                                isSearching = false
                                viewModel.searchResults = []
                                searchBarIsFocused = true
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 12)
                            }
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)

                // Conditional Content
                if isSearching && !viewModel.searchResults.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                        ForEach(viewModel.searchResults) { item in
                            NavigationLink(destination: item.isTV ?
                                AnyView(TVDetailView(show: item)) :
                                AnyView(FullScreenVideoPlayerView(embedURL: item.streamURL))) {
                                PosterCard(item: item)
                            }
                        }
                    }
                    .padding(.horizontal)
                } else if searchBarIsFocused && !viewModel.searchHistory.isEmpty {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Recent Searches")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Button("Clear History") {
                                viewModel.clearSearchHistory()
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 5)

                        ForEach(viewModel.searchHistory, id: \.self) { historyQuery in
                            Button(action: {
                                query = historyQuery
                                isSearching = true
                                viewModel.search(query: historyQuery)
                                searchBarIsFocused = false
                            }) {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.gray)
                                    Text(historyQuery)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "arrow.up.left")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                } else if !isSearching {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(CategoryCard.categories) { category in
                            NavigationLink(destination: CategoryGridView(viewModel: viewModel, category: category)) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(category.gradient)
                                        .frame(height: 100)
                                    Text(category.title)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.loadSearchHistory()
        }
    }
}
struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        TabView {
            // Home Tab
            NavigationView {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Home")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                        Spacer()
                        Image("AppLogo") // Make sure this asset exists in your Assets.xcassets
                            .resizable()
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .padding([.horizontal, .top])

                    GridView(items: $viewModel.home) {
                        // Home is preloaded, no loadMore needed
                    }
                }
                .background(Color.black.ignoresSafeArea())
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            // Search Tab
            NavigationView {
                SearchView(viewModel: viewModel)
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }

            // Movies Tab
            NavigationView {
                GridView(items: $viewModel.movies) {
                    viewModel.loadMoreMovies()
                }
                .navigationTitle("Movies")
                .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Movies", systemImage: "film")
            }

            // TV Shows Tab
            NavigationView {
                GridView(items: $viewModel.shows) {
                    viewModel.loadMoreTVShows()
                }
                .navigationTitle("TV Shows")
                .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("TV", systemImage: "tv")
            }
        }
        .onAppear {
            viewModel.fetchMovies()
            viewModel.fetchTVShows()
        }
    }
}
