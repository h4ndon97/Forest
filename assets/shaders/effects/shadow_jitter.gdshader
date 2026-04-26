shader_type canvas_item;

// REC-FX-004 — 그림자 sprite 미세 떨림.
// 시간 정지 중에만 활성화 (active=1.0). 코어 정체성 시각화: "정지된 세계지만 그림자는 살아있다".
//
// 모든 vertex에 동일한 시간 기반 offset 적용 → sprite 전체가 ±intensity 픽셀 이동.
// seed로 인스턴스별 위상 차이 → 여러 그림자가 일제히 떨리지 않고 자연스러움.
// active=0 또는 intensity=0이면 효과 없음 → fallback ColorRect도 안전.

uniform float active : hint_range(0.0, 1.0) = 0.0;
uniform float intensity : hint_range(0.0, 4.0) = 1.0;
uniform float seed = 0.0;

void vertex() {
	float t = TIME * 8.0 + seed;
	float dx = sin(t * 1.7) * intensity * active;
	float dy = cos(t * 2.3) * intensity * active;
	VERTEX += vec2(dx, dy);
}
