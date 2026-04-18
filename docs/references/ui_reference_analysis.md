# UI 레퍼런스 심층 분석 — "시간이 멈춘 숲"

> 대상: 2D 픽셀아트 메트로배니아 + 시간 조작 + 숲/그림자 공포 분위기 (Godot 4.x, 1인 개발)
> 목적: 레퍼런스 12개 게임의 UI/HUD/메뉴/트랜지션을 카테고리별로 분해하고, 1인 픽셀아트 개발자가 실제 구현 가능한 범위로 "시간이 멈춘 숲"의 UI 방향성을 제시한다.
> 작성일: 2026-04-18
> 출처: 각 섹션 말미 링크. 화면 레이아웃은 공개 리뷰/UI 데이터베이스/개발자 인터뷰 기반이며 일부는 "추정" 표기.

---

## 0. 이 문서의 구성

1. 게임별 카드 (12개)
2. 카테고리 매트릭스 (A~I × 12게임)
3. "시간이 멈춘 숲" 추천 종합
4. 1인 픽셀아트 개발자용 현실성 필터
5. 분석의 한계 및 사용자 결정 필요 사항
6. 출처

### 분석 카테고리 약어
- **A**: 인게임 HUD (체력/스킬 슬롯/자원/콤보/상태이상)
- **B**: 시간 시스템 UI (시계 표시, 정지 중 화면 연출)
- **C**: 공포/경고 UI (비네트, 적 접근 경고, 경계 표시)
- **D**: 월드 인터랙션 (환경 하이라이트, 상호작용 프롬프트, NPC 대화)
- **E**: 인벤토리/장비/스킬 (슬롯, 툴팁, 등급, 장비 실루엣)
- **F**: 월드맵 (노드, 연결선, 현재 위치, 잠금/해금)
- **G**: 메타 UI (타이틀, 메뉴, 세이브, 설정, 로딩)
- **H**: 피드백/트랜지션 (데미지 넘버, 힛 피드백, 페이드, 디졸브)
- **I**: 버튼 프롬프트/커서

### 적용 가능성 등급
- **Strong**: 직접 참고, 컨셉 차용 우선
- **Medium**: 부분 참고, 요소만 발췌
- **Skip**: 스타일/규모가 맞지 않거나 1인 개발 비현실적

---

# 1. 게임별 카드

## 1-1. Hollow Knight (2017, Team Cherry)

- **개요**: 고딕 벌레 세계의 다크 판타지 메트로배니아. 핸드드로잉 2D.
- **잘한 카테고리**: A, D, F, G, H
- **구체적 시각 디테일**:
  - 좌상단 체력 = "Mask"(해골/가면) 아이콘 가로 배치. 각 마스크는 하얀색 실루엣에 파란 이너 글로우. 피격 시 빠르게 페이드 아웃.
  - Soul 게이지 = 원형 용기(vessel)에 흰 액체가 차오름, 차면 두 개의 눈구멍이 드러나 "가면 얼굴"처럼 보임. 충전 시 액체 표면이 일렁이고 주변으로 파티클이 원형으로 튐.
  - 하단 Geo(화폐) = 작은 단색 숫자 표기, 불필요한 장식 없음.
  - 메뉴: 흑백 고딕 로고 + 얇은 세리프 폰트 + 잉크 번짐 배경. "Hornet" 스타일의 실루엣 일러스트가 타이틀에 등장.
  - 맵: Cornifer에게 미완성 양피지 맵을 구매 → 벤치에 앉아야 업데이트. 맵 아이콘(마커)을 수동으로 구매/배치 가능. 양피지 질감 + 잉크 선.
  - 트랜지션: 지역 이동 시 화면 구석에서 검은 잉크가 번지며 페이드. 지역명이 세리프 타이포로 하단에 크게 나타남.
- **적용 가능성**: **Strong** — 특히 지역명 타이포 연출, 양피지 맵 컨셉, 미니멀 체력 표기.
- **픽셀아트 솔로 현실성**: HUD/메뉴 구조는 실현 가능. 단, Hollow Knight의 고해상도 수채 배경 + 핸드드로잉 프레임은 모방 금지(팀 3인이 수년 투자). 양피지 맵 질감 정도는 솔로도 가능.
- **참고**: Game UI Database 페이지, Interface In Game, Champicky의 분석 글 (출처 6장).

---

## 1-2. Blasphemous (2019, The Game Kitchen)

- **개요**: 스페인 종교회화 모티브 다크 메트로배니아. 16비트 픽셀아트.
- **잘한 카테고리**: A, E, G, H
- **구체적 시각 디테일**:
  - 체력 = 좌상단 하트형 아이콘 + 빨간 오르브 형태의 단수 게이지. 피격 시 유리 깨지는 질감 크랙.
  - Fervor 게이지(마나) = 체력 아래 보라색 수직 게이지. 공격 적중 시 차오름.
  - 아이콘: 모든 아이템 아이콘이 중세 종교화 스타일의 유화 느낌 픽셀아트. 금색 베이스에 어두운 음영.
  - 메뉴 프레임: 양피지+금테두리, 장식 문양(마름모/십자가/가시관) 반복.
  - 데미지 피드백: 플레이어 피격 시 화면 전체 잠깐 빨간 비네트 + 살짝 줌 인.
  - 로딩/기도 화면: 긴 라틴어풍 명문이 중앙에 나타나는 명상적 로딩.
- **적용 가능성**: **Strong** — 다크 톤 + 종교/신화적 장식은 "시간이 멈춘 숲"의 고요한 공포 톤과 어울림. 단, 종교 상징은 피하고 "숲/시간/그림자" 모티브로 치환 필요.
- **픽셀아트 솔로 현실성**: 아이콘의 정교함은 솔로가 시간 투자 시 가능. 장식 프레임은 tileable 패턴으로 절감 가능.
- **참고**: Game UI Database, Wikipedia, Interface In Game.

