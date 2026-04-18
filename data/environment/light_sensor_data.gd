class_name LightSensorData
extends Resource

## 광 센서 설정 리소스.
## 빔(layer=128)이 감지 영역에 진입하면 점등, 이탈 시 소등.
## HiddenRevealer LIGHT_SENSOR/REFLECTION 소스 및 ENVIRONMENT α 잠금 양쪽에 사용.

@export var sensor_id: String = ""
@export var activation_delay: float = 0.15
@export var deactivation_delay: float = 0.15
@export var color_off: Color = Color(0.3, 0.3, 0.3)
@export var color_on: Color = Color(1.0, 0.9, 0.4)
