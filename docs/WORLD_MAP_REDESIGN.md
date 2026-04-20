# 월드맵 동심 극좌표 재설계

> 작성: 2026-04-20. Phase 3-5 월드맵의 1D 선형 BFS 레이아웃을 동심 링 + 2단 드릴다운 구조로 재설계한다.
> 본 문서는 설계 확정본 + 4단계 구현 순서. 각 Step 별도 승인 후 커밋.

---

## 1. 컨셉

### 1.1 공간 모델
- **전체 월드 = 5개 동심 링**. 1구역(빛의 숲)이 가장 바깥, 5구역(봉인의 심부)이 중심
- 구역이 안쪽으로 갈수록 스토리상 깊어짐 — "숲은 안으로 갈수록 깊어진다"(WORLD_DESIGN.md §2)
- 각 스테이지 = 자기 zone의 링 위 한 점. 극좌표 `(radius_ring, angle_deg)`로 절대 위치 보유
- 링 형태는 엄밀한 원이 아니어도 됨 (불규칙 폐곡선 허용 — 추후 아트 단계에서 결정)

### 1.2 뷰 모드
**2단 드릴다운**. 같은 월드 평면을 카메라 줌 레벨로 잘라 보여줌:

| 뷰 | 진입 | 표시 | 선택 단위 |
|---|---|---|---|
| **OVERVIEW** | M (1회) | 5링 전체 + 노드 점 + zone 라벨 | zone, 발견된 거점 |
| **DRILL_IN(zone_N)** | OVERVIEW에서 선택 + Enter | 해당 zone 아크 확대 + 라벨/상태/잠금/땅거미 | 스테이지/거점 |

### 1.3 뷰 전환

```
OVERVIEW
  ↓ (zone or 거점 선택 + Enter)
DRILL_IN(zone_N)
  ↓ ui_cancel/M           → OVERVIEW
  ↓ 인접 zone 경계 거점 선택 → DRILL_IN(zone_N±1)  [카메라 회전+반경 tween]
```

---

## 2. 확정 결정 (2026-04-20 사용자 합의)

| # | 항목 | 결정 |
|---|---|---|
| 1 | 1-h(숨겨진 스테이지) 방향 | **링 안쪽** (radius_offset 음수) |
| 2 | 경계 거점 소속 | 양쪽 zone drill-in 모두 노출 (중복 선택 가능) |
| 3 | 안쪽 링 프리뷰 | drill-in 시 **완전 가림** (스포일러 차단) |
| 4 | zone_1 아크 점유 | **270°** — 6시 시작, **반시계방향**으로 9시 종료 |
| 5 | 카메라 전환 | 부드러운 팬+줌 tween (~0.35s, ease_out) |
| 6 | test_* 스테이지 처리 | OVERVIEW/DRILL_IN 양쪽 숨김 (`zone_id=""` 또는 `radius_ring=0`) |
| 7 | 경계 거점 시각 구분 | 일반 거점 대비 테두리 +1px + **방사 화살표 배지**(`→ zone_2` 또는 `← zone_1`) |
| 8 | Phase 3-7 Pass 3 와 병행 | 파일/시그널/Autoload 충돌 없음 — 별도 커밋 |

---

## 3. 데이터 스키마

### 3.1 StageData 신규 필드

`data/stages/stage_data.gd`:

```gdscript
@export_group("월드맵 위치 (극좌표)")
## 동심 링 인덱스. 1=외곽(zone_1), 5=심부(zone_5). 0=월드맵 미표시(test_*).
@export var radius_ring: int = 0
## 시계 각도 (도). 0°=12시, 시계방향 증가. 0~360.
@export var angle_deg: float = 0.0
## 링 반경 오프셋 (픽셀). 음수=안쪽으로 끌어당김(숨겨진 leaf), 양수=바깥쪽.
@export var radius_offset: float = 0.0
```

기존 `zone_id`, `adjacent_stages`, `is_checkpoint` 필드는 그대로 유지.

### 3.2 위치 계산

```gdscript
const RING_RADII := { 1: 140, 2: 110, 3: 85, 4: 60, 5: 35 }  # Step 2 아이콘화 튜닝값
const RING_CENTER := Vector2(320, 180)  # detail panel이 가변 위치로 바뀌어 중앙 복귀

func compute_node_position(data: StageData) -> Vector2:
    var r := RING_RADII.get(data.radius_ring, 0) + data.radius_offset
    # clock convention → math convention: 0°=12시 CW → -90°=12시 CCW
    var math_rad := deg_to_rad(data.angle_deg - 90.0)
    return RING_CENTER + Vector2(cos(math_rad), sin(math_rad)) * r
```

### 3.3 zone_1 위치 할당 (확정)

9 노드 × 270° 아크 = 33.75° 간격, 6시(180°) 시작, **반시계방향**(angle 감소).

