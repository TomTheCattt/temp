//
//  SearchMapper.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation

// MARK: - SearchMapper

struct SearchMapper {
    nonisolated static func map(_ dto: SearchResponseDTO) -> SearchResult {
        return SearchResult(
            query: dto.query,
            type: dto.type,
            results: dto.results.map(map),
            pagination: map(dto.pagination),
            tookMs: dto.tookMs
        )
    }

    nonisolated static func map(_ dto: SearchResultItemDTO) -> SearchResultItem {
        return SearchResultItem(
            id: dto.id,
            type: map(dto.type),
            title: dto.title,
            subtitle: dto.subtitle,
            imageUrl: dto.imageUrl,
            metadata: dto.metadata
        )
    }

    nonisolated static func map(_ dto: SearchResultTypeDTO) -> SearchResultType {
        // Since both enums have the same raw values, we can convert directly
        return SearchResultType(rawValue: dto.rawValue) ?? .user
    }

    nonisolated static func map(_ dto: SearchPaginationDTO) -> SearchPagination {
        return SearchPagination(
            nextCursor: dto.nextCursor,
            hasMore: dto.hasMore
        )
    }

    nonisolated static func map(_ dto: SuggestionsResponseDTO) -> [SearchSuggestion] {
        return dto.suggestions.map(map)
    }

    nonisolated static func map(_ dto: SearchSuggestionDTO) -> SearchSuggestion {
        return SearchSuggestion(
            text: dto.text,
            type: dto.type.domainType,
            metadata: dto.metadata
        )
    }

    nonisolated static func map(_ dto: RecentSearchesResponseDTO) -> [RecentSearch] {
        return dto.recent.map(map)
    }

    nonisolated static func map(_ dto: RecentSearchDTO) -> RecentSearch {
        return RecentSearch(
            query: dto.query,
            type: dto.type,
            timestamp: dto.timestamp
        )
    }

    nonisolated static func map(_ dto: TrendingResponseDTO) -> [TrendingHashtag] {
        return dto.trending.map(map)
    }

    nonisolated static func map(_ dto: TrendingHashtagDTO) -> TrendingHashtag {
        return TrendingHashtag(
            tag: dto.tag,
            postsCount: dto.postsCount,
            reelsCount: dto.reelsCount,
            trendScore: dto.trendScore
        )
    }

    nonisolated static func map(_ dto: AnalyticsResponseDTO) -> SearchAnalytics {
        return SearchAnalytics(
            periodDays: dto.periodDays,
            totalSearches: dto.totalSearches,
            uniqueUsers: dto.uniqueUsers,
            topQueries: dto.topQueries.map(map),
            searchesByType: dto.searchesByType
        )
    }

    nonisolated static func map(_ dto: SearchQueryStatDTO) -> SearchQueryStat {
        return SearchQueryStat(
            query: dto.query,
            count: dto.count,
            type: dto.type
        )
    }

    nonisolated static func map(_ dto: HashtagPageResponseDTO) -> HashtagPage {
        return HashtagPage(
            hashtag: map(dto.hashtag),
            topPosts: dto.topPosts.map(map),
            topReels: dto.topReels.map(map)
        )
    }

    nonisolated static func map(_ dto: HashtagInfoDTO) -> HashtagInfo {
        return HashtagInfo(
            id: dto.id,
            tag: dto.tag,
            postsCount: dto.postsCount,
            reelsCount: dto.reelsCount
        )
    }

    nonisolated static func map(_ dto: LocationPageResponseDTO) -> LocationPage {
        return LocationPage(
            location: map(dto.location),
            topPosts: dto.topPosts.map(map)
        )
    }

    nonisolated static func map(_ dto: LocationInfoDTO) -> LocationInfo {
        return LocationInfo(
            id: dto.id,
            name: dto.name,
            address: dto.address,
            lat: dto.lat,
            lng: dto.lng,
            category: dto.category,
            postsCount: dto.postsCount
        )
    }

