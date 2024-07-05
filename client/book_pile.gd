extends Node3D

var books_in_pile = 0

const start_pos = Vector3(0.0, 5.0, 0.0)
var start_rot
var ANIMATION_TIME = 1.0
const ROTATION_STRENGTH = 20.0
var goal
var is_adding = false

var time = 0.0
var amount = 0


func add_book_to_pile():
	$AnimBook.position = start_pos
	var index = books_in_pile
	var books = get_children()
	if books[-2].visible:
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	goal = books[index]
	ANIMATION_TIME = randf_range(0.8, 1.2)
	start_rot = Vector3(randf_range(-ROTATION_STRENGTH, ROTATION_STRENGTH), randf_range(-ROTATION_STRENGTH, ROTATION_STRENGTH), randf_range(-ROTATION_STRENGTH, ROTATION_STRENGTH))
	#books[index].visible = true
	books_in_pile += 1
	is_adding = true
	

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_adding:
		time += delta
		print(time)
		if time > ANIMATION_TIME:
			is_adding = false
			time = 0.0
			goal.visible = true
			$AnimBook.position = start_pos
			get_parent().get_node("AudioStreamPlayer").play()
		else:
			var new_pos = lerp(start_pos, goal.position, time / ANIMATION_TIME)
			var new_rot = lerp(start_rot, goal.rotation, time / ANIMATION_TIME)
			$AnimBook.position = new_pos
			$AnimBook.rotation = new_rot
	elif amount > books_in_pile:
		add_book_to_pile()

