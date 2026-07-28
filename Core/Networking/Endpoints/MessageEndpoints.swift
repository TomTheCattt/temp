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
    case messages(conversationId: String, page: Int, perPage: Int)
    case send(conversationId: String, contentType: String, content: String)
    case create(participantIds: [String])
    case markRead(conversationId: String)
    case deleteMessage(messageId: String)
    case mute(conversationId: String, mute: Bool)

    var path: String {
        switch self {
        case .list:                                     return "/v1/conversations"
        case .messages(let id, _, _):                   return "/v1/conversations/\(id)/messages"
        case .send(let id, _, _):                       return "/v1/conversations/\(id)/messages"
        case .create:                                   return "/v1/conversations"
        case .markRead(let id):                         return "/v1/conversations/\(id)/read"
        case .deleteMessage(let messageId):             return "/v1/messages/\(messageId)"
        case .mute(let id, _):                          return "/v1/conversations/\(id)/mute"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list, .messages:
            return .get
        case .send, .create, .markRead, .mute:
            return .post
        case .deleteMessage:
            return .delete
        }
    }

    var parameters: Parameters? {
        switch self {
        case .list(let page, let perPage),
             .messages(_, let page, let perPage):
            return ["page": page, "per_page": perPage]
        case .send(_, let contentType, let content):
            return ["content_type": contentType, "content": content]
        case .create(let participantIds):
            return ["participant_ids": participantIds]
        case .mute(_, let mute):
            return ["mute": mute]
        default:
            return nil
        }
    }
}
