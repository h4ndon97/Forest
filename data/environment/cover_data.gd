class_name CoverData
extends EnvironmentObjectData

## 차폐물 환경 오브젝트 데이터.
## STOPPED 중 위치 이동, 상시 그림자 차단(투영 영역 내 적 강도 override).

# 그림자 차단 모드 (Q2 — Phase 2-5b는 CREATE만 구현, 자리 확보)
enum BlockMode { CREATE, REMOVE, BOTH }

## 투영 방향: 빛 반대 방향(태양/등불) vs 차폐물 local 고정.
enum ProjectionMode { LIGHT_OPPOSITE, LOCAL_FIXED }

# 위치 이동 (Push/Pull, Q1 A)
@export var move_step_pixels: float = 16.0
@export var min_x_offset: float = -64.0
@export var max_x_offset: float = 64.0

@export var block_mode: BlockMode = BlockMode.CREATE

## 영역 내 적 강도 강제값 (CREATE 모드: 0.0~1.0). 1.0=최강(짧은 그림자=밤 강함 / 긴 그림자=낮 강함).
@export var block_intensity: float = 0.9

# 투영 영역 기하
@export var shadow_projection_length: float = 96.0
@export var shadow_projection_width: float = 32.0

@export var projection_mode: ProjectionMode = ProjectionMode.LIGHT_OPPOSITE

# 본체 fallback 비주얼
@export var body_size: Vector2 = Vector2(24, 64)
@export var body_color: Color = Color(0.35, 0.30, 0.28, 1.0)
