//
//  APIEndPoint.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 26/7/26.
//

import Foundation
import Alamofire

// MARK: - HTTP Method

typealias HTTPMethod = Alamofire.HTTPMethod

// MARK: - APIEndpoint Protocol

protocol APIEndpoint {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: HTTPHeaders? { get }
    var parameters: Parameters? { get }
    var encoding: ParameterEncoding { get }
    func asURLRequest() throws -> URLRequest
}

extension APIEndpoint {
    var baseURL: URL {
        guard let url = URL(string: AppConfig.shared.baseURL) else {
            fatalError("[APIEndpoint] Invalid baseURL: '\(AppConfig.shared.baseURL)'. Check xcconfig / build settings.")
        }
        return url
    }
    var headers: HTTPHeaders? { nil }
    var parameters: Parameters? { nil }
    var encoding: ParameterEncoding {
        method == .get ? URLEncoding.default : JSONEncoding.default
    }

    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.method = method
        request.timeoutInterval = AppConfig.shared.timeoutInterval

        if let headers = headers {
            headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.name) }
        }

        if let parameters = parameters {
            return try encoding.encode(request, with: parameters)
        }
        return request
    }
}

// MARK: - APIEnvelope (Server response wrapper)

nonisolated struct APIEnvelope<T: Decodable & Sendable>: Decodable, Sendable {
    let success: Bool?
    let data: T?
    let error: String?
    let message: String?
}

// MARK: - Auth Endpoints (Better Auth - Email/Password)

enum AuthEndpoint: APIEndpoint {
    case register(email: String, password: String, username: String, fullName: String, phone: String?)
    case login(email: String, password: String)
    case logout
    case logoutAllDevices
    case me
    case refresh
    case forgotPassword(email: String)
    case verifyEmail(token: String)
    case resendVerification(email: String)
    case changePassword(currentPassword: String, newPassword: String)

    var path: String {
        switch self {
        case .register: return "/v1/auth/register"
        case .login: return "/v1/auth/login"
        case .logout: return "/v1/auth/logout"
        case .logoutAllDevices: return "/v1/auth/logout-all-devices"
        case .me: return "/v1/auth/me"
        case .refresh: return "/v1/auth/refresh"
        case .forgotPassword: return "/v1/auth/forgot-password"
        case .verifyEmail: return "/v1/auth/verify-email"
        case .resendVerification: return "/v1/auth/resend-verification"
        case .changePassword: return "/v1/auth/change-password"
        }
    }

    var method: HTTPMethod { .post }

    var parameters: Parameters? {
        switch self {
        case .register(let email, let password, let username, let fullName, let phone):
            var params: Parameters = [
                "email": email,
                "password": password,
                "username": username,
                "fullName": fullName
            ]
            if let phone { params["phone"] = phone }
            return params
        case .login(let email, let password):
            return ["email": email, "password": password]
        case .logout, .logoutAllDevices, .me, .refresh:
            return nil
        case .forgotPassword(let email):
            return ["email": email]
        case .verifyEmail(let token):
            return ["token": token]
        case .resendVerification(let email):
            return ["email": email]
        case .changePassword(let currentPassword, let newPassword):
            return ["currentPassword": currentPassword, "newPassword": newPassword]
        }
    }
}

// MARK: - User Endpoints

enum UserEndpoint: APIEndpoint {
    // Current user endpoints (use /v1/user/)
    case profile                    // GET /v1/user/profile (iOS alias for /v1/user/me)
    case updateProfile(fullName: String?, username: String?, bio: String?, website: String?, phone: String?, avatarUrl: String?)  // PUT /v1/user/profile
    case settings                   // GET /v1/user/settings
    case updateSettings(language: String?, biometricEnabled: Bool?, pushEnabled: Bool?, darkMode: Bool?)  // PUT /v1/user/settings
    case closeFriends               // GET /v1/user/close-friends (iOS alias for /v1/users/me/close-friends)
    case addCloseFriend(userId: String)  // POST /v1/user/close-friends/{userId} (iOS alias)
    case removeCloseFriend(userId: String)  // DELETE /v1/user/close-friends/{userId} (iOS alias)
    case blockedUsers(page: Int, perPage: Int)  // GET /v1/user/blocked (iOS alias for /v1/users/me/blocked)
    case deviceTokens               // GET /v1/user/device-tokens (iOS alias for /v1/users/me/device-token)
    case addDeviceToken(token: String, platform: String)  // POST /v1/user/device-tokens (iOS alias)

