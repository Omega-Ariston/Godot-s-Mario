extends Node

@onready var sfx: Node = $SFX
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer

const aboveGroundBGM := preload("res://assets/sounds/01. Above Ground BGM.mp3")
const courseClearBGM := preload("res://assets/sounds/02. Course Clear Fanfare.mp3")
const undergroundBGM := preload("res://assets/sounds/03. Underground BGM.mp3")
const underwaterBGM := preload("res://assets/sounds/04. Underwater BGM.mp3")
const castleBGM := preload("res://assets/sounds/05. Castle BGM.mp3")
const starBGM := preload("res://assets/sounds/Super_Star_theme.ogg")
const intoTheUnderBGM := preload("res://assets/sounds/02.5. Go Underground BGM.mp3")
const worldClearBGM = preload("res://assets/sounds/smb_world_clear.wav")

func play_sfx(sfx_name: String) -> AudioStreamPlayer:
	var audio_player := sfx.get_node(sfx_name) as AudioStreamPlayer
	if not audio_player:
		return
	audio_player.play()
	return audio_player

func play_world_bgm() -> void:
	var stream: AudioStream
	match GameManager.current_world_type:
		GameManager.WorldType.GROUND:
			stream = aboveGroundBGM
		GameManager.WorldType.UNDER:
			stream = undergroundBGM
		GameManager.WorldType.WATER:
			stream = underwaterBGM
		GameManager.WorldType.CASTLE:
			stream = castleBGM
	bgm_player.stream = stream
	bgm_player.play()

func into_the_under() -> AudioStreamPlayer:
	bgm_player.stream = intoTheUnderBGM
	bgm_player.play()
	return bgm_player

func course_clear() -> void:
	bgm_player.stream = courseClearBGM
	bgm_player.play()

func go_star() -> void:
	bgm_player.stream = starBGM
	bgm_player.play()

func world_cleaer() -> AudioStreamPlayer:
	bgm_player.stream = worldClearBGM
	bgm_player.play()
	return bgm_player

func pause_bgm() -> void:
	bgm_player.playing = false
