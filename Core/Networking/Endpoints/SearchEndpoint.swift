//
//  SearchEndpoint.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation
import Alamofire

// MARK: - SearchEndpoint

enum SearchEndpoint: APIEndpoint {
    // Unified search
    case search(
        query: String,
        type: SearchType?,
        limit: Int,
        cursor: String?
    )

    // Typeahead suggestions
    case suggestions(query: String, limit: Int)

    // Recent searches
    case recentSearches(limit: Int)

    // Clear search history
    case clearHistory

    // Trending hashtags
    case trending(limit: Int, timeWindowHours: Int)

    // Search analytics (admin)
    case analytics(days: Int)

    // Hashtag page
    case hashtag(tag: String)

    // Location page
    case location(locationId: String)

    var path: String {
        switch self {
        case .search:
            return "/v1/search"
        case .suggestions:
            return "/v1/search/suggestions"
        case .recentSearches:
            return "/v1/search/recent"
        case .clearHistory:
            return "/v1/search/recent"
        case .trending:
            return "/v1/search/trending"
        case .analytics:
            return "/v1/search/analytics"
        case .hashtag(let tag):
            return "/v1/hashtags/\(tag)"
        case .location(let locationId):
            return "/v1/locations/\(locationId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .search, .suggestions, .recentSearches, .trending, .analytics, .hashtag, .location:
            return .get
        case .clearHistory:
            return .delete
        }
    }

    var parameters: Parameters? {
        switch self {
        case .search(let query, let type, let limit, let cursor):
            var params: Parameters = ["q": query, "limit": limit]
            if let type { params["type"] = type.rawValue }
            if let cursor { params["cursor"] = cursor }
            return params

        case .suggestions(let query, let limit):
            return ["q": query, "limit": limit]

        case .recentSearches(let limit):
            return ["limit": limit]

        case .clearHistory:
            return nil

        case .trending(let limit, let timeWindowHours):
            return ["limit": limit, "timeWindowHours": timeWindowHours]

        case .analytics(let days):
            return ["days": days]

        case .hashtag, .location:
            return nil
        }
    }
}

// Note: SearchType, SearchResultType are defined in Shared/Enums.swift
// Note: Domain models (SearchResult, SearchSuggestion, TrendingHashtag, etc.) are defined in Data/Mappers/SearchMapper.swift
// Note: DTOs are defined in Data/DTOs/SearchDTO.swift