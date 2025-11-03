//
//  AboutPrivacyView.swift
//  seedlock
//
//  Created by Fine Ke on 25/10/2025.
//

import SwiftUI
import MessageUI

struct AboutPrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showMailComposer = false
    @State private var showMailError = false
    
    // Computed properties for app info
    private var appName: String {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ??
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Seedlock"
    }
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (Build \(build))"
    }
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Offline Notice Banner
                    // HStack(spacing: Theme.spacing12) {
                    //     Image(systemName: "wifi.slash")
                    //         .font(.system(size: 20))
                    //         .foregroundColor(.blue)
                        
                    //     Text("You are currently offline. Displayed information may be cached.")
                    //         .font(.system(size: 15))
                    //         .foregroundColor(.blue)
                    //         .fixedSize(horizontal: false, vertical: true)
                        
                    //     Spacer()
                    // }
                    // .padding(Theme.spacing16)
                    // .background(
                    //     RoundedRectangle(cornerRadius: Theme.radiusMedium)
                    //         .fill(Color.blue.opacity(0.15))
                    // )
                    // .padding(.horizontal, Theme.spacing16)
                    // .padding(.top, Theme.spacing16)
                    
                    // Zero-Knowledge Promise
                    VStack(alignment: .leading, spacing: Theme.spacing12) {
                        Text("about.zero_knowledge.title".localized)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.appLabel)
                        
                        Text("about.zero_knowledge.description".localized)
                            .font(.system(size: 15))
                            .foregroundColor(.appSecondaryLabel)
                            .lineSpacing(6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.spacing16)
                    .padding(.top, Theme.spacing8)
                    
                    // Secure Data Storage
                    VStack(alignment: .leading, spacing: Theme.spacing12) {
                        Text("about.secure_storage.title".localized)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.appLabel)
                        
                        Text("about.secure_storage.description".localized)
                            .font(.system(size: 15))
                            .foregroundColor(.appSecondaryLabel)
                            .lineSpacing(6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.spacing16)
                    
                    // Anonymous Logging
                    VStack(alignment: .leading, spacing: Theme.spacing12) {
                        Text("about.anonymous_logging.title".localized)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.appLabel)
                        
                        Text("about.anonymous_logging.description".localized)
                            .font(.system(size: 15))
                            .foregroundColor(.appSecondaryLabel)
                            .lineSpacing(6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.spacing16)
                    
                    // Legal & Licenses Section
                    VStack(alignment: .leading, spacing: Theme.spacing16) {
                        Text("about.legal_licenses".localized)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.appLabel)
                            .padding(.horizontal, Theme.spacing16)
                        
                        VStack(spacing: 0) {
                            NavigationLink(destination: TermsOfServiceView()) {
                                LegalRowView(
                                    icon: "doc.text",
                                    title: "about.terms_of_service".localized
                                )
                            }
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            NavigationLink(destination: PrivacyPolicyView()) {
                                LegalRowView(
                                    icon: "hand.raised.fill",
                                    title: "about.privacy_policy".localized
                                )
                            }
                            
//                            Divider()
//                                .padding(.leading, 56)
//                            
//                            Button(action: {
//                                // Open Open Source Licenses
//                                if let url = URL(string: "https://example.com/licenses") {
//                                    UIApplication.shared.open(url)
//                                }
//                            }) {
//                                LegalRowView(
//                                    icon: "chevron.left.forwardslash.chevron.right",
//                                    title: "about.open_source_licenses".localized
//                                )
//                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                .fill(Color.appSurface)
                        )
                        .padding(.horizontal, Theme.spacing16)
                    }
                    .padding(.top, Theme.spacing8)
                    
                    // Contact & Feedback Section
                    VStack(alignment: .leading, spacing: Theme.spacing16) {
                        Text("about.contact_feedback".localized)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.appLabel)
                        
                        Text("about.contact_description".localized)
                            .font(.system(size: 15))
                            .foregroundColor(.appSecondaryLabel)
                            .lineSpacing(6)
                        
                        Button(action: {
                            sendFeedback()
                        }) {
                            Text("about.send_feedback".localized)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.spacing16)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                        .fill(Color.appPrimary)
                                )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.spacing16)
                    .padding(.top, Theme.spacing8)
                    
                    // App Version
                    Text("\(appName) v\(appVersion)")
                        .font(.system(size: 13))
                        .foregroundColor(.appTertiaryLabel)
                        .padding(.top, Theme.spacing24)
                        .padding(.bottom, Theme.spacing32)
                }
            }
        }
        .navigationTitle("about.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMailComposer) {
            MailComposeView()
        }
        .alert("about.mail_error.title".localized, isPresented: $showMailError) {
            Button("common.ok".localized, role: .cancel) { }
        } message: {
            Text("about.mail_error.message".localized)
        }
    }
    
    private func sendFeedback() {
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            showMailError = true
        }
    }
}

// MARK: - Legal Row View

struct LegalRowView: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: Theme.spacing12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.appPrimary)
            }
            
            Text(title)
                .font(.system(size: 17))
                .foregroundColor(.appLabel)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.appTertiaryLabel)
        }
        .padding(.horizontal, Theme.spacing16)
        .padding(.vertical, Theme.spacing12)
        .contentShape(Rectangle())
    }
}

// MARK: - Mail Compose View

struct MailComposeView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients(["litesky@foxmail.com"])
        composer.setSubject("Seedlock App Feedback")
        
        // Get app version info
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        
        // Add device info
        let deviceInfo = """
        
        
        ---
        Device: \(UIDevice.current.model)
        iOS: \(UIDevice.current.systemVersion)
        App Version: \(version) (Build \(build))
        """
        composer.setMessageBody(deviceInfo, isHTML: false)
        
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        AboutPrivacyView()
    }
}

