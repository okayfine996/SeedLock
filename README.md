# Seedlock - Secure Mnemonic Manager

<div align="center">

**Zero-Knowledge Encrypted iOS Mnemonic Manager**

Secure · Simple · Reliable

[Features](#features) • [Installation](#installation) • [Usage Guide](#usage-guide) • [Architecture](#architecture) • [Security](#security)

</div>

---

## Overview

Seedlock is an iOS mnemonic phrase management application designed specifically for cryptocurrency users. It employs a zero-knowledge encryption architecture to ensure your mnemonic phrases are securely stored locally and in iCloud, while supporting automatic cross-device recovery.

### Core Principles

- **Zero-Knowledge Encryption**: Keys stored in iCloud Keychain, plaintext never uploaded
- **Biometric Protection**: Face ID/Touch ID dual protection
- **Automatic Recovery**: Automatic sync across devices with same Apple ID
- **Simple & Intuitive**: Modern iOS design with smooth user experience

## Features

### 🔐 Security First

- **AES-GCM 256-bit Encryption**: Each mnemonic uses an independent key
- **iCloud Keychain**: Secure key sync across devices
- **Biometric Authentication**: Face ID/Touch ID required to view mnemonics
- **Auto-Lock**: 30-second countdown, immediate lock on background
- **Clipboard Protection**: Configurable auto-clear (10-120 seconds)

### 📱 Complete Features

#### Mnemonic Management
- ✅ Create new mnemonics (12/15/18/21/24 words)
- ✅ Import existing mnemonics (BIP-39 standard validation)
- ✅ Edit name, tags, and notes
- ✅ Secure view and copy
- ✅ Delete with confirmation

#### Organization
- ✅ Tag categories (up to 5 tags)
- ✅ Star favorites
- ✅ Search and filter
- ✅ Three-way filter (All/Starred/Archived)

#### User Experience
- ✅ Full Dark Mode support
- ✅ Smooth animations
- ✅ Loading state feedback
- ✅ Friendly error messages
- ✅ Empty state guidance

## Installation

### System Requirements

- iOS 17.0 or later
- iPhone or iPad
- Face ID or Touch ID (recommended)
- iCloud account (for cross-device sync)

### Build Steps

1. Clone the repository
```bash
git clone https://github.com/okayfine996/SeedLock.git
cd seedlock
```

2. Open Xcode project
```bash
open seedlock.xcodeproj
```

3. Configure signing
   - Select your development team
   - Configure Bundle Identifier
   - Enable capabilities:
     - iCloud
     - Keychain Sharing

4. Run the project
   - Select target device or simulator
   - Press ⌘R to run

## Usage Guide

### First Time Use

1. **Open the app**: Welcome screen appears on first launch
2. **Add mnemonic**: Tap the "+" button in top right
3. **Choose method**: 
   - **Create New**: Automatically generate a secure mnemonic
   - **Import Existing**: Paste or type an existing mnemonic

### Viewing Mnemonics

1. **Select mnemonic**: Tap on a mnemonic in the list
2. **Biometric auth**: Tap "Show Mnemonic", authenticate with Face ID/Touch ID
3. **View and copy**: Mnemonic displays for 30 seconds, can copy to clipboard
4. **Auto-lock**: Automatically hides after 30 seconds or when backgrounded

### Managing Mnemonics

#### Edit
- Tap "Edit" in top right of detail page
- Modify name, tags, or notes
- Save changes

#### Delete
- Tap "Delete Mnemonic" at bottom of detail page
- Confirm deletion
- ⚠️ Cannot be recovered after deletion

#### Organize
- **Add tags**: Select or create tags while editing
- **Star favorites**: Tap the star icon
- **Search**: Use search bar to filter by name or tags

### Settings

Access settings page to configure:

#### Security Settings
- **App Launch Lock**: Require biometric auth on app launch
- **Clipboard Clear Time**: Choose 10/30/60/120 seconds
- **Screenshot Warning**: Show alert when screenshot taken

#### Data & Sync
- **iCloud Keychain Status**: Check key sync status
- **iCloud Account**: Ensure logged in to enable sync

## Architecture

### Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Database**: SwiftData
- **Encryption**: CryptoKit (AES-GCM)
- **Storage**: Keychain Services
- **Authentication**: LocalAuthentication

### Project Structure

```
seedlock/
├── Models/              # Data models
│   └── Mnemonic.swift
├── Services/            # Business logic
│   ├── CryptoService.swift      # Encryption service
│   ├── KeychainService.swift    # Keychain management
│   ├── BiometricService.swift   # Biometric auth
│   ├── ClipboardService.swift   # Clipboard management
│   └── BIP39Service.swift       # BIP-39 implementation
├── ViewModels/          # View models
│   └── MnemonicViewModel.swift
├── Views/               # User interface
│   ├── Home/           # Home page
│   ├── Detail/         # Detail page
│   ├── Create/         # Create/Import
│   ├── Edit/           # Edit
│   └── Settings/       # Settings
└── Core/                # Core components
    └── Theme.swift      # Theme system
```

### Design Patterns

- **MVVM Architecture**: Separation of views and business logic
- **Protocol-Oriented**: Protocol-oriented programming
- **Dependency Injection**: Service dependency injection
- **Singleton Services**: Singleton service management

## Security

### Encryption Scheme

```
Mnemonic → AES-GCM Encryption → Ciphertext Storage (Local/iCloud)
                ↑
           DEK Key → iCloud Keychain Sync
```

### Data Flow

1. **Create/Import**
   - Generate random DEK key
   - Encrypt mnemonic plaintext with DEK
   - Save DEK to iCloud Keychain
   - Save ciphertext to SwiftData (can sync to iCloud)

2. **View**
   - Biometric authentication
   - Retrieve DEK from Keychain
   - Decrypt ciphertext to get plaintext
   - Plaintext only in memory, never written to disk
   - Clear memory after 30 seconds

3. **Cross-Device Recovery**
   - iCloud auto-syncs ciphertext
   - iCloud Keychain auto-syncs DEK
   - Devices with same Apple ID can fully recover

### Security Features

- ✅ Plaintext never uploaded
- ✅ Independent key per mnemonic
- ✅ Mandatory biometric auth
- ✅ Auto-lock mechanism
- ✅ Clipboard protection
- ✅ Zero logging

## Privacy Policy

### Data Collection

Seedlock **does not collect** any personal data:
- ❌ No mnemonic collection
- ❌ No encryption key collection
- ❌ No user information collection
- ❌ No third-party analytics

### Data Storage

- **Local**: SwiftData (encrypted ciphertext)
- **iCloud**: CloudKit Private Database (ciphertext)
- **Keychain**: iCloud Keychain (encryption keys)

All data is stored only on your devices and Apple services. Developers cannot access it.

## FAQ

### Q: What if I forget my password?
A: Seedlock doesn't use passwords, it uses Face ID/Touch ID. If biometric fails, you can use your device passcode as backup.

### Q: How to recover after getting a new phone?
A: Log in to the new device with the same Apple ID, iCloud will automatically sync data. Ensure both iCloud and iCloud Keychain are enabled.

### Q: Can I use it without iCloud?
A: Yes, but data is only saved locally and cannot sync or recover across devices.

### Q: Is data uploaded to developer servers?
A: No. All data is stored only on your devices and Apple iCloud.

### Q: How many mnemonics are supported?
A: No limit, depends on your device storage.

### Q: Is mnemonic export supported?
A: Current version supports viewing and copying. Future versions will support encrypted export.

## Roadmap

### v1.0 ✅ (Current Version)
- ✅ Basic mnemonic management
- ✅ AES-GCM encryption
- ✅ Biometric authentication
- ✅ iCloud Keychain integration
- ✅ Search and filter
- ✅ Tag management

### v1.1 (Planned)
- [ ] OCR image recognition import
- [ ] Recovery codes (Keychain fallback)
- [ ] Local encrypted export
- [ ] Chinese/Japanese/Korean support
- [ ] CloudKit sync status indicator

### v1.2 (Future)
- [ ] iPad optimization
- [ ] Widget support
- [ ] Shortcuts integration
- [ ] Backup reminders
- [ ] More themes

## Contributing

Issues and Pull Requests are welcome!

### Contribution Guidelines

1. Fork the project
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) file for details.

## Acknowledgments

- BIP-39 standard word list
- Apple CryptoKit framework
- SwiftUI and SwiftData

## Contact

- **Issues**: [GitHub Issues](https://github.com/okayfine996/SeedLock/issues)
- **Email**: support@seedlock.app
- **Twitter**: [@seedlock_app](https://twitter.com/seedlock_app)

---

<div align="center">

Made with ❤️ by the Seedlock Team

**Protect Your Digital Assets - Start with Secure Mnemonic Storage**

</div>
