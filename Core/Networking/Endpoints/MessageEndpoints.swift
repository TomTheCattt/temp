//
//  MessageEndpoints.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation
import Alamofire

// MARK: - ConversationEndpoint

enum ConversationEndpoint: APIEndpoint {
    case list(page: Int, perPage: Int)
    case create(participantIds: [String], groupName: String?)
    case messages(conversationId: String, page: Int, perPage: Int)
    case sendText(conversationId: String, textContent: String, replyToId: String?)
    case sendMedia(conversationId: String, contentType: String, mediaUrl: String, mediaThumbnail: String?, mediaDuration: Double?)
    case markRead(conversationId: String)
    case mute(conversationId: String, mute: Bool)
    case deleteMessage(messageId: String)

    var path: String {
        switch self {
        case .list, .create:
            return "/v1/conversations"
        case .messages(let id, _, _):
            return "/v1/conversations/\(id)/messages"
        case .sendText(let id, _, _):
            return "/v1/conversations/\(id)/messages"
        case .sendMedia(let id, _, _, _, _):
            return "/v1/conversations/\(id)/messages"
        case .markRead(let id):
            return "/v1/conversations/\(id)/read"
        case .mute(let id, _):
            return "/v1/conversations/\(id)/mute"
        case .deleteMessage(let messageId):
            return "/v1/conversations/messages/\(messageId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list, .messages:
            return .get
        case .create, .sendText, .sendMedia, .markRead:
            return .post
        case .mute:
            return .put
        case .deleteMessage:
            return .delete
        }
    }

    var parameters: Parameters? {
        switch self {
        case .list(let page, let perPage),
             .messages(_, let page, let perPage):
            return ["page": page, "perPage": perPage]
        case .create(let participantIds, let groupName):
            var params: Parameters = ["participantIds": participantIds]
            if let groupName { params["groupName"] = groupName }
            return params
        case .sendText(_, let textContent, let replyToId):
            var params: Parameters = ["contentType": "TEXT", "textContent": textContent]
            if let replyToId { params["replyToId"] = replyToId }
            return params
        case .sendMedia(_, let contentType, let mediaUrl, let mediaThumbnail, let mediaDuration):
            var params: Parameters = ["contentType": contentType, "mediaUrl": mediaUrl]
            if let mediaThumbnail { params["mediaThumbnail"] = mediaThumbnail }
            if let mediaDuration { params["mediaDuration"] = mediaDuration }
            return params
        case .mute(_, let mute):
            return ["mute": mute]
        case .markRead, .deleteMessage:
            return nil
        }
    }
}
