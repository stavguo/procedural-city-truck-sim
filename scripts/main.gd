extends Node
@export var building_scene: PackedScene
@export var max_radius: int = 25
@export var min_radius: int = 15
@export var points: int = 9
@export var min_area: int = 10
@export var offset_poly: float = -0.5
@export var floor_multiplier: float = 7.0
@export var min_floor_height: float = 10.0

@onready var mapView = $MapView

var fastNoiseLite = FastNoiseLite.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	create_fast_noise_lite()
	var vert_arr = get_init_points()
	var obb_arr = get_obb(vert_arr)
	subdivide(vert_arr, obb_arr)

func _input(event):
	if event.is_action_pressed("quit"):
		get_tree().quit()
	if event.is_action_pressed("regenerate"):
		get_tree().reload_current_scene()
	if event.is_action_pressed("screenshot"):
		var image = get_viewport().get_texture().get_image()
		image.save_png("screenshots/%s.png" % randi())
	# TODO: Create ortho birds-eye-view camera to switch to
	if event.is_action_pressed("map"):
		if mapView.current: mapView.current = false
		else: mapView.current = true

func create_fast_noise_lite():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	fastNoiseLite.seed = rng.randi_range(0, 500)
	fastNoiseLite.noise_type = FastNoiseLite.TYPE_SIMPLEX
	fastNoiseLite.fractal_gain = 1.0
	# TODO: Set fractal octives and gain = 0

func get_noise(vec: Vector2) -> float:
	var noise = (fastNoiseLite.get_noise_2dv(vec) + 1) / 2
	return max(int(noise * 10) * 10, min_floor_height)

func get_init_points():
	var rads = 0
	var vert_arr = PackedVector2Array()
	for i in range(points):
		var dist = randf_range(min_radius, max_radius)
		vert_arr.append(Vector2(cos(rads) * dist, sin(rads) * dist))
		rads -= ((2 * PI) / points)
	make_island(vert_arr)
	return vert_arr

func make_island(vert_arr: PackedVector2Array) -> void:
	var ground_points = Geometry2D.offset_polygon(vert_arr, -offset_poly, Geometry2D.JOIN_MITER)[0]
	# Make ground material 
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color('#ffeecc')
	mat.set_shading_mode(BaseMaterial3D.SHADING_MODE_UNSHADED)
	
	# Make ground
	var ground: Array[MeshInstance3D] = GeometryHelper.make_roof(ground_points,
		0.0, mat)
	for i in range(ground.size()):
		add_child(ground[i])
	var sides: Array[MeshInstance3D] = GeometryHelper.make_walls(ground_points,
		-5.0, 0.0, mat)
	for i in range(sides.size()):
		add_child(sides[i])

func get_rect_dimensions(vert_arr: PackedVector2Array):
	var top = -INF
	var bottom = INF
	var left = INF
	var right = -INF
	for i in range(vert_arr.size()):
		top = max(top, vert_arr[i].y)
		bottom = min(bottom, vert_arr[i].y)
		left = min(left, vert_arr[i].x)
		right = max(right, vert_arr[i].x)
	var w = right - left
	var h = top - bottom
	return {"left": left, "bottom": bottom, "top": top, "right": right, \
		"width": w, "height": h}

func polygon_to_rect(vert_arr: PackedVector2Array) -> Rect2:
	var rd = get_rect_dimensions(vert_arr)
	return Rect2(Vector2(rd.left, rd.bottom), \
		Vector2(abs(rd.width), abs(rd.height)))

func too_small(vert_arr: PackedVector2Array) -> bool:
	var current_rect = polygon_to_rect(vert_arr)
	return current_rect.get_area() < min_area

func get_rotated_vector(packed_vector_array: PackedVector2Array, \
	pivot: Vector2, angle_to_rotate: float):
	var rotated_vectors = PackedVector2Array()
	for i in range(packed_vector_array.size()):
		var vector = packed_vector_array[i]
		var diff = vector - pivot
		diff = diff.rotated(angle_to_rotate)
		diff += pivot
		rotated_vectors.append(diff)
	return rotated_vectors

func get_angle_to_rotate(vert_arr: PackedVector2Array, pivot_index: int) -> float:
	var next = vert_arr[(pivot_index + 1) % vert_arr.size()]
	return -atan2(next.y - vert_arr[pivot_index].y, next.x - vert_arr[pivot_index].x)

func get_obb(vert_arr: PackedVector2Array):
	var min_rect = INF
	var bounding_box: PackedVector2Array
	var obb_pivot: int
	var obb_angle: float
	for pivot in range(vert_arr.size()):
		var angle = get_angle_to_rotate(vert_arr, pivot)
		var rot = get_rotated_vector(vert_arr, vert_arr[pivot], angle)
		var rd = get_rect_dimensions(rot)
		var current_rect = Rect2(Vector2(rd.left, rd.bottom), \
			Vector2(abs(rd.width), abs(rd.height)))
		if current_rect.get_area() < min_rect:
			min_rect = current_rect.get_area()
			bounding_box = PackedVector2Array([
				current_rect.position,
				Vector2(current_rect.position.x, current_rect.end.y),
				current_rect.end,
				Vector2(current_rect.end.x, current_rect.position.y)
			])
			obb_pivot = pivot
			obb_angle = angle
	var angle_n = -obb_angle
	var final_rot = get_rotated_vector(bounding_box, vert_arr[obb_pivot], angle_n)
	return final_rot

func split_polygon(vert_arr: PackedVector2Array, obb_arr: PackedVector2Array):
	var midpoints = []
	for i in range(obb_arr.size()):
		var v1 = obb_arr[i]
		var v2 = obb_arr[(i + 1) % obb_arr.size()]
		midpoints.append((v1 + v2) / 2)
	var first_half
	var second_half
	if midpoints[0].distance_to(midpoints[2]) < midpoints[1].distance_to(midpoints[3]):
		first_half = PackedVector2Array([obb_arr[0], midpoints[0], midpoints[2], obb_arr[3]])
		second_half = PackedVector2Array([midpoints[0], obb_arr[1], obb_arr[2], midpoints[2]])
	else:
		first_half = PackedVector2Array([obb_arr[0], obb_arr[1], midpoints[1], midpoints[3]])
		second_half = PackedVector2Array([midpoints[1], obb_arr[2], obb_arr[3], midpoints[3]])
	return {
		"p1": Geometry2D.intersect_polygons(vert_arr, first_half)[0],
		"p2": Geometry2D.intersect_polygons(vert_arr, second_half)[0]
	}

func subdivide(vert_arr: PackedVector2Array, obb_arr: PackedVector2Array):
	var split_data = split_polygon(vert_arr, obb_arr)
	var obb_arr1 = get_obb(split_data.p1)
	var obb_arr2 = get_obb(split_data.p2)
	if too_small(obb_arr1) or too_small(obb_arr2):
		var offset_arr = Geometry2D.offset_polygon(vert_arr, offset_poly, Geometry2D.JOIN_MITER)
		var building = building_scene.instantiate()
		var center = polygon_to_rect(obb_arr).get_center()
		building.initialize(offset_arr[0], 0.0, get_noise(center),
			GeometryHelper.get_random_color())
		add_child(building)
	else:
		subdivide(split_data.p1, obb_arr1)
		subdivide(split_data.p2, obb_arr2)
