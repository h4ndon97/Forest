# UI / UX / 접근성 추천

> **STATUS**: 본 문서 모든 항목 PROPOSED. 결정 아님.
> **카테고리 코드**: UX

---

## REC-UX-001 — 모래시계 그림자 (시간 자원 시각화)

- **상태**: **STALE** (2026-04-26 확정)
- **우선순위**: ~~★★★~~
- **노력**: S
- **레퍼런스**: Hollow Knight — Soul orb, Don't Starve — 직관적 게이지
- **관련 시스템**: HUD, TimeSystem
- **무효화 사유**: 현 시간 코어(일식링/궤도/배지) 디자인이 이미 구현되어 있고 사용자 만족 상태. 메모리 [B-6 일식 링 팔각형 형태 결정](C:/Users/sldpa/.claude/projects/c---H4ndon-Forest/memory/project_b6_octagon_decision.md) (2026-04-23) 디자인 결정 완료. 본 추천의 모래시계 메타포는 채택하지 않음.
- **결정 이력**: 2026-04-26 사용자 결정 — 옵션 A (STALE 확정, 현 일식링 유지). 모래시계 컨셉 폐기.

### 컨셉
숫자 게이지 대신 **모래시계 픽셀아트** + 위 모래가 떨어지지 않는 시각적 메타포. 그림자가 모래시계 옆에 누적될수록 위협 가시화. UI 이중 축 (플레이어 HUD = 빛/그림자) 정책 적용.

### 시각 컨셉
```
 ▽ (위 모래 — 시간 자원)
 |
 ↓ (정지 시 멈춰있음)
 △ (아래 모래 — 흐른 시간 누적)

옆에 그림자 형태가 점점 커짐 (그림자 강도 시각화)
```

### 이 프로젝트 적용
- 시간 정지 중: 위 모래 정지 (정상 정지 — 위안)
- 시간 흐름 중: 위 모래가 아래로 흐름
- 자원 부족 시: 위 모래 거의 없음 (시각적 경고)
- 그림자 강도: 모래시계 옆에 그림자 윤곽이 점점 짙어짐

### 구현 메모
- 현 시간 코어 위젯 교체 또는 보완
- 픽셀아트 64×64 또는 96×96 (HUD 크기)
- ShadowSystem 강도와 연동

---

## REC-UX-002 — 미니맵 단계 시스템 (Cornifer 의존)

- **상태**: PROPOSED
- **우선순위**: ★★★
- **노력**: M
- **레퍼런스**: Hollow Knight — 단계적 지도 시스템
- **관련 시스템**: WorldMapUI, MiniMap
- **의존**: REC-CONT-002 (측량사 NPC)
- **무효화 조건**: 미니맵 처음부터 풀 가시화 정책 채택 시

### 컨셉
HK의 단계적 지도 시스템:
1. 측량사 만나기 전 → 미니맵 빈칸
2. 측량사에게 영역 지도 구매 → 영역 가시화 (탐험한 부분만)
3. 거점에서 마커 강화 구매 → 핀 + 벤치/상점 마커
4. 추가: 자기 위치 표시기 강화

**메트로배니아 표준이며 학습 곡선 자연스러움**.

### 이 프로젝트 적용
- 1구역 = 1 측량사 (총 5명)
- 거점 NPC가 마커 종류 판매:
  - 체크포인트 마커 (거점 위치)
  - 상점 마커
  - 미발견 통로 마커 (Manuscript 단서)
  - 빛령 마커 (REC-CONT-001과 시너지)

### 구현 메모
- WorldMapUI에 영역별 가시화 단계 (none / base / marked)
- MiniMap 구현 (현재 기획만 — Phase 4 이월)
- 마커는 SaveSystem에 저장
- M 키로 월드맵 / 미니맵은 HUD 우하단 (현 위치)

---

## REC-UX-003 — 인벤토리 (픽셀 일러스트 + 짧은 시)

