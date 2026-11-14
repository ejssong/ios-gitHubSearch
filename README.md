# ios-gitHubSearch

GitHub 저장소를 검색하는 iOS 앱입니다.

## 요구 사항

- Xcode
- iOS

## 실행 방법

1. 저장소를 클론합니다.
2. Xcode 에서 `GitHubSearch.xcodeproj` 를 열고 실행합니다.

### 매크로 신뢰 확인

TCA 와 그 의존 패키지는 Swift 매크로를 사용합니다. Xcode 는 패키지 매크로를 처음 빌드할 때 직접 허용하기 전까지 빌드를 막고, 아래와 같은 오류를 보여줍니다.

```
Macro "ComposableArchitectureMacros" from package "swift-composable-architecture" must be enabled before it can be used
```

- **Xcode 에서 빌드할 때**: Issue navigator 에서 오류를 클릭하고 **Trust & Enable** 을 누릅니다. 매크로마다 한 번씩 허용하면 같은 버전에서는 다시 묻지 않습니다.
- **명령줄에서 빌드할 때**: 허용 창을 띄울 수 없으므로 `-skipMacroValidation` 옵션을 붙여 확인을 건너뜁니다.

## 명령줄 빌드와 테스트

```sh
xcodebuild test \
  -project GitHubSearch.xcodeproj \
  -scheme GitHubSearch \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -skipMacroValidation
```

`-destination` 의 기기 이름은 설치된 시뮬레이터에 맞게 바꿉니다. 빌드만 하려면 `test` 대신 `build` 를 씁니다.
