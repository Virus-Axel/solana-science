extends Node3D

var books
var amount = 0

var books_in_shelf = 0

const start_pos = Vector3(0.8, 0.0, 5.0)
var start_rot
var ANIMATION_TIME = 1.0
const ROTATION_STRENGTH = 10.0
var goal
var is_adding = false

var time = 0.0

func create_anim_book(book):
	$AnimBook.queue_free()
	remove_child($AnimBook)
	var new_book = book.duplicate()
	add_child(new_book)
	new_book.name = "AnimBook"
	$AnimBook.position = start_pos
	$AnimBook.visible = true

func add_book_to_shelf():
	var index = randi_range(0, books.size() - 2)
	if books.size() <= 1:
		process_mode = Node.PROCESS_MODE_DISABLED
		return

	goal = books[index]
	create_anim_book(goal)
	ANIMATION_TIME = randf_range(0.8, 1.2)
	start_rot = Vector3(randf_range(-ROTATION_STRENGTH, ROTATION_STRENGTH), randf_range(-ROTATION_STRENGTH, ROTATION_STRENGTH), randf_range(-ROTATION_STRENGTH, ROTATION_STRENGTH))
	#books[index].visible = true
	books_in_shelf += 1
	is_adding = true

# Called when the node enters the scene tree for the first time.
func _ready():
	books = get_children()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_adding:
		time += delta
		if time > ANIMATION_TIME:
			is_adding = false
			time = 0.0
			goal.visible = true
			books.erase(goal)
			print(books.size())
			$AnimBook.position = start_pos
		else:
			var new_pos = lerp(start_pos, goal.position, time / ANIMATION_TIME)
			var new_rot = lerp(start_rot, goal.rotation, time / ANIMATION_TIME)
			$AnimBook.position = new_pos
			$AnimBook.rotation = new_rot
	elif amount > books_in_shelf:
		add_book_to_shelf()
