shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D full_mask : filter_nearest, repeat_disable;
uniform sampler2D visible_mask : filter_nearest, repeat_disable;
uniform vec4 outline_color : source_color = vec4(0.1, 0.9, 1.0, 1.0);
uniform int width_px : hint_range(1, 4) = 2;
uniform int debug_view : hint_range(0, 3) = 0;

float full_at(vec2 uv) {
	if (any(lessThan(uv, vec2(0.0))) ||
		any(greaterThanEqual(uv, vec2(1.0)))) {
		return 0.0;
	}
	return texture(full_mask, uv).r;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 pixel = 1.0 / vec2(textureSize(full_mask, 0));
	float a = full_at(uv);
	float v = texture(visible_mask, uv).r;
	float hidden = max(a - v, 0.0);
	float edge = 0.0;
	if (a > 0.001) {
		float eroded = a;
		for (int y = -4; y <= 4; y++) {
			for (int x = -4; x <= 4; x++) {
				if (abs(x) <= width_px && abs(y) <= width_px) {
					eroded = min(eroded, full_at(uv + vec2(float(x), float(y)) * pixel));
				}
			}
		}
		edge = max(a - eroded, 0.0);
	}
	float hidden_fraction = clamp(hidden / max(a, 0.0001), 0.0, 1.0);
	COLOR = vec4(outline_color.rgb, outline_color.a * edge * hidden_fraction);
	if (debug_view == 1) {
		COLOR = vec4(vec3(a), 1.0);
	} else if (debug_view == 2) {
		COLOR = vec4(vec3(v), 1.0);
	} else if (debug_view == 3) {
		COLOR = vec4(vec3(hidden), 1.0);
	}
}
