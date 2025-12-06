# MASShortcut-Swift

macOS 전역 키보드 단축키 관리를 위한 네이티브 Swift 6 라이브러리입니다.

이 프로젝트는 Objective-C 기반의 [MASShortcut](https://github.com/shpakovski/MASShortcut)을 현대적으로 재작성한 것으로, Swift 6의 엄격한 동시성 표준(`Sendable` 체크 등)을 준수하도록 설계되었습니다.

## 주요 기능

- **전역 모니터링 (Global Monitoring)**: 애플리케이션이 백그라운드에 있을 때도 키보드 단축키를 감지합니다 (Carbon `RegisterEventHotKey` 사용).
- **Swift 6 동시성 (Concurrency)**: `Sendable` 및 `@MainActor`를 완벽하게 지원하여 스레드 안전성을 보장합니다.
- **Async/Await API**: 단축키 등록을 위한 최신 비동기 인터페이스를 제공합니다.
- **유효성 검사 (Validation)**: 시스템 예약 단축키(예: `Cmd+Tab`) 사용이나 앱 메인 메뉴와의 충돌을 방지합니다.

## 요구사항

- macOS 13.0 이상
- Swift 6.0 이상

## 설치

`Package.swift` 파일에 다음 의존성을 추가하세요:

```swift
dependencies: [
    .package(url: "https://github.com/Meapri/MASShortcut-Swift.git", from: "3.0.0")
]
```

## 사용법

### 1. 전역 단축키 등록

`MASShortcutMonitor`를 사용하여 액션을 등록합니다. 액션 클로저는 지정된 큐나 MainActor에서 실행됩니다.

```swift
import MASShortcut
import Carbon

// 단축키 정의 (예: Command + Option + K)
let shortcut = MASShortcut(keyCode: kVK_ANSI_K, modifierFlags: [.command, .option])

Task {
    do {
        // 단축키 등록
        // 액션은 비동기(async) 클로저로 실행됩니다
        let registration = try await MASShortcutMonitor.shared.registerShortcut(shortcut) {
            print("단축키가 눌렸습니다!")
        }
        
        // 'registration' 객체는 나중에 수동으로 등록 해제할 때 필요합니다.
        // 별도로 저장하지 않으면 앱이 종료되거나 unregisterAllShortcuts가 호출될 때까지 유지됩니다.
    } catch {
        print("등록 실패: \(error)")
    }
}
```

### 2. 단축키 유효성 검사

`MASShortcutValidator`를 사용하여 사용자가 지정한 단축키가 시스템 키나 앱 메뉴와 충돌하지 않는지 확인합니다.

```swift
let validator = MASShortcutValidator()

// 시스템 충돌 확인 (예: Cmd+Tab)
let result = await validator.validateShortcut(shortcut)

switch result {
case .success:
    print("유효한 단축키입니다")
case .failure(let error):
    print("유효하지 않은 단축키: \(error.localizedDescription)")
}

// 메뉴 충돌 확인
var explanation: String?
if await validator.isShortcutAlreadyTakenBySystem(shortcut, explanation: &explanation) {
    print("충돌 감지됨: \(explanation ?? "")")
}
```

### 3. 빌더 패턴

플루언트(Fluent) 문법을 사용하여 단축키를 생성할 수도 있습니다:

```swift
let shortcut = MASShortcut.composed { composer in
    composer.key(kVK_ANSI_L).command().shift()
}
```

## 아키텍처 참고사항

- **MASShortcutMonitor**: Carbon 이벤트 루프 통합을 담당합니다. 표준 EventHandler를 설치하여 `kEventHotKeyPressed` 이벤트를 가로챕니다.
- **MASShortcutVerify**: 라이브러리의 기능을 실제 환경에서 검증하기 위해 포함된 실행 가능한 타겟입니다.

## 라이선스

BSD 2-Clause License. 자세한 내용은 [LICENSE](LICENSE) 파일을 참고하세요.
