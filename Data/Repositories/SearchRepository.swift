//
//  SearchRepository.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation
import Combine

// MARK: - SearchRepository Protocol

protocol SearchRepositoryProtocol {
    func search(query: String, type: SearchType?, limit: Int, cursor: String?) -> AnyPublisher<SearchResult, Error>
    func getSuggestions(query: String, limit: Int) -> AnyPublisher<[SearchSuggestion], Error>
    func getRecentSearches(limit: Int) -> AnyPublisher<[RecentSearch], Error>
    func clearSearchHistory() -> AnyPublisher<Void, Error>
    func getTrending(limit: Int, timeWindowHours: Int) -> AnyPublisher<[TrendingHashtag], Error>
    func getAnalytics(days: Int) -> AnyPublisher<SearchAnalytics, Error>
    func getHashtagPage(tag: String) -> AnyPublisher<HashtagPage, Error>
    func getLocationPage(locationId: String) -> AnyPublisher<LocationPage, Error>
}

// MARK: - SearchRepository Implementation

final class SearchRepository: SearchRepositoryProtocol {
    private let dataSource: RemoteSearchDataSourceProtocol
    private let mapper: SearchMapper.Type = SearchMapper.self

    init(dataSource: RemoteSearchDataSourceProtocol) {
        self.dataSource = dataSource
    }

    func search(query: String, type: SearchType?, limit: Int, cursor: String?) -> AnyPublisher<SearchResult, Error> {
        return dataSource.search(query: query, type: type, limit: limit, cursor: cursor)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    func getSuggestions(query: String, limit: Int) -> AnyPublisher<[SearchSuggestion], Error> {
        return dataSource.getSuggestions(query: query, limit: limit)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    func getRecentSearches(limit: Int) -> AnyPublisher<[RecentSearch], Error> {
        return dataSource.getRecentSearches(limit: limit)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    func clearSearchHistory() -> AnyPublisher<Void, Error> {
        return dataSource.clearSearchHistory()
            .eraseToAnyPublisher()
    }

    func getTrending(limit: Int, timeWindowHours: Int) -> AnyPublisher<[TrendingHashtag], Error> {
        return dataSource.getTrending(limit: limit, timeWindowHours: timeWindowHours)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    func getAnalytics(days: Int) -> AnyPublisher<SearchAnalytics, Error> {
        return dataSource.getAnalytics(days: days)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    func getHashtagPage(tag: String) -> AnyPublisher<HashtagPage, Error> {
        return dataSource.getHashtagPage(tag: tag)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    func getLocationPage(locationId: String) -> AnyPublisher<LocationPage, Error> {
        return dataSource.getLocationPage(locationId: locationId)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }
}