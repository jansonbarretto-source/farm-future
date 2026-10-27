extends Control

@onready var slot_seed: Control = $Slot_Seed
@onready var slot_seed_icon: TextureRect = $Slot_Seed/Icon
@onready var seed_popup: PanelContainer = $Slot_Seed/SeedMenuPopup

@onready var slot_hoe: Control = get_node_or_null("Slot_Hoe")
@onready var slot_water: Control = get_node_or_null("Slot_WateringCan")

var seed_grid: GridContainer
var is_popup_open: bool = false

func _ready() -> void:
	if seed_popup:
		seed_popup.hide()
		seed_popup.mouse_filter = Control.MOUSE_FILTER_PASS
		_style_popup_window()
		_setup_grid_container()
	
	if slot_seed:
		slot_seed.mouse_filter = Control.MOUSE_FILTER_STOP
		slot_seed.gui_input.connect(_on_slot_gui_input)

	if slot_hoe:
		slot_hoe.gui_input.connect(func(event): _on_tool_slot_gui_input(event, GameData.ActiveItem.HOE))
		
	if slot_water:
		slot_water.gui_input.connect(func(event): _on_tool_slot_gui_input(event, GameData.ActiveItem.WATERING_CAN))
		
	if GameData and GameData.has_signal("data_changed"):
		if not GameData.data_changed.is_connected(_on_data_changed):
			GameData.data_changed.connect(_on_data_changed)
		_on_data_changed()

func _setup_grid_container() -> void:
	var existing_scroll = seed_popup.get_node_or_null("ScrollContainer")
	if existing_scroll:
		existing_scroll.queue_free()
		
	var existing_grid = seed_popup.get_node_or_null("SeedGrid")
	if existing_grid:
		seed_grid = existing_grid
	else:
		seed_grid = GridContainer.new()
		seed_grid.name = "SeedGrid"
		seed_grid.columns = 4
		seed_grid.add_theme_constant_override("h_separation", 6)
		seed_grid.add_theme_constant_override("v_separation", 6)
		seed_popup.add_child(seed_grid)
	
	seed_popup.custom_minimum_size = Vector2(0, 0)
	seed_grid.mouse_filter = Control.MOUSE_FILTER_PASS

func _style_popup_window() -> void:
	var popup_style = StyleBoxFlat.new()
	popup_style.bg_color = Color(0.14, 0.09, 0.06, 0.96)
	popup_style.border_color = Color(0.45, 0.31, 0.18, 1.0)
	popup_style.set_border_width_all(4)
	popup_style.set_corner_radius_all(8)
	popup_style.set_content_margin_all(8)
	popup_style.shadow_color = Color(0, 0, 0, 0.6)
	popup_style.shadow_size = 6
	seed_popup.add_theme_stylebox_override("panel", popup_style)

func _on_data_changed() -> void:
	_auto_fallback_seed_if_empty()
	_update_slot_icon()
	if is_popup_open:
		_refresh_seed_menu()

func _auto_fallback_seed_if_empty() -> void:
	if not GameData:
		return
		
	var current_seed = GameData.selected_seed_type
	var current_count = GameData.seed_inventory.get(current_seed, 0)
	
	if current_count <= 0:
		for seed_name in GameData.seed_inventory.keys():
			if GameData.seed_inventory[seed_name] > 0:
				GameData.select_seed_type(seed_name)
				return

func _update_slot_icon() -> void:
	if not GameData or not slot_seed_icon:
		return
		
	var current_seed = GameData.selected_seed_type
	if GameData.SEED_DATA.has(current_seed):
		var data = GameData.SEED_DATA[current_seed]
		if data.has("icon") and ResourceLoader.exists(data["icon"]):
			slot_seed_icon.texture = load(data["icon"])

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_1:
			GameData.select_item(GameData.ActiveItem.HOE)
		elif event.keycode == KEY_2:
			GameData.select_item(GameData.ActiveItem.WATERING_CAN)
		elif event.keycode == KEY_3:
			GameData.select_item(GameData.ActiveItem.SEED)
		elif event.keycode == KEY_TAB: # Inalis na ang KEY_E dito para malayang magamit sa Market Stall
			_cycle_seed(1)

	if is_popup_open and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if seed_popup and not seed_popup.get_global_rect().has_point(event.global_position):
				if slot_seed and slot_seed.get_global_rect().has_point(event.global_position):
					return
				_hide_popup()

