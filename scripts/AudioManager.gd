extends Node

# Dictionary para sa lahat ng sound files at music sa 'sounds' folder
var sounds = {
	"click": "res://sounds/buttonclick.mp3",
	"buy": "res://sounds/buy sound.wav",
	"chicken": "res://sounds/chicken sound.wav",
	"coin": "res://sounds/coin npc.wav",
	"cow": "res://sounds/cow sound.wav",
	"crop_flooded": "res://sounds/crop flooded.mp3",
	"crop_wither": "res://sounds/crop wither.wav",
	"door_sleep": "res://sounds/door house to sleep.wav",
	"dry_season": "res://sounds/dry season.wav",
	"error": "res://sounds/error.wav",
	"harvest": "res://sounds/harvest.mp3",
	"hoe": "res://sounds/hoe.wav",
	"machine_process": "res://sounds/machine process.wav",
	"bgm": "res://sounds/main game music.mp3",
	"manure": "res://sounds/manure.wav",
	"night_time": "res://sounds/night time.wav",
	"open": "res://sounds/open.wav",
	"open_inventory": "res://sounds/open Inventory.wav",
	"pig": "res://sounds/pig.wav",
	"planting": "res://sounds/Planting.mp3",
	"rain": "res://sounds/rain sound.mp3",
	"walking": "res://sounds/sandstep1.wav",
	"sell": "res://sounds/sell from market.wav",
	"sheep": "res://sounds/sheep.wav",
	"ting": "res://sounds/ting.wav",
	"tool_swap": "res://sounds/toolSwap.wav",
	"unlock": "res://sounds/unlock.wav",
	"water_refill": "res://sounds/water refill from river.wav",
	"water_tank_fill": "res://sounds/water tank fill.mp3",
	"watering": "res://sounds/Watering.mp3"
}

var sfx_players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 5

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Gumawa ng pool ng audio players para sabay-sabay silang tumugtog kung kinakailangan
	for i in range(POOL_SIZE):
		var player = AudioStreamPlayer.new()
		add_child(player)
		sfx_players.append(player)

func play_sfx(sound_name: String) -> void:
	if not sounds.has(sound_name):
		return
		
	var file_path = sounds[sound_name]
	if not ResourceLoader.exists(file_path):
		return
		
	var stream = load(file_path) as AudioStream
	if not stream:
		return
		
	# Hanapin ang bakanteng player sa pool
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return
			
	# Kung puno ang pool, gamitin muna ang una
	sfx_players[0].stream = stream
	sfx_players[0].play()
