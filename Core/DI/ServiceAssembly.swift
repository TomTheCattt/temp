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

        container.register(KeychainManager.self) { _ in
            KeychainManager()
        }.inObjectScope(.container)

        // MARK: AuthManager

        container.register(AuthManagerProtocol.self) { resolver in
            AuthManager(
                keychainManager: resolver.resolve(KeychainManager.self)!
            )
        }.inObjectScope(.container)

        // MARK: BiometricAuthenticator

        container.register(BiometricAuthenticator.self) { _ in
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

        // MARK: LocalStorage

        container.register(LocalStorageProtocol.self) { _ in
            InMemoryStorage()
        }.inObjectScope(.container)
    }
}