func _on_tool_slot_gui_input(event: InputEvent, item: GameData.ActiveItem) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		GameData.select_item(item)

func _on_slot_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if GameData:
				GameData.select_item(GameData.ActiveItem.SEED)
				
			if is_popup_open:
				_hide_popup()
			else:
				_show_popup()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cycle_seed(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cycle_seed(-1)

func _cycle_seed(direction: int) -> void:
	if not GameData:
		return

	var owned_seeds: Array = []
	for seed_name in GameData.seed_inventory.keys():
		if GameData.seed_inventory[seed_name] > 0:
			owned_seeds.append(seed_name)
			
	if owned_seeds.size() == 0:
		print("[HOTBAR] No seeds available in inventory!")
		return
		
	var current_index = owned_seeds.find(GameData.selected_seed_type)
	if current_index == -1:
		current_index = 0
	else:
		current_index = (current_index + direction) % owned_seeds.size()
		if current_index < 0:
			current_index = owned_seeds.size() - 1
			
	var next_seed = owned_seeds[current_index]
	GameData.select_seed_type(next_seed)
	GameData.select_item(GameData.ActiveItem.SEED)
	print("[HOTBAR] Equipped Seed: ", next_seed)

func _show_popup() -> void:
	_refresh_seed_menu()
	if seed_popup and seed_grid.get_child_count() > 0:
		seed_popup.show()
		seed_popup.position = Vector2(-270, -135)
		is_popup_open = true

func _hide_popup() -> void:
	if seed_popup:
		seed_popup.hide()
		is_popup_open = false

func _refresh_seed_menu() -> void:
	if not seed_grid:
		return

	for child in seed_grid.get_children():
		child.queue_free()

	for seed_name in GameData.seed_inventory.keys():
		var count = GameData.seed_inventory[seed_name]
		if count > 0:
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(72, 52)
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
			
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.08, 0.05, 0.03, 0.9)
			btn_style.border_color = Color(0.28, 0.18, 0.1, 1.0)
			
			if seed_name == GameData.selected_seed_type:
				btn_style.border_color = Color(1.0, 0.85, 0.2, 1.0)
				btn_style.bg_color = Color(0.22, 0.15, 0.08, 0.95)
				
			btn_style.set_border_width_all(2)
			btn_style.set_corner_radius_all(6)
			
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_stylebox_override("hover", btn_style)
			btn.add_theme_stylebox_override("pressed", btn_style)
			
			var center_container = CenterContainer.new()
			center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
			center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(center_container)
			
			var vbox = VBoxContainer.new()
			vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			vbox.add_theme_constant_override("separation", 2)
			vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			center_container.add_child(vbox)
			
			var data = GameData.SEED_DATA.get(seed_name, {})
			
			if data.has("icon") and ResourceLoader.exists(data["icon"]):
				var icon_rect = TextureRect.new()
				icon_rect.custom_minimum_size = Vector2(22, 22)
				icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon_rect.texture = load(data["icon"])
				icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				vbox.add_child(icon_rect)
			
			var name_label = Label.new()
			name_label.text = seed_name
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_label.add_theme_font_size_override("font_size", 9)
			name_label.add_theme_color_override("font_color", Color(1, 1, 1))
			name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
			name_label.add_theme_constant_override("outline_size", 3)
			name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(name_label)
			
			var count_label = Label.new()
			count_label.text = "x" + str(count)
			count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			count_label.add_theme_font_size_override("font_size", 9)
			count_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.65))
			count_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
			count_label.add_theme_constant_override("outline_size", 3)
			count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(count_label)
			
			var target_seed = seed_name
			btn.pressed.connect(func(): _on_seed_button_pressed(target_seed))
			
			seed_grid.add_child(btn)

func _on_seed_button_pressed(seed_name: String) -> void:
	if GameData:
		GameData.select_seed_type(seed_name)
		GameData.select_item(GameData.ActiveItem.SEED)
		
	print("[UI] Successfully Selected and Equipped Seed: ", seed_name)
	_update_slot_icon()
	_hide_popup()