    nonisolated static func map(_ dto: PostSummaryDTO) -> PostSummary {
        return PostSummary(
            id: dto.id,
            authorId: dto.authorId,
            caption: dto.caption,
            locationName: dto.locationName,
            likesCount: dto.likesCount,
            commentsCount: dto.commentsCount,
            createdAt: dto.createdAt,
            author: map(dto.author),
            mediaItems: dto.mediaItems?.map(map)
        )
    }

    nonisolated static func map(_ dto: ReelSummaryDTO) -> ReelSummary {
        return ReelSummary(
            id: dto.id,
            authorId: dto.authorId,
            caption: dto.caption,
            videoUrl: dto.videoUrl,
            thumbnailUrl: dto.thumbnailUrl,
            likesCount: dto.likesCount,
            commentsCount: dto.commentsCount,
            playsCount: dto.playsCount,
            createdAt: dto.createdAt,
            author: map(dto.author)
        )
    }

    nonisolated static func map(_ dto: UserSummaryDTO) -> UserSummary {
        return UserSummary(
            id: dto.id,
            username: dto.username,
            fullName: dto.fullName,
            avatarUrl: dto.avatarUrl,
            isVerified: dto.isVerified
        )
    }

    nonisolated static func map(_ dto: MediaItemSummaryDTO) -> MediaItemSummary {
        return MediaItemSummary(
            url: dto.url,
            type: dto.type,
            width: dto.width,
            height: dto.height
        )
    }
}

// MARK: - Domain Models

struct SearchResult: Equatable {
    let query: String
    let type: String
    let results: [SearchResultItem]
    let pagination: SearchPagination
    let tookMs: Int
}

struct SearchResultItem: Identifiable, Equatable {
    let id: String
    let type: SearchResultType
    let title: String
    let subtitle: String?
    let imageUrl: String?
    let metadata: [String: String]?
}

struct SearchPagination: Equatable {
    let nextCursor: String?
    let hasMore: Bool
}

struct SearchSuggestion: Equatable {
    let text: String
    let type: SearchType
    let metadata: [String: String]?
}

struct RecentSearch: Equatable {
    let query: String
    let type: String
    let timestamp: Date
}

struct TrendingHashtag: Equatable {
    let tag: String
    let postsCount: Int
    let reelsCount: Int
    let trendScore: Double
}

struct SearchAnalytics: Equatable {
    let periodDays: Int
    let totalSearches: Int
    let uniqueUsers: Int
    let topQueries: [SearchQueryStat]
    let searchesByType: [String: Int]
}

struct SearchQueryStat: Equatable {
    let query: String
    let count: Int
    let type: String
}

struct HashtagPage: Equatable {
    let hashtag: HashtagInfo
    let topPosts: [PostSummary]
    let topReels: [ReelSummary]
}

struct HashtagInfo: Equatable {
    let id: String
    let tag: String
    let postsCount: Int
    let reelsCount: Int
}

struct LocationPage: Equatable {
    let location: LocationInfo
    let topPosts: [PostSummary]
}

struct LocationInfo: Equatable {
    let id: String
    let name: String
    let address: String?
    let lat: Double
    let lng: Double
    let category: String?
    let postsCount: Int
}

struct PostSummary: Identifiable, Equatable {
    let id: String
    let authorId: String
    let caption: String?
    let locationName: String?
    let likesCount: Int
    let commentsCount: Int
    let createdAt: Date
    let author: UserSummary
    let mediaItems: [MediaItemSummary]?
}

struct ReelSummary: Identifiable, Equatable {
    let id: String
    let authorId: String
    let caption: String?
    let videoUrl: String
    let thumbnailUrl: String?
    let likesCount: Int
    let commentsCount: Int
    let playsCount: Int
    let createdAt: Date
    let author: UserSummary
}

struct UserSummary: Identifiable, Equatable {
    let id: String
    let username: String
    let fullName: String
    let avatarUrl: String?
    let isVerified: Bool
}

struct MediaItemSummary: Equatable {
    let url: String
    let type: String
    let width: Int?
    let height: Int?
}

// Note: SearchType is defined in SearchEndpoint.swift
// In a real project, this would be in a shared Enums file