# 시간이 멈춘 숲 — 6. 성장 시스템

> 이 문서는 강화 포인트 투자, 능력치 성장, 빌드 분화를 정의한다.
> 스킬 시스템(SKILLS.md)과 스테이지 보상(STAGES.md)에서 확정된 구조 위에서 설계된다.

---

## 1. 성장 구조 (확정)

### 세 가지 성장 카테고리

| 카테고리 | 내용 | 성장 경로 |
|---|---|---|
| **빛 투자** | 빛 스킬 해금 + 빛 관련 능력치 | 강화 포인트 |
| **그림자 투자** | 그림자 스킬 해금 + 그림자 관련 능력치 | 강화 포인트 |
| **프로퍼티** | 시간 자원 등 기반 능력치 | 별도 포인트 + 장비/장신구 |

- 빛/그림자: 스킬 해금과 능력치 상승이 투자 시 동시에 발생
- 프로퍼티: 별도 포인트로 영구 투자 + 장비로 유연하게 조정 가능
- 혼합 계열: 빛·그림자 각각 일정 이상 투자 시 해금
- **스킬 슬롯**: 해금된 스킬은 4슬롯에 자유롭게 장착 가능 (트리 제한 없음, Phase 2-1 구현)

---

## 2. 능력치 항목 (확정)

### 빛 투자 시 상승

| 능력치 | 설명 |
|---|---|
| 공격력 | 기본 공격 및 빛 스킬 데미지 |
| 등불 범위/밝기 | 밤 전투 효율 향상 |

### 그림자 투자 시 상승

| 능력치 | 설명 |
|---|---|
| HP | 체력 증가 |

### 프로퍼티 (별도 포인트 + 장비)

| 능력치 | 설명 |
|---|---|
| 시간 자원 최대치 | 시간 조작 가능량 |
| 시간 자원 회복량 | 흐름 중 회복 속도 |

### 미결 사항
- [ ] 빛/그림자 투자 능력치 추가 항목 여부
- [ ] 프로퍼티 능력치 추가 항목 여부 (이동 속도 등)

---

## 3. 빌드 분화 (확정)

| | 빛 특화 | 그림자 특화 | 혼합 |
|---|---|---|---|
| 스킬 | 빠르고 날카로운 공격 | 묵직하고 넓은 공격 | 융합 공격 + 연쇄 콤보 보너스 |
| 능력치 | 공격력↑, 등불 범위↑ | HP↑ | 양쪽 균형 |
| 체감 | 낮은 체력, 높은 화력 | 높은 체력, 안정적 생존 | 콤보 연계, 상황 대응력 |

### 피니시 속성 연동 (Phase 2-1 구현)
- 4타 콤보 피니시의 속성은 장착된 4슬롯의 스킬 경로(light/shadow/hybrid) 다수결로 결정
- 빛 투자 → 빛 스킬 장착 → 피니시 빛 속성 / 그림자 → 그림자 / 혼재 → hybrid / 비어있음 → neutral

### 리스펙 (확정)
- **가능** — 거점에서 비용을 내고 재분배
- 빌드 실험이 자유로움, 보스나 구역에 맞춰 전략적으로 재조정 가능

---

## 4. 구현 상태 (Phase 2-6 완료)

### GrowthSystem Autoload

```
GrowthSystem (Autoload, src/systems/growth/growth_system.gd)
├── PointTracker (growth_point_tracker.gd) — 포인트 잔고/투자/리스펙
└── StatCalculator (growth_stat_calculator.gd) — 투자→보너스 계산
```

### 포인트 체계

| 포인트 | 용도 | 획득 |
|---|---|---|
| **강화 포인트** | 빛/그림자 투자 | 적 처치 (1~3), 스테이지 클리어 (10), 보스 (50) |
| **프로퍼티 포인트** | 프로퍼티 투자 | 별도 획득 (향후 구체화) |

### 투자 보너스 (포인트당, growth_config.tres)

| 카테고리 | 능력치 | 보너스/pt | 적용 대상 |
|---|---|---|---|
| 빛 | 공격력 | +5.0 | CombatSystem.get_combo_damage() |
| 빛 | 등불 범위 | +15.0px | ShadowSystem._lantern_max_range |
| 빛 | 등불 밝기 | +0.05 energy | PlayerLantern._light.energy |
| 그림자 | HP | +10.0 | PlayerHealth.max_hp |
| 프로퍼티 | 시간 최대치 | +10.0 | TimeResource.max_value |
| 프로퍼티 | 시간 회복량 | +1.0/hr | TimeResource.recover() |

