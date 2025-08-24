[![Build Status](https://travis-ci.org/shpakovski/MASShortcut.svg?branch=master)](https://travis-ci.org/shpakovski/MASShortcut)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# MASShortcut - Modern Swift 6 Keyboard Shortcut Framework

[![Swift 6](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://developer.apple.com/macos/)
[![SPM](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Tests](https://img.shields.io/badge/Tests-17%20passed-success.svg)](https://github.com/shpakovski/MASShortcut)

**MASShortcut** is a modern, fully Swift 6-native framework for managing global keyboard shortcuts on macOS. Originally inspired by [ShortcutRecorder](http://wafflesoftware.net/shortcut/), it has been completely rewritten with modern Swift concurrency, value semantics, and type safety.

![Screenshot of the demo project](https://raw.githubusercontent.com/shpakovski/MASShortcut/master/Demo/screenshot.png "This is how the demo looks like")

## ✨ Key Features

### 🚀 Modern Swift 6 Architecture
- **Value Semantics**: `MASShortcut` is now a `struct` with full `Sendable` compliance
- **Async/Await**: Modern asynchronous programming with proper error handling
- **Result Types**: Type-safe error handling throughout the API
- **Builder Patterns**: Fluent, chainable APIs for creating shortcuts
- **KeyPath Support**: Dynamic property access and transformation
- **Protocol-Oriented Design**: Extensible architecture with clear abstractions

### 🎯 Core Functionality
- 🎹 **Global Shortcuts**: System-wide keyboard shortcut registration and monitoring
- 🎨 **UI Components**: Modern SwiftUI-ready shortcut recording interfaces
- 🔄 **Persistence**: Seamless integration with UserDefaults and custom storage
- ✅ **Validation**: Comprehensive shortcut validation with contextual rules
- 🔧 **Compatibility**: Full compatibility with legacy Shortcut Recorder format

### 🛡️ Safety & Performance
- **Thread Safety**: Complete Sendable compliance for concurrent programming
- **Memory Efficiency**: Value types and immutability for optimal performance
- **Type Safety**: Compile-time guarantees with strong typing
- **Error Handling**: Comprehensive error types with detailed diagnostics

Partially done:

* Accessibility support. There’s some basic accessibility code, testers and feedback welcome.
* Localisation. The English and Czech localization should be complete, there’s basic support for German, French, Spanish, Italian, and Japanese. If you’re a native speaker in one of the mentioned languages, please test the localization and report issues or add missing strings.

Pull requests welcome :)

# Installation

## 📦 Installation

### Swift Package Manager (Recommended)
[Swift Package Manager](https://swift.org/package-manager/) is the simplest way to install for Xcode projects. Simply add the following Package Dependency:

```swift
dependencies: [
    .package(url: "https://github.com/Meapri/MASShortcut-Swift.git", from: "3.0.2")
]
```

#### System Requirements
- **Xcode**: 15.0+
- **macOS**: 13.0+
- **Swift**: 6.0+ (with strict concurrency checking)
- **Platform**: Intel & Apple Silicon (Universal Binary)

### ✅ Swift 6 Compatibility
MASShortcut v3.0.2+ is **fully compatible** with Swift 6's strict concurrency checking:

- ✅ **Sendable Protocol Compliance**: All types properly conform to `Sendable`
- ✅ **Thread Safety**: Protected mutable state with locks and actor isolation
- ✅ **Async/Await Support**: Modern async APIs with proper error handling
- ✅ **Backward Compatibility**: Legacy APIs remain fully functional
- ✅ **Zero Warnings**: Compiles cleanly with Swift 6 strict concurrency mode

#### Integration
1. Open your Xcode project
2. Go to **File > Add Packages**
3. Enter `https://github.com/Meapri/MASShortcut-Swift.git`
4. Choose the latest version (3.0.2+ for Swift 6 support)
5. Add to your target

### Command Line Installation
```bash
# Clone and build
git clone https://github.com/Meapri/MASShortcut-Swift.git
cd MASShortcut-Swift
swift build --configuration release
```


### CocoaPods
You can also use [CocoaPods](http://cocoapods.org/), by adding the following line to your Podfile:

    pod 'MASShortcut'

If you want to stick to the 1.x branch, you can use the version smart match operator:

    pod 'MASShortcut', '~> 1'

### Carthage
You can also install via [Carthage](https://github.com/Carthage/Carthage), or you can use Git submodules and link against the MASShortcut framework manually.

To build from the command line, type 'make release'. The framework will be created in a temporary directory and revealed in Finder when the build is complete.

# 📖 Usage Guide

## 🚀 Quick Start

### Modern Async/Await API
```swift
import MASShortcut

// 1. Create a shortcut using the builder pattern
let shortcut = MASShortcut.composed { composer in
    composer.key(kVK_ANSI_A).command().shift()
}

// 2. Register with async/await
do {
    let registration = try await MASShortcutMonitor.shared.registerShortcut(shortcut) {
        print("Command + Shift + A was pressed!")
    }

    // Keep the registration alive
    self.currentRegistration = registration
} catch {
    print("Failed to register shortcut: \(error)")
}
```

### Builder Pattern
```swift
// Using Result-based builder
let result = MASShortcut.build { builder in
    builder.key(kVK_ANSI_C)      // 'C' key
    builder.command()            // ⌘
    builder.option()             // ⌥
    builder.shift()              // ⇧
}

switch result {
case .success(let shortcut):
    print("Created: \(shortcut)")
case .failure(let error):
    print("Error: \(error)")
}
```

### KeyPath-Based Operations
```swift
let original = MASShortcut(keyCode: kVK_ANSI_X, modifierFlags: .command)

// Transform using key paths
let modified = original
    .with(\.keyCode, value: kVK_ANSI_V)           // Change to 'V'
    .map(\.modifierFlags) { $0.union(.shift) }    // Add shift

// Access properties dynamically
let keyCode = original[keyPath: \.keyCode]
let isCommandOnly = original[\.modifierFlags] == .command
```

## 🎯 Advanced Usage

### Multiple Shortcuts with Higher-Order APIs
```swift
let shortcuts = [
    MASShortcut.composed { $0.key(kVK_ANSI_N).command() },      // ⌘N
    MASShortcut.composed { $0.key(kVK_ANSI_O).command() },      // ⌘O
    MASShortcut.composed { $0.key(kVK_ANSI_S).command() }       // ⌘S
]

let registrations = try await MASShortcutMonitor.shared.registerShortcuts(shortcuts) { shortcut in
    {
        switch shortcut.keyCode {
        case kVK_ANSI_N: print("New document")
        case kVK_ANSI_O: print("Open document")
        case kVK_ANSI_S: print("Save document")
        default: break
        }
    }
}
```

### Contextual Validation
```swift
let shortcut = MASShortcut.composed { $0.key(kVK_ANSI_Q).command() }

// Different validation contexts
let contexts = [
    ValidationContext.default,           // Standard validation
    ValidationContext.lenient,           // Permissive validation
    ValidationContext(allowSystemShortcuts: true, allowServiceMenuOverrides: true, allowOptionModifier: true)
]

for context in contexts {
    let result = await MASShortcutValidator.shared.validateForContext(shortcut, context: context)
    print("\(context): \(result)")
}
```

### Automatic Resource Management
```swift
let shortcut = MASShortcut.composed { $0.key(kVK_ANSI_T).command() }

// Automatically clean up after operation
try await MASShortcutMonitor.shared.withShortcut(shortcut, action: {
    print("Temporary shortcut activated")
}) {
    // Perform work with the shortcut active
    try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
    print("Work completed")
}
// Shortcut is automatically unregistered here
```

# Shortcut Recorder Compatibility

By default, MASShortcut uses a different User Defaults storage format incompatible with Shortcut Recorder. But it’s easily possible to change that, so that you can replace Shortcut Recorder with MASShortcut without having to migrate the shortcuts previously stored by your apps. There are two parts of the story:

If you bind the recorder control (`MASShortcutView`) to User defaults, set the Value Transformer field in the Interface Builder to `MASDictionaryTransformer`. This makes sure the shortcuts are written in the Shortcut Recorder format.

If you use `MASShortcutBinder` to automatically load shortcuts from User Defaults, set the `bindingOptions` accordingly:

```objective-c
[[MASShortcutBinder sharedBinder] setBindingOptions:@{NSValueTransformerNameBindingOption:MASDictionaryTransformerName}];
```

This makes sure that the shortcuts in the Shortcut Recorder format are loaded correctly.

# Notifications

By registering for KVO notifications from `NSUserDefaultsController`, you can get a callback whenever a user changes the shortcut, allowing you to perform any UI updates, or other code handling tasks.

This is just as easy to implement:
    
```objective-c
// Declare an ivar for key path in the user defaults controller
NSString *_observableKeyPath;
    
// Make a global context reference
void *kGlobalShortcutContext = &kGlobalShortcutContext;
    
// Implement when loading view
_observableKeyPath = [@"values." stringByAppendingString:kPreferenceGlobalShortcut];
[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:_observableKeyPath
                                                             options:NSKeyValueObservingOptionInitial
                                                             context:kGlobalShortcutContext];

// Capture the KVO change and do something
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)obj
                        change:(NSDictionary *)change context:(void *)ctx
{
    if (ctx == kGlobalShortcutContext) {
        NSLog(@"Shortcut has changed");
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:obj change:change context:ctx];
    }
}

// Do not forget to remove the observer
[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self
                                                             forKeyPath:_observableKeyPath
                                                                context:kGlobalShortcutContext];
```

# 📚 API Reference

## Core Types

### MASShortcut
```swift
@frozen public struct MASShortcut: Sendable, Hashable, Codable, CustomStringConvertible {
    public let keyCode: Int
    public let modifierFlags: NSEvent.ModifierFlags

    // Creation methods
    public init(keyCode: Int, modifierFlags: NSEvent.ModifierFlags)
    public init?(event: NSEvent)

    // Builder patterns
    public static func build(_ builder: (inout Builder) -> Void) -> Result<MASShortcut, ShortcutError>
    public static func composed(_ composer: (MASShortcutComposer) -> MASShortcutComposer) -> MASShortcut?

    // KeyPath operations
    public func with<T>(_ keyPath: WritableKeyPath<MASShortcut, T>, value: T) -> MASShortcut
    public func map<T>(_ keyPath: WritableKeyPath<MASShortcut, T>, transform: (T) -> T) -> MASShortcut
}
```

### MASShortcutMonitor
```swift
@MainActor public final class MASShortcutMonitor: NSObject, ShortcutMonitoring, @unchecked Sendable {
    // Async registration
    func registerShortcut(_ shortcut: MASShortcut, action: @escaping @Sendable () async -> Void) async throws -> ShortcutRegistration

    // Synchronous registration (legacy compatibility)
    func registerShortcut(_ shortcut: MASShortcut, withAction action: @escaping () -> Void) -> Bool

    // Higher-order APIs
    func registerShortcuts(_ shortcuts: [(MASShortcut, @Sendable () async -> Void)]) async throws -> [ShortcutRegistration]
    func withShortcut<T: Sendable>(...) async throws -> T
}
```

### MASShortcutValidator
```swift
@MainActor public final class MASShortcutValidator: NSObject, ShortcutValidation, @unchecked Sendable {
    // Async validation
    func validateShortcut(_ shortcut: MASShortcut) async -> Result<Void, ValidationError>
    func validateForContext(_ shortcut: MASShortcut, context: ValidationContext) async -> Result<Void, ValidationError>

    // Legacy validation
    func isShortcutValid(_ shortcut: MASShortcut) -> Bool
}
```

## 🎯 Migration Guide

### From Objective-C to Swift 6

#### Old API (Objective-C)
```objective-c
// Old way
MASShortcut *shortcut = [MASShortcut shortcutWithKeyCode:kVK_ANSI_A modifierFlags:NSCommandKeyMask];
[[MASShortcutMonitor sharedMonitor] registerShortcut:shortcut withAction:^{ /* action */ }];
```

#### New API (Swift 6)
```swift
// New way - Builder pattern
let shortcut = MASShortcut.composed { composer in
    composer.key(kVK_ANSI_A).command()
}

// Async registration with error handling
do {
    let registration = try await MASShortcutMonitor.shared.registerShortcut(shortcut) {
        // Action
    }
} catch {
    // Handle error
}
```

### From Legacy Swift to Modern Swift 6

#### Before (Legacy Swift)
```swift
let shortcut = MASShortcut(keyCode: 0, modifierFlags: .command)
MASShortcutMonitor.shared.registerShortcut(shortcut, withAction: { /* action */ })
```

#### After (Modern Swift 6)
```swift
let shortcut = MASShortcut.composed { composer in
    composer.key(0).command()
}

let registration = try await MASShortcutMonitor.shared.registerShortcut(shortcut) {
    // Async action
}
```

## 🔧 Error Handling

### ValidationError
```swift
public enum ValidationError: LocalizedError, Sendable {
    case invalidShortcut(reason: String)
    case systemReserved
    case menuConflict(MenuConflict)
    case serviceMenuConflict
    case invalidModifierCombination
}
```

### RegistrationError
```swift
public enum RegistrationError: LocalizedError, Sendable {
    case shortcutAlreadyRegistered(MASShortcut)
    case systemRegistrationFailed
    case invalidShortcut
}
```

### Error Handling Example
```swift
do {
    let registration = try await MASShortcutMonitor.shared.registerShortcut(shortcut) {
        print("Shortcut activated")
    }
} catch let error as MASShortcutMonitor.RegistrationError {
    switch error {
    case .shortcutAlreadyRegistered(let existing):
        print("Shortcut already registered: \(existing)")
    case .systemRegistrationFailed:
        print("System registration failed")
    case .invalidShortcut:
        print("Invalid shortcut")
    }
} catch {
    print("Unknown error: \(error)")
}
```

# 🤝 Contributing

We welcome contributions! Here's how you can help:

### Development Setup
```bash
# Clone the repository
git clone https://github.com/shpakovski/MASShortcut.git
cd MASShortcut

# Run tests
swift test

# Build for production
swift build --configuration release
```

### Code Style
- Follow Swift 6 strict concurrency guidelines
- Use `@MainActor` for UI-related code
- Implement `@unchecked Sendable` only when absolutely necessary
- Write comprehensive tests for new features
- Document all public APIs with Swift documentation comments

### Testing
```bash
# Run all tests
swift test

# Run with code coverage
swift test --enable-code-coverage

# Run specific test
swift test --filter MASShortcutTests
```

### Pull Request Process
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Add tests for your changes
4. Ensure all tests pass (`swift test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📄 License

MASShortcut is licensed under the 2-clause BSD license.

```
Copyright (c) 2024, MASShortcut Contributors
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

## 🙏 Acknowledgments

- Original **ShortcutRecorder** project for inspiration
- Swift community for modern concurrency patterns
- Contributors who helped shape this framework

---

<div align="center">

**[📦 Install Now](https://github.com/shpakovski/MASShortcut)** • **[📖 Documentation](https://github.com/shpakovski/MASShortcut/blob/main/README.md)** • **[🐛 Report Issues](https://github.com/shpakovski/MASShortcut/issues)**

**Built with ❤️ for the macOS developer community**

</div>
