extends Control

@onready var slot_seed: Control = $Slot_Seed
@onready var seed_popup: PanelContainer = $Slot_Seed/SeedMenuPopup
@onready var seed_list: HBoxContainer = $Slot_Seed/SeedMenuPopup/SeedList

var is_popup_open: bool = false

func _ready() -> void:
	if seed_popup:
		seed_popup.hide()
	
	# I-connect LAMANG ang gui_input event para sa Left Click
	if slot_seed:
		slot_seed.gui_input.connect(_on_slot_gui_input)
		
	GameData.data_changed.connect(_refresh_seed_menu)
	_refresh_seed_menu()

# Kapag nag-click sa labas ng slot at popup, kusa itong isasara
func _unhandled_input(event: InputEvent) -> void:
	if is_popup_open and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Kaunting delay para makasigurong hindi na-click ang mismong seed button
			await get_tree().create_timer(0.05).timeout
			_hide_popup()

func _on_slot_gui_input(event: InputEvent) -> void:
	# Tinitiyak na LEFT CLICK lamang ang magbubukas/magsasara
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_popup_open:
			_hide_popup()
		else:
			_show_popup()

func _show_popup() -> void:
	_refresh_seed_menu()
	# Lalabas lamang kung mayroon kang kahit 1 seed sa inventory
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
			
			# I-load ang icon mula sa SEED_DATA kung mayroon
			if data.has("icon") and ResourceLoader.exists(data["icon"]):
				btn.icon = load(data["icon"])
				btn.expand_icon = true
				btn.custom_minimum_size = Vector2(40, 40)

			# Highlight ang kasalukuyang active/selected seed
			if seed_name == GameData.selected_seed_type:
				btn.modulate = Color.YELLOW
			
			# Para hindi mag-trigger ang _unhandled_input kapag pindot ang button
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
			
			btn.pressed.connect(func(): _on_select_seed(seed_name))
			seed_list.add_child(btn)

func _on_select_seed(seed_name: String) -> void:
	GameData.select_seed_type(seed_name)
	print("Naselect na Seed: ", seed_name)
	_refresh_seed_menu()
	_hide_popup()
