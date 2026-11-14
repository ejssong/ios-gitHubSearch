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