- **상태**: **IMPLEMENTED (인프라)** (2026-04-26)
- **우선순위**: ★★★
- **노력**: S (인프라) / M (작가 협업 후 텍스트 채우기)
- **레퍼런스**: Blasphemous — Rosary Beads / Prayers
- **관련 시스템**: InventorySystem, ItemData, equipment_tab
- **검증 (인프라)**:
  - `data/items/item_data.gd` — `flavor_text: String` 필드 추가 (`@export_multiline`)
  - `src/ui/menus/inventory/equipment_tab.gd` — `_flavor_label` 추가 (보라/회색 톤 `Color(0.55, 0.45, 0.7, 0.85)`), `_update_selection`에서 빈 문자열 아닐 때만 표시
  - `data/items/weapons/sword_basic.tres` placeholder 시조 풍 텍스트 추가 — 시각 검증용
  - 메모리 [feedback_art_ready_code] 정책 부합 — 텍스트 비어있으면 영역 자동 숨김, 채우면 즉시 반영
  - gdlint 통과 + Godot 헤드리스 로드 통과
- **남은 작업 (작가 협업 의존)**: 30~50개 아이템 시 텍스트 채우기 + (옵션) 일러스트 144×144

### 구현 컨셉
- ItemData 스키마에 `flavor_text` 필드 추가 (메카닉 `description`과 별개)
- 인벤토리 [장비] 탭의 정보 영역에 별도 라벨 — 메카닉 설명 위에 회색 보라 톤으로 표시
- 빈 문자열이면 라벨 숨김 — 작가 미작성 아이템도 자연스럽게 작동

### 검증 (UI 시각)
- 인벤토리 열기 → 낡은 검 선택 → 정보 영역에 표시:
```
낡은 검
평범한 검. 쓸만하다.
  ※ 녹슨 날에도 손때는 남아 — 누군가의 길이었으리.
```
- 다른 아이템(flavor_text 비어있음) 선택 → flavor 라벨 자동 숨김

### 미래 확장
- REC-NARR-003 Lore Trinkets와 같은 스키마 공유 — 새 카테고리(trinket)에서도 즉시 활용 가능
- 일러스트 144×144 — 별도 art_specs 작성 필요
- 한국어 시조 / 동양 철학 톤 (REC-MKT-002/004 시너지)

### 컨셉
한국 인디 차별화. 18 스킬 + 장비 4종(검/방어구/장신구3) + 등불 강화 = 약 30~50 아이템. **각 아이템에 2~3줄 시 + 픽셀아트 144×144**. 환경 스토리텔링.

### 레퍼런스 분석
Blasphemous Rosary Beads:
- 각 묵주에 짧은 산문 + 일러스트
- 효과는 게임플레이지만 텍스트는 종교적 시
- 모은 묵주 = 자연스러운 lore 컬렉션

### 이 프로젝트 적용
- 아이템 종류:
  - 검 (5~7종): 각 검에 짧은 시 (한국어 시조 풍 가능, REC-MKT-002/004 시너지)
  - 방어구 (5종): 각자 사연
  - 장신구 (15~20종): 가장 풍부한 lore 매체
  - 등불 강화 단계 (5단계): 각 단계 시
  - 소모품: 단순 설명만
- 시 형식: 3~4줄, 시조 또는 단가 풍

### 작가 협업
- 한국어 시 = 작가 협업 필수 (REC-CONT-005 작가와 동일 가능)
- 영문 시는 후속 패치 (한국어 → 영어 번역 시 시적 손실 우려, 별도 작가 검토)

### 구현 메모
- 인벤토리 메뉴 UI 확장
- 아이템 클릭 시 일러스트 + 시 + 효과 분리 표시
- ItemData .tres에 `flavor_text` 필드 추가

---

## REC-UX-004 — 시간 정지 자동 보조 모드

- **상태**: PROPOSED
- **우선순위**: ★★
- **노력**: S
- **레퍼런스**: Celeste / Hades — Assist Mode
- **관련 시스템**: TimeSystem, 옵션 메뉴
- **의존**: —
- **무효화 조건**: 코어 메카닉이 충분히 직관적이라 검증되면

### 컨셉
일부 플레이어가 시간 정지 활용을 어려워할 수 있음. **옵션으로 보조 제공, 도전과제는 잠금**. 한국 인디 시장 접근성 어필.

### 옵션
- 시간 정지 시간 +50% (정지 자체가 더 길어짐)
- 그림자 강도 -1 stage (난이도 자동 하향)
- 땅거미 추적 비활성
- 적 데미지 -25%
- 자동 패리 윈도우 +50% (REC-MECH-003 시 적용)

