shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float scanline_strength : hint_range(0.0, 0.2) = 0.075;
uniform float chromatic_shift_pixels : hint_range(0.0, 2.0) = 0.8;
uniform float vignette_strength : hint_range(0.0, 0.25) = 0.12;
uniform float transition_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 channel_offset = vec2(SCREEN_PIXEL_SIZE.x * chromatic_shift_pixels, 0.0);
	vec3 color = vec3(
		texture(screen_texture, uv + channel_offset).r,
		texture(screen_texture, uv).g,
		texture(screen_texture, uv - channel_offset).b
	);

	float scanline = 1.0 - scanline_strength * (0.5 + 0.5 * sin(uv.y / SCREEN_PIXEL_SIZE.y * 3.14159265));
	float edge = smoothstep(0.35, 0.95, length((uv - vec2(0.5)) * 2.0));
	color *= scanline * (1.0 - vignette_strength * edge);

	float beam_height = mix(0.49, SCREEN_PIXEL_SIZE.y * 1.5, transition_amount);
	float beam = 1.0 - smoothstep(beam_height, beam_height + SCREEN_PIXEL_SIZE.y * 2.0, abs(uv.y - 0.5));
	color = mix(color, vec3(0.004, 0.008, 0.018), transition_amount);
	color += vec3(0.08, 0.72, 0.95) * beam * transition_amount * 0.7;
	COLOR = vec4(color, 1.0);
}
