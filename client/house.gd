extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	$scientist/AnimationPlayer.get_animation("CameraAction").loop_mode = true
	$scientist/AnimationPlayer.get_animation("Action").loop_mode = true
	#$scientist/AnimationPlayer.play("CameraAction")
	#$scientist/AnimationPlayer.play("Action")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
