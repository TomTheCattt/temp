//
//  BiometricAuthenticator.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 20/7/26.
//

import Foundation
import LocalAuthentication

public enum BiometricPolicy: Sendable {
    case biometricsOnly
    case biometricsOrDevicePasscode

    var localAuthenticationPolicy: LAPolicy {
        switch self {
        case .biometricsOnly:
            return .deviceOwnerAuthenticationWithBiometrics
        case .biometricsOrDevicePasscode:
            return .deviceOwnerAuthentication
        }
    }
}

public protocol BiometricAuthenticating: Sendable {
    func canAuthenticate(policy: BiometricPolicy) -> Bool
    func authenticate(reason: String, policy: BiometricPolicy) async throws -> Bool
}

public struct BiometricAuthenticator: BiometricAuthenticating, Sendable {
    public init() {}

    public func canAuthenticate(policy: BiometricPolicy) -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(policy.localAuthenticationPolicy, error: &error)
    }

    public func authenticate(reason: String, policy: BiometricPolicy) async throws -> Bool {
        let context = LAContext()
        return try await context.evaluatePolicy(
            policy.localAuthenticationPolicy,
            localizedReason: reason
        )
    }
}
