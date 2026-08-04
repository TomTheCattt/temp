//
//  UploadEndpoint.swift
//  Instagram
//
//  Created by Kiro on 1/8/26.
//

import Foundation
import Alamofire

// MARK: - UploadEndpoint

enum UploadEndpoint: APIEndpoint {
    case image
    case video
    case avatar

    var path: String {
        switch self {
        case .image:    return "/v1/upload/image"
        case .video:    return "/v1/upload/video"
        case .avatar:   return "/v1/upload/avatar"
        }
    }

    var method: HTTPMethod { .post }
}

// MARK: - UploadImageResponseDTO

nonisolated struct UploadImageResponseDTO: Decodable, Sendable {
    let url: String
    let width: Int?
    let height: Int?
    let pendingUploadId: String?
}

// MARK: - UploadVideoResponseDTO

nonisolated struct UploadVideoResponseDTO: Decodable, Sendable {
    let url: String
    let thumbnailUrl: String?
    let duration: Double?
    let width: Int?
    let height: Int?
    let pendingUploadId: String?
}

// MARK: - UploadAvatarResponseDTO

nonisolated struct UploadAvatarResponseDTO: Decodable, Sendable {
    let url: String
}
