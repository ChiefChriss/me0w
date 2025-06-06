import SwiftUI
import WebKit
import UIKit
import Kingfisher

// MARK: - Models

struct EmbedItem: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let title: String
    let overview: String  // Single source of truth for description
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double
    let releaseDate: String?
    let isTV: Bool
    let streamURL: String
    
    // Add a unique identifier that combines id and media type
    var uniqueId: String {
        "\(isTV ? "tv" : "movie")_\(id)"
    }
    
    // Update Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueId)
    }
    
    // Update Equatable conformance
    static func == (lhs: EmbedItem, rhs: EmbedItem) -> Bool {
        lhs.uniqueId == rhs.uniqueId
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, overview, posterPath, backdropPath, voteAverage, releaseDate, isTV, streamURL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        overview = try container.decode(String.self, forKey: .overview)
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        voteAverage = try container.decode(Double.self, forKey: .voteAverage)
        releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        isTV = try container.decode(Bool.self, forKey: .isTV)
        streamURL = try container.decode(String.self, forKey: .streamURL)
    }
    
    init(id: Int, title: String, overview: String, posterPath: String?, backdropPath: String?, 
         voteAverage: Double, releaseDate: String?, isTV: Bool, streamURL: String) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.voteAverage = voteAverage
        self.releaseDate = releaseDate
        self.isTV = isTV
        self.streamURL = streamURL
    }
    
    var fullPosterURL: String {
        if let path = posterPath {
            return "https://image.tmdb.org/t/p/w500\(path)"
        }
        return ""  // Return empty string or a default image URL
    }
    
    var fullBackdropURL: String {
        if let path = backdropPath {
            return "https://image.tmdb.org/t/p/original\(path)"
        }
        return ""
    }
}

struct Episode: Identifiable, Codable {
    let id: Int
    let episodeNumber: Int
    let name: String
    let overview: String
    let stillPath: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case episodeNumber = "episode_number"
        case name
        case overview
        case stillPath = "still_path"
    }
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
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            KFImage(URL(string: "https://image.tmdb.org/t/p/w500\(episode.stillPath ?? "")"))
                .placeholder {
                    Color.gray
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 280, height: 157)
                .clipped()
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Episode \(episode.episodeNumber)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(episode.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(episode.overview)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(3)
            }
            .padding(.horizontal, 8)
        }
        .frame(width: 280)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

// Add ContentType enum at the top level
enum ContentType {
    case movies
    case shows
    case category
    case search
    case home
}

// Add TMDBResponse struct at the top of the file
struct TMDBResponse: Codable {
    let page: Int
    let results: [TMDBResult]
    let totalPages: Int
    let totalResults: Int
    
    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct TMDBResult: Codable {
    let id: Int
    let title: String?
    let name: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double
    let releaseDate: String?
    let firstAirDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
    }
}

// Update ContentViewModel to handle thread safety and actor isolation
@MainActor
class ContentViewModel: ObservableObject {
    @Published var movies: [EmbedItem] = []
    @Published var shows: [EmbedItem] = []
    @Published var home: [EmbedItem] = []
    @Published var searchResults: [EmbedItem] = []
    @Published var categoryResults: [EmbedItem] = []
    @Published var searchHistory: [String] = []
    @Published var totalSeasons: Int = 0
    @Published var episodes: [Episode] = []
    
    @Published var isLoading = false
    @Published var error: String?
    @Published var isLoadingMore = false
    @Published var featuredContent: EmbedItem?
    @Published var continueWatching: [EmbedItem] = []
    @Published var myList: [EmbedItem] = []
    
    let apiKey = "e316c59b24ce81a8f56c325a3ffd2554"
    @Published var moviePage = 1
    @Published var showPage = 1
    private let maxHistoryItems = 10
    private let searchHistoryKey = "searchHistory"
    private let myListKey = "myList"
    private let continueWatchingKey = "continueWatching"
    
    // Add a flag to track if initial load is done
    @Published var hasInitialLoad = false
    
    // Change from private to internal
    var currentCategoryId: Int?
    
    @Published var hasReachedEnd = false
    
    private let maxMyListItems = 100
    private let maxContinueWatchingItems = 20
    private let requestTimeout: TimeInterval = 30
    
