extends Control

@onready var slot_seed: Control = $Slot_Seed
@onready var slot_seed_icon: TextureRect = $Slot_Seed/Icon
@onready var seed_popup: PanelContainer = $Slot_Seed/SeedMenuPopup

var seed_list: Container
var is_popup_open: bool = false

func _ready() -> void:
	if seed_popup:
		seed_popup.hide()
		seed_popup.mouse_filter = Control.MOUSE_FILTER_PASS
		_style_popup_window()
		_setup_scrollable_container()
	
	if slot_seed:
		slot_seed.gui_input.connect(_on_slot_gui_input)
		
	if GameData and GameData.has_signal("data_changed"):
		if not GameData.data_changed.is_connected(_on_data_changed):
			GameData.data_changed.connect(_on_data_changed)
		_on_data_changed()

func _setup_scrollable_container() -> void:
	var existing = seed_popup.get_node_or_null("ScrollContainer")
	var scroll: ScrollContainer
	
	if existing:
		scroll = existing
	else:
		scroll = ScrollContainer.new()
		scroll.name = "ScrollContainer"
		seed_popup.add_child(scroll)
	
	scroll.custom_minimum_size = Vector2(320, 75)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	# HINDI HARARANGIN ANG CLICKS SA BUTTONS
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var hbox = scroll.get_node_or_null("SeedList")
	if not hbox:
		hbox = HBoxContainer.new()
		hbox.name = "SeedList"
		hbox.add_theme_constant_override("separation", 8)
		scroll.add_child(hbox)
		
	hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	seed_list = hbox

func _style_popup_window() -> void:
	var popup_style = StyleBoxFlat.new()
	popup_style.bg_color = Color(0.14, 0.09, 0.06, 0.96)
	popup_style.border_color = Color(0.45, 0.31, 0.18, 1.0)
	popup_style.set_border_width_all(4)
	popup_style.set_corner_radius_all(8)
	popup_style.set_expand_margin_all(8)
	popup_style.shadow_color = Color(0, 0, 0, 0.6)
	popup_style.shadow_size = 6
	seed_popup.add_theme_stylebox_override("panel", popup_style)

func _on_data_changed() -> void:
	_update_slot_icon()
	if is_popup_open:
		_refresh_seed_menu()

func _update_slot_icon() -> void:
	var current_seed = GameData.selected_seed_type
	if GameData.SEED_DATA.has(current_seed):
		var data = GameData.SEED_DATA[current_seed]
		if data.has("icon") and ResourceLoader.exists(data["icon"]) and slot_seed_icon:
			slot_seed_icon.texture = load(data["icon"])

func _unhandled_input(event: InputEvent) -> void:
	if is_popup_open and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Tiyakin na sa labas lang ng popup iki-click bago mag-close
			if seed_popup and not seed_popup.get_global_rect().has_point(event.global_position):
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

	for child in seed_list.get_children():
		child.queue_free()

	for seed_name in GameData.seed_inventory.keys():
		var count = GameData.seed_inventory[seed_name]
		if count > 0:
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(85, 58)
			
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.08, 0.05, 0.03, 0.85)
			btn_style.border_color = Color(0.28, 0.18, 0.1, 1.0)
			
			if seed_name == GameData.selected_seed_type:
				btn_style.border_color = Color(1.0, 0.85, 0.2, 1.0)
				btn_style.bg_color = Color(0.22, 0.15, 0.08, 0.9)
				
			btn_style.set_border_width_all(2)
			btn_style.set_corner_radius_all(6)
			
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_stylebox_override("hover", btn_style)
			btn.add_theme_stylebox_override("pressed", btn_style)
			
			var vbox = VBoxContainer.new()
			vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
			vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(vbox)
			
			var data = GameData.SEED_DATA.get(seed_name, {})
			
			if data.has("icon") and ResourceLoader.exists(data["icon"]):
				var icon_rect = TextureRect.new()
				icon_rect.custom_minimum_size = Vector2(24, 24)
				icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon_rect.texture = load(data["icon"])
				icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				vbox.add_child(icon_rect)
			
			var name_label = Label.new()
			name_label.text = seed_name
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_label.add_theme_font_size_override("font_size", 10)
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
			
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
			
			# DIRECT GUI INPUT HANDLER FOR GUARANTEED CLICKS
			var current_name = seed_name
			btn.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_on_select_seed(current_name)
			)
			
			seed_list.add_child(btn)

func _on_select_seed(seed_name: String) -> void:
	GameData.select_seed_type(seed_name)
	GameData.select_item(GameData.ActiveItem.SEED)
	print("[UI] Successfully Selected Seed: ", seed_name)
	_update_slot_icon()
	_hide_popup()