### 이 프로젝트 적용
- 옵션 메뉴 새 섹션 "접근성"
- 각 옵션 ON/OFF 또는 % 조정
- 도전과제는 자동으로 잠금 (Hades 패턴)
- 게임 시작 시 1회 안내 (방해 안 되게)

### 구현 메모
- TimeSystem/ShadowSystem/DuskSpiderSystem에 modifier hook
- SaveSystem에 옵션 상태 저장
- 옵션 변경은 게임 중 적용 가능

---

## REC-UX-005 — 한글 픽셀아트 폰트 통합

- **상태**: **IMPLEMENTED** (2026-04-26 검증)
- **우선순위**: ★★★
- **노력**: S
- **레퍼런스**: korean_pixel_font_research.md
- **관련 시스템**: UI 전체
- **검증**: `data/themes/main_theme.tres` (Galmuri11/14 + Mulmaru fallback) + `project.godot:58` `theme/custom` 등록 확인. Label/Button/RichTextLabel/HudLabel 자동 적용.
- **이력**: 본래 본 폴더 작성 시(2026-04-25) PROPOSED로 잘못 표기. 코드 검증 누락 사례. 2026-04-26 사용자 지적으로 정정.

### 컨셉
한국 1인 개발의 차별화. **한글 폰트 + 영문 폰트 분리**. 일본 인디(Tunic 따라잡기) 시장 진입에 결정적. 가독성 = 시장 결정 요인.

### 이 프로젝트 적용
- 메인 폰트: Galmuri 또는 Mulmaru (이미 리서치)
- 서브 폰트: 영문 — 적절한 픽셀 영문 폰트
- UI 텍스트는 원본 해상도(1080p)로 렌더 (이미 GDD §13 결정)
- Manuscript Pages(REC-CONT-005)는 별도 룬 폰트 (작업 필요)

### 구현 메모
- 본 항목은 거의 IMPLEMENTED 직전 상태 (리서치 완료)
- 적용 작업만 남음 → 메인 세션에서 별도 진행

---

## REC-UX-006 — Tunic식 디제틱 가이드 (매뉴얼 발견형)

- **상태**: PROPOSED
- **우선순위**: ★★★
- **노력**: S
- **레퍼런스**: Tunic — 매뉴얼 페이지 (페이지 발견 시 새 메카닉 단서)
- **관련 시스템**: StorySystem, UI
- **의존**: REC-CONT-005 (Manuscript)
- **무효화 조건**: REC-CONT-005 미채택 시 STALE

### 컨셉
**튜토리얼 분리 화면 대신 게임 내 매뉴얼 발견**. 1구역 초반에 메카닉 5장 분산 배치. **"튜토리얼"이 콘텐츠가 됨**.

### 레퍼런스 분석
Tunic Manual:
- 게임 진행하면서 자연스럽게 페이지 발견
- 페이지 자체가 메카닉 안내 (어떻게 굴리는지, 패리하는지 등)
- 화면 분리 튜토리얼 0
- 발견 자체가 즐거움

### 이 프로젝트 적용
- 1구역 시작 5분 내 발견 가능한 페이지 5장:
  - 페이지 1: 시간 정지/흐름 기본
  - 페이지 2: 그림자 = 적 강도
  - 페이지 3: 등불 사용
  - 페이지 4: 환경 오브젝트(거울)
  - 페이지 5: 땅거미 경고
- 페이지는 환경에 자연스럽게 배치 (두루마리, 비석, 묘사된 그림)

### 구현 메모
- REC-CONT-005 Manuscript 시스템과 같은 인벤토리 카테고리
- 1구역 매뉴얼 페이지는 룬 없이 한국어 (튜토리얼 역할)
- UI 스타일: 양피지 + 손그림 도해

---

## REC-UX-007 — 월드맵 상시 열람 + 일러스트 맵 + 시간 반영

