import SwiftUI
import WebKit
import UIKit
import Combine

// MARK: - API Service
class APIService {
    static let shared = APIService()
    let apiKey = "e316c59b24ce81a8f56c325a3ffd2554"

    func fetch<T: Decodable>(_ type: T.Type, from url: URL, completion: @escaping (Result<T, Error>) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data {
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decoded))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}
struct EmbedItem: Identifiable, Codable {
    let id: Int
    let title: String
    let posterPath: String
    let isTV: Bool

    var streamURL: String {
        isTV ? "https://vidlink.pro/tv/\(id)/1/1??autoplay=true&nextbutton=true" : "https://vidlink.pro/movie/\(id)?autoplay=true&nextbutton=true"
    }

    var fullPosterURL: String {
        "https://image.tmdb.org/t/p/w500\(posterPath)"
    }
}

struct Episode: Identifiable, Codable {
    let id = UUID()
    let episodeNumber: Int
    let stillPath: String?
}

struct SearchResponse: Decodable {
    let results: [EmbedRaw]
}

struct EmbedRaw: Decodable {
    let id: Int
    let poster_path: String?
    let title: String?
    let name: String?
    let media_type: String?
}

struct CategoryCard: Identifiable {
    let id = UUID()
    let title: String
    let gradient: LinearGradient
    let genreId: Int?

