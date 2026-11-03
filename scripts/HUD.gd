
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
	# TOP BAR FONT STYLING
	var labels_to_style = [money_label, seeds_label, wheat_label]

	for lbl in labels_to_style:
		if lbl:
			lbl.add_theme_font_size_override("font_size", 13)
			lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
			lbl.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.04))
			lbl.add_theme_constant_override("outline_size", 3)

	# LISTEN TO GAMEDATA UPDATES
	if GameData and GameData.has_signal("data_changed"):
		if not GameData.data_changed.is_connected(_update_hud_ui):
			GameData.data_changed.connect(_update_hud_ui)

	# HOE BUTTON
	if hoe_button:
		hoe_button.pressed.connect(func():
			if GameData and "ActiveItem" in GameData:
				GameData.select_item(GameData.ActiveItem.HOE)
		)

		hoe_button.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed:
				if event.button_index == MOUSE_BUTTON_RIGHT:
					_deselect_hud_item()
					print("[HUD] Hoe deselected via right-click")
		)

	# WATERING CAN BUTTON
	if water_button:
		water_button.pressed.connect(func():
			if GameData and "ActiveItem" in GameData:
				GameData.select_item(GameData.ActiveItem.WATERING_CAN)
		)

		water_button.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed:
				if event.button_index == MOUSE_BUTTON_RIGHT:
					_deselect_hud_item()
					print("[HUD] Watering Can deselected via right-click")
		)

	# SEED BUTTON
	if seed_button:
		seed_button.pressed.connect(func():
			if GameData and "ActiveItem" in GameData:
				GameData.select_item(GameData.ActiveItem.SEED)
		)

		seed_button.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed:
				if event.button_index == MOUSE_BUTTON_RIGHT:
					_deselect_hud_item()
					print("[HUD] Seed slot deselected via right-click")
		)

	# SELECT HOE WHEN THE GAME STARTS
	if GameData and "ActiveItem" in GameData and GameData.has_method("select_item"):
		GameData.select_item(GameData.ActiveItem.HOE)

	_update_hud_ui()


func _unhandled_input(event: InputEvent) -> void:
	if not GameData or not "ActiveItem" in GameData:
		return

	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_1:
			GameData.select_item(GameData.ActiveItem.HOE)

		elif event.keycode == KEY_2:
			GameData.select_item(GameData.ActiveItem.WATERING_CAN)

		elif event.keycode == KEY_3:
			GameData.select_item(GameData.ActiveItem.SEED)


# DESELECT CURRENT ITEM
func _deselect_hud_item() -> void:
	if not GameData:
		return

	if GameData.has_method("deselect_current_item"):
		GameData.deselect_current_item()
	else:
		GameData.selected_seed_type = ""
		GameData.selected_inventory_item = ""
		GameData.data_changed.emit()


# UPDATE COMPLETE HUD
func _update_hud_ui() -> void:
	if not GameData:
		return

	_update_resource_labels()
	_update_hotbar_selection()


