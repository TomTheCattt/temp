//
//  ServiceAssembly.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Swinject

// MARK: - ServiceAssembly

/// Registers application services (auth, permission, keychain, etc.)
final class ServiceAssembly: Assembly {

    func assemble(container: Container) {

        // MARK: KeychainManager

        container.register(KeychainManagerProtocol.self) { _ in
            KeychainManager()
        }.inObjectScope(.container)

        // MARK: AuthManager

        container.register(AuthManagerProtocol.self) { resolver in
            AuthManager(
                keychainManager: resolver.resolve(KeychainManagerProtocol.self)!,
                networkService: resolver.resolve(NetworkServiceProtocol.self)!
            )
        }.inObjectScope(.container)

        // MARK: ChatSyncService

        container.register(ChatSyncService.self) { resolver in
            ChatSyncService(
                webSocketMessageHandler: resolver.resolve(WebSocketMessageHandler.self)!,
                messageRepository: resolver.resolve(MessageRepositoryProtocol.self)!
            )
        }.inObjectScope(.container)

        // MARK: BiometricAuthenticator

        container.register(BiometricAuthenticating.self) { _ in
            BiometricAuthenticator()
        }.inObjectScope(.container)

        // MARK: ImageLoader

        container.register(ImageLoading.self) { _ in
            ImageLoader.shared
        }.inObjectScope(.container)

        // MARK: WebSocketService

        container.register(WebSocketServiceProtocol.self) { _ in
            WebSocketService()
        }.inObjectScope(.container)

        // MARK: WebSocketMessageHandler

        container.register(WebSocketMessageHandler.self) { resolver in
            WebSocketMessageHandler(
                webSocketService: resolver.resolve(WebSocketServiceProtocol.self)!
            )
        }.inObjectScope(.container)

        // MARK: WebSocketConnectionManager

        container.register(WebSocketConnectionManagerProtocol.self) { resolver in
            WebSocketConnectionManager(
                webSocketService: resolver.resolve(WebSocketServiceProtocol.self)!,
                authManager: resolver.resolve(AuthManagerProtocol.self)!
            )
        }.inObjectScope(.container)

        // MARK: LocalStorage

        container.register(LocalStorageProtocol.self) { _ in
            InMemoryStorage()
        }.inObjectScope(.container)

        // MARK: PhotoLibraryService

        container.register(PhotoLibraryServiceProtocol.self) { _ in
            PhotoLibraryService.shared
        }.inObjectScope(.container)

        container.register(PhotoLibraryService.self) { _ in
            PhotoLibraryService.shared
        }.inObjectScope(.container)

        // MARK: CallManager

        container.register(CallManager.self) { _ in
            CallManager.shared
        }.inObjectScope(.container)

        // MARK: CallMediaPipelineProtocol

        container.register(CallMediaPipelineProtocol.self) { _ in
            DefaultCallMediaPipeline.shared
        }.inObjectScope(.container)

        // MARK: CallSignalingHandlerProtocol

        container.register(CallSignalingHandlerProtocol.self) { resolver in
            let wsHandler = resolver.resolve(WebSocketMessageHandler.self)
                ?? WebSocketMessageHandler(webSocketService: resolver.resolve(WebSocketServiceProtocol.self) ?? WebSocketService())
            return WebSocketCallSignalingHandler(messageHandler: wsHandler)
        }.inObjectScope(.container)

        // MARK: CallService

        container.register(CallServiceProtocol.self) { resolver in
            let service = CallService.shared
            if let handler = resolver.resolve(CallSignalingHandlerProtocol.self) {
                service.configure(signalingHandler: handler)
            }
            return service
        }.inObjectScope(.container)

        container.register(CallService.self) { resolver in
            let service = CallService.shared
            if let handler = resolver.resolve(CallSignalingHandlerProtocol.self) {
                service.configure(signalingHandler: handler)
            }
            return service
        }.inObjectScope(.container)
    }
}
