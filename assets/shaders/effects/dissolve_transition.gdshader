shader_type canvas_item;

// Phase 3-7 Pass 5 Step 1 ③ — 메뉴/씬 전환 디졸브 오버레이.
// weight=0: 완전 투명(원본 노출). weight=1: 디졸브 색으로 화면 덮음.
// overlay_dissolve_noise.png(#51)이 아직 없으므로 hash value_noise로 대체.

uniform float weight: hint_range(0.0, 1.0) = 0.0;
uniform vec4 dissolve_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float edge_softness: hint_range(0.0, 0.2) = 0.05;
uniform float noise_scale = 32.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
	float n = value_noise(UV * noise_scale);
	float alpha_factor = smoothstep(n - edge_softness, n + edge_softness, weight);
	COLOR = vec4(dissolve_color.rgb, dissolve_color.a * alpha_factor);
}
