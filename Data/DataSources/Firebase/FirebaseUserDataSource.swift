//
//  FirebaseUserDataSource.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// MARK: - FirebaseUserDataSource

/// Production-ready Firebase Firestore user data source.
/// Implemented as a Swift 6 actor for thread-safety and data-race safety.
actor FirebaseUserDataSource: Sendable {

    static let shared = FirebaseUserDataSource()

    private let db: Firestore
    private let storageService: FirebaseStorageServiceProtocol

    // In-memory caches to prevent redundant network trips
    private var userCache: [String: User] = [:]
    private var settingsCache: [String: UserSettings] = [:]

    init(
        db: Firestore = Firestore.firestore(),
        storageService: FirebaseStorageServiceProtocol = FirebaseStorageService.shared
    ) {
        self.db = db
        self.storageService = storageService
    }

    private var usersCollection: CollectionReference {
        db.collection("users")
    }

    // MARK: - User Identification Helper

    private func resolvedCurrentUserId() async -> String? {
        if let uid = Auth.auth().currentUser?.uid, !uid.isEmpty {
            return uid
        }
        let sessionUid = await MainActor.run { SessionStore.shared.currentUserId }
        return sessionUid.isEmpty ? nil : sessionUid
    }

    private func fetchCurrentUserDocData() async -> [String: Any]? {
        guard let myId = await resolvedCurrentUserId() else { return nil }
        let snapshot = try? await usersCollection.document(myId).getDocument()
        return snapshot?.data()
    }

    // MARK: - Save / Cache Management

    func saveUser(_ user: User) async throws {
        let data = userToDictionary(user)
        try await usersCollection.document(user.id).setData(data, merge: true)
        userCache[user.id] = user
    }

    func updateUserCache(_ user: User) {
        userCache[user.id] = user
    }

    // MARK: - User Profile

    func fetchCurrentUser() async throws -> User {
        guard let myId = await resolvedCurrentUserId() else {
            if let sessionUser = await MainActor.run(body: { SessionStore.shared.currentUser }) {
                return sessionUser
            }
            throw FirebaseAuthError.notSignedIn
        }

        do {
            let user = try await fetchUser(id: myId)
            await MainActor.run { SessionStore.shared.setSession(user: user) }
            return user
        } catch {
            if let sessionUser = await MainActor.run(body: { SessionStore.shared.currentUser }) {
                return sessionUser
            }
            throw error
        }
    }

    func fetchUser(id: String) async throws -> User {
        let currentId = await resolvedCurrentUserId()
        let myDocData = await fetchCurrentUserDocData()

        let docRef = usersCollection.document(id)
        let snapshot = try await docRef.getDocument()

        guard snapshot.exists, let data = snapshot.data() else {
            if let cached = userCache[id] {
                return cached
            }
            throw APIError.notFound
        }

        let user = parseUser(data: data, id: snapshot.documentID, currentUserId: currentId, currentUserDocData: myDocData)
        userCache[id] = user
        return user
    }

    func searchUsers(query: String, page: Int, perPage: Int) async throws -> [User] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }

        let currentId = await resolvedCurrentUserId()
        let myDocData = await fetchCurrentUserDocData()

        let snapshot = try await usersCollection.limit(to: 100).getDocuments()
        var candidates: [User] = []

        for doc in snapshot.documents {
            let data = doc.data()
            let user = parseUser(data: data, id: doc.documentID, currentUserId: currentId, currentUserDocData: myDocData)
            if user.username.lowercased().contains(trimmed) || user.fullName.lowercased().contains(trimmed) {
                candidates.append(user)
            }
        }

        let start = (page - 1) * perPage
        let end = min(start + perPage, candidates.count)
        guard start < end else { return [] }
        return Array(candidates[start..<end])
    }

    func updateProfile(name: String?, bio: String?, website: String?) async throws -> User {
        guard let myId = await resolvedCurrentUserId() else {
            throw FirebaseAuthError.notSignedIn
        }

        var updates: [String: Any] = [:]
        if let name { updates["fullName"] = name }
        if let bio { updates["bio"] = bio }
        if let website { updates["website"] = website }
        updates["updatedAt"] = Timestamp(date: .now)

        try await usersCollection.document(myId).setData(updates, merge: true)

        let updated = try await fetchUser(id: myId)
        await MainActor.run { SessionStore.shared.setSession(user: updated) }
        userCache[myId] = updated
        return updated
    }

    func setPrivateAccount(_ isPrivate: Bool) async throws -> User {
        guard let myId = await resolvedCurrentUserId() else {
            throw FirebaseAuthError.notSignedIn
        }

        let updates: [String: Any] = [
            "isPrivate": isPrivate,
            "updatedAt": Timestamp(date: .now)
        ]
        try await usersCollection.document(myId).setData(updates, merge: true)

        let updated = try await fetchUser(id: myId)
        await MainActor.run { SessionStore.shared.setSession(user: updated) }
        userCache[myId] = updated
        return updated
    }

    func updateAvatar(imageData: Data) async throws -> User {
        guard let myId = await resolvedCurrentUserId() else {
            throw FirebaseAuthError.notSignedIn
        }

        let avatarPath = "avatars/\(myId).jpg"
        let downloadURL = try await storageService.uploadImage(data: imageData, path: avatarPath)

        let updates: [String: Any] = [
            "avatarURL": downloadURL.absoluteString,
            "updatedAt": Timestamp(date: .now)
        ]
        try await usersCollection.document(myId).setData(updates, merge: true)

        let updated = try await fetchUser(id: myId)
        await MainActor.run { SessionStore.shared.setSession(user: updated) }
        userCache[myId] = updated
        return updated
    }

    // MARK: - Follow / Unfollow

    func follow(userId: String) async throws {
        guard let myId = await resolvedCurrentUserId() else {
            throw FirebaseAuthError.notSignedIn
        }
        guard myId != userId else { return }

        let batch = db.batch()
        let myRef = usersCollection.document(myId)
        let targetRef = usersCollection.document(userId)

        batch.setData([
            "following": FieldValue.arrayUnion([userId]),
            "followingCount": FieldValue.increment(Int64(1))
        ], forDocument: myRef, merge: true)

        batch.setData([
            "followers": FieldValue.arrayUnion([myId]),
            "followersCount": FieldValue.increment(Int64(1))
        ], forDocument: targetRef, merge: true)

        try await batch.commit()

        userCache.removeValue(forKey: myId)
        userCache.removeValue(forKey: userId)
    }

    func unfollow(userId: String) async throws {
        guard let myId = await resolvedCurrentUserId() else {
            throw FirebaseAuthError.notSignedIn
        }
        guard myId != userId else { return }

        let batch = db.batch()
        let myRef = usersCollection.document(myId)
        let targetRef = usersCollection.document(userId)

        batch.setData([
            "following": FieldValue.arrayRemove([userId]),
            "followingCount": FieldValue.increment(Int64(-1))
        ], forDocument: myRef, merge: true)

        batch.setData([
            "followers": FieldValue.arrayRemove([myId]),
            "followersCount": FieldValue.increment(Int64(-1))
        ], forDocument: targetRef, merge: true)

        try await batch.commit()

        userCache.removeValue(forKey: myId)
        userCache.removeValue(forKey: userId)
    }

    // MARK: - Block / Unblock

    func block(userId: String) async throws {
        guard let myId = await resolvedCurrentUserId() else {
            throw FirebaseAuthError.notSignedIn
        }
        guard myId != userId else { return }

        let myRef = usersCollection.document(myId)
        try await myRef.setData([
            "blockedUsers": FieldValue.arrayUnion([userId])
        ], merge: true)

        userCache.removeValue(forKey: myId)
        userCache.removeValue(forKey: userId)
    }

    func unblock(userId: String) async throws {
        guard let myId = await resolvedCurrentUserId() else {
            throw FirebaseAuthError.notSignedIn
        }

        let myRef = usersCollection.document(myId)
        try await myRef.setData([
            "blockedUsers": FieldValue.arrayRemove([userId])
        ], merge: true)

        userCache.removeValue(forKey: myId)
        userCache.removeValue(forKey: userId)
    }

    func fetchBlockedUsers(page: Int, perPage: Int) async throws -> [User] {
        guard let myId = await resolvedCurrentUserId() else { return [] }
        let myDoc = try await usersCollection.document(myId).getDocument()
        let blockedIds = (myDoc.data()?["blockedUsers"] as? [String]) ?? []

        let start = (page - 1) * perPage
        let end = min(start + perPage, blockedIds.count)
        guard start < end else { return [] }
        let pageIds = Array(blockedIds[start..<end])

        var blockedList: [User] = []
        for id in pageIds {
            if let user = try? await fetchUser(id: id) {
                var blockedUser = user
                blockedUser.isBlocked = true
                blockedList.append(blockedUser)
            }
        }
        return blockedList
    }

    // MARK: - Settings

    func fetchSettings() async throws -> UserSettings {
        guard let myId = await resolvedCurrentUserId() else {
            return UserSettings.default
        }
        if let cached = settingsCache[myId] {
            return cached
        }

        let doc = try await usersCollection.document(myId).getDocument()
        let settingsDict = (doc.data()?["settings"] as? [String: Any]) ?? [:]
        let settings = parseSettings(dict: settingsDict)
        settingsCache[myId] = settings
        return settings
    }

    func updateSettings(_ patch: UserSettingsPatch) async throws -> UserSettings {
        guard let myId = await resolvedCurrentUserId() else {
            throw FirebaseAuthError.notSignedIn
        }

        let current = try await fetchSettings()
        var updated = current
        if let push = patch.pushEnabled { updated.pushEnabled = push }
        if let like = patch.likeNotifications { updated.likeNotifications = like }
        if let comment = patch.commentNotifications { updated.commentNotifications = comment }
        if let follow = patch.followNotifications { updated.followNotifications = follow }
        if let dm = patch.directMessageNotifications { updated.directMessageNotifications = dm }
        if let activity = patch.activityStatusVisible { updated.activityStatusVisible = activity }
        if let hq = patch.highQualityUploads { updated.highQualityUploads = hq }
        if let cellular = patch.cellularDataEnabled { updated.cellularDataEnabled = cellular }

        try await usersCollection.document(myId).setData([
            "settings": settingsToDictionary(updated)
        ], merge: true)

        settingsCache[myId] = updated
        return updated
    }

    // MARK: - Close Friends

    func fetchCloseFriends(page: Int, perPage: Int) async throws -> [User] {
        guard let myId = await resolvedCurrentUserId() else { return [] }
        let doc = try await usersCollection.document(myId).getDocument()
        let ids = (doc.data()?["closeFriends"] as? [String]) ?? []

        let start = (page - 1) * perPage
        let end = min(start + perPage, ids.count)
        guard start < end else { return [] }
        let pageIds = Array(ids[start..<end])

        var friends: [User] = []
        for id in pageIds {
            if let user = try? await fetchUser(id: id) {
                friends.append(user)
            }
        }
        return friends
    }

    func setCloseFriends(userIds: [String]) async throws -> [User] {
        guard let myId = await resolvedCurrentUserId() else {
            throw FirebaseAuthError.notSignedIn
        }

        try await usersCollection.document(myId).setData([
            "closeFriends": userIds
        ], merge: true)

        var friends: [User] = []
        for id in userIds {
            if let user = try? await fetchUser(id: id) {
                friends.append(user)
            }
        }
        return friends
    }

    // MARK: - Lists (Followers, Following, Suggested)

    func fetchFollowers(userId: String, page: Int, perPage: Int) async throws -> [User] {
        let doc = try await usersCollection.document(userId).getDocument()
        let followerIds = (doc.data()?["followers"] as? [String]) ?? []

        let start = (page - 1) * perPage
        let end = min(start + perPage, followerIds.count)
        guard start < end else { return [] }
        let pageIds = Array(followerIds[start..<end])

        var followers: [User] = []
        for id in pageIds {
            if let user = try? await fetchUser(id: id) {
                followers.append(user)
            }
        }
        return followers
    }

    func fetchFollowing(userId: String, page: Int, perPage: Int) async throws -> [User] {
        let doc = try await usersCollection.document(userId).getDocument()
        let followingIds = (doc.data()?["following"] as? [String]) ?? []

        let start = (page - 1) * perPage
        let end = min(start + perPage, followingIds.count)
        guard start < end else { return [] }
        let pageIds = Array(followingIds[start..<end])

        var following: [User] = []
        for id in pageIds {
            if let user = try? await fetchUser(id: id) {
                following.append(user)
            }
        }
        return following
    }

    func fetchSuggested(page: Int, perPage: Int) async throws -> [User] {
        let currentId = await resolvedCurrentUserId()
        let myDocData = await fetchCurrentUserDocData()
        let followingIds = Set((myDocData?["following"] as? [String]) ?? [])

        let snapshot = try await usersCollection.limit(to: 50).getDocuments()
        var candidates: [User] = []

        for doc in snapshot.documents {
            if let currentId, doc.documentID == currentId { continue }
            if followingIds.contains(doc.documentID) { continue }
            let data = doc.data()
            let user = parseUser(data: data, id: doc.documentID, currentUserId: currentId, currentUserDocData: myDocData)
            candidates.append(user)
        }

        let start = (page - 1) * perPage
        let end = min(start + perPage, candidates.count)
        guard start < end else { return [] }
        return Array(candidates[start..<end])
    }

    // MARK: - Private Parsing Helpers

    private func parseUser(
        data: [String: Any],
        id: String,
        currentUserId: String?,
        currentUserDocData: [String: Any]?
    ) -> User {
        let username = (data["username"] as? String) ?? ""
        let fullName = (data["fullName"] as? String) ?? ""
        let email = data["email"] as? String
        let phone = data["phone"] as? String
        let avatarURL = (data["avatarURL"] as? String ?? data["avatarUrl"] as? String).flatMap { URL(string: $0) }
        let bio = data["bio"] as? String
        let website = data["website"] as? String
        let isVerified = (data["isVerified"] as? Bool) ?? false
        let isPrivate = (data["isPrivate"] as? Bool) ?? false
        let followers = (data["followers"] as? [String]) ?? []
        let following = (data["following"] as? [String]) ?? []
        let followersCount = (data["followersCount"] as? Int) ?? followers.count
        let followingCount = (data["followingCount"] as? Int) ?? following.count
        let postsCount = (data["postsCount"] as? Int) ?? 0

        let createdAt: Date
        if let ts = data["createdAt"] as? Timestamp {
            createdAt = ts.dateValue()
        } else if let date = data["createdAt"] as? Date {
            createdAt = date
        } else if let str = data["createdAt"] as? String {
            createdAt = DateMapper.toDate(str)
        } else {
            createdAt = .now
        }

        var isUserFollowing = false
        var isUserFollowedBy = false
        var isUserBlocked = false

        if let currentUserId, !currentUserId.isEmpty, currentUserId != id {
            let myFollowing = (currentUserDocData?["following"] as? [String]) ?? []
            let myFollowers = (currentUserDocData?["followers"] as? [String]) ?? []
            let myBlocked = (currentUserDocData?["blockedUsers"] as? [String]) ?? []

            isUserFollowing = myFollowing.contains(id) || followers.contains(currentUserId)
            isUserFollowedBy = myFollowers.contains(id) || following.contains(currentUserId)
            isUserBlocked = myBlocked.contains(id)
        }

        return User(
            id: id,
            username: username,
            fullName: fullName,
            email: email,
            phone: phone,
            avatarURL: avatarURL,
            bio: bio,
            website: website,
            isVerified: isVerified,
            isPrivate: isPrivate,
            followersCount: max(0, followersCount),
            followingCount: max(0, followingCount),
            postsCount: max(0, postsCount),
            createdAt: createdAt,
            isFollowing: isUserFollowing,
            isFollowedBy: isUserFollowedBy,
            isBlocked: isUserBlocked
        )
    }

    private func userToDictionary(_ user: User) -> [String: Any] {
        var dict: [String: Any] = [
            "id": user.id,
            "username": user.username,
            "fullName": user.fullName,
            "isVerified": user.isVerified,
            "isPrivate": user.isPrivate,
            "followersCount": user.followersCount,
            "followingCount": user.followingCount,
            "postsCount": user.postsCount,
            "createdAt": Timestamp(date: user.createdAt)
        ]
        if let email = user.email { dict["email"] = email }
        if let phone = user.phone { dict["phone"] = phone }
        if let avatarURL = user.avatarURL?.absoluteString { dict["avatarURL"] = avatarURL }
        if let bio = user.bio { dict["bio"] = bio }
        if let website = user.website { dict["website"] = website }
        return dict
    }

    private func parseSettings(dict: [String: Any]) -> UserSettings {
        let defaults = UserSettings.default
        return UserSettings(
            pushEnabled: (dict["pushEnabled"] as? Bool) ?? defaults.pushEnabled,
            likeNotifications: (dict["likeNotifications"] as? Bool) ?? defaults.likeNotifications,
            commentNotifications: (dict["commentNotifications"] as? Bool) ?? defaults.commentNotifications,
            followNotifications: (dict["followNotifications"] as? Bool) ?? defaults.followNotifications,
            directMessageNotifications: (dict["directMessageNotifications"] as? Bool) ?? defaults.directMessageNotifications,
            activityStatusVisible: (dict["activityStatusVisible"] as? Bool) ?? defaults.activityStatusVisible,
            highQualityUploads: (dict["highQualityUploads"] as? Bool) ?? defaults.highQualityUploads,
            cellularDataEnabled: (dict["cellularDataEnabled"] as? Bool) ?? defaults.cellularDataEnabled
        )
    }

    private func settingsToDictionary(_ s: UserSettings) -> [String: Any] {
        [
            "pushEnabled": s.pushEnabled,
            "likeNotifications": s.likeNotifications,
            "commentNotifications": s.commentNotifications,
            "followNotifications": s.followNotifications,
            "directMessageNotifications": s.directMessageNotifications,
            "activityStatusVisible": s.activityStatusVisible,
            "highQualityUploads": s.highQualityUploads,
            "cellularDataEnabled": s.cellularDataEnabled
        ]
    }
}
