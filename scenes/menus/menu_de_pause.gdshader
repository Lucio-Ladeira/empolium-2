shader_type canvas_item;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    float pisca = step(0.4, sin(TIME * 7.0));

    tex.a *= pisca;

    COLOR = tex;
}
