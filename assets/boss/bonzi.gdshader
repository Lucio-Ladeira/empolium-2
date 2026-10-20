shader_type canvas_item;
void fragment() {
 vec4 pixel = texture(TEXTURE, UV);
 // A imagem original tem fundo branco; chave aplicada apenas neste sprite.
 float branco = min(pixel.r,min(pixel.g,pixel.b));
 pixel.a *= 1.0-smoothstep(0.94,0.99,branco);
 COLOR *= pixel;
}
