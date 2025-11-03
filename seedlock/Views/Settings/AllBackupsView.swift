//
//  AllBackupsView.swift
//  seedlock
//
//  View for displaying all backup files
//

import SwiftUI

struct AllBackupsView: View {
    let iCloudBackups: [BackupFileInfo]
    @Binding var selectedBackupURL: URL?
    @Binding var showRestoreSheet: Bool
    
    @State private var localBackups: [BackupFileInfo] = []
    @State private var isLoadingBackups = false
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.spacing12) {
                    ForEach(localBackups) { backup in
                        backupRow(backup)
                    }
                }
                .padding(.horizontal, Theme.spacing16)
                .padding(.vertical, Theme.spacing16)
            }
            .refreshable {
                await loadBackups()
            }
        }
        .navigationTitle("all_backups.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { Task { await loadBackups() } }) {
                    if isLoadingBackups {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            localBackups = iCloudBackups
        }
    }
    
    // MARK: - Backup Row
    
    private func backupRow(_ backup: BackupFileInfo) -> some View {
        HStack(spacing: Theme.spacing12) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "cloud.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.appPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(backup.dateString)
                    .font(.system(size: 17))
                    .foregroundColor(.appLabel)
                
                Text(String(format: "all_backups.mnemonics_count".localized, backup.mnemonicCount) + " • \(backup.sizeString)")
                    .font(.system(size: 13))
                    .foregroundColor(.appSecondaryLabel)
            }
            
            Spacer()
            
            Menu {
                Button(action: {
                    selectedBackupURL = backup.url
                    showRestoreSheet = true
                }) {
                    Label("backup.menu.restore".localized, systemImage: "arrow.down.doc")
                }
                
                Button(role: .destructive, action: {
                    Task { await deleteBackup(backup) }
                }) {
                    Label("backup.menu.delete".localized, systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.appSecondaryLabel)
            }
        }
        .padding(Theme.spacing16)
        .background(Color.appSurface)
        .cornerRadius(Theme.radiusMedium)
    }
    
    // MARK: - Actions
    
    private func loadBackups() async {
        isLoadingBackups = true
        do {
            let backups = try await BackupService.shared.listBackupsFromiCloudDrive()
            await MainActor.run {
                localBackups = backups
                isLoadingBackups = false
            }
        } catch {
            await MainActor.run {
                isLoadingBackups = false
            }
            print("❌ Failed to load backups: \(error)")
        }
    }
    
    private func deleteBackup(_ backup: BackupFileInfo) async {
        do {
            try await BackupService.shared.deleteBackup(at: backup.url)
            await loadBackups()
        } catch {
            print("❌ Failed to delete backup: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        AllBackupsView(
            iCloudBackups: [],
            selectedBackupURL: .constant(nil),
            showRestoreSheet: .constant(false)
        )
    }
}