| stage_id | display_name | radius_ring | angle_deg | radius_offset | 비고 |
|---|---|---|---|---|---|
| `start_village` | 시작 마을 | 1 | 180.0 | 0 | 6시, 숲 밖 진입 |
| `stage_1_1` | 숲의 입구 | 1 | 146.25 | 0 | 5시 |
| `stage_1_2` | 나무 사이길 | 1 | 112.5 | 0 | 4시 |
| `stage_1_3` | 이끼 계곡 | 1 | 78.75 | 0 | 2~3시 |
| `stage_1_4` | 고목의 뜰 | 1 | 45.0 | 0 | 1~2시 |
| `stage_1_h` | 숨겨진 등불대 | 1 | 45.0 | **-50** | 1-4 안쪽, 같은 각도. "뒤에 숨은" 느낌으로 일부 패널 겹침 허용 |
| `stage_1_5` | 부서진 사당 | 1 | 11.25 | 0 | 12시 근처 |
| `stage_1_6` | 빛의 공터 | 1 | 337.5 | 0 | 11시 |
| `stage_1_b` | 거대 고목 (보스) | 1 | 303.75 | 0 | 10시 |
| `border_checkpoint` | 1-2 경계 | 1 | 270.0 | 0 | 9시, zone_2 방사 진입구 |

zone_2~5 스테이지는 미정의 (Phase 진입 시 채움). OVERVIEW에서 빈 placeholder 링만 점선으로.

---

## 4. 뷰 상태 머신

### 4.1 상태 변수

```gdscript
enum View { OVERVIEW, DRILL_IN }
var _view: View = View.OVERVIEW
var _focused_zone_id: String = ""   # DRILL_IN 시
var _camera_tween: Tween             # 전환 중 입력 차단용
var _transitioning: bool = false
```

### 4.2 렌더 분기

| 대상 | OVERVIEW | DRILL_IN(zone_N) |
|---|---|---|
| 포커스 zone 노드 | 점만 (라벨 없음) | 라벨/상태/잠금/땅거미 노출 |
| 다른 zone 노드 | 점만 (작게) | **숨김** |
| zone 경계 거점 | 양쪽 zone에서 점 표시 | 양쪽 drill-in 모두 노출 + 화살표 배지 |
| placeholder 링(zone_2~5, 미구현) | 점선 원 + zone 이름 라벨 | 숨김 |
| 같은 ring 인접 연결선 | arc 세그먼트 (8~12 포인트 샘플링) | 동일 |
| 다른 ring 인접 연결선 | 방사 직선 | 동일 |
| 1-h leaf | radius_offset 적용된 위치 | 동일 |
| 시간 오버레이 | 노드 bg tint (기존 D11 유지) | 동일 |

### 4.3 경계 거점 시각 구분

- **일반 거점 테두리**: 2px 금색
- **경계 거점 테두리**: 3px 금색
- **방사 화살표 배지**: 노드 옆에 작은 라벨 `→ zone_2` (drill-in zone_1) / `← zone_1` (drill-in zone_2)
- 배지 위치 = 노드에서 다음 zone 방향(반경 안쪽)으로 14px 오프셋
- 경계 판정: `adjacent_stages` 의 stage들 중 다른 `zone_id` 존재 시 boundary

### 4.4 카메라

`Camera2D` 노드 추가, 또는 `Control` `pivot_offset` + `scale` tween. 후자가 CanvasLayer 친화적.

```gdscript
func _focus_zone(zone_id: String) -> void:
    var arc_center := _compute_zone_arc_center(zone_id)  # zone 노드 angle 평균
    var target_offset := Vector2(320, 180) - arc_center
    var target_zoom := 1.8  # 줌 레벨
    _transitioning = true
    _camera_tween.tween_method(_apply_camera, _current_state, target_state, 0.35) \
        .set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
    _camera_tween.finished.connect(func(): _transitioning = false, CONNECT_ONE_SHOT)
```

---

## 5. 파일 영향

| 파일 | 변경 | 예상 줄수 |
|---|---|---|
| `data/stages/stage_data.gd` | +3필드 (radius_ring, angle_deg, radius_offset) | 41 → 50 |
| `data/stages/*.tres` (zone_1 10건) | 신규 필드 채움 | 데이터 패치 |
| `src/ui/menus/world_map/world_map_graph_builder.gd` | **재작성** — 극좌표 배치, arc 연결선, placeholder 링, leaf offset | 230 → ~280 |
| `src/ui/menus/world_map/world_map_ui.gd` | 뷰 상태 머신 + 카메라 + 선택 로직 2단 → 분리 필요 | 310 → 분리 |
| `src/ui/menus/world_map/world_map_zone_layout.gd` | **재작성** — 극좌표 기반 라벨 + placeholder 링 | 69 → ~120 |
| `src/ui/menus/world_map/world_map_detail_panel.gd` | 변경 없음 | — |
| **신규** `src/ui/menus/world_map/world_map_view_state.gd` | enum/focused_zone/전환 명령 | ~80 |
| **신규** `src/ui/menus/world_map/world_map_camera.gd` | 카메라 tween/줌 헬퍼 | ~80 |

