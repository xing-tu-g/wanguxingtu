
// terrain_river.gdshader
// 河流地形：蓝色叠加 + 水平波纹 UV 偏移动画
// 适用 renderer：Forward+ / Mobile / Compatibility
shader_type canvas_item;

uniform vec4 overlay_color : source_color = vec4(0.25, 0.45, 0.70, 0.40);
uniform float wave_speed : hint_range(0.0, 3.0) = 0.8;
uniform float wave_frequency : hint_range(1.0, 20.0) = 8.0;
uniform float wave_amplitude : hint_range(0.0, 0.1) = 0.03;

void fragment() {
	vec2 uv = UV;

	// 水平波纹：沿 X 方向做正弦 UV 偏移，模拟水流
	float wave = sin(uv.y * wave_frequency + TIME * wave_speed) * wave_amplitude;
	uv.x += wave;

	vec4 base = texture(TEXTURE, uv);

	// 用 UV.y 驱动颜色深浅变化，模拟水流明暗
	float flow = 0.5 + 0.5 * sin(uv.y * wave_frequency * 0.5 + TIME * wave_speed * 1.2);
	vec4 terrain = mix(overlay_color * 0.8, overlay_color * 1.2, flow);
	terrain.a = overlay_color.a * (0.6 + 0.4 * flow);

	COLOR = mix(base, terrain, terrain.a);
}
