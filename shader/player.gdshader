shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
vec4 tex_color = texture(TEXTURE, UV);


// Mantém o personagem normal
COLOR = tex_color;

// Tamanho de 1 pixel da textura
vec2 pixel_size = 1.0 / vec2(textureSize(TEXTURE, 0));

// Alpha dos pixels ao redor
float surrounding_alpha = 0.0;

surrounding_alpha = max(surrounding_alpha,
	texture(TEXTURE, UV + vec2(-pixel_size.x,  0.0)).a);

surrounding_alpha = max(surrounding_alpha,
	texture(TEXTURE, UV + vec2( pixel_size.x,  0.0)).a);

surrounding_alpha = max(surrounding_alpha,
	texture(TEXTURE, UV + vec2( 0.0, -pixel_size.y)).a);

surrounding_alpha = max(surrounding_alpha,
	texture(TEXTURE, UV + vec2( 0.0,  pixel_size.y)).a);

surrounding_alpha = max(surrounding_alpha,
	texture(TEXTURE, UV + vec2(-pixel_size.x, -pixel_size.y)).a);

surrounding_alpha = max(surrounding_alpha,
	texture(TEXTURE, UV + vec2( pixel_size.x, -pixel_size.y)).a);

surrounding_alpha = max(surrounding_alpha,
	texture(TEXTURE, UV + vec2(-pixel_size.x,  pixel_size.y)).a);

surrounding_alpha = max(surrounding_alpha,
	texture(TEXTURE, UV + vec2( pixel_size.x,  pixel_size.y)).a);

// Só desenha o outline em áreas transparentes
if (tex_color.a < 0.1 && surrounding_alpha > 0.1) {
	COLOR = vec4(outline_color.rgb, surrounding_alpha * outline_color.a);
}


}
