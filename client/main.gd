extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	var accounts = [
		Keypair.new_random(),
		Keypair.new_random(),
		Keypair.new_random(),
		Keypair.new_random(),
		Keypair.new_random(),
	]
	var ix = $AnchorProgram.build_instruction("research", accounts, null)
	print(ix.serialize())
	
	$Transaction.add_instruction(ix)
	$Transaction.update_latest_blockhash()
	
	$Transaction.sign_and_send()
	print(await $Transaction.transaction_response_received)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
