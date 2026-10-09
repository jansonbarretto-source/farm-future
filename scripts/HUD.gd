extends CanvasLayer

# Hotbar Button Nodes
@onready var hoe_button: Button = $HotBarPanel/Slot_Hoe
@onready var water_button: Button = $HotBarPanel/Slot_Water
@onready var seed_button: Button = $HotBarPanel/Slot_Seed

# Selection Border Overlays
@onready var hoe_border: Control = $HotBarPanel/Slot_Hoe/SelectionBorder
@onready var water_border: Control = $HotBarPanel/Slot_Water/SelectionBorder
@onready var seed_border: Control = $HotBarPanel/Slot_Seed/SelectionBorder

# Resource Display Labels
@onready var money_label: Label = $Control/TopBar/MoneyLabel
@onready var seeds_label: Label = $Control/TopBar/SeedLabel
@onready var wheat_label: Label = $Control/TopBar/WheatLabel

func _ready() -> void:
	# Listen to GameData updates
	if GameData.has_signal("data_changed"):
		GameData.data_changed.connect(_update_hud_ui)
	
	# Connect Button Click Signals
	if hoe_button:
		hoe_button.pressed.connect(func(): GameData.select_item(GameData.ActiveItem.HOE))
	if water_button:
		water_button.pressed.connect(func(): GameData.select_item(GameData.ActiveItem.WATERING_CAN))
	if seed_button:
		seed_button.pressed.connect(func(): GameData.select_item(GameData.ActiveItem.SEED))
		
	# Select HOE on game launch
	GameData.select_item(GameData.ActiveItem.HOE)
	_update_hud_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_1:
			GameData.select_item(GameData.ActiveItem.HOE)
		elif event.keycode == KEY_2:
			GameData.select_item(GameData.ActiveItem.WATERING_CAN)
		elif event.keycode == KEY_3:
			GameData.select_item(GameData.ActiveItem.SEED)

func _update_hud_ui() -> void:
	_update_resource_labels()
	_update_hotbar_selection()

func _update_resource_labels() -> void:
	if money_label and "money" in GameData:
		money_label.text = "₱" + str(GameData.money)
	if seeds_label and "seeds" in GameData:
		seeds_label.text = str(GameData.seeds)
	if wheat_label and "wheat" in GameData:
		wheat_label.text = str(GameData.wheat)

func _update_hotbar_selection() -> void:
	var current = GameData.selected_item
	
	# Explicitly show only the active selection border
	if hoe_border:
		hoe_border.visible = (current == GameData.ActiveItem.HOE)
	if water_border:
		water_border.visible = (current == GameData.ActiveItem.WATERING_CAN)
	if seed_border:
		seed_border.visible = (current == GameData.ActiveItem.SEED)
