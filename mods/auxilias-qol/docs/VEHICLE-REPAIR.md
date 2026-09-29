# 탈거 차량 부품 수리

기능 구현 및 자동 검사 완료, 게임 내 수동 시험 전이다. 기존 모드의 `AQoL` 이름과
B42 `craftRecipe` 구조를 사용한다. 샌드박스 옵션 체계가 없어 이번에는 Config 상수로 둔다.

## 사용법과 대상

부품을 탈거해서 자신의 소지품 또는 휴대한 가방에 넣고, 제작 화면의 수리 분류에서
`탈거한 브레이크/서스펜션/머플러/타이어 수리`를 선택한다. 작업 가능한 표면과 렌치가
필요하다. 렌치와 수리 대상은 유지되며 재료만 소모된다. 기술·잡지 선행 조건은 없다.

| 부품 | 실제 바닐라 item stem (각각 접미사 1/2/3) | 개수 | 소모 재료 |
|---|---|---:|---|
| 브레이크 | OldBrake, NormalBrake, ModernBrake | 9 | ScrapMetal 2개 + DuctTape 2회 |
| 서스펜션 | NormalSuspension, ModernSuspension | 6 | ScrapMetal 2개 + DuctTape 2회 |
| 머플러 | OldCarMuffler, NormalCarMuffler, ModernCarMuffler | 9 | ScrapMetal 2개 + DuctTape 2회 |
| 타이어 | OldTire, NormalTire, ModernTire | 9 | TirePiece 1개 + DuctTape 2회 |

모두 `Base.` 접두사의 정확한 ID만 허용한다. 차량 템플릿과 아이템 정의에서 선정한
33종이며, 임의의 모드 부품이나 차체·유리·좌석·배터리·엔진은 포함하지 않는다.
기존 Fixing 정의나 일반 접착 수리 태그가 있는 대상으로 바뀌면 이 수리법에서는 제외한다.
임의의 다른 모드가 독자적으로 추가한 제작 수리법까지 자동 판별하지는 않는다.

## 수리량과 수리 횟수

`AQoLVehicleRepairConfig.lua`에 세 기본값과 기본 수리율·최소 복구량을 모았다.

```text
baseAmount = missingCondition * 0.20 / max(previousHaveBeenRepaired, 1)
repairAmount = baseAmount * (1 + effectiveMechanicsLevel * 0.02)
ignoreChance = min(effectiveMechanicsLevel * 0.05, 0.75)
```

수리량은 가장 가까운 정수로 반올림하고 최소 1을 보장하며 최대 condition에서 자른다.
0 condition도 허용하고 완전한 부품은 거부한다. 별도 실패 판정이나 XP 지급은 없다.
이 수리법의 자원·시간·기본 수리율은 초기 밸런스이며 게임 내 조정이 필요하다.
아이템 ID·등급·압력·용량·사용자 이름·modData는 교체하지 않는다.

직접 처리하는 `OnCreate`이므로 바닐라 Fixing 함수를 호출하지 않는다. 기존 횟수를
저장하고 수리 후 무시 확률이 성공하면 그대로 두며, 그렇지 않을 때만 딱 한 번 +1 한다.
기존 횟수를 줄이거나 0으로 초기화하지 않는다. Lv 0/5/10/15의 수리량 배율은
1.00/1.10/1.20/1.30이고 무시 확률은 0/25/50/75%다.

## Beyond Ten 및 멀티플레이

공통 원본 `shared/lua/Auxilia/SkillUtils.lua`의
`AuxiliaSkillUtils.GetSkillLevel(character, perk)`를 사용한다. QoL은
`config/mods.json`의 소비자로 등록되어 `tools/sync-shared.ps1`로 배포본을 복사한다.

매 호출 시 `BeyondTen.GetEffectiveLevel` 함수 유무를 확인하고 `pcall`로 호출한다.
정상적인 0 이상의 유한 숫자는 10으로 자르지 않고 사용한다. API 부재·오류·잘못된
자료형·음수·NaN·무한대는 바닐라 `getPerkLevel`로 폴백한다. nil 캐릭터·perk는 0이다.
`mod.info`의 필수 의존성은 추가하지 않았다. 실제 Beyond Ten 배포본은 시험하지 않았으며,
MP의 초과 레벨 적용에는 그 모드가 서버에서도 같은 API/레벨을 제공해야 한다.
클라이언트에만 API가 있는 경우 서버는 안전하게 바닐라 레벨을 사용한다.

