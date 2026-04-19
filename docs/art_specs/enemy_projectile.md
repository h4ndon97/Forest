# 적 투사체(돌 파편) 교보재

> Pass 11 — `EnemyProjectile` 프로그래밍 아트.
> 포털 교보재 패턴(`stage_portal_visual.gd`) 준수. signpost_stone / pillar_enemy / 보스 phase_2_branch_storm 공통 사용.

## 1. 개요

- **스크립트**: `src/entities/enemies/projectile/enemy_projectile_visual.gd` (~105줄)
- **배치**: `EnemyProjectile.tscn` 루트 `Area2D` → 자식 `Visual: Node2D`
- **대체 대상**: 기존 `FallbackVisual` `ColorRect` 8×6 (삭제됨)
- **원점 규약**: Visual 노드 원점 = 투사체 중심. 기본 비행 방향 = +X(오른쪽).

## 2. 크기/플립

| 요소 | 값 |
|---|---|
| 시각 폭 | 16 px |
| 시각 높이 | 10 px |
| 히트박스(collision) | 8×6 (변경 없음) |
| 좌향 비행 | 부모 `enemy_projectile.gd._update_visual_facing()`이 `_visual.scale.x = -1.0`로 수평 플립 |

## 3. 컬러 팔레트

| 용도 | RGB |
|---|---|
| 돌 기본 | (0.42, 0.40, 0.376) |
| 돌 하이라이트 | (0.58, 0.56, 0.53) |
| 돌 섀도우 | (0.25, 0.23, 0.21) |
| 균열 | (0.15, 0.13, 0.11) |
| 먼지 트레일 | (0.60, 0.57, 0.53) |

## 4. 구성 요소

- **돌 파편 본체**: 비대칭 오각형. 우측 팁 뾰족 + 좌측 뒤쪽 사각. 비행 중 ±0.18 rad, 주기 0.4s 진동(`tilt`)으로 회전감 부여.
- **상단 하이라이트 라인** 2개(팁→상단 뒤쪽).
- **하단 섀도우 라인** 2개(팁→하단 뒤쪽).
- **균열** 1줄(중앙→상단 짧게).
- **먼지 트레일** 3개 — 뒤쪽(−X)으로 step=4px씩, 반지름 2.2→0.8 감소, α 0.55→0.12 감소, Y 방향 ±0.8 px 와블(주기 0.25s).

## 5. API / 데이터

- `@export var sprite_path: String = ""` — PNG 교체 경로. 설정 시 `_setup_sprite_fallback()`이 자식 `Sprite2D`("ProjectileSprite") 생성 후 `_draw()` 스킵.
- 크기 고정(16×10). 적/보스별 속도·데미지·수명은 `enemy_projectile.gd.setup()` 주입(시각 API는 관여하지 않음).

## 6. 사용처

| 발사자 | 데이터 | 비고 |
|---|---|---|
| signpost_stone (돌기둥) | `data/enemies/zone1/signpost_stone.tres` | Phase 2-2 기본 사수 |
| pillar_enemy | `data/enemies/pillar_enemy.tres` | 돌기둥 계열 |
| AncientOakheart phase 2 | `data/bosses/zone1/phase_2_branch_storm.tres` | branch_storm 분산탄으로 재활용 — 아트는 동일 돌 파편 |

## 7. 관련 파일

- `src/entities/enemies/projectile/enemy_projectile_visual.gd` (신규)
- `src/entities/enemies/projectile/EnemyProjectile.tscn` (FallbackVisual 제거, Visual Node2D 추가)
- `src/entities/enemies/projectile/enemy_projectile.gd` (`_fallback_visual` → `_visual` 참조 전환)
