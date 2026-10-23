//
//  StoryViewerViewModel.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - StoryViewerViewModel

@MainActor
@Observable
final class StoryViewerViewModel {

    // MARK: - State

    var stories: [Story] = []
    var isLoading = false
    var currentStoryIndex: Int = 0
    var currentItemIndex: Int = 0
    var itemProgress: Double = 0.0
    var isPaused = false

    // MARK: - Computed

    var currentStory: Story? {
        guard stories.indices.contains(currentStoryIndex) else { return nil }
        return stories[currentStoryIndex]
    }

    var currentItem: StoryItem? {
        guard let story = currentStory,
              story.items.indices.contains(currentItemIndex) else { return nil }
        return story.items[currentItemIndex]
    }

    var totalItemsInCurrentStory: Int {
        currentStory?.items.count ?? 0
    }

    var hasNextStory: Bool {
        currentStoryIndex < stories.count - 1
    }

    var hasPreviousStory: Bool {
        currentStoryIndex > 0
    }

    // MARK: - Dependencies

    private let fetchStoriesUseCase: FetchStoriesUseCaseProtocol
    private let markStoryViewedUseCase: MarkStoryViewedUseCaseProtocol
    private let deleteStoryUseCase: DeleteStoryUseCaseProtocol
    private let targetUserId: String?

    // MARK: - Init

    init(
        stories: [Story] = [],
        initialIndex: Int = 0,
        targetUserId: String? = nil,
        fetchStoriesUseCase: FetchStoriesUseCaseProtocol? = nil,
        markStoryViewedUseCase: MarkStoryViewedUseCaseProtocol? = nil,
        deleteStoryUseCase: DeleteStoryUseCaseProtocol? = nil
    ) {
        self.stories = stories
        self.currentStoryIndex = initialIndex
        self.targetUserId = targetUserId
        self.fetchStoriesUseCase = fetchStoriesUseCase ?? DIContainer.shared.resolve(FetchStoriesUseCaseProtocol.self)
        self.markStoryViewedUseCase = markStoryViewedUseCase ?? DIContainer.shared.resolve(MarkStoryViewedUseCaseProtocol.self)
        self.deleteStoryUseCase = deleteStoryUseCase ?? DIContainer.shared.resolve(DeleteStoryUseCaseProtocol.self)
    }

    // MARK: - Actions

    func loadStories() async {
        // TODO: Implement loadStories logic from scratch
    }

    func goToNext() {
        guard let story = currentStory else { return }

        if currentItemIndex < story.items.count - 1 {
            currentItemIndex += 1
            itemProgress = 0
        } else if hasNextStory {
            currentStoryIndex += 1
            currentItemIndex = 0
            itemProgress = 0
            markCurrentStoryViewedIfNeeded()
        }
    }

    func goToPrevious() {
        if currentItemIndex > 0 {
            currentItemIndex -= 1
            itemProgress = 0
        } else if hasPreviousStory {
            currentStoryIndex -= 1
            currentItemIndex = 0
            itemProgress = 0
            markCurrentStoryViewedIfNeeded()
        }
    }

    func jumpToStory(at index: Int) {
        guard stories.indices.contains(index) else { return }
        currentStoryIndex = index
        currentItemIndex = 0
        itemProgress = 0
        markCurrentStoryViewedIfNeeded()
    }

    func markCurrentStoryViewedIfNeeded() {
        // TODO: Implement markCurrentStoryViewedIfNeeded logic from scratch
    }

    func deleteCurrentStory() async -> Bool {
        // TODO: Implement deleteCurrentStory logic from scratch
        return false
    }

    func pause() {
        isPaused = true
    }

    func resume() {
        isPaused = false
    }
}