### 혼합 해금
- 빛·그림자 각각 **3포인트 이상** 투자 시 `hybrid_unlocked` 시그널 발신
- 임계값: `growth_config.tres`의 `hybrid_unlock_threshold`에서 조정

### 리스펙
- 거점에서 실행 가능
- 비용: 총 투자 포인트 × 50% (강화 포인트 소모)
- 빛/그림자 투자 초기화, 반환 포인트 = 투자한 총량
- 프로퍼티는 리스펙 대상 아님

### 세이브/로드
- SaveManager(`save_manager.gd`)의 `collect_data()`/`apply_data()`에 통합 (`"growth"` 키)
- 저장 항목: available_growth, available_property, light/shadow/property_invested, hybrid_unlocked

### 시스템 간 통신 (EventBus)

| 시그널 | 발신 | 수신 |
|---|---|---|
| `growth_stats_changed()` | GrowthSystem (투자/리스펙 후) | PlayerHealth, TimeResource, ShadowSystem, PlayerLantern |
| `growth_points_changed(growth, property)` | PointTracker | (Phase 3 UI) |
| `growth_invested(category, total)` | PointTracker | (Phase 3 UI) |
| `growth_respec_completed()` | PointTracker | (Phase 3 UI) |
| `hybrid_unlocked()` | PointTracker | SkillSystem (Phase 3) |
| `points_earned(amount, source)` | PointTracker | (Phase 3 UI) |

### Public API

| 카테고리 | 메서드 | 용도 |
|---|---|---|
| 조회 | `get_available_growth()` / `get_available_property()` | 잔여 포인트 |
| 조회 | `get_light_invested()` / `get_shadow_invested()` / `get_property_invested()` | 투자 현황 |
| 투자 | `invest_light(n)` / `invest_shadow(n)` / `invest_property(n)` | 포인트 투자 |
| 리스펙 | `can_respec()` / `respec()` | 리스펙 가능 여부/실행 |
| 보너스 | `get_attack_bonus()` / `get_hp_bonus()` / `get_lantern_*_bonus()` / `get_time_*_bonus()` | 소비 시스템용 |
| 해금 | `is_hybrid_unlocked()` | 혼합 해금 여부 |
| 세이브 | `get_save_data()` / `load_save_data(data)` | 직렬화 |

### 디버그 키 (Phase 3 UI 전까지)

| 키 | 기능 |
|---|---|
| F5 | 강화+프로퍼티 포인트 각 +10 |
| F6 | 빛 투자 1pt |
| F7 | 그림자 투자 1pt |
| F9 | 프로퍼티 투자 1pt |

### 파일 구조

```
src/systems/growth/
├── growth_system.gd           # Autoload 오케스트레이터
├── growth_point_tracker.gd    # 포인트 잔고/투자/리스펙
└── growth_stat_calculator.gd  # 보너스 계산

data/growth/
├── growth_config_data.gd      # GrowthConfigData Resource 클래스
└── growth_config.tres         # 수치 인스턴스
```

### 수정 파일

- `src/systems/event_bus/event_bus.gd` — +5 시그널 (growth_stats_changed, growth_points_changed, growth_invested, growth_respec_completed, hybrid_unlocked)
- `src/systems/combat/combat_system.gd` — get_combo_damage()에 공격력 보너스 가산
- `src/entities/player/player_health.gd` — HP 보너스 적용 + growth_stats_changed 핸들러
- `src/systems/time/time_resource.gd` — 시간 자원 최대치/회복량 보너스 + growth_stats_changed 핸들러
- `src/systems/shadow/shadow_system.gd` — 등불 범위 보너스 + growth_stats_changed 핸들러
- `src/entities/player/player_lantern.gd` — 등불 밝기 보너스 + growth_stats_changed 핸들러
- `src/systems/stage/stage_system.gd` — load_save_data를 save_manager에 위임
- `src/systems/stage/save_manager.gd` — collect_data/apply_data에 growth 데이터 수집/복원 통합
- `project.godot` — +GrowthSystem Autoload (EventBus 직후)

### 미결 사항
- [ ] 빛/그림자 투자 능력치 추가 항목 여부
- [ ] 프로퍼티 능력치 추가 항목 여부 (이동 속도 등)
- [ ] 투자 → 스킬 해금 매핑 (어떤 투자 수준에서 어떤 스킬 해금?)
- [ ] 프로퍼티 포인트 구체적 획득 경로
- [ ] 성장 투자 UI (Phase 3)
- [ ] 수치 밸런싱 (Phase 5)
