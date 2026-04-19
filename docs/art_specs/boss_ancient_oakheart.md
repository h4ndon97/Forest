# 거대 고목(AncientOakheart) 보스 교보재

> Pass 10 — 1구역 보스 프로그래밍 아트.
> 포털 교보재 패턴(`stage_portal_visual.gd`) + 환경 오브젝트 패턴(Pass 8/9) 준수.

## 1. 개요

- **스크립트**: `src/entities/bosses/zone1/ancient_oakheart_visual.gd`
- **배치**: `AncientOakheart.tscn` 루트 `CharacterBody2D` → 자식 `Visual: Node2D`
- **대체 대상**: 기존 `FallbackSprite` `ColorRect` (삭제됨)
- **원점 규약**: Visual 노드 원점 = 지면 접지점. 나무 구조는 원점에서 위(−Y)로 뻗음.

## 2. 크기/앵커

| 요소 | 값 | 비고 |
|---|---|---|
| 본체 폭 | 56 px | `base_stats.collision_width` |
| 본체 높이 | 72 px | `base_stats.collision_height` |
| 루트 스프레드 | ±40 px | 지면의 뿌리 5개 |
| 트렁크 상단 폭 | 40 px | 위로 갈수록 좁아짐 |
| 약점(knothole) 위치 | (0, −56) | `boss_data.weak_point_offset` |
| 약점 반지름 | 10 px | 시각만 — 히트박스 r=22는 별도 |

## 3. 컬러 팔레트

| 용도 | RGB | 사용처 |
|---|---|---|
| 껍질 기본 | (0.29, 0.18, 0.11) | 본체·뿌리·가지 스텁 |
| 껍질 하이라이트 | (0.42, 0.29, 0.19) | 좌측 스트립 |
| 껍질 섀도우 | (0.19, 0.12, 0.07) | 우측 스트립 + 세로 결 |
| 속살(inner wood) | (0.56, 0.40, 0.24) | 가지 절단면 + 페이즈 2 상처 얼룩 |
| 균열 | (0.12, 0.07, 0.04) | 페이즈 2 가로 균열 + 약점 knothole |
| 이끼 | (0.27, 0.35, 0.18) | 하단 5개 클러스터 |
| 이끼 밝음 | (0.36, 0.47, 0.24) | 이끼 하이라이트 |
| 약점 발광 | (0.95, 0.78, 0.38) | 페이즈 2 약점 halo/코어 |

## 4. 페이즈별 표현

| 페이즈 | HP 임계 | 시각 |
|---|---|---|
| 0 (phase_1) | 100–50% | 온전한 고목. 약점 knothole은 어두운 구멍으로만 표시(발광 없음) |
| 1 (phase_2) | 50–0% | 가로 균열 3줄 + 속살 얼룩 3개 + 약점 발광 halo/코어 (1.6s 펄스) |

전환 경로: `base_boss._on_phase_entered` → `EventBus.boss_phase_changed(boss_id, from, to)` → Visual의 `_on_boss_phase_changed` → `set_phase(to_phase)`.

Visual은 `_resolve_boss_id()`로 부모의 `boss_data.boss_id`를 저장해 자기 보스만 필터링. base_boss는 Visual을 직접 참조하지 않음(시그널 결합).

## 5. 애니메이션

- **스웨이**: ±1.5 px, 주기 3.5s. 본체 상단·가지 스텁·약점(비율 적용)에 적용. 뿌리·이끼는 고정.
- **약점 펄스 (페이즈 2)**: 주기 1.6s, halo α 0.35–0.7, 코어 α 0.6–0.9.

## 6. API

```gdscript
func configure(body_size: Vector2, weak_point_offset: Vector2) -> void
func set_phase(phase_index: int) -> void
```

`base_boss.gd._ready()`가 `$Visual`이 존재할 때 `configure(Vector2(collision_width, collision_height), boss_data.weak_point_offset)` 호출. `set_phase`는 EventBus 경로로만 호출됨.

## 7. Sprite 교체 경로

`@export var sprite_path: String = ""` 설정 시 `_setup_sprite_fallback()`이 자식 `Sprite2D`("BossSprite") 생성 후 `_draw()` 스킵. 스프라이트 도입 시 씬 에디터에서 Visual 노드의 sprite_path를 PNG 경로로 지정하면 됨.

## 8. 관련 파일

- `src/entities/bosses/zone1/ancient_oakheart_visual.gd` (신규, ~250줄)
- `src/entities/bosses/zone1/AncientOakheart.tscn` (FallbackSprite 제거, Visual Node2D 추가)
- `src/entities/bosses/base/base_boss.gd` (_ready에 Visual configure 호출 추가)
- `data/bosses/zone1/ancient_oakheart.tres` (변경 없음 — 데이터 주도)
