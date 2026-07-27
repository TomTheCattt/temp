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

