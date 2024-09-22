extends Node

# 普通的暂停用于角色变身/受伤、死亡时，全局暂停用于按下暂停键时
# 普通暂停会将暂停期间可以移动的物体临时加入白名单

var is_paused := false
var can_pause := true
var curr_white_list := []

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start"):
		if is_paused and can_pause:
			unpause_global()
		elif not is_paused and can_pause:
			pause_global()
		get_viewport().set_input_as_handled()


func pause_normal() -> void:
	curr_white_list = get_white_list()
	for node: Node in curr_white_list:
		node.set_process_mode(Node.PROCESS_MODE_ALWAYS)
	get_tree().paused = true
	
func unpause_normal() -> void:
	for node: Node in curr_white_list:
		node.set_process_mode(Node.PROCESS_MODE_INHERIT)
	curr_white_list = []
	get_tree().paused = false

func get_white_list() -> Array:
	var white_list := []
	var player: Player = get_tree().get_first_node_in_group("Player")
	if is_instance_valid(player):
		white_list.append_array([
			player.animation_player, player.blink_animator, player.initialize_animator, \
				player.on_fire_timer, player.dying_timer, player.state_machine,
			])
	var coin_bricks := get_tree().get_nodes_in_group("CoinBricks")
	for coin_brick: CoinBrick in coin_bricks:
		white_list.append(coin_brick.animation_player)
	var statuses := get_tree().get_nodes_in_group("Status")
	for status in statuses:
		white_list.append(status)
	return white_list
	
func pause_global() -> void:
	can_pause = false
	for node: Node in curr_white_list:
		node.set_process_mode(Node.PROCESS_MODE_INHERIT)
	SoundManager.pause_bgm()
	is_paused = true
	get_tree().paused = true
	await SoundManager.play_sfx("Pause").finished
	can_pause = true
	
func unpause_global() -> void:
	can_pause = false
	for node: Node in curr_white_list:
		node.set_process_mode(Node.PROCESS_MODE_ALWAYS)
	SoundManager.unpause_bgm()
	is_paused = false
	get_tree().paused = false
	await SoundManager.play_sfx("Pause").finished
	can_pause = true
