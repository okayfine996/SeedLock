//
//  LoggerService.swift
//  seedlock
//
//  Unified logging service for better debugging and monitoring
//

import Foundation
import os.log

/// Unified logging service for the app
final class LoggerService {
    static let shared = LoggerService()
    
    private let osLog: OSLog
    private let dateFormatter: DateFormatter
    
    private init() {
        // Use subsystem and category for better log organization
        self.osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.seedlock", category: "app")
        
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    }
    
    // MARK: - Log Levels
    
    /// Log a debug message (only in debug builds)
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: Source file (auto-filled)
    ///   - function: Source function (auto-filled)
    ///   - line: Source line (auto-filled)
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        log(level: .debug, message: message, file: file, function: function, line: line)
        #endif
    }
    
    /// Log an info message
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: Source file (auto-filled)
    ///   - function: Source function (auto-filled)
    ///   - line: Source line (auto-filled)
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }
    
    /// Log a warning message
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: Source file (auto-filled)
    ///   - function: Source function (auto-filled)
    ///   - line: Source line (auto-filled)
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }
    
    /// Log an error message
    /// - Parameters:
    ///   - message: The message to log
    ///   - error: Optional error object
    ///   - file: Source file (auto-filled)
    ///   - function: Source function (auto-filled)
    ///   - line: Source line (auto-filled)
    func error(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let fullMessage = error != nil ? "\(message) - \(error!.localizedDescription)" : message
        log(level: .error, message: fullMessage, file: file, function: function, line: line)
    }
    
    /// Log a success message
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: Source file (auto-filled)
    ///   - function: Source function (auto-filled)
    ///   - line: Source line (auto-filled)
    func success(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .success, message: message, file: file, function: function, line: line)
    }
    
    // MARK: - Private Methods
    
    private func log(level: LogLevel, message: String, file: String, function: String, line: Int) {
        let fileName = (file as NSString).lastPathComponent
        let timestamp = dateFormatter.string(from: Date())
        
        // Format: [TIMESTAMP] EMOJI [FILE:LINE] MESSAGE
        let formattedMessage = "[\(timestamp)] \(level.emoji) [\(fileName):\(line)] \(message)"
        
        // Console output
        print(formattedMessage)
        
        // System log (for Console.app and debugging)
        os_log("%{public}@", log: osLog, type: level.osLogType, formattedMessage)
        
        // Store in diagnostics if it's an important event
        if level == .error || level == .warning || level == .success {
            let diagnosticType: DiagnosticEvent.EventType = {
                switch level {
                case .error: return .error
                case .warning: return .warning
                case .success: return .success
                default: return .info
                }
            }()
            
            DiagnosticsLogger.shared.logEvent(diagnosticType, title: message)
        }
    }
}

// MARK: - Log Level

enum LogLevel {
    case debug
    case info
    case warning
    case error
    case success
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .success: return "✅"
        }
    }
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .success: return .info
        }
    }
}

// MARK: - Convenience Extensions

extension LoggerService {
    /// Log the start of an operation
    func logOperationStart(_ operation: String, file: String = #file, line: Int = #line) {
        info("🔄 Starting: \(operation)", file: file, line: line)
    }
    
    /// Log the completion of an operation
    func logOperationComplete(_ operation: String, duration: TimeInterval? = nil, file: String = #file, line: Int = #line) {
        if let duration = duration {
            success("✅ Completed: \(operation) (took \(String(format: "%.2f", duration))s)", file: file, line: line)
        } else {
            success("✅ Completed: \(operation)", file: file, line: line)
        }
    }
    
    /// Log an operation failure
    func logOperationFailed(_ operation: String, error: Error, file: String = #file, line: Int = #line) {
        self.error("❌ Failed: \(operation)", error: error, file: file, line: line)
    }
}

// MARK: - Global Helper Functions

/// Quick debug log (only in debug builds)
func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    LoggerService.shared.debug(message, file: file, function: function, line: line)
}

/// Quick info log
func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    LoggerService.shared.info(message, file: file, function: function, line: line)
}

/// Quick warning log
func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    LoggerService.shared.warning(message, file: file, function: function, line: line)
}

/// Quick error log
func logError(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    LoggerService.shared.error(message, error: error, file: file, function: function, line: line)
}

/// Quick success log
func logSuccess(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    LoggerService.shared.success(message, file: file, function: function, line: line)
}

