shader_type canvas_item;
render_mode unshaded;
varying vec4 tinta;
void vertex() { tinta = COLOR; }
void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	float borda = 0.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			borda = max(borda, texture(TEXTURE, UV + vec2(float(x),float(y)) * TEXTURE_PIXEL_SIZE).a);
		}
	}
	COLOR = mix(vec4(0.0, 1.0, 1.0, borda), pixel, pixel.a) * tinta;
}