    @Published var trendingMovies: [EmbedItem] = []
    @Published var trendingShows: [EmbedItem] = []
    
    private var networkSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()
    
    init() {
        // Load saved data
        loadSearchHistory()
        loadMyList()
        loadContinueWatching()
        
        // Start loading data
        Task {
            await fetchInitialData()
        }
    }
    
    // Change to public access level
    func fetchInitialData() async {
        // Use the original methods for initial data loading
        fetchMovies()
        fetchTVShows()
        fetchTrendingContent()
    }
    
    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.timeoutInterval = requestTimeout
        request.cachePolicy = .returnCacheDataElseLoad
        return request
    }
    
    func fetchMovies() {
        guard !isLoading else { return }
        Task { @MainActor in
            isLoading = true
            error = nil
        }
        
        let urlString = "https://api.themoviedb.org/3/movie/popular?api_key=\(apiKey)&language=en-US&page=\(moviePage)"
        guard let url = URL(string: urlString) else {
            Task { @MainActor in
                isLoading = false
                isLoadingMore = false
                error = "Invalid URL"
            }
            return
        }
        
        let request = makeRequest(url: url)
        
        networkSession.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    self.isLoadingMore = false
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.error = "Invalid response"
                    self.isLoadingMore = false
                    return
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    guard let data = data else {
                        self.error = "No data received"
                        self.isLoadingMore = false
                        return
                    }
                    
                    self.parse(data: data, isTV: false) { [weak self] items in
                        guard let self = self else { return }
                        Task { @MainActor in
                            self.hasInitialLoad = true
                            self.isLoadingMore = false
                            
                            if self.moviePage == 1 {
                                // Ensure unique items by using uniqueId
                                self.movies = Array(Set(items))
                                if self.home.isEmpty {
                                    self.home = Array(Set(items.prefix(10)))
                                    self.featuredContent = items.first
                                }
                            } else {
                                if items.isEmpty {
                                    self.hasReachedEnd = true
                                    self.moviePage -= 1
                                } else {
                                    // Ensure unique items when appending
                                    let newItems = Set(items)
                                    let existingIds = Set(self.movies.map { $0.uniqueId })
                                    let uniqueNewItems = newItems.filter { !existingIds.contains($0.uniqueId) }
                                    self.movies += Array(uniqueNewItems)
                                }
                            }
                        }
                    }
                case 429:
                    self.error = "Rate limit exceeded. Please try again later."
                    self.isLoadingMore = false
                case 401:
                    self.error = "Authentication failed. Please check your API key."
                    self.isLoadingMore = false
                default:
                    self.error = "Server error: \(httpResponse.statusCode)"
                    self.isLoadingMore = false
                }
            }
        }.resume()
    }
    
    func fetchTVShows() {
        guard !isLoading else { return }
        Task { @MainActor in
            isLoading = true
            error = nil
        }
        
        let urlString = "https://api.themoviedb.org/3/tv/popular?api_key=\(apiKey)&language=en-US&page=\(showPage)"
        guard let url = URL(string: urlString) else {
            Task { @MainActor in
                isLoading = false
                isLoadingMore = false
                error = "Invalid URL"
            }
            return
        }
        
        let request = makeRequest(url: url)
        
        networkSession.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    self.isLoadingMore = false
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.error = "Invalid response"
                    self.isLoadingMore = false
                    return
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    guard let data = data else {
                        self.error = "No data received"
                        self.isLoadingMore = false
                        return
                    }
                    
                    self.parse(data: data, isTV: true) { [weak self] items in
                        guard let self = self else { return }
                        Task { @MainActor in
                            self.hasInitialLoad = true
                            self.isLoadingMore = false
                            
                            if self.showPage == 1 {
                                self.shows = items
                            } else {
                                if items.isEmpty {
                                    self.hasReachedEnd = true
                                    self.showPage -= 1
                                } else {
                                    self.shows += items
                                }
                            }
                        }
                    }
                case 429:
                    self.error = "Rate limit exceeded. Please try again later."
                    self.isLoadingMore = false
                case 401:
                    self.error = "Authentication failed. Please check your API key."
                    self.isLoadingMore = false
                default:
                    self.error = "Server error: \(httpResponse.statusCode)"
                    self.isLoadingMore = false
                }
            }
        }.resume()
    }
    
    func fetchTrendingContent() {
        // Fetch trending movies
        let moviesURLString = "https://api.themoviedb.org/3/trending/movie/day?api_key=\(apiKey)&language=en-US"
        guard let moviesURL = URL(string: moviesURLString) else { return }
        
        URLSession.shared.dataTask(with: moviesURL) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else { return }
            
            self.parse(data: data, isTV: false) { [weak self] items in
                DispatchQueue.main.async {
                    self?.trendingMovies = items
                }
            }
        }.resume()
        
        // Fetch trending TV shows
        let showsURLString = "https://api.themoviedb.org/3/trending/tv/day?api_key=\(apiKey)&language=en-US"
        guard let showsURL = URL(string: showsURLString) else { return }
        
        URLSession.shared.dataTask(with: showsURL) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else { return }
            
            self.parse(data: data, isTV: true) { [weak self] items in
                DispatchQueue.main.async {
                    self?.trendingShows = items
                }
            }
        }.resume()
    }
    
    @MainActor
    private func parseAsync(data: Data, isTV: Bool) async {
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(TMDBResponse.self, from: data)
            let items = response.results.map { result in
                EmbedItem(
                    id: result.id,
                    title: result.title ?? result.name ?? "",
                    overview: result.overview ?? "No overview available",
                    posterPath: result.posterPath,
                    backdropPath: result.backdropPath,
                    voteAverage: result.voteAverage,
                    releaseDate: result.releaseDate ?? result.firstAirDate,
                    isTV: isTV,
                    streamURL: isTV ? 
                        "https://vidlink.pro/tv/\(result.id)/1/1?autoplay=true&nextbutton=true" :
                        "https://vidlink.pro/movie/\(result.id)?autoplay=true&nextbutton=true"
                )
            }
            
            hasInitialLoad = true
            isLoadingMore = false
            
            if isTV {
                if showPage == 1 {
                    shows = items
                } else {
                    if items.isEmpty {
                        hasReachedEnd = true
                        showPage -= 1
                    } else {
                        shows += items
                    }
                }
            } else {
                if moviePage == 1 {
                    movies = items
                    if home.isEmpty {
                        home = Array(items.prefix(10))
                        featuredContent = items.first
                    }
                } else {
                    if items.isEmpty {
                        hasReachedEnd = true
                        moviePage -= 1
                    } else {
                        movies += items
                    }
                }
            }
        } catch {
            self.error = "Failed to parse data: \(error.localizedDescription)"
            isLoadingMore = false
        }
        isLoading = false
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
        let urlString = "https://api.themoviedb.org/3/tv/\(showId)?api_key=\(apiKey)&language=en-US"
        guard let url = URL(string: urlString) else { return }
        
        networkSession.dataTask(with: makeRequest(url: url)) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let numberOfSeasons = json["number_of_seasons"] as? Int {
                    Task { @MainActor in
                        self.totalSeasons = numberOfSeasons
                    }
                }
            } catch {
                print("Error parsing season count: \(error)")
            }
        }.resume()
    }

    func fetchEpisodes(for showId: Int, season: Int) {
        let urlString = "https://api.themoviedb.org/3/tv/\(showId)/season/\(season)?api_key=\(apiKey)&language=en-US"
        guard let url = URL(string: urlString) else { return }
        
        networkSession.dataTask(with: makeRequest(url: url)) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let episodesData = json["episodes"] as? [[String: Any]] {
                    let episodes = try episodesData.compactMap { episodeData -> Episode? in
                        let data = try JSONSerialization.data(withJSONObject: episodeData)
                        return try JSONDecoder().decode(Episode.self, from: data)
                    }
                    
                    Task { @MainActor in
                        self.episodes = episodes.sorted { $0.episodeNumber < $1.episodeNumber }
                    }
                }
            } catch {
                print("Error parsing episodes: \(error)")
            }
        }.resume()
    }

    func search(query: String) {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://api.themoviedb.org/3/search/multi?api_key=\(apiKey)&language=en-US&query=\(encoded)") else { return }

        addSearchQuery(query)

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self, let data = data else { return }
            // Pass false as default, the parse method will determine the actual type from media_type
            self.parse(data: data, isTV: false) { items in
                DispatchQueue.main.async {
                    self.searchResults = items
                }
            }
        }.resume()
    }

    func fetchByGenre(genreId: Int) {
        currentCategoryId = genreId
        guard !isLoading else { return }
        isLoading = true
        error = nil
        
        guard let url = URL(string: "https://api.themoviedb.org/3/discover/movie?api_key=\(apiKey)&language=en-US&with_genres=\(genreId)") else {
            isLoading = false
            error = "Invalid URL"
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.isLoadingMore = false
                    self.error = error.localizedDescription
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.isLoadingMore = false
                    self.error = "Invalid server response"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.isLoadingMore = false
                    self.error = "No data received"
                }
                return
            }
            
            self.parse(data: data, isTV: false) { [weak self] items in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.isLoadingMore = false
                    self.categoryResults = items
                }
            }
        }.resume()
    }

    private func parse(data: Data, isTV: Bool, completion: @escaping ([EmbedItem]) -> Void) {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw NSError(domain: "ParseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
            }
            
            guard let results = json["results"] as? [[String: Any]] else {
                throw NSError(domain: "ParseError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Missing results array"])
            }
            
            let items = try results.compactMap { dict -> EmbedItem? in
                guard let id = dict["id"] as? Int else {
                    print("Warning: Missing id in item")
                    return nil
                }
                
                guard let title = dict["title"] as? String ?? dict["name"] as? String else {
                    print("Warning: Missing title in item with id: \(id)")
                    return nil
                }
                
                let posterPath = dict["poster_path"] as? String
                let mediaType = dict["media_type"] as? String
                let isTVResult: Bool = {
                    if let type = mediaType {
                        return type == "tv"
                    }
                    return isTV
                }()
                
                let overview = dict["overview"] as? String ?? "No overview available"
                let backdropPath = dict["backdrop_path"] as? String
                let voteAverage = dict["vote_average"] as? Double ?? 0.0
                let releaseDate = dict["release_date"] as? String ?? dict["first_air_date"] as? String
                
                return EmbedItem(
                    id: id,
                    title: title,
                    overview: overview,
                    posterPath: posterPath,
                    backdropPath: backdropPath,
                    voteAverage: voteAverage,
                    releaseDate: releaseDate,
                    isTV: isTVResult,
                    streamURL: isTVResult ? 
                        "https://vidlink.pro/tv/\(id)/1/1?autoplay=true&nextbutton=true" :
                        "https://vidlink.pro/movie/\(id)?autoplay=true&nextbutton=true"
                )
            }
            
            if items.isEmpty {
                throw NSError(domain: "ParseError", code: -3, userInfo: [NSLocalizedDescriptionKey: "No valid items found in response"])
            }
            
            Task { @MainActor in
                completion(items)
            }
        } catch {
            Task { @MainActor in
                self.error = "Failed to parse data: \(error.localizedDescription)"
                completion([])
            }
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

    func toggleMyList(_ item: EmbedItem) {
        if myList.contains(where: { $0.id == item.id }) {
            myList.removeAll { $0.id == item.id }
        } else {
            if myList.count >= maxMyListItems {
                myList.removeLast()
            }
            myList.append(item)
        }
        saveMyList()
    }
    
    func addToContinueWatching(_ item: EmbedItem) {
        if !continueWatching.contains(where: { $0.id == item.id }) {
            continueWatching.insert(item, at: 0)
            if continueWatching.count > maxContinueWatchingItems {
                continueWatching = Array(continueWatching.prefix(maxContinueWatchingItems))
            }
            saveContinueWatching()
        }
    }
    
    private func loadMyList() {
        if let data = UserDefaults.standard.data(forKey: myListKey),
           let items = try? JSONDecoder().decode([EmbedItem].self, from: data) {
            myList = items
        }
    }
    
    private func saveMyList() {
        do {
            let data = try JSONEncoder().encode(myList)
            UserDefaults.standard.set(data, forKey: myListKey)
        } catch {
            print("Error saving my list: \(error)")
        }
    }
    
    private func loadContinueWatching() {
        if let data = UserDefaults.standard.data(forKey: continueWatchingKey),
           let items = try? JSONDecoder().decode([EmbedItem].self, from: data) {
            continueWatching = items
        }
    }
    
    private func saveContinueWatching() {
        do {
            let data = try JSONEncoder().encode(continueWatching)
            UserDefaults.standard.set(data, forKey: continueWatchingKey)
        } catch {
            print("Error saving continue watching: \(error)")
        }
    }

    // Add back the reset methods
    func resetMovies() {
        moviePage = 1
        movies = []
        hasInitialLoad = false
        fetchMovies()
    }
    
    func resetShows() {
        showPage = 1
        shows = []
        hasInitialLoad = false
        fetchTVShows()
    }
    
    func resetCategory() {
        categoryResults = []
        hasInitialLoad = false
        if let genreId = currentCategoryId {
            fetchByGenre(genreId: genreId)
        }
    }
}