---

## 1-3. Ender Lilies: Quietus of the Knights (2021, Live Wire/Adglobe)

- **개요**: 폐허 왕국을 탐험하는 멜랑콜리 다크 메트로배니아. "시간이 멈춘 숲"과 분위기가 가장 유사.
- **잘한 카테고리**: A, C, D, G, H — **가장 직접적인 레퍼런스**
- **구체적 시각 디테일**:
  - HUD 극도로 미니멀: 좌상단 체력 바(얇은 수평, 흰색/하늘색) + 우상단 스킬 아이콘 4개(원형 실루엣).
  - 체력 바 피격 시 흰색 플래시 → 실제 감소까지 약 0.3초 지연(가독성).
  - 아이콘: 흑백 실루엣 + 은은한 청백색 이너 글로우. 마우스 호버/선택 시 아이콘이 부드럽게 하이라이트.
  - 스킬 슬롯: 사이드뷰 "동료 영혼"이 플레이어 주변에 뜨고 공격 시 각 영혼이 각자 애니메이션으로 공격하는 연출. 이 연출이 HUD와 결합되어 "스킬 슬롯 = 영혼 실루엣"으로 통일.
  - 분위기: 화면 가장자리 은은한 비네트 상시 유지. 스테인드글라스 빛줄기, 먼지 파티클.
  - 메뉴: 하얀색 얇은 세리프/고딕 폰트 + 검은 배경 + 미세한 잎/넝쿨 장식.
  - 맵: 육각형/직사각 방 블록 연결형, 현재 방은 흰색 펄스. 미탐험은 어둠.
- **적용 가능성**: **Strong (최우선)** — 어두운 숲 + 정적인 공포 + 미니멀 HUD라는 삼위일체가 프로젝트 톤과 정확히 일치.
- **픽셀아트 솔로 현실성**: HUD 미니멀 전략은 솔로 최적. 실루엣+단색 글로우 아이콘은 32x32 픽셀 안에서도 완성 가능.
- **참고**: Game UI Database 1193번, Rely on Horror 리뷰, TechRaptor 프리뷰, Cogconnected 리뷰.

---

## 1-4. Katana Zero (2019, Askiisoft)

- **개요**: 시간 조작 + 네온 느와르 1히트 킬 액션. 시간 메카닉 UI에서 가장 중요한 레퍼런스.
- **잘한 카테고리**: B, G, H, I
- **구체적 시각 디테일**:
  - **시간 슬로우 UI**: 화면 전체가 채도 감소 + 약간의 블러 + 청록/자홍 글로우 프레임, 하단에 수평 게이지가 줄어듦. 게이지가 다 떨어지면 고정된 프레임의 스캔라인이 잠깐 깜빡이며 복귀.
  - **VHS 테이프 메타포**: 죽으면 "되감기(rewind)" 연출, 화면이 실제 VHS처럼 지직거리며 되감김. 메뉴/타이틀도 VHS 재생 UI(PLAY/REWIND/STOP 아이콘)로 치환.
  - **채도/색상**: 보라/핑크/전기청색 네온. 대화창은 적-녹 크로매틱 어베레이션(RGB 어긋남).
  - **대화 UI**: 대화 중 선택지 시간 제한 게이지가 상단에 나타나고, 타임아웃 시 자동 선택.
  - **메뉴 전환**: 모든 전환이 CRT 스캔라인 + 글리치 + 색수차. 로딩 화면도 VHS 트래킹 바.
- **적용 가능성**: **Medium** — VHS 메타포는 "시간이 멈춘 숲"의 숲/자연 톤과 어울리지 않음. 다만 **"시간 흐름이 바뀔 때 화면 전체에 색/질감 필터가 변한다"는 원리는 Strong**. 채도↓ + 청록 글로우 + 게이지는 그대로 차용 가능.
- **픽셀아트 솔로 현실성**: 시간 정지 중 필터 효과는 Godot의 CanvasModulate + 셰이더로 간단 구현. 네온 색상 팔레트는 다크 숲과 상충하므로 청백색으로 치환 권장.
- **참고**: Kelleher Bros 리뷰, Eoin Deroe 분석, Wikipedia.

---

## 1-5. Superhot (2016, SUPERHOT Team)

- **개요**: "움직이면 시간이 흐른다"는 극도의 미니멀 FPS. 우리 프로젝트는 2D지만 시간 정지 메카닉 UI 철학이 핵심 참고.
- **잘한 카테고리**: B, H
- **구체적 시각 디테일**:
  - **제로 HUD**: 전통 HUD 없음. 모든 정보가 세계 안에 있음(diegetic).
  - **색 코딩**: 적=빨강, 무기=검정, 배경=백/회색. 색 3개로 모든 의미 전달.
  - **시간 상태 표시**: 느림 = 세계가 그냥 멈춘 것처럼 보이고 사운드가 저음 유지. 빠름 = 사운드가 정상 속도. UI가 아니라 **오디오+움직임**으로 시간 상태를 전달.
  - **킬 시 유리 파편**: 적이 빨간 유리 조각처럼 산산조각. 데미지 넘버 없음.
  - 메뉴: 도스 터미널 스타일 텍스트, "SUPERHOT SUPERHOT SUPERHOT" 반복 크레딧.
- **적용 가능성**: **Medium** — 제로 HUD는 메트로배니아와 맞지 않음. 그러나 **"시간 상태는 화면 필터+오디오로 전달, UI는 최소화"는 Strong 원칙**. 채도/속도감으로 시간을 알리는 철학 차용.
- **픽셀아트 솔로 현실성**: 3색 팔레트로 정보 전달은 솔로 친화적. 다만 완전 미니멀은 메트로배니아에서 정보 과부족.
- **참고**: Robin Koman UI 리뷰, Washburn Review, Wikipedia.

