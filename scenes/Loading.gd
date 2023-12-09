extends Node2D

var progress: Array = []
var scene_name: String
var scene_load_status: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	scene_name = "res://scenes/Poisson.tscn"
	ResourceLoader.load_threaded_request(scene_name)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	scene_load_status = ResourceLoader.load_threaded_get_status(scene_name, progress)
	$CanvasLayer/Label.text = str(floor(progress[0] * 100)) + "%"
	if scene_load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var new_scene = ResourceLoader.load_threaded_get(scene_name)
