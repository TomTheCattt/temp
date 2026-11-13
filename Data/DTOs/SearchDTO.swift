//
//  SearchDTO.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation

// MARK: - Search Request DTOs

nonisolated struct SearchRequestDTO: Codable {
    let q: String
    let type: SearchTypeDTO?
    let limit: Int
    let cursor: String?
}

nonisolated struct SuggestionsRequestDTO: Codable {
    let q: String
    let limit: Int
}

nonisolated struct TrendingRequestDTO: Codable {
    let limit: Int
    let timeWindowHours: Int
}

nonisolated struct AnalyticsRequestDTO: Codable {
    let days: Int
}

// MARK: - Search Response DTOs

nonisolated struct SearchResponseDTO: Codable {
    let query: String
    let type: String
    let results: [SearchResultItemDTO]
    let pagination: SearchPaginationDTO
    let tookMs: Int
}

nonisolated struct SearchResultItemDTO: Codable {
    // Can be User, Post, Reel, Hashtag, Location, or Audio
    let id: String
    let type: SearchResultTypeDTO
    let title: String
    let subtitle: String?
    let imageUrl: String?
    let metadata: [String: String]?
}

nonisolated enum SearchResultTypeDTO: String, Codable {
    case user = "user"
    case post = "post"
    case reel = "reel"
    case hashtag = "hashtag"
    case location = "location"
    case audio = "audio"
}

nonisolated struct SearchPaginationDTO: Codable {
    let nextCursor: String?
    let hasMore: Bool
}

nonisolated struct SuggestionsResponseDTO: Codable {
    let query: String
    let suggestions: [SearchSuggestionDTO]
}

nonisolated struct SearchSuggestionDTO: Codable {
    let text: String
    let type: SearchTypeDTO
    let metadata: [String: String]?
}

nonisolated struct RecentSearchesResponseDTO: Codable {
    let recent: [RecentSearchDTO]
}

nonisolated struct RecentSearchDTO: Codable {
    let query: String
    let type: String
    let timestamp: Date
}

nonisolated struct TrendingResponseDTO: Codable {
    let trending: [TrendingHashtagDTO]
    let timeWindowHours: Int
}

nonisolated struct TrendingHashtagDTO: Codable {
    let tag: String
    let postsCount: Int
    let reelsCount: Int
    let trendScore: Double
}

nonisolated struct AnalyticsResponseDTO: Codable {
    let periodDays: Int
    let totalSearches: Int
    let uniqueUsers: Int
    let topQueries: [SearchQueryStatDTO]
    let searchesByType: [String: Int]
}

nonisolated struct SearchQueryStatDTO: Codable {
    let query: String
    let count: Int
    let type: String
}

// MARK: - Hashtag & Location DTOs

nonisolated struct HashtagPageResponseDTO: Codable {
    let hashtag: HashtagInfoDTO
    let topPosts: [PostSummaryDTO]
    let topReels: [ReelSummaryDTO]
}

nonisolated struct HashtagInfoDTO: Codable {
    let id: String
    let tag: String
    let postsCount: Int
    let reelsCount: Int
}

nonisolated struct LocationPageResponseDTO: Codable {
    let location: LocationInfoDTO
    let topPosts: [PostSummaryDTO]
}

nonisolated struct LocationInfoDTO: Codable {
    let id: String
    let name: String
    let address: String?
    let lat: Double
    let lng: Double
    let category: String?
    let postsCount: Int
}

// Lightweight summaries
struct PostSummaryDTO: Codable {
    let id: String
    let authorId: String
    let caption: String?
    let locationName: String?
    let likesCount: Int
    let commentsCount: Int
    let createdAt: Date
    let author: UserSummaryDTO
    let mediaItems: [MediaItemSummaryDTO]?
}

struct ReelSummaryDTO: Codable {
    let id: String
    let authorId: String
    let caption: String?
    let videoUrl: String
    let thumbnailUrl: String?
    let likesCount: Int
    let commentsCount: Int
    let playsCount: Int
    let createdAt: Date
    let author: UserSummaryDTO
}

struct UserSummaryDTO: Codable {
    let id: String
    let username: String
    let fullName: String
    let avatarUrl: String?
    let isVerified: Bool
}

struct MediaItemSummaryDTO: Codable {
    let url: String
    let type: String
    let width: Int?
    let height: Int?
}

// MARK: - Search Enums

nonisolated enum SearchTypeDTO: String, Codable, CaseIterable {
    case users = "users"
    case posts = "posts"
    case reels = "reels"
    case hashtags = "hashtags"
    case locations = "locations"
    case audio = "audio"
    case all = "all"

    var domainType: SearchType {
        switch self {
        case .users: return .users
        case .posts: return .posts
        case .reels: return .reels
        case .hashtags: return .hashtags
        case .locations: return .locations
        case .audio: return .audio
        case .all: return .all
        }
    }
}

// Import domain enum
// Note: SearchType is defined in SearchEndpoint.swift