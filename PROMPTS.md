# Prompts

이 과제를 진행하며 AI(Claude Code)에게 보낸 프롬프트 기록입니다.  
`.claude/hooks/log_prompt.py` hook 이 내가 입력한 본문만 자동으로 추가하고,
작업이 끝나면 프롬프트마다 구현 요소와 결과를 정리합니다.

## 1. 저장소 초기 파일

> .gitignore 랑 README 만들어서 첫 커밋 푸시해줘

**구현 요소**
- Xcode 용 `.gitignore`, 제목과 한 줄 소개만 있는 `README.md`
- 커밋 작성자는 이 레포에만 GitHub noreply 주소로 설정

**결과**
- 첫 커밋 `f507030` 을 `main` 에 푸시

## 2. 프롬프트 기록 hook

> 내가 보내는 프롬프트를 자동으로 기록하는 hook 을 세팅해줘.
> 내가 직접 쓴 본문만 남기고 시스템이나 플러그인이 끼워넣는 내용은 다 빼줘.
> 이 메시지는 hook 설치 전이라 안 남을 테니 첫 항목으로 직접 넣어주고, 다음 메시지부터 잘 기록되는지 확인해줘.

**구현 요소**
- `.claude/settings.json` 에 `UserPromptSubmit` hook 등록 (프로젝트 범위)
- `.claude/hooks/log_prompt.py` 가 hook 입력의 `prompt` 필드만 꺼내 `PROMPTS.md` 에 인용문으로 추가
- `<system-reminder>` 같은 시스템 블록은 제거하고, 남는 본문이 없으면 기록하지 않음
- 기록 실패가 프롬프트 전송을 막지 않도록 stdout 출력 없이 항상 정상 종료

**결과**
- 샘플 입력(여러 줄 본문, 시스템 블록 혼입, 빈 입력, 깨진 입력)으로 스크립트 동작 확인
- 커밋 `357f6ea`

## 3. 프로젝트 골격

> SwiftUI + TCA 로 GitHub 저장소 검색 앱 과제를 진행할 거야.
> 로컬 SPM 패키지 구조로 프로젝트 구성해주고, minimum iOS 17, Swift 6 이고, TCA 는 여기 호환되는 버전으로 설치해줘.
> gitignore 도 Xcode, SPM 에 맞게 세팅하고, TCA import 한 상태로 시뮬레이터 빌드까지 확인해줘.

**구현 요소**
- 얇은 앱 셸(`GitHubSearch.xcodeproj`, `App/`) + 로컬 패키지 `GitHubSearchKit`
- 앱 타깃은 `AppFeature` 하나만 링크하고, 모듈은 `GitHubSearchKit/Package.swift` 에서 추가
- 최소 iOS 17, Swift 6 언어 모드, TCA `1.26.2` exact 고정
- `.gitignore` 를 Xcode·SPM 항목으로 정리하고 `Package.resolved` 는 추적

**결과**
- iPhone 17 (iOS 26.2) 시뮬레이터 빌드 성공
- 커밋 `21ed32e`

## 4. 요구사항 정리와 질문

> 과제 요구사항 & 예시 이미지 공유할게.
> 아직 구현하지 말고, 읽어보고 애매하거나 내가 정해야 하는 부분 있으면 질문으로 정리해줘.
>
> 해당 요구사항 보고 GitHub Issues 로 관리할꺼야.
> 프로젝트 설계 부터 ~ '검색 화면' → '검색 결과 화면' 순서로 작업할거고, 추가 구현은 가장 마지막에 작업할꺼야.

함께 전달한 요구사항 원문과 예시 이미지는 [docs/requirements/requirements.md](docs/requirements/requirements.md) 에 있습니다.

**구현 요소**
- 요구사항 원문을 `docs/requirements/requirements.md` 로 정리 (검색 화면, 검색 결과 화면, 추가 구현, endpoint)
- 예시 이미지를 `docs/sampleImage/` 에 저장 (`search.png`, `search-result.png`)

