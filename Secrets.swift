import Foundation

enum Secrets {
    static var tmdbApiKey: String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["TMDB_API_KEY"] as? String,
              !key.isEmpty,
              key != "YOUR_TMDB_API_KEY" else {
            fatalError("Missing TMDB_API_KEY in Secrets.plist. Copy Secrets.example.plist to Secrets.plist and add your key.")
        }
        return key
    }
}
