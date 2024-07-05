extends Node3D

var pr = 0.00
var last_time = 0
var going_down = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	$scientist/AnimationPlayer.get_animation("CameraAction").loop_mode = true
	$scientist/AnimationPlayer.get_animation("Action").loop_mode = true
	$progress/AnimationPlayer.play("Animation")
	$progress/AnimationPlayer.get_animation("Animation").loop_mode = true
	$progress/AnimationPlayer.speed_scale = 2.0
	#$scientist/AnimationPlayer.play("CameraAction")
	#$scientist/AnimationPlayer.play("Action")

func set_read_progress(progress :float):
	$progress_bar/Cylinder.set_blend_shape_value(0, 1.0 - progress)


func _on_ui_start_read(last_time):
	if going_down:
		return
	going_down = true
	set_read_progress(0.0)
	$AnimationPlayer.play("down")
	$AnimationPlayer.seek(0.1, true)
	$progress.visible = true
	$progress_bar.visible = true
	$stop_timer.wait_time = last_time
	$stop_timer.start()
	$Timer.start()
	_on_timer_timeout()


func _on_ui_stop_read():
	if not going_down:
		return
	going_down = false
	$AnimationPlayer.play_backwards("down")
	$Ui.is_reading = false
	$Ui.update_reading_anim()
	#$progress.visible = false
	#$progress_bar.visible = false
	$Timer.stop()


func _on_timer_timeout():
	var where = float($Ui.TIME_TO_READ_BOOK) - $stop_timer.time_left
	var progress = where / float($Ui.TIME_TO_READ_BOOK)

	set_read_progress(progress)


func _on_audio_stream_player_3_finished():
	$AudioStreamPlayer3.play()
