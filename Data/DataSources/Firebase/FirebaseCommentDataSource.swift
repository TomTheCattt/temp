//
//  FirebaseCommentDataSource.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - FirebaseCommentDataSource

actor FirebaseCommentDataSource: Sendable {

    private let firestore: Firestore
    private var cachedComments: [String: [Comment]] = [:]

    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }

    // MARK: - Fetch Comments

    func fetchComments(postId: String, page: Int, perPage: Int) async throws -> [Comment] {
        let currentUserId = await resolveCurrentUserId()

        do {
            let snapshot = try await firestore.collection("posts")
                .document(postId)
                .collection("comments")
                .order(by: "createdAt", descending: false)
                .getDocuments()

            if !snapshot.documents.isEmpty {
                let flatComments = snapshot.documents.compactMap { doc -> Comment? in
                    parseComment(doc.data(), documentId: doc.documentID, postId: postId, currentUserId: currentUserId)
                }

                let structured = assembleCommentHierarchy(flatComments)
                cachedComments[postId] = structured
            }
        } catch {
            AppLogger.network.error("FirebaseCommentDataSource.fetchComments error: \(error.localizedDescription). Falling back to in-memory cache.")
        }

        let existing = cachedComments[postId] ?? []
        let start = (page - 1) * perPage
        let end = min(start + perPage, existing.count)
        guard start < end else { return [] }
        return Array(existing[start..<end])
    }

    // MARK: - Add Comment

    func addComment(postId: String, text: String, parentId: String?) async throws -> Comment {
        let currentUser = await resolveCurrentUser()
        let commentId = "comment_\(UUID().uuidString.prefix(10))"

        let newComment = Comment(
            id: commentId,
            postId: postId,
            author: currentUser,
            text: text,
            likesCount: 0,
            isLiked: false,
            replies: [],
            parentId: parentId,
            createdAt: .now
        )

        let commentData = commentToDict(newComment)
        do {
            try await firestore.collection("posts")
                .document(postId)
                .collection("comments")
                .document(commentId)
                .setData(commentData)

            try await firestore.collection("posts")
                .document(postId)
                .updateData(["commentsCount": FieldValue.increment(Int64(1))])
        } catch {
            AppLogger.network.error("FirebaseCommentDataSource.addComment error: \(error.localizedDescription)")
        }

        var list = cachedComments[postId] ?? []
        if let parentId = parentId {
            if let parentIndex = list.firstIndex(where: { $0.id == parentId }) {
                let parent = list[parentIndex]
                list[parentIndex] = Comment(
                    id: parent.id,
                    postId: parent.postId,
                    author: parent.author,
                    text: parent.text,
                    likesCount: parent.likesCount,
                    isLiked: parent.isLiked,
                    replies: parent.replies + [newComment],
                    parentId: parent.parentId,
                    createdAt: parent.createdAt
                )
            } else {
                list.append(newComment)
            }
        } else {
            list.insert(newComment, at: 0)
        }
        cachedComments[postId] = list

        return newComment
    }

    // MARK: - Delete Comment

    func deleteComment(postId: String, commentId: String) async throws {
        do {
            try await firestore.collection("posts")
                .document(postId)
                .collection("comments")
                .document(commentId)
                .delete()

            try await firestore.collection("posts")
                .document(postId)
                .updateData(["commentsCount": FieldValue.increment(Int64(-1))])
        } catch {
            AppLogger.network.error("FirebaseCommentDataSource.deleteComment error: \(error.localizedDescription)")
        }

        guard var list = cachedComments[postId] else { return }
        if let index = list.firstIndex(where: { $0.id == commentId }) {
            list.remove(at: index)
            cachedComments[postId] = list
            return
        }

        for i in 0..<list.count {
            if let replyIndex = list[i].replies.firstIndex(where: { $0.id == commentId }) {
                var replies = list[i].replies
                replies.remove(at: replyIndex)
                let parent = list[i]
                list[i] = Comment(
                    id: parent.id,
                    postId: parent.postId,
                    author: parent.author,
                    text: parent.text,
                    likesCount: parent.likesCount,
                    isLiked: parent.isLiked,
                    replies: replies,
                    parentId: parent.parentId,
                    createdAt: parent.createdAt
                )
                cachedComments[postId] = list
                return
            }
        }
    }

    // MARK: - Like / Unlike Comment

    func likeComment(postId: String, commentId: String) async throws {
        let currentUserId = await resolveCurrentUserId()
        let updatePayload: [String: Any] = [
            "likesCount": FieldValue.increment(Int64(1)),
            "likedBy": FieldValue.arrayUnion([currentUserId])
        ]

        do {
            try await firestore.collection("posts")
                .document(postId)
                .collection("comments")
                .document(commentId)
                .updateData(updatePayload)
        } catch {
            AppLogger.network.error("FirebaseCommentDataSource.likeComment error: \(error.localizedDescription)")
        }

        mutateComment(postId: postId, commentId: commentId) { comment in
            Comment(
                id: comment.id,
                postId: comment.postId,
                author: comment.author,
                text: comment.text,
                likesCount: comment.likesCount + 1,
                isLiked: true,
                replies: comment.replies,
                parentId: comment.parentId,
                createdAt: comment.createdAt
            )
        }
    }

    func unlikeComment(postId: String, commentId: String) async throws {
        let currentUserId = await resolveCurrentUserId()
        let updatePayload: [String: Any] = [
            "likesCount": FieldValue.increment(Int64(-1)),
            "likedBy": FieldValue.arrayRemove([currentUserId])
        ]

        do {
            try await firestore.collection("posts")
                .document(postId)
                .collection("comments")
                .document(commentId)
                .updateData(updatePayload)
        } catch {
            AppLogger.network.error("FirebaseCommentDataSource.unlikeComment error: \(error.localizedDescription)")
        }

        mutateComment(postId: postId, commentId: commentId) { comment in
            Comment(
                id: comment.id,
                postId: comment.postId,
                author: comment.author,
                text: comment.text,
                likesCount: max(0, comment.likesCount - 1),
                isLiked: false,
                replies: comment.replies,
                parentId: comment.parentId,
                createdAt: comment.createdAt
            )
        }
    }

    // MARK: - Private Helpers

    private func mutateComment(postId: String, commentId: String, transform: (Comment) -> Comment) {
        guard var list = cachedComments[postId] else { return }
        if let index = list.firstIndex(where: { $0.id == commentId }) {
            list[index] = transform(list[index])
            cachedComments[postId] = list
            return
        }

        for i in 0..<list.count {
            if let replyIndex = list[i].replies.firstIndex(where: { $0.id == commentId }) {
                var replies = list[i].replies
                replies[replyIndex] = transform(replies[replyIndex])
                let parent = list[i]
                list[i] = Comment(
                    id: parent.id,
                    postId: parent.postId,
                    author: parent.author,
                    text: parent.text,
                    likesCount: parent.likesCount,
                    isLiked: parent.isLiked,
                    replies: replies,
                    parentId: parent.parentId,
                    createdAt: parent.createdAt
                )
                cachedComments[postId] = list
                return
            }
        }
    }

    private func assembleCommentHierarchy(_ flat: [Comment]) -> [Comment] {
        var topLevel: [Comment] = []
        var repliesByParent: [String: [Comment]] = [:]

        for item in flat {
            if let parentId = item.parentId {
                var arr = repliesByParent[parentId] ?? []
                arr.append(item)
                repliesByParent[parentId] = arr
            } else {
                topLevel.append(item)
            }
        }

        return topLevel.map { parent in
            let replies = repliesByParent[parent.id] ?? []
            return Comment(
                id: parent.id,
                postId: parent.postId,
                author: parent.author,
                text: parent.text,
                likesCount: parent.likesCount,
                isLiked: parent.isLiked,
                replies: replies,
                parentId: parent.parentId,
                createdAt: parent.createdAt
            )
        }
    }

    private func parseComment(_ data: [String: Any], documentId: String, postId: String, currentUserId: String) -> Comment? {
        let authorData = data["author"] as? [String: Any]
        let author = parseUser(authorData, rootData: data, fallbackId: data["authorId"] as? String ?? "")
        let text = data["text"] as? String ?? ""
        let likesCount = data["likesCount"] as? Int ?? 0
        let parentId = data["parentId"] as? String
        let createdAt = parseDate(data["createdAt"])
        let likedBy = data["likedBy"] as? [String] ?? []
        let isLiked = likedBy.contains(currentUserId)

        return Comment(
            id: documentId,
            postId: postId,
            author: author,
            text: text,
            likesCount: max(0, likesCount),
            isLiked: isLiked,
            replies: [],
            parentId: parentId,
            createdAt: createdAt
        )
    }

    private func commentToDict(_ comment: Comment) -> [String: Any] {
        var dict: [String: Any] = [
            "id": comment.id,
            "postId": comment.postId,
            "authorId": comment.author.id,
            "author": userToDict(comment.author),
            "text": comment.text,
            "likesCount": comment.likesCount,
            "createdAt": Timestamp(date: comment.createdAt),
            "likedBy": comment.isLiked ? [comment.author.id] : []
        ]
        if let parentId = comment.parentId {
            dict["parentId"] = parentId
        }
        return dict
    }

    private func userToDict(_ user: User) -> [String: Any] {
        var dict: [String: Any] = [
            "id": user.id,
            "username": user.username,
            "fullName": user.fullName,
            "isVerified": user.isVerified,
            "isPrivate": user.isPrivate,
            "followersCount": user.followersCount,
            "followingCount": user.followingCount,
            "postsCount": user.postsCount
        ]
        if let avatarURL = user.avatarURL?.absoluteString { dict["avatarUrl"] = avatarURL }
        return dict
    }

    private func parseUser(_ authorDict: [String: Any]?, rootData: [String: Any], fallbackId: String) -> User {
        let username = (authorDict?["username"] as? String)
            ?? (rootData["authorUsername"] as? String)
            ?? (rootData["username"] as? String)
            ?? "user"
        let fullName = (authorDict?["fullName"] as? String)
            ?? (rootData["authorFullName"] as? String)
            ?? username.capitalized
        let avatarStr = (authorDict?["avatarUrl"] as? String)
            ?? (authorDict?["avatarURL"] as? String)
            ?? (rootData["authorPhotoUrl"] as? String)
            ?? (rootData["avatarUrl"] as? String)
            ?? (rootData["avatarURL"] as? String)
        let avatarURL = avatarStr.flatMap { URL(string: $0) }
        let isVerified = (authorDict?["isVerified"] as? Bool)
            ?? (rootData["isVerified"] as? Bool)
            ?? false

        return User(
            id: authorDict?["id"] as? String ?? fallbackId,
            username: username,
            fullName: fullName,
            email: authorDict?["email"] as? String,
            phone: authorDict?["phone"] as? String,
            avatarURL: avatarURL,
            bio: authorDict?["bio"] as? String,
            website: authorDict?["website"] as? String,
            isVerified: isVerified,
            isPrivate: authorDict?["isPrivate"] as? Bool ?? false,
            followersCount: authorDict?["followersCount"] as? Int ?? 0,
            followingCount: authorDict?["followingCount"] as? Int ?? 0,
            postsCount: authorDict?["postsCount"] as? Int ?? 0,
            createdAt: parseDate(authorDict?["createdAt"] ?? rootData["createdAt"]),
            isFollowing: authorDict?["isFollowing"] as? Bool ?? false,
            isFollowedBy: authorDict?["isFollowedBy"] as? Bool ?? false,
            isBlocked: authorDict?["isBlocked"] as? Bool ?? false
        )
    }

    private func parseDate(_ value: Any?) -> Date {
        if let timestamp = value as? Timestamp {
            return timestamp.dateValue()
        }
        if let dateString = value as? String {
            return DateMapper.toDate(dateString)
        }
        if let date = value as? Date {
            return date
        }
        return .now
    }

    private func resolveCurrentUserId() async -> String {
        let authUid = await MainActor.run { FirebaseAuthService.shared.currentUserUID }
        if let authUid, !authUid.isEmpty {
            return authUid
        }
        let sessionUid = await MainActor.run { SessionStore.shared.currentUserId }
        return sessionUid
    }

    private func resolveCurrentUser() async -> User {
        if let sessionUser = await MainActor.run(body: { SessionStore.shared.currentUser }) {
            return sessionUser
        }
        let uid = await resolveCurrentUserId()
        return User(
            id: uid,
            username: "user_\(uid.prefix(6))",
            fullName: "Instagram User",
            email: nil,
            phone: nil,
            avatarURL: nil,
            bio: nil,
            website: nil,
            isVerified: false,
            isPrivate: false,
            followersCount: 0,
            followingCount: 0,
            postsCount: 0,
            createdAt: .now,
            isFollowing: false,
            isFollowedBy: false,
            isBlocked: false
        )
    }
}
