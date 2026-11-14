# GitHubSearch

GitHub 저장소 검색 iOS 앱 과제입니다. 요구사항은 [docs/requirements/requirements.md](docs/requirements/requirements.md) 에 있고, 작업은 GitHub 이슈 단위로 진행합니다.

## 기술

- 최소 iOS 17, Swift 6 언어 모드, SwiftUI + TCA (`1.26.2` 고정)
- 외부 라이브러리는 금지가 아니다. 추가할 때는 이유를 이슈나 PR 에 적는다.

## 구조

앱 타깃 하나에 폴더로 역할을 나눈다. `Tests/` 는 `App/` 과 같은 폴더 구조를 따른다.

| 폴더 | 역할 |
|---|---|
| `App/Search` | 검색어 입력, 최근 검색어 저장/삭제, 검색 실행 전달 |
| `App/SearchResult` | 검색 API/DTO, 결과, 로딩, 오류, 페이지 상태 |
| `App/Core` | 범용 클라이언트. 지금은 `Network` 의 `HTTPClient` |

- 의존 방향은 `Search` → `SearchResult` → `Core` 다. 컴파일러가 막아 주지 않으므로 반대 방향으로 참조하지 않는다.
- endpoint 와 응답 모델(DTO)은 `Core` 가 아니라 그것을 쓰는 Feature 폴더에 둔다.
- 파일은 `App/` 이나 `Tests/` 아래에 넣기만 하면 타깃에 포함된다. `project.pbxproj` 는 직접 고치지 않는다. 꼭 고쳐야 하면 Xcode 를 닫고 한다. (열려 있으면 Xcode 가 덮어쓴다.)

## TCA 규칙

- Feature 는 `@Reducer struct XxxFeature` 와 `XxxView` 한 쌍이다. 상태는 `@ObservableState struct State: Equatable`.
- 액션 이름은 일어난 일을 적는다. (`queryChanged`, `searchSubmitted`)
- 리듀서에서 `URLSession`, `UserDefaults`, 현재 시각 같은 외부 세계를 직접 쓰지 않는다. `@DependencyClient` 로 감싸거나 TCA 가 제공하는 의존성을 주입받는다.
- 자식 Feature 는 `Scope`, `ifLet` 로 합성한다.
- HTTP 오류는 `HTTPClient` 가 `HTTPError` 로 바꿔서 넘긴다. Feature 는 `HTTPError` 만 보고 안내 문구를 정한다.

## 테스트

- Swift Testing(`@Test`)으로 쓴다. 리듀서는 `TestStore` 로 상태 변화를 빠짐없이 확인한다.
- 실제 네트워크를 호출하지 않는다. 의존성을 바꿔 끼우거나 `URLProtocol` 가짜 응답을 쓴다.
- 동작을 추가하거나 바꾸면 그 동작을 확인하는 테스트를 함께 넣는다.

## 작업 흐름

1. `/start-issue <번호>`: 이슈를 읽고 브랜치를 만든 뒤 계획을 확인받는다.
2. 구현한다. 결정 사항이 바뀌면 이슈 본문을 먼저 고친다.
3. `/verify`: 시뮬레이터 빌드와 테스트를 돌린다.
4. `reviewer` 서브에이전트로 변경분을 검토한다.
5. `/finish-issue`: 변경 내용을 확인받고 커밋, 푸시, PR 을 만든다.

지켜야 할 것:

- **커밋 전에 반드시 무엇이 들어가는지 보여주고 확인을 받는다.** 이전의 승인은 다음 커밋으로 이어지지 않는다.
- 머지는 사람이 코드를 본 뒤에 한다. 직접 머지하지 않는다.
- 확인하지 못한 것은 숨기지 않고 PR 과 보고에 적는다.
- `PROMPTS.md` 에는 hook 이 프롬프트를 자동으로 추가한다. 작업을 마칠 때 항목을 정리하되, 프롬프트 원문은 고치지 않고 무엇을 남길지는 확인을 받는다.
