extends Node
signal open_map
signal close_map

@export var building_scene: PackedScene
@export var car_scene: PackedScene

@export var poisson_width: int = 1200
@export var poisson_height: int = 1200
@export var poisson_radius: int = 200
@export var poisson_retries: int = 30
@export var min_area: int = 7200
@export var offset_poly: float = -10
@export var floor_height: int = 5
@export var min_floors: int = 2
@export var max_floors: int = 7
@export var land_water_ratio: float = 0.8

@onready var mapView = $MapView

var fastNoiseLite
var delaunay
var street_mat
var radar_mat
var building_mats: Array[StandardMaterial3D] = []
var spawn_locations: Array[PackedVector2Array] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	mapView.position.x = poisson_width / 2
	mapView.position.z = poisson_height / 2
	mapView.set_size(poisson_height)
	
	create_mats()
	create_random_generator()
	create_points()
	var spawn_pos = spawn_locations[randi_range(0,spawn_locations.size() - 1)]
	var mid = midpoint(spawn_pos[0], spawn_pos[1])
	var car = car_scene.instantiate()
	car.set_position(Vector3(mid.x,2,mid.y))
	add_child(car)
	open_map.connect($Car/Hud.open_map.bind())
	close_map.connect($Car/Hud.close_map.bind())

func _input(event):
	if event.is_action_pressed("quit"):
		get_tree().quit()
	if event.is_action_pressed("regenerate"):
		get_tree().reload_current_scene()
	if event.is_action_pressed("screenshot"):
		var image = get_viewport().get_texture().get_image()
		image.save_png("screenshots/%s.png" % randi())
	if event.is_action_pressed("map"):
		if mapView.current:
			close_map.emit()
			mapView.current = false
		else:
			open_map.emit()
			mapView.current = true

func create_mats():
	# make street layer1
	street_mat = StandardMaterial3D.new()
	street_mat.albedo_color = Color('#424245')
	street_mat.set_shading_mode(BaseMaterial3D.SHADING_MODE_UNSHADED)
	# make street layer2
	radar_mat = StandardMaterial3D.new()
	radar_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	radar_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.5)
	radar_mat.set_shading_mode(BaseMaterial3D.SHADING_MODE_UNSHADED)
	# Make building material
	var mat = StandardMaterial3D.new()
	#mat.albedo_color = GeometryHelper.get_random_color()
	var img = Image.load_from_file(ProjectSettings.globalize_path("res://assets/materials/buildings/prentis.png"))
	var tex = ImageTexture.create_from_image(img)
	#tex.set_size_override(Vector2i(512,512))
	mat.set_texture(BaseMaterial3D.TEXTURE_ALBEDO, tex)
	mat.set_flag(BaseMaterial3D.FLAG_USE_TEXTURE_REPEAT, true)
	mat.set_texture_filter(BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS)
	#mat.set_shading_mode(BaseMaterial3D.SHADING_MODE_UNSHADED)
	building_mats.append(mat)

func create_points():
	var rect = Rect2(0,0,poisson_width,poisson_height)
	delaunay = Delaunay.new(rect)
	var corners = PackedVector2Array([
		Vector2(0, poisson_height),
		Vector2(0, 0),
		Vector2(poisson_width, 0),
		Vector2(poisson_width, poisson_height)
	])
	var points: Array = PoissonDiscSampling.generate_points_for_polygon(corners,
		poisson_radius, poisson_retries)
	for i in range(points.size()):
		delaunay.add_point(points[i])
	var triangles = delaunay.triangulate()
	var sites = delaunay.make_voronoi(triangles)
	sites = sites.filter(remove_border_site)
	sites.sort_custom(sort_descending_noise)
	var islands_made: int = 0
	for site in sites:
		if islands_made < land_water_ratio * sites.size():
			islands_made += 1
			create_voronoi_site(site.polygon)

func remove_border_site(site: Delaunay.VoronoiSite) -> bool:
	return !delaunay.is_border_site(site)

func sort_descending_noise(a: Delaunay.VoronoiSite, b: Delaunay.VoronoiSite) ->bool:
	return fastNoiseLite.get_noise_2dv(a.center) > fastNoiseLite.get_noise_2dv(b.center)

func create_voronoi_site(polygon: PackedVector2Array) -> void:
	var obb_arr = get_obb(polygon)
	subdivide(polygon, obb_arr)

func create_random_generator():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	fastNoiseLite = FastNoiseLite.new()
	fastNoiseLite.seed = rng.randi_range(0,500)
	fastNoiseLite.noise_type = FastNoiseLite.TYPE_SIMPLEX
	fastNoiseLite.set_frequency(0.0005)

func midpoint(p1: Vector2, p2: Vector2) -> Vector2:
	return (p1 + p2) / 2

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
		# Add new spawn locations
		for i in range(vert_arr.size()):
			spawn_locations.append(PackedVector2Array([vert_arr[i],
				vert_arr[(i + 1) % vert_arr.size()]]))
		var building = building_scene.instantiate()
		building.initialize(vert_arr, offset_poly, 0.0,
			floor_height * randi_range(min_floors, max_floors), building_mats[0],
			street_mat, radar_mat)
		add_child(building)
	else:
		subdivide(split_data.p1, obb_arr1)
		subdivide(split_data.p2, obb_arr2)