---

## 1-6. Dead Cells (2018, Motion Twin)

- **개요**: 로그라이트 메트로배니아 + 정교한 픽셀아트. 인벤토리/장비 UI의 정석.
- **잘한 카테고리**: A, E, H, I
- **구체적 시각 디테일**:
  - **체력 바**: 상단 긴 수평 막대, 내부에 ☠ 아이콘. 피격 시 흰 플래시 → 감소까지 지연(가독성 패턴).
  - **스킬 슬롯**: 하단 중앙 4슬롯(무기1/무기2/스킬1/스킬2), 각 슬롯에 쿨다운 원형 마스크.
  - **아이템 등급 색상 (5단계)** (추정):
    - 흰색(Common) → 초록(Uncommon) → 파랑(Rare) → 노랑(Legendary) → 무지개/유색(S-tier)
  - **툴팁**: 아이템 호버 시 대형 툴팁 창 — 데미지 범위/DPS/어픽스 뱃지/플레이버 텍스트. 어픽스마다 작은 컬러 아이콘(독=초록 물방울, 불=주황 불꽃).
  - **데미지 넘버**: 타격 시 플레이어 방향으로 팝업, 크리티컬은 노란색 + 큰 폰트 + 약간의 흔들림.
  - **씬 전환**: 방 이동은 빠른 수평 슬라이드. 메타 전환은 검은 세로줄 와이프.
- **적용 가능성**: **Strong** — 5등급 색 코딩, 쿨다운 원형 마스크, 툴팁 구조는 우리 InventorySystem에 그대로 이식 가능.
- **픽셀아트 솔로 현실성**: 아이콘 개수가 많음(수백 개). 솔로는 총 50~80개로 제한하면 현실적. 등급 색상 테두리로 단일 실루엣을 5단계로 재활용 전략 권장.
- **참고**: Game UI Database 1780, Dead Cells Wiki, community discussions.

---

## 1-7. Moonlighter (2018, Digital Sun)

- **개요**: 상점 운영 + 던전 탐험 픽셀아트 RPG. **상점/가격책정 UI의 표준 레퍼런스**.
- **잘한 카테고리**: D, E, G
- **구체적 시각 디테일**:
  - **상점 진열 UI**: 플레이어가 선반에 직접 아이템을 배치 → 가격 태그(종이 쪽지 아이콘)를 놓음. 손님 반응(😊😐😠 상단 말풍선)으로 가격 적정성 표시.
  - **인벤토리 그리드**: 픽셀 그리드 기반 6x4 슬롯. 아이템은 다양한 크기(1x1, 2x2, 2x1) — 테트리스형.
  - **메뉴 프레임**: 나무+놋쇠 장식, 양피지 배경. 옆에 상인 상반신 도트 일러스트.
  - **대화**: 말풍선에 캐릭터 초상화(감정에 따라 표정 변화 3~5종).
  - **가격 변동 피드백**: 판매 시 숫자 카운트업 애니메이션 + 금화 아이콘 튀어오름.
- **적용 가능성**: **Strong (상점/인벤토리)** — 우리 프로젝트에도 상점(ITEMS.md 참고)이 있으므로 가격 태그/손님 반응 메커니즘은 유용. 양피지 프레임도 숲 톤과 호환.
- **픽셀아트 솔로 현실성**: 상인 초상화는 부담. 초상화 없이 말풍선 + 단색 실루엣만으로 대체 권장.
- **참고**: Game UI Database 205, 80lv 인터뷰, Interface In Game.

---

## 1-8. Death's Door (2021, Acid Nerve)

- **개요**: 아이소메트릭 액션 어드벤처. "까마귀 사신"의 소울스라이크 감성.
- **잘한 카테고리**: A, E, G, I
- **구체적 시각 디테일**:
  - **극미니멀 HUD**: 체력 = 작은 점들(pip), 마력 = 작은 점들, 화면 좌상단 구석에 소형 배치. 전투 중 시야 방해 최소화.
  - **아이콘**: Jenny Brewer 디자인 — 2톤 실루엣(주황/흰색 또는 청/흰색), 굵은 아웃라인. 매우 단순하지만 즉시 인식 가능.
  - **메뉴**: 거의 종이 질감 배경 + 검은 세리프 폰트. "책을 펼친 느낌"의 페이지 전환.
  - **장비 UI**: 무기 4종 아이콘 + 각 무기 업그레이드 트리(작은 가지 모양). 현재 선택 무기만 하이라이트.
  - **대화 UI**: 컷씬처럼 캐릭터 중앙 배치 + 하단 대화 바. 대화 타이핑 사운드가 캐릭터별로 다름.
- **적용 가능성**: **Strong (아이콘 스타일)** — 우리가 아이콘 80개를 2톤 실루엣으로 통일하면 솔로 제작이 현실적.
- **픽셀아트 솔로 현실성**: 2톤 실루엣 아이콘 전략은 솔로 최적. 1개당 15~30분이면 가능.
- **참고**: Jenny Brewer 포트폴리오, Frits Olsen ArtStation, Game UI Database 1085/1353.

---

## 1-9. Hyper Light Drifter (2016, Heart Machine)

