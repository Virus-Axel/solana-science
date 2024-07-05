extends Control

var payer : Keypair = Keypair.new_from_file("res://payer.json")
var mint_keypair: Keypair = Keypair.new_random()
var scientist_name

# Todo, use existing mints and do not expose private key.
#var decent_book_keypair: Keypair = Keypair.new_random()
#var interesting_book_keypair: Keypair = Keypair.new_random()
#var fascinating_book_keypair: Keypair = Keypair.new_random()

var decent_book_keypair: Keypair = Keypair.new_from_seed([108, 4, 53, 212, 153, 18, 178, 40, 230, 208, 84, 15, 190, 96, 119, 160, 151, 21, 196, 83, 173, 87, 140, 174, 140, 228, 212, 90, 27, 86, 116, 111])
var interesting_book_keypair: Keypair = Keypair.new_from_seed([26, 129, 203, 18, 146, 4, 117, 25, 93, 140, 104, 221, 139, 225, 162, 239, 6, 222, 67, 216, 165, 123, 129, 245, 138, 137, 156, 247, 203, 172, 66, 12])
var fascinating_book_keypair: Keypair = Keypair.new_from_seed([89, 219, 60, 175, 45, 153, 177, 68, 158, 28, 66, 65, 158, 187, 66, 39, 150, 121, 90, 24, 166, 135, 15, 122, 182, 178, 51, 226, 88, 67, 49, 77])

#var decent_book_keypair: Pubkey = Pubkey.new_from_string("FDMnm7Wh2cgFVAQ81EHrFJQ8QVmgNqqKvYo5HJGWSQDN")
#var interesting_book_keypair: Pubkey = Pubkey.new_from_string("eQigyb3RRTTJmqZieidXHxAQRfXqtciLQGXaCsBCXWa")
#var fascinating_book_keypair: Pubkey = Pubkey.new_from_string("BW4Q2XGZe47Xh8gVwHh31KnBUjfgZURuXb51XEqqibHK")


var game_account

var fb_amount = 0
var ib_amount = 0
var db_amount = 0

signal publish_ok
signal publish_err

signal place_bid_ok
signal place_bid_err

signal read_ok
signal read_err

func has_any_books():
	return fb_amount > 0 || db_amount > 0 || ib_amount > 0

func get_token_balance(token_account: Pubkey, client):
	client.get_token_account_balance(token_account.to_string())
	
	var response = await client.http_response_received
	print(response)
	if not response.has("result"):
		return null
		
	if not response["result"].has("value"):
		return null
		
	return int(response["result"]["value"]["amount"])

func get_token_balances():
	var decent_book_account: Pubkey = Pubkey.new_associated_token_address(payer, decent_book_keypair)
	var interesting_book_account: Pubkey = Pubkey.new_associated_token_address(payer, interesting_book_keypair)
	var fascinating_book_account: Pubkey = Pubkey.new_associated_token_address(payer, fascinating_book_keypair)
	
	return[
		await get_token_balance(decent_book_account, $"../BalanceClient1"),
		await get_token_balance(interesting_book_account, $"../BalanceClient2"),
		await get_token_balance(fascinating_book_account, $"../BalanceClient3"),
	]


func game_account_from_data(encoded_data: String):
	var decoded_data = SolanaUtils.bs64_decode(encoded_data)
	
	var sale_book = Pubkey.new_from_bytes(decoded_data.slice(8, 40))
	var seller = Pubkey.new_from_bytes(decoded_data.slice(40, 72))
	var seller_scientist = Pubkey.new_from_bytes(decoded_data.slice(72, 104))
	var highest_bidder = Pubkey.new_from_bytes(decoded_data.slice(104, 136))
	var highest_bidder_scientist = Pubkey.new_from_bytes(decoded_data.slice(136, 168))
	var highest_bid = decoded_data.decode_u64(168)
	print(sale_book.to_string())
	print(seller.to_string())
	print(highest_bidder.to_string())
	print("----------")
	
	return {
		"sale_book" = sale_book,
		"highest_bidder" = highest_bidder,
		"highest_bidder_scientist" = highest_bidder_scientist,
		"highest_bid" = highest_bid,
		"seller" = seller,
		"seller_scientist" = seller_scientist,
	}

func get_game_account():
	#game_account = Pubkey.new_pda(["SOLANA_SCIENCE_GAME_ACCOUNT"], $AnchorProgram.get_pid())
	$SolanaClient.get_account_info(game_account.to_string())
	
	var response = await($SolanaClient.http_response_received)
	if not response.has("result"):
		return {}
	
	if not response["result"].has("value"):
		return {}
	
	if response["result"]["value"] == null:
		return {}
		
	if not response["result"]["value"].has("data"):
		return {}
	
	var encoded_data = response["result"]["value"]["data"][0]
	return game_account_from_data(encoded_data)