새로운 client command나 전역 timed-action 후크 없이 바닐라 `ISHandcraftAction`의
`OnCreate`를 사용한다. SP는 perform, MP 서버는 complete에서 recipe를 수행한다.
콜백 자체도 클라이언트 실행을 거부한다. 완료 직전 소유자·손상·수리 대상·중복 대상을
재검사하고 상태를 바꾼 다음 `syncItemFields()`를 한 번 호출한다. 재료 소비·작업 중단은
기존 제작 작업이 처리한다. 이 빌드의 동기화 API가 플레이어 소지품에 한정되어
바닥·상자·차량 보관함 부품은 먼저 집어야 한다. 장착 부품은 직접 변경하지 않으며
이후 정상 장착 작업이 condition과 차량 상태를 갱신·전송한다.

## 변경 파일

- 공통 헬퍼 원본: `shared/lua/Auxilia/SkillUtils.lua`, 소비자 매핑: `config/mods.json`
- 배포 Lua: `media/lua/shared/Auxilia/SkillUtils.lua` (생성본),
  `AQoLVehicleRepairConfig.lua`, `AQoLVehicleRepair.lua`
- 제작 수리법: `media/scripts/AQoLVehicleRepairs.txt`
- 한영 UX: `media/lua/shared/Translate/{EN,KO}/{Recipes,Tooltip}.json`
- 검사: `tools/validate.ps1`, `tools/test-vehicle-repairs.ps1`,
  `tools/tests/vehicle-repair-{bootstrap,integration}.lua`, 공용 `RunLua.java`
- 문서: 이 파일, `README.md`, `CHANGELOG.md`, `docs/FEATURES.md`, `docs/SMOKE-TEST.md`,
  `shared/knowledge/BUILD-42-VEHICLE-ITEM-REPAIR.md`

주요 함수: `GetSkillLevel`, `GetMechanicsLevel`, `CalculateRepairAmount`,
`GetIgnoreChance`, `RollIgnoreRepairCount`, `CanRepairItem`, `OnTest`, `OnCreate`.

## 자동 검사와 수동 시험

```powershell
./tools/validate.ps1
./mods/auxilias-qol/tools/test-vehicle-repairs.ps1 -GameDirectory '<게임 설치 경로>'
./mods/auxilias-qol/tools/test-skill-books.ps1 -GameDirectory '<게임 설치 경로>'
```

실제 게임 Kahlua에서 새 Lua의 문법과 실행을 검사한다. 설치된 아이템·차량 템플릿으로
독립적인 33종 oracle을 만들고 제작 입력과 대조한다. 실제 `ISHandcraftAction.lua`를
읽어 SP/서버/클라이언트 경로의 호출 횟수·횟수 증가·동기화·난수 호출을 검사한다.
주변 게임 객체 및 인벤토리/제작 로직은 시험 대역이므로 네트워크·재료 소모의 실기 검증은 아니다.
의도적으로 발생시킨 Beyond Ten 오류 1건은 설치본 Kahlua에서 errorCount를 2 올린다.
테스트 실행기는 그 정확한 증가량만 허용하고 기존 스킬북 검사는 여전히 0건을 요구한다.

수동 시험 체크리스트:

1. EN/KO에서 네 수리법 검색·재료 표시·소지품 및 휴대 가방 입력 선택을 확인한다.
   바닥·상자·장착 상태에서는 거부되고 집으면 가능해야 한다.
2. 네 부품군과 차량 종류 1/2/3에서 상태 0/50/99/100, 기존 횟수 0/1/2/10을 시험한다.
   무시 실패 시 +1, 성공 시 이전 값 유지, 최대 condition 초과 없음과 재료 1회 소비를 기록한다.
3. 작업 취소·이동 중단·재료 부족·대상 이동에서 중복 소비/무료 수리가 없는지 확인한다.
4. Beyond Ten 없이 Lv 0/5/10, 실제 Beyond Ten과 함께 Lv 11~15를 시험한다.
   클라이언트와 서버 양쪽에 활성화한 경우와 서버 API 오류 폴백을 구분한다.
   확률 확인은 충분한 반복 표본의 원시 수치를 기록한다.
5. 두 플레이어의 서버에서 수리·전달·장착·탈거·저장/로드·재접속 후 condition과 횟수,
   타이어 공기압, 실제 제동/서스펜션/소음 성능이 유지되는지 확인한다.
6. 바닐라 무기/차체 수리, 기존 차량 분해 및 스킬북 기능을 회귀 확인한다.

검사 시 설치본은 42.21.0, 중앙 배포 대상은 42.20이었다. 42.20 실기 재검증과
양 버전의 실제 제작 파싱·SP/MP 동작 확인 전에는 릴리스 검증 완료로 간주하지 않는다.
