import Foundation

struct Profile: Codable, Identifiable, Hashable {
    let id: String
    var username: String?
    var avatarUrl: String?
    var isPublic: Bool
    /// Local part of the email (before "@") — only ever populated by search_profiles
    /// as a fallback display name when the user hasn't set a username yet. The full
    /// email never leaves the database.
    var emailPrefix: String? = nil

    enum CodingKeys: String, CodingKey {
        case id, username
        case avatarUrl = "avatar_url"
        case isPublic  = "is_public"
        case emailPrefix = "email_prefix"
    }

    /// What to show in the UI when there's no username.
    var displayName: String { username ?? emailPrefix ?? "Unknown" }
}
