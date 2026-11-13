//
//  NotesUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation

// MARK: - NotesUseCase

protocol NotesUseCaseProtocol: Sendable {
    func fetchNotes() async throws -> [InstagramNote]
    func saveNote(text: String) async throws -> InstagramNote
}

final class NotesUseCase: NotesUseCaseProtocol, Sendable {

    private let messageRepository: MessageRepositoryProtocol

    init(messageRepository: MessageRepositoryProtocol) {
        self.messageRepository = messageRepository
    }

    func fetchNotes() async throws -> [InstagramNote] {
        try await messageRepository.fetchNotes()
    }

    func saveNote(text: String) async throws -> InstagramNote {
        try await messageRepository.saveNote(text: text)
    }
}