func init_book_mints():
	var mint_authority: Pubkey = Pubkey.new_pda(["SOLANA_SCIENCE_AUTHORITY_SEED"], $AnchorProgram.get_pid())
	
	#for mint in MINTS:
	#	var ix = SystemProgram.create_account(payer, mint);
	
	print(decent_book_keypair.get_public_bytes())
	print(interesting_book_keypair.get_public_bytes())
	print(fascinating_book_keypair.get_public_bytes())
	
	var accounts = [
		payer,
		decent_book_keypair,
		interesting_book_keypair,
		fascinating_book_keypair,
		mint_authority,
		
		SystemProgram.get_pid(),
		TokenProgram2022.get_pid(),
	]
	$BookTransaction.set_payer(payer)
	
	var ix = $AnchorProgram.build_instruction("new_game", accounts, null)
	$BookTransaction.add_instruction(ix)
	$BookTransaction.update_latest_blockhash()
	
	$BookTransaction.sign_and_send()
	print(await $BookTransaction.transaction_response_received)
	await $BookTransaction.confirmed

func new_scientist():
	var ata: Pubkey = Pubkey.new_associated_token_address(payer, mint_keypair)
	var decent_book_account: Pubkey = Pubkey.new_associated_token_address(payer, decent_book_keypair)
	var interesting_book_account: Pubkey = Pubkey.new_associated_token_address(payer, interesting_book_keypair)
	var fascinating_book_account: Pubkey = Pubkey.new_associated_token_address(payer, fascinating_book_keypair)
	var mint_authority: Pubkey = Pubkey.new_pda(["SOLANA_SCIENCE_AUTHORITY_SEED"], $AnchorProgram.get_pid())
	
	var accounts = [
		payer,
		mint_keypair,
		mint_authority,
		
		SystemProgram.get_pid(),
		TokenProgram2022.get_pid(),
	]
	print(mint_keypair.get_public_string())
	
	print(scientist_name)
	var ix = $AnchorProgram.build_instruction("new_scientist", accounts, scientist_name)
	
	$Transaction.set_payer(payer)
	$Transaction.add_instruction(ix)
	
	ix = $AnchorProgram.build_instruction(
		"initialize",
		[
			payer,
			ata,
			decent_book_account,
			interesting_book_account,
			fascinating_book_account,
			mint_keypair,
			decent_book_keypair,
			interesting_book_keypair,
			fascinating_book_keypair,
			mint_authority,
			
			SystemProgram.get_pid(),
			TokenProgram2022.get_pid(),
			AssociatedTokenAccountProgram.get_pid(),
		],
		null
	)
	$Transaction.add_instruction(ix)
	
	$Transaction.update_latest_blockhash()
	
	$Transaction.sign_and_send()
	print(await $Transaction.transaction_response_received)
	await $Transaction.confirmed

func read_book():
	var ata: Pubkey = Pubkey.new_associated_token_address(payer, mint_keypair)
	var decent_book_account: Pubkey = Pubkey.new_associated_token_address(payer, decent_book_keypair)
	var interesting_book_account: Pubkey = Pubkey.new_associated_token_address(payer, interesting_book_keypair)
	var fascinating_book_account: Pubkey = Pubkey.new_associated_token_address(payer, fascinating_book_keypair)

	var mint_authority: Pubkey = Pubkey.new_pda(["SOLANA_SCIENCE_AUTHORITY_SEED"], $AnchorProgram.get_pid())
	var accounts = [
		payer,
		decent_book_account,
		interesting_book_account,
		fascinating_book_account,
		mint_keypair,
		decent_book_keypair,
		interesting_book_keypair,
		fascinating_book_keypair,
		mint_authority,
		TokenProgram2022.get_pid(),
	]
	
	var book_type = 1;
	if fb_amount > 0:
		book_type = 3
	elif ib_amount > 0:
		book_type = 2
	
	var ix = $AnchorProgram.build_instruction("research", accounts, AnchorProgram.u8(book_type))
	
	$Transaction2.set_payer(payer)
	$Transaction2.set_instructions([ix])
	$Transaction2.update_latest_blockhash()
	
	$Transaction2.sign_and_send()