- **상태**: ACCEPTED (2026-04-26 사용자 결정)
- **우선순위**: ★★★
- **노력**: M (Stage 0~2 인프라) / L (Stage 3 일러스트 협업)
- **레퍼런스**: Hollow Knight (월드맵 토글) + Ori (일러스트 배경 맵) + 본 게임 시간 모티프
- **관련 시스템**: WorldMapUI, OverlaySystem, EventBus, TimeSystem, StageSystem
- **검증 (현 상태)**:
  - 트리거: `src/entities/objects/portal/world_map_portal.gd:19-20` — 거점 포털 `interact` 키로만 `world_map_opened.emit()`
  - UI: `src/ui/menus/world_map/world_map_ui.gd` (302줄, Autoload CanvasLayer layer=90)
  - 시간 반영: `_refresh_bg_colors()` (line 272~) 노드 bg color만 갱신, 영역 일러스트 미존재
  - 입력 차단: `src/entities/player/player.gd:81-82` `world_map_opened/closed` → `_input_blocked` 토글
- **무효화 조건**: 현 원형 노드 그래프 디자인이 사용자 만족 상태로 확정되고 일러스트 방향 자체가 폐기될 경우

### 컨셉

현재 월드맵의 두 가지 한계:
1. **거점 포털에서만 열림** — 메트로배니아 표준 위반 (HK/Ori/Salt and Sanctuary 모두 어디서든 토글 가능)
2. **추상 원형 노드 그래프** — 본 게임의 시간/빛/그림자 모티프와 시각적 연결 약함

본 추천은 두 변경을 분리 처리:
1. **상시 열람** (Stage 0): 코드 변경만으로 즉시 — 새 입력 액션 + 어디서든 토글
2. **영역 polygon + 시간 셰이더 + 일러스트 swap** (Stage 1~3): 점진적 비주얼 강화 — 영역 마스크 인프라가 일러스트 단계까지 그대로 이어짐

### 단계적 진행

| Stage | 내용 | 비용 | 출력 |
|---|---|---|---|
| 0 | 상시 열람 라우팅. 새 입력 액션 + portal 외 트리거. 전투 중 정책 결정 | S | 어디서든 M 키로 월드맵 |
| **0.5** | **마우스 호버 detail panel + 미발견 스테이지 fog (`???`)** | M | 메트로배니아 표준 발견 보상감 |
| 1 | 영역 polygon + zone별 색 분리 fallback. 노드 재배치/유지 결정 | M | 일러스트 부재 시 시각 빈약 회피 |
| 2 | 영역 마스크 + 시간 셰이더 톤 변화 (낮=따뜻 / 저녁=황혼 / 밤=차가움) | M | 일러스트 없이도 시간 모티프 표현 |
| 3 | 영역 일러스트 텍스처 swap + ShaderMaterial 통합 | L (아트 협업) | 비주얼 완성. 코드 거의 무수정 |

### Stage 0 구현 메모 (상시 열람)

- 새 InputMap 액션 신설 (예: `toggle_world_map`, 기본 키 `M`)
- 토글 처리 위치: 글로벌 입력 처리 — 후보 (1) `world_map_ui.gd._unhandled_input` (2) 새 Autoload `MapInputRouter` (3) `pause_menu.gd` 확장
- 결정 필요: **전투 중 열림 가능?** — 옵션 A 일시정지 / 옵션 B 단순 오버레이 (시간/적 계속) / 옵션 C 전투 중 잠금
- 거점 포털은 **fast-travel 진입점으로 유지** (포털에서 열면 패스트트래블 모드, 일반 열기는 view-only 모드 분기 가능)
- 인벤토리/일시정지 등 다른 UI와 키 충돌 정책 확립 필요

### Stage 0.5 구현 메모 (마우스 호버 + fog)

**호버**:
- 모든 노드를 호버 대상으로 (거점/일반 구분 없음)
- 키보드 ←→는 유지 — 거점만 순회 (fast-travel 용도, 패드 호환)
- 호버 detail panel은 selection과 별개 — `_hover_id` 우선, 비면 `_selectable_ids[_selected_index]` fallback
- fast-travel은 키보드 selection 기반만 (호버로 이동 X)
- Control mouse_entered/exited 시그널 활용. `world_map_node_hover.gd` 신규 파일이 connect 처리

**fog**:
- 기준: **Stage 단위 발견** — 첫 입장 시 `_discovered_stages`에 set
- 시작 마을(`start_village`)은 처음부터 발견 상태
- 노드 색: 짙은 회색 단색 + 테두리 없음(또는 짙은 회색)
- detail panel: 이름 "???", 시각 "??", 상태 "미발견", 인접 hidden
- 연결선: 양쪽 발견된 경우만 표시
- REC-UX-002 (Cornifer 측량사)와 양립 — 본 fog는 기본 정책, REC-UX-002는 zone 단위 격상 (별도 레이어)

