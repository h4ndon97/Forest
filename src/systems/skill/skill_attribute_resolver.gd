extends Node

## 장착된 스킬 경로를 분석하여 피니시 속성을 결정한다.


## 장착된 경로 배열에서 다수결로 속성 결정.
## light > shadow → "light"
## shadow > light → "shadow"
## 동률(둘 다 > 0) → "hybrid"
## hybrid만 → "hybrid"
## 빈 슬롯만 → "neutral"
func resolve(equipped_paths: Array) -> String:
	var light_count: int = 0
	var shadow_count: int = 0
	var hybrid_count: int = 0

	for p in equipped_paths:
		match p:
			"light":
				light_count += 1
			"shadow":
				shadow_count += 1
			"hybrid":
				hybrid_count += 1

	if light_count == 0 and shadow_count == 0 and hybrid_count == 0:
		return "neutral"

	if hybrid_count > 0 and light_count == 0 and shadow_count == 0:
		return "hybrid"

	if light_count > shadow_count:
		return "light"
	if shadow_count > light_count:
		return "shadow"
	return "hybrid"
