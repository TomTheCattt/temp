//
//  APIErrors.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 20/7/26.
//

import Alamofire
import Foundation

// MARK: - APIError

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case forbidden
    case notFound
    case serverError(String)
    case networkError(Error)
    case decodingError(Error)
    case timeout
    case noInternetConnection
    case cannotConnectToHost
    case unknown(Int?)

    /// Technical description — used for logging/debugging only. NEVER show to users.
    var errorDescription: String? {
        switch self {
        case .invalidURL:               return "Invalid URL."
        case .unauthorized:             return "Unauthorized. Please log in again."
        case .forbidden:                return "Access forbidden."
        case .notFound:                 return "Resource not found."
        case .serverError(let msg):     return "Server error: \(msg)"
        case .networkError(let err):    return "Network error: \(err.localizedDescription)"
        case .decodingError(let err):   return "Decoding error: \(err.localizedDescription)"
        case .timeout:                  return "Request timed out."
        case .noInternetConnection:     return "No internet connection."
        case .cannotConnectToHost:      return "Cannot connect to server."
        case .unknown(let code):        return "Unexpected error (code: \(code ?? -1))."
        }
    }

    /// User-facing, friendly message — safe to display in UI (toast, error view, alert).
    /// Never leaks technical details (status codes, decoding internals, etc.).
    var userMessage: String {
        switch self {
        case .noInternetConnection:     return L10n.Error.offline
        case .timeout:                  return L10n.Error.timeout
        case .cannotConnectToHost:      return L10n.Error.cannotReachServer
        case .unauthorized:             return L10n.Error.sessionExpired
        case .forbidden:                return L10n.Error.forbidden
        case .notFound:                 return L10n.Error.notFound
        case .serverError:              return L10n.Error.server
        // Technical failures are hidden behind a generic, friendly message.
        case .invalidURL, .networkError, .decodingError, .unknown:
            return L10n.Error.generic
        }
    }
}

// MARK: - Error + User Message

extension Error {

    /// A friendly, user-facing message for any error.
    /// - Maps `APIError` to its curated `userMessage`.
    /// - Falls back to a generic friendly message for unknown errors,
    ///   so raw `localizedDescription` is never shown to users.
    var userMessage: String {
        if let apiError = self as? APIError {
            return apiError.userMessage
        }
        return L10n.Error.generic
    }

    static func from(_ error: AFError, response: HTTPURLResponse?) -> APIError {
        if let code = response?.statusCode {
            switch code {
            case 401: return .unauthorized
            case 403: return .forbidden
            case 404: return .notFound
            case 500...599: return .serverError("HTTP \(code)")
            default: break
            }
        }

        if error.isSessionTaskError {
            let nsError = error.underlyingError as NSError?
            if nsError?.code == NSURLErrorNotConnectedToInternet {
                return .noInternetConnection
            }
            if nsError?.code == NSURLErrorTimedOut {
                return .timeout
            }
            if nsError?.code == NSURLErrorCannotConnectToHost || nsError?.code == NSURLErrorCannotFindHost {
                return .cannotConnectToHost
            }
        }

        if error.isResponseSerializationError {
            return .decodingError(error)
        }

        return .unknown(response?.statusCode)
    }
}