struct FullScreenVideoPlayerView: UIViewControllerRepresentable {
    let embedURL: String
    let item: EmbedItem
    @ObservedObject var viewModel: ContentViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel, item: item)
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
        let viewModel: ContentViewModel
        let item: EmbedItem
        
        init(viewModel: ContentViewModel, item: EmbedItem) {
            self.viewModel = viewModel
            self.item = item
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            viewModel.addToContinueWatching(item)
            
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
    let item: EmbedItem
    @ObservedObject var viewModel: ContentViewModel
    @State private var selectedSeason = 1
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                KFImage(URL(string: item.fullPosterURL))
                    .placeholder {
                        Color.gray.frame(height: 300)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                
                Text(item.title)
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                
                if viewModel.totalSeasons > 0 {
                    Picker("Season", selection: $selectedSeason) {
                        ForEach(1...viewModel.totalSeasons, id: \.self) { season in
                            Text("Season \(season)").tag(season)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedSeason) {
                        viewModel.fetchEpisodes(for: item.id, season: selectedSeason)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.episodes) { ep in
                                NavigationLink(destination: FullScreenVideoPlayerView(
                                    embedURL: "https://vidlink.pro/tv/\(item.id)/\(selectedSeason)/\(ep.episodeNumber)?autoplay=true&nextbutton=true",
                                    item: item,
                                    viewModel: viewModel
                                )) {
                                    EpisodeCard(showID: item.id, selectedSeason: selectedSeason, episode: ep, onTap: {})
                                }
                            }
                        }
                    }
                } else {
                    // If no seasons data is available, show the first episode directly
                    NavigationLink(destination: FullScreenVideoPlayerView(
                        embedURL: item.streamURL,
                        item: item,
                        viewModel: viewModel
                    )) {
                        Text("Watch First Episode")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchSeasonCount(showId: item.id)
            viewModel.fetchEpisodes(for: item.id, season: selectedSeason)
        }
    }
}

