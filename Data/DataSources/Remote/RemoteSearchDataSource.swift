//
//  RemoteSearchDataSource.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation
import Combine

// MARK: - RemoteSearchDataSource Protocol

protocol RemoteSearchDataSourceProtocol {
    func search(query: String, type: SearchType?, limit: Int, cursor: String?) -> AnyPublisher<SearchResponseDTO, Error>
    func getSuggestions(query: String, limit: Int) -> AnyPublisher<SuggestionsResponseDTO, Error>
    func getRecentSearches(limit: Int) -> AnyPublisher<RecentSearchesResponseDTO, Error>
    func clearSearchHistory() -> AnyPublisher<Void, Error>
    func getTrending(limit: Int, timeWindowHours: Int) -> AnyPublisher<TrendingResponseDTO, Error>
    func getAnalytics(days: Int) -> AnyPublisher<AnalyticsResponseDTO, Error>
    func getHashtagPage(tag: String) -> AnyPublisher<HashtagPageResponseDTO, Error>
    func getLocationPage(locationId: String) -> AnyPublisher<LocationPageResponseDTO, Error>
}

// MARK: - RemoteSearchDataSource Implementation

final class RemoteSearchDataSource: RemoteSearchDataSourceProtocol {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    func search(query: String, type: SearchType?, limit: Int, cursor: String?) -> AnyPublisher<SearchResponseDTO, Error> {
        let endpoint = SearchEndpoint.search(
            query: query,
            type: type,
            limit: limit,
            cursor: cursor
        )

        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func getSuggestions(query: String, limit: Int) -> AnyPublisher<SuggestionsResponseDTO, Error> {
        let endpoint = SearchEndpoint.suggestions(query: query, limit: limit)

        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func getRecentSearches(limit: Int) -> AnyPublisher<RecentSearchesResponseDTO, Error> {
        let endpoint = SearchEndpoint.recentSearches(limit: limit)

        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func clearSearchHistory() -> AnyPublisher<Void, Error> {
        let endpoint = SearchEndpoint.clearHistory

        return networkService.requestVoidPublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func getTrending(limit: Int, timeWindowHours: Int) -> AnyPublisher<TrendingResponseDTO, Error> {
        let endpoint = SearchEndpoint.trending(limit: limit, timeWindowHours: timeWindowHours)

        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func getAnalytics(days: Int) -> AnyPublisher<AnalyticsResponseDTO, Error> {
        let endpoint = SearchEndpoint.analytics(days: days)

        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func getHashtagPage(tag: String) -> AnyPublisher<HashtagPageResponseDTO, Error> {
        let endpoint = SearchEndpoint.hashtag(tag: tag)

        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func getLocationPage(locationId: String) -> AnyPublisher<LocationPageResponseDTO, Error> {
        let endpoint = SearchEndpoint.location(locationId: locationId)

        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}