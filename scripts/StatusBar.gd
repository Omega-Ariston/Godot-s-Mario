extends CanvasLayer

@export var time: int = 400 # 8-1和8-3只有300秒
@export var world: int # 世界编号
@export var level: int # 关卡编号

var score := 0
var coin := 0

@onready var score_label: RichTextLabel = $Score
@onready var time_label: RichTextLabel = $Time
@onready var level_label: RichTextLabel = $Level
@onready var coin_label: RichTextLabel = $Coin

func _ready() -> void:
	score_label.text = 'MARIO\n' + ("%06d" % score)
	time_label.text = 'Time\n' + str(time)
	coin_label.text = ("%02d" % coin)
	level_label.text = '[center]WORLD\n' + str(world) + '-' + str(level) + '[/center]'
