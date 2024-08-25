class_name Piranha
extends Enemy

const SCORE := 200

enum State {
	IN,
	GOING_UP,
	OUT,
	GOING_DOWN,
}

# 原始颜色，顺序为花、茎、牙
const COLOR_ORIGIN := [
	Vector4(0.12, 0.52, 0.0, 1.0),
	Vector4(0.84, 0.55, 0.13, 1.0),
	Vector4(1.0, 1.0, 1.0, 1.0),
]

const COLOR_CYAN := [
	Vector4(0.11, 0.40, 0.46, 1.0),
	Vector4(0.51, 0.22, 0.06, 1.0),
	Vector4(0.98, 0.73, 0.67, 1.0)
]

const DISTANCE := Variables.TILE_SIZE.y * 1.5
const PLAYER_RANGE := Variables.TILE_SIZE.x * 2
const DURATION := 0.8
const SPEED := DISTANCE / DURATION

@onready var timer: Timer = $Timer
@onready var sprite_2d: Sprite2D = $Graphics/Sprite2D

var player: Player
var is_player_nearby := false
var can_up := true
var can_down := false
var origin_pos_y : float

func _ready() -> void:
	origin_pos_y = position.y
	await GameManager.player_ready
	
	var sprite_material = sprite_2d.material as ShaderMaterial
	sprite_material.set_shader_parameter("origin_colors", COLOR_ORIGIN.duplicate())
	if GameManager.current_world_type == GameManager.WorldType.UNDER:
		sprite_material.set_shader_parameter("shader_enabled", true)
		sprite_material.set_shader_parameter("new_colors", COLOR_CYAN.duplicate())
	else:
		sprite_material.set_shader_parameter("shader_enabled", false)
		
	player = get_tree().get_first_node_in_group("Player")
	animation_player.play("idle", -1, 0.8, false)

func get_next_state(state: State) -> int:
		
	match state:
		State.IN:
			if player and can_up and not is_player_nearby:
				return State.GOING_UP
		State.GOING_UP:
			if position.y <= origin_pos_y - DISTANCE:
				return State.OUT
		State.OUT:
			if can_down:
				return State.GOING_DOWN
		State.GOING_DOWN:
			if position.y >= origin_pos_y:
				return State.IN
			
	return state_machine.KEEP_CURRENT


func tick_physics(state: State, delta: float) -> void:
	match state:
		State.GOING_UP:
			move(SPEED, -1, delta)
		State.GOING_DOWN:
			move(SPEED, +1, delta)


func move(speed : float, dir: int, delta: float, _gravity := 0.0) -> void:
	position.y += speed * dir * delta
	

func transition_state(_from: State, to: State) -> void:
	match to:
		State.IN:
			timer.start()
		State.OUT:
			timer.start()
		State.GOING_UP:
			can_up = false
		State.GOING_DOWN:
			can_down = false
			
func _physics_process(_delta: float) -> void:
	if player:
		# 如果玩家在附近，就停止切换状态
		is_player_nearby = abs(player.global_position.x - global_position.x) < PLAYER_RANGE

func on_stomped(_player: Player) -> void:
	# 伤害玩家
	player.hurt(self)
	
# 被无敌星撞或被龟壳撞
func on_charged(_body: CharacterBody2D) -> void:
	die()

# 被火球打
func on_hit(_body: CharacterBody2D) -> void:
	die()

func die(_pause := false) -> void:
	SoundManager.play_sfx("Kill")
	ScoreManager.add_score(SCORE, self)
	queue_free()

func _on_timer_timeout() -> void:
	match state_machine.current_state:
		State.IN:
			can_up = true
		State.OUT:
			can_down = true
	
