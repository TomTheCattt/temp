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
    case refresh(refreshToken: String)
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

    var headers: HTTPHeaders? {
        switch self {
        case .refresh(let refreshToken):
            return ["Authorization": "Bearer \(refreshToken)"]
        default:
            return nil
        }
    }

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
        case .logout, .logoutAllDevices, .me:
            return nil
        case .refresh:
            return nil // refreshToken sent in Authorization header
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
    case updateProfileName(name: String)  // PUT /v1/user/profile (iOS alias - accepts { name } only)
    case settings                   // GET /v1/user/settings
    case updateSettings(language: String?, biometricEnabled: Bool?, pushEnabled: Bool?, darkMode: Bool?)  // PUT /v1/user/settings
    case closeFriends               // GET /v1/user/close-friends (iOS alias for /v1/users/me/close-friends)
    case addCloseFriend(userId: String)  // POST /v1/user/close-friends/{userId} (iOS alias)
    case removeCloseFriend(userId: String)  // DELETE /v1/user/close-friends/{userId} (iOS alias)
    case blockedUsers(page: Int, perPage: Int)  // GET /v1/user/blocked (iOS alias for /v1/users/me/blocked)
    case addDeviceToken(token: String, platform: String)  // POST /v1/user/me/device-token
    case deleteDeviceToken(token: String)                 // DELETE /v1/user/me/device-token

    // Full profile update (use /v1/users/me - canonical endpoint)
    case updateFullProfile(fullName: String?, bio: String?, website: String?, isPrivate: Bool?)  // PUT /v1/users/me

    // Public/Other user endpoints (use /v1/user/)
    case publicProfile(userId: String)  // GET /v1/user/{userId}
    case follow(userId: String)         // POST /v1/user/{userId}/follow
    case unfollow(userId: String)       // DELETE /v1/user/{userId}/follow
    case block(userId: String)          // POST /v1/user/{userId}/block
    case unblock(userId: String)        // DELETE /v1/user/{userId}/block
    case followers(userId: String, page: Int, perPage: Int)  // GET /v1/user/{userId}/followers
    case following(userId: String, page: Int, perPage: Int)  // GET /v1/user/{userId}/following
    case search(query: String, page: Int, perPage: Int)      // GET /v1/user/search
    case suggested(page: Int, perPage: Int)                  // GET /v1/user/suggested

    var path: String {
        switch self {
        // Current user endpoints (/v1/user/)
        case .profile: return "/v1/user/profile"
        case .updateProfileName: return "/v1/user/profile"
        case .settings, .updateSettings: return "/v1/user/settings"
        case .closeFriends: return "/v1/user/me/close-friends"
        case .addCloseFriend(let userId): return "/v1/user/me/close-friends/\(userId)"
        case .removeCloseFriend(let userId): return "/v1/user/me/close-friends/\(userId)"
        case .blockedUsers: return "/v1/user/me/blocked"
        case .addDeviceToken: return "/v1/user/me/device-token"
        case .deleteDeviceToken: return "/v1/user/me/device-token"

        // Full profile update (canonical endpoint)
        case .updateFullProfile: return "/v1/user/me"

        // Public/Other user endpoints (/v1/user/)
        case .publicProfile(let userId): return "/v1/user/\(userId)"
        case .follow(let userId): return "/v1/user/\(userId)/follow"
        case .unfollow(let userId): return "/v1/user/\(userId)/follow"
        case .block(let userId): return "/v1/user/\(userId)/block"
        case .unblock(let userId): return "/v1/user/\(userId)/block"
        case .followers(let userId, _, _): return "/v1/user/\(userId)/followers"
        case .following(let userId, _, _): return "/v1/user/\(userId)/following"
        case .search: return "/v1/user/search"
        case .suggested: return "/v1/user/suggested"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .profile, .settings, .followers, .following, .search, .suggested, .closeFriends, .blockedUsers, .publicProfile:
            return .get
        case .updateProfileName, .updateSettings, .updateFullProfile:
            return .put
        case .follow, .block, .addCloseFriend, .addDeviceToken:
            return .post
        case .unfollow, .unblock, .removeCloseFriend, .deleteDeviceToken:
            return .delete
        }
    }

    var parameters: Parameters? {
        switch self {
        case .profile, .settings, .follow, .unfollow, .block, .unblock, .addCloseFriend, .removeCloseFriend, .closeFriends, .publicProfile:
            return nil
        case .updateProfileName(let name):
            return ["name": name]
        case .updateSettings(let language, let biometricEnabled, let pushEnabled, let darkMode):
            var params: Parameters = [:]
            if let language { params["language"] = language }
            if let biometricEnabled { params["biometricEnabled"] = biometricEnabled }
            if let pushEnabled { params["pushEnabled"] = pushEnabled }
            if let darkMode { params["darkMode"] = darkMode }
            return params
        case .updateFullProfile(let fullName, let bio, let website, let isPrivate):
            var params: Parameters = [:]
            if let fullName { params["fullName"] = fullName }
            if let bio { params["bio"] = bio }
            if let website { params["website"] = website }
            if let isPrivate { params["isPrivate"] = isPrivate }
            return params
        case .followers(_, let page, let perPage), .following(_, let page, let perPage), .blockedUsers(let page, let perPage):
            return ["page": page, "perPage": perPage]
        case .search(let query, let page, let perPage):
            return ["q": query, "page": page, "perPage": perPage]
        case .suggested(let page, let perPage):
            return ["page": page, "perPage": perPage]
        case .addDeviceToken(let token, let platform):
            return ["token": token, "platform": platform]
        case .deleteDeviceToken(let token):
            return ["token": token]
        }
    }
}

