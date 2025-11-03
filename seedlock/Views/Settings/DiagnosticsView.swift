//
//  DiagnosticsView.swift
//  seedlock
//
//  Created by AI Assistant on 25/10/2025.
//

import SwiftUI
import UIKit

struct DiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var events: [DiagnosticEvent] = []
    @State private var errorCount: Int = 0
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.spacing16) {
                    // Error Count Banner
                    if errorCount > 0 {
                        HStack {
                            Text(String(format: "diagnostics.errors_count".localized, errorCount))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.orange)
                            
                            Spacer()
                        }
                        .padding(Theme.spacing16)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(Theme.radiusMedium)
                    }
                    
                    // Events Timeline
                    VStack(spacing: 0) {
                        ForEach(events) { event in
                            eventRow(event)
                        }
                    }
                    .background(Color.appSurface)
                    .cornerRadius(Theme.radiusMedium)
                    
                    // System Information
                    VStack(spacing: 0) {
                        infoRow(label: "diagnostics.info.os".localized, value: getOSVersion())
                        
                        Divider()
                            .padding(.leading, Theme.spacing16)
                        
                        infoRow(label: "diagnostics.info.device".localized, value: getDeviceModel())
                        
                        Divider()
                            .padding(.leading, Theme.spacing16)
                        
                        infoRow(label: "diagnostics.info.app_version".localized, value: getAppVersion())
                    }
                    .background(Color.appSurface)
                    .cornerRadius(Theme.radiusMedium)
                    
                    // Export Button
                    Button(action: exportDiagnostics) {
                        Text("diagnostics.export_button".localized)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.appPrimary)
                            .cornerRadius(Theme.radiusMedium)
                    }
                }
                .padding(Theme.spacing16)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("diagnostics.title".localized)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.appLabel)
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                        Text("common.back".localized)
                            .font(.system(size: 17))
                    }
                    .foregroundColor(.appPrimary)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("diagnostics.export_button".localized) {
                    exportDiagnostics()
                }
                .foregroundColor(.appPrimary)
            }
        }
        .onAppear {
            loadDiagnosticEvents()
        }
    }
    
    // MARK: - Event Row
    
    private func eventRow(_ event: DiagnosticEvent) -> some View {
        HStack(spacing: Theme.spacing12) {
            // Icon
            ZStack {
                Circle()
                    .fill(event.type.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: event.type.icon)
                    .font(.system(size: 18))
                    .foregroundColor(event.type.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 17))
                    .foregroundColor(.appLabel)
                
                Text(event.time)
                    .font(.system(size: 13))
                    .foregroundColor(.appSecondaryLabel)
            }
            
            Spacer()
        }
        .padding(Theme.spacing16)
        .background(Color.appSurface)
    }
    
    // MARK: - Info Row
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 17))
                .foregroundColor(.appLabel)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 17))
                .foregroundColor(.appSecondaryLabel)
        }
        .padding(Theme.spacing16)
    }
    
    // MARK: - Data Loading
    
    private func loadDiagnosticEvents() {
        // Load events from DiagnosticsLogger
        events = DiagnosticsLogger.shared.getEvents()
        errorCount = events.filter { $0.type == .error }.count
    }
    
    // MARK: - System Info
    
    private func getOSVersion() -> String {
        let version = UIDevice.current.systemVersion
        return "iOS \(version)"
    }
    
    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        // Map to friendly names
        let deviceMap: [String: String] = [
            "iPhone14,2": "iPhone 13 Pro",
            "iPhone14,3": "iPhone 13 Pro Max",
            "iPhone14,4": "iPhone 13 mini",
            "iPhone14,5": "iPhone 13",
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone15,4": "iPhone 15",
            "iPhone15,5": "iPhone 15 Plus",
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",
        ]
        
        return deviceMap[identifier] ?? identifier
    }
    
    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    // MARK: - Export
    
    private func exportDiagnostics() {
        let diagnosticData = generateDiagnosticReport()
        
        // Create activity view controller
        let activityVC = UIActivityViewController(
            activityItems: [diagnosticData],
            applicationActivities: nil
        )
        
        // Present share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = window
            activityVC.popoverPresentationController?.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            activityVC.popoverPresentationController?.permittedArrowDirections = []
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func generateDiagnosticReport() -> String {
        var report = "Seedlock Diagnostics Report\n"
        report += "Generated: \(Date())\n"
        report += "================================\n\n"
        
        report += "System Information:\n"
        report += "- OS: \(getOSVersion())\n"
        report += "- Device: \(getDeviceModel())\n"
        report += "- App Version: \(getAppVersion())\n"
        report += "- Errors: \(errorCount)\n\n"
        
        report += "Events:\n"
        report += "================================\n"
        for event in events {
            report += "[\(event.time)] \(event.type.rawValue.uppercased()): \(event.title)\n"
        }
        
        return report
    }
}

// MARK: - Diagnostic Event

struct DiagnosticEvent: Identifiable {
    let id = UUID()
    let type: EventType
    let title: String
    let time: String
    let timestamp: Date
    
    enum EventType: String {
        case info
        case warning
        case error
        case success
        
        var icon: String {
            switch self {
            case .info:
                return "info.circle.fill"
            case .warning:
                return "exclamationmark.triangle.fill"
            case .error:
                return "xmark.circle.fill"
            case .success:
                return "checkmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .info:
                return .blue
            case .warning:
                return .orange
            case .error:
                return .red
            case .success:
                return .green
            }
        }
    }
}

// MARK: - Diagnostics Logger

class DiagnosticsLogger {
    static let shared = DiagnosticsLogger()
    
    private var events: [DiagnosticEvent] = []
    private let maxEvents = 100
    
    private init() {
        // Add initial events for demo
        logEvent(.success, title: "App Launched")
    }
    
    func logEvent(_ type: DiagnosticEvent.EventType, title: String) {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"
        timeFormatter.locale = LanguageManager.shared.currentLocale
        
        let event = DiagnosticEvent(
            type: type,
            title: title,
            time: timeFormatter.string(from: Date()),
            timestamp: Date()
        )
        
        events.insert(event, at: 0)
        
        // Keep only recent events
        if events.count > maxEvents {
            events.removeLast()
        }
        
        // Log to console
        print("📊 [Diagnostics] [\(type.rawValue.uppercased())] \(title)")
    }
    
    func getEvents() -> [DiagnosticEvent] {
        return events
    }
    
    func clearEvents() {
        events.removeAll()
    }
}

#Preview {
    NavigationStack {
        DiagnosticsView()
    }
}

