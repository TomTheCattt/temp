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

    // MARK: - Init

    init(
        stories: [Story],
        initialIndex: Int,
        fetchStoriesUseCase: FetchStoriesUseCaseProtocol
    ) {
        self.stories = stories
        self.currentStoryIndex = initialIndex
        self.fetchStoriesUseCase = fetchStoriesUseCase
    }

    // MARK: - Actions

    func loadStories() async {
        guard stories.isEmpty else { return }
        isLoading = true

        do {
            stories = try await fetchStoriesUseCase.execute()
        } catch {
            // Silent fail
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
        }
    }

    /// Move to a specific story by index.
    func jumpToStory(at index: Int) {
        guard stories.indices.contains(index) else { return }
        currentStoryIndex = index
        currentItemIndex = 0
        itemProgress = 0
    }

    func pause() {
        isPaused = true
    }

    func resume() {
        isPaused = false
    }
}
