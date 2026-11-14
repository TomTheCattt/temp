//
//  Enums.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//  Shared enum definitions for all layers
//

import Foundation
import SwiftUI

// MARK: - Report Enums

enum ReportType: String, Codable, CaseIterable, Equatable {
    case post = "POST"
    case comment = "COMMENT"
    case reel = "REEL"
    case story = "STORY"
    case user = "USER"
    case message = "MESSAGE"
}

enum ReportReason: String, Codable, CaseIterable, Equatable {
    case spam = "SPAM"
    case inappropriateContent = "INAPPROPRIATE_CONTENT"
    case harassment = "HARASSMENT"
    case hateSpeech = "HATE_SPEECH"
    case violence = "VIOLENCE"
    case sexualContent = "SEXUAL_CONTENT"
    case selfHarm = "SELF_HARM"
    case fakeAccount = "FAKE_ACCOUNT"
    case intellectualProperty = "INTELLECTUAL_PROPERTY"
    case other = "OTHER"
}

enum ReportStatus: String, Codable, CaseIterable, Equatable {
    case pending = "PENDING"
    case reviewed = "REVIEWED"
    case resolved = "RESOLVED"
    case dismissed = "DISMISSED"
}

// MARK: - Search Enums

enum SearchType: String, Codable, CaseIterable, Equatable {
    case users = "users"
    case posts = "posts"
    case reels = "reels"
    case hashtags = "hashtags"
    case locations = "locations"
    case audio = "audio"
    case all = "all"
}

enum SearchResultType: String, Codable, Equatable {
    case user = "user"
    case post = "post"
    case reel = "reel"
    case hashtag = "hashtag"
    case location = "location"
    case audio = "audio"
}

// MARK: - Call Enums

enum CallType: String, Codable, CaseIterable, Equatable {
    case audio = "audio"
    case video = "video"

    var title: String {
        switch self {
        case .audio: return "Audio"
        case .video: return "Video"
        }
    }

    var icon: String {
        switch self {
        case .audio: return "phone.fill"
        case .video: return "video.fill"
        }
    }

    var color: Color {
        switch self {
        case .audio: return .blue
        case .video: return .green
        }
    }
}

enum CallStatus: String, Codable, CaseIterable, Equatable {
    case initiated = "initiated"
    case ringing = "ringing"
    case answered = "answered"
    case ended = "ended"
    case missed = "missed"
    case rejected = "rejected"
    case busy = "busy"
    case failed = "failed"
}

enum CallSignalingType: String, Codable, Equatable {
    case initiate = "call_initiate"
    case offer = "call_offer"
    case answer = "call_answer"
    case iceCandidate = "call_ice_candidate"
    case hangup = "call_hangup"
    case reject = "call_reject"
    case busy = "call_busy"
    case ringing = "call_ringing"
}

// MARK: - Upload Enums

enum UploadTargetType: String, Codable, CaseIterable, Equatable {
    case post = "post"
    case reel = "reel"
    case story = "story"
    case message = "message"
    case avatar = "avatar"
}

// MARK: - Notification Enums (if needed)

enum NotificationType: String, Codable, CaseIterable, Equatable, Sendable {
    case like = "LIKE"
    case comment = "COMMENT"
    case follow = "FOLLOW"
    case followRequest = "FOLLOW_REQUEST"
    case followAccept = "FOLLOW_ACCEPT"
    case mention = "MENTION"
    case taggedInPost = "TAGGED_IN_POST"
    case taggedInComment = "TAGGED_IN_COMMENT"
    case taggedInStory = "TAGGED_IN_STORY"
    case storyMention = "STORY_MENTION"
    case storyReply = "STORY_REPLY"
    case reelLike = "REEL_LIKE"
    case reelComment = "REEL_COMMENT"
    case liveVideo = "LIVE_VIDEO"
    case liveJoin = "LIVE_JOIN"
    case dmMessage = "DM_MESSAGE"
    case dmReaction = "DM_REACTION"

    // Backward compatibility aliases
    case message = "MESSAGE"
    case call = "CALL"
    case live = "LIVE"
    case newReel = "NEW_REEL"
    case newStory = "NEW_STORY"
}

// MARK: - Device Platform

enum DevicePlatform: String, Codable, CaseIterable, Equatable, Sendable {
    case ios = "IOS"
    case android = "ANDROID"
    case web = "WEB"
}

