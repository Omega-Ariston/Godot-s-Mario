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
		coin = v
		coin_label.text = ("%02d" % coin)

@onready var score_label: RichTextLabel = $Score
@onready var time_label: RichTextLabel = $Time
@onready var level_label: RichTextLabel = $Level
@onready var coin_label: RichTextLabel = $Coin

func initialize() -> void:
	score = 0
	coin = 0
