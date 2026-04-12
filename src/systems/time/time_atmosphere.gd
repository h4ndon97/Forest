extends CanvasModulate

## 시각에 따라 CanvasModulate 색조를 전환하여 낮/밤 분위기를 표현한다.


func update_atmosphere(current_hour: float, config: TimeConfigData) -> void:
	color = _calculate_color(current_hour, config)


func _calculate_color(hour: float, config: TimeConfigData) -> Color:
	var sunrise := config.sunrise_hour
	var sunset := config.sunset_hour
	var dur := config.transition_duration_hours

	var sunrise_start := sunrise - dur
	var sunrise_end := sunrise + dur
	var sunset_start := sunset - dur
	var sunset_end := sunset + dur

	# 일출 전환 (05:00~07:00)
	if hour >= sunrise_start and hour < sunrise:
		var t := (hour - sunrise_start) / dur
		return config.night_color.lerp(config.sunrise_color, t)

	if hour >= sunrise and hour < sunrise_end:
		var t := (hour - sunrise) / dur
		return config.sunrise_color.lerp(config.day_color, t)

	# 낮 유지 (07:00~17:00)
	if hour >= sunrise_end and hour < sunset_start:
		return config.day_color

	# 일몰 전환 (17:00~19:00)
	if hour >= sunset_start and hour < sunset:
		var t := (hour - sunset_start) / dur
		return config.day_color.lerp(config.sunset_color, t)

	if hour >= sunset and hour < sunset_end:
		var t := (hour - sunset) / dur
		return config.sunset_color.lerp(config.night_color, t)

	# 밤 유지 (19:00~05:00)
	return config.night_color