- **개요**: 픽셀아트 감성의 정점. 네온 판타지 하이브리드.
- **잘한 카테고리**: A, D, G, H — **색상/아이콘 스타일의 교과서**
- **구체적 시각 디테일**:
  - **체력 표시**: 우하단 5개의 결정형 다이아몬드(health pips). 각 pip은 청록 + 흰 글로우. 하나 잃을 때마다 깨짐 애니메이션.
  - **에너지/대시 차지**: 체력 아래 작은 원형 오르브(dash charge). 시간에 따라 차오름.
  - **색 팔레트**: 핑크+청록+다크블루 스플릿 컴플리먼터리. 광원은 거의 백색.
  - **대사 UI**: 대사 **없음**. NPC는 픽토그램/아이콘으로만 의사소통. 말풍선 안에 작은 그림 애니메이션.
  - **메뉴**: 검은 배경 + 흰/시안 얇은 선. 미니멀 벡터 느낌.
  - **맵**: 4x4 구역으로 구성된 상위 월드맵 + 각 구역 내부 맵. 잠금 구역은 어둡게, 해금 시 서서히 밝아짐.
- **적용 가능성**: **Strong** — 특히 픽셀 다이아몬드 pip 체력 표시, 픽토그램 NPC 대화는 **번역 작업을 줄이는 1인 개발 친화적 선택**. 단, 우리 프로젝트는 한국어 대사가 필요하므로 픽토그램은 보완용.
- **픽셀아트 솔로 현실성**: HLD 수준 감성은 높은 기준이지만 "큰 면 단색 + 얇은 아웃라인" 접근은 솔로에게 효율적. 복잡한 프레임 장식보다 색면 중심 권장.
- **참고**: Medium UI Breakdown (SYH), I Draw Wearing Hats 분석, COLOURlovers 팔레트.

---

## 1-10. Eastward (2021, Pixpil)

- **개요**: 포스트아포칼립스 픽셀아트 액션 어드벤처. 따뜻한 조명이 특징.
- **잘한 카테고리**: D, G, I
- **구체적 시각 디테일**:
  - **대화 UI**: 하단 대화창 — 나무 틀 + 초상화 아이콘 + 타이핑 텍스트. 여러 캐릭터 동시 대화 시 현재 화자만 밝게, 나머지 어둡게.
  - **대화창 구조**: 좌측 초상화 + 중앙 이름 라벨 + 우측 텍스트. 선택지는 말풍선 스타일.
  - **픽셀 + 라이팅**: 2D 스프라이트에 3D 기반 라이팅 적용(Aseprite → 3D 공간에서 범프맵 적용). 우리 솔로 제작에는 과함.
  - **메뉴**: 나무+황동 장식. 아이템 아이콘은 "정물화" 느낌(그림자 진한 픽셀).
  - **미니맵**: 우상단 심플한 격자 맵.
- **적용 가능성**: **Medium** — 대화창 구조(초상화+이름+텍스트)는 표준이므로 차용. 복잡한 라이팅은 Skip.
- **픽셀아트 솔로 현실성**: 초상화는 감정별 3종×주요 NPC 10명만 제작해도 상당 비용. 필요 NPC만 골라서 진행 권장.
- **참고**: Game UI Database 2131, Game Developer 인터뷰, 80lv 기사.

---

## 1-11. Celeste (2018, Maddy Makes Games)

- **개요**: 픽셀아트 플랫포머. UI/Map/게임 3개 월드로 스타일 분리.
- **잘한 카테고리**: G, H — **트랜지션/메뉴 감성의 정석**
- **구체적 시각 디테일**:
  - **해상도 철학**: 게임=320x180, UI=높은 해상도, 맵=3D. "스타일이 영역 넘어 새어나가지 않도록" 설계 (참고: saint11 consistency 글).
  - **메뉴**: 중앙 정렬 심플한 세리프/산세리프 혼용. 배경은 픽셀 산 일러스트 + 파스텔 하늘.
  - **챕터 선택**: 각 챕터를 카드처럼 순차적으로 넘기는 갤러리. 카드에 챕터별 대표 색.
  - **트랜지션**: 방 이동 시 카메라 슬라이딩(물리 기반). 데스 시 화면이 잠깐 픽셀 단위로 분해되었다가 재구성.
  - **로딩**: 없음 — 모든 전환이 즉각적.
  - **대화**: 카메라 살짝 줌 인 + 캐릭터 옆 말풍선. 픽셀 캐릭터 초상화 + 감정 반응.
- **적용 가능성**: **Strong (트랜지션)** — 카메라 슬라이딩 전환은 "시간이 멈춘 숲"의 스테이지 이동에 적합. 데스 시 픽셀 분해 연출도 차용 고려.
- **픽셀아트 솔로 현실성**: Celeste 레벨의 폴리싱은 솔로 어려움. 다만 **"해상도 일관성"** 원칙은 반드시 채택. UI는 고해상도(베이스×2 또는 ×3), 게임은 640x360.
- **참고**: saint11 blog, Aran P. Ink tilesets, Game UI Database 53.

---

## 1-12. Tunic (2022, Isometricorp)

- **개요**: 아이소메트릭 젤다풍 액션. **게임 내 "발견형 매뉴얼"이라는 혁신적 UI 컨셉**.
- **잘한 카테고리**: D, E, G — **메타 UI 혁신의 최고봉**
- **구체적 시각 디테일**:
  - **인게임 매뉴얼**: NES 시대 인쇄 매뉴얼을 픽 완벽 재현. 종이 얼룩, 스테이플 흔적, 찢김, 낙서. 필드에서 "매뉴얼 페이지"를 발견하면 1장씩 채워짐.
  - **언어**: 가상 문자로 작성 → 플레이어가 해독 불필요(분위기 전달). 중요 정보는 그림으로 전달.
  - **메뉴 연결성**: 매뉴얼/스탯/맵/인벤토리가 같은 "책" 안에서 페이지 넘김으로 전환. UI 요소가 다른 요소로 이동 시 애니메이션으로 연결 표시.
  - **아이콘**: 굵은 아웃라인 + 수채화 질감 + 손글씨 라벨.
  - **맵**: 매뉴얼 안의 손그림 지도. 현재 위치는 깜빡이는 점. 일부 영역은 찢어져 있음.
