extends Node3D

func initialize(ground_points: PackedVector2Array, bottom: float, top: float) -> void:
	# Make building material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = GeometryHelper.get_random_color()
	mat.set_shading_mode(BaseMaterial3D.SHADING_MODE_UNSHADED)
	
	# Make walls
	var walls: Array[MeshInstance3D] = GeometryHelper.make_walls(ground_points,
		bottom, top, mat)
	for i in range(walls.size()):
		add_child(walls[i])

	# Make roof
	var roof: Array[MeshInstance3D] = GeometryHelper.make_roof(ground_points,
		top, mat)
	for i in range(roof.size()):
		add_child(roof[i])
