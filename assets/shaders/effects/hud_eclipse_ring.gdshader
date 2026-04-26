shader_type canvas_item;

// Phase 4-0 / Pass 5 — B-6 일식 링 셰이더 (글로우 + 아크 마스크).
// 1) 글로우: glow_threshold 이상 밝기 픽셀 주변에 stepped 헤일로 (픽셀아트 친화 — 정수 px 오프셋 샘플링)
// 2) 아크 마스크: resource_ratio에 따라 12시부터 시계방향 잠식. 잠식 영역 = shadow_tex (있으면) 또는 fallback 다크
// alpha 보존 + 런타임 modulate(COLOR) 곱셈 — 외곽 호흡/dim은 modulate가 담당.

uniform float resource_ratio : hint_range(0.0, 1.0) = 1.0;
uniform float glow_intensity : hint_range(0.0, 0.5) = 0.20;
uniform float glow_threshold : hint_range(0.0, 1.0) = 0.25;
uniform float glow_saturation_threshold : hint_range(0.0, 1.0) = 0.15;  // 채도 임계 (회색 제외)
uniform float inner_boost : hint_range(0.0, 3.0) = 2.0;  // 본체 자체 발광 강도
uniform float core_glow_intensity : hint_range(0.0, 1.0) = 0.4;  // 흰색 발광 핵 강도
uniform float arc_aa_band : hint_range(0.0, 0.1) = 0.01;
uniform sampler2D shadow_tex : filter_nearest, repeat_disable;
uniform bool has_shadow_tex = false;

const float HALF_PI_LOCAL = 1.57079632679;
const float TAU_LOCAL = 6.28318530718;

void fragment() {
	vec4 base = texture(TEXTURE, UV);

	// === 글로우: 31x31 stepped 샘플 (반경 15, 패딩 끝까지 헤일로 도달) ===
	// 채도 임계 추가 — 색이 있는 픽셀만 글로우 기여 (회색 프레임 제외)
	vec3 glow_acc = vec3(0.0);
	float glow_weight = 0.0;
	for (int dx = -15; dx <= 15; dx++) {
		for (int dy = -15; dy <= 15; dy++) {
			if (dx == 0 && dy == 0) continue;
			float dist = length(vec2(float(dx), float(dy)));
			float falloff = 1.0 / (1.0 + dist * 0.3);
			vec2 offset = vec2(float(dx), float(dy)) * TEXTURE_PIXEL_SIZE;
			vec4 sampled = texture(TEXTURE, UV + offset);
			float bright = max(sampled.r, max(sampled.g, sampled.b));
			float dark = min(sampled.r, min(sampled.g, sampled.b));
			float saturation = bright - dark;
			if (bright < glow_threshold || saturation < glow_saturation_threshold) continue;
			glow_acc += sampled.rgb * sampled.a * falloff;
			glow_weight += falloff;
		}
	}
	vec3 glow_color = vec3(0.0);
	if (glow_weight > 0.0) {
		glow_color = glow_acc / glow_weight;
	}

	// 외곽 헤일로: 누적 contribution × intensity (거리 멀수록 자연스럽게 약해짐)
	vec3 outer_glow = glow_acc * glow_intensity * (1.0 - base.a);

	// 내부 부스트: 채도 있는 본체 픽셀에 평균 색 추가 + 흰색 발광 핵
	float self_bright = max(base.r, max(base.g, base.b));
	float self_dark = min(base.r, min(base.g, base.b));
	float self_sat = self_bright - self_dark;
	vec3 inner_lit = base.rgb;
	if (self_bright >= glow_threshold && self_sat >= glow_saturation_threshold) {
		// 채도 보존 색 부스트
		inner_lit = base.rgb + glow_color * inner_boost * base.a;
		// 흰색 발광 핵 (luminescence 느낌 강조)
		inner_lit += vec3(core_glow_intensity * base.a);
	}

	// === 아크 마스크: 12시 기준 시계방향 잠식 ===
	// 자원 차감 시 잠식 영역이 12시에서 CW로 확장, 잔여 가시 영역은 CCW 측에 잔존.
	// → 경계선이 CW(12→3→6→9→12)로 진행. AA 밴드는 잠식 측에 둠.
	vec2 to_center = UV - vec2(0.5);
	float angle = atan(to_center.y, to_center.x);
	float clock_angle = mod(angle + HALF_PI_LOCAL, TAU_LOCAL);
	float consume_threshold = (1.0 - resource_ratio) * TAU_LOCAL;
	float consume_factor = 1.0 - smoothstep(consume_threshold - arc_aa_band, consume_threshold, clock_angle);

	// 가시 영역 결과
	vec4 visible = vec4(inner_lit + outer_glow, max(base.a, length(outer_glow) * 0.5));

	// 잠식 영역 결과
	vec4 consumed;
	if (has_shadow_tex) {
		consumed = texture(shadow_tex, UV);
	} else {
		consumed = vec4(0.10, 0.08, 0.07, base.a * 0.6);
	}

	vec4 mixed = mix(visible, consumed, consume_factor);
	COLOR = mixed * COLOR;
}