- **적용 가능성**: **Medium to Strong (아이디어)** — 완전한 매뉴얼 재현은 솔로 과부담. 그러나 **"메뉴를 책 형식으로 통합(인벤토리/맵/스킬트리가 모두 페이지)"** 컨셉은 숲 세계관의 "고대 기록" 설정과 어울릴 수 있음.
- **픽셀아트 솔로 현실성**: 완전 Tunic 스타일은 Skip. 단, "책 UI + 페이지 넘김 전환"은 프레임 하나 + 종이 질감 2장으로도 구현 가능.
- **참고**: Raja Kabierski 블로그, 80lv 인터뷰, Game Developer IGF 기사, Game UI Database 1385.

---

# 2. 카테고리 매트릭스

| 카테고리 | 최우선 | 보조 참고 | 스킵/부적합 |
|---|---|---|---|
| **A. 인게임 HUD** | Ender Lilies (미니멀), Death's Door (극미니멀) | Hollow Knight (마스크), Hyper Light Drifter (pip), Dead Cells (슬롯/쿨다운), Blasphemous (게이지) | Superhot (제로 HUD) |
| **B. 시간 시스템 UI** | Katana Zero (채도↓+게이지), Superhot (철학) | — | — |
| **C. 공포/경고 UI** | Ender Lilies (상시 비네트), Blasphemous (빨간 비네트) | Hollow Knight (간접) | Hyper Light Drifter (밝음) |
| **D. 월드 인터랙션** | Ender Lilies (서브틀한 하이라이트), Moonlighter (NPC), Eastward (대화창) | Hollow Knight (벤치), Death's Door | Tunic (대사 없음) |
| **E. 인벤토리/장비/스킬** | Dead Cells (등급+툴팁), Moonlighter (그리드) | Death's Door (아이콘), Blasphemous (장식), Tunic (책) | Hollow Knight (간단) |
| **F. 월드맵** | Hollow Knight (양피지+마커), Ender Lilies (블록 연결) | Hyper Light Drifter (구역) | Celeste (3D 맵) |
| **G. 메타 UI (타이틀/메뉴)** | Ender Lilies (어두운 미니멀), Hollow Knight (고딕 잉크), Celeste (카드), Tunic (책) | Blasphemous (장식), Death's Door (페이지) | Katana Zero (VHS) |
| **H. 피드백/트랜지션** | Celeste (카메라 슬라이딩), Dead Cells (데미지 넘버), Hollow Knight (잉크 페이드) | Hyper Light Drifter (깨짐), Katana Zero (글리치) | — |
| **I. 버튼 프롬프트/커서** | Death's Door (2톤 심플), Hyper Light Drifter (미니멀) | Dead Cells (표준) | — |

---

# 3. "시간이 멈춘 숲" 추천 종합

## 3-1. 인게임 HUD — 3가지 방향안

### 방향안 A. 미니멀 영혼형 (Ender Lilies 직계) ★ 솔로 추천
- **레이아웃**: 좌상단 얇은 가로 체력바(최대 3단 분할 가능), 우상단 스킬 슬롯 4개(원형 실루엣 아이콘).
- **색감**: 흰색/창백한 청백색 단색 + 다크 배경 대비. 피격 시 흰 플래시.
- **장식**: 거의 없음. 잎사귀 1~2개가 바 모서리에 살짝 삐져나옴.
- **특징**: 1인 픽셀아트에 최적, 정보 가독성 최상.
- **제작 난이도**: **쉬움** / **예상 소요**: 2~3일

### 방향안 B. 고대 기록형 (Tunic × Blasphemous 하이브리드)
- **레이아웃**: 체력/마나/스킬이 모두 "책갈피"처럼 화면 모서리에 꽂혀 있음. 양피지 프레임.
- **색감**: 베이지/세피아 + 녹녹한 청색 악센트.
- **장식**: 테두리에 잎, 덩굴, 고대 문자(가상).
- **특징**: 분위기 몰입 최고, 다만 가독성이 덜하고 공간 차지.
- **제작 난이도**: **어려움** / **예상 소요**: 1~2주

### 방향안 C. 하이브리드 실루엣형 (Death's Door × Hyper Light Drifter)
- **레이아웃**: 체력 = 5~7개 다이아몬드/잎사귀 pip, 우측 하단. 스킬 = 좌측 하단 2톤 실루엣 아이콘 4개.
- **색감**: 백색+청록 글로우. 어두운 숲 배경에 대비.
- **장식**: 거의 없음, 아이콘 자체가 장식.
- **특징**: 인식성 높고 심미성 중간. B안보다 가볍고 A안보다 "게임스러움".
- **제작 난이도**: **보통** / **예상 소요**: 4~6일

**권장**: A안 기반 + C안의 pip 아이디어 차용 (체력이 심각할 때만 pip이 "꺼지는 잎사귀"로 변환하는 하이브리드). 난이도 쉬움, 고유성 확보.

---

## 3-2. 메타 UI (타이틀/메뉴) — 3가지 방향안

### 방향안 α. 양피지 / 고대 기록 (Hollow Knight × Blasphemous)
- 양피지 배경 + 잉크 세리프 폰트 + 말라버린 잎사귀/뿌리 장식. 타이틀 로고는 검은 잉크.
- **분위기**: "잊혀진 숲의 기록을 펼치는" 느낌.
- **제작 난이도**: **보통** / **소요**: 3~5일
- **한글 폰트**: 본명조/나눔명조 계열의 세리프 추천.

