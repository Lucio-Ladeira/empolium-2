shader_type canvas_item;

void fragment() {
    float alpha = texture(TEXTURE, UV).a;

    COLOR = vec4(
        alpha,
        0.0,
        0.0,
        alpha
    );
}