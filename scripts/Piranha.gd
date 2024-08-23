class_name Piranha
extends StaticBody2D

const SCORE := 200
# 原始颜色，顺序为花、茎、呀
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

@onready var timer: Timer = $Timer
@onready var animated_sprite_2d: AnimatedSprite2D = $Graphics/AnimatedSprite2D

var player: Player
var is_player_nearby := false
var direction := -1 # -1表示向上，1表示向下
var distance := Variables.TILE_SIZE.y * 1.5
var player_range := Variables.TILE_SIZE.x * 2
var duration := 1

func _ready() -> void:
	await GameManager.world_ready
	var sprite_material = animated_sprite_2d.material as ShaderMaterial
	sprite_material.set_shader_parameter("origin_colors", COLOR_ORIGIN.duplicate())
	if GameManager.current_world_type == GameManager.WorldType.UNDER:
		sprite_material.set_shader_parameter("shader_enabled", true)
		sprite_material.set_shader_parameter("new_colors", COLOR_CYAN.duplicate())
	else:
		sprite_material.set_shader_parameter("shader_enabled", false)
		
	player = get_tree().get_first_node_in_group("Player")
	_on_timer_timeout()
	
func _physics_process(_delta: float) -> void:
	# 如果玩家在附近，就停止切换状态
	if abs(player.global_position.x - global_position.x) < player_range:
		is_player_nearby = true
	else:
		is_player_nearby = false

func on_stomped(_player: Player) -> void:
	# 伤害玩家
	player.hurt(self)
	
# 被无敌星撞或被龟壳撞
func on_charged(_body: CharacterBody2D) -> void:
	die()

# 被火球打
func on_hit(_body: CharacterBody2D) -> void:
	die()

func die() -> void:
	SoundManager.play_sfx("Kill")
	ScoreManager.add_score(SCORE, self)
	queue_free()

func _on_timer_timeout() -> void:
	if not (is_player_nearby and direction == -1):
		var tween = create_tween()
		tween.tween_property(self, "global_position:y", global_position.y + direction * distance, duration)
		direction *= -1
