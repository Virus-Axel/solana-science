extends Control

var PID = "Bp7LbjQdrAGGQft9TyJYiGvmKP6NzHZvvD35wiW12FMQ"
var scientist = "5pnJmbAtTj6sBmEFttUyYLnpHMUdLubTM3fnstLxZX2j"
var payer;

const TIME_TO_READ_BOOK = 120
const TIME_PER_IDEA = 30.0

var UI_bid = 0

func update_books():
	var balances = await $Control.get_token_balances()

	if balances[0] is int:
		set_decent_books(balances[0])
	if balances[1] is int:
		set_interesting_books(balances[1])
	if balances[2] is int:
		set_fascinating_books(balances[2])

func calculate_ideas(custom_data) -> int:
	var total_books = int(custom_data["Published Decent Books"]) + int(custom_data["Published Interesting Books"]) + int(custom_data["Published Fascinating Books"])
	var timestamp = Time.get_unix_time_from_system()
	var delta_time = float(timestamp) - float(custom_data["Last Modified"])
	var rest_ideas = maxf(0.0, float(delta_time) / TIME_PER_IDEA)
	return float(custom_data["Experience"]) - total_books + rest_ideas
	

func parse_custom_data(data: PackedByteArray) -> Dictionary:
	const TIME_OFFSET = 344
	var data_slice = data.slice(TIME_OFFSET)
	var i = 0;
	var ret = {}
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

	return ret

func set_ideas(ideas: int):
	$Panel/Label.text = str(ideas)

func set_book_score(score: int):
	$Label5.text = "Book Score: " + str(score)
	
func set_published_decent(amount: int):
	$ItemList.set_item_text(0, "Published Decent Books: " + str(amount))

func set_published_interesting(amount: int):
	$ItemList.set_item_text(1, "Published Interesting Books: " + str(amount))

func set_published_fascinating(amount: int):
	$ItemList.set_item_text(2, "Published Fascinating Books: " + str(amount))

func set_sale_item(item: Pubkey):
	$Label.text = "For Sale: " + item.to_string()
	$BookIconPicker.set_icon(item)

func set_item_price(price: int):
	$Label2.text = "Price: " + str(price)
	$Button.text = "Bid " + str(price + 100)
	UI_bid = price + 100

func show_network_error():
	$Label6.visible = true
	
func set_cash(cash: int):
	$Label3.text = "Cash: " + str(cash)

func set_decent_books(amount: int):
	$Label7.text = "Decent Books: " + str(amount)

func set_interesting_books(amount: int):
	$Label8.text = "Interesting Books: " + str(amount)

func set_fascinating_books(amount: int):
	$Label9.text = "Fascinating Books: " + str(amount)


func update_ui():

	var game_data = await $Control.get_game_account()
	
	print("Highest Bidder: ", game_data["highest_bidder"].to_string())
	
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
	var custom_data = parse_custom_data(decoded_data)
	
	set_published_decent(int(custom_data["Published Decent Books"]))
	set_published_interesting(int(custom_data["Published Interesting Books"]))
	set_published_fascinating(int(custom_data["Published Fascinating Books"]))

	set_book_score(float(custom_data["Book Score"]))
	var ideas = calculate_ideas(custom_data)
	set_ideas(ideas)
	set_cash(int(custom_data["Cash"]))

func play_read():
	$Button7/AnimationPlayer.play("scale")

# Called when the node enters the scene tree for the first time.
func _ready():
	play_read()
	await $Control.init()
	
	scientist = $Control.mint_keypair.get_public_string()
	$SolanaClient.account_subscribe($Control.decent_book_keypair, Callable(self, "decent_book_callback"))
	$SolanaClient.account_subscribe($Control.interesting_book_keypair, Callable(self, "interesting_book_callback"))
	$SolanaClient.account_subscribe($Control.fascinating_book_keypair, Callable(self, "fascinating_book_callback"))
	
	await update_ui()
	update_books()
	pass # Replace with function body.


func decent_book_callback(param):
	var ata = Pubkey.new_associated_token_address($Control.payer, $Control.decent_book_keypair)
	var amount = await $Control.get_token_balance(ata)
	if amount is int:
		set_decent_books(amount)


func interesting_book_callback(params):
	var ata = Pubkey.new_associated_token_address($Control.payer, $Control.interesting_book_keypair)
	var amount = await $Control.get_token_balance(ata)
	if amount is int:
		set_interesting_books(amount)

func fascinating_book_callback(params):
	var ata = Pubkey.new_associated_token_address($Control.payer, $Control.fascinating_book_keypair)
	var amount = await $Control.get_token_balance(ata)
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


func place_bid():
	await $Control.place_bid(UI_bid)
	pass # Replace with function body.