func place_bid(price):
	var ata: Pubkey = Pubkey.new_associated_token_address(payer, mint_keypair)
	var decent_book_account: Pubkey = Pubkey.new_associated_token_address(payer, decent_book_keypair)
	var interesting_book_account: Pubkey = Pubkey.new_associated_token_address(payer, interesting_book_keypair)
	var fascinating_book_account: Pubkey = Pubkey.new_associated_token_address(payer, fascinating_book_keypair)

	var mint_authority: Pubkey = Pubkey.new_pda(["SOLANA_SCIENCE_AUTHORITY_SEED"], $AnchorProgram.get_pid())
	game_account = Pubkey.new_pda(["SOLANA_SCIENCE_GAME_ACCOUNT"], $AnchorProgram.get_pid())
	
	var game_account_data = await get_game_account()
	
	if game_account_data.is_empty():
		return
	
	if(game_account_data["highest_bidder_scientist"].to_string() == SystemProgram.get_pid().to_string()):
		game_account_data["highest_bidder_scientist"] = Pubkey.new_random()
	
	var accounts = [
		payer,
		game_account,
		decent_book_account,
		interesting_book_account,
		fascinating_book_account,
		mint_keypair,
		decent_book_keypair,
		interesting_book_keypair,
		fascinating_book_keypair,
		mint_authority,
		game_account_data["highest_bidder_scientist"],
		TokenProgram2022.get_pid(),
	]
	var ix = $AnchorProgram.build_instruction("place_bid", accounts, price)
	
	$Transaction4.instructions.clear()
	
	$Transaction4.set_payer(payer)
	$Transaction4.set_instructions([ix])
	$Transaction4.update_latest_blockhash()
	
	$Transaction4.sign_and_send()


func publish_book():
	var ata: Pubkey = Pubkey.new_associated_token_address(payer, mint_keypair)
	var decent_book_account: Pubkey = Pubkey.new_associated_token_address(payer, decent_book_keypair)
	var interesting_book_account: Pubkey = Pubkey.new_associated_token_address(payer, interesting_book_keypair)
	var fascinating_book_account: Pubkey = Pubkey.new_associated_token_address(payer, fascinating_book_keypair)

	var mint_authority: Pubkey = Pubkey.new_pda(["SOLANA_SCIENCE_AUTHORITY_SEED"], $AnchorProgram.get_pid())
	game_account = Pubkey.new_pda(["SOLANA_SCIENCE_GAME_ACCOUNT"], $AnchorProgram.get_pid())
	
	var game_account_data = await get_game_account()
	
	if game_account_data.is_empty():
		game_account_data["highest_bidder"] = Pubkey.new_random()
		game_account_data["seller"] = Pubkey.new_random()
		game_account_data["seller_scientist"] = Pubkey.new_random()
	
	if game_account_data["highest_bidder"].to_string() == SystemProgram.get_pid().to_string():
		game_account_data["highest_bidder"] = Pubkey.new_random()

	
	var accounts = [
		payer,
		game_account,
		decent_book_account,
		interesting_book_account,
		fascinating_book_account,
		mint_keypair,
		decent_book_keypair,
		interesting_book_keypair,
		fascinating_book_keypair,
		mint_authority,
		game_account_data["highest_bidder"],
		game_account_data["seller_scientist"],
		SystemProgram.get_pid(),
		TokenProgram2022.get_pid(),
	]
	var ix = $AnchorProgram.build_instruction("publish_book", accounts, null)
	
	$Transaction3.instructions.clear()
	
	$Transaction3.set_payer(payer)
	$Transaction3.set_instructions([ix])
	$Transaction3.update_latest_blockhash()
	
	$Transaction3.sign_and_send()
	

# Called when the node enters the scene tree for the first time.
func _ready():
	print(decent_book_keypair.get_public_string())
	print(interesting_book_keypair.get_public_string())
	print(fascinating_book_keypair.get_public_string())
	game_account = Pubkey.new_pda(["SOLANA_SCIENCE_GAME_ACCOUNT"], $AnchorProgram.get_pid())
	#init(Keypair.new_random())

func init(pk):
	payer = pk
	# Shhhhhhhhhh
	mint_keypair = Keypair.new_from_seed(pk.get_public_bytes())
	#await init_book_mints()
	await new_scientist()
	#await read_book()
	#await publish_book()
	
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_transaction_3_transaction_response_received(result):
	if result.has("result"):
		publish_ok.emit()
	else:
		publish_err.emit()


func _on_transaction_4_transaction_response_received(result):
	if result.has("result"):
		place_bid_ok.emit()
	else:
		place_bid_err.emit()


func _on_transaction_2_transaction_response_received(result):
	if result.has("result"):
		read_ok.emit()
	else:
		print(result)
		read_err.emit()
