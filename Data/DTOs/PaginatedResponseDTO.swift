//
//  PaginatedResponseDTO.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - PaginatedResponseDTO

/// Generic paginated response wrapper from API.
nonisolated struct PaginatedResponseDTO<T: Decodable & Sendable>: Decodable, Sendable {
    let items: [T]
    let page: Int
    let perPage: Int
    let total: Int
    let hasMore: Bool
}
