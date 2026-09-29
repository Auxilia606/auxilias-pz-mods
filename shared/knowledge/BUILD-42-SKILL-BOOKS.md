# Build 42 스킬북과 경험치 배율

조사일: 2026-09-27. 설치된 42.20.4의 Lua·아이템 스크립트 및 Java 바이트코드를
정적으로 조사했다. 로컬 `Zomboid/console.txt`의 `version=42.20.4`도 확인했다.
신규 모드 아이템의 실제 독서·경험치·멀티플레이 시험 결과는 아니다.

## 근거와 재현

설치 경로: `C:/Program Files (x86)/Steam/steamapps/common/ProjectZomboid`.
아래 경로는 이 설치 경로 기준이다.

- `media/scripts/generated/items/literature.txt`: `SkillTrained`가 있는 아이템 120개.
- `media/lua/server/XpSystem/XPSystem_SkillBook.lua`: 24개 스킬 매핑과 완독 배율.
- `media/lua/shared/TimedActions/ISReadABook.lua`: 독서 조건·페이지·배율 등록·서버 동작.
- `media/lua/server/Items/ProceduralDistributions.lua`: 장소별 배포 가중치.
- `media/lua/server/XpSystem/XpUpdate.lua`: 이동·전투·벌목 XP와 신체 특성 전환.
- `media/lua/shared/Definitions/FitnessExercises.lua`: 운동별 설정.
- `media/lua/shared/Sandbox/Apocalypse.lua`: `MinutesPerPage = 2.0`.
- `projectzomboid.jar`: `javap -p -c`로 아래 클래스를 조사했다.
  `zombie.characters.IsoGameCharacter$XP`, `zombie.characters.skills.PerkFactory`,
  `zombie.characters.BodyDamage.Fitness`.

```powershell
$pz = 'C:/Program Files (x86)/Steam/steamapps/common/ProjectZomboid'
javap -p -c -classpath "$pz/projectzomboid.jar" 'zombie.characters.IsoGameCharacter$XP'
javap -p -c -classpath "$pz/projectzomboid.jar" zombie.characters.skills.PerkFactory
javap -p -c -classpath "$pz/projectzomboid.jar" zombie.characters.BodyDamage.Fitness
```

## 전체 시리즈

각 접두사 뒤에 `1`~`5`를 붙인 `Base` 아이템이 각각 존재한다.
일반 배율은 3/5/8/12/16, 낮은 배율은 1.5/2.5/4/6/8이다.

| SkillTrained | Perks | 아이템 접두사 | 배율군 |
|---|---|---|---|
| Blacksmith | Blacksmith | BookBlacksmith | 일반 |
| Butchering | Butchering | BookButchering | 일반 |
| Carpentry | Woodwork | BookCarpentry | 일반 |
| Carving | Carving | BookCarving | 일반 |
| Cooking | Cooking | BookCooking | 일반 |
| Electricity | Electricity | BookElectrician | 일반 |
| Farming | Farming | BookFarming | 일반 |
| FirstAid | Doctor | BookFirstAid | 일반 |
| Fishing | Fishing | BookFishing | 일반 |
| FlintKnapping | FlintKnapping | BookFlintKnapping | 일반 |
| Foraging | PlantScavenging | BookForaging | 일반 |
| Glassmaking | Glassmaking | BookGlassmaking | 일반 |
| Husbandry | Husbandry | BookHusbandry | 일반 |
| Masonry | Masonry | BookMasonry | 일반 |
| Mechanics | Mechanics | BookMechanic | 일반 |
| MetalWelding | MetalWelding | BookMetalWelding | 일반 |
| Pottery | Pottery | BookPottery | 일반 |
| Tailoring | Tailoring | BookTailoring | 일반 |
| Tracking | Tracking | BookTracking | 일반 |
| Trapping | Trapping | BookTrapping | 일반 |
| Maintenance | Maintenance | BookMaintenance | 일반 |
| Aiming | Aiming | BookAiming | 낮음 |
| Reloading | Reloading | BookReloading | 낮음 |
| LongBlade | LongBlade | BookLongBlade | 낮음 |

Fitness·Strength는 목록에 없다. 달리기·은밀 이동 계열과 도끼 등에도 없는 사례가
있으므로 “체력·근력 외 모든 스킬에 책이 있다”는 설명은 부정확하다.

## 120권의 공통 규격

### 42.21.0 재확인 (2026-09-29)