**결과**
- 구현 없이, 요구사항만으로 정해지지 않는 부분을 질문 20개로 정리
  - 검색 화면 6개: 검색 실행 시점, 중복 검색어 처리, 저장 방식, 최근 검색어 배치, 전체삭제 확인, 취소 동작
  - 검색 결과 화면 7개: 화면 전환 방식, WebView 구현, 오류·빈 결과 표시, 첫 검색 로딩, 페이지 크기와 끝 처리, 다음 페이지 호출 시점, 썸네일 로딩
  - 공통 5개: 외부 라이브러리, 자동완성 매칭, 모듈 구성, 테스트 범위, 지원 범위
  - 이슈 관리 2개: 이슈 단위, 작업 흐름

## 5. 모듈 구조와 HTTPClient (#1)

> 이슈 #1 작업 시작할게. 브랜치 만들어서 진행해줘.
>
> 코드 작성 전에 타깃 의존 방향이랑 Core 클라이언트 두 개의 인터페이스 초안 먼저 보여줘.
>
> - SearchFeature, SearchResultFeature 는 빈 리듀서랑 빈 화면까지만.
> - 테스트 타깃마다 테스트가 최소 하나는 돌게 해줘. 실제 네트워크 호출은 없이
> - HTTP 에러는 클라이언트 안에서 의미 있는 에러로 바꿔서 넘길거야.
>
> 빌드랑 테스트 통과 확인하고 PR 올려줘. 머지는 내가 코드 보고 나서 할게.

초안을 확인한 뒤 보낸 수정 요청입니다.

> 전체적으로 모듈 구조는 정리된 것 같고, 아래로 해당 역할을 분명하게 해줘. (이건 실제 feature 구현 할 때)
> - SearchFeature : 검색어 입력, 최근 검색어 저장/삭제, 검색 실행 전달
> - SearchResultFeature : 검색 API/DTO, 결과, 로딩, 오류, 페이지 상태
> - Core : HTTPClient
>
> HTTPError도 조금 단순하게 수정해줘.
> - network, rateLimited, invaliedRequest, unknown 만 남겨주고

**구현 요소**
- 의존 방향: `AppFeature` → `SearchFeature` → `SearchResultFeature` → `Core`
- `Core` 는 `HTTPClient` 만 두고 `swift-dependencies` 에만 의존. 초안에 있던 UserDefaults 클라이언트는 제외하고, 최근 검색어 저장은 `SearchFeature` 의 역할로 정리
- `HTTPError` 는 `network`, `rateLimited`, `invalidRequest`, `unknown` 네 가지. 상태 코드와 연결 오류를 클라이언트 안에서 변환
- `SearchFeature`, `SearchResultFeature` 는 빈 리듀서와 빈 화면
- 테스트는 Swift Testing. `HTTPClient` 는 `URLProtocol` 가짜 응답으로 실제 네트워크 없이 검증

**결과**
- 시뮬레이터 빌드 성공, 테스트 13개 통과 (`CoreTests` 10개, Feature 테스트 각 1개)
- 이슈 #1 본문을 바뀐 결정에 맞게 수정하고 PR 로 올림 (머지는 코드 확인 후)

## 6. 로컬 패키지를 폴더 구조로 변경 (#9)

Xcode 에서 패키지 구조를 확인한 뒤 보낸 프롬프트입니다.

> 기존 요구사항이었어? GitHubSearchKit 으로 하는게? 그냥 폴더로만 관리하는게 좋을 것 같은데

> Issues 새로 만들어서 fix 로 구현해줘

> -skipMacroValidation 관련해서는 README 에 넣어주세요.

> Core 에서도 Network 로 정리해줘

