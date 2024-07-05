extends Control

var PID = "Bp7LbjQdrAGGQft9TyJYiGvmKP6NzHZvvD35wiW12FMQ"
var scientist = "5pnJmbAtTj6sBmEFttUyYLnpHMUdLubTM3fnstLxZX2j"
var payer;

const TIME_TO_READ_BOOK = 120
const TIME_PER_IDEA = 5.0

var UI_bid = 0
var custom_data = {}

var is_reading

func update_reading_anim():
	if $Control.has_any_books() and not is_reading and not $Button7/AnimationPlayer.is_playing():
		play_read()
		$Button7.disabled = false
	else:
		$Button7/AnimationPlayer.stop()
		$Button7.disabled = true

func set_total_read(total):
	get_parent().get_node("ShelfBooks").amount = total

func set_is_reading():
	is_reading = true
	update_reading_anim()

func set_is_not_reading():
	is_reading = false
	update_reading_anim()

func update_books():
	var balances = await $Control.get_token_balances()

	if balances[0] is int:
		set_decent_books(balances[0])
	if balances[1] is int:
		set_interesting_books(balances[1])
	if balances[2] is int:
		set_fascinating_books(balances[2])

func calculate_ideas() -> int:
	if custom_data.is_empty():
		return 0
	var total_books = int(custom_data["Published Decent Books"]) + int(custom_data["Published Interesting Books"]) + int(custom_data["Published Fascinating Books"])
	var correction = int(custom_data["Book Score"]) / TIME_PER_IDEA
	var timestamp = max(Time.get_unix_time_from_system(), float(custom_data["Last Modified"]))
	var delta_time = float(timestamp) - float(custom_data["Last Modified"])
	var rest_ideas = maxf(0.0, float(delta_time) / TIME_PER_IDEA)
	return 0.0 - total_books + rest_ideas + correction
	

func parse_custom_data(data: PackedByteArray) -> Dictionary:
	const TIME_OFFSET = 302
	var data_slice = data.slice(TIME_OFFSET)
	var i = 0;
	var ret = {}
	
	var name_size = data_slice.decode_u32(i)
	i += 4
	var val = data_slice.slice(i, i + name_size).get_string_from_ascii()
	ret["name"] = val
	i += name_size
	set_token_name(val)
	
	var symbol_size = data_slice.decode_u32(i)
	i += 4
	val = data_slice.slice(i, i + symbol_size).get_string_from_ascii()
	ret["symbol"] = val
	i += symbol_size
	
	var uri_size = data_slice.decode_u32(i)
	i += 4
	val = data_slice.slice(i, i + uri_size).get_string_from_ascii()
	ret["uri"] = val
	i += 4 + uri_size
	
	while i < data_slice.size():
		var key_size = data_slice.decode_u32(i)
		i += 4
		var key: String = data_slice.slice(i, i + key_size).get_string_from_ascii()
		i += key_size
		var value_size = data_slice.decode_u32(i)
		i += 4
		var value = data_slice.slice(i, i + value_size).get_string_from_ascii()
		i += value_size;
		
		ret[key] = value

	if custom_data.has("Last Modified"):
		if Time.get_unix_time_from_system() < float(custom_data["Last Modified"]):
			set_is_reading()
		else:
			set_is_not_reading()

	return ret

func set_ideas(ideas: int):
	$Panel/Label.text = str(ideas)
	if ideas <= 0:
		$Panel/Button8.disabled = true
	else:
		$Panel/Button8.disabled = false

func set_book_score(score: int):
	pass
	#$Label5.text = "Book Score: " + str(score)
	
func set_experience(score: float):

	const MAX_LEVEL = 10.0
	var normalized_exp = score / MAX_LEVEL

	var logarithmic_exp = log(1.0 + normalized_exp)

	var level = int(logarithmic_exp * MAX_LEVEL)
	var progression = (logarithmic_exp) * MAX_LEVEL - level

	$Label10.text = "Lvl: " + str(level)
	$Label10/ProgressBar.value = 100.0 * progression
	
	
func set_published_decent(amount: int):
	get_parent().get_node("BookPile").amount = amount

func set_published_interesting(amount: int):
	get_parent().get_node("BookPile2").amount = amount

func set_published_fascinating(amount: int):
	get_parent().get_node("BookPile3").amount = amount

func set_sale_item(item: Pubkey):
	$BookIconPicker.set_icon(item)

func set_item_price(price: int):
	$Button.text = "Bid " + str(price + 100)
	UI_bid = price + 100
	$BookIconPicker/Label.text = str(price)
	$Button6/Label4.text = str(UI_bid)

func show_network_error():
	$Label6.visible = true
	

func set_token_name(name: String):
	$Label11.text = name

func set_cash(cash: int):
	$HBoxContainer2/Label4.text = "x" + str(cash)
	$Label3.text = "Cash: " + str(cash)

func set_decent_books(amount: int):
	$Control.db_amount = amount
	$HBoxContainer/Label4.text = "x" + str(amount)
	update_reading_anim()

func set_interesting_books(amount: int):
	$Control.ib_amount = amount
	$HBoxContainer/Label6.text = "x" + str(amount)
	update_reading_anim()

func set_fascinating_books(amount: int):
	$Control.fb_amount = amount
	$HBoxContainer/Label5.text = "x" + str(amount)
	update_reading_anim()


