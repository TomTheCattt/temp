//
//  DIContainer.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Swinject

// MARK: - DIContainer

/// Centralized Dependency Injection container.
/// All module assemblies are registered here at app launch.
final class DIContainer: @unchecked Sendable {

    static let shared = DIContainer()

    let container: Container

    private init() {
        container = Container()
        registerAssemblies()
    }

    // MARK: - Registration

    private func registerAssemblies() {
        let assemblies: [Assembly] = [
            NetworkAssembly(),
            ServiceAssembly(),
            RepositoryAssembly(),
            UseCaseAssembly(),
            ViewModelAssembly()
        ]

        assemblies.forEach { $0.assemble(container: container) }
    }

    // MARK: - Resolve

    /// Resolve a dependency. Crashes in DEBUG if not registered (fail-fast).
    func resolve<T>(_ type: T.Type) -> T {
        guard let instance = container.resolve(type) else {
            #if DEBUG
            fatalError("[DIContainer] Failed to resolve \(type). Did you register it?")
            #else
            AppLogger.general.error("Failed to resolve \(String(describing: type))")
            fatalError("Dependency resolution failed")
            #endif
        }
        return instance
    }

    /// Resolve with a name qualifier.
    func resolve<T>(_ type: T.Type, name: String) -> T {
        guard let instance = container.resolve(type, name: name) else {
            #if DEBUG
            fatalError("[DIContainer] Failed to resolve \(type) with name '\(name)'.")
            #else
            AppLogger.general.error("Failed to resolve \(String(describing: type)) name=\(name)")
            fatalError("Dependency resolution failed")
            #endif
        }
        return instance
    }

    /// Optional resolve — returns nil if not registered.
    func resolveOptional<T>(_ type: T.Type) -> T? {
        container.resolve(type)
    }
}

// MARK: - Convenience accessor

/// Shorthand for `DIContainer.shared.resolve(...)`.
@propertyWrapper
struct Injected<T> {
    private let instance: T

    init() {
        self.instance = DIContainer.shared.resolve(T.self)
    }

    var wrappedValue: T { instance }
}
