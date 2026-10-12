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

# Resource Display Icons
@onready var seed_icon: TextureRect = $Control/TopBar/SeedIcon
@onready var wheat_icon: TextureRect = $Control/TopBar/WheatIcon

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
	# 1. Money Display
	if money_label:
		if "player_money" in GameData:
			money_label.text = "₱" + str(GameData.player_money)
		elif "money" in GameData:
			money_label.text = "₱" + str(GameData.money)

	# 2. Selected Seed Info & Count
	var current_seed = GameData.selected_seed_type if "selected_seed_type" in GameData else "Wheat"
	var current_seed_count = 0
	
	if "seed_inventory" in GameData and GameData.seed_inventory.has(current_seed):
		current_seed_count = GameData.seed_inventory[current_seed]
	elif "seeds" in GameData:
		current_seed_count = GameData.seeds

	# Dynamic Label Updates
	if seeds_label:
		seeds_label.text = str(current_seed_count) # Magpapakita ng count (e.g., 10)
		
	if wheat_label:
		wheat_label.text = current_seed # Magpapakita ng name (e.g., "Carrot", "Tomato")

	# 3. Dynamic Seed Pack Icon (Middle Icon)
	if seed_icon and GameData.SEED_DATA.has(current_seed):
		var data = GameData.SEED_DATA[current_seed]
		if data.has("icon") and ResourceLoader.exists(data["icon"]):
			seed_icon.texture = load(data["icon"])

	# 4. Dynamic Crop Sprite Icon (Rightmost Icon)
	if wheat_icon and GameData.SEED_DATA.has(current_seed):
		var data = GameData.SEED_DATA[current_seed]
		if data.has("crop_icon") and ResourceLoader.exists(data["crop_icon"]):
			wheat_icon.texture = load(data["crop_icon"])

func _update_hotbar_selection() -> void:
	var current = GameData.selected_item
	
	# Explicitly show only the active selection border
	if hoe_border:
		hoe_border.visible = (current == GameData.ActiveItem.HOE)
	if water_border:
		water_border.visible = (current == GameData.ActiveItem.WATERING_CAN)
	if seed_border:
		seed_border.visible = (current == GameData.ActiveItem.SEED)
