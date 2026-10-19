shader_type canvas_item;
void fragment() {
	vec4 arte = texture(TEXTURE, UV);
	vec2 pixel = UV / TEXTURE_PIXEL_SIZE;
	// Recolore somente os glifos escuros do percentual, sem alterar a imagem.
	if (pixel.x >= 480.0 && pixel.x < 720.0 && pixel.y < 64.0
		&& max(max(arte.r, arte.g), arte.b) < 0.2) {
		arte.rgb = vec3(1.0);
	}
	COLOR = arte;
}

