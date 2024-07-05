extends Control

const GAME_PRICE = 10.0
const LAMPORTS_PER_SOL = 1000000000
const SAVES_DIR = "user://"

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	#show_naming()
	$AnimationPlayer.play("new_animation")
	var wallets = $WalletAdapter.get_available_wallets()
	$VBoxContainer2/OptionButton.set_item_disabled(0, not 0 in wallets)
	$VBoxContainer2/OptionButton.set_item_disabled(1, not 1 in wallets)
	$VBoxContainer2/OptionButton.set_item_disabled(2, not 2 in wallets)
	
	if not wallets.is_empty():
		$VBoxContainer2/OptionButton.select(wallets[0])


func show_naming():
	$Panel.visible = true
	modulate.r = 0.2
	modulate.g = 0.2
	modulate.b = 0.2
	
func remove_naming():
	$Panel.visible = false
	modulate.r = 1.0
	modulate.g = 1.0
	modulate.b = 1.0
	
func show_load():
	$Panel2.visible = true
	modulate.r = 0.2
	modulate.g = 0.2
	modulate.b = 0.2

func remove_load():
	$Panel2.visible = false
	modulate.r = 1.0
	modulate.g = 1.0
	modulate.b = 1.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_8_pressed():
	$WalletAdapter.connect_wallet()
	var ut = Time.get_unix_time_from_system()
	var timestamp = Time.get_datetime_string_from_unix_time(ut)
	await $WalletAdapter.connection_established
	
	show_naming()
	

func show_load_files():
	$Panel2/ItemList.clear()
	var dir = DirAccess.open(SAVES_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				pass
			else:
				if file_name.ends_with(".json"):
					var sci_name = file_name.substr(0, file_name.length() - 5)
					$Panel2/ItemList.add_item(sci_name)

			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	$Panel2/Button9.disabled = true
	show_load()


func _on_button_9_pressed():
	var payer = Keypair.new_random()
	var scientist_name = $Panel/LineEdit.text
	payer.save_to_file(SAVES_DIR + scientist_name + ".json")

	$Panel/Transaction.set_payer($WalletAdapter)
	
	var ix = SystemProgram.transfer($WalletAdapter, payer, GAME_PRICE * LAMPORTS_PER_SOL)

	print(payer.get_public_string())

	$Panel/Transaction.set_instructions([ix])
	$Panel/Transaction.update_latest_blockhash()
	
	$Panel/Transaction.sign_and_send()
	
	await $Panel/Transaction.confirmed
	print("RES")
	
	var new_scene = load("res://house.tscn").instantiate()
	get_tree().root.add_child(new_scene)
	new_scene.get_node("Ui/Control").scientist_name = scientist_name
	new_scene.get_node("Ui").init(payer)
	get_node("/root/TitleScreen").queue_free()


func _on_button_10_pressed():
	var file_name = $Panel2/ItemList.get_item_text($Panel2/ItemList.get_selected_items()[0])
	var kp = Keypair.new_from_file(SAVES_DIR + file_name + ".json")
	
	var new_scene = load("res://house.tscn").instantiate()
	get_tree().root.add_child(new_scene)
	new_scene.get_node("Ui").load_key(kp)
	get_node("/root/TitleScreen").queue_free()


func _on_item_list_item_selected(index):
	$Panel2/Button9.disabled = false
	pass # Replace with function body.
