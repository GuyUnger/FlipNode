shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

varying vec4 modulate;

uniform sampler2D goolash_boil_noise : repeat_enable;
uniform float goolash_frame;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	COLOR.rgb = modulate.rgb;
	vec2 uv = SCREEN_UV;
	
	COLOR.a = texture(screen_texture, SCREEN_UV).r;
	
}
