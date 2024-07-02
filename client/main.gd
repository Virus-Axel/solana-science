extends Control

var payer : Keypair = Keypair.new_from_file("res://payer.json")
var mint_keypair: Keypair = Keypair.new_random()
var decent_book_keypair: Keypair = Keypair.new_random()
var interesting_book_keypair: Keypair = Keypair.new_random()
var fascinating_book_keypair: Keypair = Keypair.new_random()


func get_token_balance(token_account: Pubkey):
	$SolanaClient.get_token_account_balance(token_account.to_string())
	
	var response = await $SolanaClient.http_response_received
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
		await get_token_balance(decent_book_account),
		await get_token_balance(interesting_book_account),
		await get_token_balance(fascinating_book_account),
	]


func get_game_account():
	var game_account: Pubkey = Pubkey.new_pda(["SOLANA_SCIENCE_GAME_ACCOUNT"], $AnchorProgram.get_pid())
	$SolanaClient.get_account_info(game_account.to_string())
	
	var response = await($SolanaClient.http_response_received)
	if not response.has("result"):
		return {}
	
	if not response["result"].has("value"):
		return {}
	
	if response["result"]["value"] == null:
		return {}
	
	var encoded_data = response["result"]["value"]["data"][0]
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


func init_book_mints():
	var mint_authority: Pubkey = Pubkey.new_pda(["SOLANA_SCIENCE_AUTHORITY_SEED"], $AnchorProgram.get_pid())
	
	#for mint in MINTS:
	#	var ix = SystemProgram.create_account(payer, mint);
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
	
	var ix = $AnchorProgram.build_instruction("new_scientist", accounts, null)
	
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
	var ix = $AnchorProgram.build_instruction("research", accounts, AnchorProgram.u8(1))
	
	$Transaction2.set_payer(payer)
	$Transaction2.add_instruction(ix)
	$Transaction2.update_latest_blockhash()
	
	$Transaction2.sign_and_send()
	print(await $Transaction2.transaction_response_received)
	await $Transaction2.confirmed
	

func place_bid(price):
	var ata: Pubkey = Pubkey.new_associated_token_address(payer, mint_keypair)
	var decent_book_account: Pubkey = Pubkey.new_associated_token_address(payer, decent_book_keypair)
	var interesting_book_account: Pubkey = Pubkey.new_associated_token_address(payer, interesting_book_keypair)
	var fascinating_book_account: Pubkey = Pubkey.new_associated_token_address(payer, fascinating_book_keypair)

	var mint_authority: Pubkey = Pubkey.new_pda(["SOLANA_SCIENCE_AUTHORITY_SEED"], $AnchorProgram.get_pid())
	var game_account: Pubkey = Pubkey.new_pda(["SOLANA_SCIENCE_GAME_ACCOUNT"], $AnchorProgram.get_pid())
	
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
	
	$Transaction3.instructions.clear()
	
	$Transaction3.set_payer(payer)
	$Transaction3.set_instructions([ix])
	$Transaction3.update_latest_blockhash()
	
	$Transaction3.sign_and_send()
	print(await $Transaction3.transaction_response_received)
	await $Transaction3.confirmed


func publish_book():
	var ata: Pubkey = Pubkey.new_associated_token_address(payer, mint_keypair)
	var decent_book_account: Pubkey = Pubkey.new_associated_token_address(payer, decent_book_keypair)
	var interesting_book_account: Pubkey = Pubkey.new_associated_token_address(payer, interesting_book_keypair)
	var fascinating_book_account: Pubkey = Pubkey.new_associated_token_address(payer, fascinating_book_keypair)

	var mint_authority: Pubkey = Pubkey.new_pda(["SOLANA_SCIENCE_AUTHORITY_SEED"], $AnchorProgram.get_pid())
	var game_account: Pubkey = Pubkey.new_pda(["SOLANA_SCIENCE_GAME_ACCOUNT"], $AnchorProgram.get_pid())
	
	var game_account_data = await get_game_account()
	
	if game_account_data.is_empty():
		print("RANDOMIZING!")
		game_account_data["highest_bidder"] = Pubkey.new_random()
		game_account_data["seller"] = Pubkey.new_random()
		game_account_data["seller_scientist"] = Pubkey.new_random()
	
	if game_account_data["highest_bidder"].to_string() == SystemProgram.get_pid().to_string():
		print("SYSTEMPROGRAM")
		game_account_data["highest_bidder"] = Pubkey.new_random()
		print(game_account_data["highest_bidder"].to_string())
	
	print("SELLLLLLLLL: ")
	print(game_account_data)
	
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
	print(await $Transaction3.transaction_response_received)
	await $Transaction3.confirmed

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#init()

func init():
	await init_book_mints()
	await new_scientist()
	#await read_book()
	await publish_book()
	
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