    static let categories: [CategoryCard] = [
        CategoryCard(title: "Action", gradient: LinearGradient(colors: [Color.orange, Color.red.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 28),
        CategoryCard(title: "Comedy", gradient: LinearGradient(colors: [Color.green, Color.teal], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 35),
        CategoryCard(title: "Drama", gradient: LinearGradient(colors: [Color.blue, Color.purple.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 18),
        CategoryCard(title: "Horror", gradient: LinearGradient(colors: [Color.purple, Color.black], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 27),
        CategoryCard(title: "Romance", gradient: LinearGradient(colors: [Color.pink, Color.red.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 10749),
        CategoryCard(title: "Sci-Fi", gradient: LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 878),
        CategoryCard(title: "Thriller", gradient: LinearGradient(colors: [Color.red, Color.black], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 53),
        CategoryCard(title: "Animation", gradient: LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 16),
        CategoryCard(title: "Documentary", gradient: LinearGradient(colors: [Color.gray, Color.blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 99),
        CategoryCard(title: "Family", gradient: LinearGradient(colors: [Color.green.opacity(0.7), Color.yellow.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 10751),
        CategoryCard(title: "Fantasy", gradient: LinearGradient(colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 14),
        CategoryCard(title: "Crime", gradient: LinearGradient(colors: [Color.black, Color.red.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing), genreId: 80)
    ]
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

    private var moviePage = 1
    private var showPage = 1
    private let maxHistoryItems = 10
    private let searchHistoryKey = "searchHistory"

    init() {
        loadSearchHistory()
    }

    func fetchMovies() {
        guard let url = URL(string: "https://api.themoviedb.org/3/movie/popular?api_key=\(APIService.shared.apiKey)&language=en-US&page=\(moviePage)") else { return }
        APIService.shared.fetch(SearchResponse.self, from: url) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let response) = result {
                    let items = self?.mapRaw(response.results, isTV: false) ?? []
                    self?.movies += items
                    if self?.moviePage == 1 && self?.home.isEmpty == true {
                        self?.home += items.prefix(10)
                    }
                }
            }
        }
    }

    func fetchTVShows() {
        guard let url = URL(string: "https://api.themoviedb.org/3/tv/popular?api_key=\(APIService.shared.apiKey)&language=en-US&page=\(showPage)") else { return }
        APIService.shared.fetch(SearchResponse.self, from: url) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let response) = result {
                    let items = self?.mapRaw(response.results, isTV: true) ?? []
                    self?.shows += items
                    if self?.showPage == 1 && self?.home.isEmpty == true {
                        self?.home += items.prefix(10)
                    }
                }
            }
        }
    }

    func loadMoreMovies() {
        moviePage += 1
        fetchMovies()
    }

    func loadMoreTVShows() {
        showPage += 1
        fetchTVShows()
    }

    func search(query: String) {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://api.themoviedb.org/3/search/multi?api_key=\(APIService.shared.apiKey)&language=en-US&query=\(encoded)") else { return }

        addSearchQuery(query)

        APIService.shared.fetch(SearchResponse.self, from: url) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let response) = result {
                    self?.searchResults = self?.mapRaw(response.results, isTV: nil) ?? []
                }
            }
        }
    }

    func fetchByGenre(genreId: Int) {
        guard let url = URL(string: "https://api.themoviedb.org/3/discover/movie?api_key=\(APIService.shared.apiKey)&language=en-US&with_genres=\(genreId)") else { return }
        APIService.shared.fetch(SearchResponse.self, from: url) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let response) = result {
                    self?.categoryResults = self?.mapRaw(response.results, isTV: false) ?? []
                }
            }
        }
    }

    private func mapRaw(_ raw: [EmbedRaw], isTV: Bool?) -> [EmbedItem] {
        raw.compactMap { item in
            guard let poster = item.poster_path else { return nil }
            let title = item.title ?? item.name ?? ""
            let tv = item.media_type == "tv" || isTV == true
            return EmbedItem(id: item.id, title: title, posterPath: poster, isTV: tv)
        }
    }

    // Search history management
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
// NetflixAppOptimized.swift - Full SwiftUI App with Views

// [Cut for brevity: APIService, models, and ContentViewModel from previous section remain unchanged above.]

// MARK: - FullScreen Video Player
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
                    }
                }, 500);
            }, 2000);
            """
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}

// MARK: - GridView
struct GridView: View {
    @Binding var items: [EmbedItem]
    let loadMore: () -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                ForEach(items.indices, id: \.self) { index in
                    let item = items[index]
                    NavigationLink(destination: item.isTV ? AnyView(TVDetailView(show: item)) : AnyView(FullScreenVideoPlayerView(embedURL: item.streamURL))) {
                        VStack(alignment: .leading) {
                            AsyncImage(url: URL(string: item.fullPosterURL)) { phase in
                                switch phase {
                                case .empty:
                                    Color.gray.frame(height: 200)
                                case .success(let image):
                                    image.resizable().scaledToFill().frame(height: 200).clipped()
                                case .failure:
                                    Color.red.frame(height: 200)
                                @unknown default:
                                    Color.black.frame(height: 200)
                                }
                            }
                            .cornerRadius(10)

                            Text(item.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .onAppear {
                            if index == items.count - 1 {
                                loadMore()
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.black)
    }
}

// MARK: - TVDetailView
struct TVDetailView: View {
    let show: EmbedItem
    @State private var selectedSeason = 1
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: URL(string: show.fullPosterURL)) { phase in
                    if case let .success(image) = phase {
                        image.resizable().aspectRatio(contentMode: .fit).cornerRadius(12)
                    } else {
                        Color.gray.frame(height: 300)
                    }
                }
                Text(show.title).font(.title).bold().foregroundColor(.white)

                Picker("Season", selection: $selectedSeason) {
                    ForEach(1...viewModel.totalSeasons, id: \.self) { season in
                        Text("Season \(season)").tag(season)
                    }
                }
                .pickerStyle(.menu)
                .padding(.bottom)
                .onChange(of: selectedSeason) {
                    viewModel.fetchEpisodes(for: show.id, season: selectedSeason)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.episodes) { ep in
                            let url = "https://vidlink.pro/tv/\(show.id)/\(selectedSeason)/\(ep.episodeNumber)?autoplay=true&nextbutton=true"
                            NavigationLink(destination: FullScreenVideoPlayerView(embedURL: url)) {
                                VStack {
                                    if let path = ep.stillPath {
                                        AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(path)")) { img in
                                            img.resizable().aspectRatio(contentMode: .fill)
                                                .frame(width: 120, height: 70)
                                                .clipped()
                                                .cornerRadius(8)
                                        } placeholder: {
                                            Color.gray.frame(width: 120, height: 70)
                                        }
                                    } else {
                                        Color.gray.frame(width: 120, height: 70).cornerRadius(8)
                                    }
                                    Text("Ep \(ep.episodeNumber)").font(.caption2).foregroundColor(.white)
                                }
                            }
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

// MARK: - Continue with SearchView and ContentView next on request
// NetflixAppOptimized.swift - Full SwiftUI App with Views

// [Cut for brevity: APIService, models, ContentViewModel, FullScreenVideoPlayerView, GridView, TVDetailView remain above.]

// MARK: - CategoryGridView
struct CategoryGridView: View {
    @ObservedObject var viewModel: ContentViewModel
    let category: CategoryCard

    var body: some View {
        GridView(items: $viewModel.categoryResults) {
            // Optional load more logic here
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if let genreId = category.genreId {
                viewModel.fetchByGenre(genreId: genreId)
            }
        }
    }
}

// MARK: - SearchView
struct SearchView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var query = ""
    @State private var isSearching = false
    @FocusState private var searchBarIsFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray).padding(.leading, 12)
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
                                Image(systemName: "xmark.circle.fill").foregroundColor(.gray).padding(.trailing, 12)
                            }
                        }
                    }
                    .background(Color(.systemGray6)).cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)

                if isSearching && !viewModel.searchResults.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                        ForEach(viewModel.searchResults) { item in
                            NavigationLink(destination: item.isTV ? AnyView(TVDetailView(show: item)) : AnyView(FullScreenVideoPlayerView(embedURL: item.streamURL))) {
                                VStack(alignment: .leading) {
                                    AsyncImage(url: URL(string: item.fullPosterURL)) { phase in
                                        switch phase {
                                        case .empty: Color.gray.frame(height: 200)
                                        case .success(let image): image.resizable().scaledToFill().frame(height: 200).clipped()
                                        case .failure: Color.red.frame(height: 200)
                                        @unknown default: Color.black.frame(height: 200)
                                        }
                                    }.cornerRadius(10)
                                    Text(item.title).font(.caption).fontWeight(.medium).foregroundColor(.white).lineLimit(1)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                } else if searchBarIsFocused && !viewModel.searchHistory.isEmpty {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Recent Searches").font(.headline).foregroundColor(.white)
                            Spacer()
                            Button("Clear History") {
                                viewModel.clearSearchHistory()
                            }.font(.caption).foregroundColor(.red)
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
                                    Image(systemName: "clock.fill").foregroundColor(.gray)
                                    Text(historyQuery).foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "arrow.up.left").foregroundColor(.gray)
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
                                    RoundedRectangle(cornerRadius: 12).fill(category.gradient).frame(height: 100)
                                    Text(category.title).font(.title2).fontWeight(.semibold).foregroundColor(.white)
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

// MARK: - ContentView
struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        TabView {
            NavigationView {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Home").font(.largeTitle).bold().foregroundColor(.white)
                        Spacer()
                        Image(systemName: "film") // Replace with your app logo if needed
                            .resizable()
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .padding([.horizontal, .top])

                    GridView(items: $viewModel.home) {}
                }
                .background(Color.black.ignoresSafeArea())
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            NavigationView {
                SearchView(viewModel: viewModel)
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }

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

// MARK: - Preview
#Preview {
    ContentView().preferredColorScheme(.dark)
}

