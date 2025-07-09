vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 color_src = Texel(tex, texture_coords);
    float factor = 0.8;
	return vec4(
        mix(color_src.r, 0.9, factor),
        mix(color_src.g, 0.9, factor),
        mix(color_src.b, 0.9, factor),
        color_src.a
    );
}