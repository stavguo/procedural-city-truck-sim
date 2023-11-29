extends Camera3D

@export var _followScanRadius: float

@export var _playerTarget: NodePath
@onready var _target = get_node(_playerTarget)

@export var _playerRotationTarget: NodePath
@onready var _targetRotation = get_node(_playerRotationTarget)

# Called when the node enters the scene tree for the first time.
func _ready():
	size = _followScanRadius

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# For now, camera height is floor height times max floors
	position = Vector3(_target.position.x, 50, _target.position.z)
	rotation_degrees.y = _targetRotation.rotation_degrees.y
