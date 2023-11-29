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
		
		# Bottom left?
		surface_tool.set_normal(Vector3(1, 1, 1))
		surface_tool.set_uv(Vector2(0,1))
		surface_tool.add_vertex(Vector3(first.x, bottom, first.y))
		
		# Bottom right?
		surface_tool.set_normal(Vector3(1, 1, 1))
		surface_tool.set_uv(Vector2(1,1))
		surface_tool.add_vertex(Vector3(second.x, bottom, second.y))
		
		# Top right?
		surface_tool.set_normal(Vector3(1, 1, 1))
		surface_tool.set_uv(Vector2(1,0))
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

static func make_roof(ground_points: PackedVector2Array, height: float,
	mat: StandardMaterial3D) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	var tris = Geometry2D.triangulate_polygon(ground_points)
	for i in range(0, tris.size(), 3):
		var surface_tool = SurfaceTool.new();
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES);
		surface_tool.set_material(mat)
		
		var first = ground_points[tris[i]]
		var second = ground_points[tris[i + 1]]
		var third = ground_points[tris[i+ 2]]
		
		surface_tool.set_normal(Vector3(1, 1, 1));
		surface_tool.add_vertex(Vector3(first.x, height, first.y));
		
		surface_tool.set_normal(Vector3(1, 1, 1));
		surface_tool.add_vertex(Vector3(second.x, height, second.y));
		
		surface_tool.set_normal(Vector3(1, 1, 1));
		surface_tool.add_vertex(Vector3(third.x, height, third.y));
		
		surface_tool.add_index(0);
		surface_tool.add_index(1);
		surface_tool.add_index(2);
		
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.mesh = surface_tool.commit()
		mesh_inst.create_trimesh_collision()
		meshes.append(mesh_inst)
	return meshes

static func make_building_radar_object(ground_points: PackedVector2Array,
		height: int, mat: StandardMaterial3D) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	var tris = Geometry2D.triangulate_polygon(ground_points)
	for i in range(0, tris.size(), 3):
		var surface_tool = SurfaceTool.new();
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES);
		surface_tool.set_material(mat)
		
		var first = ground_points[tris[i]]
		var second = ground_points[tris[i + 1]]
		var third = ground_points[tris[i+ 2]]
		
		surface_tool.set_normal(Vector3(1, 1, 1));
		surface_tool.add_vertex(Vector3(first.x, height, first.y));
		
		surface_tool.set_normal(Vector3(1, 1, 1));
		surface_tool.add_vertex(Vector3(second.x, height, second.y));
		
		surface_tool.set_normal(Vector3(1, 1, 1));
		surface_tool.add_vertex(Vector3(third.x, height, third.y));
		
		surface_tool.add_index(0);
		surface_tool.add_index(1);
		surface_tool.add_index(2);
		
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.mesh = surface_tool.commit()
		mesh_inst.set_layer_mask_value(2, true)
		mesh_inst.set_layer_mask_value(3, true)
		meshes.append(mesh_inst)
	return meshes
