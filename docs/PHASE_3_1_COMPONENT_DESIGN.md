# Phase 3-1 신규 컴포넌트 4종 설계 (Architect)

> 작성일: 2026-04-18
> **구현 완료: 2026-04-18** — 4종 컴포넌트 + 7 스테이지 모두 반영
> 상위 문서: `PHASE_3_PLAN.md` §3 / `DEVELOPMENT_PLAN.md` §Phase 3-1
> 대상: 1구역 레벨 디자인 착수 전 선구현할 컴포넌트 설계 (✅ 완료)

---

## 0. 공통 원칙

- **단일 책임**: 각 컴포넌트는 감지 / 드러내기 / 검증 중 하나만 수행 (Composition over Inheritance).
- **Signal 기반 통신**: 직접 참조는 부모→자식 주입 또는 등록 반환값 범위 (`feedback_direct_ref_policy`).
- **센싱형은 STOPPED 게이팅 없음**: 환경 상태의 연속 관측이 본질. 수동 조작 오브젝트만 STOPPED 게이팅 유지 (기존 `environment_object.gd`).

---

## 1. HiddenRevealer 컴포넌트 (✅ 구현 완료)

### 1.1 책임
4가지 `reveal_condition` (LIGHT_SENSOR / REFLECTION / PURIFICATION / SHADOW_COVER) 중 하나의 충족 시 타깃을 드러내는 동작만 담당. 감지는 외부 센서/detector에 위임.

### 1.2 파일 경로
```
src/entities/objects/environment/hidden_revealer/
├── hidden_revealer.gd              # 본체 (≤ 150줄)
├── HiddenRevealer.tscn             # 씬 (Node2D 단독)
└── reveal_condition.gd             # enum 전용

data/environment/
└── hidden_revealer_data.gd         # HiddenRevealerData Resource
```

### 1.3 씬 구성
```
HiddenRevealer (Node2D, script=hidden_revealer.gd)
  └─ (선택) DebugLabel (Label)
```

### 1.4 공개 API
```gdscript
@export var data: HiddenRevealerData
@export var target_node_path: NodePath
@export var source_node_path: NodePath

func is_revealed() -> bool
func force_reveal() -> void
```

### 1.5 HiddenRevealerData (Resource)
```gdscript
class_name HiddenRevealerData extends Resource
enum RevealCondition { LIGHT_SENSOR, REFLECTION, PURIFICATION, SHADOW_COVER }
enum RevealAction { QUEUE_FREE, SET_VISIBLE }
@export var reveal_condition: RevealCondition
@export var reveal_action: RevealAction = RevealAction.SET_VISIBLE
@export var one_shot: bool = true
@export var require_sustained_seconds: float = 0.0
```

### 1.6 조건별 구독 dispatch
| reveal_condition | 감지 소스 | 구독 시그널 |
|---|---|---|
| `LIGHT_SENSOR` | source → LightSensor | 로컬 `light_sensor_activated` |
| `REFLECTION` | source → LightSensor (반사광이 도달한 동일 컴포넌트) | 로컬 `light_sensor_activated` |
| `PURIFICATION` | source → ShadowResidue | EventBus `residue_purified` (position 필터) |
| `SHADOW_COVER` | source → 차폐물의 `ShadowProjectionZone` | Area2D `body_entered/exited` (플레이어 그룹 필터, `require_sustained_seconds` 지속) |

### 1.7 시그널
- 로컬: `revealed(target: Node)`
- EventBus: 없음 (선택적으로 `hidden_revealed(stage_id, revealer_name)` 연출용)

### 1.8 세이브 복원
드러난 후 StateFlags에 `hidden_revealer.<stage_id>.<node_name>` 플래그 기록. 재진입 시 `_ready`에서 플래그 확인 후 `force_reveal()` 즉시 호출.

### 1.9 STOPPED 게이팅
없음. 모든 조건 소스가 센싱이므로 상시 관측.

---

## 2. LightSensor 컴포넌트 (ENVIRONMENT α) (✅ 구현 완료)

