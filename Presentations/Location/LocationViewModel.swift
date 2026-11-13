//
//  LocationViewModel.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - LocationViewModel

@MainActor
@Observable
final class LocationViewModel {

    // MARK: - State

    var posts: [Post] = []
    var isLoading = false

    let locationName: String

    // MARK: - Init

    init(locationName: String) {
        self.locationName = locationName
    }

    // MARK: - Actions

    func loadPosts() async {
        // TODO: Implement loadPosts for location from scratch
    }

    func loadMore() async {
        // TODO: Implement loadMore for location from scratch
    }
}
