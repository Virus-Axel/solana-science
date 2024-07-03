extends CenterContainer

const AMPLITUDE = 0.05
const FREQUENCY = 3.0

var time = 0.0

func is_mint_decent(mint: Pubkey) -> bool:
	var kp = get_parent().get_node("Control").decent_book_keypair
	var payer = get_parent().get_node("Control").payer
	var ata = Pubkey.new_associated_token_address(payer, kp)
	return mint.to_bytes() == kp.get_public_bytes()
	
func is_mint_interesting(mint: Pubkey) -> bool:
	var kp = get_parent().get_node("Control").interesting_book_keypair
	var payer = get_parent().get_node("Control").payer
	var ata = Pubkey.new_associated_token_address(payer, kp)
	print(mint.to_bytes())
	print(ata.to_bytes())
	return mint.to_bytes() == kp.get_public_bytes()
	
func is_mint_fascinating(mint: Pubkey) -> bool:
	var kp = get_parent().get_node("Control").fascinating_book_keypair
	var payer = get_parent().get_node("Control").payer
	var ata = Pubkey.new_associated_token_address(payer, kp)
	return (mint.to_bytes() == kp.get_public_bytes())

func set_icon(mint: Pubkey):
	print(mint)
	if is_mint_decent(mint):
		$TextureRect.visible = true
		$TextureRect2.visible = false
		$TextureRect3.visible = false
	elif is_mint_interesting(mint):
		$TextureRect.visible = false
		$TextureRect2.visible = true
		$TextureRect3.visible = false
	elif is_mint_fascinating(mint):
		$TextureRect.visible = false
		$TextureRect2.visible = false
		$TextureRect3.visible = true


func update_scale():
	time += $Timer.wait_time
	var scale_value = 1.0 + sin(time * FREQUENCY) * AMPLITUDE
	scale.x = scale_value
	scale.y = scale_value
