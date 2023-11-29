shader_type canvas_item;

uniform float radius;

void fragment() {
	// Calculate the distance from the center of the viewport to the current fragment
	vec2 center = vec2(0.5, 0.5); // Center of the viewport
	vec2 local_cords = (UV - center); // Adjust for aspect ratio
	float distance = length(local_cords);
	
	// Define the radius of the circle (0.5 for a circle that fits within viewport)
	float circleRadius = radius / float(2);
	
	// Discard fragments outside of the circle
	if (distance > circleRadius) {
		discard;
	}
}
