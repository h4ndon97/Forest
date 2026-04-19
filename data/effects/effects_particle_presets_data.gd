class_name EffectsParticlePresetsData
extends Resource

## 피격 시 파티클(혈흔/파편) 카테고리별 프리셋.
## Phase 3-7 Pass 2 ⑤. category = organic / mineral / shadow.

@export_group("Organic (tree / flower)")
@export var organic_color_core: Color = Color(0.60, 0.85, 0.50, 1.0)
@export var organic_color_tint: Color = Color(0.95, 1.00, 0.80, 1.0)
@export var organic_amount: int = 8
@export var organic_lifetime: float = 0.35
@export var organic_speed_min: float = 40.0
@export var organic_speed_max: float = 80.0
@export var organic_gravity: float = 60.0
@export var organic_scale: float = 1.0
@export var organic_texture_path: String = ""

@export_group("Mineral (rock / pillar / shard)")
@export var mineral_color_core: Color = Color(0.55, 0.50, 0.45, 1.0)
@export var mineral_color_tint: Color = Color(0.30, 0.28, 0.25, 1.0)
@export var mineral_amount: int = 10
@export var mineral_lifetime: float = 0.45
@export var mineral_speed_min: float = 60.0
@export var mineral_speed_max: float = 120.0
@export var mineral_gravity: float = 120.0
@export var mineral_scale: float = 1.0
@export var mineral_texture_path: String = ""

@export_group("Shadow (dusk_spider / boss)")
@export var shadow_color_core: Color = Color(0.55, 0.25, 0.75, 1.0)
@export var shadow_color_tint: Color = Color(0.15, 0.10, 0.20, 1.0)
@export var shadow_amount: int = 12
@export var shadow_lifetime: float = 0.55
@export var shadow_speed_min: float = 35.0
@export var shadow_speed_max: float = 70.0
@export var shadow_gravity: float = 40.0
@export var shadow_scale: float = 1.0
@export var shadow_texture_path: String = ""

@export_group("Finish 증폭")
@export_range(1.0, 4.0, 0.1) var finish_amount_mult: float = 2.0
@export_range(1.0, 3.0, 0.1) var finish_speed_mult: float = 1.3

@export_group("풀")
## 카테고리당 풀 크기. round-robin 재사용 — 콤보 4타 간격이 짧으면 2 이상 권장
@export_range(1, 6, 1) var pool_per_category: int = 2
