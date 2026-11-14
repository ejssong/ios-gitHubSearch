---
name: verify
description: 시뮬레이터 빌드와 전체 테스트를 정해진 명령으로 실행하고 결과를 요약한다. 구현을 마쳤을 때, 커밋이나 PR 전에, "빌드 확인", "테스트 돌려줘" 같은 요청에 사용한다.
---

# 빌드와 테스트 검증

## 명령

레포 루트에서 실행한다. 몇 분 걸리므로 백그라운드로 돌리고 끝나기를 기다린다.

```sh
xcodebuild test \
  -project GitHubSearch.xcodeproj \
  -scheme GitHubSearch \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -skipMacroValidation \
  -derivedDataPath .build/DerivedData \
  > .build/verify.log 2>&1; echo "exit=$?"
```

- `-skipMacroValidation`: 명령줄에서는 TCA 매크로 허용 창을 띄울 수 없어서 필요하다.
- `-derivedDataPath .build/DerivedData`: Xcode 가 같은 프로젝트를 열어 둔 상태에서 기본 빌드 폴더를 쓰면 실행이 시작 단계에서 멈춘 적이 있다. `.build/` 는 git 에서 제외되어 있다.
- `iPhone 17` 시뮬레이터가 없으면 `xcrun simctl list devices available` 에서 고른다.

## 결과 읽기

```sh
grep -E " error: |\*\* (TEST|BUILD) |✘|Test run with" .build/verify.log | sort -u
grep "warning: " .build/verify.log | grep -E "/(App|Tests)/" | sort -u
```

- 통과 기준: 종료 코드 0, `** TEST SUCCEEDED **`, 실패(`✘`) 없음
- 우리 코드(`App/`, `Tests/`)에서 나온 경고는 함께 보고한다. 패키지의 경고는 무시한다.

## 보고

- 통과 여부, 실행된 테스트 수, 실패한 테스트 이름과 메시지를 그대로 적는다.
- 실패하면 원인을 고치고 다시 실행한다. 통과하지 않은 상태로 완료라고 하지 않는다.
- 테스트로 확인하지 못한 것(실제 화면 조작, 실제 API 호출 등)은 "확인하지 못한 것"으로 따로 적는다.
