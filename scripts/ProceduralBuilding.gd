extends Node3D

func initialize(ground_points: PackedVector2Array, bottom: float, top: float, 
		mat: StandardMaterial3D) -> void:
	
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