// Add a loading view
struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            Text("Loading...")
                .foregroundColor(.white)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// Add an error view
struct ErrorView: View {
    let error: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            Text(error)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Button("Retry") {
                retryAction()
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// Update ContentCard to fix title truncation
struct ContentCard: View {
    let item: EmbedItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            KFImage(URL(string: item.fullPosterURL))
                .placeholder {
                    Color.gray
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 160, height: 240)
                .clipped()
                .cornerRadius(8)
            
            Text(item.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(width: 160, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
        }
    }
}

// Update DetailView to remove unnecessary optional check
struct DetailView: View {
    let item: EmbedItem
    @ObservedObject var viewModel: ContentViewModel
    @State private var isAddingToMyList = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: URL(string: item.fullPosterURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 400)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 400)
                            .clipped()
                    case .failure:
                        Image(systemName: "film")
                            .frame(maxWidth: .infinity)
                            .frame(height: 400)
                            .background(Color.gray.opacity(0.3))
                    @unknown default:
                        EmptyView()
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(item.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Overview")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(item.overview)  // No need for if let since overview is non-optional
                        .font(.body)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 16) {
                        NavigationLink(destination: Group {
                            if item.isTV {
                                TVDetailView(item: item, viewModel: viewModel)
                            } else {
                                FullScreenVideoPlayerView(embedURL: item.streamURL, item: item, viewModel: viewModel)
                            }
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Play")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            isAddingToMyList = true
                            viewModel.toggleMyList(item)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isAddingToMyList = false
                            }
                        }) {
                            HStack {
                                Image(systemName: viewModel.myList.contains(where: { $0.id == item.id }) ? "checkmark" : "plus")
                                Text(viewModel.myList.contains(where: { $0.id == item.id }) ? "My List" : "Add to My List")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .opacity(isAddingToMyList ? 0.5 : 1.0)
                        }
                        .disabled(isAddingToMyList)
                    }
                }
                .padding()
            }
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Update GridView to restore infinite scroll
struct GridView: View {
    @ObservedObject var viewModel: ContentViewModel
    @Binding var items: [EmbedItem]
    let contentType: ContentType
    let shouldLoadMore: Bool
    let title: String
    
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            if viewModel.isLoading && items.isEmpty {
                LoadingView()
            } else if let error = viewModel.error {
                ErrorView(error: error) {
                    Task { @MainActor in
                        viewModel.isLoadingMore = false
                        viewModel.error = nil
                        viewModel.hasReachedEnd = false
                        loadMore()
                    }
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(items, id: \.uniqueId) { item in
                            NavigationLink {
                                if item.isTV {
                                    TVDetailView(item: item, viewModel: viewModel)
                                } else {
                                    FullScreenVideoPlayerView(embedURL: item.streamURL, item: item, viewModel: viewModel)
                                }
                            } label: {
                                ContentCard(item: item)
                                    .onAppear {
                                        if shouldLoadMore && item.id == items.last?.id && !viewModel.isLoadingMore && !viewModel.hasReachedEnd {
                                            loadMore()
                                        }
                                    }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                    
                    if viewModel.isLoadingMore {
                        ProgressView()
                            .padding()
                    }
                }
                .refreshable {
                    await refreshContent()
                }
            }
        }
    }
    
