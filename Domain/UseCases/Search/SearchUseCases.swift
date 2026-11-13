//
//  SearchUseCases.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation
import Combine

// MARK: - Search Use Cases

// Search Use Case
struct SearchUseCase: SearchUseCaseProtocol {
    private let repository: SearchRepositoryProtocol

    init(repository: SearchRepositoryProtocol) {
        self.repository = repository
    }

    func execute(query: String, type: SearchType? = nil, limit: Int = 20, cursor: String? = nil) -> AnyPublisher<SearchResult, Error> {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Fail(error: SearchError.emptyQuery)
                .eraseToAnyPublisher()
        }

        return repository.search(query: query, type: type, limit: limit, cursor: cursor)
    }
}

// Get Search Suggestions Use Case
struct GetSearchSuggestionsUseCase: GetSearchSuggestionsUseCaseProtocol {
    private let repository: SearchRepositoryProtocol

    init(repository: SearchRepositoryProtocol) {
        self.repository = repository
    }

    func execute(query: String, limit: Int = 10) -> AnyPublisher<[SearchSuggestion], Error> {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        return repository.getSuggestions(query: query, limit: limit)
    }
}

// Get Recent Searches Use Case
struct GetRecentSearchesUseCase: GetRecentSearchesUseCaseProtocol {
    private let repository: SearchRepositoryProtocol

    init(repository: SearchRepositoryProtocol) {
        self.repository = repository
    }

    func execute(limit: Int = 10) -> AnyPublisher<[RecentSearch], Error> {
        return repository.getRecentSearches(limit: limit)
    }
}

// Clear Search History Use Case
struct ClearSearchHistoryUseCase: ClearSearchHistoryUseCaseProtocol {
    private let repository: SearchRepositoryProtocol

    init(repository: SearchRepositoryProtocol) {
        self.repository = repository
    }

    func execute() -> AnyPublisher<Void, Error> {
        return repository.clearSearchHistory()
    }
}

// Get Trending Hashtags Use Case
struct GetTrendingHashtagsUseCase: GetTrendingHashtagsUseCaseProtocol {
    private let repository: SearchRepositoryProtocol

    init(repository: SearchRepositoryProtocol) {
        self.repository = repository
    }

    func execute(limit: Int = 20, timeWindowHours: Int = 24) -> AnyPublisher<[TrendingHashtag], Error> {
        return repository.getTrending(limit: limit, timeWindowHours: timeWindowHours)
    }
}

// Get Search Analytics Use Case (Admin)
struct GetSearchAnalyticsUseCase: GetSearchAnalyticsUseCaseProtocol {
    private let repository: SearchRepositoryProtocol

    init(repository: SearchRepositoryProtocol) {
        self.repository = repository
    }

    func execute(days: Int = 7) -> AnyPublisher<SearchAnalytics, Error> {
        return repository.getAnalytics(days: days)
    }
}

// Get Hashtag Page Use Case
struct GetHashtagPageUseCase: GetHashtagPageUseCaseProtocol {
    private let repository: SearchRepositoryProtocol

    init(repository: SearchRepositoryProtocol) {
        self.repository = repository
    }

    func execute(tag: String) -> AnyPublisher<HashtagPage, Error> {
        let normalizedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().replacingOccurrences(of: "^#", with: "", options: .regularExpression)
        guard !normalizedTag.isEmpty else {
            return Fail(error: SearchError.emptyTag)
                .eraseToAnyPublisher()
        }
        return repository.getHashtagPage(tag: normalizedTag)
    }
}

// Get Location Page Use Case
struct GetLocationPageUseCase: GetLocationPageUseCaseProtocol {
    private let repository: SearchRepositoryProtocol

    init(repository: SearchRepositoryProtocol) {
        self.repository = repository
    }

    func execute(locationId: String) -> AnyPublisher<LocationPage, Error> {
        return repository.getLocationPage(locationId: locationId)
    }
}

// MARK: - Search Errors

enum SearchError: Error, LocalizedError {
    case emptyQuery
    case emptyTag
    case invalidLocationId
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .emptyQuery:
            return "Search query cannot be empty"
        case .emptyTag:
            return "Hashtag cannot be empty"
        case .invalidLocationId:
            return "Invalid location ID"
        case .unauthorized:
            return "Not authorized to perform this action"
        }
    }
}

// Note: SearchError is defined here
// Note: SearchRepositoryProtocol is defined in Data/Repositories/SearchRepository.swift
// Note: Domain models (SearchResult, SearchSuggestion, RecentSearch, TrendingHashtag, SearchAnalytics, HashtagPage, LocationPage, PostSummary, ReelSummary, UserSummary, MediaItemSummary) are defined in Data/Mappers/SearchMapper.swift
// Note: SearchType, SearchResultType are defined in Shared/Enums.swift