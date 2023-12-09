class_name GeometryHelper

static func get_random_color() -> Color:
	var colors = [
		'#46425e',
		'#15788c',
		'#00b9be',
		'#ffb0a3',
		'#ff6973'
	]
	return Color(colors[randi() % colors.size()])

static func make_walls(ground_points: PackedVector2Array, bottom: float, 
		top: float, mat: StandardMaterial3D) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	# loop through each wall
	for i in range(ground_points.size()):
		var first = ground_points[i]
		var second = ground_points[(i + 1) % ground_points.size()]
		
		var surface_tool = SurfaceTool.new();
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		surface_tool.set_material(mat)
		
		var uv_width = first.distance_to(second) / 5
		var uv_height = (top - bottom) / 5
		
		# Bottom left?
		surface_tool.set_normal(Vector3(1, 1, 1))
		surface_tool.set_uv(Vector2(0, uv_height))
		surface_tool.add_vertex(Vector3(first.x, bottom, first.y))
		
		# Bottom right?
		surface_tool.set_normal(Vector3(1, 1, 1))
		surface_tool.set_uv(Vector2(uv_width, uv_height))
		surface_tool.add_vertex(Vector3(second.x, bottom, second.y))
		
		# Top right?
		surface_tool.set_normal(Vector3(1, 1, 1))
		surface_tool.set_uv(Vector2(uv_width,0))
		surface_tool.add_vertex(Vector3(second.x, top, second.y))
		
		# Top left?
		surface_tool.set_normal(Vector3(1, 1, 1))
		surface_tool.set_uv(Vector2(0,0))
		surface_tool.add_vertex(Vector3(first.x, top, first.y))
		
		surface_tool.add_index(0)
		surface_tool.add_index(1)
		surface_tool.add_index(2)
		
		surface_tool.add_index(0)
		surface_tool.add_index(2)
		surface_tool.add_index(3)
		
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.mesh = surface_tool.commit()
		mesh_inst.create_trimesh_collision()
		meshes.append(mesh_inst)
	return meshes

static func create_mesh_from_triangulation(points: PackedVector2Array, 
	tris: Array[int], mat: StandardMaterial3D, height: float, col: bool) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	
	var surface_tool = SurfaceTool.new()
	for i in range(0, tris.size(), 3):
		
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface_tool.set_material(mat)
		
		var first = points[tris[i]]
		var second = points[tris[i + 1]]
		var third = points[tris[i+ 2]]
		
		surface_tool.set_normal(Vector3(1, 1, 1))
		surface_tool.add_vertex(Vector3(first.x, height, first.y))
		
		surface_tool.set_normal(Vector3(1, 1, 1))
		surface_tool.add_vertex(Vector3(second.x, height, second.y))
		
		surface_tool.set_normal(Vector3(1, 1, 1))
		surface_tool.add_vertex(Vector3(third.x, height, third.y))
		
#		surface_tool.add_index(0);
#		surface_tool.add_index(1);
#		surface_tool.add_index(2);
		surface_tool.index()
		
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.mesh = surface_tool.commit()
		if col:
			mesh_inst.create_trimesh_collision()
		meshes.append(mesh_inst)
	return meshes

static func make_street_polygon(outer_points: PackedVector2Array,
	inner_points: PackedVector2Array) -> PackedVector2Array:
	# initialize closest_inner_index
	var closest_inner_index: int = 0
	# for every point in inner boundary
	for i in range(inner_points.size()):
		# store min AND idx in closest_inner_point
		if outer_points[0].distance_to(inner_points[i]) < \
			outer_points[0].distance_to(inner_points[closest_inner_index]):
			closest_inner_index = i
	# initialize closest_inner_point
	var closest_inner_point: Vector2 = outer_points[closest_inner_index]
	# Add repeat of first outer boundary point for polygon formation
	outer_points.append(outer_points[0])
	# TODO: Verify order of inner boundary, could be counter clockwise
	for i in range(closest_inner_index, closest_inner_index - 
		(inner_points.size() + 1), -1):
		# Append point to outer_points (using modulo)
		outer_points.append(inner_points[i % inner_points.size()])
	# return Array[MeshInstance3D] of triangulation
	return outer_points
