shader_type canvas_item;

// Phase 4-0 / Pass 5 — B-6 일식 링 셰이더 (글로우 + 아크 마스크).
// 1) 글로우: glow_threshold 이상 밝기 픽셀 주변에 stepped 헤일로 (픽셀아트 친화 — 정수 px 오프셋 샘플링)
// 2) 아크 마스크: resource_ratio에 따라 12시부터 시계방향 잠식. 잠식 영역 = shadow_tex (있으면) 또는 fallback 다크
// alpha 보존 + 런타임 modulate(COLOR) 곱셈 — 외곽 호흡/dim은 modulate가 담당.

uniform float resource_ratio : hint_range(0.0, 1.0) = 1.0;
uniform float glow_intensity : hint_range(0.0, 3.0) = 1.2;
uniform float glow_threshold : hint_range(0.0, 1.0) = 0.25;
uniform float arc_aa_band : hint_range(0.0, 0.1) = 0.01;
uniform sampler2D shadow_tex : filter_nearest, repeat_disable;
uniform bool has_shadow_tex = false;

const float HALF_PI_LOCAL = 1.57079632679;
const float TAU_LOCAL = 6.28318530718;

void fragment() {
	vec4 base = texture(TEXTURE, UV);

	// === 글로우: 5x5 stepped 샘플 (정수 px 오프셋, 픽셀아트 친화) ===
	vec3 glow_acc = vec3(0.0);
	float glow_weight = 0.0;
	for (int dx = -2; dx <= 2; dx++) {
		for (int dy = -2; dy <= 2; dy++) {
			if (dx == 0 && dy == 0) continue;
			vec2 offset = vec2(float(dx), float(dy)) * TEXTURE_PIXEL_SIZE;
			vec4 sampled = texture(TEXTURE, UV + offset);
			float brightness = max(sampled.r, max(sampled.g, sampled.b));
			if (brightness < glow_threshold) continue;
			float dist = length(vec2(float(dx), float(dy)));
			float falloff = 1.0 / (1.0 + dist);
			glow_acc += sampled.rgb * sampled.a * falloff;
			glow_weight += falloff;
		}
	}
	vec3 glow = vec3(0.0);
	if (glow_weight > 0.0) {
		glow = (glow_acc / glow_weight) * glow_intensity * (1.0 - base.a);
	}

	// === 아크 마스크: 12시 기준 시계방향 잠식 ===
	vec2 to_center = UV - vec2(0.5);
	float angle = atan(to_center.y, to_center.x);
	float clock_angle = mod(angle + HALF_PI_LOCAL, TAU_LOCAL);
	float consume_threshold = resource_ratio * TAU_LOCAL;
	float consume_factor = smoothstep(consume_threshold, consume_threshold + arc_aa_band, clock_angle);

	// 가시 영역 결과
	vec4 visible = vec4(base.rgb + glow, max(base.a, length(glow) * 0.5));

	// 잠식 영역 결과
	vec4 consumed;
	if (has_shadow_tex) {
		consumed = texture(shadow_tex, UV);
	} else {
		// fallback — 다크 + base alpha를 유지해 팔각 윤곽 보존
		consumed = vec4(0.10, 0.08, 0.07, base.a * 0.6);
	}

	vec4 mixed = mix(visible, consumed, consume_factor);
	COLOR = mixed * COLOR;
}
