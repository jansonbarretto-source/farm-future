extends Control

@onready var play_button: TextureButton = $PlayButton
@onready var settings_button: TextureButton = $SettingsButton
@onready var quit_button: TextureButton = $QuitButton

func _ready() -> void:
	# Connect button signals
	play_button.pressed.connect(_on_play_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

func _on_play_button_pressed() -> void:
	# Load the farm level
	get_tree().change_scene_to_file("res://scenes/MainFarm.tscn")

func _on_settings_button_pressed() -> void:
	# Placeholder for settings menu / popup
	print("Settings clicked!")

func _on_quit_button_pressed() -> void:
	# Exit game application
	get_tree().quit()