로컬 게임 로그의 버전은 42.21.0이다. 이 설치본에도 바닐라 기술서 24개 시리즈/120권이 있고,
조준·재장전·장검의 완독 배율은 1.5/2.5/4/6/8이다. 기술서가 없는 실제 스킬은
Fitness, Strength, Sprinting, Lightfoot, Nimble, Sneak, Axe, Blunt, SmallBlunt,
SmallBlade, Spear의 11개다. 내부 Perk ID와 표시 이름이 다를 수 있다
(예: Sprinting의 영어 UI는 Running, Sneak는 Sneaking).

현재 ISReadABook:getDuration은 앉은 자세 보정을 character:isSitting()으로 검사한다.
기존 42.20.4용 시험 대역을 재사용할 때 이 API가 빠지면 독서 생성 시험이 실패한다.
새 빌드 전체의 게임 내 호환성을 확인했다는 의미는 아니며 중앙 대상 버전 변경 근거로 삼지 않는다.

### 규격 표

| 권 | XP가 향하는 레벨 | 읽고 활용할 현재 레벨 | 페이지 | 일반 배율 | 낮은 배율 |
|---|---|---|---|---|---|
| 1 | 1–2 | 0–1 | 220 | 3 | 1.5 |
| 2 | 3–4 | 2–3 | 260 | 5 | 2.5 |
| 3 | 5–6 | 4–5 | 300 | 8 | 4 |
| 4 | 7–8 | 6–7 | 340 | 12 | 6 |
| 5 | 9–10 | 8–9 | 380 | 16 | 8 |

전체 120권의 무게는 1.0, `NumLevelsTrained`는 2이다. 아이콘과 모델은 기존 색상별
책 또는 `Book_Generic`/`Book_Generic_Mask`와 TINT 모델을 사용한다.

- 책은 XP나 레벨을 직접 주지 않는다. 대상 스킬의 이후 XP에 배율을 등록한다.
- `LvlSkillTrained`는 현재 레벨이 아닌, 도달할 첫 레벨이다. 현재 레벨 5는 3권,
  현재 레벨 6은 4권이다. 이전 권을 완독했는지를 요구하는 연속 독서 조건은 없다.
- `checkMultiplier`는 10% 독서 단위로 `floor(읽은 비율 / 10) × 최대 배율 / 10`을
  등록한다. 엔진은 등록값이 1을 초과할 때만 실제 XP에 곱한다. 따라서 3배 책의
  50% 독서는 1.5배이며, 1.5배 책은 70%에서 처음 1배를 넘는다.
- 레벨이 너무 낮거나 이미 해당 범위를 넘었거나 문맹이면 정상적인 학습 대상이 아니다.
- 독서 진도는 캐릭터의 아이템 full type별로 보존된다. 책을 소비하는 코드는 없다.
- 배율은 스킬별 하나의 항목이며 권별 배율을 누적 곱하지 않는다. 해당 상한 XP를
  통과하면 엔진이 항목을 제거한다. 실시간 만료 타이머를 사용하는 방식이 아니다.
- 독서 시간은 `MinutesPerPage`와 하루 길이·빠른/느린 독서·독서 안경·앉은 자세의
  영향을 받는다. 2분/페이지 기준 명목 게임 시간은 440/520/600/680/760분이다.
- 빠른 독서는 시간 ×0.7, 느린 독서는 ×1.3, 독서 안경과 앉은 자세는 각각 ×0.9.
- 서버 독서는 `animEvent` 및 `complete`에서 처리하며 `addXpMultiplier`를 사용한다.
  독자적인 클라이언트 전용 XP 지급으로 대체할 필요가 있는지는 먼저 실제 시험해야 한다.

## 배포 예시

아래는 목공 1~5권의 가중치이며 백분율이 아니다. rolls, 다른 항목, 전리품 설정에
따라 실제 생성 빈도가 달라진다.

| 분배표 | 1~5권 가중치 |
|---|---|
| BookstoreBooks / BookstoreBlueCollar | 10 / 8 / 6 / 4 / 2 |
| LibraryBooks | 8 / 6 / 4 / 2 / 1 |
| CrateBooks / PostOfficeBooks | 6 / 4 / 2 / 1 / 0.5 |
| ClassroomShelves | 2 / 1 / 0.5 / 없음 / 없음 |
| UniversityLibraryBooks | 없음 / 없음 / 8 / 4 / 2 |

전투 책은 일부 공통 분배표에서도 더 희귀하다. 예를 들어 `CrateBooks`의 조준·장검은
0.6/0.4/0.2/0.1/0.05이다. `BookstoreSports`, `LibrarySports`, `FitnessTrainer`,
`GymLockers`도 실제로 존재하지만, 이름만으로 스킬북이 든다고 판단하면 안 된다.
스포츠 서가에는 일반 스포츠 도서가 있으며 그것은 스킬 XP 배율 책과 다르다.

## 전리품 경로 확장 조사 (2026-09-27)

