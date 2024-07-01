extends Control

var PID = "Bp7LbjQdrAGGQft9TyJYiGvmKP6NzHZvvD35wiW12FMQ"
var scientist = "9Uz7mm73FaCq3UNSxD8zUSm2a7xekWW7BW8TSpUgGNW"

const TIME_TO_READ_BOOK = 120
const TIME_PER_IDEA = 3600.0

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
	$Label4.text = "Ideas: " + str(ideas)

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

func set_item_price(price: int):
	$Label2.text = "Price: " + str(price)
	$Button.text = "Bid " + str(price + 100)

func show_network_error():
	$Label6.visible = true

func update_ui():
	var game_account: Pubkey = Pubkey.new_pda(["SOLANA_SCIENCE_GAME_ACCOUNT"], Pubkey.new_from_string(PID))
	$SolanaClient.get_account_info(game_account.to_string())

	var response = await($SolanaClient.http_response_received)
	print(response)
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
	
	var sale_book = Pubkey.new_from_bytes(decoded_data.slice(8, 40))
	var seller = Pubkey.new_from_bytes(decoded_data.slice(40, 72))
	var highest_bidder = Pubkey.new_from_bytes(decoded_data.slice(72, 104))
	var highest_bid = decoded_data.decode_u64(104)
	
	set_sale_item(sale_book)
	set_item_price(highest_bid)
	
	print(decoded_data)
	
	$SolanaClient.get_account_info(scientist)

	response = await($SolanaClient.http_response_received)

	if not response.has("result"):
		show_network_error()
		return
	
	if not response["result"].has("value"):
		show_network_error()
		return
	
	if response["result"]["value"] == null:
		show_network_error()
		return
		
	encoded_data = response["result"]["value"]["data"][0]
	decoded_data = SolanaUtils.bs64_decode(encoded_data)
	var custom_data = parse_custom_data(decoded_data)
	
	set_published_decent(int(custom_data["Published Decent Books"]))
	set_published_interesting(int(custom_data["Published Interesting Books"]))
	set_published_fascinating(int(custom_data["Published Fascinating Books"]))

	set_book_score(float(custom_data["Book Score"]))
	var ideas = calculate_ideas(custom_data)
	set_ideas(ideas)


# Called when the node enters the scene tree for the first time.
func _ready():
	update_ui()
	pass # Replace with function body.


# Called everPublished Interesting Books: y frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
