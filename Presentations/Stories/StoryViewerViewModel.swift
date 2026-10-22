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

    private(set) var stories: [Story] = []
    private(set) var isLoading = false

    /// Index of the current story (user) being viewed.
    var currentStoryIndex: Int = 0

    /// Index of the current item within the active story.
    var currentItemIndex: Int = 0

    /// Progress for the active item (0.0 to 1.0).
    var itemProgress: Double = 0.0

    /// Whether playback is paused (e.g. user is holding down).
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
            markCurrentStoryViewedIfNeeded()
            return
        }
        isLoading = true

        do {
            let fetched = try await fetchStoriesUseCase.execute()
            let currentUserId = SessionStore.shared.currentUserId
            // Order: current user's story first, then friends' stories (Single Source of Truth with StoriesBarView)
            let myStories = fetched.filter { $0.author.id == currentUserId }
            let otherStories = fetched.filter { $0.author.id != currentUserId }
            stories = myStories + otherStories

            // Jump to target user's story if specified
            if let userId = targetUserId,
               let index = stories.firstIndex(where: { $0.author.id == userId }) {
                currentStoryIndex = index
            } else {
                currentStoryIndex = 0
            }
            markCurrentStoryViewedIfNeeded()
        } catch {
            AppLogger.general.error("StoryViewerViewModel.loadStories error: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Advance to the next item or next story.
    func goToNext() {
        guard let story = currentStory else { return }

        if currentItemIndex < story.items.count - 1 {
            // Next item in same story
            currentItemIndex += 1
            itemProgress = 0
        } else if hasNextStory {
            // Next user's story
            currentStoryIndex += 1
            currentItemIndex = 0
            itemProgress = 0
            markCurrentStoryViewedIfNeeded()
        }
        // else: reached the end — dismiss handled by view
    }

    /// Go back to previous item or previous story.
    func goToPrevious() {
        if currentItemIndex > 0 {
            // Previous item in same story
            currentItemIndex -= 1
            itemProgress = 0
        } else if hasPreviousStory {
            // Previous user's story
            currentStoryIndex -= 1
            currentItemIndex = 0
            itemProgress = 0
            markCurrentStoryViewedIfNeeded()
        }
    }

    /// Move to a specific story by index.
    func jumpToStory(at index: Int) {
        guard stories.indices.contains(index) else { return }
        currentStoryIndex = index
        currentItemIndex = 0
        itemProgress = 0
        markCurrentStoryViewedIfNeeded()
    }

    /// Mark the currently active story as viewed immediately in-memory and asynchronously persist to backend.
    func markCurrentStoryViewedIfNeeded() {
        guard let story = currentStory, !story.isViewed else { return }

        // 1. Immediately update local in-memory entity for instant UI feedback
        let updatedStory = Story(
            id: story.id,
            author: story.author,
            items: story.items,
            isViewed: true,
            createdAt: story.createdAt,
            expiresAt: story.expiresAt
        )
        if stories.indices.contains(currentStoryIndex) {
            stories[currentStoryIndex] = updatedStory
        }

        // 2. Broadcast event to StoriesBarView so circle rings transition from gradient to gray
        NotificationCenter.default.post(name: .didUpdateStoryViewed, object: story.id)

        // 3. Persist to Firestore / backend via UseCase
        let storyId = story.id
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.markStoryViewedUseCase.execute(storyId: storyId)
            } catch {
                AppLogger.network.error("Failed to mark story as viewed: \(error.localizedDescription)")
            }
        }
    }

    /// Delete the currently active story.
    /// Returns `true` if the entire stories list is now empty and the viewer should dismiss.
    func deleteCurrentStory() async -> Bool {
        guard let story = currentStory else { return false }
        let storyId = story.id
        do {
            try await deleteStoryUseCase.execute(storyId: storyId)
            stories.removeAll { $0.id == storyId }
            NotificationCenter.default.post(name: .didCreateStory, object: nil)

            if stories.isEmpty {
                return true
            }

            if currentStoryIndex >= stories.count {
                currentStoryIndex = max(0, stories.count - 1)
            }
            currentItemIndex = 0
            itemProgress = 0
            markCurrentStoryViewedIfNeeded()
            return false
        } catch {
            AppLogger.general.error("Failed to delete story: \(error.localizedDescription)")
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
