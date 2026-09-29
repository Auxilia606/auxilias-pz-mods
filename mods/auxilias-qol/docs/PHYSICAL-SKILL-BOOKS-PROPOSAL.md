# 체력·근력 스킬북

상태: 2026-09-27, 0.3.1 구현 완료. 정적 검사 및 바닐라 Lua 통합 검사 통과.
실제 클라이언트 플레이·서버 접속·저장 파일을 이용한 검증은 아직 하지 않았다.
대상 버전은 `config/project-zomboid.json`을 따른다. 조사한 설치 빌드는 42.20.4.
바닐라 전체 목록과 엔진 근거는
[공통 조사](../../../shared/knowledge/BUILD-42-SKILL-BOOKS.md)에 있다.

## 구현 구성

체력(Fitness) 1~5권과 근력(Strength) 1~5권, 총 10개 아이템을 추가한다.
배율은 사용자 결정에 따라 일반 바닐라 기술서와 동일한 3/5/8/12/16으로 확정한다.
페이지 수도 바닐라 규격을 사용한다. 아래 한·영 이름은 사용자 승인 후 그대로 구현했다.

| 권 | 적용 대상 레벨 | 읽는 현재 레벨 | 페이지 | 완독 배율 |
|---|---|---|---|---|
| 1 | 1–2 | 0–1 | 220 | 3배 |
| 2 | 3–4 | 2–3 | 260 | 5배 |
| 3 | 5–6 | 4–5 | 300 | 8배 |
| 4 | 7–8 | 6–7 | 340 | 12배 |
| 5 | 9–10 | 8–9 | 380 | 16배 |

무게 1.0, 권당 두 레벨, 부분 독서·독서 특성·문맹·레벨 조건·진도 저장은 바닐라를
따른다. 현재 체력/근력이 5이면 해당 3권부터 활용한다. 1·2권은 낮은 신체 능력으로
시작한 캐릭터에도 의미가 있으므로 포함한다.

책을 읽고 실제로 활동하면서 성장하는 흐름을 유지한다. 운동뿐 아니라 해당 스킬의
일상 행동 XP에도 적용하며, 운동 규칙·통증·영양·특성 획득 조건을 별도로 바꾸지 않는다.
체력과 근력은 다른 활동으로 오르므로 책은 각각 분리하고, 동일한 바닐라 배율을 사용한다.

일반 기술서와 같은 배율을 권하는 이유는 책의 단계·희귀도·독서 시간을 익숙한 규칙에
맞추면서 매우 큰 후반 필요 XP를 줄일 수 있기 때문이다. 다만 전투와 운반 능력에
직접 영향을 주므로 단순한 표시 편의 기능보다 밸런스 영향이 크다.

## 배율 선택의 영향

아래는 레벨 5의 시작 XP에서 10까지, 매 구간 시작 전 완독, 다른 보정 동일,
경계 초과 XP·독서 시간 제외 조건의 산술 비교이다. 실제 소요 일수 예측은 아니다.

| 방식 | 권별 배율 | 책 적용 전 기준으로 필요한 XP 상당량 |
|---|---|---|
| 책 없음 | 1 / 1 / 1 / 1 / 1 | 450,000 |
| 일반 기술서형 — 채택 | 3 / 5 / 8 / 12 / 16 | 33,125 |
| 전투 기술서형 — 비교용, 미채택 | 1.5 / 2.5 / 4 / 6 / 8 | 66,250 |

일반형 계산: 30,000/8 + (60,000+90,000)/12 + (120,000+150,000)/16.
책을 모두 갖춘 후반 성장에 한정하면 약 13.6배 차이다. 전투형은 비교 자료로만 남긴다.
초기의 보수적/사용자 지정 배율 제안은 채택하지 않는다.

## 바닐라 이름을 기준으로 한 제목

설치된 `media/lua/shared/Translate/KO/ItemName.json` 및 `EN/ItemName.json`의
24개 시리즈, 각 5권을 확인했다. 한국어는 `스킬명 N권: "책 제목"`, 영어는
`Skill RomanNumeral: "Book Title"` 형식이다. 장검 3권처럼 저자명을 넣는 예외도 있다.
스킬명 번역은 `KO/IG_UI.json`에서 Fitness=체력, Strength=근력이다.

