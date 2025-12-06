import Foundation
import AppKit
import Carbon
import MASShortcut

// Helper for colored output
func pass(_ msg: String) { print("\u{001B}[32m✅ PASS: \(msg)\u{001B}[0m") }
func fail(_ msg: String) { print("\u{001B}[31m❌ FAIL: \(msg)\u{001B}[0m"); exit(1) }
func info(_ msg: String) { print("\u{001B}[34mℹ️ INFO: \(msg)\u{001B}[0m") }

// Setup MainActor for the test (needed for Validator)
@MainActor
func runVerification() async {
    info("Starting Extensive Real-world Verification...")
    
    // ----------------------------------------------------------------
    // 1. Resource Validation (SystemShortcuts.plist)
    // ----------------------------------------------------------------
    info("Step 1: Verifying Resource Loading & System Shortcuts")
    let validator = MASShortcutValidator()
    
    // CMD+TAB (KeyCode 48) - Should be reserved
    let cmdTab = MASShortcut(keyCode: 48, modifierFlags: .command)
    let result1 = await validator.validateShortcut(cmdTab)
    
    switch result1 {
    case .failure(.systemReserved):
        pass("Correctly identified Cmd+Tab as system reserved.")
    case .success:
        fail("Cmd+Tab should be rejected, but passed validation.")
    case .failure(let err):
        fail("Cmd+Tab failed with unexpected error: \(err)")
    }
    
    // CMD+OPT+K (Random) - Should be valid
    let cmdOptK = MASShortcut(keyCode: Int(kVK_ANSI_K), modifierFlags: [.command, .option])
    let result2 = await validator.validateShortcut(cmdOptK)
    
    switch result2 {
    case .success:
        pass("Correctly accepted valid shortcut Cmd+Opt+K.")
    case .failure(let err):
        fail("Cmd+Opt+K should be accepted, but failed: \(err)")
    }

    // ----------------------------------------------------------------
    // 2. Menu Conflict Validation
    // ----------------------------------------------------------------
    info("Step 2: Verifying Menu Conflict Detection")
    let menu = NSMenu(title: "Main")
    let item = NSMenuItem(title: "Save", action: nil, keyEquivalent: "s")
    item.keyEquivalentModifierMask = .command
    menu.addItem(item)
    NSApp.mainMenu = menu
    
    // CMD+S - Should conflict
    let cmdS = MASShortcut(keyCode: Int(kVK_ANSI_S), modifierFlags: .command)
    var explanation: String? = nil
    let isTaken = validator.isShortcutAlreadyTakenBySystem(cmdS, explanation: &explanation)
    
    if isTaken {
        pass("Correctly detected conflict with Menu item 'Save' (Cmd+S).")
        if let text = explanation, text.contains("Save") {
            pass("Explanation contains menu item title.")
        } else {
            fail("Explanation missing or incorrect: \(String(describing: explanation))")
        }
    } else {
        fail("Failed to detect conflict with Cmd+S")
    }

    // ----------------------------------------------------------------
    // 3. Monitor Registration & Concurrency
    // ----------------------------------------------------------------
    info("Step 3: Verifying Monitor Registration & Thread Safety")
    let monitor = MASShortcutMonitor.create()
    
    do {
        // Register from a background task to test Concurrency/Sendable
        let task = Task.detached {
            return try await monitor.registerShortcut(cmdOptK, action: {
                print("Shortcut triggered!")
            })
        }
        let registration = try await task.value
        
        pass("Successfully registered shortcut from background task.")
        
        let isRegistered = monitor.isShortcutRegistered(cmdOptK)
        if isRegistered {
            pass("Monitor reports shortcut is registered.")
        } else {
            fail("Monitor reports shortcut is NOT registered.")
        }
        
        // Cleanup
        await monitor.unregisterShortcut(registration)
        let isReqAfter = monitor.isShortcutRegistered(cmdOptK)
        if !isReqAfter {
            pass("Successfully unregistered shortcut.")
        } else {
            fail("Shortcut should be unregistered.")
        }
        
    } catch {
        fail("Registration failed: \(error)")
    }
    
    info("Looking good! All checks passed.")
    exit(0)
}

// Entry point
// We need a run loop or at least a main dispatch queue for NSApp related things (even if mocked)
let app = NSApplication.shared
Task { @MainActor in
    await runVerification()
}
RunLoop.main.run()