### 2.1 책임
빔 감지 → 점등/소등 토글. 이중 용도: (a) HiddenRevealer LIGHT_SENSOR/REFLECTION 소스, (b) ENVIRONMENT 잠금 α validator.

### 2.2 파일 경로
```
src/entities/objects/environment/light_sensor/
├── light_sensor.gd                 # 본체 (≤ 200줄)
├── LightSensor.tscn

data/environment/
└── light_sensor_data.gd            # LightSensorData Resource
```

### 2.3 씬 구성
```
LightSensor (Area2D, layer=64 SENSOR, mask=128 LIGHT_BEAM)
  ├─ CollisionShape2D (RectangleShape2D 32×32)
  ├─ Visual (ColorRect, OFF/ON 색상)
  └─ (선택) LabelId
```

### 2.4 공개 API
```gdscript
signal light_sensor_activated(sensor_id: String)
signal light_sensor_deactivated(sensor_id: String)

@export var data: LightSensorData
@export var sensor_id: String

func is_activated() -> bool
func get_sensor_id() -> String
func force_set_state(activated: bool) -> void
```

### 2.5 LightSensorData (Resource)
```gdscript
class_name LightSensorData extends Resource
@export var sensor_id: String
@export var activation_delay: float = 0.15
@export var deactivation_delay: float = 0.15
@export var color_off: Color = Color(0.3, 0.3, 0.3)
@export var color_on: Color = Color(1.0, 0.9, 0.4)
```

### 2.6 시그널
- 로컬: `light_sensor_activated / light_sensor_deactivated`
- EventBus 신규: `light_sensor_toggled(sensor_id: String, is_on: bool)`

### 2.7 StageLockValidator ENVIRONMENT 분기 설계
`StageData.lock_requirement` 필드를 prefix 인코딩으로 재사용:
```
"light_sensor:<sensor_id>"   → α
"registry:<combo_key>"        → β
"flag:<flag_id>"              → γ
```
- Validator는 `light_sensor_toggled` 구독 → 내부 `_sensor_states` Dictionary 유지
- 검증 시점 주의: LightSensor는 해당 스테이지 씬이 로드되어야 존재 → 1-6 ENVIRONMENT 잠금 센서는 1-6 **이전** 스테이지에 물리 배치 필요

### 2.8 STOPPED 게이팅
없음 (순수 관측).

### 2.9 세이브
`_sensor_states`는 세이브하지 않음 (현재 관측값이므로 스테이지 로드 시 자체 재감지).

---

## 3. EnvironmentStateRegistry (ENVIRONMENT β, 2구역+ 앵커) (✅ 골격 구현 완료)

### 3.1 책임
여러 환경 오브젝트의 현재 상태 프리셋을 집계, 구체 조합 만족 판정. 1구역 미사용.

### 3.2 Autoload 여부
**Autoload 아님**. 스테이지 로컬 Node. 근거: 한 스테이지 내 조합이므로 스테이지 스코프.

### 3.3 파일 경로
```
src/systems/environment_state/
├── environment_state_registry.gd         # 스테이지 로컬 Node
├── combination_rule.gd                   # Resource 정의
└── state_snapshot.gd                     # 내부 헬퍼

data/environment/combinations/
└── (스테이지별 .tres)
```

### 3.4 API (골격)
```gdscript
signal combination_satisfied(combo_key: String)
signal combination_broken(combo_key: String)

@export var rules: Array[CombinationRule]

func register_object(object_id: String, initial_state_name: String) -> void
func report_state(object_id: String, state_name: String) -> void
func is_combo_satisfied(combo_key: String) -> bool
func get_current_snapshot() -> Dictionary
```

```gdscript
class_name CombinationRule extends Resource
@export var combo_key: String
@export var required_states: Dictionary  # { object_id: state_name }
```

### 3.5 시그널
- 로컬: `combination_satisfied / combination_broken`
- EventBus 신규: `environment_combo_changed(combo_key: String, satisfied: bool)`

### 3.6 의존성
- **받음**: 환경 오브젝트가 `report_state()` 직접 호출 (등록 반환값 정책, 그룹 기반 탐색)
- **보냄**: StageLockValidator β 분기, 디버그 UI

