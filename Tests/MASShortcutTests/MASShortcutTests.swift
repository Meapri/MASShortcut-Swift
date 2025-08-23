import XCTest
@testable import MASShortcut
import AppKit

final class MASShortcutTests: XCTestCase {

    // MARK: - MASShortcut Tests

    func testMASShortcutCreation() {
        // 기본 생성자 테스트
        let shortcut1 = MASShortcut(keyCode: 0, modifierFlags: .command)
        XCTAssertEqual(shortcut1.keyCode, 0)
        XCTAssertEqual(shortcut1.modifierFlags, .command)

        // NSEvent 생성자 테스트
        let event = NSEvent.keyEvent(with: .keyDown,
                                   location: .zero,
                                   modifierFlags: [.command, .shift],
                                   timestamp: 0,
                                   windowNumber: 0,
                                   context: nil,
                                   characters: "A",
                                   charactersIgnoringModifiers: "A",
                                   isARepeat: false,
                                   keyCode: 0)
        let shortcut2 = MASShortcut(event: event!)
        XCTAssertEqual(shortcut2?.keyCode, 0)
        XCTAssertEqual(shortcut2?.modifierFlags, [.command, .shift])
    }

    func testMASShortcutEquality() {
        let shortcut1 = MASShortcut(keyCode: 0, modifierFlags: .command)
        let shortcut2 = MASShortcut(keyCode: 0, modifierFlags: .command)
        let shortcut3 = MASShortcut(keyCode: 1, modifierFlags: .command)

        XCTAssertEqual(shortcut1, shortcut2)
        XCTAssertNotEqual(shortcut1, shortcut3)
    }

    func testMASShortcutHashable() {
        let shortcut1 = MASShortcut(keyCode: 0, modifierFlags: .command)
        let shortcut2 = MASShortcut(keyCode: 0, modifierFlags: .command)

        let set = Set([shortcut1, shortcut2])
        XCTAssertEqual(set.count, 1) // 같은 shortcut은 중복되지 않아야 함
    }

    func testMASShortcutCodable() throws {
        let shortcut = MASShortcut(keyCode: 0, modifierFlags: [.command, .shift])

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(shortcut)

        // Decode
        let decoder = JSONDecoder()
        let decodedShortcut = try decoder.decode(MASShortcut.self, from: data)

        XCTAssertEqual(shortcut, decodedShortcut)
    }

    func testMASShortcutBuilder() {
        let result = MASShortcut.build { builder in
            builder.key(0)
            builder.command()
            builder.shift()
        }

        switch result {
        case .success(let shortcut):
            XCTAssertEqual(shortcut.keyCode, 0)
            XCTAssertEqual(shortcut.modifierFlags, [.command, .shift])
        case .failure:
            XCTFail("Builder should succeed")
        }
    }

    func testMASShortcutComposer() {
        let shortcut = MASShortcut.composed { composer in
            composer.key(0).command().option()
        }

        XCTAssertNotNil(shortcut)
        XCTAssertEqual(shortcut?.keyCode, 0)
        XCTAssertEqual(shortcut?.modifierFlags, [.command, .option])
    }

    func testMASShortcutKeyPath() {
        let original = MASShortcut(keyCode: 0, modifierFlags: NSEvent.ModifierFlags([.command]))

        // KeyPath subscript 테스트
        let keyCode = original[keyPath: \.keyCode]
        let modifiers = original[\.modifierFlags]
        XCTAssertEqual(keyCode, 0)
        XCTAssertEqual(modifiers, NSEvent.ModifierFlags([.command]))
    }

    func testMASShortcutDescription() {
        let shortcut = MASShortcut(keyCode: 0, modifierFlags: [.command, .shift])
        let description = shortcut.description
        XCTAssertTrue(description.contains("⌘")) // Command symbol
        XCTAssertTrue(description.contains("⇧")) // Shift symbol
    }

    // MARK: - MASShortcutValidator Tests

    func testMASShortcutValidatorBasic() {
        let validator = MASShortcutValidator.shared

        // 유효한 단축키 테스트
        let validShortcut = MASShortcut(keyCode: 0, modifierFlags: NSEvent.ModifierFlags([.command, .shift]))
        let isValid = validator.isShortcutValid(validShortcut)
        XCTAssertTrue(isValid)

        // 유효하지 않은 단축키 테스트 (modifier 없음)
        let invalidShortcut = MASShortcut(keyCode: 0, modifierFlags: [])
        let isInvalid = validator.isShortcutValid(invalidShortcut)
        XCTAssertFalse(isInvalid)
    }

