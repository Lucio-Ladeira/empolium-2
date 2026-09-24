shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform float mask_value : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	// COLOR.a ja inclui a textura e a modulacao do CanvasItem.
	COLOR = vec4(vec3(mask_value), COLOR.a);
}
