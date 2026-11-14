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
