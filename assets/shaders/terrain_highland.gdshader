
// terrain_highland.gdshader
// 高地地形：金黄色叠加 + 缓慢呼吸脉冲，示意"高处"
// 适用 renderer：Forward+ / Mobile / Compatibility
shader_type canvas_item;

uniform vec4 overlay_color : source_color = vec4(0.85, 0.75, 0.40, 0.35);
uniform float pulse_speed : hint_range(0.0, 3.0) = 0.6;
uniform float pulse_strength : hint_range(0.0, 0.5) = 0.15;

void fragment() {
	vec4 base = texture(TEXTURE, UV);

	// 缓慢呼吸脉冲：用 sin 驱动 alpha 强弱变化
	float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);
	float alpha = overlay_color.a * (1.0 - pulse_strength + pulse_strength * 2.0 * pulse);

	// 边缘增亮：用 UV 距离中心的距离驱动，模拟"高处被光照"
	vec2 center = UV - vec2(0.5, 0.5);
	float dist = length(center);
	float rim = 1.0 - smoothstep(0.0, 0.7, dist);
	vec4 terrain = overlay_color;
	terrain.rgb *= 1.0 + 0.3 * rim;
	terrain.a = alpha * (0.7 + 0.3 * rim);

	COLOR = mix(base, terrain, terrain.a);
}
