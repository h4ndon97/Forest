class_name LanternConfigData
extends Resource

## 등불 최대 범위 (픽셀). 이 거리 밖의 오브젝트는 그림자 미생성.
@export var max_range: float = 200.0

## PointLight2D energy
@export var light_energy: float = 1.0

## PointLight2D texture_scale
@export var light_texture_scale: float = 1.5

## 등불 빛 색상 (따뜻한 주황)
@export var light_color: Color = Color(1.0, 0.9, 0.7, 1.0)

## 플레이어 기준 등불 위치 오프셋
@export var offset: Vector2 = Vector2(8, -20)