// MARK: - Audience & Privacy Enums

enum PostAudience: String, Codable, CaseIterable, Equatable, Sendable {
    case publicAudience = "PUBLIC"
    case followers = "FOLLOWERS"
    case closeFriends = "CLOSE_FRIENDS"
}

enum FollowStatus: String, Codable, CaseIterable, Equatable, Sendable {
    case pending = "PENDING"
    case accepted = "ACCEPTED"
    case blocked = "BLOCKED"
}

// MARK: - Polymorphic Interaction Enums

enum CommentableType: String, Codable, CaseIterable, Equatable, Sendable {
    case post = "POST"
    case reel = "REEL"
    case story = "STORY"
}

enum LikeableType: String, Codable, CaseIterable, Equatable, Sendable {
    case post = "POST"
    case reel = "REEL"
    case comment = "COMMENT"
    case story = "STORY"
}

// MARK: - Direct Message Enums

enum MessageContentType: String, Codable, CaseIterable, Equatable, Sendable {
    case text = "TEXT"
    case image = "IMAGE"
    case video = "VIDEO"
    case audio = "AUDIO"
    case file = "FILE"
    case postShare = "POST_SHARE"
    case reelShare = "REEL_SHARE"
    case storyShare = "STORY_SHARE"
    case profileShare = "PROFILE_SHARE"
    case location = "LOCATION"
    case contact = "CONTACT"
    case voice = "VOICE"
    case reply = "REPLY"
    case system = "SYSTEM"
}

enum MessageDeliveryStatus: String, Codable, CaseIterable, Equatable, Sendable {
    case sending = "SENDING"
    case sent = "SENT"
    case delivered = "DELIVERED"
    case read = "READ"
    case failed = "FAILED"
}

// MARK: - Auth Enums

enum AuthProvider: String, Codable, CaseIterable, Equatable {
    case email = "email"
    case google = "google"
    case apple = "apple"
    case facebook = "facebook"
}

// MARK: - User Enums

enum UserPrivacy: String, Codable, CaseIterable, Equatable {
    case `public` = "PUBLIC"
    case `private` = "PRIVATE"
    case followers = "FOLLOWERS"
}

// MARK: - Media Enums

enum MediaType: String, Codable, CaseIterable, Equatable, Sendable {
    case image = "IMAGE"
    case video = "VIDEO"
    case carousel = "CAROUSEL"
    case audio = "AUDIO"
}

enum UploadStatus: String, Codable, CaseIterable, Equatable {
    case pending = "pending"
    case uploading = "uploading"
    case complete = "complete"
    case failed = "failed"
    case expired = "expired"
}

// MARK: - TUS Constants

enum TusConstants {
    static let protocolVersion = "1.0.0"
    static let defaultChunkSize: Int64 = 5 * 1024 * 1024 // 5MB
    static let maxChunkSize: Int64 = 50 * 1024 * 1024 // 50MB
    static let defaultExpiryHours = 24
}

// MARK: - Error Enums

enum AppError: Error, LocalizedError, Equatable {
    case networkError(String)
    case serverError(Int, String?)
    case decodingError(String)
    case encodingError(String)
    case unauthorized
    case forbidden
    case notFound(String)
    case validationError(String)
    case alreadyExists(String)
    case rateLimited(retryAfter: Int?)
    case offline
    case timeout
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .serverError(let code, let msg):
            return "Server error (\(code)): \(msg ?? "Unknown")"
        case .decodingError(let msg):
            return "Decoding error: \(msg)"
        case .encodingError(let msg):
            return "Encoding error: \(msg)"
        case .unauthorized:
            return "Unauthorized. Please log in again."
        case .forbidden:
            return "You don't have permission to perform this action."
        case .notFound(let resource):
            return "\(resource) not found."
        case .validationError(let msg):
            return "Validation error: \(msg)"
        case .alreadyExists(let resource):
            return "\(resource) already exists."
        case .rateLimited(let retryAfter):
            if let retryAfter {
                return "Rate limited. Try again in \(retryAfter) seconds."
            }
            return "Rate limited. Please try again later."
        case .offline:
            return "You appear to be offline. Please check your connection."
        case .timeout:
            return "Request timed out. Please try again."
        case .unknown(let msg):
            return "Unknown error: \(msg)"
        }
    }
}