**파일 변경**:
- `src/systems/stage/stage_discovery.gd` 신규 (~30줄, StageSystem 자식)
- `stage_system.gd` — Discovery 자식 추가 + `is_stage_discovered` 위임. 라인 한계 압박으로 `_unhandled_input` debug jump 핫키를 `stage_debug.gd`로 이주
- `save_manager.gd` — `discovered_stages` 직렬화
- `world_map_graph_builder.gd` — fog 색 + 노드 mouse_filter PASS + `build_all_nodes` 통합 (ui 회수)
- `world_map_detail_panel.gd` — fog 시 `???` 표시 + `show_for(stage_id, pos)` 메서드 (ui 회수)
- `world_map_node_hover.gd` 신규 (~50줄)
- `world_map_ui.gd` — `_hover_id` 멤버 + selection/hover 통합 detail 호출

### Stage 1 구현 메모 (영역 polygon fallback)

- 영역 데이터: `data/world_map/zone_polygon_data.gd` Resource — zone별 polygon 정점 + 기본 색
- 1구역=따뜻한 황색, 2구역=청록 안개색, 3구역=보라/검정 거울색, 4구역=짙은 그림자색, 5구역=금/검정
- 노드는 polygon 위에 z-index로 오버레이. 기존 `_node_container` 위에 `_zone_polygon_container` 신설
- 노드 재배치는 사용자 결정 — 옵션 A 현 원형 유지 / 옵션 B polygon 내부에 자유 배치

### Stage 2 구현 메모 (시간 셰이더)

- `assets/shaders/world_map_time_tint.gdshader` 신설 — UV 기반 색조 보정 (낮=warm, 저녁=황혼, 밤=cool)
- TimeSystem `current_hour` → 셰이더 uniform `time_phase` (0~1) 매핑
- 영역별 각자 ShaderMaterial 인스턴스. polygon 또는 Sprite2D 모두 적용 가능
- 메모리 [godot-shaders-fx skill](C:/Users/sldpa/.claude/projects/c---H4ndon-Forest/memory/reference_godot_shaders_fx_skill.md) 활용

### Stage 3 구현 메모 (일러스트 swap)

- 영역별 PNG (예: 320×180 또는 640×360, 메인 캔버스 기준)
- 메모리 [발광 스프라이트 3레이어 규약](C:/Users/sldpa/.claude/projects/c---H4ndon-Forest/memory/project_art_three_layer_rule.md) 적용 (광원/등불 표현 시)
- placeholder fallback: 텍스처 미존재 시 polygon 색만 사용 — 코드 분기 없이 swap

### 의존/시너지

- REC-UX-002 (미니맵 단계 시스템) — **별도 시스템**. 월드맵=오버뷰, 미니맵=룸 단위. 본 추천은 월드맵에 한정
- REC-CONT-002 (Cornifer형 측량사 NPC) — 의존 없음. 본 추천은 처음부터 풀 가시화 전제 (단계적 가시화는 REC-UX-002 영역)
- REC-MKT-002 (수묵화 톤 픽셀아트) — Stage 3 일러스트 방향 강한 시너지
- REC-FX-006 (컷신 인프라) — 일러스트 패널 작업 흐름 공유

### 결정 이력

- 2026-04-26 사용자 결정 — 상시 열람 + Stage 단계적 진행 + A안(셰이더 톤 변화)부터 시작 채택. 추천 폴더 등재 + Architect 설계 진행 합의.

---

## 카테고리 메모

- 7개 중 5개가 노력 S/M — UI 작업은 핵심 시스템 변경 적음
- REC-UX-005 (한글 폰트)는 이미 리서치 완료 — 즉시 적용 가능
- REC-UX-002/006은 다른 카테고리 의존 — 통합 작업 권장
- REC-UX-004 (접근성)는 한국 인디 시장 + 글로벌 모두에서 어필 강함
- REC-UX-007은 메트로배니아 표준 + 본 게임 시간 모티프의 결합점 — Stage 3 일러스트 도달 시 마케팅 GIF hook 가치 큼
- 본 카테고리는 **현재 가장 빈약한 영역** (메타/접근성/도전과제 문서 부재)
