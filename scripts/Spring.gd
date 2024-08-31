class_name Spring
extends StaticBody2D

enum State {
	IDLE,
	COMPRESS,
	RELEASE,
}

const NORMAL_FORCE := -400.0
const JUMP_FORCE := -600.0

var is_stomped := false
var jump_requested := false
var player: Player

@onready var sprite_2d: Sprite2D = $Graphics/Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: StateMachine = $StateMachine
@onready var spring_area: CollisionShape2D = $Area2D/SpringArea

func _input(event: InputEvent) -> void:
	if state_machine.current_state == State.COMPRESS:
		if event.is_action_pressed("jump"):
			jump_requested = true
	if is_stomped and (event.is_action_pressed("jump") or event.is_action_released("jump")):
		# 覆盖Player的跳跃操作
		get_viewport().set_input_as_handled()
		

func get_next_state(state: State) -> int:
	match state:
		State.IDLE:
			if is_stomped:
				return State.COMPRESS
		State.COMPRESS:
			if not animation_player.is_playing():
				return State.RELEASE
		State.RELEASE:
			if not animation_player.is_playing():
				return State.IDLE
				
	return state_machine.KEEP_CURRENT

func tick_physics(_state: State, _delta: float) -> void:
	if is_stomped:
		# 粘住玩家
		player.velocity.x = 0

func transition_state(_from: State, to: State) -> void:
	match to:
		State.IDLE:
			is_stomped = false
			animation_player.play("idle")
		State.COMPRESS:
			animation_player.play("compress", -1, 2.0, false)
		State.RELEASE:
			# 给玩家一个上跳的力
			player.velocity.y = JUMP_FORCE if jump_requested else NORMAL_FORCE
			jump_requested = false
			animation_player.play("release", -1, 2.0, false)

func _on_area_2d_body_entered(body: Player) -> void:
	player = body
	is_stomped = true