42.20.4의 기술서 출처는 `ProceduralDistributions`만으로 완전히 열거되지 않는다.
`Items/Distributions.lua`의 직접 배포표, `Distribution_BagsAndContainers.lua`,
`Distribution_BinJunk.lua`, `Distribution_ClosetJunk.lua`,
`Vehicles/VehicleDistributions.lua`에도 기술서가 있다. 가중치 배열은 주 목록뿐 아니라
`junk.items` 등에 중첩되고 `ClutterTables` 및 차량/방 배포표 사이에서 공유된다.
`Distributions.lua`는 방 배포표를 `Distributions` 배열에 추가하고 동일 객체를
`SuburbsDistributions`에도 할당하므로 객체별 방문 추적이 필요하다.

`RandomizedWorldContent/StoryClutter/StoryClutter_Definitions.lua`에는 기술서 full type을
포함하는 가중치 없는 배열도 있다. 이를 item/weight 쌍으로 해석하면 안 된다.
`Foraging/Categories/Junk.lua`는 `forageSystem.addForageDef`로 기술서 채집 정의를 등록한다.
`forageSystem.forageDefinitions`에 등록한 정의는 이후 `forageSystem.init`에서
`populateItemDefs`를 거쳐 지형별 전리품에 반영된다. 배열·정의를 변경할 때에는 기존 항목과
중첩 테이블을 공유해서 원본까지 바꾸지 않도록 주의한다.

## 42.21.0 장검 기술서 출처 (2026-09-29)

BookLongBlade1~5는 일반 기술서 전체 경로와 일치하지 않는다. 전체 Lua 검색 및 실제 전리품
테이블 실행 결과, 장검을 가진 서로 다른 가중치 배열은 14개다. ProceduralDistributions의
BookstoreBooks, CrateBooks, LivingRoomShelf, LivingRoomShelfClassy, LivingRoomShelfRedneck,
LivingRoomWardrobe, MedievalBooks, PostOfficeBooks, RecRoomShelf, SafehouseBookShelf,
ShelfGeneric, SurvivalGear와 BagsAndContainers.SurvivorItems,
VehicleDistributions.MobileLibraryTruckBed이다.

MedievalBooks는 Items/Distributions.lua의 classroom_medieval.shelves에서 참조한다.
일반 학교 서가가 아닌 중세학 교실의 전문 서가이며, 1~5권 가중치는 10/8/6/4/2다.
일반 Classroom/School 및 Gym의 전용 목록에는 장검 기술서가 없다.
현재 Foraging/Categories/Junk와 StoryClutter에도 장검 기술서가 없다.
일반 기술서 출처를 모두 복제하면 장검보다 장소가 넓어지고, 일반 기술서의 가중치를 복제하면
서점 등 공통 출처에서도 전투 기술서의 희귀도가 달라진다.

## Fitness / Strength의 엔진 처리

`IsoGameCharacter$XP.AddXP`는 신체 스킬을 출신 스킬 보너스 및 Fast/Slow Learner
등 일부 보정에서 제외하지만, 책의 `getMultiplier(perk)`를 곱하는 부분에는
Fitness/Strength 제외 분기가 없다. 따라서 해당 스킬에 배율을 등록하는 설계는
정적 근거가 있다. 실제 신규 책으로 성공했다고 주장할 단계는 아니다.

운동의 `Fitness.incStats`는 싱글플레이에서 `XP.AddXP`, 서버에서 `GameServer.addXp`를
사용한다. `XpUpdate.lua`의 달리기·짐 운반·근접전·벌목도 해당 신체 XP를 지급한다.
기존 스킬북 경로를 쓰면 효과는 운동 UI에만 한정되지 않는다.

영양 상태에 따른 Fitness XP 허용 여부, Strength의 단백질 보정은 책 배율보다 앞에서
처리된다. 배율 책 자체로 그 제한을 해제하지 않는다. 샌드박스 XP 배율도 별도로
적용되므로 모드가 다시 곱하면 안 된다.

두 스킬의 레벨별 추가 필요 XP는 동일하다. `PerkFactory` 정의값에 내부 ×1.5가
적용되어 1,500 / 3,000 / 6,000 / 9,000 / 18,000 / 30,000 / 60,000 /
90,000 / 120,000 / 150,000이 된다. 레벨 5 시작부터 10까지는 450,000 XP이다.

남은 실기 검증: 부분 독서·완독, 5→6 및 7→8 경계, 저장/로드, 다른 사람이 읽은 책,
운동·이동·전투의 XP 비율, 샌드박스 배율 조합, MP 서버/클라이언트 동기화,
신체 스킬 UI의 배율 표시 및 음수 XP 경로의 부작용.