바닐라 예시:

- 목공 1권: "못 박기부터 시작하는 만들기" → 5권: "현장 목재 가공과 건축학적 목공"
- 요리 1권: "더 나은 햄버거 조리법" → 4권: "마스터 셰프가 알려주는 주방 기술"
- 장검 1권: "멋있는 검!" → 5권: "중세 장검의 마모분석"
- 물건관리 5권: "도구 사용의 생체역학 이해"

친근한 입문서에서 실용 지침서, 전문가 훈련서, 학술서로 이어지는 경향을 따른다.
처음 제안한 '체력 단련 1권'처럼 권수만 다른 제목 대신 아래 개별 제목을 사용한다.
아래 영문 제목은 바닐라 인용이 아닌 새로 작성한 대응 제목이다.

| 권 | 체력 책의 전체 이름 | 영문 이름 |
|---|---|---|
| 1 | 체력 1권: "소파에서 일어나는 법" | Fitness I: "Getting Off the Couch" |
| 2 | 체력 2권: "하루 30분 유산소 운동" | Fitness II: "Thirty Minutes of Aerobics a Day" |
| 3 | 체력 3권: "러너를 위한 지구력 훈련" | Fitness III: "Endurance Training for Runners" |
| 4 | 체력 4권: "육상 코치의 컨디셔닝 지침서" | Fitness IV: "The Track Coach's Conditioning Manual" |
| 5 | 체력 5권: "심폐지구력과 운동생리학" | Fitness V: "Cardiorespiratory Endurance and Exercise Physiology" |

| 권 | 근력 책의 전체 이름 | 영문 이름 |
|---|---|---|
| 1 | 근력 1권: "처음 드는 아령" | Strength I: "Your First Pair of Dumbbells" |
| 2 | 근력 2권: "맨몸으로 만드는 튼튼한 몸" | Strength II: "Building Strength Without Weights" |
| 3 | 근력 3권: "바벨과 덤벨 훈련 지침서" | Strength III: "The Barbell and Dumbbell Training Manual" |
| 4 | 근력 4권: "역도 챔피언들의 훈련 비법" | Strength IV: "Training Secrets of Weightlifting Champions" |
| 5 | 근력 5권: "근력 발달의 생체역학" | Strength V: "The Biomechanics of Strength Development" |

## 획득 경로

0.3.1은 사용자 요청에 따라 바닐라 기술서의 전리품 경로 전체를 따라간다.
`ProceduralDistributions.list`, `Distributions`/`SuburbsDistributions`, `VehicleDistributions`,
`BagsAndContainers`, `ClutterTables`를 재귀 탐색한다. 해당 목록에 존재하는 바닐라 기술서의
권별 최대 가중치를 체력·근력 책 각각에 적용한다. 여러 스킬의 가중치를 합산하지 않는다.
원래 없는 권은 일반 목록에 억지로 추가하지 않는다. `Base.` 접두사 유무는 모두 지원한다.
예: 일반 서점은 10/8/6/4/2, 도서관은 8/6/4/2/1, 도서 상자·우체국은 6/4/2/1/0.5.

다음 22개 체육·교육 목록은 모든 권에 별도 최소 가중치를 적용한다.
실제 값은 `max(현지 바닐라 값, 우대값, 이미 있는 모드 책 가중치)`다.

| 분배표 | 1~5권 최소 가중치 |
|---|---|
| BookstoreSports | 10 / 8 / 6 / 4 / 2 |
| LibrarySports | 8 / 6 / 4 / 2 / 1 |
| UniversityLibrarySports | 8 / 6 / 6 / 4 / 2 |
| FitnessTrainer, GymWeights, SchoolGymSportsGear | 8 / 6 / 4 / 2 / 1 |
| GymLockers, SportStoreBoxing, SportStorageWeights | 6 / 4 / 3 / 2 / 1 |
| BaseballLockers, GolfLockers, PoolLockers | 4 / 3 / 2 / 1 / 0.5 |
| ClassroomMisc, ClassroomShelves, ClassroomSecondaryMisc, ClassroomSecondaryShelves | 4 / 3 / 2 / 1 / 0.5 |
| ClassroomDesk, ClassroomSecondaryDesk, SchoolLockers, SchoolLockersBad, CrateBooksSchool | 2 / 1.5 / 1 / 0.5 / 0.25 |
| UniversityLibraryBooks | 4 / 3 / 12 / 6 / 3 |

