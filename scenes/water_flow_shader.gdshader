shader_type canvas_item;

uniform vec2 flow_speed = vec2(0.0, 0.2); // Adjust X and Y speed of the current

void fragment() {
    // Continuously shifts the texture coordinates over time
    vec2 scrolled_uv = UV + flow_speed * TIME;
    COLOR = texture(TEXTURE, scrolled_uv);
}