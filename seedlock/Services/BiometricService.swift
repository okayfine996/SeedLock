//
//  BiometricService.swift
//  seedlock
//
//  Created by Fine Ke on 24/10/2025.
//

import Foundation
import LocalAuthentication

/// Service for handling biometric authentication (Face ID/Touch ID)
final class BiometricService {
    static let shared = BiometricService()
    
    private init() {}
    
    // MARK: - Biometric Type
    
    enum BiometricType {
        case faceID
        case touchID
        case none
        
        var displayName: String {
            switch self {
            case .faceID:
                return "Face ID"
            case .touchID:
                return "Touch ID"
            case .none:
                return "Biometric Authentication"
            }
        }
    }
    
    // MARK: - Check Availability
    
    /// Checks if biometric authentication is available on this device
    /// - Returns: True if biometrics are available
    func isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// Gets the type of biometric authentication available
    /// - Returns: The biometric type (Face ID, Touch ID, or none)
    func biometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }
    
    // MARK: - Authentication
    
    /// Authenticates the user using biometrics
    /// - Parameters:
    ///   - reason: The reason for authentication to display to the user
    ///   - completion: Callback with success/failure result
    func authenticate(reason: String, completion: @escaping (Result<Void, BiometricError>) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                completion(.failure(.notAvailable(error.localizedDescription)))
            } else {
                completion(.failure(.notAvailable("Biometric authentication is not available")))
            }
            return
        }
        
        // Perform authentication
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(.success(()))
                } else {
                    if let error = error as? LAError {
                        completion(.failure(self.mapLAError(error)))
                    } else {
                        completion(.failure(.unknown))
                    }
                }
            }
        }
    }
    
    // MARK: - Error Mapping
    
    private func mapLAError(_ error: LAError) -> BiometricError {
        switch error.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancelled
        case .userFallback:
            return .userFallback
        case .biometryNotAvailable:
            return .notAvailable("Biometric authentication is not available")
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .lockout
        default:
            return .unknown
        }
    }
}

// MARK: - Errors

enum BiometricError: LocalizedError {
    case notAvailable(String)
    case authenticationFailed
    case userCancelled
    case userFallback
    case notEnrolled
    case lockout
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .notAvailable(let message):
            return message
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .userCancelled:
            return "Authentication was cancelled"
        case .userFallback:
            return "User requested fallback authentication"
        case .notEnrolled:
            return "Biometric authentication is not set up on this device"
        case .lockout:
            return "Biometric authentication is locked. Please try again later."
        case .unknown:
            return "An unknown error occurred during authentication"
        }
    }
}

