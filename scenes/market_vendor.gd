extends Node2D

@export var market_ui: Control # Optional direct reference in Inspector

@onready var prompt_label: Label = $PromptLabel

var is_player_near: bool = false

func _ready() -> void:
	if prompt_label:
		prompt_label.hide()

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		is_player_near = true
		if prompt_label:
			prompt_label.show()

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		is_player_near = false
		if prompt_label:
			prompt_label.hide()

func _unhandled_input(event: InputEvent) -> void:
	if is_player_near and event is InputEventKey and event.pressed and not event.is_echo():
		# Triggers if E key is pressed OR if the custom "interact" action is defined
		if event.keycode == KEY_E or event.is_action_pressed("interact"):
			open_market()
			get_viewport().set_input_as_handled() # Consumes input so no other script uses it

func open_market() -> void:
	# Check assigned export variable first, then fallback to tree search
	var ui = market_ui
	if not ui:
		ui = get_tree().root.find_child("MarketUI", true, false)
		
	if ui:
		if ui.has_method("open_market"):
			ui.open_market()
		elif ui.has_method("show"):
			ui.show()
	else:
		print("Error: MarketUI node not found in scene tree!")
