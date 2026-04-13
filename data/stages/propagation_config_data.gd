class_name PropagationConfigData
extends Resource

## 시간 전파 설정 리소스.
## 인접 스테이지로의 시간 전파 규칙을 정의한다.

## 홉당 전파 비율 (인접 = rate, 인접의 인접 = rate^2, ...)
@export var propagation_rate: float = 0.5

## 이 비율 미만이면 전파 중단
@export var minimum_threshold: float = 0.05

## 재귀 탐색 최대 깊이 (안전 제한)
@export var max_depth: int = 6

## 기본 시간 흐름 속도 (게임 시간 시/분). TimeConfigData.flow_speed와 동일 값.
@export var flow_speed: float = 1.0
