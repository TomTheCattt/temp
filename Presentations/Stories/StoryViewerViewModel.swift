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
        guard stories.isEmpty else {
            // Already populated via init
            markCurrentStoryViewedIfNeeded()
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await fetchStoriesUseCase.execute()
            self.stories = fetched

            if let targetUserId, let index = fetched.firstIndex(where: { $0.author.id == targetUserId }) {
                self.currentStoryIndex = index
            } else {
                self.currentStoryIndex = 0
            }
            self.currentItemIndex = 0
            self.itemProgress = 0
            markCurrentStoryViewedIfNeeded()
        } catch {
            self.stories = []
        }
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
        guard let story = currentStory, !story.isViewed else { return }

        // Optimistically mark as viewed in memory
        stories[currentStoryIndex].isViewed = true

        let storyId = story.id
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.markStoryViewedUseCase.execute(storyId: storyId)
                NotificationCenter.default.post(name: .didUpdateStoryViewed, object: storyId)
            } catch {
                // Silently ignore view receipt failures
            }
        }
    }

    func deleteCurrentStory() async -> Bool {
        guard let story = currentStory else { return false }
        do {
            try await deleteStoryUseCase.execute(storyId: story.id)
            stories.remove(at: currentStoryIndex)
            NotificationCenter.default.post(name: .didCreateStory, object: nil)

            if stories.isEmpty {
                return true
            }
            if currentStoryIndex >= stories.count {
                currentStoryIndex = max(0, stories.count - 1)
            }
            currentItemIndex = 0
            itemProgress = 0
            return false
        } catch {
            return false
        }
    }

    func pause() {
        isPaused = true
    }

    func resume() {
        isPaused = false
    }
}
