extends CanvasLayer

@export var time: int = -1:
	set(v):
		if not is_node_ready():
			await ready
		time = v
		time_label.text = 'Time\n' + (("%03d" % time) if time != -1 else '')
		
@export var level: String = "1-1": # 关卡编号
	set(v):
		if not is_node_ready():
			await ready
		level = v
		level_label.text = '[center]WORLD\n' + level + '[/center]'

var score := 0:
	set(v):
		if not is_node_ready():
			await ready
		score = v
		score_label.text = 'MARIO\n' + ("%06d" % score)
		
var coin := 0:
	set(v):
		if not is_node_ready():
			await ready
		if v == 100:
			coin = 0
			GameManager.add_life()
		else:
			coin = v
		coin_label.text = ("%02d" % coin)

@onready var score_label: RichTextLabel = $Score
@onready var time_label: RichTextLabel = $Time
@onready var level_label: RichTextLabel = $Level
@onready var coin_label: RichTextLabel = $Coin
@onready var coin_animation: AnimatedSprite2D = $CoinAnimation

func _ready() -> void:
	GameManager.world_ready.connect(_on_world_ready)

func initialize() -> void:
	score = 0
	coin = 0

func transition_screen() -> void:
	StatusBar.time = -1
	coin_animation.play("cyan")
	coin_animation.frame = 0
	coin_animation.pause()
	
func _on_world_ready() -> void:
	match GameManager.current_world_type:
		GameManager.WorldType.UNDER:
			coin_animation.play("cyan")
		GameManager.WorldType.CASTLE:
			coin_animation.play("grey")
		_:
			coin_animation.play("origin")
