# Phase 4-0 #3 — 속성 피니시 메커닉 상세 스펙

> 상위 로드맵: [`PHASE_4_0_ENGINE_HARDENING.md`](../PHASE_4_0_ENGINE_HARDENING.md) §4.3
> 설계 원천: [`COMBAT.md`](../COMBAT.md) §2 (D1~D5 확정 2026-04-20)
> 선행: Phase 4-0 #1 CombatSystem(`b389a67` 이전) / #2 SkillSystem(`b389a67`) 완료
> 작성일: 2026-04-25
> 상태: Step 분할 확정, 착수 대기

---

## 1. 목표

콤보 4타 피니시를 `SkillSystem.get_finish_attribute()` 결과(`light`/`shadow`/`hybrid`/`neutral`)에 따라 공간 거동과 히트 방식이 분기되도록 구현. Strategy 패턴으로 각 속성을 독립 파일 분리해 `player_combo.gd` 비대화 방지.

[COMBAT.md §2](../COMBAT.md) 거동 매핑 표 그대로 실장.

---

## 2. 현재 상태 (2026-04-25, `b389a67` 기준)

**이미 준비됨**
- [player_combo.gd:83-86](../../src/entities/player/player_combo.gd#L83-L86) 피니시 감지 + `spec.attribute` 전달
- [AttackSpec](../../src/systems/combat/attack_spec.gd) 필드 `piercing`/`multi_hit_count`/`multi_hit_interval`/`knockback` **선제 선언**됨(Phase 4-0 #1 Step 1)
- [EffectsSystem](../../src/systems/effects/effects_system.gd) `request_screen_flash`/`request_afterimage` 작동
- [player_health.set_invulnerable(duration)](../../src/entities/player/player_health.gd#L101) API 존재 — light_dash가 사용 중
- [damage_resolver](../../src/systems/combat/damage_resolver.gd) 속성별 플래시/파티클 분기 활성 (#1 Step 6 + #2 Step 5)
- [event_bus.gd:164](../../src/systems/event_bus/event_bus.gd#L164) `screen_flash_requested` signal 정의됨 — connect 0건(고아)

**결핍**
- `src/entities/player/finish/` 폴더 자체가 없음
- 피니시 거동 분기 코드 0 (현재 모든 피니시가 동일한 rect 히트박스 1타)
- `EnemySystem.get_nearest_enemy(pos, max_dist)` API 없음 — shadow 텔포 좌표 계산 필수
- AttackSpec의 piercing/multi_hit_count 필드 실제 처리 0 (필드만 있음)
- `screen_flash_requested` 고아 시그널 부활 미처리 ([damage_resolver.gd:107](../../src/systems/combat/damage_resolver.gd#L107) TODO)

---

## 3. 결정 사항 (2026-04-25 확정)

| # | 결정 | 사유 |
|---|---|---|
| D1 | Strategy = RefCounted 정적 메서드(`static execute(ctx)`). 인스턴스 없음 | skill_handler_* 패턴과 통일. 상태 없음 |
| D2 | 4개 전략 모두 `CombatSystem.request_attack(AttackSpec)` 경유. 히트박스 직접 생성 금지 | #1 Step 1 원칙 준수 |
| D3 | piercing은 본 Phase에서 **미구현**. 현재 Area2D가 이미 "swept piercing"(정적 영역 내 모든 적 + 적별 i-frame). light 피니시는 플레이어 **이동**으로 자연 관통 체감 확보 | 스코프 관리. 순수 piercing 의미론은 필요 시 Phase 5에서 |
| D4 | multi-hit은 `SceneTreeTimer(ignore_time_scale=true)` 3회 스폰 (3개 독립 Area2D). `attack_requests` 확장 없음 | `EffectsAfterimage` 패턴 재사용. attack_requests 단순 유지 |
| D5 | Shadow 적 부재 시 → `finish_neutral.execute(ctx)` 호출 ([COMBAT.md §2 D3](../COMBAT.md) 그대로) | UX 혼선 방지 |
| D6 | Neutral 강넉백은 본 Phase **미구현**. `spec.knockback` 필드는 값 세팅만(base_enemy 수용 훅 미추가). Phase 5 밸런싱에서 구현 | 적/보스 피격 훅 추가는 별도 회귀 위험. 본 Phase 체감 범위는 "4분기가 눈에 보이는지" |
| D7 | Light 돌진 = `player.velocity.x` 직접 세팅 + 0.15s i-frame. `player_light_dash.gd` 재사용하지 않음(state_machine 분리, 콤보 중 상태 전환 리스크) | 단순성 |
| D8 | Shadow 텔포 = `player.global_position` 즉시 이동. 적 뒤 = `enemy.pos - facing * 28px`. 바닥 충돌 체크 없음(공중 적 대응) | Phase 5에서 지상 강제 확인 검토 |
| D9 | Finish Strategy 위치 = `src/entities/player/finish/` | [PHASE_4_0 §4.3](../PHASE_4_0_ENGINE_HARDENING.md#L260) 스펙대로 |
| D10 | `screen_flash_requested` 부활 범위 = emit(damage_resolver에서 light 피니시 시) + connect(EffectsSystem이 `request_screen_flash`로 포워드). Tier 2 #5 일부 자연 해소 | damage_resolver TODO 해소 |
| D11 | combat_config.tres에 피니시 수치 필드 추가 **없이**, 전략 파일 내부 상수로 시작. 튜닝 반복 후 Phase 5 밸런싱에서 .tres 이전 | 본 Phase는 체감 확인, .tres 이전은 밸런싱 단계 |

---

## 4. 목표 구조

### 4.1 파일 트리

```
src/entities/player/finish/                (신규)
├── finish_strategy.gd                     # 정적 베이스 + FinishContext 상수
├── finish_neutral.gd                      # 기본 경로
├── finish_hybrid.gd                       # 80×40 광역
├── finish_light.gd                        # 전방 72px 돌진 + i-frame
└── finish_shadow.gd                       # 근접 적 뒤 텔포 + 3단 다단 + i-frame + D3 fallback

src/systems/enemy/enemy_registry.gd        (수정: get_nearest 추가)
src/systems/enemy/enemy_system.gd          (수정: get_nearest_enemy API)

src/entities/player/player_combo.gd        (수정: 피니시 분기 → Strategy 위임)
src/systems/combat/damage_resolver.gd      (수정: light 피니시 시 screen_flash_requested emit)
src/systems/effects/effects_system.gd      (수정: screen_flash_requested connect)
```

### 4.2 FinishContext

Strategy에 전달할 불변 Dictionary:

| 키 | 타입 | 용도 |
|---|---|---|
| `player` | CharacterBody2D | spec.attacker / 좌표 / velocity |
| `movement` | Node | facing_direction |
| `health` | Node | set_invulnerable(duration) |
| `damage` | float | `CombatSystem.get_combo_damage(max_hits)` |
| `config` | CombatConfigData | hitbox_size/offset 등 |
| `attribute` | String | "light"/"shadow"/"hybrid"/"neutral" (본인 값, 시그널에 포함) |

### 4.3 Strategy 베이스

```gdscript
# src/entities/player/finish/finish_strategy.gd
class_name FinishStrategy
extends RefCounted

const KEY_PLAYER := "player"
const KEY_MOVEMENT := "movement"
const KEY_HEALTH := "health"
const KEY_DAMAGE := "damage"
const KEY_CONFIG := "config"
const KEY_ATTRIBUTE := "attribute"

static func execute(_ctx: Dictionary) -> void:
    push_error("FinishStrategy.execute() must be overridden")
```

### 4.4 수치 (COMBAT.md §2 표 반영)

| 속성 | hitbox | 추가 | i-frame | damage |
|---|---|---|---|---|
| light | 60×24 (현 size × 1.67) | 전방 72px dash (0.15s) | 0.25s | finish_damage (40) |
| shadow | 36×24 (기본) | 3단 다단, 간격 0.1s, 텔포 28px behind | 0.35s (텔포+다단) | finish_damage/3 per hit |
| hybrid | 80×40 | 제자리 | — | finish_damage |
| neutral | 36×24 (기본) | 제자리 | — | finish_damage |

**light dash 속도**: 72px / 0.15s = 480px/s. `player.velocity.x = facing * 480`.

### 4.5 player_combo 통합점

[player_combo.gd:64](../../src/entities/player/player_combo.gd#L64) `_start_hit`:

```gdscript
func _start_hit(hit_number: int) -> void:
    _combo_count = hit_number
    _combo_state = ComboState.ATTACKING
    _is_attacking = true
    _input_buffered = false

    if _combo_count >= _config.combo_max_hits:
        _execute_finish()  # 신규
    else:
        _execute_normal_hit()  # 기존 spec 빌드 경로

    # 애니메이션/타이머는 공통 (기존 유지)
```

`_execute_finish()` 내부:
```gdscript
var attribute: String = _resolve_finish_attribute()
var strategy: Script = FINISH_STRATEGIES.get(attribute, NeutralStrategy)
strategy.execute({
    KEY_PLAYER: _parent,
    KEY_MOVEMENT: _movement,
    KEY_HEALTH: _parent.get_node("Health"),
    KEY_DAMAGE: CombatSystem.get_combo_damage(_combo_count),
    KEY_CONFIG: _config,
    KEY_ATTRIBUTE: attribute,
})
```

`FINISH_STRATEGIES` preload 상수 Dictionary(light/shadow/hybrid/neutral → Script 매핑).

**_current_attack_area 안전장치**: 전략은 자체 Area2D를 `CombatSystem.request_attack`으로 생성 → 기존 `_current_attack_area` 추적 불가(다단 시 3개 생성). 피니시는 기존처럼 추적하지 않고 `attack_requests` 자동 만료에 위임(short duration). 참고: player_skill도 동일 패턴.

### 4.6 EnemySystem.get_nearest_enemy API

```gdscript
# src/systems/enemy/enemy_system.gd
## 주어진 위치에서 max_dist 내의 최근접 살아있는 적을 반환. 없으면 null.
func get_nearest_enemy(pos: Vector2, max_dist: float) -> Node:
    return _registry.get_nearest(pos, max_dist)

# src/systems/enemy/enemy_registry.gd
func get_nearest(pos: Vector2, max_dist: float) -> Node:
    var best: Node = null
    var best_dist_sq: float = max_dist * max_dist
    for enemy in _enemies.values():
        if not is_instance_valid(enemy) or not (enemy is Node2D):
            continue
        var d_sq: float = pos.distance_squared_to((enemy as Node2D).global_position)
        if d_sq < best_dist_sq:
            best_dist_sq = d_sq
            best = enemy
    return best
```

단순 거리 기반. 방향 가중(예: 전방 우선) 필요 시 Phase 5에서 확장.

---

## 5. 단계별 마이그레이션

### Step 1 — Scaffolding + EnemySystem API (회귀 0)

**신규**
- `src/entities/player/finish/finish_strategy.gd` (추상 베이스 + 상수)
- `src/entities/player/finish/finish_{neutral,hybrid,light,shadow}.gd` (4 전략 — 모두 `push_warning("not yet implemented")` + 기존 spec 1회 호출로 fallback)
- `src/systems/enemy/enemy_registry.gd` `get_nearest(pos, max_dist) -> Node` 추가
- `src/systems/enemy/enemy_system.gd` `get_nearest_enemy(pos, max_dist) -> Node` 래퍼 추가

**수정**
- `player_combo.gd`: `_start_hit` 피니시 분기 → Strategy 위임. FINISH_STRATEGIES 매핑 상수.

**검증**: gdlint/gdformat/헤드리스. 실게임 피니시 타격 시 기존과 동일 거동(내부 경로만 Strategy 경유).

### Step 2 — neutral / hybrid 구현 (회귀 중 낮음)

**neutral**: 기존 경로 그대로 복제(표준 rect 히트박스 + finish_damage). `spec.knockback` 필드만 값 세팅(1.5× 플레이스홀더, 수용 훅 없음).

**hybrid**: 동일하되 `spec.hitbox_size = Vector2(80, 40)` + `hitbox_offset.x` 재계산(중심 정렬).

**검증**: 실게임 hybrid 스킬 2개 장착 후 4타 → 80×40 광역 확인(다수 적 동시 데미지).

### Step 3 — light 구현 (회귀 중)

**light**:
1. `player.velocity.x = facing * LIGHT_DASH_SPEED` (0.15s 유지는 velocity 타이머)
2. `health.set_invulnerable(LIGHT_IFRAME_DURATION)` (0.25s)
3. `spec.hitbox_size = Vector2(60, 24)` + `spec.active_duration = 0.2` (돌진 궤적 전체 커버)
4. `EffectsSystem.request_afterimage` 호출(5개, light_dash 파라미터 재사용)

**주의**: velocity 세팅 방식 — `player_combo`가 velocity 직접 쓰면 `player_movement` 중 평형 재설정과 충돌 가능. Step 3 진입 시 실측 후 필요 시 `_parent.set_meta("finish_dash_active", true)` + movement가 이 플래그 시 가속도 무시 등 방어 코드 검토.

**검증**: 4타 피니시 시 플레이어 전방 이동(72px) + 잔상 + 피격 i-frame.

### Step 4 — shadow 구현 (회귀 중)

**shadow**:
1. `target: Node = EnemySystem.get_nearest_enemy(_parent.global_position, SHADOW_RANGE)`. null이면 `finish_neutral.execute(ctx)` 호출 후 return (D5 fallback)
2. `health.set_invulnerable(SHADOW_IFRAME_DURATION)` (0.35s)
3. `_parent.global_position = target.global_position + Vector2(-facing * 28, 0)` — 텔포
4. 3단 다단: `t=0, 0.1, 0.2`에 `SceneTreeTimer` 스케줄 → 각 타이머에 `CombatSystem.request_attack(spec)` 호출. damage는 `finish_damage / 3` (D4 총합 유지)
5. 각 히트박스 `active_duration = 0.08`
6. 잔상 (보라 계열 3~5개)

**검증**: 적 부재 시 일반 피니시, 적 존재 시 텔포 + 3 데미지 넘버.

### Step 5 — screen_flash_requested 부활 (회귀 0)

**damage_resolver.gd** `_apply_effects`:
```gdscript
if spec.is_finish and spec.attribute == "light":
    var cfg: EffectsConfigData = EffectsSystem.get_config()
    EventBus.screen_flash_requested.emit(
        cfg.light_finish_flash_color,   # 신규 필드. effects_config_data에 추가.
        cfg.light_finish_flash_duration  # 신규 필드
    )
```

**effects_system.gd** `_ready`:
```gdscript
EventBus.screen_flash_requested.connect(_on_screen_flash_requested)

func _on_screen_flash_requested(color: Color, duration: float) -> void:
    request_screen_flash(color, duration)
```

**effects_config_data.gd** Light Dash / Screen Flash 그룹에 `light_finish_flash_color: Color` + `light_finish_flash_duration: float` 추가. 기본값 = 흰색 0.6 알파 / 0.12s.

**검증**: light 피니시 시 전체 화면 순간 번쩍.

---

## 6. 검증 방법

### 헤드리스
- `--headless --quit` 로드 에러 0 (각 Step 후)

### 정적 분석
- 수정·신규 파일 gdlint/gdformat clean

### 수동 플레이 체크리스트 (Step 5 후 전체 확인)
- [ ] 빈 슬롯 4개 → 4타 피니시 = **neutral** (기존 경로 동일)
- [ ] shadow_strike 슬롯 3+ → 4타 = **shadow** 텔포 + 3단 데미지 넘버
- [ ] light_slash 슬롯 3+ → 4타 = **light** 전방 돌진 + 잔상 + 화면 플래시 + i-frame (적 공격 안 받음)
- [ ] light 2 + shadow 2 → 4타 = **hybrid** 80×40 광역 (다수 적 동시 데미지)
- [ ] shadow 피니시 시 근처 적 없으면 → neutral 경로 fallback
- [ ] 콤보 진행 중 사망 → 기존 `_cancel_current_attack`로 정상 중단 (회귀 없음)

---

## 7. 위험 / 완화

| 위험 | 완화 |
|---|---|
| light dash velocity 덮어쓰기가 movement 로직과 충돌 | Step 3 실측 후 필요 시 flag/guard 도입 |
| shadow 텔포 직후 충돌(벽 내부 등) | Phase 5 강화; 본 Phase는 `get_nearest_enemy`에 지상 필터 없음 |
| multi_hit 3개 Area2D가 같은 적에 중복 데미지 | base_enemy의 i-frame이 짧으므로 0.1s 간격이면 데미지 적용 가능. 실측 후 필요시 간격 조정 |
| Shadow 다단 중 적이 죽으면 남은 히트는 허공 | 의도됨. 데미지 넘버 미출력(damage_resolver에서 display_damage <= 0 처리) |
| FINISH_STRATEGIES Dictionary 키 오타 | 상수로 선언(KEY_ATTR_LIGHT 등), 매핑 실패 시 neutral로 폴백 |

---

## 8. 미결 사항 (Phase 5 이월)

- [ ] `spec.knockback` 실제 수용 — base_enemy/base_boss 훅 추가
- [ ] shadow 텔포 지상 보정(공중 적은 공중 텔포 허용 or 금지?)
- [ ] light dash의 piercing 고유 의미론(현재는 이동으로 대체)
- [ ] 피니시 수치 .tres 이전(combat_config 확장)
- [ ] 강화 이동(#4)과의 입력 충돌 여부 — 속성 토글 키 도입 시 재검토
