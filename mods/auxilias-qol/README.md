# Auxilia's Quality of Life

Project Zomboid를 플레이하면서 발견한 불편함을 하나씩 개선하기 위한 개인 편의성 모드다.
현재 `0.1.0`은 기능을 정하기 전의 뼈대이며 게임 동작을 바꾸지 않는다.

## 프로젝트 구조

- `workshop/`: 게임과 Workshop에 설치할 모드 파일
- `source-assets/`: 대표 이미지 원본과 제작 자료
- `docs/`: 이 모드의 기능 설계와 실제 플레이 검증 기록
- `tools/`: 독립 검증, 패키징, 로컬 배포 도구

대상 게임 버전은 저장소의 `config/project-zomboid.json`에서 관리한다.
공유할 수 있는 엔진 사실은 `shared/knowledge`에, 이 모드만의 기능 결정과 테스트 기록은 `docs`에 둔다.

## 다음 작업

`docs/FEATURES.md`에 실제로 불편했던 상황과 원하는 동작을 적고, 기능 하나를 골라 구현한다.
기능을 추가할 때마다 로드, 실제 상호작용, 저장 및 불러오기를 확인한다.

```powershell
./tools/validate.ps1 -Mod auxilias-qol
./tools/package.ps1 -Mod auxilias-qol
```

현재는 게임에서 모드 선택 항목으로 로드할 수 있는 메타데이터와 빈 `media` 디렉터리만 제공한다.
