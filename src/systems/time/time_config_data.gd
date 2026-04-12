class_name TimeConfigData
extends Resource

## 시각 설정
@export var initial_hour: float = 12.0
@export var sunrise_hour: float = 6.0
@export var sunset_hour: float = 18.0
@export var manipulation_limit_minutes: float = 10.0

## 조작 속도 (인게임 시간/초)
@export var manipulation_speed: float = 3.0

## 흐름 속도 (인게임 시간/실시간 분 — 1.0 = 1분에 1시간)
@export var flow_speed: float = 1.0

## 자원
@export var resource_max: float = 100.0
@export var resource_initial: float = 100.0
@export var consume_per_game_hour: float = 10.0
@export var recover_per_game_hour: float = 5.0
@export var kill_recover_amount: float = 3.0

## 분위기 (CanvasModulate)
@export var day_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var night_color: Color = Color(0.15, 0.1, 0.25, 1.0)
@export var sunrise_color: Color = Color(1.0, 0.85, 0.7, 1.0)
@export var sunset_color: Color = Color(0.9, 0.6, 0.4, 1.0)
@export var transition_duration_hours: float = 1.0
