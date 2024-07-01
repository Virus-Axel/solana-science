extends Control

var payer : Keypair = Keypair.new_from_file("res://payer.json")
var mint_keypair: Keypair = Keypair.new_random()
var decent_book_keypair: Keypair = Keypair.new_random()
var interesting_book_keypair: Keypair = Keypair.new_random()
var fascinating_book_keypair: Keypair = Keypair.new_random()


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
	print(ix.serialize())
	
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
	print(ix.serialize())
	
	$Transaction2.set_payer(payer)
	$Transaction2.add_instruction(ix)
	$Transaction2.update_latest_blockhash()
	
	$Transaction2.sign_and_send()
	print(await $Transaction2.transaction_response_received)
	await $Transaction2.confirmed
	

func publish_book():
	var ata: Pubkey = Pubkey.new_associated_token_address(payer, mint_keypair)
	var decent_book_account: Pubkey = Pubkey.new_associated_token_address(payer, decent_book_keypair)
	var interesting_book_account: Pubkey = Pubkey.new_associated_token_address(payer, interesting_book_keypair)
	var fascinating_book_account: Pubkey = Pubkey.new_associated_token_address(payer, fascinating_book_keypair)

	var mint_authority: Pubkey = Pubkey.new_pda(["SOLANA_SCIENCE_AUTHORITY_SEED"], $AnchorProgram.get_pid())
	var game_account: Pubkey = Pubkey.new_pda(["SOLANA_SCIENCE_GAME_ACCOUNT"], $AnchorProgram.get_pid())
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
		decent_book_account,
		SystemProgram.get_pid(),
		TokenProgram2022.get_pid(),
	]
	var ix = $AnchorProgram.build_instruction("publish_book", accounts, null)
	print(ix.serialize())
	
	$Transaction3.set_payer(payer)
	$Transaction3.add_instruction(ix)
	$Transaction3.update_latest_blockhash()
	
	$Transaction3.sign_and_send()
	print(await $Transaction3.transaction_response_received)
	await $Transaction3.confirmed

# Called when the node enters the scene tree for the first time.
func _ready():
	await init_book_mints()
	await new_scientist()
	#await read_book()
	publish_book()
	
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