300줄 제한: `world_map_ui` 가 분리 후 ~200줄 유지, 신규 view_state/camera 가 각각 80~100줄.

---

## 6. 구현 순서 (4 Step)

각 Step 독립 커밋 가능. 사용자 승인 후 다음 Step 진행.

### Step 1 — 데이터 스키마 + zone_1 위치 패치
- `stage_data.gd` +3필드
- zone_1 10개 .tres 파일에 angle_deg/radius_ring/radius_offset 채움 (§3.3)
- 검증: gdlint clean / `--headless --quit` clean
- **렌더 변경 없음** — 기존 BFS 선형 UI 그대로 동작

### Step 2 — 그래프 빌더 극좌표 재작성 + OVERVIEW 뷰
- `world_map_graph_builder.gd` 재작성:
  - `compute_node_position()` 극좌표 → Vector2
  - `create_arc_connection()` 같은 ring 인접 시 호 샘플링
  - `create_radial_connection()` 다른 ring 인접 시 직선
  - `create_placeholder_ring()` zone_2~5 점선 원
- `world_map_ui.gd` 가 새 빌더 사용. drill-in 로직은 다음 Step. **OVERVIEW만 먼저 동작**
- 검증: 인게임 OVERVIEW 시각 확인. 노드 9개 + arc 연결선 + placeholder 링 4개 + zone_1 라벨

### Step 3 — 뷰 상태 머신 + 드릴인 + 카메라 tween
- `world_map_view_state.gd` 신규 — enum + focused_zone + 전환 규칙
- `world_map_camera.gd` 신규 — Control offset/scale tween (~0.35s)
- `world_map_ui.gd` 분리 (orchestrator로 축소)
- DRILL_IN 렌더: 라벨 노출, 다른 zone 숨김, detail_panel 연결 유지
- zone 간 이동: 경계 거점 선택 시 다른 zone drill-in 전환
- 검증: 인게임 — OVERVIEW → DRILL_IN(zone_1) → 노드 선택 → 패스트트래블, ESC 복귀, border 선택 시 zone_2 drill-in (zone_2 빈 상태)

### Step 4 — 경계 거점 배지 + 땅거미 ⚠ 분기 + QA
- 경계 거점 판정 로직(adjacency 중 다른 zone_id) + 화살표 배지 렌더
- 땅거미 ⚠: OVERVIEW 에서는 zone-level 배지(`zone_1 ⚠`), DRILL_IN 에서는 노드-level (기존 로직)
- placeholder 링 점선 스타일 튜닝
- 검증: gdlint / gdformat / 헤드리스 / 인게임 플레이테스트

---

## 7. 리스크

| 리스크 | 대응 |
|---|---|
| 300줄 제한 초과 | Step 3 착수 전 ui 분리 구조 확정. view_state/camera 신규 파일로 책임 분산 |
| arc 연결선 곡률 계산 | 두 점의 각도 보간 + 같은 반경에서 8~12 포인트 샘플링. Line2D 다점 사용 |
| 카메라 전환 중 입력 누수 | `_transitioning` 플래그로 `_process` 입력 무시 |
| test_* 스테이지 이동 호환성 | StageSystem 자체 로직(BFS 등록, 패스트트래블)에는 영향 없음. 월드맵 렌더만 숨김 |
| Phase 3-7 Pass 3 와 병행 | 파일/시그널 충돌 없음 확인됨 (effects/ vs ui/menus/world_map/) |
| `class_name` 신규 추가 시 캐시 갱신 | view_state/camera에 `class_name` 부여 시 `--editor --headless --quit` 1회 필요 (Pass 2 학습) |

---

## 8. 미결 / 향후 결정

- 링 반경 실측값 (RING_RADII): ✅ Step 2 아이콘화로 {1:140, 2:110, 3:85, 4:60, 5:35}, 중심 (240,180). 드릴인 후 재조정 가능
- 오버뷰 노드 디자인: 16px 원형 dot + 방사 이름 라벨(font 7, 64x10). 상태/시간/잠금 상세는 detail panel 담당
- 카메라 줌 레벨 (drill-in scale): Step 3 시각 확인 후 튜닝
- 경계 거점 배지 폰트/색상 정확값: Step 4 시각 확인 후 튜닝
- zone_2~5 실제 노드 추가 시점: 각 zone Phase 진입 시
- 아크 시작 각도 / 회전 방향이 zone 별로 다를 수 있음 (zone_2는 다른 각도) — Phase 4-E 진입 시 결정
- 1구역 영역 탑뷰 픽셀아트 (Phase 3-7 아트와 병행 항목): 본 재설계와 별개로 진행

---

## 9. 참조

- `docs/PHASE_3_PLAN.md` §7 — Phase 3-5 원안
- `docs/WORLD_DESIGN.md` §2 — 나선형 세계 배치
- `docs/STAGES.md` — 거점 시스템
- `docs/CORE_SYSTEMS.md` — StageData / StageSystem
