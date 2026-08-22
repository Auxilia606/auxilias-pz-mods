# Auxilia Project Zomboid Mods

여러 Project Zomboid 모드를 한곳에서 개발하기 위한 모노레포다. 각 모드는 독립적으로
배포할 수 있지만, 게임 버전 기준·엔진 지식·재사용 Lua·검증 도구·Workshop 비주얼 규칙은
레포 전체가 공유한다.

## 구조

| 경로 | 역할 |
|---|---|
| `mods/<slug>/` | 모드별 버전, 문서, 원본 자산, Workshop 배포 트리 |
| `config/` | 등록된 모드와 공통 Project Zomboid 대상 버전 |
| `shared/knowledge/` | 모드 개발에서 확인한 엔진 동작과 재사용 가능한 작업 방식 |
| `shared/lua/` | 여러 모드에 복사해 배포할 공통 런타임 Lua의 원본 |
| `shared/branding/` | Workshop 썸네일·포스터의 브랜드 규격과 템플릿 |
| `tools/` | 전체 모드 검증, 패키징, 배포, 공통 코드 동기화 |

현재 포함된 모드:

- [Auxilia's Crossbow](mods/auxilias-crossbow/README.md)

## 공통 명령

```powershell
# 모든 모드 검증
./tools/validate.ps1

# 특정 모드만 검증 또는 패키징
./tools/validate.ps1 -Mod auxilias-crossbow
./tools/package.ps1 -Mod auxilias-crossbow

# 특정 모드 또는 등록된 모든 모드를 로컬 게임 폴더에 배포
./tools/deploy.ps1 -Mod auxilias-crossbow
./tools/deploy.ps1 -All

# 모든 모드의 릴리스 패키지 생성
./tools/package.ps1

# 공통 Lua를 등록된 모드 배포 트리에 동기화
./tools/sync-shared.ps1
```

패키지는 기본적으로 `dist/<mod-slug>/`에 생성된다. 로컬 게임 설치는
`./tools/deploy.ps1 -Mod <slug>`를 사용하며, `./tools/deploy.ps1 -All`은
`config/mods.json`에 등록된 모든 모드를 배포한다. 기본 배포 루트는
`$env:USERPROFILE\Zomboid\Workshop`이고 `-DestinationRoot <path>`로 바꿀 수 있다.

## 공통 변경 정책

Project Zomboid 대상 버전의 단일 기준은
[`config/project-zomboid.json`](config/project-zomboid.json)이다. 이 값을 바꾸면 루트
검증이 모든 모드의 버전 디렉터리와 `versionMin`을 함께 검사하므로 일부 모드만 이전
버전에 남은 상태로 릴리스할 수 없다. 버전 변경 절차와 지원 판정 기준은
[`shared/knowledge/GAME-VERSIONING.md`](shared/knowledge/GAME-VERSIONING.md)에 있다.

새 모드는 [`config/mods.json`](config/mods.json)에 등록하고 기존 모드와 같은 프로젝트
경계를 사용한다. 공통으로 확인된 로직은 개별 모드 문서에 복사하지 않고
`shared/knowledge`에 기록한다. 실제 런타임 코드 공유가 필요하면 `shared/lua`를 원본으로
두고 모드 등록 정보의 `sharedLua` 매핑으로 배포 위치를 선언한다.
구체적인 디렉터리와 완료 게이트는
[`shared/knowledge/ADDING-A-MOD.md`](shared/knowledge/ADDING-A-MOD.md)를 따른다.

## 비주얼 아이덴티티

모든 Workshop 이미지는
[`shared/branding/BRAND-GUIDE.md`](shared/branding/BRAND-GUIDE.md)의 캔버스, 팔레트,
조명, 구도 규칙을 따른다. 루트 검증은 512×512 출력물 세 개(`preview.png`, `poster.png`,
`icon.png`)가 동일한 파일인지와 고해상도 원본 존재 여부를 검사한다.

## 라이선스

저장소 코드는 [MIT License](LICENSE)로 배포한다. Project Zomboid와 관련 상표는
The Indie Stone에 속하며, 이 저장소의 모드는 비공식 커뮤니티 프로젝트다.
