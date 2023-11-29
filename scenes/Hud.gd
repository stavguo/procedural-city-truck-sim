extends CanvasLayer

@export var main: Node

func open_map():
	visible = false

func close_map():
	visible = true

# Called when the node enters the scene tree for the first time.
func _ready():
	#var timer = get_node("../../../../Poisson")
	#main.open_map.connect(open_map)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
