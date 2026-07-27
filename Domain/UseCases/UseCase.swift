//
//  UseCase.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - UseCase Base Protocol

/// Base protocol for all use cases in the Domain layer.
/// Each UseCase encapsulates a single business action.
///
/// Usage:
/// ```swift
/// final class LoginUseCase: UseCase {
///     typealias Input = LoginInput
///     typealias Output = AuthSession
///     func execute(_ input: LoginInput) async throws -> AuthSession { ... }
/// }
/// ```
protocol UseCase {
    associatedtype Input: Sendable
    associatedtype Output: Sendable

    func execute(_ input: Input) async throws -> Output
}

// MARK: - NoInput

/// Use when a UseCase requires no input parameters.
struct NoInput: Sendable {}

// MARK: - PaginationInput

/// Common pagination input reusable across use cases.
struct PaginationInput: Sendable {
    let page: Int
    let perPage: Int

    init(page: Int = 1, perPage: Int = 20) {
        self.page = page
        self.perPage = perPage
    }
}