# UPDATE MONEY, SEEDS, CROPS, ANIMALS, AND ICONS
func _update_resource_labels() -> void:
	if not GameData:
		return

	# 1. MONEY DISPLAY
	if money_label:
		if "player_money" in GameData:
			money_label.text = str(GameData.player_money)
		elif "money" in GameData:
			money_label.text = str(GameData.money)

	# 2. DETERMINE SELECTED ITEM
	var current_item: String = ""
	var is_seed_selected: bool = false
	var current_count: int = 0

	# Inventory selection takes priority.
	# This prevents a harvested Wheat item from being mistaken for Wheat seeds.
	if "selected_inventory_item" in GameData:
		if GameData.selected_inventory_item != "":
			current_item = GameData.selected_inventory_item
			is_seed_selected = false

	# Only use seed_inventory when an actual seed is selected.
	if current_item == "" and "selected_seed_type" in GameData:
		if GameData.selected_seed_type != "":
			current_item = GameData.selected_seed_type
			is_seed_selected = true

	# 3. GET THE CORRECT INVENTORY COUNT
	if current_item != "":
		if is_seed_selected:
			# Seeds are displayed separately from regular inventory.
			if "seed_inventory" in GameData:
				current_count = int(GameData.seed_inventory.get(current_item, 0))

		else:
			# Harvested crops and produce.
			if "crop_inventory" in GameData and GameData.crop_inventory.has(current_item):
				current_count = int(GameData.crop_inventory.get(current_item, 0))

			# Animals.
			elif "animal_inventory" in GameData:
				current_count = int(GameData.animal_inventory.get(current_item, 0))

	# 4. UPDATE RESOURCE LABELS
	if seeds_label:
		seeds_label.text = str(current_count) if current_item != "" else "-"

	if wheat_label:
		wheat_label.text = current_item if current_item != "" else "None"

	# 5. DETERMINE ICON PATHS
	var icon_path: String = ""
	var crop_icon_path: String = ""

	if current_item != "":
		if is_seed_selected:
			# SEED SELECTED
			if "SEED_DATA" in GameData and GameData.SEED_DATA.has(current_item):
				var seed_data = GameData.SEED_DATA[current_item]
				icon_path = seed_data.get("icon", "")
				crop_icon_path = seed_data.get("crop_icon", "")

		else:
			# REGULAR INVENTORY ITEM SELECTED

			# ANIMAL ICON
			if "animal_inventory" in GameData and GameData.animal_inventory.has(current_item):
				if "ANIMAL_DATA" in GameData and GameData.ANIMAL_DATA.has(current_item):
					var animal_data = GameData.ANIMAL_DATA[current_item]
					icon_path = animal_data.get("icon", "")
					crop_icon_path = animal_data.get("icon", "")

			# HARVESTED CROP / PRODUCE ICON
			elif "crop_inventory" in GameData and GameData.crop_inventory.has(current_item):
				if "SEED_DATA" in GameData and GameData.SEED_DATA.has(current_item):
					var crop_data = GameData.SEED_DATA[current_item]
					crop_icon_path = crop_data.get("crop_icon", "")

				# Fallback paths for items without a crop icon entry.
				elif current_item == "Pesticide":
					crop_icon_path = "res://images/assets/for main (crops)/pest control station/pesticides.png"

				elif current_item == "Organic Fertilizer":
					crop_icon_path = "res://images/assets/for main (crops)/fertilizer/fertilizer.png"

				elif current_item == "Egg":
					crop_icon_path = "res://images/assets/for main (crops)/egg/egg.png"

				elif current_item == "Milk":
					crop_icon_path = "res://images/assets/for main (crops)/milk/milk.png"

	# 6. UPDATE MIDDLE ICON (SEED PACK / ITEM ICON)
	if seed_icon:
		if icon_path != "" and ResourceLoader.exists(icon_path):
			seed_icon.texture = load(icon_path)
			seed_icon.visible = true
		else:
			seed_icon.texture = null
			seed_icon.visible = false

	# 7. UPDATE RIGHTMOST ICON (CROP / ANIMAL ICON)
	if wheat_icon:
		if crop_icon_path != "" and ResourceLoader.exists(crop_icon_path):
			wheat_icon.texture = load(crop_icon_path)
			wheat_icon.visible = true
		else:
			wheat_icon.texture = null
			wheat_icon.visible = false


# UPDATE HOTBAR SELECTION BORDERS
func _update_hotbar_selection() -> void:
	if not GameData or not "ActiveItem" in GameData or not "selected_item" in GameData:
		return

	var current = GameData.selected_item

	# SHOW ONLY THE ACTIVE SELECTION BORDER
	if hoe_border:
		hoe_border.visible = (current == GameData.ActiveItem.HOE)

	if water_border:
		water_border.visible = (current == GameData.ActiveItem.WATERING_CAN)

	if seed_border:
		seed_border.visible = (current == GameData.ActiveItem.SEED)
