extends Control

var payer : Keypair = Keypair.new_from_file("res://payer.json")

func new_scientist():
	var mint_keypair: Keypair = Keypair.new_random()
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
	$Transaction.update_latest_blockhash()
	
	$Transaction.sign_and_send()
	print(await $Transaction.transaction_response_received)

# Called when the node enters the scene tree for the first time.
func _ready():
	new_scientist()
	return
	var accounts = [
		payer,
		payer,
		payer,
		payer,
		payer,
	]
	var ix = $AnchorProgram.build_instruction("research", accounts, null)
	print(ix.serialize())
	
	$Transaction.set_payer(payer)
	$Transaction.add_instruction(ix)
	$Transaction.update_latest_blockhash()
	
	$Transaction.sign_and_send()
	print(await $Transaction.transaction_response_received)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
