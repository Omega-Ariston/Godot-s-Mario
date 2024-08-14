class_name CoinBumped
extends CharacterBody2D

const BOUNCE_VELOCITY := -300.0
const SCORE := 200

@onready var timer: Timer = $Timer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if StatusBar.coin == 99:
		StatusBar.coin = 0
		GameManager.add_life()
	else:
		StatusBar.coin += 1
	velocity.y = BOUNCE_VELOCITY
	animation_player.play("idle", -1, 1.5, false)
	timer.start()
	
func _physics_process(delta: float) -> void:
	velocity.y += GameManager.default_gravity  * delta
	move_and_slide()

func _on_timer_timeout() -> void:
	ScoreManager.add_score(self, SCORE)
	queue_free()
