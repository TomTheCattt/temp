//
//  MyStoryView.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI

// MARK: - MyStoryView

/// Story viewer entry point for the current user's own stories.
/// Delegates to `StoryViewerView` which dynamically adapts UI between owner controls
/// (viewers count, close friends indicator, delete confirmation, camera add-story)
/// and friend viewer controls (profile navigation, reply bar, reaction) as stories
/// seamlessly transition between users.
struct MyStoryView: View {

    let viewModel: StoryViewerViewModel

    init(viewModel: StoryViewerViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        StoryViewerView(viewModel: viewModel)
    }
}