### 방향안 β. 다크 미니멀 (Ender Lilies × Celeste) ★ 솔로 추천
- 검은 배경 + 중앙 정렬 흰 텍스트 + 은은한 배경 일러스트(멀리 숲 실루엣, 달, 빛줄기).
- 메뉴 호버 시 텍스트 옆에 작은 "시계 초침" 아이콘이 틱틱 움직임(시간 모티브).
- **분위기**: 고요, 쓸쓸, 무게감.
- **제작 난이도**: **쉬움** / **소요**: 2~3일
- **한글 폰트**: 나눔명조/고운돋움/일반 고딕.

### 방향안 γ. 고전 RPG 책형 (Tunic 경량판)
- 화면 중앙에 펼쳐진 오래된 책. 왼쪽 페이지=메뉴 목록, 오른쪽 페이지=설정/상세.
- 페이지 넘김 전환.
- **분위기**: 신비로운 고서.
- **제작 난이도**: **어려움** / **소요**: 1~2주 (페이지 전환 애니메이션 포함).

**권장**: β안이 분위기+솔로 난이도 밸런스 최상. "시간이 멈춘 숲"의 정적인 톤과 가장 맞음.

---

## 3-3. 시간 조작 UI 특수 연출 — 권장 방식

우리 프로젝트에서 가장 중요한 시각적 식별자. Katana Zero + Superhot 철학 조합 권장.

### 권장 스펙
- **정지 상태 진입 시 연출**:
  1. 화면 전체 채도 20~40%까지 다운 (셰이더 `saturation` 파라미터 0.5초 이징).
  2. 청백색 비네트가 가장자리에서 스며듦 (CanvasModulate + 추가 Light2D).
  3. 중앙 또는 우상단에 초침 아이콘이 1초간 표시되었다가 페이드 아웃.
  4. 미묘한 스캔라인 1프레임(선택, 많으면 피로).
  5. 오디오: 저음 드론 레이어 추가.

- **정지 중 상시 표시**:
  - 우상단 조그만 원형 시계 아이콘. 시계 바늘이 **멈춰있음**.
  - 시간 자원(스테미나성) 있다면 작은 수평 바 하단.

- **복귀 연출**:
  - 채도 복구(0.3초) + 비네트 해제 + 드론 페이드 아웃.

- **제작 난이도**: **보통** — 셰이더 2~3개(채도/비네트/스캔라인) + 파티클 1~2개로 충분.
- **예상 소요**: 3~4일 (셰이더 튜닝 포함).

**피해야 할 것**: Katana Zero의 VHS 글리치 — 자연/숲 톤과 충돌. 네온 색상 — 숲의 차분함 파괴.

---

## 3-4. 땅거미(공포 요소 특수 적) 연출 — 권장 방식

Ender Lilies의 상시 비네트 + Blasphemous의 피격 비네트 + Superhot의 오디오 활용.

### 권장 스펙
- **거리별 3단계**:
  1. **원거리 (미인식)**: 화면 가장자리 비네트가 평소보다 10~15% 진해짐. 저음 드론 페이드 인. 플레이어는 "뭔가 있다"만 감지.
  2. **중거리 (추적 임박)**: 비네트가 30~40%까지 진해지고, 화면 랜덤 위치에 **검은 잉크 얼룩**이 0.2초 깜빡였다 사라짐(2~3초 간격). 심장박동 사운드 레이어.
  3. **근거리 (피격 위험)**: 화면 네 모서리에서 검은 덩굴이 짧게 뻗어나옴(animated). 크로매틱 어베레이션 미세 적용. 사운드 고조.

- **시각 요소**:
  - **방향 지시**: 땅거미가 화면 밖에 있을 때, 해당 방향 가장자리가 특히 진함 (비대칭 비네트).
  - **소리**: 비주얼보다 사운드가 70% 비중. 1인 개발 시 비주얼은 최소화하고 사운드 프리셋 활용.

- **제작 난이도**: **보통** / **소요**: 3~5일 (비네트 셰이더 + 잉크 얼룩 스프라이트 3~5종 + 덩굴 애니메이션).

---

## 3-5. 월드맵 스타일 — 권장 방식

Hollow Knight(양피지+마커) + Ender Lilies(블록 연결형) 하이브리드.

### 권장 스펙
- **전체 스타일**: 양피지 배경 + 잉크 드로잉. 검은 잉크로 지역 경계, 초록/청록 잉크로 강이나 빛 영역 표시.
- **노드 구조**: 지역(스테이지)별 블록 + 지역 간 얇은 점선/실선 연결. 잠금 지역은 어둡게 그림자 처리 + 자물쇠 아이콘.
- **현재 위치**: 깜빡이는 원형 마커(청백색).
- **거점/체크포인트**: 나무 아이콘. 상점은 등불 아이콘.
- **해금 연출**: 잠금 해제 시 잉크가 확장되며 지역이 밝아지는 0.5초 애니메이션.
- **마커 시스템(선택)**: 플레이어가 직접 아이콘(느낌표, 별, X)을 배치 가능(Hollow Knight 차용).

- **제작 난이도**: **보통** — 양피지 배경 1장 + 잉크 브러시 tileable + 지역 블록 일러스트 N개(N = 스테이지 수).
- **예상 소요**: 스테이지 10개 기준 1~2주.

**한계/결정 필요**: 마커 시스템은 UX 복잡도 증가. 지역 수가 15개 이하면 생략, 20개 이상이면 채택 권장.

---

## 3-6. 트랜지션 — 권장 방식

Celeste의 카메라 슬라이딩 + Hollow Knight의 잉크 번짐 하이브리드.