무작위 건물의 `StoryClutter`는 가중치 없는 목록이므로, 바닐라 기술서가 있는 권에 한해
두 시리즈를 각 1개씩 추가한다. 채집은 해당 권의 목공책 정의를 독립 복사해 지형별
가중치·채집 조건을 그대로 따른다. 운동시설에서 채집 확률까지 별도 올리지는 않는다.

42.20.4 데이터 실행 감사에서 기술서가 든 서로 다른 가중치 목록 286개, 무작위 소품
목록 4개를 확인했다. 이는 건물 개수가 아니라 여러 장소가 공유할 수 있는 Lua 목록 수다.
목록 원문은 게임 설치에서 직접 읽으며 기술서 ID 검증 기준도 실제 아이템 정의에서 추출한다.

위 가중치는 생성 확률(%)이 아니다. 추가된 두 시리즈는 다른 아이템과 추첨을 공유한다.
배포 빈도·밸런스는 실기 표본으로 확인해야 하며, 기존에 생성된 보관함을 소급해서 채우지 않는다.

## 구현 방향과 검증

- ID는 `AuxiliasQoL.BookFitness1`~`5`, `AuxiliasQoL.BookStrength1`~`5`.
  기존 공개 ID를 변경하지 않고 새 모드 네임스페이스 안에 둔다.
- `ItemType = base:literature`, `DisplayCategory = SkillBook` 등 현재 바닐라 필드를 사용한다.
- `SkillBook`에 Fitness/Strength 매핑과 배율을 등록하고 `ISReadABook`를 재사용한다.
  별도 XP 보상 이벤트는 중복 배율과 MP 문제를 만들 수 있어 우선 도입하지 않는다.
- 체력은 청록색, 근력은 적갈색의 바닐라 TINT 책 모델과 아이콘을 재사용한다.
- `AQoLPhysicalSkillBooks.lua`는 바닐라 표를 require한 뒤 두 스킬의 perk와
  배율만 등록한다. 배율은 로드 시 `SkillBook.Carpentry`에서 가져온다.
  타 모드가 목공 배율을 먼저 바꾸면 그 값을 따르며, 체력/근력 표를 나중에
  덮어쓰는 모드가 있으면 나중 값이 적용된다. 배율 모드 간 강제 우선순위는 두지 않는다.
- `AQoLPhysicalSkillBooksLoot.lua`는 `OnPreDistributionMerge`에 추가한다.
  공유 목록과 반복 이벤트에도 중복 삽입하지 않는다. 기존 책의 가중치는 내리지 않고
  위 기본값/우대값보다 낮을 때만 높인다. 기존 바닐라 항목 자체는 변경하지 않는다.
- `AQoLPhysicalSkillBooksForaging.lua`는 바닐라 Junk 채집 정의를 require한 후 두 시리즈를 등록한다.
- 먼저 3권 하나로 현재 레벨 5의 부분 독서→완독→운동 XP→6레벨 전환을 확인한다.
  이어 두 시리즈 전체, 자연 활동 XP, 저장/로드, MP, 문맹, 잘못된 권, 샌드박스와의
  중복 적용, 신체 스킬 UI 배율 표시를 검증한다.

정적 검사는 전체 10개 아이템의 ID·레벨·페이지·타입·모델·번역을 확인한다.
`tools/test-skill-books.ps1 -GameDirectory <설치 경로>`는 게임의 Kahlua 실행기에서
실제 바닐라 `SkillBook`, `ProceduralDistributions`, `ISReadABook`와 모드 Lua를 실행한다.
캐릭터·아이템·네트워크 API는 시험용 대역이므로 Java XP 지급이나 실제 저장·MP 동작을
검증한 것으로 간주하지 않는다. 실행에는 `javac`와 게임의 `jre64`가 필요하며 결과물은
모드의 무시되는 `work/skill-book-tests` 폴더에만 둔다.