    // Public/Other user endpoints (use /v1/users/)
    case publicProfile(userId: String)  // GET /v1/users/{userId}
    case follow(userId: String)         // POST /v1/users/{userId}/follow
    case unfollow(userId: String)       // DELETE /v1/users/{userId}/follow
    case block(userId: String)          // POST /v1/users/{userId}/block
    case unblock(userId: String)        // DELETE /v1/users/{userId}/block
    case followers(userId: String, page: Int, perPage: Int)  // GET /v1/users/{userId}/followers
    case following(userId: String, page: Int, perPage: Int)  // GET /v1/users/{userId}/following
    case search(query: String, page: Int, perPage: Int)      // GET /v1/users/search
    case suggested(page: Int, perPage: Int)                  // GET /v1/users/suggested

    var path: String {
        switch self {
        // Current user endpoints (/v1/user/)
        case .profile, .updateProfile: return "/v1/user/profile"
        case .settings, .updateSettings: return "/v1/user/settings"
        case .closeFriends: return "/v1/user/close-friends"
        case .addCloseFriend(let userId): return "/v1/user/close-friends/\(userId)"
        case .removeCloseFriend(let userId): return "/v1/user/close-friends/\(userId)"
        case .blockedUsers: return "/v1/user/blocked"
        case .deviceTokens: return "/v1/user/device-tokens"
        case .addDeviceToken: return "/v1/user/device-tokens"

        // Public/Other user endpoints (/v1/users/)
        case .publicProfile(let userId): return "/v1/users/\(userId)"
        case .follow(let userId): return "/v1/users/\(userId)/follow"
        case .unfollow(let userId): return "/v1/users/\(userId)/follow"
        case .block(let userId): return "/v1/users/\(userId)/block"
        case .unblock(let userId): return "/v1/users/\(userId)/block"
        case .followers(let userId, _, _): return "/v1/users/\(userId)/followers"
        case .following(let userId, _, _): return "/v1/users/\(userId)/following"
        case .search: return "/v1/users/search"
        case .suggested: return "/v1/users/suggested"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .profile, .settings, .followers, .following, .search, .suggested, .closeFriends, .blockedUsers, .deviceTokens, .publicProfile:
            return .get
        case .updateProfile, .updateSettings:
            return .put
        case .follow, .block, .addCloseFriend, .addDeviceToken:
            return .post
        case .unfollow, .unblock, .removeCloseFriend:
            return .delete
        }
    }

    var parameters: Parameters? {
        switch self {
        case .profile, .settings, .follow, .unfollow, .block, .unblock, .addCloseFriend, .removeCloseFriend, .closeFriends, .deviceTokens, .publicProfile:
            return nil
        case .updateProfile(let fullName, let username, let bio, let website, let phone, let avatarUrl):
            var params: Parameters = [:]
            if let fullName { params["fullName"] = fullName }
            if let username { params["username"] = username }
            if let bio { params["bio"] = bio }
            if let website { params["website"] = website }
            if let phone { params["phone"] = phone }
            if let avatarUrl { params["avatarUrl"] = avatarUrl }
            return params
        case .updateSettings(let language, let biometricEnabled, let pushEnabled, let darkMode):
            var params: Parameters = [:]
            if let language { params["language"] = language }
            if let biometricEnabled { params["biometricEnabled"] = biometricEnabled }
            if let pushEnabled { params["pushEnabled"] = pushEnabled }
            if let darkMode { params["darkMode"] = darkMode }
            return params
        case .followers(_, let page, let perPage), .following(_, let page, let perPage), .blockedUsers(let page, let perPage):
            return ["page": page, "perPage": perPage]
        case .search(let query, let page, let perPage):
            return ["q": query, "page": page, "perPage": perPage]
        case .suggested(let page, let perPage):
            return ["page": page, "perPage": perPage]
        case .addDeviceToken(let token, let platform):
            return ["token": token, "platform": platform]
        }
    }
}

// MARK: - Upload Endpoints

enum UploadEndpoint: APIEndpoint {
    case presignedUrl(filename: String, contentType: String, folder: String?)
    case confirmUpload(uploadId: String)

    var path: String {
        switch self {
        case .presignedUrl: return "/v1/upload/presigned-url"
        case .confirmUpload(let uploadId): return "/v1/upload/\(uploadId)/confirm"
        }
    }

    var method: HTTPMethod { .post }

    var parameters: Parameters? {
        switch self {
        case .presignedUrl(let filename, let contentType, let folder):
            var params: Parameters = ["filename": filename, "contentType": contentType]
            if let folder { params["folder"] = folder }
            return params
        case .confirmUpload:
            return nil
        }
    }
}

// MARK: - WebSocket Endpoint

enum WebSocketEndpoint: APIEndpoint {
    case connect(token: String)

    var path: String { "/ws" }

    var method: HTTPMethod { .get }

    var parameters: Parameters? {
        switch self {
        case .connect(let token):
            return ["token": token]
        }
    }
}