func update_ui():

	var game_data = await $Control.get_game_account()
	if not game_data.is_empty():
	
		set_sale_item(game_data["sale_book"])
		set_item_price(game_data["highest_bid"])
	
	$SolanaClient.get_account_info(scientist)

	var response = await($SolanaClient.http_response_received)

	if not response.has("result"):
		show_network_error()
		return
	
	if not response["result"].has("value"):
		show_network_error()
		return
	
	if response["result"]["value"] == null:
		show_network_error()
		return
		
	var encoded_data = response["result"]["value"]["data"][0]
	var decoded_data = SolanaUtils.bs64_decode(encoded_data)
	custom_data = parse_custom_data(decoded_data)
	
	set_published_decent(int(custom_data["Published Decent Books"]))
	set_published_interesting(int(custom_data["Published Interesting Books"]))
	set_published_fascinating(int(custom_data["Published Fascinating Books"]))

	set_book_score(float(custom_data["Book Score"]))
	set_cash(int(custom_data["Cash"]))

func update_ideas():
	var ideas = calculate_ideas()
	set_ideas(ideas)

func play_read():
	$Button7/AnimationPlayer.play("scale")

func _ready():
	#await init(Keypair.new_random())
	pass

# Called when the node enters the scene tree for the first time.
func init(pk):
	await $Control.init(pk)
	await load_key(pk)

func load_key(pk):
	print("TRYING_TO_SUBSCRIBE")
	$Control.mint_keypair = pk
	scientist = $Control.mint_keypair.get_public_string()
	$SolanaClient.account_subscribe($Control.decent_book_keypair, Callable(self, "decent_book_callback"))
	$SolanaClient.account_subscribe($Control.interesting_book_keypair, Callable(self, "interesting_book_callback"))
	$SolanaClient.account_subscribe($Control.fascinating_book_keypair, Callable(self, "fascinating_book_callback"))

	$SolanaClient.account_subscribe($Control.game_account, Callable(self, "game_account_changed"))
	$SolanaClient.account_subscribe(scientist, Callable(self, "scientist_data_changed"))
	
	print("updating ui")
	await update_ui()
	update_books()
	pass # Replace with function body.

func game_account_changed(param):
	var encoded_data = param["result"]["value"]["data"][0]
	var game_data = await $Control.game_account_from_data(encoded_data)
	
	if game_data["highest_bidder_scientist"].to_string() == $Control.mint_keypair.get_public_string() and game_data["highest_bid"] > 200:
		$Button6.disabled = true
	else:
		$Button6.disabled = false
	
	set_sale_item(game_data["sale_book"])
	set_item_price(game_data["highest_bid"])

func scientist_data_changed(params):
	var encoded_data = params["result"]["value"]["data"][0]
	var decoded_data = SolanaUtils.bs64_decode(encoded_data)
	custom_data = parse_custom_data(decoded_data)
	
	set_published_decent(int(custom_data["Published Decent Books"]))
	set_published_interesting(int(custom_data["Published Interesting Books"]))
	set_published_fascinating(int(custom_data["Published Fascinating Books"]))

	const RANDOM_FACTOR = 30.0
	var total_read = float(custom_data["Book Score"]) / RANDOM_FACTOR

	set_total_read(total_read)

	set_book_score(float(custom_data["Book Score"]))
	set_experience(float(custom_data["Experience"]))
	set_cash(int(custom_data["Cash"]))

func decent_book_callback(param):
	var ata = Pubkey.new_associated_token_address($Control.payer, $Control.decent_book_keypair)
	var amount = await $Control.get_token_balance(ata, $BalanceClient1)
	if amount is int:
		set_decent_books(amount)


func interesting_book_callback(params):
	var ata = Pubkey.new_associated_token_address($Control.payer, $Control.interesting_book_keypair)
	var amount = await $Control.get_token_balance(ata, $BalanceClient2)
	if amount is int:
		set_interesting_books(amount)

func fascinating_book_callback(params):
	var ata = Pubkey.new_associated_token_address($Control.payer, $Control.fascinating_book_keypair)
	var amount = await $Control.get_token_balance(ata, $BalanceClient3)
	if amount is int:
		set_fascinating_books(amount)


# Called everPublished Interesting Books: y frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

func _on_button_2_pressed():
	await update_ui()
	update_books()

func _exit_tree():
	$SolanaClient.unsubscribe_all(Callable(self, "decent_book_callback"))
	$SolanaClient.unsubscribe_all(Callable(self, "interesting_book_callback"))
	$SolanaClient.unsubscribe_all(Callable(self, "fascinating_book_callback"))
	$SolanaClient.unsubscribe_all(Callable(self, "game_account_changed"))
	$SolanaClient.unsubscribe_all(Callable(self, "scientist_data_changed"))


func place_bid():
	await $Control.place_bid(UI_bid)
	pass # Replace with function body.


func _on_button_6_mouse_entered():
	$Button6/Label4.visible = true
	pass # Replace with function body.


func _on_button_6_mouse_exited():
	$Button6/Label4.visible = false
	pass # Replace with function body.


# READ BOOK
func _on_button_7_pressed():
	$Control.read_book()
	pass # Replace with function body.


func _on_button_pressed():
	get_parent().get_node("ShelfBooks").amount = 100
