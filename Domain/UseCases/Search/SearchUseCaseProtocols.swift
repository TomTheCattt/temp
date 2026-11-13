//
//  SearchUseCaseProtocols.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation
import Combine

// MARK: - Search Use Case Protocols

protocol SearchUseCaseProtocol {
    func execute(query: String, type: SearchType?, limit: Int, cursor: String?) -> AnyPublisher<SearchResult, Error>
}

protocol GetSearchSuggestionsUseCaseProtocol {
    func execute(query: String, limit: Int) -> AnyPublisher<[SearchSuggestion], Error>
}

protocol GetRecentSearchesUseCaseProtocol {
    func execute(limit: Int) -> AnyPublisher<[RecentSearch], Error>
}

protocol ClearSearchHistoryUseCaseProtocol {
    func execute() -> AnyPublisher<Void, Error>
}

protocol GetTrendingHashtagsUseCaseProtocol {
    func execute(limit: Int, timeWindowHours: Int) -> AnyPublisher<[TrendingHashtag], Error>
}

protocol GetSearchAnalyticsUseCaseProtocol {
    func execute(days: Int) -> AnyPublisher<SearchAnalytics, Error>
}

protocol GetHashtagPageUseCaseProtocol {
    func execute(tag: String) -> AnyPublisher<HashtagPage, Error>
}

protocol GetLocationPageUseCaseProtocol {
    func execute(locationId: String) -> AnyPublisher<LocationPage, Error>
}