shader_type canvas_item;
render_mode blend_mix;

// ── Background depth-of-field + vignette + tonal wash ──────────────────
// Applies a 5-tap Gaussian blur, radial vignette darkening, and a subtle
// tint overlay.  Designed for 2D background TextureRects in Godot 4.
// Renderer: works on all renderers (no SCREEN_TEXTURE dependency).

uniform float blur_amount : hint_range(0.0, 4.0) = 1.5;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;
uniform vec4 tint_color : source_color = vec4(0.05, 0.08, 0.18, 0.30);

void fragment() {
	vec4 base = texture(TEXTURE, UV);

	// ── 5-tap cross-kernel blur ─────────────────────────────────────
	vec2 texel = TEXTURE_PIXEL_SIZE * blur_amount;
	vec4 blurred  = base * 0.4;
	blurred += texture(TEXTURE, UV + vec2( texel.x, 0.0)) * 0.15;
	blurred += texture(TEXTURE, UV + vec2(-texel.x, 0.0)) * 0.15;
	blurred += texture(TEXTURE, UV + vec2(0.0,  texel.y)) * 0.15;
	blurred += texture(TEXTURE, UV + vec2(0.0, -texel.y)) * 0.15;

	// ── Radial vignette ─────────────────────────────────────────────
	vec2 uv_centered = UV - 0.5;
	float vignette = 1.0 - dot(uv_centered, uv_centered) * vignette_strength * 2.0;
	vignette = clamp(vignette, 0.0, 1.0);

	// ── Composite ───────────────────────────────────────────────────
	vec4 result = blurred * vignette;
	result = mix(result, tint_color, tint_color.a);
	result.a = base.a;

	COLOR = result;
}