    func testMASShortcutValidatorAsync() async {
        let validator = await MASShortcutValidator.shared
        let shortcut = MASShortcut(keyCode: 0, modifierFlags: NSEvent.ModifierFlags([.command, .shift]))

        let result = await validator.validateShortcut(shortcut)

        switch result {
        case .success:
            XCTAssertTrue(true)
        case .failure(let error):
            XCTFail("Validation should succeed: \(error)")
        }
    }

    func testMASShortcutValidatorContext() async {
        let validator = await MASShortcutValidator.shared
        let shortcut = MASShortcut(keyCode: 0, modifierFlags: NSEvent.ModifierFlags([.command, .shift]))

        // Default context
        let defaultResult = await validator.validateForContext(shortcut, context: .default)
        switch defaultResult {
        case .success:
            XCTAssertTrue(true)
        case .failure:
            XCTFail("Should succeed with default context")
        }

        // Lenient context
        let lenientResult = await validator.validateForContext(shortcut, context: .lenient)
        switch lenientResult {
        case .success:
            XCTAssertTrue(true)
        case .failure:
            XCTFail("Should succeed with lenient context")
        }
    }

    // MARK: - MASShortcutMonitor Tests

    func testMASShortcutMonitorRegistration() async {
        let monitor = await MASShortcutMonitor.shared
        let shortcut = MASShortcut(keyCode: 0, modifierFlags: NSEvent.ModifierFlags([.command, .shift]))

        // 등록 테스트 (동기 버전 사용)
        let success = monitor.registerShortcut(shortcut, withAction: {
            print("Test action executed")
        })

        XCTAssertTrue(success)
    }

    func testMASShortcutMonitorMultipleShortcuts() async {
        let monitor = await MASShortcutMonitor.shared
        let shortcuts = [
            MASShortcut(keyCode: 0, modifierFlags: NSEvent.ModifierFlags([.command])),
            MASShortcut(keyCode: 1, modifierFlags: NSEvent.ModifierFlags([.command, .shift]))
        ]

        var successCount = 0
        for shortcut in shortcuts {
            let success = monitor.registerShortcut(shortcut, withAction: {
                print("Action for \(shortcut)")
            })
            if success {
                successCount += 1
            }
        }

        XCTAssertEqual(successCount, 2)
    }

    // MARK: - MASDictionaryTransformer Tests

    func testMASDictionaryTransformer() {
        let transformer = MASDictionaryTransformer()
        let shortcut = MASShortcut(keyCode: 0, modifierFlags: [.command, .shift])

        // Forward transformation (MASShortcut -> NSDictionary)
        let dictionary = transformer.reverseTransformedValue(shortcut) as? [String: Any]
        XCTAssertNotNil(dictionary)
        XCTAssertEqual(dictionary?["keyCode"] as? Int, 0)
        XCTAssertEqual(dictionary?["modifierFlags"] as? UInt, NSEvent.ModifierFlags([.command, .shift]).rawValue)

        // Reverse transformation (NSDictionary -> MASShortcut)
        let restoredShortcut = transformer.transformedValue(dictionary) as? MASShortcut
        XCTAssertEqual(restoredShortcut, shortcut)
    }

    // MARK: - Legacy API Compatibility Tests

    func testLegacyAPICompatibility() {
        let shortcut = MASShortcut(keyCode: 0, modifierFlags: NSEvent.ModifierFlags([.command]))

        // Legacy static 메서드들
        let shortcut1 = MASShortcut.shortcut(keyCode: 0, modifierFlags: NSEvent.ModifierFlags([.command]))
        let shortcut2 = MASShortcut.shortcut(event: NSEvent.keyEvent(with: .keyDown,
                                                                    location: .zero,
                                                                    modifierFlags: NSEvent.ModifierFlags([.command]),
                                                                    timestamp: 0,
                                                                    windowNumber: 0,
                                                                    context: nil,
                                                                    characters: "A",
                                                                    charactersIgnoringModifiers: "A",
                                                                    isARepeat: false,
                                                                    keyCode: 0)!)

        XCTAssertEqual(shortcut1, shortcut)
        XCTAssertEqual(shortcut2, shortcut)
    }

    func testSendableCompliance() {
        // MASShortcut이 Sendable 프로토콜을 준수하는지 확인
        let shortcut = MASShortcut(keyCode: 0, modifierFlags: NSEvent.ModifierFlags([.command]))

        func acceptSendable<T: Sendable>(_ value: T) {}
        acceptSendable(shortcut) // 컴파일 에러가 없어야 함

        // ValidationContext가 Sendable인지 확인
        let context = ValidationContext.default
        acceptSendable(context)
    }

    func testPerformance() {
        measure {
            for i in 0..<1000 {
                let shortcut = MASShortcut(keyCode: i, modifierFlags: NSEvent.ModifierFlags([.command]))
                let _ = shortcut.description
            }
        }
    }
}