**구현 요소**
- 로컬 패키지는 과제 요구사항이 아니었고, 화면 3개 규모에 모듈 4개는 과하다고 판단해 3번 항목의 결정을 변경
- `GitHubSearchKit` 을 삭제하고 앱 타깃 폴더로 이동: `App/Core/Network`, `App/Search`, `App/SearchResult`. 역할 구분은 그대로이고 의존 방향은 규칙으로 유지
- TCA 를 프로젝트에 직접 연결 (1.26.2 고정 유지), 테스트 타깃 `GitHubSearchTests` 와 공유 스킴 추가
- 모듈 경계용 `public` 선언 제거. 동작 변경 없음
- README 에 매크로 신뢰 확인(Trust & Enable)과 명령줄의 `-skipMacroValidation` 설명 추가

**결과**
- 이슈 #9 생성 (라벨 `fix`)
- 시뮬레이터 빌드 성공, 기존 테스트 13개가 새 테스트 타깃에서 통과

## 7. 검색창과 검색 실행 (#2)

> 이어서 #2로 넘어가주세요

구조 변경(#9)이 머지된 뒤 이어서 보낸 프롬프트입니다.

> #2 작업 하던거 이어서 하자.

**구현 요소**
- `SearchFeature` 상태는 입력 중인 `query` 와 결과 영역 `result` (없으면 `nil`)
- 키보드의 검색 버튼을 눌렀을 때만 검색 실행. 앞뒤 공백을 뺀 검색어로 `SearchResultFeature` 상태를 만들어 전달하고, 빈 검색어는 무시
- 검색어를 지우거나("취소" 포함) 고치면 결과 영역을 닫음
- 화면은 큰 제목 "Search" 와 항상 보이는 검색창(placeholder "저장소 검색"). 결과는 같은 화면 안에서 전환
- 시스템 "취소" 버튼이 한국어로 나오도록 프로젝트 기본 언어를 `ko` 로 변경

**결과**
- 시뮬레이터 빌드 성공, 테스트 18개 통과 (`SearchFeatureTests` 6개)

## 8. 최근 검색어 (#3)

> /start-issue 3

계획과 질문 네 가지를 받은 뒤 보낸 프롬프트입니다.

> 1. @DependencyClient 로 진행해주세요. 여러 Feature가 같은 저장값을 공유해야 되는 상황은 아니기 때문에
> 2. 검색어가 비어 있을 때 "2. 검색어가 비어있을 시, 최근 검색어를 최대 10개까지 보여줍니다." 요구 사항 임
> 3. 표시해주세요. mm.dd 로
> 4. viewAppeared 액션으로 읽어주세요. 테스트 환경에서도 화면 진입 -> 목록 로드 -> 상태 변경을 검증할 수 있고, State 생성은 값 초기화만 담당하도록 하는 편이 나을 것 같습니다.
>
> 추가로 의견있거나 잘못된 판단 있으면 알려줘

> /finish-issue

**구현 요소**
- `RecentSearch` (검색어, 검색 시각) 와 UserDefaults 를 감싼 `RecentSearchClient` (`@DependencyClient`, 목록을 JSON 으로 통째로 읽고 씀)
- 화면이 나타날 때(`viewAppeared`) 목록을 읽음. `State` 생성은 값 초기화만 담당
- 검색 실행과 최근 검색어 선택은 같은 경로: 앞뒤 공백 제거, 대소문자 무시로 중복을 지우고 지금 시각으로 맨 위에 기록, 10개 초과분은 버림
- 개별 삭제와 전체 삭제(확인 없음). 바뀔 때마다 리듀서에서 바로 저장. 처음에는 `.run` 이펙트로 저장했으나 연속 저장의 순서가 보장되지 않는다는 리뷰 지적으로 변경
- 화면은 검색어가 비어 있을 때만 "최근 검색" 세로 목록, 항목마다 `MM.dd` 날짜와 ✕, 머리글에 "전체삭제"

**결과**
- 시뮬레이터 빌드 성공, 테스트 31개 통과 (`SearchFeatureTests` 14개, `RecentSearchClientTests` 3개, `RecentSearchTests` 2개)
- 이슈 #3 결정 사항에 날짜 표시와 저장 방식을 추가
- 시뮬레이터에서 직접 눌러 보는 확인은 하지 않음

## 9. 결과 목록과 총 결과 수 (#4)

#3 의 커밋·PR 계획을 확인한 뒤 보낸 프롬프트입니다.

> 네 진행해주세요

> /start-issue 4

계획과 질문 세 가지를 받은 뒤 보낸 프롬프트입니다.

> 1. A로
> 2. B로 진행. 전체적인 요구사항을 봤을 때는 호출 하나뿐이라 리듀서가 httpClient 하나로 쓰는 것도 가능하지만, 확장성이랑 책임분리를 생각했을 때 B로 진행하는게 좋을 것 같은데 의견 줘. 대신 확실하게 해야할 건 SearchResultFeature / RepositorySearchClient / HTTPClient 의 역할을 정확하게 구분해줘. 
> 3. 인증 없이 진행

구현과 리뷰 반영을 마친 뒤, 서버 주소와 요청 정의의 위치를 정리하며 보낸 프롬프트입니다.

> 지금 서버 주소 & 공통 해더가 feature 내부에 있는데 이걸 App/Configuration 으로 빼고
> SearchResult/API 내에 실제 Endpoint 와 Response 를 위치하는건 어떨까?

> SearchRepositoriesEndpoint 내에는 아직 extension HTTPRequest가 남아 있어, 전용 Endpoint 타입으로 바꾸고 싶어.

> path 랑 queryItem 도 GitHubAPI 에서 관리하는건 어때?
> 그럼 검색 클라이언트에서도 GitHubAPI.searchRepositoreis(keyword: , page ) 로 단순해질 것 같은데 Configuration 을 App/API/GitHubAPI 로

> /finish-issue

커밋 전 확인에서 리뷰가 찾은 `+` 문제를 물은 뒤, 이 PR 에 포함하기로 하며 보낸 프롬프트입니다.

> + 문제는 뭐야?

> B 로 진행해주세요

**구현 요소**
- 역할을 네 곳으로 나눔: `GitHubAPI` (서버 주소, 공통 헤더, 경로와 쿼리로 요청 생성), `HTTPClient` (전송, `HTTPError` 변환), `RepositorySearchClient` (요청 실행, DTO → `RepositoryItem` 변환), `SearchResultFeature` (요청 시점과 취소, 로딩·성공·실패 상태, 안내 문구)
- 요청 정의의 위치는 `SearchResult` 안 → `App/Configuration` + 전용 Endpoint 타입 → `App/API/GitHubAPI` 순으로 바꿈. 이 규모에서는 요청을 한곳에 모으는 쪽이 단순하다고 판단
- 검색은 `SearchFeature` 가 결과 상태를 만든 직후 `.result(.searchRequested)` 로 시작. 같은 검색어를 다시 제출해도 다시 검색하고, 진행 중이던 요청은 취소
- 화면은 총 결과 수(`266,714개 저장소`), 썸네일(`AsyncImage`)·제목·설명 목록, 첫 로딩 표시, 빈 결과와 오류 안내에 "다시 시도" 버튼
- 리뷰 반영: 응답 전 검색어를 지우거나 다시 제출하는 경우의 취소 테스트, `owner` 가 `null` 인 항목 허용, 기본 클라이언트가 호출 시점의 `httpClient` 를 쓰도록 변경
- `CLAUDE.md` 구조 표에 `App/API` 를 추가하고 의존 방향을 `Search` → `SearchResult` → `API` → `Core` 로 수정

**결과**
- 시뮬레이터 빌드 성공, 테스트 53개 통과
- 이슈 #4 결정 사항에 검색 시작 방식, 역할 구분, 인증 없음, 폴더 구성을 추가
- 리뷰에서 검색어의 `+` 가 공백으로 검색되는 문제(`c++` → `c`)를 발견. `HTTPClient` 가 쿼리의 `+` 를 `%2B` 로 보내도록 함께 수정
- 시뮬레이터에서 직접 눌러 보는 확인은 하지 않음

## 10. WebView 이동 (#5)

> /start-issue 5

계획과 질문 네 가지를 받은 뒤 보낸 프롬프트입니다.

> 1. A로
> 2. A로
> 3. 네
> 4. 네 진행해주세요

구현을 마친 뒤 보낸 프롬프트입니다.

> WebView 도 SearchResult/WebView 로  View / Feature 로 명확히 구분해줘.

> /finish-issue

커밋에 들어갈 내용을 확인하며 보낸 프롬프트입니다.

> 네 진행해주세요

> 네

**구현 요소**
- WebView 화면을 `App/SearchResult/WebView` 에 `RepositoryWebFeature` (주소, 제목, 불러오는 중인지) 와 `RepositoryWebView` (`WKWebView` 를 감싸고 시작·끝을 액션으로 알림) 로 나눔. 처음에는 로딩 상태를 뷰의 `@State` 로 둔 화면 하나였음
- 이동은 `SearchResultFeature` 의 `@Presents var webPage` 로 연결. 행을 누르면 `repositoryTapped`, 뒤로 가면 `webPage(.dismiss)`, 다시 검색하면 닫힘
- 주소는 응답의 `html_url`. `http`/`https` 이고 host 가 있는 주소만 받아들이고, 주소가 없는 항목은 눌러도 이동하지 않음
- 로딩 표시는 콜백 종류가 아니라 웹뷰의 현재 상태(`isLoading`)를 따름. 링크를 연달아 누르거나 웹 콘텐츠 프로세스가 죽는 경우에 표시가 어긋나던 것을 리뷰 지적으로 고침
- `.claude/agents/reviewer.md` 의 의존 방향을 `Search` → `SearchResult` → `API` → `Core` 로 수정

**결과**
- 시뮬레이터 빌드 성공, 테스트 64개 통과
- 이슈 #5 결정 사항에 이동 방식, 폴더 구성, 주소 처리, 로딩 표시를 추가
- WebView 화면(push, 페이지 표시, 로딩 표시, 뒤로 가기)은 시뮬레이터에서 확인하지 않음

## 11. 자동완성 (#6)

> /start-issue 6

계획과 질문 두 가지(브랜치를 어디서 낼지, 날짜 형식)를 받은 뒤 보낸 프롬프트입니다.

> 1. PR 머지했어
> 2. B 로 통일

> /finish-issue

커밋에 들어갈 내용을 확인하며 보낸 프롬프트입니다.

> 네

**구현 요소**
- 후보는 저장하지 않고 `SearchFeature.State.suggestions` 가 검색어와 최근 검색어에서 계산. 앞뒤 공백을 빼고 대소문자를 무시해 앞부분이 일치하는 항목만, 날짜 내림차순으로
- 검색어가 비어 있거나 결과 화면이 떠 있으면 후보 없음. 결과를 보다가 검색어를 고치면 다시 나옴
- 후보를 누르면(`suggestionTapped`) 최근 검색어를 눌렀을 때와 같은 경로로 검색창을 채우고 검색 실행
- 화면은 입력 중에 검색어와 오른쪽 날짜만 있는 목록. 날짜는 예시의 "03. 09." 대신 최근 검색어 목록과 같은 `03.09` 로 통일

**결과**
- 시뮬레이터 빌드 성공, 테스트 72개 통과
- 이슈 #6 결정 사항에 날짜 형식 변경과 후보 조건·순서·선택 동작을 추가
- 알려진 제한: 한글은 조합 중인 글자(예: "스윞") 때문에 후보가 잠깐 사라졌다가 다시 나옴
- 시뮬레이터에서 직접 눌러 보는 확인은 하지 않음

## 12. 다음 페이지 미리 호출과 로딩 표시 (#7)

> /start-issue 7 
> 끝에서 10번째 정확히 지정한건 아니라서 prefetching 으로 구현해줘.

계획과 질문 두 가지(prefetch 구현 방식, 다음 페이지 실패 시 처리)를 받은 뒤 보낸 프롬프트입니다.

> 1. LazyVStack 이랑 onScrollTargetVisibilityChange 활용해서 해줘.
> 2. A

`onScrollTargetVisibilityChange` 가 iOS 18 부터라는 안내를 받은 뒤 보낸 프롬프트입니다.

> 1. 아니야 점유율 생각해서 17 유지하고 onAppear 로 진행해주세요

> "prefetch 거리는 한 페이지의 절반인 15개" 이건 디바이스 마다 다를건데

> % 로 지정해주세요

구현을 마친 뒤 보낸 프롬프트입니다.

> if let notice = store.notice { 이부분 switch case 로 변경해줘

> /finish-issue

커밋에 들어갈 내용을 확인하며 보낸 프롬프트입니다.

> 네

**구현 요소**
- 행이 화면에 나타날 때(`onAppear`) 리듀서에 알리고, 그 행이 불러온 목록의 70% 지점을 지났으면 다음 페이지를 요청. 기준은 항목 수가 아니라 비율이고 상수 하나(`prefetchThresholdPercent`)
- 기준이 정해진 과정: 이슈의 "끝에서 10번째 항목" → `onScrollTargetVisibilityChange` (iOS 18 부터라 최소 iOS 17 을 유지하려고 제외) → `onAppear` 와 고정 거리 15개 (기기마다 보이는 행 수가 달라 제외) → 비율
- 요청 중에는 다시 요청하지 않음. 전체 건수 또는 1,000건(API 상한)까지 불러왔거나 빈 페이지가 오면 멈춤. 이미 있는 저장소는 다시 붙이지 않음
- 다음 페이지 실패 시 목록은 그대로 두고 맨 아래에 안내와 "다시 시도". 스크롤만으로는 다시 요청하지 않음
- 새 검색이나 첫 페이지 "다시 시도"가 오면 진행 중인 다음 페이지 요청을 취소
- `SearchResultView` 의 분기를 `switch store.phase` 로 정리. 목록은 `List` 그대로, 요청 중이면 맨 아래에 로딩 표시 행

**결과**
- 시뮬레이터 빌드 성공, 테스트 90개 통과
- 실제 API 로 `page=34` 는 200(30건), `page=35` 는 422 임을 확인. 1,000건 상한 판단과 일치
- 이슈 #7 결정 사항을 비율 기준으로 고치고 실패 처리, 중복 제거, 취소를 추가
- 시뮬레이터에서 직접 스크롤해 보는 확인은 하지 않음

## 13. TCA + Clean Architecture 구조로 변경 (#19)

> 전체적으로 폴더 구성을 아래와 같이 구성해주고 싶은데 피드백 해줘.
> - App
> - Feature
>   ㄴ Search
>   ㄴ SearchResult
>   ㄴ WebView
> - Domain
>   ㄴ Entities
>   ㄴ Repositories
> - Data
>   ㄴ Network

피드백(인터페이스와 구현 분리, 저장 구현의 위치, `HTTPError` 의 위치 등)을 받은 뒤 보낸 프롬프트입니다.

> TCA + Clean Architecture 구조로 변경하고 싶어. Issues 만들어주고 작업할거야.
> 1. 네
> 2. Data/UserDefaults 로 진행해주세요
> 3. Data — HTTPError 를 정하고 Domain -  Repositories 에서 실제 안내 문구를 지정해주세요

이슈 #19 를 만든 뒤, 타입 이름을 묻는 항목에 답한 프롬프트입니다.

> Repository 로 바꾸겠습니다.

> /start-issue 19

계획과 질문 네 가지(오류 타입, 타입 이름, 소스 폴더 위치, GitHub 하위 폴더)를 받은 뒤 보낸 프롬프트입니다.

> 추천대로 해주세요

> /finish-issue

커밋에 들어갈 내용을 확인하며 보낸 프롬프트입니다.

> 네

PR 을 올린 뒤, 같은 PR 에 이어서 통신 계층을 바꾸며 보낸 프롬프트입니다.

> HTTPClient / HTTPError / HTTPRequest 쪽 
> protocol APIClientProtocol: Sendable {
>   func get<Response: Decodable>( ) async throws -> Response 
> }
> 프로토콜 생성해주고
> Data/Network/Search 
> 로 SearchAPIClient 에서 해당 프로토콜 채택해서 만들어줘

> 1. B로 진행해주고 테스트 코드도 다시 
> 2. path 랑 queryItems
> 3. A 로

> GitHubAPI 랑 SearvhAPIClient 랑 합치는 방법은?

합치는 방법 두 가지(프로토콜 확장에 검색 메서드를 두는 A, `SearchAPIClient` 에만 두는 B)를 받은 뒤 보낸 프롬프트입니다.

> A로 진행해주세요

> 네 진행해주세요

**구현 요소**
- 폴더를 `Application` / `Feature` / `Domain` / `Data` 로 나눔. 의존 방향은 `Feature` → `Domain` ← `Data`
- 저장소를 인터페이스와 구현으로 분리: 선언과 `testValue` 는 `Domain/Repositories` (`SearchRepository`, `RecentSearchRepository`), `liveValue` 는 `Data/Network/GitHub` 와 `Data/UserDefaults`
- 오류를 두 단계로 나눔: `Data` 의 `HTTPError` 를 저장소 구현이 `Domain` 의 `SearchError` 로 바꿔 넘기고, 안내 문구는 `SearchError.message` 가 정함. 리듀서는 `HTTPError` 를 더 이상 보지 않음
- 통신 계층은 `APIClientProtocol` (`get(path:queryItems:)`) 과 이를 채택한 `Data/Network/Search/SearchAPIClient` 로 구성. `SearchAPIClient` 가 서버 주소와 공통 헤더를 알고 `URLSession` 으로 전송하며 `HTTPError` 변환, `+` 인코딩, JSON 해석을 맡음. 처음 구조 변경 때 옮겨 두었던 `HTTPClient`, `HTTPRequest` 는 삭제
- `GitHubAPI` 는 `SearchAPIClient` 에 합침. 검색 endpoint 의 경로와 쿼리는 `APIClientProtocol` 확장의 `searchRepositories(keyword:page:)` 가 정함. 저장소 구현은 프로토콜만 보고, 테스트에서는 가짜 구현(`StubAPIClient`)으로 바꿔 끼움
- 소스는 `App/` 아래에 두어 `project.pbxproj` 를 고치지 않음. UseCase 계층은 두지 않음
- `CLAUDE.md` 의 구조 표·의존 방향·오류 규칙과 `.claude/agents/reviewer.md` 의 의존 방향을 새 계층에 맞춤

**결과**
- 시뮬레이터 빌드 성공, 테스트 91개 통과. 동작 변경 없음 (안내 문구 동일)
- `HTTPClient` 에 붙어 있던 테스트는 `SearchAPIClient` 테스트로 다시 씀
- `Feature`, `Application`, `Domain` 에서 `Data` 의 타입을 쓰는 코드가 없음을 `grep` 으로 확인
- 로직의 위치는 바꾸지 않아, 화면 표현에 가까운 `RecentSearch.searchedDateText` 등이 `Domain` 에 남아 있음
- 시뮬레이터에서 화면이 그대로인지 직접 확인하지는 않음
