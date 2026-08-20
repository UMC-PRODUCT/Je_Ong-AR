# Jeong-AR

실물 카드에 인쇄된 **Apple 기술 로고를 ARKit 이미지 인식으로 식별**하고, 카드를 터치하면 그 카드 위에 로고와 기술 설명이 떠오르는 부스 전시용 AR 앱입니다.

[![Swift](https://img.shields.io/badge/Swift-6.1-orange.svg)]()
[![Xcode](https://img.shields.io/badge/Xcode-16.4-blue.svg)]()
[![License](https://img.shields.io/badge/license-MIT-green.svg)]()

<br>

## 📱 동작 방식

```
① 스캔          ② 인식          ③ 열람
책상에 엎어둔     ARReferenceImage  카드를 터치하면
카드를 iPad로     로 각 카드를      그 카드 위에 로고 +
비춘다            개별 식별         설명 패널이 뜬다
```

1. **스캔** — 책상 위에 Apple 기술 로고가 인쇄된 카드를 엎어놓고, iPad 카메라로 훑는다.
2. **인식** — ARKit이 각 카드의 뒷면 로고를 `ARReferenceImage`로 식별해 `ARImageAnchor`를 붙인다. 카드마다 로고가 다르므로 어떤 기술의 카드인지 구분된다.
3. **열람** — 화면에서 원하는 카드를 터치하면, 실물 카드 바로 위 공간에 해당 로고 이미지와 기술 설명 텍스트가 떠오른다.

가상 카드를 3D로 렌더링하지 않습니다. 실물 카드가 이미 존재하므로 AR은 **"어느 카드인지 식별"** 과 **"그 위에 정보를 띄우는"** 역할만 맡습니다.

<br>

## ⚒️ 기술 스택

| ![SwiftUI](https://developer.apple.com/assets/elements/icons/swiftui/swiftui-96x96_2x.png) | ![ARKit](https://developer.apple.com/assets/elements/icons/arkit/arkit-96x96_2x.png) | ![RealityKit](https://developer.apple.com/assets/elements/icons/realitykit/realitykit-96x96_2x.png) |
|:------:|:------:|:------:|
| SwiftUI | ARKit | RealityKit |

- **ARKit** — `ARWorldTrackingConfiguration.detectionImages` 기반 이미지 인식
- **RealityKit** — `ARImageAnchor` 위 패널 엔티티 배치, 텍스처 렌더링
- **SwiftUI** — 오버레이 UI, `@Observable` ViewModel
- **SwiftData** — 카드 데이터 영속화
- **Tuist** — 모듈 구성 (`UMCAR`, `ARCore`, `Dependency`)

<br>

## 🤔 요구사항

- Xcode 16.4 이상
- Tuist 4.61.x 이상
- **ARKit 이미지 인식을 지원하는 실기기** (시뮬레이터 불가)

```bash
cd UMCAR
tuist install
tuist generate
```

<br>

## 📂 프로젝트 구조

```
UMCAR/
├── UMCAR/          앱 타깃 — SwiftUI 화면, ViewModel, SwiftData 모델
├── ARCore/         AR 프레임워크 — ARKit/RealityKit 로직 일체
│   ├── Sources/UIComponents/   ARContainerViewController (+ extensions)
│   ├── Sources/Features/AR/    카드 감지·배치 기능 제공자
│   ├── Sources/Features/DynamicTexture/  패널 이미지 렌더링·캐시
│   ├── Sources/System/         RealityKit System
│   └── Sources/Components/     RealityKit Component
└── Dependency/     DIContainer
Tools/              카드 데이터 CSV → JSON 변환 스크립트
```

<br>

## 🚧 현재 상태

이 저장소는 영어 발음 학습 게임(**Konglish**)의 코드베이스에서 출발해 위 방식으로 전환하는 중입니다.
평면 스캔·포탈 연출·가상 카드 배치·발음 채점으로 구성된 기존 구조가 이미지 인식 기반으로 교체됩니다.

**전환 계획, 파일별 작업 목록, 카드 인쇄 요구사항, 미결정 사항은 [`Docs/IMPLEMENTATION.md`](./Docs/IMPLEMENTATION.md)를 참고하세요.**

<br>

## 📆 프로젝트 기간

- 원본(Konglish) 챌린지: `2025.06.25 ~ 2025.07.28`
- AR 카드 인식 전환: `2026.08 ~`