### 3.7 STOPPED 게이팅
없음.

### 3.8 1구역 사용
**미사용**. API 골격만 커밋 → 2구역 설계 시 활용.

---

## 4. StateFlagPersistence (ENVIRONMENT γ, 독립 Autoload) (✅ 구현 완료)

### 4.1 책임
씬 전환/세이브 간 지속되는 boolean 플래그 저장소. 월드 영구 이벤트 추적.

### 4.2 Autoload
**독립 Autoload `StateFlags`**. `StageSystem` 이전에 등록.

### 4.3 파일 경로
```
src/systems/state_flags/
├── state_flag_persistence.gd          # Autoload 본체 (≤ 200줄)
└── flag_naming.gd                     # 상수 모음
```

### 4.4 공개 API
```gdscript
signal flag_set(flag_id: String)
signal flag_cleared(flag_id: String)

func set_flag(flag_id: String, value: bool = true) -> void
func has_flag(flag_id: String) -> bool
func get_flag(flag_id: String) -> bool
func clear_flag(flag_id: String) -> void
func get_all_flags() -> Dictionary
func load_save_data(data: Dictionary) -> void
func get_save_data() -> Dictionary
```

### 4.5 네이밍 컨벤션
- 형식: `<domain>.<scope>.<name>` (snake_case, `.` 구분)
- 예시:
  - `hidden_revealer.stage_1_4.portal_1h_revealed` (1-H 발견)
  - `boss.zone_1.cleared`
  - `stage_unlock.zone_4.shortcut_a`

### 4.6 시그널
- Autoload 로컬: `flag_set / flag_cleared`
- EventBus 신규: `state_flag_changed(flag_id: String, value: bool)`

### 4.7 SaveManager 연동
- `save_manager.gd.collect_data()` → `data["state_flags"] = StateFlags.get_save_data()`
- `save_manager.gd.apply_data()` → StateFlags.load_save_data
- StateFlags 자체는 파일 I/O 없음 (직렬화 경로 단일화)

### 4.8 의존성
- **구독**: 없음 (passive store)
- **피구독**: HiddenRevealer, StageLockValidator γ 분기, 월드맵 UI, 향후 2~5구역 퍼즐

### 4.9 STOPPED 게이팅
없음.

### 4.10 1구역 사용 (최소)
- HiddenRevealer 드러냄 후 일관 플래그 기록
- 1-H 입구 드러냄 시 `hidden_revealer.stage_1_4.portal_1h_revealed` 기록
- 실제 효과(2구역 빛 경로)는 2구역 설계 시 `has_flag()`로 분기

---

## 5. EventBus 신규 시그널

```gdscript
signal light_sensor_toggled(sensor_id: String, is_on: bool)
signal environment_combo_changed(combo_key: String, satisfied: bool)
signal state_flag_changed(flag_id: String, value: bool)
signal hidden_revealed(stage_id: String, revealer_name: String)  # 선택, 연출용
```

---

## 6. 단위 검증 시나리오 (TestStage)

| # | 컴포넌트 | 시나리오 | 통과 조건 |
|---|---|---|---|
| V1 | LightSensor 단독 | 렌즈 빔 FocusZone layer=128 승격 후 센서(layer 64, mask 128) 겹침 | `light_sensor_toggled` ON/OFF 토글 |
| V2 | HiddenRevealer LIGHT_SENSOR | V1 센서 ON 시 숨은 타깃 visible/free | 시그널 수신 1프레임 내 드러남 |
| V3 | HiddenRevealer PURIFICATION | ShadowResidue 정화 시 타깃 드러남 | `residue_purified` 수신 + 플래그 set |
| V4 | HiddenRevealer SHADOW_COVER | 플레이어 영역 내 sustained 체류 | 타이머 만료 시 드러남, 이탈 시 리셋 |
| V5 | StageLockValidator α | lock_requirement="light_sensor:sensor_a" / 센서 OFF 거부, ON 통과 | 포탈 진입 정확히 분기 |
| V6 | StateFlagPersistence | set → 세이브 → 재시작 → 유지 | has_flag 반환 일치 |
| V7 | HiddenRevealer 세이브 복원 | 드러낸 후 스테이지 재진입 | `force_reveal` 즉시 호출 |
| V8 | EnvironmentStateRegistry 스모크 | 더미 규칙 1 + 오브젝트 2 조합 토글 | `environment_combo_changed` 정확 |

