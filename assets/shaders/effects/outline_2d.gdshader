shader_type canvas_item;

// Phase 4 — 플레이어 외곽선 강조 펄스용 셰이더.
// Selout(sprite-baked 1px) 위에 강조 모먼트(피니시/피격/시간정지)에서 1~3프레임 토글된다.
// 8방향 샘플 + UV bound 체크 — AtlasTexture 인접 프레임 bleeding 방지.
// 캐릭터 픽셀(alpha>0) 위치는 투명으로 두어 원본 sprite가 그대로 보이게 함.
//   → 본 셰이더는 외곽 halo만 추가 그림.

uniform float outline_width : hint_range(0.0, 4.0) = 0.0;
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

float sample_alpha(vec2 uv) {
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		return 0.0;
	}
	return texture(TEXTURE, uv).a;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	// 캐릭터 픽셀 위치 — 그리지 않음 (원본 sprite가 담당)
	if (tex.a > 0.0) {
		COLOR = vec4(0.0);
		return;
	}

	// outline 비활성 (width 0) — 빠른 종료
	if (outline_width <= 0.0) {
		COLOR = vec4(0.0);
		return;
	}

	// 8방향 (square) 샘플
	vec2 ps = TEXTURE_PIXEL_SIZE * outline_width;
	float max_a = 0.0;
	max_a = max(max_a, sample_alpha(UV + vec2(-ps.x, 0.0)));
	max_a = max(max_a, sample_alpha(UV + vec2(ps.x, 0.0)));
	max_a = max(max_a, sample_alpha(UV + vec2(0.0, -ps.y)));
	max_a = max(max_a, sample_alpha(UV + vec2(0.0, ps.y)));
	max_a = max(max_a, sample_alpha(UV + vec2(-ps.x, -ps.y)));
	max_a = max(max_a, sample_alpha(UV + vec2(ps.x, -ps.y)));
	max_a = max(max_a, sample_alpha(UV + vec2(-ps.x, ps.y)));
	max_a = max(max_a, sample_alpha(UV + vec2(ps.x, ps.y)));

	if (max_a > 0.0) {
		COLOR = vec4(outline_color.rgb, outline_color.a * max_a);
	} else {
		COLOR = vec4(0.0);
	}
}
