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
    case create(participantIds: [String], groupName: String?, groupAvatar: String?)
    case createGroup(participantIds: [String], groupName: String?)
    case messages(conversationId: String, cursor: String?, perPage: Int)
    case sendText(conversationId: String, textContent: String, replyToId: String?)
    case sendMedia(conversationId: String, contentType: String, mediaUrl: String, mediaThumbnail: String?, mediaDuration: Double?)
    case markRead(conversationId: String)
    case mute(conversationId: String, mute: Bool)
    case deleteMessage(messageId: String)
    case fetchGroupDetails(conversationId: String)
    case updateGroupMuteSettings(conversationId: String, muteMessages: Bool, muteCalls: Bool)
    case leaveGroup(conversationId: String)
    case deleteGroup(conversationId: String)

    var path: String {
        switch self {
        case .list, .create:
            return "/v1/conversations"
        case .createGroup:
            return "/v1/conversations/group"
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
        case .fetchGroupDetails(let id):
            return "/v1/conversations/\(id)/details"
        case .updateGroupMuteSettings(let id, _, _):
            return "/v1/conversations/\(id)/mute-settings"
        case .leaveGroup(let id):
            return "/v1/conversations/\(id)/leave"
        case .deleteGroup(let id):
            return "/v1/conversations/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list, .messages, .fetchGroupDetails:
            return .get
        case .create, .createGroup, .sendText, .sendMedia, .markRead:
            return .post
        case .mute, .updateGroupMuteSettings:
            return .put
        case .deleteMessage, .leaveGroup, .deleteGroup:
            return .delete
        }
    }

    var parameters: Parameters? {
        switch self {
        case .list(let page, let perPage):
            return ["page": page, "perPage": perPage]
        case .messages(_, let cursor, let perPage):
            var params: Parameters = ["perPage": perPage]
            if let cursor { params["cursor"] = cursor }
            return params
        case .create(let participantIds, let groupName, let groupAvatar):
            var params: Parameters = ["participantIds": participantIds]
            if let groupName { params["groupName"] = groupName }
            if let groupAvatar { params["groupAvatar"] = groupAvatar }
            return params
        case .createGroup(let participantIds, let groupName):
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
        case .updateGroupMuteSettings(_, let muteMessages, let muteCalls):
            return ["muteMessages": muteMessages, "muteCalls": muteCalls]
        case .markRead, .deleteMessage, .fetchGroupDetails, .leaveGroup, .deleteGroup:
            return nil
        }
    }
}
