//
//  CallHistoryViewModel.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation
import Observation

// MARK: - CallHistoryViewModel

@MainActor
@Observable
final class CallHistoryViewModel {

    // MARK: - State
    var calls: [CallHistoryItem] = []
    var filteredCalls: [CallHistoryItem] = []
    var selectedFilter: Filter = .all
    var isLoading = false
    var errorMessage: String?
    var selectedCall: CallHistoryItem?

    // MARK: - Dependencies
    private let callHistoryUseCase: CallHistoryUseCaseProtocol

    // MARK: - Init
    init(callHistoryUseCase: CallHistoryUseCaseProtocol) {
        self.callHistoryUseCase = callHistoryUseCase
    }

    // MARK: - Filters
    enum Filter: CaseIterable {
        case all
        case video
        case audio
        case missed

        var title: String {
            switch self {
            case .all: return "All"
            case .video: return "Video"
            case .audio: return "Audio"
            case .missed: return "Missed"
            }
        }

        var icon: String {
            switch self {
            case .all: return "phone"
            case .video: return "video"
            case .audio: return "phone"
            case .missed: return "phone.badge.xmark"
            }
        }
    }

    // MARK: - Actions
    func loadCalls() async {
        isLoading = true
        errorMessage = nil

        do {
            calls = try await callHistoryUseCase.fetchCallHistory()
            applyFilter()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func applyFilter() {
        switch selectedFilter {
        case .all:
            filteredCalls = calls
        case .video:
            filteredCalls = calls.filter { $0.type == .video }
        case .audio:
            filteredCalls = calls.filter { $0.type == .audio }
        case .missed:
            filteredCalls = calls.filter { $0.isMissed }
        }
    }

    func selectCall(_ call: CallHistoryItem) {
        selectedCall = call
    }

    func deleteCall(id: String) async {
        do {
            try await callHistoryUseCase.deleteCallHistory(id: id)
            calls.removeAll { $0.id == id }
            applyFilter()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearHistory() {
        Task {
            do {
                try await callHistoryUseCase.clearCallHistory()
                calls.removeAll()
                filteredCalls.removeAll()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
