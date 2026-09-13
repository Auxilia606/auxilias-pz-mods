# Auxilia's Quality of Life

Project Zomboid를 플레이하면서 발견한 불편함을 하나씩 개선하기 위한 개인 편의성 모드다.

첫 기능은 운행 가능한 일반 승용 차량을 분해하는 것이다. 용접 토치 사용량 10회와 용접 마스크가 필요하며, 동물·탑승자가 없고 견인 중이 아니며 엔진이 꺼진 차에서 사용할 수 있다. 적재 공간을 미리 비울 필요는 없다. 분해가 끝나면 모든 차량 부품 보관함의 아이템은 주변 바닥에 떨어지고 장착된 부품과 연료는 소모된다. 회수품과 경험치는 현재 바닐라 폐차 분해 규칙을 따른다. 자세한 조건과 남은 테스트 계획은 [기능 문서](docs/FEATURES.md)에, 사용자 플레이 확인 범위는 [확인 기록](docs/SMOKE-TEST.md)에 있다.

## 프로젝트 구조

- `workshop/`: 게임과 Workshop에 설치할 모드 파일
- `source-assets/`: 대표 이미지 원본과 제작 자료
- `docs/`: 이 모드의 기능 설계와 실제 플레이 검증 기록
- `tools/`: 독립 검증, 패키징, 로컬 배포 도구

대상 게임 버전은 저장소의 `config/project-zomboid.json`에서 관리한다.
공유할 수 있는 엔진 사실은 `shared/knowledge`에, 이 모드만의 기능 결정과 테스트 기록은 `docs`에 둔다.

```powershell
./tools/validate.ps1 -Mod auxilias-qol
./tools/package.ps1 -Mod auxilias-qol
```
