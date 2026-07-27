//
//  NetworkAssembly.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Swinject
import Alamofire

// MARK: - NetworkAssembly

/// Registers networking-related dependencies:
/// - Alamofire `Session`
/// - `NetworkService` protocol
final class NetworkAssembly: Assembly {

    func assemble(container: Container) {

        // MARK: Alamofire Session

        container.register(Session.self) { _ in
            let interceptor = AuthInterceptor(
                authManager: container.resolve(AuthManagerProtocol.self)!
            )
            let monitor = NetworkEventMonitor()

            let configuration = URLSessionConfiguration.af.default
            configuration.timeoutIntervalForRequest = AppConfig.shared.timeoutInterval
            configuration.timeoutIntervalForResource = 60

            return Session(
                configuration: configuration,
                interceptor: interceptor,
                eventMonitors: [monitor]
            )
        }.inObjectScope(.container)

        // MARK: NetworkService

        container.register(NetworkServiceProtocol.self) { resolver in
            NetworkService(session: resolver.resolve(Session.self)!)
        }.inObjectScope(.container)
    }
}