### 권장 스펙
- **방 이동 (같은 스테이지 내)**: 카메라 슬라이딩 (Celeste 스타일). 즉각적, 0.2~0.3초.
- **스테이지 이동**: 검은 잉크가 화면 한쪽에서 번지며 페이드. 1초. 중앙에 지역명이 세리프 폰트로 등장 후 페이드 (Hollow Knight 스타일).
- **메뉴 전환**: 페이드 + 부드러운 슬라이딩 결합. 0.4초.
- **사망**: 플레이어 캐릭터가 픽셀 단위로 흩어짐(Celeste 스타일) → 검은 화면 → 리스폰 위치에서 페이드 인.
- **세이브 아이콘**: 우하단에 작은 시계 아이콘이 돌며 "기록 중" 0.5초 표시.

- **제작 난이도**: **쉬움~보통** / **소요**: 2~3일.

---

# 4. 1인 픽셀아트 개발자용 현실성 필터

## 4-1. 추천안 난이도 요약

| 추천안 | 난이도 | 예상 소요 | 비고 |
|---|---|---|---|
| HUD A안 (미니멀 영혼형) | 쉬움 | 2~3일 | 솔로 최적 |
| HUD B안 (고대 기록형) | 어려움 | 1~2주 | 장식 부담 |
| HUD C안 (하이브리드 실루엣) | 보통 | 4~6일 | 균형 |
| 메타 UI α (양피지) | 보통 | 3~5일 | 한글 폰트 주의 |
| 메타 UI β (다크 미니멀) | 쉬움 | 2~3일 | 솔로 최적 |
| 메타 UI γ (책형) | 어려움 | 1~2주 | 페이지 애니 부담 |
| 시간 조작 필터 | 보통 | 3~4일 | 셰이더 중심 |
| 땅거미 공포 연출 | 보통 | 3~5일 | 사운드 의존 |
| 월드맵 (하이브리드) | 보통 | 1~2주 | 지역 수에 따라 변동 |
| 트랜지션 | 쉬움~보통 | 2~3일 | Godot 기본 기능 활용 |

**총 HUD+메타 권장 조합 (A안 + β안)**: 약 4~6일.
**전체 UI 완성(모든 카테고리) 예상**: 4~6주 (솔로 풀타임 기준).

## 4-2. 피해야 할 것 (솔로 불가/비효율)

- Hollow Knight의 핸드드로잉 수채 배경·프레임 장식 수준 (팀 작업 2년+).
- Blasphemous의 종교화 수준 세밀 아이콘 120개+ (스타일 통일성 높아 모방 어려움).
- Tunic의 완전한 인쇄 매뉴얼 재현 (컨셉 차용만).
- Eastward의 3D 라이팅 기반 픽셀아트 파이프라인.
- Katana Zero의 VHS/CRT 복합 셰이더 (스타일 충돌 문제도 있음).

## 4-3. 솔로 개발 핵심 전략

1. **아이콘 개수 상한**: 80개. Dead Cells 300+, Blasphemous 200+는 불가.
2. **색 팔레트 제한**: 16~24색. 파스텔 청백 + 다크 네이비 + 세피아 + 포인트 1~2색.
3. **실루엣 + 단색 글로우** 통일. 그라데이션/광택 피하기.
4. **프레임/장식은 tileable**. 수작업 장식보다 재사용 가능한 블록.
5. **UI 해상도는 게임보다 2배 (640x360 게임 → 1280x720 UI)**. Celeste 원칙.
6. **한글 폰트 비트맵 변환**: 본명조·나눔명조 계열 소문자 픽셀화 또는 기성 픽셀 한글 폰트(네오둥근모, 둥근모꼴) 고려.

---

# 5. 분석의 한계와 사용자 결정 필요 사항

## 5-1. 한계

- 각 게임의 UI 스크린샷을 직접 관찰하지 않고 리뷰/분석글/DB 요약에 의존했으므로, 픽셀 단위의 정확한 수치(체력바 두께, 아이콘 크기 등)는 제공 불가. **Game UI Database** 직접 방문 권장.
- 일부 정보는 "추정" — 특히 Dead Cells 등급 색상, Ender Lilies 스킬 슬롯 세부 레이아웃은 커뮤니티 합의 기반 추정.
- 1인 개발 공수 산정은 사용자의 Aseprite/Godot 숙련도에 따라 ±50% 변동 가능.
- VR/고해상도 이슈(Eastward 3D 라이팅 등)는 우리 프로젝트와 무관하므로 심도 있게 다루지 않음.

## 5-2. 사용자 결정 필요 사항

1. **HUD 방향안 선택**: A안 / B안 / C안 / 하이브리드 중 결정.
2. **메타 UI 방향안 선택**: α / β / γ 중 결정.
3. **시간 조작 UI 강도**: 미묘하게(권장) vs 강렬하게.
4. **땅거미 연출 비주얼/오디오 비중**: 비주얼 중심(작업 많음) vs 오디오 중심(권장).
5. **월드맵 마커 기능**: 도입 여부 (지역 수에 따라 결정).
6. **한글 폰트 선택**: 기성 픽셀 한글 폰트 사용 vs 자체 픽셀화.
7. **대화창에 초상화 포함 여부**: 포함 시 NPC×감정 조합 수 결정 필요 (작업량 폭증 변수).
8. **Tunic식 "책 통합 메뉴"** 부분 차용 여부.
9. **데미지 넘버** 표시 여부 (Ender Lilies처럼 미표시 vs Dead Cells처럼 적극 표시).
10. **등급 색 코딩 시스템**: 5단계 유지 vs 간소화(3단계).

## 5-3. 다음 단계 제안

