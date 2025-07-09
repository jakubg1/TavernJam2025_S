vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 color_src = Texel(tex, texture_coords);
	return vec4(1, 1, 1, color_src.a);
}