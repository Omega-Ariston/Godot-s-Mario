class_name Goomba
extends Enemy

enum State {
	WALK,
	STOMPED,
	DEAD,
}

const SPEED := 30.0
const SCORE := {
	"stomped" : 100,
	"hit": 100,
	"charged": 100,
	"bumped": 100,
}

# 原始颜色，顺序为蘑菇头、蘑菇柄、脚
const COLOR_ORIGIN := [
	Vector4(0.6, 0.29, 0.04, 1.0),
	Vector4(1.0, 0.78, 0.72, 1.0),
	Vector4(0, 0, 0, 1.0),
]

const COLOR_CYAN := [
	Vector4(0.11, 0.40, 0.46, 1.0),
	Vector4(0.68, 0.91, 0.91, 1.0),
	Vector4(0.06, 0.19, 0.22, 1.0)
]

const COLOR_GREY := [
	Vector4(0.73, 0.73, 0.73, 1.0),
	Vector4(0.98, 0.98, 0.98, 1.0),
	Vector4(0.45, 0.45, 0.45, 1.0)
]

@onready var sprite_2d: Sprite2D = $Graphics/Sprite2D

func _on_world_ready() -> void:
	var sprite_material = sprite_2d.material as ShaderMaterial
	sprite_material.set_shader_parameter("origin_colors", COLOR_ORIGIN.duplicate())
	if GameManager.current_world_type == GameManager.WorldType.UNDER:
		sprite_material.set_shader_parameter("shader_enabled", true)
		sprite_material.set_shader_parameter("new_colors", COLOR_CYAN.duplicate())
	elif GameManager.current_world_type == GameManager.WorldType.CASTLE:
		sprite_material.set_shader_parameter("shader_enabled", true)
		sprite_material.set_shader_parameter("new_colors", COLOR_GREY.duplicate())
	else:
		sprite_material.set_shader_parameter("shader_enabled", false)

func get_next_state(state: State) -> int:
	match state:
		State.WALK:
			if hit or charged or bumped:
				return State.DEAD
			if stomped:
				return State.STOMPED
	return state_machine.KEEP_CURRENT


func tick_physics(state: State, delta: float) -> void:
	if is_on_wall():
		turn()
	
	match state:
		State.WALK:
			move(SPEED, direction, delta, default_gravity, false)
		State.STOMPED:
			velocity.x = 0.0
		State.DEAD:
			move(DEAD_BOUNCE.x, attack_direction, delta)


func transition_state(_from: State, to: State) -> void:
	match to:
		State.WALK:
			animation_player.play("walk")
		State.STOMPED:
			ScoreManager.add_score(SCORE["stomped"], self)
			animation_player.play("stomped")
		State.DEAD:
			if charged:
				ScoreManager.add_score(SCORE["charged"], self)
			elif hit:
				ScoreManager.add_score(SCORE["hit"], self)
			elif bumped:
				ScoreManager.add_score(SCORE["bumped"], self)
			die()

func turn() -> void:
	direction = Direction.LEFT if direction == Direction.RIGHT else Direction.RIGHT
