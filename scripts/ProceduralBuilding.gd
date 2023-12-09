extends Node3D

func initialize(outer_points: PackedVector2Array, delta: float, bottom: float, top: float, 
		wall_mat: StandardMaterial3D, street_mat: StandardMaterial3D,
		radar_mat: StandardMaterial3D) -> void:
	# TODO: Offset poly here
	var inner_points = Geometry2D.offset_polygon(outer_points, delta, Geometry2D.JOIN_MITER)[0]
	# Make walls
	var walls: Array[MeshInstance3D] = GeometryHelper.make_walls(inner_points,
		bottom, top, wall_mat)
	for i in range(walls.size()):
		add_child(walls[i])
	# Make roof
	#var roof: Array[MeshInstance3D] = GeometryHelper.make_roof(inner_points,
		#top, mat)
	#for i in range(roof.size()):
		#add_child(roof[i])
	
	# Make street
	var street_polygon: PackedVector2Array = GeometryHelper.make_street_polygon(
		outer_points, inner_points)
	var tris = Geometry2D.triangulate_polygon(street_polygon)
	var street_meshes1: Array[MeshInstance3D] = GeometryHelper.create_mesh_from_triangulation(street_polygon, 
		tris, street_mat, bottom, true)
	#var street_meshes2: Array[MeshInstance3D] = street_meshes1
	var street_meshes2: Array[MeshInstance3D] = GeometryHelper.create_mesh_from_triangulation(street_polygon, 
		tris, radar_mat, bottom, false)
	for i in range(street_meshes1.size()):
		street_meshes1[i].set_layer_mask_value(1, true)
		street_meshes2[i].set_layer_mask_value(2, false)
		street_meshes2[i].set_layer_mask_value(3, false)
		add_child(street_meshes1[i])
	for i in range(street_meshes2.size()):
		#street_meshes2[i].set_surface_override_material(0, radar_mat)
		street_meshes2[i].set_layer_mask_value(1, false)
		street_meshes2[i].set_layer_mask_value(2, true)
		street_meshes2[i].set_layer_mask_value(3, true)
		add_child(street_meshes2[i])
