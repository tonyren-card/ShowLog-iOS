import Foundation

enum Config {
    private static let info = Bundle.main.infoDictionary!

    // MARK: - TMDB
    static let tmdbAPIKey      = info["TMDBAPIKey"] as! String
    static let tmdbBaseURL     = "https://api.themoviedb.org/3"
    static let tmdbImageBase   = "https://image.tmdb.org/t/p/w500"
    static let tmdbBackdropBase = "https://image.tmdb.org/t/p/w1280"

    // MARK: - Supabase
    static let supabaseURL     = "https://\(info["SupabaseHost"] as! String)"
    static let supabaseAnonKey = info["SupabaseAnonKey"] as! String

    // MARK: - Netlify
    static let netlifyBaseURL  = "https://showlogd.netlify.app"
}
