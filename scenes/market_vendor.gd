extends Node2D

@onready var prompt_label: Label = $PromptLabel

var is_player_near: bool = false

func _ready() -> void:
	prompt_label.hide()

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_near = true
		prompt_label.show()

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_near = false
		prompt_label.hide()

func _unhandled_input(event: InputEvent) -> void:
	if is_player_near and event.is_action_pressed("interact"):
		open_market()

func open_market() -> void:
	print("Enter Market!")
