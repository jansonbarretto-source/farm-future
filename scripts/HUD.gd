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
	if GameData and GameData.has_signal("data_changed"):
		if not GameData.data_changed.is_connected(_update_hud_ui):
			GameData.data_changed.connect(_update_hud_ui)
	
	# Connect Button Click Signals & Right-Click Deselect
	if hoe_button:
		hoe_button.pressed.connect(func(): 
			if GameData and "ActiveItem" in GameData:
				GameData.select_item(GameData.ActiveItem.HOE)
		)
		hoe_button.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
				if GameData:
					GameData.selected_seed_type = ""
					GameData.data_changed.emit()
					print("[HUD] Hoe/Tool deselected via right-click")
		)

	if water_button:
		water_button.pressed.connect(func(): 
			if GameData and "ActiveItem" in GameData:
				GameData.select_item(GameData.ActiveItem.WATERING_CAN)
		)
		water_button.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
				if GameData:
					GameData.selected_seed_type = ""
					GameData.data_changed.emit()
					print("[HUD] Watering Can deselected via right-click")
		)

	if seed_button:
		seed_button.pressed.connect(func(): 
			if GameData and "ActiveItem" in GameData:
				GameData.select_item(GameData.ActiveItem.SEED)
		)
		seed_button.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
				if GameData:
					GameData.selected_seed_type = ""
					GameData.data_changed.emit()
					print("[HUD] Seed slot deselected via right-click")
		)
		
	# Select HOE on game launch with safety check
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

func _update_hud_ui() -> void:
	if not GameData:
		return
		
	_update_resource_labels()
	_update_hotbar_selection()

func _update_resource_labels() -> void:
	if not GameData:
		return

	# 1. Money Display
	if money_label:
		if "player_money" in GameData:
			money_label.text = "₱" + str(GameData.player_money)
		elif "money" in GameData:
			money_label.text = "₱" + str(GameData.money)

	# 2. Selected Item / Seed / Animal / Crop Info & Count
	var current_item = ""
	if "selected_seed_type" in GameData and GameData.selected_seed_type != "":
		current_item = GameData.selected_seed_type
	elif "selected_inventory_item" in GameData and GameData.selected_inventory_item != "":
		current_item = GameData.selected_inventory_item

	var current_count = 0
	
	if current_item != "":
		if "seed_inventory" in GameData and GameData.seed_inventory.has(current_item):
			current_count = GameData.seed_inventory[current_item]
		elif "crop_inventory" in GameData and GameData.crop_inventory.has(current_item):
			current_count = GameData.crop_inventory[current_item]
		elif "animal_inventory" in GameData and GameData.animal_inventory.has(current_item):
			current_count = GameData.animal_inventory[current_item]

	# Dynamic Label Updates
	if seeds_label:
		seeds_label.text = str(current_count) if current_item != "" else "-"
		
	if wheat_label:
		wheat_label.text = current_item if current_item != "" else "None"

	# 3 & 4. Dynamic Icon Updates (Checks SEED_DATA, ANIMAL_DATA, and CROP_TEXTURES / CROP_ICON)
	var icon_path = ""
	var crop_icon_path = ""

	if current_item != "":
		if "SEED_DATA" in GameData and GameData.SEED_DATA.has(current_item):
			var data = GameData.SEED_DATA[current_item]
			icon_path = data.get("icon", "")
			crop_icon_path = data.get("crop_icon", "")
		elif "ANIMAL_DATA" in GameData and GameData.ANIMAL_DATA.has(current_item):
			var data = GameData.ANIMAL_DATA[current_item]
			icon_path = data.get("icon", "")
			crop_icon_path = data.get("icon", "")
		elif "SEED_DATA" in GameData and GameData.SEED_DATA.has(current_item): # Backup check
			pass
		# Kung ang item ay nasa crop_inventory (tulad ng Pesticide, Fertilizer, Produce, etc.)
		elif "crop_inventory" in GameData and GameData.crop_inventory.has(current_item):
			if "SEED_DATA" in GameData and GameData.SEED_DATA.has(current_item):
				crop_icon_path = GameData.SEED_DATA[current_item].get("crop_icon", "")
			# O kaya kung nakatabi sa inventory_ui textures, pwede rin nating direktang ilagay ang path:
			elif current_item == "Pesticide":
				crop_icon_path = "res://images/assets/for main (crops)/pest control station/pesticides.png"
			elif current_item == "Organic Fertilizer":
				crop_icon_path = "res://images/assets/for main (crops)/fertilizer/fertilizer.png"
			elif current_item == "Egg":
				crop_icon_path = "res://images/assets/for main (crops)/egg/egg.png"
			elif current_item == "Milk":
				crop_icon_path = "res://images/assets/for main (crops)/milk/milk.png"

	# Set Middle Icon (Seed Pack / Item Icon)
	if seed_icon:
		if icon_path != "" and ResourceLoader.exists(icon_path):
			seed_icon.texture = load(icon_path)
			seed_icon.visible = true
		else:
			seed_icon.texture = null

	# Set Rightmost Icon (Crop / Animal / Pesticide Sprite)
	if wheat_icon:
		if crop_icon_path != "" and ResourceLoader.exists(crop_icon_path):
			wheat_icon.texture = load(crop_icon_path)
			wheat_icon.visible = true
		else:
			wheat_icon.texture = null

func _update_hotbar_selection() -> void:
	if not GameData or not "ActiveItem" in GameData or not "selected_item" in GameData:
		return

	var current = GameData.selected_item
	
	# Explicitly show only the active selection border
	if hoe_border:
		hoe_border.visible = (current == GameData.ActiveItem.HOE)
	if water_border:
		water_border.visible = (current == GameData.ActiveItem.WATERING_CAN)
	if seed_border:
		seed_border.visible = (current == GameData.ActiveItem.SEED)