    private func loadMore() {
        guard !viewModel.isLoadingMore && !viewModel.hasReachedEnd else { return }
        
        Task { @MainActor in
            viewModel.isLoadingMore = true
            
            switch contentType {
            case .movies:
                viewModel.moviePage += 1
                viewModel.fetchMovies()
            case .shows:
                viewModel.showPage += 1
                viewModel.fetchTVShows()
            case .category:
                if let genreId = viewModel.currentCategoryId {
                    viewModel.fetchByGenre(genreId: genreId)
                }
            case .search, .home:
                break
            }
        }
    }
    
    private func refreshContent() async {
        viewModel.hasReachedEnd = false
        switch contentType {
        case .movies:
            viewModel.resetMovies()
        case .shows:
            viewModel.resetShows()
        case .category:
            viewModel.resetCategory()
        case .search, .home:
            break
        }
    }
}

struct CategoryGridView: View {
    @ObservedObject var viewModel: ContentViewModel
    let category: CategoryCard

    var body: some View {
        GridView(viewModel: viewModel, items: $viewModel.categoryResults, contentType: ContentType.category, shouldLoadMore: false, title: category.title)
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
                    GridView(viewModel: viewModel, items: $viewModel.searchResults, contentType: ContentType.search, shouldLoadMore: false, title: "Search Results")
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

// Update FeaturedBannerView to support navigation on play
struct FeaturedBannerView: View {
    let item: EmbedItem
    let onAdd: () -> Void
    let currentIndex: Int
    let totalCount: Int
    @ObservedObject var viewModel: ContentViewModel
    
    @State private var isPlaying = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            KFImage(URL(string: item.fullBackdropURL ?? item.fullPosterURL))
                .resizable()
                .aspectRatio(16/9, contentMode: .fill)
                .frame(maxWidth: .infinity, minHeight: 280, maxHeight: 340)
                .clipped()
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.85), Color.clear, Color.black.opacity(0.7), Color.black.opacity(0.95)]),
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .ignoresSafeArea(edges: .top)

            VStack(alignment: .leading, spacing: 12) {
                Text("Home")
                    .font(.largeTitle).bold()
                    .foregroundColor(.white)
                    .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44)
                    .padding(.leading, 16)

                Spacer()

                if !item.overview.isEmpty {
                    Text("\"\(item.overview)\"")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 16)
                        .lineLimit(2)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.title).bold()
                        .foregroundColor(.white)
                        .lineLimit(2)
                    HStack(spacing: 10) {
                        if let release = item.releaseDate {
                            Text(release)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        if item.isTV {
                            Text("TV Show")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        } else {
                            Text("Movie")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Text(String(format: "%.1f ★", item.voteAverage))
                            .font(.subheadline)
                            .foregroundColor(.yellow)
                    }
                }
                .padding(.horizontal, 16)

                HStack(spacing: 16) {
                    NavigationLink(
                        destination: Group {
                            if item.isTV {
                                TVDetailView(item: item, viewModel: viewModel)
                            } else {
                                FullScreenVideoPlayerView(embedURL: item.streamURL, item: item, viewModel: viewModel)
                            }
                        },
                        isActive: $isPlaying
                    ) {
                        Button(action: { isPlaying = true }) {
                            Image(systemName: "play.fill")
                                .foregroundColor(.black)
                                .frame(width: 44, height: 44)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                    }
                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.gray.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)

                if totalCount > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<totalCount, id: \.self) { idx in
                            Circle()
                                .fill(idx == currentIndex ? Color.white : Color.white.opacity(0.4))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, minHeight: 280, maxHeight: 340)
        .background(Color.black)
    }
}