// MARK: - Upload Endpoints

enum UploadEndpoint: APIEndpoint {
    // Presigned URL flow (for large files - direct to S3)
    case presign(contentType: String, maxSize: Int?, prefix: String?)      // POST /v1/upload/presign
    case confirm(pendingUploadId: String, targetType: String, targetId: String?)  // POST /v1/upload/confirm

    // Direct multipart uploads (for smaller files)
    case uploadImage(data: Data, filename: String)   // POST /v1/upload/image
    case uploadVideo(data: Data, filename: String)   // POST /v1/upload/video
    case uploadAvatar(data: Data, filename: String)  // POST /v1/upload/avatar

    // Pending upload management
    case getPendingStatus(pendingUploadId: String)   // GET /v1/upload/pending/:id
    case deletePending(pendingUploadId: String)      // DELETE /v1/upload/pending/:id

    var path: String {
        switch self {
        case .presign: return "/v1/upload/presign"
        case .confirm: return "/v1/upload/confirm"
        case .uploadImage: return "/v1/upload/image"
        case .uploadVideo: return "/v1/upload/video"
        case .uploadAvatar: return "/v1/upload/avatar"
        case .getPendingStatus(let id): return "/v1/upload/pending/\(id)"
        case .deletePending(let id): return "/v1/upload/pending/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .presign, .confirm, .uploadImage, .uploadVideo, .uploadAvatar:
            return .post
        case .getPendingStatus:
            return .get
        case .deletePending:
            return .delete
        }
    }

    var parameters: Parameters? {
        switch self {
        case .presign(let contentType, let maxSize, let prefix):
            var params: Parameters = ["contentType": contentType]
            if let maxSize { params["maxSize"] = maxSize }
            if let prefix { params["prefix"] = prefix }
            return params
        case .confirm(let pendingUploadId, let targetType, let targetId):
            var params: Parameters = ["pendingUploadId": pendingUploadId, "targetType": targetType]
            if let targetId { params["targetId"] = targetId }
            return params
        case .getPendingStatus, .deletePending:
            return nil
        case .uploadImage, .uploadVideo, .uploadAvatar:
            // Multipart uploads handled separately, not via parameters
            return nil
        }
    }

    var encoding: ParameterEncoding {
        switch self {
        case .uploadImage, .uploadVideo, .uploadAvatar:
            return MultipartEncoding()  // Custom encoding for multipart
        default:
            return JSONEncoding.default
        }
    }
}

// MARK: - Multipart Encoding Helper

/// Custom encoding for multipart/form-data uploads
private struct MultipartEncoding: ParameterEncoding {
    func encode(_ urlRequest: any URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        // The actual multipart body is built in NetworkService.requestMultipart
        // This is a placeholder - the real encoding happens in the network service
        return try urlRequest.asURLRequest()
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