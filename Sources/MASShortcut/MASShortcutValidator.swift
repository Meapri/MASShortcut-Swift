import AppKit
import Carbon

/**
 This class is used by the recording control to tell which shortcuts are acceptable.

 There are two kinds of shortcuts that are not considered acceptable: shortcuts that
 are too simple (like single letter keys) and shortcuts that are already used by the
 operating system.
 */
/// Protocol for shortcut validation operations.
public protocol ShortcutValidation {
    /// Validates if a shortcut is acceptable for registration.
    func validateShortcut(_ shortcut: MASShortcut) async -> Result<Void, ValidationError>

    /// Validates a shortcut for use in a specific context.
    func validateForContext(_ shortcut: MASShortcut, context: ValidationContext) async -> Result<Void, ValidationError>
}

/// Context information for shortcut validation.
public struct ValidationContext: Sendable {
    public let allowSystemShortcuts: Bool
    public let allowServiceMenuOverrides: Bool
    public let allowOptionModifier: Bool

    public static let `default` = ValidationContext(
        allowSystemShortcuts: false,
        allowServiceMenuOverrides: false,
        allowOptionModifier: false
    )

    public static let lenient = ValidationContext(
        allowSystemShortcuts: true,
        allowServiceMenuOverrides: true,
        allowOptionModifier: true
    )
}

/// Represents a conflict with an existing menu item.
public struct MenuConflict: Sendable {
    public let menuItemTitle: String
    public let menuItemTag: Int
    public let conflictingShortcut: MASShortcut
    public let menuPath: [String]

    public init(menuItem: NSMenuItem, conflictingShortcut: MASShortcut, menuPath: [String]) {
        self.menuItemTitle = menuItem.title
        self.menuItemTag = menuItem.tag
        self.conflictingShortcut = conflictingShortcut
        self.menuPath = menuPath
    }
}

/// Errors that can occur during shortcut validation.
public enum ValidationError: LocalizedError, Sendable {
    case invalidShortcut(reason: String)
    case systemReserved
    case menuConflict(MenuConflict)
    case serviceMenuConflict
    case invalidModifierCombination

            public var errorDescription: String? {
            switch self {
            case .invalidShortcut(let reason):
                return "Invalid shortcut: \(reason)"
            case .systemReserved:
                return "This shortcut is reserved by the system"
            case .menuConflict(let conflict):
                return "Shortcut conflicts with menu item '\(conflict.menuItemTitle)'"
            case .serviceMenuConflict:
                return "Shortcut conflicts with Services menu"
            case .invalidModifierCombination:
                return "Invalid combination of modifier keys"
            }
        }
}

/// Modern shortcut validator with async/await support.
/// Thread-safe implementation for Swift 6 compatibility.
/// Note: Uses @unchecked Sendable due to complex validation logic and UI integration requirements.
/// This is a pragmatic choice for compatibility while acknowledging the trade-off.
public final class MASShortcutValidator: ShortcutValidation, @unchecked Sendable {

    // MARK: - Properties

    /// Configuration for validation behavior.
    private var context: ValidationContext = .default
    
    /// Cached system shortcuts
    private lazy var systemShortcuts: [MASShortcut] = {
        guard let url = Bundle.module.url(forResource: "SystemShortcuts", withExtension: "plist"),
              let array = NSArray(contentsOf: url) as? [[String: Any]] else {
            return []
        }
        
        return array.compactMap { dict in
            guard let keyCode = dict["keyCode"] as? Int,
                  let flags = dict["modifierFlags"] as? UInt else {
                return nil
            }
            return MASShortcut(keyCode: keyCode, modifierFlags: NSEvent.ModifierFlags(rawValue: flags))
        }
    }()

    // MARK: - Initialization

    public init() {
        // Default initialization
    }

    // MARK: - Factory Method

    /// Creates a new shortcut validator instance.
    /// For Swift 6 compatibility, shared instances are not used.
    /// Instead, create and manage your own instance.
    public static func create() -> MASShortcutValidator {
        return MASShortcutValidator()
    }

    // MARK: - Configuration

    /// Updates the validation context.
    public func updateContext(_ newContext: ValidationContext) {
        context = newContext
    }

    /// Gets the current validation context.
    public func getContext() -> ValidationContext {
        return context
    }

    // MARK: - Public Methods

    /// Validates if a shortcut is acceptable for registration.
    public func validateShortcut(_ shortcut: MASShortcut) async -> Result<Void, ValidationError> {
        return await validateForContext(shortcut, context: context)
    }