// Update ContentView to use custom headers
struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        TabView {
            // Home Tab
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if let featured = viewModel.featuredContent {
                            FeaturedBannerView(
                                item: featured,
                                onAdd: { /* handle add to list */ },
                                currentIndex: 0,
                                totalCount: 1,
                                viewModel: viewModel
                            )
                            Spacer().frame(height: 24)
                        }
                        
                        if !viewModel.continueWatching.isEmpty {
                            ContinueWatchingSection(viewModel: viewModel)
                        }
                        
                        if !viewModel.trendingMovies.isEmpty {
                            HorizontalScrollingSection(
                                title: "Trending Movies",
                                items: viewModel.trendingMovies,
                                viewModel: viewModel
                            )
                        }
                        
                        if !viewModel.trendingShows.isEmpty {
                            HorizontalScrollingSection(
                                title: "Trending TV Shows",
                                items: viewModel.trendingShows,
                                viewModel: viewModel
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Popular on Me0w")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            GridView(viewModel: viewModel, items: $viewModel.home, contentType: ContentType.home, shouldLoadMore: false, title: "Home")
                        }
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
                GridView(
                    viewModel: viewModel,
                    items: $viewModel.movies,
                    contentType: .movies,
                    shouldLoadMore: true,
                    title: "Movies"
                )
            }
            .tabItem {
                Label("Movies", systemImage: "film")
            }

            // TV Shows Tab
            NavigationView {
                GridView(
                    viewModel: viewModel,
                    items: $viewModel.shows,
                    contentType: .shows,
                    shouldLoadMore: true,
                    title: "TV Shows"
                )
            }
            .tabItem {
                Label("TV Shows", systemImage: "tv")
            }
        }
        .onAppear {
            // Initial data fetch
            if !viewModel.hasInitialLoad {
                Task {
                    await viewModel.fetchInitialData()
                }
            }
        }
    }
}

// Restore ContinueWatchingSection
struct ContinueWatchingSection: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Continue Watching")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.continueWatching) { item in
                        NavigationLink(destination: Group {
                            if item.isTV {
                                TVDetailView(item: item, viewModel: viewModel)
                            } else {
                                FullScreenVideoPlayerView(embedURL: item.streamURL, item: item, viewModel: viewModel)
                            }
                        }) {
                            VStack(alignment: .leading) {
                                KFImage(URL(string: item.fullPosterURL))
                                    .placeholder {
                                        Color.gray
                                    }
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 200, height: 120)
                                    .clipped()
                                    .cornerRadius(8)
                                
                                Text(item.title)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// Restore HorizontalScrollingSection
struct HorizontalScrollingSection: View {
    let title: String
    let items: [EmbedItem]
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(items, id: \.uniqueId) { item in
                        NavigationLink {
                            if item.isTV {
                                TVDetailView(item: item, viewModel: viewModel)
                            } else {
                                FullScreenVideoPlayerView(embedURL: item.streamURL, item: item, viewModel: viewModel)
                            }
                        } label: {
                            ContentCard(item: item)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}
