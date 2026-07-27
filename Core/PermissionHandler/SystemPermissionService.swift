//
//  SystemPermissionService.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 20/7/26.
//

import AVFoundation
import Contacts
import Foundation
import LocalAuthentication
import Photos
import UserNotifications

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

import CoreLocation

// MARK: - System Permission Service

/// Concrete implementation of `PermissionServiceProtocol` using real system APIs.
/// Lives in the app host because it requires platform frameworks (UIKit, CoreLocation, etc.).
final class SystemPermissionService: NSObject, PermissionServiceProtocol, @unchecked Sendable {
    private let locationManager = CLLocationManager()

    func status(for permission: PermissionType) async -> PermissionStatus {
        switch permission {
        case .camera:
            return mapAVStatus(AVCaptureDevice.authorizationStatus(for: .video))
        case .microphone:
            return mapAVStatus(AVCaptureDevice.authorizationStatus(for: .audio))
        case .photoLibrary:
            return mapPHStatus(PHPhotoLibrary.authorizationStatus(for: .readWrite))
        case .contacts:
            return mapCNStatus(CNContactStore.authorizationStatus(for: .contacts))
        case .notifications:
            return await notificationStatus()
        case .location:
            return mapCLStatus(locationManager.authorizationStatus)
        case .locationAlways:
            return mapCLAlwaysStatus(locationManager.authorizationStatus)
        case .faceID:
            return faceIDStatus()
        case .tracking:
            return trackingStatus()
        }
    }

    func request(_ permission: PermissionType) async -> PermissionStatus {
        switch permission {
        case .camera:
            await AVCaptureDevice.requestAccess(for: .video)
            return await status(for: .camera)
        case .microphone:
            await AVCaptureDevice.requestAccess(for: .audio)
            return await status(for: .microphone)
        case .photoLibrary:
            await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return await status(for: .photoLibrary)
        case .contacts:
            return await requestContacts()
        case .notifications:
            return await requestNotifications()
        case .location:
            return await requestLocation()
        case .locationAlways:
            return await requestLocationAlways()
        case .faceID:
            return await requestFaceID()
        case .tracking:
            return await requestTracking()
        }
    }

    // MARK: - Mapping Helpers

    private func mapAVStatus(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorized: return .authorized
        @unknown default: return .denied
        }
    }

    private func mapPHStatus(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorized, .limited: return .authorized
        @unknown default: return .denied
        }
    }

    private func mapCNStatus(_ status: CNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorized: return .authorized
        case .limited: return .limited
        @unknown default: return .denied
        }
    }

    private func mapCLStatus(_ status: CLAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorizedWhenInUse: return .authorizedWhenInUse
        case .authorizedAlways: return .authorized
        @unknown default: return .denied
        }
    }

    private func mapCLAlwaysStatus(_ status: CLAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorizedAlways: return .authorized
        case .notDetermined: return .notDetermined
        default: return mapCLStatus(status)
        }
    }

    private func notificationStatus() async -> PermissionStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized: return .authorized
        case .provisional: return .provisional
        case .ephemeral: return .authorized
        @unknown default: return .denied
        }
    }

    private func faceIDStatus() -> PermissionStatus {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if canEvaluate {
            return .authorized
        }
        if let error, error.code == LAError.biometryNotAvailable.rawValue {
            return .restricted
        }
        return .notDetermined
    }

    private func trackingStatus() -> PermissionStatus {
        #if canImport(AppTrackingTransparency)
        switch ATTrackingManager.trackingAuthorizationStatus {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorized: return .authorized
        @unknown default: return .denied
        }
        #else
        return .restricted
        #endif
    }

    // MARK: - Request Helpers

    private func requestContacts() async -> PermissionStatus {
        let store = CNContactStore()
        do {
            let granted = try await store.requestAccess(for: .contacts)
            return granted ? .authorized : .denied
        } catch {
            return .denied
        }
    }

    private func requestNotifications() async -> PermissionStatus {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            return granted ? .authorized : .denied
        } catch {
            return .denied
        }
    }

    private func requestLocation() async -> PermissionStatus {
        locationManager.requestWhenInUseAuthorization()
        // CLLocationManager is delegate-based; for simplicity return current status.
        // In production, use a continuation-based wrapper.
        try? await Task.sleep(nanoseconds: 500_000_000)
        return await status(for: .location)
    }

    private func requestLocationAlways() async -> PermissionStatus {
        locationManager.requestAlwaysAuthorization()
        try? await Task.sleep(nanoseconds: 500_000_000)
        return await status(for: .locationAlways)
    }

    private func requestFaceID() async -> PermissionStatus {
        let context = LAContext()
        do {
            _ = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to enable biometric login"
            )
            return .authorized
        } catch {
            return .denied
        }
    }

    private func requestTracking() async -> PermissionStatus {
        #if canImport(AppTrackingTransparency)
        let status = await ATTrackingManager.requestTrackingAuthorization()
        switch status {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
        #else
        return .restricted
        #endif
    }
}

