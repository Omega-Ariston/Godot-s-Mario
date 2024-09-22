extends Node

@onready var sfx: Node = $SFX
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer

const BGM := {
	GameManager.WorldType.GROUND: preload("res://assets/sounds/bgm/Ground.mp3"),
	GameManager.WorldType.UNDER: preload("res://assets/sounds/bgm/Under.mp3"),
	GameManager.WorldType.WATER: preload("res://assets/sounds/bgm/Water.mp3"),
	GameManager.WorldType.CASTLE: preload("res://assets/sounds/bgm/Castle.mp3"),
}

const BGM_HURRY := {
	GameManager.WorldType.GROUND: preload("res://assets/sounds/bgm/Ground Hurry.mp3"),
	GameManager.WorldType.UNDER: preload("res://assets/sounds/bgm/Under Hurry.mp3"),
	GameManager.WorldType.WATER: preload("res://assets/sounds/bgm/Water Hurry.mp3"),
	GameManager.WorldType.CASTLE: preload("res://assets/sounds/bgm/Castle Hurry.mp3"),
}

const levelClearBGM := preload("res://assets/sounds/bgm/Level Clear.mp3")
const starBGM := preload("res://assets/sounds/bgm/Star.ogg")
const starBGMHurry := preload("res://assets/sounds/bgm/Star Hurry.mp3")
const intoTheUnderBGM := preload("res://assets/sounds/bgm/Into The Under.mp3")
const worldClearBGM := preload("res://assets/sounds/bgm/World Clear.wav")
const princessBGM := preload("res://assets/sounds/bgm/Princess.mp3")
const warningBGM := preload("res://assets/sounds/bgm/Warning.wav")
const touchFlagBGM := preload("res://assets/sounds/bgm/Touch Flag.wav")
const marioDieBGM := preload("res://assets/sounds/bgm/Mario Die.wav")

const WORLD_STREAM_INDEX := 0
const STAR_STREAM_INDEX := 1
const WARNING_STREAM_INDEX := 2

func play_sfx(sfx_name: String) -> AudioStreamPlayer:
	var audio_player := sfx.get_node(sfx_name) as AudioStreamPlayer
	audio_player.play()
	return audio_player

func play_world_bgm() -> void:
	if StatusBar.time > Variables.WARNING_TIME:
		bgm_player.stream = BGM[GameManager.current_world_type]
	else:
		bgm_player.stream = BGM_HURRY[GameManager.current_world_type]
	bgm_player.play()

func into_the_under() -> AudioStreamPlayer:
	bgm_player.stream = intoTheUnderBGM
	bgm_player.play()
	return bgm_player
	
func touch_flag() -> void:
	bgm_player.stop()
	bgm_player.stream = touchFlagBGM
	bgm_player.play()
	
func mario_die() -> void:
	bgm_player.stop()
	bgm_player.stream = marioDieBGM
	bgm_player.play()

func level_clear() -> void:
	bgm_player.stream = levelClearBGM
	bgm_player.play()

func go_star() -> void:
	if StatusBar.time > Variables.WARNING_TIME:
		bgm_player.stream = starBGM
	else:
		bgm_player.stream = starBGMHurry
	bgm_player.play()
	await bgm_player.finished
	play_world_bgm()

func warn() -> void:
	bgm_player.stream = warningBGM
	bgm_player.play()
	await bgm_player.finished
	play_world_bgm()

func world_clear() -> AudioStreamPlayer:
	bgm_player.stop()
	bgm_player.stream = worldClearBGM
	bgm_player.play()
	return bgm_player

func meet_princess() -> void:
	bgm_player.stop()
	bgm_player.stream = princessBGM
	bgm_player.play()

func pause_bgm() -> void:
	bgm_player.stream_paused = true
	
func unpause_bgm() -> void:
	bgm_player.stream_paused = false