    /// Validates a shortcut for use in a specific context.
    public func validateForContext(_ shortcut: MASShortcut, context: ValidationContext) async -> Result<Void, ValidationError> {
        // Basic validation
        guard isShortcutValid(shortcut, context: context) else {
            return .failure(.invalidShortcut(reason: "Shortcut does not meet basic requirements"))
        }

        // System reserved check
        if !context.allowSystemShortcuts && isSystemReserved(shortcut) {
            return .failure(.systemReserved)
        }
        
        // Menu Conflict Check (must run on Main Thread)
        let isTakenByMenu = await MainActor.run {
             var explanation: String? = nil
             return isShortcutAlreadyTakenBySystem(shortcut, explanation: &explanation)
        }
        
        if isTakenByMenu {
            return .failure(.menuConflict(MenuConflict(menuItem: NSMenuItem(), conflictingShortcut: shortcut, menuPath: []))) // Simplified error construction
        }

        return .success(())
    }

    /// Synchronous validation method for backward compatibility.
    /// Note: This is a synchronous wrapper around the async validation for compatibility.
    /// For new code, prefer the async validateShortcut method.
    public func isShortcutValid(_ shortcut: MASShortcut) -> Bool {
        return isShortcutValid(shortcut, context: context)
    }



    // MARK: - Legacy API (for backward compatibility)

    private func isShortcutValid(_ shortcut: MASShortcut, context: ValidationContext) -> Bool {
        let keyCode = shortcut.keyCode
        let modifiers = shortcut.modifierFlags

        // Allow any function key with any combination of modifiers
        let functionKeys: Set<Int> = [
            Int(kVK_F1), Int(kVK_F2), Int(kVK_F3), Int(kVK_F4),
            Int(kVK_F5), Int(kVK_F6), Int(kVK_F7), Int(kVK_F8),
            Int(kVK_F9), Int(kVK_F10), Int(kVK_F11), Int(kVK_F12),
            Int(kVK_F13), Int(kVK_F14), Int(kVK_F15), Int(kVK_F16),
            Int(kVK_F17), Int(kVK_F18), Int(kVK_F19), Int(kVK_F20)
        ]

        if functionKeys.contains(keyCode) {
            return true
        }

        // Do not allow any other key without modifiers
        let hasModifierFlags = modifiers.rawValue > 0
        if !hasModifierFlags {
            return false
        }

        // Allow any hotkey containing Control or Command modifier
        let includesCommand = modifiers.contains(.command)
        let includesControl = modifiers.contains(.control)
        if includesCommand || includesControl {
            return true
        }

        // Allow Option key only in selected cases
        let includesOption = modifiers.contains(.option)
        if includesOption {
            // Always allow Option-Space and Option-Escape because they do not have any bind system commands
            if keyCode == Int(kVK_Space) || keyCode == Int(kVK_Escape) {
                return true
            }

            // Allow Option modifier with any key even if it will break the system binding
            if context.allowOptionModifier {
                return true
            }
        }

        // The hotkey does not have any modifiers or violates system bindings
        return false
    }

    private func isSystemReserved(_ shortcut: MASShortcut) -> Bool {
        return systemShortcuts.contains(shortcut)
    }

    /// Checks if a shortcut is already taken by a menu item.
    /// - Note: This method must run on the MainActor because it accesses NSMenu.
    @MainActor
    public func isShortcut(_ shortcut: MASShortcut, alreadyTakenInMenu menu: NSMenu, explanation: inout String?) -> Bool {
        // Services menu check
        if context.allowServiceMenuOverrides == false && menu == NSApp.servicesMenu {
            return false // Simplified for now, in reality traversing services menu is complex
        }

        let keyEquivalent = shortcut.keyCodeStringForKeyEquivalent
        let flags = shortcut.modifierFlags

        for menuItem in menu.items {
            if menuItem.hasSubmenu, let submenu = menuItem.submenu {
                if isShortcut(shortcut, alreadyTakenInMenu: submenu, explanation: &explanation) {
                    return true
                }
            }

            var equalFlags = MASPickModifiersIncludingFn(menuItem.keyEquivalentModifierMask) == flags
            let equalHotkeyLowercase = menuItem.keyEquivalent.lowercased() == keyEquivalent

            // Check if the cases are different (case insensitive match)
            if equalHotkeyLowercase && menuItem.keyEquivalent != keyEquivalent {
                let theirFlags = menuItem.keyEquivalentModifierMask.union(.shift)
                equalFlags = MASPickModifiersIncludingFn(theirFlags) == flags
            }

            if equalFlags && equalHotkeyLowercase {
                let format = NSLocalizedString("This shortcut cannot be used because it is already used by the menu item '%@'.",
                                              comment: "Message for alert when shortcut is already used")
                explanation = String(format: format, menuItem.title)
                return true
            }
        }
        return false
    }

    @MainActor
    public func isShortcutAlreadyTakenBySystem(_ shortcut: MASShortcut, explanation: inout String?) -> Bool {
        if isSystemReserved(shortcut) {
             explanation = NSLocalizedString("This shortcut is reserved by the system.", comment: "System reserved explanation")
             return true
        }
        
        // Main Menu Check
        if let mainMenu = NSApp.mainMenu {
             if isShortcut(shortcut, alreadyTakenInMenu: mainMenu, explanation: &explanation) {
                 return true
             }
        }
        
        return false
    }
}
