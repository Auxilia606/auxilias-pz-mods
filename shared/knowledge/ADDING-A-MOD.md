# 새 모드 추가 절차

## 프로젝트 경계 만들기

새 모드는 `mods/<slug>` 아래에서 기존 모드와 독립적으로 설치·검증·배포할 수 있어야 한다.
최소 구조는 다음과 같다.

```text
mods/<slug>/
├── README.md
├── CHANGELOG.md
├── VERSION
├── docs/
├── source-assets/
├── tools/
│   ├── validate.ps1
│   ├── package.ps1
│   └── deploy.ps1
└── workshop/
    ├── workshop.txt
    ├── preview.png
    └── Contents/mods/<ModId>/
        ├── mod.info
        ├── icon.png
        ├── poster.png
        └── <releaseLine>/
            ├── mod.info
            └── media/
```

`workshop`은 다른 레포 파일 없이 그대로 설치 가능한 트리여야 한다. 직접 편집하는 이미지와
Blender 파일은 `source-assets`에 두고, 생성 결과만 `workshop`에 넣는다.

## 등록하기

`config/mods.json`에 다음 필드를 추가한다.

- `slug`: 디렉터리·명령·릴리스 태그에 쓰는 소문자 kebab-case 이름
- `displayName`: 사용자에게 보이는 이름
- `modId`: `mod.info`의 안정적인 내부 ID
- `path`: 레포 루트 기준 프로젝트 경로
- `packageName`: ZIP과 로컬 Workshop 폴더 이름
- `releaseTagPrefix`: 보통 `<slug>/v`
- `coverSource`: 프로젝트 기준 고해상도 대표 이미지 경로
- `sharedLua`: 공통 Lua 원본과 버전별 `media` 아래 배포 위치의 매핑

모드별 `tools/validate.ps1`은 그 기능의 ID, 번역, 레시피, 모델과 생성 자산을 깊이 검사한다.
`package.ps1`은 Workshop 트리를 ZIP으로 만들고 원본과 파일 수·크기·해시를 비교하며,
`deploy.ps1`은 전용 로컬 폴더를 안전하게 교체한 뒤 같은 비교를 수행한다.
루트 검증은 공통 버전, 메타데이터, 브랜드 이미지, 공통 Lua와 등록부 일관성을 검사한 뒤 이
모드 전용 검증기를 호출한다.

## 첫 수직 단면

대표 기능 하나를 등록 → 획득 → 사용 → 저장/불러오기까지 연결한다. 처음부터 많은 변형을
복사하지 않는다. 확인한 엔진 동작이 다른 모드에도 유효하면 `shared/knowledge`에 게임 빌드,
재현 단계, 성공·실패 근거와 함께 기록한다.

## 완료 게이트

1. `./tools/validate.ps1 -Mod <slug>`가 통과한다.
2. `./tools/package.ps1 -Mod <slug>`가 ZIP과 SHA-256을 만든다.
3. 깨끗한 설치에서 로드 및 핵심 상호작용을 확인한다.
4. `mods/<slug>/docs`에 실제 시험 결과를 남긴다.
5. `<slug>/v<VERSION>` 태그로 해당 모드만 릴리스한다.
