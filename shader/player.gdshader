shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 silhouette_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);


void fragment() {
    vec4 screen_color = textureLod(screen_texture, SCREEN_UV, 0.0);
    vec4 tex_color = texture(TEXTURE, UV);

    COLOR = tex_color;

    if (screen_color.r < 0.9) {
        COLOR.rgb = silhouette_color.rgb;
    }
}