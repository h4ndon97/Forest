# Phase 4-0 Tier 1 #1 — CombatSystem 리팩토링 상세 스펙

> 상위 로드맵: [`PHASE_4_0_ENGINE_HARDENING.md`](../PHASE_4_0_ENGINE_HARDENING.md) §4.1
> 설계 원천: [`COMBAT.md`](../COMBAT.md) §2 속성 피니시 · §11 강화 이동
> 착수 예정: Phase 4-0 **Week 1**
> 작성일: 2026-04-21
> 상태: **착수 전 상세 설계 확정본**

---

## 1. 목적·범위·완료 기준

### 1.1 목적

현재 전투 로직(공격 요청·데미지 계산·히트박스 생성·이펙트 발행)은 플레이어·적·보스 각 엔티티와 `player_combo.gd`, `player_skill.gd`, `attack_behavior_*.gd`, `base_enemy.gd` 등 **최소 6개 스크립트에 분산**되어 있다. `CombatSystem`은 실질적으로 리스폰·데미지 계산 유틸 역할만 담당 중이다.

이 Phase는 전투를 **요청자(Intent) / 허브(CombatSystem) / 수신자(damage_resolver)** 3계층으로 재편하여:

1. 엔티티는 "공격 의도(AttackSpec)"만 CombatSystem에 전달한다.
2. CombatSystem이 히트박스 생성·활성·이펙트·데미지 적용을 조율한다.
3. `.tres` 한 장만 추가해도 전투 파이프라인에 태울 수 있는 **API 경계**를 만든다 ([상위 로드맵 §2.2](../PHASE_4_0_ENGINE_HARDENING.md#L48) 성공 정의 1·4·5).

### 1.2 범위

#### 포함
- **신규 Resource 3종**: `AttackSpec` / `ProjectileSpec` / `AoeSpec`
- **신규 헬퍼 3종**: `hitbox_factory.gd` / `damage_resolver.gd` / `attack_requests.gd`
- **CombatSystem 확장 API**: `request_attack` / `request_projectile` / `request_aoe`
- **플레이어 2주체 전환**: `player_combo` + `player_skill` (이중 히트박스 해소)
- **적 behavior 3종 전환**: melee / ranged / projectile
- **보스 behavior 3종 전환**: melee_aoe (telegraph 흡수) / ranged_spread / root_summon
- **데미지 수신 경로 이동**: `base_enemy._on_hurtbox_area_entered` → `damage_resolver`
- **고아 시그널 3종 부활**: `hit_flash_requested` / `hitstop_requested` / `screen_flash_requested` ([이벤트 버스](../../src/systems/event_bus/event_bus.gd))

#### 비포함 (다른 Tier·Phase에서 처리)
- SkillExecutor 실행 파이프라인 (쿨다운·자원·입력 분기) — **#2**
- `SkillData.custom_script` 필드 추가 — **#2**
- 속성 피니시 Strategy 모듈 분리 (`finish_light/shadow/hybrid/neutral.gd`) — **#3**
- `get_combo_damage()` 매 프레임 Getter 캐싱 — **#6** (본 Phase는 **경계만 확정**, 구현은 #6)
- 신규 아트·사운드·UI

### 1.3 완료 기준

- [ ] `player_combo.gd`에서 Area2D 직접 생성 코드 제거 → `CombatSystem.request_attack(spec)` 위임
- [ ] `player_skill.gd`에서 별도 SkillHitbox 제거 → `request_attack` 통합 (이중 히트박스 해소)
- [ ] 적 `attack_behavior_melee/ranged`가 `request_attack` / `request_projectile` 경유
- [ ] 보스 `attack_behavior_boss_melee_aoe`의 telegraph 2단계 상태머신을 `AttackSpec.telegraph_duration` 필드로 흡수
- [ ] 투사체 생성(`enemy_projectile.tscn` 인스턴싱)이 `CombatSystem.request_projectile` 경유
- [ ] `base_enemy._on_hurtbox_area_entered`의 데미지·이펙트 발동 로직이 `damage_resolver`로 이동
- [ ] `hit_flash_requested` / `hitstop_requested` / `screen_flash_requested` 3개 고아 시그널이 `damage_resolver`에서 emit되고 `EffectsSystem`이 수신
- [ ] `player_combo.gd` LOC 감소 (현재 193줄 → 목표 ≤ 175줄, 약 10% 감소)
  - 본 Phase 단독 한계. 이중 히트박스 효과는 Step 2.5(player_skill 45%↓)에서 발생.
  - 추가 압축은 Step 2.5에서 두 호출처 공통 빌더로 자연 추출 시 가능.
- [ ] `combat_system.gd` LOC **300줄 이하 유지**
- [ ] Godot 헤드리스 로드 테스트 **ERROR 0 / WARNING 0**
- [ ] 1-1 ~ 1-6 + 1-H + 1-B 스테이지 회귀 플레이 통과 (콤보·스킬·적·보스 모든 히트 정상)
- [ ] `gdlint` / `gdformat --check` 수정 파일 전체 clean

---

## 2. 현재 전투 로직 인벤토리

### 2.1 플레이어 — 콤보 + 스킬 (**이중 히트박스** 문제)

#### `src/entities/player/player_combo.gd` (193줄)
| 영역 | 라인 | 역할 |
|---|---|---|
| 상태머신 | 40-51 | IDLE/ATTACKING/WINDOW + 버퍼 입력 |
| 데미지 메타 설정 | 71-78 | `hit_number` / `damage` / `is_finish` / `finish_attribute` |
| 데미지 계산 요청 | 74 | `CombatSystem.get_combo_damage(_combo_count)` |
| 히트박스 활성화 | 79-81 | `monitoring = true` (enemies_active 조건) |
| 피니시 속성 해결 | 134-137 | `SkillSystem.get_finish_attribute()` 다수결 |
| **Area2D 생성** | **153-169** | `_create_attack_hitbox()` — 리팩토링 주요 타겟 |
| 타이머 3종 | 172-192 | hit/window/reset |

#### `src/entities/player/player_skill.gd` (164줄) — **별도 히트박스**
| 영역 | 라인 | 역할 |
|---|---|---|
| 입력 → 슬롯 | 34-44 | `_try_use_skill(slot_index)` 호출 |
| 쿨다운/자원 체크 | 50-64 | `TimeSystem.get_resource_data()` + `time_resource_consume_flat_requested` |
| 히트박스 메타 설정 | 77-81 | `damage` / `is_skill` / `skill_path` (is_finish=false 고정) |
| 형상 전환 | 83-96 | `effect_type`별 Rectangle/Circle 교체 |
| 히트박스 활성화 | 99-105 | `skill.active_duration` 동안 ON |
| **Area2D 생성** | **128-143** | `_create_hitbox()` — **별도 SkillHitbox** |

**문제점**: 두 컴포넌트가 각자 Area2D를 생성·관리 중. `_on_hurtbox_area_entered`는 둘 다 "player_attack" 그룹으로만 식별하므로 데미지 메타 필드 계약이 **암묵적으로 2개 코드에 걸쳐 합의**되어 있음. 신규 공격 타입 추가 시 3번째 히트박스가 생길 위험.

### 2.2 적 — `attack_behavior` 구조 (**부분 완성**)

#### `src/entities/enemies/base/behaviors/attack_behavior_base.gd` (38줄)
- 훅 3종: `on_attack_enter()` / `on_attack_exit()` / `on_state_update(delta)`
- 히트박스는 **이미 씬에 배치**된 것을 `setup(..., hitbox)`로 주입받음

#### `src/entities/enemies/base/behaviors/attack_behavior_melee.gd` (52줄)
| 라인 | 역할 |
|---|---|
| 12-17 `_on_setup()` | `HitboxShape` 조회 + `_apply_shape()` |
| 20-24 `on_attack_enter()` | `monitoring = true` (deferred) |
| 27-30 `on_attack_exit()` | `monitoring = false` |
| 33-42 `on_state_update()` | `hitbox_active_duration` 만료 시 자동 OFF |
| 45-51 `_apply_shape()` | `stats_data.hitbox_size/offset` 반영 |

**평가**: Strategy 패턴이 이미 정립됨. 리팩토링은 **`monitoring` 제어 → `CombatSystem.request_attack` 위임**만 교체하면 됨. 전면 재작성 불필요.

#### 적 투사체 — `src/entities/enemies/projectile/enemy_projectile.gd` (57줄)
| 라인 | 역할 |
|---|---|
| 14-18 `setup()` | direction/speed/damage/lifetime 주입 + `set_meta("damage")` |
| 22 `_ready()` | `"enemy_projectile"` 그룹 등록 |
| 41-42 `_physics_process()` | 직선 이동 |
| 45-46 `_on_lifetime_timeout()` | 수명 만료 소멸 |
| 49-51 `_on_body_entered()` | 벽 접촉 소멸 |

**평가**: 투사체 인스턴스 자체는 `ProjectileSpec`로 파라미터 주입할 수 있게 얇은 어댑터만 추가하면 됨. 씬 구조(Visual 자식 노드 등)는 유지.

### 2.3 보스 — `phase_controller` + **telegraph 2단계**

#### `src/entities/bosses/base/behaviors/attack_behavior_boss_melee_aoe.gd` (111줄)
| 라인 | 역할 |
|---|---|
| 23-37 `setup_with_pattern()` | `BossPhasePattern` 에서 `telegraph_durations[idx]` + `hitbox_active_duration` 주입 |
| 44-51 `on_attack_enter()` | `_phase_state = 1` (telegraph), 예고선 visible |
| 53-60 `on_attack_exit()` | 상태 0 복귀, 히트박스/예고 visible off |
| **63-77** `on_state_update()` | **telegraph→active 2단계 자동 전이** |
| 67-71 | telegraph 만료 → `_phase_state = 2` + `monitoring = true` |
| 76-77 | active 만료 → `on_attack_exit()` |
| 80-88 `_apply_shape()` | pattern.hitbox_size/offset |
| 91-110 `_create_fallback_visuals()` | 예고선/활성 ColorRect 폴백 |

**핵심 발견**: 이 telegraph 2단계 상태머신은 **AttackSpec에 `telegraph_duration` 필드**만 추가하면 `CombatSystem` 내부 `attack_requests.gd`가 흡수 가능. 예고선 시각화는 별도 컴포넌트로 유지 가능(이번 Phase 비포함).

### 2.4 데미지 수신·이펙트 체인 — [`base_enemy.gd:244-267`](../../src/entities/enemies/base/base_enemy.gd#L244-L267)

```gdscript
func _on_hurtbox_area_entered(area: Area2D) -> void:
    if area.is_in_group("player_attack"):
        var damage: float = area.get_meta("damage", 0.0)
        var is_finish: bool = area.get_meta("is_finish", false)
        var attribute: String = area.get_meta("finish_attribute", "")
        var flash_color: Color = Color(0.0, 0.0, 0.0, 0.0)
        if is_finish and attribute != "":
            flash_color = EffectsSystem.get_finish_color(attribute)
        feedback_comp.play_hit_flash(flash_color)                  # ← EffectsSystem 직접 호출
        if is_finish:
            EffectsSystem.request_shake(EffectsSystem.PRESET_FINISH)
            EffectsSystem.request_hitstop(EffectsSystem.PRESET_FINISH)
        else:
            EffectsSystem.request_shake(EffectsSystem.PRESET_LIGHT)
            EffectsSystem.request_hitstop(EffectsSystem.PRESET_HIT)
        var category: StringName = EffectsSystem.resolve_enemy_category(...)
        EffectsSystem.request_hit_particle(...)
        take_damage(damage)                                        # ← 엔티티 체력 감소
        _spawn_damage_number(damage, is_finish, attribute)         # ← 데미지 넘버
        EventBus.damage_dealt.emit(enemy_id, damage)               # ← 이벤트 전파
```

**관찰**:
- 이 24줄이 "히트 감지 + 이펙트 6종 발동 + 데미지 적용 + 이벤트 전파"를 **모두** 수행
- `EffectsSystem` 직접 호출 5건, `feedback_comp` 직접 호출 1건
- 같은 로직이 [`base_boss.gd`](../../src/entities/bosses/base/base_boss.gd)에도 유사 형태로 중복 존재 (확인 필요)
- 이 로직을 `damage_resolver`로 이동하면서 **EffectsSystem 직접 호출 → EventBus 시그널 emit**으로 전환하면 고아 시그널 3개가 자연 부활

### 2.5 데미지 계산 병목 — [`combat_system.gd:41-45`](../../src/systems/combat/combat_system.gd#L41-L45)

```gdscript
func get_combo_damage(hit_number: int) -> float:
    var base: float = CombatCalculatorScript.calculate_hit_damage(hit_number, _config)
    base += GrowthSystem.get_attack_bonus()
    base += InventorySystem.get_attack_bonus()
    return CombatCalculatorScript.calculate_final_damage(base, _config.finish_attribute)
```

- 호출처: [`player_combo.gd:74`](../../src/entities/player/player_combo.gd#L74) — 매 타마다 호출 (4타 콤보 = 4회)
- 문제: 매 호출이 `GrowthSystem`·`InventorySystem` Autoload getter 트리거

**본 Phase에서의 처리 방침**:
- **#6과 분리** — 구현은 Tier 3 #6에서
- 본 Phase는 **API 경계만 확정**: `AttackSpec.damage` 필드가 요청자 시점에 결정된 값을 담도록 계약. 이후 #6에서 `CombatSystem` 내부 캐시가 붙어도 외부 API는 불변.

---

## 3. 목표 아키텍처

### 3.1 Resource 스키마 (**Step 1에서 `damage_resolver` 수요까지 미리 반영**)

#### `src/systems/combat/attack_spec.gd` (신규, `class_name AttackSpec`)

```gdscript
class_name AttackSpec extends Resource

# --- 요청자 식별 ---
@export var attacker: Node                         # 히트박스 소유자(방향 기준 + 자기 피격 제외)
@export var source_group: String = "player_attack" # 히트박스에 추가할 그룹

# --- 형상 ---
@export var hitbox_size: Vector2 = Vector2(36, 24)
@export var hitbox_offset: Vector2 = Vector2(24, -14)
@export var shape_type: String = "rect"            # "rect" | "circle"
@export var circle_radius: float = 0.0             # shape_type == "circle"일 때만

# --- 타이밍 ---
@export var telegraph_duration: float = 0.0        # 예고선 단계 (보스 흡수용, 0이면 즉시 active)
@export var active_duration: float = 0.3           # 히트박스 ON 유지 시간

# --- 데미지/판정 (damage_resolver가 읽을 필드 — Step 6까지 변경 금지) ---
@export var damage: float = 0.0
@export var attribute: String = "none"             # "light"|"shadow"|"hybrid"|"neutral"|"none"
@export var is_finish: bool = false
@export var piercing: bool = false                 # 다수 적 관통 허용 (light 피니시)
@export var multi_hit_count: int = 1               # 다단히트 횟수 (shadow 피니시)
@export var multi_hit_interval: float = 0.0        # 다단히트 간격(초)
@export var knockback: float = 0.0                 # 넉백 강도 (neutral 피니시용 강화)

# --- 메타 (스킬 등 추적용) ---
@export var tags: PackedStringArray = []           # 예: ["skill"], ["combo"], ["boss_p1"]
@export var skill_id: String = ""                  # effect_type="skill" 일 때만 사용
```

**설계 노트**:
- 기존 `player_combo`가 `set_meta`로 설정하던 4개 필드(`damage`·`is_finish`·`finish_attribute`·`hit_number`)가 `damage`·`is_finish`·`attribute`·`tags`로 1:1 대응
- `player_skill`의 `is_skill`/`skill_path` 메타는 `tags = ["skill"]` + `skill_id`로 대체
- `piercing`·`multi_hit_count`·`multi_hit_interval`·`knockback`은 **#3 속성 피니시에서 사용 예정** — Step 1에 미리 선언해 두되 Step 6 이후 구현
- `telegraph_duration`은 **보스 흡수 전용** — 플레이어/일반 적은 0

#### `src/systems/combat/projectile_spec.gd` (신규)

```gdscript
class_name ProjectileSpec extends Resource

@export var attacker: Node
@export var source_group: String = "enemy_projectile"
@export var scene: PackedScene                      # enemy_projectile.tscn 등
@export var spawn_position: Vector2 = Vector2.ZERO
@export var direction: Vector2 = Vector2.RIGHT
@export var speed: float = 180.0
@export var lifetime: float = 3.0
@export var damage: float = 0.0
@export var attribute: String = "none"
@export var tags: PackedStringArray = []
```

#### `src/systems/combat/aoe_spec.gd` (신규, **스켈레톤만**)

```gdscript
class_name AoeSpec extends Resource

@export var attacker: Node
@export var source_group: String = "player_attack"
@export var center: Vector2 = Vector2.ZERO
@export var radius: float = 40.0
@export var telegraph_duration: float = 0.0
@export var active_duration: float = 0.2
@export var damage: float = 0.0
@export var attribute: String = "none"
@export var tags: PackedStringArray = []
```

**주의**: AoE는 현 시점에 본격 사용처 없음 (player_skill의 `aoe` effect_type은 Circle 히트박스로 구현됨). 본 Phase에서는 **스키마만 선언** + `request_aoe()` stub 함수 제공. 실제 구현 및 사용은 #2 SkillExec에서.

### 3.2 `CombatSystem` 확장 API

```gdscript
# src/systems/combat/combat_system.gd (확장)

# --- 신규 Public API ---
func request_attack(spec: AttackSpec) -> Node2D:
    # 1. hitbox_factory로 Area2D 생성 또는 재사용
    # 2. attack_requests에 등록 (telegraph/active 생명주기 관리)
    # 3. 생성된 Area2D 반환 (요청자가 이동/회전에 쓰려면 참조 필요할 수 있음)
    ...

func request_projectile(spec: ProjectileSpec) -> Node2D:
    # 1. spec.scene instantiate
    # 2. setup(direction, speed, damage, lifetime) 호출
    # 3. 스폰 부모에 add_child
    ...

func request_aoe(spec: AoeSpec) -> void:
    # Step 1에서는 stub(미사용). #2 또는 #3 단계에서 본격 구현.
    push_warning("request_aoe not yet implemented")
```

**기존 API는 그대로 유지** (`get_combo_damage`·`set_spawn_point`·`get_spawn_point`).

### 3.3 파일 트리

```
src/systems/combat/
├── combat_system.gd            (기존, 확장 API 추가 — 300줄 이내 유지)
├── combat_calculator.gd        (기존, 변경 없음)
├── combat_config_data.gd       (기존, 변경 없음)
├── attack_spec.gd              (신규, Resource)
├── projectile_spec.gd          (신규, Resource)
├── aoe_spec.gd                 (신규, Resource, stub)
├── hitbox_factory.gd           (신규, Area2D 생성·풀링 전담)
├── attack_requests.gd          (신규, telegraph/active 상태머신 + 동시 요청 큐)
└── damage_resolver.gd          (신규, hurtbox 접촉 시 데미지·이펙트·이벤트 분배)
```

**scene 파일 변경 없음**. 모든 Area2D는 CombatSystem(Autoload)이 런타임에 부착/해제.

### 3.4 EventBus 시그널 부활 계획

현 상태 ([`event_bus.gd:161-164`](../../src/systems/event_bus/event_bus.gd#L161-L164)):
- `hit_flash_requested(target, color, duration)` — **고아** (emit 0)
- `hitstop_requested(duration, scale)` — **고아** (emit 0)
- `screen_flash_requested(color, duration)` — **고아** (emit 0)
- `screen_shake_requested(trauma)` — 유일하게 emit/connect 됨

Step 6에서 전환:

| 시점 | 호출 방식 |
|---|---|
| Before (현재) | `base_enemy` → `EffectsSystem.request_hit_flash/shake/hitstop` 직접 |
| After | `damage_resolver` → `EventBus.hit_flash_requested.emit(...)` → `EffectsSystem` 수신 |

**주의**: 이 전환은 **API 방향 반전** (push → pub/sub). 회귀 위험은 "emit했는데 connect 누락" 한 종류. Step 6에서 connect 먼저 → emit으로 교체 순서 준수.

`screen_shake_requested`는 이미 이 방식이므로 **참고 구현**으로 활용.

---

## 4. API 변경 Before / After

### 4.1 [`player_combo.gd`](../../src/entities/player/player_combo.gd)

#### Before (현재, 라인 64-81)
```gdscript
func _start_hit(hit_number: int) -> void:
    _combo_count = hit_number
    ...
    var facing: int = _movement.facing_direction
    _attack_shape.position.x = absf(_config.hitbox_offset.x) * facing
    _attack_hitbox.set_meta("hit_number", _combo_count)
    var damage: float = CombatSystem.get_combo_damage(_combo_count)
    _attack_hitbox.set_meta("damage", damage)
    var is_finish: bool = _combo_count >= _config.combo_max_hits
    _attack_hitbox.set_meta("is_finish", is_finish)
    _attack_hitbox.set_meta("finish_attribute", _resolve_finish_attribute() if is_finish else "")
    if _enemies_active:
        _attack_hitbox.monitoring = true
        _attack_hitbox.monitorable = true
    ...
```
+ `_create_attack_hitbox()` (라인 153-169)

#### After
```gdscript
func _start_hit(hit_number: int) -> void:
    _combo_count = hit_number
    ...
    var spec := AttackSpec.new()
    spec.attacker = _parent
    spec.source_group = "player_attack"
    spec.hitbox_size = _config.hitbox_size
    spec.hitbox_offset = Vector2(
        absf(_config.hitbox_offset.x) * _movement.facing_direction,
        _config.hitbox_offset.y,
    )
    spec.active_duration = _config.hit_duration
    spec.damage = CombatSystem.get_combo_damage(_combo_count)
    spec.is_finish = _combo_count >= _config.combo_max_hits
    spec.attribute = _resolve_finish_attribute() if spec.is_finish else "none"
    spec.tags = PackedStringArray(["combo", "hit_%d" % _combo_count])
    if _enemies_active:
        CombatSystem.request_attack(spec)
    ...
```

- `_create_attack_hitbox()` **제거** (Area2D 생성은 `hitbox_factory` 소관)
- `_attack_hitbox` 멤버 변수 **제거**
- `_hit_timer` 유지 (콤보 상태머신 타이밍과 히트박스 생명주기는 **여전히 분리** — 상태 전이용)

**예상 LOC**: 193 → ~170 (약 10% 감소). 30%↓ 가정은 spec 조립 14줄을 누락한 추정이었음. 추가 감소는 Step 2.5에서 player_skill과 공통 빌더 추출 시 자연 발생.

### 4.2 [`player_skill.gd`](../../src/entities/player/player_skill.gd)

#### Before (현재, 라인 69-105)
```gdscript
# 히트박스 설정 및 활성화
_configure_hitbox(skill)
_activate_hitbox(skill)
_play_skill_animation(skill)

func _configure_hitbox(skill: SkillData) -> void:
    _skill_hitbox.set_meta("damage", skill.damage)
    _skill_hitbox.set_meta("is_finish", false)
    _skill_hitbox.set_meta("is_skill", true)
    _skill_hitbox.set_meta("skill_path", skill.path)

    match skill.effect_type:
        "aoe":
            var circle := CircleShape2D.new()
            circle.radius = skill.aoe_radius
            ...
        _:
            var rect := RectangleShape2D.new()
            ...
```
+ `_create_hitbox()` (라인 128-143, **별도 SkillHitbox**)

#### After
```gdscript
func _try_use_skill(slot_index: int) -> void:
    ...
    var spec := AttackSpec.new()
    spec.attacker = _parent
    spec.source_group = "player_attack"
    spec.damage = skill.damage
    spec.is_finish = false
    spec.attribute = "none"  # 스킬 속성 체계는 #2/#3에서
    spec.tags = PackedStringArray(["skill"])
    spec.skill_id = skill.id
    spec.active_duration = skill.active_duration

    match skill.effect_type:
        "aoe":
            spec.shape_type = "circle"
            spec.circle_radius = skill.aoe_radius
        _:
            spec.shape_type = "rect"
            spec.hitbox_size = skill.hitbox_size
            spec.hitbox_offset = Vector2(
                absf(skill.hitbox_offset.x) * _movement.facing_direction,
                skill.hitbox_offset.y,
            )

    CombatSystem.request_attack(spec)
    _play_skill_animation(skill)
```

- `_create_hitbox()`·`_configure_hitbox()`·`_activate_hitbox()`·`_deactivate_hitbox()` **모두 제거**
- `_skill_hitbox`·`_skill_shape`·`_active_timer`·`_is_active` 멤버 전부 제거
- 쿨다운/자원 소비 로직은 유지 (**#2에서 SkillExecutor로 이동 예정**)

**예상 LOC**: 164 → ~90 (45% 감소)

**이중 히트박스 해소 검증**: `player_combo` + `player_skill` 양쪽 모두 `CombatSystem.request_attack` 1개 경로로 수렴.

### 4.3 [`attack_behavior_melee.gd`](../../src/entities/enemies/base/behaviors/attack_behavior_melee.gd) / `attack_behavior_ranged.gd`

#### Before (melee, 라인 20-42)
```gdscript
func on_attack_enter() -> void:
    _is_active = true
    _active_timer = 0.0
    _hitbox.set_deferred("monitoring", true)
    _hitbox.set_deferred("monitorable", true)

func on_state_update(delta: float) -> void:
    ...
    if _active_timer >= _stats_data.hitbox_active_duration:
        _hitbox.set_deferred("monitoring", false)
        ...
```

#### After
```gdscript
func on_attack_enter() -> void:
    var spec := AttackSpec.new()
    spec.attacker = _enemy_root
    spec.source_group = "enemy_attack"
    spec.hitbox_size = _stats_data.hitbox_size
    spec.hitbox_offset = _stats_data.hitbox_offset
    spec.active_duration = _stats_data.hitbox_active_duration
    spec.damage = _stats_data.attack_damage
    CombatSystem.request_attack(spec)

func on_state_update(delta: float) -> void:
    pass  # 타이밍은 CombatSystem.attack_requests가 관리
```

**중요**: 씬에 이미 배치된 `Hitbox` Area2D는 **제거 가능** (CombatSystem이 런타임 생성). 단, 적 씬 수정 범위를 최소화하려면 **기존 씬 Hitbox를 `hitbox_factory`에 재사용 풀로 등록**하는 옵션도 고려 — Step 3 진행 중 결정.

### 4.4 [`attack_behavior_boss_melee_aoe.gd`](../../src/entities/bosses/base/behaviors/attack_behavior_boss_melee_aoe.gd) (telegraph 흡수)

#### Before (라인 44-77, 34줄의 2단계 상태머신)
```gdscript
var _phase_state: int = 0  # 0=idle, 1=telegraph, 2=active
var _phase_timer: float = 0.0
...
func on_state_update(delta: float) -> void:
    if _phase_state == 1 and _phase_timer >= _telegraph_duration:
        _phase_state = 2
        _hitbox.set_deferred("monitoring", true)
    elif _phase_state == 2 and _phase_timer >= _active_duration:
        on_attack_exit()
```

#### After
```gdscript
func on_attack_enter() -> void:
    var spec := AttackSpec.new()
    spec.attacker = _enemy_root
    spec.source_group = "boss_attack"
    spec.hitbox_size = _pattern.hitbox_size
    spec.hitbox_offset = _pattern.hitbox_offset
    spec.telegraph_duration = _telegraph_duration
    spec.active_duration = _active_duration
    spec.damage = _pattern.damage  # 또는 stats_data.attack_damage
    spec.tags = PackedStringArray(["boss", "p1_melee_aoe"])
    _current_attack_node = CombatSystem.request_attack(spec)
    _show_telegraph_visuals()  # ColorRect 표시는 유지 (별도)

func on_attack_exit() -> void:
    _hide_telegraph_visuals()
```

- `_phase_state`·`_phase_timer`·`on_state_update`의 상태머신 **제거**
- 예고선/활성 ColorRect 토글은 유지 (시각 컴포넌트와 전투 판정 분리)
- **선택**: ColorRect 가시성을 `CombatSystem`이 emit하는 시그널(`attack_telegraph_started/active/ended`) 기반으로 전환 — Step 5에서 판단

### 4.5 [`base_enemy._on_hurtbox_area_entered`](../../src/entities/enemies/base/base_enemy.gd#L244-L267) → `damage_resolver`

#### Before (24줄, 2.4에 전체 인용)
- 히트 감지 + 메타 읽기 + 이펙트 6종 직접 호출 + `take_damage` + 데미지 넘버 + `damage_dealt` emit

#### After — `damage_resolver.gd` (신규)
```gdscript
extends RefCounted
class_name DamageResolver

# CombatSystem이 단일 인스턴스 보유
static func resolve_hit(target: Node, attacker_area: Area2D) -> void:
    if not attacker_area.has_meta("attack_spec"):
        return  # legacy 또는 미등록 공격
    var spec: AttackSpec = attacker_area.get_meta("attack_spec")

    # 이펙트 발행 (고아 시그널 부활)
    var flash_color := Color(0.0, 0.0, 0.0, 0.0)
    if spec.is_finish and spec.attribute != "none":
        flash_color = EffectsSystem.get_finish_color(spec.attribute)
    EventBus.hit_flash_requested.emit(target, flash_color, 0.08)
    EventBus.hitstop_requested.emit(
        EffectsSystem.PRESET_FINISH if spec.is_finish else EffectsSystem.PRESET_HIT
    )
    # screen_shake는 기존 경로 유지 (EffectsSystem.request_shake)

    # 파티클 (일단 직접 호출 유지)
    EffectsSystem.request_hit_particle(...)

    # 데미지 적용
    if target.has_method("take_damage"):
        target.take_damage(spec.damage)

    # 데미지 넘버
    if target.has_method("spawn_damage_number"):
        target.spawn_damage_number(spec.damage, spec.is_finish, spec.attribute)

    # 이벤트 전파
    if target.has_method("get_entity_id"):
        EventBus.damage_dealt.emit(target.get_entity_id(), spec.damage)
```

`base_enemy._on_hurtbox_area_entered`는 **한 줄**로 축소:
```gdscript
func _on_hurtbox_area_entered(area: Area2D) -> void:
    if area.is_in_group("player_attack"):
        DamageResolver.resolve_hit(self, area)
```

**`hit_flash_requested` 수신자 생성**:
```gdscript
# src/systems/effects/effects_system.gd _ready()
EventBus.hit_flash_requested.connect(_on_hit_flash_requested)
EventBus.hitstop_requested.connect(_on_hitstop_requested)
# screen_flash_requested는 사용처 미확정 — Step 6에서 결정 또는 #5로 연기
```

---

## 5. 단계별 마이그레이션 커밋 계획

**원칙**: 각 Step은 **독립 회귀 테스트 가능한 커밋** 단위. Step 1은 "미사용 코드 추가"로 회귀 위험 0. Step 6만 "동작 방식 변경"으로 리스크 집중.

### Step 1 — AttackSpec + hitbox_factory + attack_requests 신설 (**미사용**)

**작업**:
- `attack_spec.gd` / `projectile_spec.gd` / `aoe_spec.gd` 작성 (3.1 스키마 그대로)
- `hitbox_factory.gd` — `create(spec: AttackSpec) -> Area2D` 단일 API
- `attack_requests.gd` — telegraph/active 생명주기 타이머 관리
- `damage_resolver.gd` — 스크립트만 작성, 아직 아무도 호출 안 함
- `combat_system.gd`에 `request_attack`·`request_projectile` 추가 (내부 로직 완성, 호출자 없음)

**검증**:
- Godot 헤드리스 로드 (ERROR 0)
- 기존 플레이 회귀 없음 (미사용 코드만 추가)

**커밋**: `Phase 4-0 #1 Step 1: CombatSystem 확장 API 신설 (AttackSpec/hitbox_factory)`

**LOC 예산**: +300줄 (combat_system.gd 여전히 300줄 이내 유지)

### Step 2 — `player_combo` 전환

**작업**: [4.1](#41-player_combogd) Before → After

**검증**:
- 1-1 회귀 플레이 — 4타 콤보 히트·피니시 색상·데미지 숫자 정상
- 적 `_on_hurtbox_area_entered`가 여전히 `set_meta`로 메타 읽음 (아직 작동해야 함)
- **호환성 트릭**: `hitbox_factory`가 생성한 Area2D에 `spec` 자체를 메타로 달되(`set_meta("attack_spec", spec)`), **동시에 레거시 메타 필드도 set** (`set_meta("damage", spec.damage)` 등) — Step 6에서 레거시 메타 제거

**커밋**: `Phase 4-0 #1 Step 2: player_combo → request_attack 전환`

### Step 2.5 — `player_skill` 전환 (**이중 히트박스 해소**)

**작업**: [4.2](#42-player_skillgd) Before → After

**검증**:
- `light_slash`·`shadow_strike` 슬롯 장착 후 발동 → 데미지 정상
- 쿨다운·자원 소모 정상 (로직은 그대로)
- `effect_type = "aoe"` 경로(Circle 형상) 정상 — `hitbox_factory`가 `shape_type == "circle"` 분기 지원해야 함

**커밋**: `Phase 4-0 #1 Step 2.5: player_skill 이중 히트박스 제거 → request_attack 통합`

### Step 3 — 적 `attack_behavior_melee/ranged` 전환

**작업**: [4.3](#43-attack_behavior_meleegd--attack_behavior_rangedgd) Before → After

**세부**:
- `attack_behavior_melee` — `monitoring` 제어 코드 제거, `request_attack` 호출
- `attack_behavior_ranged` — `request_projectile`로 교체
- 기존 씬의 Hitbox Area2D 처리 — 2옵션 중 결정:
  - (A) 씬에서 제거하고 CombatSystem이 동적 생성
  - (B) 씬 Hitbox를 `hitbox_factory`에 풀로 등록하여 재사용
- 권장: (A) — 씬 간 일관성. 성능 이슈 발견 시 #6에서 풀링 도입.

**검증**:
- 1-1 (늑대·토끼), 1-2~1-3 (새로운 적 유형이 있다면) 회귀 플레이
- 적 공격이 플레이어에게 데미지 주는지 확인

**커밋**: `Phase 4-0 #1 Step 3: 적 근접/원거리 attack_behavior 전환`

### Step 4 — 적 투사체 (`enemy_projectile`) 전환

**작업**:
- `attack_behavior_ranged`가 투사체 인스턴싱하던 부분 → `CombatSystem.request_projectile(spec)`
- `enemy_projectile.gd`는 그대로 유지 (인터페이스만 `setup()` 호출 주체가 CombatSystem으로 바뀜)

**검증**:
- 1-1~1-3 원거리 적 (있는 경우) 투사체 정상 발사·명중·소멸

**커밋**: `Phase 4-0 #1 Step 4: 적 투사체 생성 경로 통합`

### Step 5 — 보스 `attack_behavior_boss_*` 전환 (**telegraph 흡수**)

**작업**: [4.4](#44-attack_behavior_boss_melee_aoegd-telegraph-흡수) Before → After

**세부**:
- `melee_aoe` — telegraph 2단계 상태머신 제거, `AttackSpec.telegraph_duration` 활용
- `ranged_spread` — 분산 탄막은 `request_projectile`을 반복 호출
- `root_summon` — 소환물이 독립 엔티티이면 `request_attack` 아님 (스킵 또는 별도 경로)
- ColorRect 예고선 가시성: `attack_requests`가 상태 전이 시 callback 또는 시그널로 통지

**검증**:
- 1-B (1구역 보스) 전 페이즈 회귀 플레이 — telegraph 타이밍·active 타이밍·히트 판정

**커밋**: `Phase 4-0 #1 Step 5: 보스 behavior → request_attack 전환 + telegraph 흡수`

### Step 6 — `damage_resolver` 이동 + 고아 시그널 부활 (**본 Phase 최고 리스크**)

**작업**: [4.5](#45-base_enemy_on_hurtbox_area_entered--damage_resolver) Before → After

**세부 순서** (emit→connect 역전 방지):
1. `EffectsSystem._ready()`에서 `hit_flash_requested`·`hitstop_requested` **connect 먼저**
2. 새 `_on_hit_flash_requested`·`_on_hitstop_requested` 핸들러가 기존 `request_hit_flash`·`request_hitstop` 내부 로직을 호출하도록 연결 (이펙트 코드 중복 없이)
3. `damage_resolver.resolve_hit()` 본체 작성 — **EventBus emit 사용**
4. `base_enemy._on_hurtbox_area_entered` 한 줄로 축소 → `DamageResolver.resolve_hit(self, area)`
5. `base_boss` 동일 적용 (동일 로직 존재 확인 필요)
6. Step 2~5에서 달아둔 **레거시 메타 필드 set 제거** — `spec` 메타만 남김
7. `screen_flash_requested` 사용처 처리:
   - Phase 4-0 **#3 속성 피니시**(light 속성 화면 플래시)에서 자연 사용 — 이번 Step은 **emit 주체 없음 상태로 종료** 허용
   - 또는 `EventBus.hit_flash_requested`의 보스급 확장 케이스로 한 번 써보기

**검증**:
- **전 스테이지 회귀**: 1-1·1-2·1-3·1-4·1-5·1-6·1-H·1-B
- 콤보 4타 색상 플래시·힛스톱·카메라 쉐이크 **육안 확인**
- `damage_dealt` 시그널 수신처(HUD 데미지 넘버 등) 정상 작동
- gdlint / gdformat clean

**커밋**: `Phase 4-0 #1 Step 6: damage_resolver 이동 + 고아 시그널 3종 부활`

---

## 6. 검증 체크리스트

### 6.1 자동 검증 (매 Step 필수)

- [ ] `gdlint` 수정 파일 clean
- [ ] `gdformat --check` 수정 파일 clean
- [ ] Godot 헤드리스 로드: `godot --headless --path "c:/_H4ndon/Forest" --quit` → ERROR 0 / WARNING 0
- [ ] 수정한 스크립트 300줄 이하

### 6.2 회귀 플레이 시나리오 (Step 2 이후 매 Step)

| 시나리오 | 확인 항목 | Step |
|---|---|---|
| 1-1 콤보 4타 | 1·2·3타 기본 데미지, 4타 피니시 색상, 데미지 숫자 | S2~ |
| 1-1 스킬 발동 | 쿨다운·자원 소모·히트박스 1개만 존재 | S2.5~ |
| 1-1 적 근접 공격 | 적이 플레이어 피격, 피격 후 무적 | S3~ |
| 1-3 원거리 적 (있으면) | 투사체 발사·명중·소멸 | S4~ |
| 1-B 보스 P1 | 예고선→히트박스 타이밍 일치, 데미지 정상 | S5~ |
| 1-B 보스 P2/P3 | 다른 공격 패턴 모두 정상 | S5~ |
| 전 스테이지 | 화면 쉐이크·힛스톱·피격 파티클·색상 플래시 | S6 |

### 6.3 구조 목표

| 파일 | 현재 | 목표 | Step |
|---|---|---|---|
| `player_combo.gd` | 193줄 | ≤ 175줄 (약 10%↓, 단독 한계) | S2 |
| `player_skill.gd` | 164줄 | ≤ 90줄 (45%↓) | S2.5 |
| `combat_system.gd` | 86줄 | ≤ 300줄 (확장 후) | S1 |
| `attack_behavior_boss_melee_aoe.gd` | 111줄 | ≤ 60줄 (telegraph 흡수) | S5 |
| `base_enemy._on_hurtbox_area_entered` | 24줄 | 3줄 | S6 |

### 6.4 시그널 커버리지 (Step 6 후)

- [ ] `hit_flash_requested` — emit ≥ 1 (damage_resolver), connect ≥ 1 (EffectsSystem)
- [ ] `hitstop_requested` — emit ≥ 1, connect ≥ 1
- [ ] `screen_flash_requested` — 상태 확정 (사용 or 예약 주석)
- [ ] `damage_dealt` — emit 주체 `damage_resolver`로 이전 완료

---

## 7. 미결 사항

본 Phase 진행 중 결정 — 발견 즉시 본 문서에 기록.

- [ ] `attack_requests`가 동시에 활성화 가능한 공격 수 상한 (현재 무제한 가정)
- [ ] 히트박스 풀링 도입 여부 (Step 3 성능 측정 후 #6으로 이전 또는 본 Phase 내 처리)
- [ ] 적 씬의 기존 `Hitbox` Area2D 처리 — 제거 vs 풀로 재사용 (Step 3 착수 시 확정)
- [ ] 보스 ColorRect 예고선 가시성 토글 방식 — 시그널 vs 콜백 (Step 5)
- [ ] `screen_flash_requested` 실제 사용처 — #3 속성 피니시로 이전 또는 별도 커밋
- [ ] `damage_dealt` 페이로드 확장 여부 — 현재 `(target_id, amount)` → `(target_id, amount, spec_tags)` 확장이 HUD/UI에 유용한가 (EventBus 하위호환 영향 검토 필요)
- [ ] `attacker == target` 자기 피격 제외 로직 위치 — `damage_resolver` vs `hitbox_factory` collision_mask

---

## 8. 관련 문서

### 상위
- [`PHASE_4_0_ENGINE_HARDENING.md`](../PHASE_4_0_ENGINE_HARDENING.md) §4.1

### 설계 원천
- [`COMBAT.md`](../COMBAT.md) §2 속성 피니시 · §11 강화 이동
- [`CORE_SYSTEMS.md`](../CORE_SYSTEMS.md)
- [`EFFECTS.md`](../EFFECTS.md) 이펙트 프리셋·시그널 계약

### 연계 (후속 Phase)
- `SKILL_EXECUTION_SPEC.md` — #2 (착수 직전 작성)
- `FINISH_ATTRIBUTE_SPEC.md` — #3 (착수 직전 작성)

### 참조 소스 (리팩토링 대상)
- [`src/systems/combat/combat_system.gd`](../../src/systems/combat/combat_system.gd)
- [`src/entities/player/player_combo.gd`](../../src/entities/player/player_combo.gd)
- [`src/entities/player/player_skill.gd`](../../src/entities/player/player_skill.gd)
- [`src/entities/enemies/base/base_enemy.gd`](../../src/entities/enemies/base/base_enemy.gd)
- [`src/entities/enemies/base/behaviors/attack_behavior_base.gd`](../../src/entities/enemies/base/behaviors/attack_behavior_base.gd)
- [`src/entities/enemies/base/behaviors/attack_behavior_melee.gd`](../../src/entities/enemies/base/behaviors/attack_behavior_melee.gd)
- [`src/entities/bosses/base/behaviors/attack_behavior_boss_melee_aoe.gd`](../../src/entities/bosses/base/behaviors/attack_behavior_boss_melee_aoe.gd)
- [`src/entities/enemies/projectile/enemy_projectile.gd`](../../src/entities/enemies/projectile/enemy_projectile.gd)
- [`src/systems/event_bus/event_bus.gd`](../../src/systems/event_bus/event_bus.gd) (L161-L164 고아 시그널)
