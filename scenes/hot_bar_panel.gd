extends Control

@onready var slot_seed: Control = $Slot_Seed
@onready var slot_seed_icon: TextureRect = $Slot_Seed/Icon
@onready var seed_popup: PanelContainer = $Slot_Seed/SeedMenuPopup
@onready var seed_list: HBoxContainer = $Slot_Seed/SeedMenuPopup/SeedList

var is_popup_open: bool = false

func _ready() -> void:
	if seed_popup:
		seed_popup.hide()
	
	# Connect gui_input para sa Slot Seed button
	if slot_seed:
		slot_seed.gui_input.connect(_on_slot_gui_input)
		
	GameData.data_changed.connect(_on_data_changed)
	_on_data_changed()

func _on_data_changed() -> void:
	_update_slot_icon()
	_refresh_seed_menu()

# Nagpapadala ng tamang icon ng napiling seed sa Slot 3 Hotbar Box
func _update_slot_icon() -> void:
	var current_seed = GameData.selected_seed_type
	if GameData.SEED_DATA.has(current_seed):
		var data = GameData.SEED_DATA[current_seed]
		if data.has("icon") and ResourceLoader.exists(data["icon"]) and slot_seed_icon:
			slot_seed_icon.texture = load(data["icon"])

# Kapag nag-click sa labas ng slot at popup, kusa itong isasara
func _unhandled_input(event: InputEvent) -> void:
	if is_popup_open and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			await get_tree().create_timer(0.05).timeout
			_hide_popup()

func _on_slot_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_popup_open:
			_hide_popup()
		else:
			_show_popup()

func _show_popup() -> void:
	_refresh_seed_menu()
	if seed_popup and seed_list.get_child_count() > 0:
		seed_popup.show()
		is_popup_open = true

func _hide_popup() -> void:
	if seed_popup:
		seed_popup.hide()
		is_popup_open = false

func _refresh_seed_menu() -> void:
	if not seed_list:
		return

	# Linisin ang lumang mga buttons
	for child in seed_list.get_children():
		child.queue_free()

	# I-loop ang mga seeds na may stock sa inventory
	for seed_name in GameData.seed_inventory.keys():
		var count = GameData.seed_inventory[seed_name]
		if count > 0:
			var btn = Button.new()
			var data = GameData.SEED_DATA.get(seed_name, {})
			
			btn.text = seed_name + " (" + str(count) + ")"
			
			# I-load ang PNG icon mula sa SEED_DATA
			if data.has("icon") and ResourceLoader.exists(data["icon"]):
				btn.icon = load(data["icon"])
				btn.expand_icon = true
				btn.custom_minimum_size = Vector2(40, 40)

			# Highlight ang kasalukuyang active/selected seed
			if seed_name == GameData.selected_seed_type:
				btn.modulate = Color.YELLOW
			
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
			btn.pressed.connect(func(): _on_select_seed(seed_name))
			seed_list.add_child(btn)

func _on_select_seed(seed_name: String) -> void:
	GameData.select_seed_type(seed_name)
	print("Naselect na Seed: ", seed_name)
	_on_data_changed()
	_hide_popup()