V1~V7 **1구역 스테이지 착수 전 필수 통과**. V8은 β 골격 동작만 확인.

---

## 6.5 구현 결과 요약 (2026-04-18)

- **HiddenRevealer**: 4 파일 생성, 4 조건(LIGHT_SENSOR/REFLECTION/PURIFICATION/SHADOW_COVER) 모두 구현. `SET_VISIBLE` 액션에 `process_mode=INHERIT` 복원 추가 (숨김 포탈 Area2D 재활성화).
- **LightSensor**: 3 파일 생성, ENVIRONMENT α validator 역할 병행. 1-3 반사 센서 / 1-4 숨김 포탈 센서 / 1-6 진입 센서 3종 데이터 리소스 배치.
- **EnvironmentStateRegistry**: 3 파일 골격 커밋 (1구역 미사용).
- **StateFlagPersistence**: Autoload `StateFlags` 등록, HiddenRevealer 세이브 복원과 연동.
- **Cover 확장**: `PlayerShadowDetectZone` (Area2D, layer=0/mask=2)을 `ShadowProjectionZone` 자식으로 추가 — SHADOW_COVER 조건 충족.
- **스테이지 데이터 및 씬**: 1-1~1-6 + 1-H 총 7개 `.tres` / `.tscn` / `.gd` 생성.

---

## 7. 결정 필요 사항

| # | 항목 | 제안 |
|---|---|---|
| L-1 | 렌즈 FocusZone의 collision_layer 승격 vs 별도 LightEmitterZone 추가 | (A) FocusZone에 layer=128 추가 — 가장 단순 |
| L-2 | 반사 바닥 REFLECTION 표현 방식 | 반사 바닥 위에 LightSensor 배치 + 반사 바닥에 `LightEmitterZone`(신규 Area2D)을 layer=128로 얹어 "반사광"을 표현 |
| L-3 | 1-6 ENVIRONMENT 잠금 LightSensor 물리 배치 | 1-5에 포탈 인접 배치 (포탈은 현재 스테이지에서 다음 스테이지 진입 판정) |
| R-1 | ShadowProjectionZone을 SHADOW_COVER 센서로 재사용 | HiddenRevealer가 Area2D body_entered에 직접 연결 + 플레이어 그룹 필터 (기존 계약 불변) |
| R-4 | LightSensor 복수 빔 입력 규칙 | OR (어느 하나라도 들어오면 ON) 기본. 다중 입력 AND 요구는 β로 커버 |
| R-6 | StateFlags Autoload 순서 | EventBus 직후, StageSystem 이전 |
| D | HiddenRevealerData.reveal_action 기본값 | SET_VISIBLE (회수 가능, 안전한 기본) |

---

## 8. 파일 생성/수정 영향

**신규**
- HiddenRevealer 4파일 (hidden_revealer.gd, HiddenRevealer.tscn, reveal_condition.gd, hidden_revealer_data.gd)
- LightSensor 3파일 (light_sensor.gd, LightSensor.tscn, light_sensor_data.gd)
- EnvironmentStateRegistry 3파일 (environment_state_registry.gd, combination_rule.gd, state_snapshot.gd)
- StateFlagPersistence 2파일 (state_flag_persistence.gd, flag_naming.gd)

**수정**
- `src/systems/event_bus/event_bus.gd` — 시그널 4종 추가
- `src/systems/stage/stage_lock_validator.gd` — ENVIRONMENT prefix 파싱
- `src/systems/stage/save_manager.gd` — StateFlags 직렬화 포함
- `project.godot` — StateFlags Autoload 추가
- 조건부: `Lens.tscn` / `ReflectiveFloor.tscn` — 빔 방출 영역 layer 조정
