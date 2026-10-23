//
//  HashtagViewModel.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - HashtagViewModel

@MainActor
@Observable
final class HashtagViewModel {

    // MARK: - State

    var posts: [Post] = []
    var isLoading = false
    var postCount: Int = 0

    let hashtagName: String

    // MARK: - Dependencies

    private let postRepository: PostRepositoryProtocol

    // MARK: - Init

    init(hashtagName: String, postRepository: PostRepositoryProtocol) {
        self.hashtagName = hashtagName
        self.postRepository = postRepository
    }

    // MARK: - Actions

    func loadPosts() async {
        // TODO: Implement loadPosts for hashtag from scratch
    }

    func loadMore() async {
        // TODO: Implement loadMore for hashtag from scratch
    }
}