1. 사용자: 위 10개 결정 사항에 대한 답변을 리스트로 제공.
2. Claude: 확정된 선택을 기반으로 **art_specs/ui_specs.md** (아트 명세서) 생성 — HUD 각 요소의 정확한 픽셀 크기, 색상 헥스, 상태별 프레임 수, 애니메이션 타이밍.
3. Phase 3-7에서 실제 UI 제작 시 이 명세서를 기준으로 Aseprite 작업 → Godot 반영.

---

# 6. 출처

## 게임별 레퍼런스
- Hollow Knight: [Game UI Database](https://www.gameuidatabase.com/gameData.php?id=113), [Interface In Game](https://interfaceingame.com/games/hollow-knight/), [The Picky Champy Analysis](https://champicky.com/2022/03/23/hollow-knight-interface-design-analysis/), [Soul Wiki](https://hollowknight.fandom.com/wiki/Soul), [Hallownest Map](https://www.hallownest.net/)
- Blasphemous: [Game UI Database](https://www.gameuidatabase.com/gameData.php?id=97), [Wikipedia](https://en.wikipedia.org/wiki/Blasphemous_(video_game)), [Interface In Game](https://interfaceingame.com/games/blasphemous/), [Juan Carlos Ortega ArtStation](https://www.artstation.com/artwork/eRRdJ6)
- Ender Lilies: [Game UI Database](https://www.gameuidatabase.com/gameData.php?id=1193), [Rely on Horror Review](https://www.relyonhorror.com/reviews/review-ender-lilies-quietus-of-the-knights/), [TechRaptor Preview](https://techraptor.net/gaming/previews/ender-lilies-quietus-of-knights-is-both-bleak-and-beautiful), [CogConnected Review](https://cogconnected.com/review/ender-lilies-quietus-of-the-knights-review/)
- Katana Zero: [Kelleher Bros Review](https://www.kelleherbros.com/blog/2020/3/9/katana-zero-review), [Eoin Deroe Confession](https://www.eoinderoeoshea.com/katana-zero-full-confession), [Wikipedia](https://en.wikipedia.org/wiki/Katana_Zero)
- Superhot: [Game UI Database](https://www.gameuidatabase.com/gameData.php?id=789), [Robin Koman UI Review](https://robinkoman.com/ui-review-superhot/), [Interface In Game](https://interfaceingame.com/games/superhot/), [Washburn Review](https://washburnreview.org/7037/features/game-superhot-features-a-minimalist-art-style-engaging-mechanics/)
- Dead Cells: [Game UI Database](https://www.gameuidatabase.com/gameData.php?id=1780), [HudFreeGaming](https://hudfreegaming.fandom.com/wiki/Dead_Cells)
- Moonlighter: [Game UI Database](https://www.gameuidatabase.com/gameData.php?id=205), [80lv Article](https://80.lv/articles/moonlighter-building-pixel-art-preparing-for-switch), [Interface In Game](https://interfaceingame.com/games/moonlighter/)
- Death's Door: [Game UI Database PC](https://www.gameuidatabase.com/gameData.php?id=1085), [Jenny Brewer Portfolio](https://www.missjenart.com/uiart/deathsdoor-icons), [Frits Olsen ArtStation](https://www.artstation.com/artwork/X18WBL)
- Hyper Light Drifter: [Game UI Database](https://www.gameuidatabase.com/gameData.php?id=497), [UI Breakdown by SYH](https://medium.com/the-space-ape-games-experience/hyper-light-drifter-ui-breakdown-c2d9cfe0a192), [I Draw Wearing Hats](http://idrawwearinghats.blogspot.com/2014/04/art-direction-analysis-of-hyper-light.html), [Color Palette](https://www.colourlovers.com/palette/4422211/Hyper_Light_Drifter)
- Eastward: [Game UI Database](https://www.gameuidatabase.com/gameData.php?id=2131), [Game Developer Interview](https://www.gamedeveloper.com/art/eastward-s-creators-share-insights-on-making-pixel-art-adventures), [80lv Article](https://80.lv/articles/eastward-charming-chinese-pixel-art-adventure)
- Celeste: [Game UI Database](https://www.gameuidatabase.com/gameData.php?id=53), [saint11 Consistency](https://saint11.art/blog/consistency/), [Celeste Tilesets](https://aran.ink/posts/celeste-tilesets), [Interface In Game](https://interfaceingame.com/games/celeste/)
- Tunic: [Game UI Database](https://www.gameuidatabase.com/gameData.php?id=1385), [Raja Kabierski Blog](https://www.rajakabierski.com/blog/tunic), [80lv Manual Article](https://80.lv/articles/tunic-s-developer-on-creating-the-in-game-manual-full-of-mysteries), [Game Developer IGF](https://www.gamedeveloper.com/road-to-igf-2023/how-tunic-weaves-wondrous-unknowable-worlds-inspired-by-inscrutable-nes-manuals)

## 일반 참고
- [PC Gamer - Metroidvania Map Design](https://www.pcgamer.com/how-to-design-a-great-metroidvania-map/)
- [Game Developer - Hollow Knight Mapping](https://www.gamedeveloper.com/design/how-the-i-hollow-knight-i-devs-mapped-out-their-metroidvania-)
- [DualShockers - Best Metroidvania Maps](https://www.dualshockers.com/best-metroidvania-game-maps/)
- [MetSys - Godot Metroidvania Framework](https://github.com/KoBeWi/Metroidvania-System)
- [Wayline - Floating Combat Text Implementation](https://www.wayline.io/blog/unity-floating-combat-text)
- [Studio Miniboss Pixel Art Tutorials](https://blog.studiominiboss.com/pixelart)

---

*작성 완료. 사용자는 "5-2. 사용자 결정 필요 사항"의 10개 항목에 답변하면 다음 단계(아트 명세서 작성)로 진행 가능.*
