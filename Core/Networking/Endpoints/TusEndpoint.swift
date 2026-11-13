//
//  TusEndpoint.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation
import Alamofire

// MARK: - TusEndpoint (TUS Resumable Upload Protocol)

enum TusEndpoint: APIEndpoint {
    // Create a new upload (returns upload URL with upload ID)
    case createUpload(
        fileSize: Int64,
        metadata: TusMetadata,
        uploadLength: Int64?
    )

    // Get upload info (HEAD request equivalent)
    case getUploadInfo(uploadId: String)

    // Upload chunk (PATCH request to upload URL)
    case uploadChunk(
        uploadId: String,
        data: Data,
        offset: Int64
    )

    // Complete upload (POST to /confirm or final PATCH)
    case completeUpload(
        uploadId: String,
        targetType: String,
        targetId: String?
    )

    // Delete/abort upload
    case deleteUpload(uploadId: String)

    // Get upload options (OPTIONS request)
    case options(uploadId: String?)

    var path: String {
        switch self {
        case .createUpload:
            return "/v1/upload/tus"
        case .getUploadInfo(let uploadId),
             .uploadChunk(let uploadId, _, _),
             .completeUpload(let uploadId, _, _),
             .deleteUpload(let uploadId):
            return "/v1/upload/tus/\(uploadId)"
        case .options(let uploadId):
            if let uploadId {
                return "/v1/upload/tus/\(uploadId)"
            }
            return "/v1/upload/tus"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .createUpload:
            return .post
        case .getUploadInfo:
            return .head
        case .uploadChunk:
            return .patch
        case .completeUpload:
            return .post // or .put depending on implementation
        case .deleteUpload:
            return .delete
        case .options:
            return .options
        }
    }

    var headers: HTTPHeaders? {
        var headers: HTTPHeaders = [:]

        switch self {
        case .createUpload(_, let metadata, let uploadLength):
            headers["Upload-Metadata"] = metadata.encoded
            if let uploadLength {
                headers["Upload-Length"] = String(uploadLength)
            } else {
                headers["Upload-Deferred-Length"] = "1"
            }
            headers["Tus-Resumable"] = "1.0.0"

        case .getUploadInfo:
            headers["Tus-Resumable"] = "1.0.0"

        case .uploadChunk(_, _, let offset):
            headers["Upload-Offset"] = String(offset)
            headers["Tus-Resumable"] = "1.0.0"
            headers["Content-Type"] = "application/offset+octet-stream"

        case .completeUpload:
            headers["Tus-Resumable"] = "1.0.0"

        case .deleteUpload:
            headers["Tus-Resumable"] = "1.0.0"

        case .options:
            headers["Tus-Resumable"] = "1.0.0"
        }

        return headers.isEmpty ? nil : headers
    }

    var parameters: Parameters? {
        switch self {
        case .createUpload(let fileSize, let metadata, _):
            let params: Parameters = [
                "fileSize": fileSize,
                "metadata": metadata.dictionary
            ]
            return params

        case .completeUpload(_, let targetType, let targetId):
            var params: Parameters = ["targetType": targetType]
            if let targetId { params["targetId"] = targetId }
            return params

        default:
            return nil
        }
    }

    var encoding: ParameterEncoding {
        switch self {
        case .uploadChunk:
            // Raw data upload, handled by NetworkService
            return JSONEncoding.default
        default:
            return JSONEncoding.default
        }
    }
}

// Note: UploadTargetType, TusConstants are defined in Shared/Enums.swift
// Note: Domain models (TusMetadata, TusCreateResponse, etc.) are defined in Domain/UseCases/Upload/TusUseCases.swift
// Note: DTOs are defined in Data/DataSources/Remote/RemoteTusDataSource.swift (if needed)
// Note: TusError is defined in Domain/UseCases/Upload/TusUseCases.swift