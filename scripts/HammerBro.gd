class_name HammerBro
extends Enemy

enum State {
	WONDER,
	JUMP_UP,
	JUMP_DOWN,
	LANDING,
	CHASING,
	DEAD,
}

const SPEED := 30.0
const SCORE := {
	"stomped" : 1000,
	"hit": 1000,
	"charged": 1000,
	"bumped": 1000,
}
const WONDER_RANGE := Variables.TILE_SIZE.x / 2

# 原始颜色，顺序为壳、肉、壳边缘
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

var origin_x : float

@onready var sprite_2d: Sprite2D = $Graphics/Sprite2D

func _ready() -> void:
	origin_x = global_position.x

func _on_world_ready() -> void:
	var sprite_material = sprite_2d.material as ShaderMaterial
	sprite_material.set_shader_parameter("origin_colors", COLOR_ORIGIN.duplicate())
	if GameManager.current_world_type == GameManager.WorldType.UNDER:
		sprite_material.set_shader_parameter("shader_enabled", true)
		sprite_material.set_shader_parameter("new_colors", COLOR_CYAN.duplicate())
	else:
		sprite_material.set_shader_parameter("shader_enabled", false)

func get_next_state(state: State) -> int:
	return state_machine.KEEP_CURRENT


func tick_physics(state: State, delta: float) -> void:
	# 始终面朝玩家
	direction = Direction.LEFT if player.global_position.x < global_position.x else Direction.RIGHT



func transition_state(_from: State, to: State) -> void:
	match to:
		State.DEAD:
			if charged:
				ScoreManager.add_score(SCORE["charged"], self)
			elif hit:
				ScoreManager.add_score(SCORE["hit"], self)
			elif bumped:
				ScoreManager.add_score(SCORE["bumped"], self)
			elif stomped:
				ScoreManager.add_score(SCORE["stomped"], self)
			die()
