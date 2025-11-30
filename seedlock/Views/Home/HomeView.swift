//
//  HomeView.swift
//  seedlock
//
//  Created by Fine Ke on 24/10/2025.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var mnemonics: [Mnemonic]
    
    // Observe language changes to refresh UI
    @ObservedObject private var languageManager = LanguageManager.shared
    
    @State private var searchText = ""
    @State private var selectedFilter: FilterType = .all
    @State private var dismissedBanners: Set<String> = []
    @State private var showError = false
    @State private var isLoading = false
    @State private var showCreateSheet = false
    @State private var showImportSheet = false
    @State private var navigateToSettings = false
    @State private var selectedMnemonic: Mnemonic?
    @State private var showDeleteConfirmation = false
    @State private var mnemonicToDelete: Mnemonic?
    
    // Animation namespace for filter tabs
    @Namespace private var filterAnimation
    
    // App Storage for banner settings
    @AppStorage("cloudKitSyncEnabled") private var cloudKitSyncEnabled = false
    @AppStorage("iCloudKeychainEnabled") private var iCloudKeychainEnabled = false
    @AppStorage("lastBackupDate") private var lastBackupTimestamp: Double = 0
    @AppStorage("autoBackupEnabled") private var autoBackupEnabled = false
    
    enum FilterType: String, CaseIterable {
        case all = "All"
        case starred = "Starred"
        case archived = "Archived"
        
        var localizedName: String {
            switch self {
            case .all: return "home.filter.all".localized
            case .starred: return "home.filter.starred".localized
            case .archived: return "home.filter.archived".localized
            }
        }
    }
    
    var filteredMnemonics: [Mnemonic] {
        var filtered = mnemonics
        
        // Apply filter
        switch selectedFilter {
        case .all:
            filtered = filtered.filter { !$0.isArchived }
        case .starred:
            filtered = filtered.filter { $0.isStarred && !$0.isArchived }
        case .archived:
            filtered = filtered.filter { $0.isArchived }
        }
        
        // Apply search
        if !searchText.isEmpty {
            filtered = filtered.filter { mnemonic in
                mnemonic.name.localizedCaseInsensitiveContains(searchText) ||
                mnemonic.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return filtered
    }
    
    // MARK: - Banner Logic
    
    enum BannerType: String {
        case iCloudDisabled = "icloud_disabled"
        case backupReminder = "backup_reminder"
        case noBackupSetup = "no_backup_setup"
        case keychainDisabled = "keychain_disabled"
        case firstMnemonic = "first_mnemonic"
        case manyMnemonics = "many_mnemonics"
    }
    
    struct BannerInfo {
        let type: BannerType
        let icon: String
        let iconColor: Color
        let title: String
        let message: String
        let actionText: String
        let action: () -> Void
    }
    
    private var currentBanner: BannerInfo? {
        let hasMnemonics = !mnemonics.isEmpty
        let mnemonicCount = mnemonics.count
        let hasBackup = lastBackupTimestamp > 0
        let daysSinceBackup = hasBackup ? Int(Date().timeIntervalSince(Date(timeIntervalSince1970: lastBackupTimestamp)) / 86400) : 999
        let isSignedIntoiCloud = FileManager.default.ubiquityIdentityToken != nil
        
        // Priority 1: iCloud not signed in + has mnemonics
        if hasMnemonics && !isSignedIntoiCloud && !dismissedBanners.contains(BannerType.iCloudDisabled.rawValue) {
            return BannerInfo(
                type: .iCloudDisabled,
                icon: "exclamationmark.icloud",
                iconColor: .orange,
                title: "banner.icloud_disabled.title".localized,
                message: "banner.icloud_disabled.message".localized,
                actionText: "banner.icloud_disabled.action".localized,
                action: { openSystemSettings() }
            )
        }
        
        // Priority 2: No backup setup + has mnemonics
        if hasMnemonics && !autoBackupEnabled && !hasBackup && !dismissedBanners.contains(BannerType.noBackupSetup.rawValue) {
            return BannerInfo(
                type: .noBackupSetup,
                icon: "exclamationmark.triangle.fill",
                iconColor: .red,
                title: "banner.no_backup.title".localized,
                message: "banner.no_backup.message".localized,
                actionText: "banner.no_backup.action".localized,
                action: { navigateToSettings = true }
            )
        }
        
        // Priority 3: Backup reminder (30+ days)
        if hasMnemonics && hasBackup && daysSinceBackup > 30 && !dismissedBanners.contains(BannerType.backupReminder.rawValue) {
            return BannerInfo(
                type: .backupReminder,
                icon: "clock.arrow.circlepath",
                iconColor: .orange,
                title: "banner.backup_reminder.title".localized,
                message: String(format: "banner.backup_reminder.message".localized, daysSinceBackup),
                actionText: "banner.backup_reminder.action".localized,
                action: { navigateToSettings = true }
            )
        }
        
        // Priority 4: CloudKit disabled + has mnemonics
        if hasMnemonics && isSignedIntoiCloud && !cloudKitSyncEnabled && !dismissedBanners.contains(BannerType.keychainDisabled.rawValue) {
            return BannerInfo(
                type: .keychainDisabled,
                icon: "icloud.slash",
                iconColor: .blue,
                title: "banner.sync_disabled.title".localized,
                message: "banner.sync_disabled.message".localized,
                actionText: "banner.sync_disabled.action".localized,
                action: { navigateToSettings = true }
            )
        }
        
        // Priority 5: First mnemonic created
        if mnemonicCount == 1 && !dismissedBanners.contains(BannerType.firstMnemonic.rawValue) {
            return BannerInfo(
                type: .firstMnemonic,
                icon: "checkmark.circle.fill",
                iconColor: .green,
                title: "banner.first_mnemonic.title".localized,
                message: "banner.first_mnemonic.message".localized,
                actionText: "banner.first_mnemonic.action".localized,
                action: { dismissBanner(.firstMnemonic) }
            )
        }
        
        // Priority 6: Many mnemonics without organization
        if mnemonicCount >= 10 && mnemonics.filter({ $0.isStarred }).isEmpty && !dismissedBanners.contains(BannerType.manyMnemonics.rawValue) {
            return BannerInfo(
                type: .manyMnemonics,
                icon: "star.fill",
                iconColor: .yellow,
                title: "banner.many_mnemonics.title".localized,
                message: String(format: "banner.many_mnemonics.message".localized, mnemonicCount),
                actionText: "banner.many_mnemonics.action".localized,
                action: { dismissBanner(.manyMnemonics) }
            )
        }
        
        return nil
    }
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Smart Banner
                if let banner = currentBanner {
                    smartBannerView(banner)
                        .padding(.horizontal, Theme.spacing16)
                        .padding(.top, Theme.spacing8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Search
                searchBar
                    .padding(.horizontal, Theme.spacing16)
                    .padding(.top, Theme.spacing8)
                
                // Filter tabs
                filterTabs
                    .padding(.horizontal, Theme.spacing16)
                    .padding(.top, Theme.spacing12)
                
                // Content
                if isLoading {
                    ScrollView {
                        loadingView
                            .padding(.horizontal, Theme.spacing16)
                            .padding(.top, Theme.spacing16)
                    }
                } else if filteredMnemonics.isEmpty {
                    if showError {
                        errorView
                    } else {
                        emptyStateView
                    }
                } else {
                    mnemonicsList
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateMnemonicView()
        }
        .sheet(isPresented: $showImportSheet) {
            ImportMnemonicView()
        }
        .navigationDestination(isPresented: $navigateToSettings) {
            SettingsView()
        }
        .navigationDestination(item: $selectedMnemonic) { mnemonic in
            MnemonicDetailView(mnemonic: mnemonic)
        }
        .alert("home.delete_confirmation.title".localized, isPresented: $showDeleteConfirmation) {
            Button("common.cancel".localized, role: .cancel) {}
            Button("common.delete".localized, role: .destructive) {
                if let mnemonic = mnemonicToDelete {
                    confirmDelete(mnemonic)
                }
            }
        } message: {
            if let mnemonic = mnemonicToDelete {
                Text(String(format: "home.delete_confirmation.message".localized, mnemonic.name))
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: {
                navigateToSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.appLabel)
                    .frame(width: Theme.minTapTarget, height: Theme.minTapTarget)
            }
            
            Spacer()
            
            Text("home.title".localized)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.appLabel)
            
            Spacer()
            
            Menu {
                Button {
                    showCreateSheet = true
                } label: {
                    Label("home.create_new".localized, systemImage: "plus.circle")
                }
                
                Button {
                    showImportSheet = true
                } label: {
                    Label("home.import_existing".localized, systemImage: "square.and.arrow.down")
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: 35, height: 35)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, Theme.spacing16)
        .padding(.top, Theme.spacing8)
        .padding(.bottom, Theme.spacing12)
    }
    
    // MARK: - Smart Banner
    private func smartBannerView(_ banner: BannerInfo) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: Theme.spacing12) {
                // Icon
                Image(systemName: banner.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(banner.iconColor)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(banner.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.appLabel)
                    
                    Text(banner.message)
                        .font(.system(size: 13))
                        .foregroundColor(.appSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Action Button
                Button(action: banner.action) {
                    Text(banner.actionText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(banner.iconColor)
                        .padding(.horizontal, Theme.spacing12)
                        .padding(.vertical, Theme.spacing8)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.radiusSmall)
                                .fill(banner.iconColor.opacity(0.15))
                        )
                }
            }
            .padding(Theme.spacing16)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                    .fill(banner.iconColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusMedium)
                            .stroke(banner.iconColor.opacity(0.3), lineWidth: 1)
                    )
            )
            .overlay(
                // Close button
                Button(action: {
                    withAnimation {
                        dismissBanner(banner.type)
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.appTertiaryLabel)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color.appSurface.opacity(0.8))
                        )
                }
                .padding(8),
                alignment: .topTrailing
            )
        }
    }
    
    private func dismissBanner(_ type: BannerType) {
        dismissedBanners.insert(type.rawValue)
    }
    
    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: Theme.spacing12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.appSecondaryLabel)
                .font(.system(size: 18))
            
            TextField("home.search.placeholder".localized, text: $searchText)
                .foregroundColor(.appLabel)
                .font(.system(size: 17))
        }
        .padding(Theme.spacing16)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                .fill(Color.appSurface.opacity(0.6))
        )
    }
    
    // MARK: - Filter Tabs
    private var filterTabs: some View {
        HStack(spacing: Theme.spacing16) {
            ForEach(FilterType.allCases, id: \.self) { filter in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedFilter = filter
                    }
                }) {
                    ZStack {
                        // Background with matched geometry effect
                        if selectedFilter == filter {
                            RoundedRectangle(cornerRadius: Theme.radiusSmall)
                                .fill(Color.appPrimary)
                                .matchedGeometryEffect(id: "filterBackground", in: filterAnimation)
                                .padding(3)
                        }
                        
                        // Text
                        Text(filter.localizedName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedFilter == filter ? .white : .appSecondaryLabel)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.spacing8)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 40)
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                .fill(Color.appSurface.opacity(0.6))
        )
    }
    
    // MARK: - Mnemonics List
    private var mnemonicsList: some View {
        List {
            ForEach(filteredMnemonics) { mnemonic in
                MnemonicRowView(mnemonic: mnemonic) {
                    selectedMnemonic = mnemonic
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    // Delete action
                    Button(role: .destructive) {
                        mnemonicToDelete = mnemonic
                        showDeleteConfirmation = true
                    } label: {
                        Label("home.swipe.delete".localized, systemImage: "trash")
                    }
                    
                    // Archive/Unarchive action
                    Button {
                        toggleArchive(mnemonic)
                    } label: {
                        Label(
                            mnemonic.isArchived ? "home.swipe.unarchive".localized : "home.swipe.archive".localized,
                            systemImage: mnemonic.isArchived ? "tray.and.arrow.up" : "archivebox"
                        )
                    }
                    .tint(.orange)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: Theme.spacing24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.appSurface)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "key.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.appSecondaryLabel)
            }
            
            VStack(spacing: Theme.spacing12) {
                Text("home.empty.title".localized)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.appLabel)
                
                Text("home.empty.message".localized)
                    .font(.system(size: 15))
                    .foregroundColor(.appSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing32)
            }
            
            Spacer()
        }
        .padding(.top, 60)
    }
    
    // MARK: - Error State
    private var errorView: some View {
        VStack(spacing: Theme.spacing24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.appDanger.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.appDanger)
            }
            
            VStack(spacing: Theme.spacing12) {
                Text("home.error.title".localized)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.appLabel)
                
                Text("home.error.message".localized)
                    .font(.system(size: 15))
                    .foregroundColor(.appSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing32)
            }
            
            Button(action: {
                // Retry loading
                withAnimation {
                    showError = false
                }
            }) {
                Text("common.retry".localized)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 160)
                    .padding(.vertical, Theme.spacing16)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusMedium)
                            .fill(Color.appPrimary)
                    )
            }
            
            Spacer()
        }
        .padding(.top, 60)
    }
    
    // MARK: - Loading State
    private var loadingView: some View {
        VStack(spacing: Theme.spacing12) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonRowView()
            }
        }
    }
    
    // MARK: - Actions
    
    private func deleteMnemonic(_ mnemonic: Mnemonic) {
        mnemonicToDelete = mnemonic
        showDeleteConfirmation = true
    }
    
    private func confirmDelete(_ mnemonic: Mnemonic) {
        withAnimation {
            // Delete encryption key from keychain
            try? KeychainService.shared.deleteKey(for: mnemonic.id.uuidString)
            
            // Delete from database
            modelContext.delete(mnemonic)
            try? modelContext.save()
            
            // Log event
            DiagnosticsLogger.shared.logEvent(.warning, title: "Mnemonic Deleted")
        }
    }
    
    private func toggleArchive(_ mnemonic: Mnemonic) {
        withAnimation {
            mnemonic.isArchived.toggle()
            mnemonic.markAsUpdated()
            try? modelContext.save()
        }
    }
}

#Preview("Home with Data") {
    HomeView()
        .modelContainer(for: Mnemonic.self, inMemory: true)
}

#Preview("Home Empty") {
    let schema = Schema([Mnemonic.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    
    return HomeView()
        .modelContainer(container)
}

