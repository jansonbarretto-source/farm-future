extends Control

const RECIPES = {
	"French Fries": { "input": "Potato", "in_qty": 1, "out_qty": 1, "time": 8.0 },
	"Flour": { "input": "Wheat", "in_qty": 1, "out_qty": 1, "time": 5.0 },
	"Cheese": { "input": "Milk", "in_qty": 1, "out_qty": 1, "time": 10.0 },
	"Bread": { "input": "Wheat", "in_qty": 2, "out_qty": 1, "time": 12.0 },
	"Yarn": { "input": "Wool", "in_qty": 1, "out_qty": 1, "time": 8.0 },
	"Jam": { "input": "Strawberry", "in_qty": 1, "out_qty": 1, "time": 10.0 },
	"Tomato Ketchup": { "input": "Tomato", "in_qty": 2, "out_qty": 1, "time": 7.0 },
	"Popcorn": { "input": "Corn", "in_qty": 1, "out_qty": 1, "time": 6.0 },
	"Banana Smoothie": { "input": "Banana", "in_qty": 1, "out_qty": 1, "time": 8.0 },
	"Polished Rice Box": { "input": "Rice", "in_qty": 1, "out_qty": 1, "time": 6.0 },
	"Carrot Juice": { "input": "Carrot", "in_qty": 1, "out_qty": 1, "time": 5.0 }
}

var target_machine: Node = null

func setup(machine: Node) -> void:
	target_machine = machine
	_build_ui()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if get_child_count() == 0 and target_machine:
		_build_ui()

func _close_panel() -> void:
	if get_parent() is CanvasLayer:
		get_parent().queue_free()
	else:
		queue_free()

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
		
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	bg.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			_close_panel()
	)
	add_child(bg)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 360)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.05, 0.98)
	style.border_color = Color(0.68, 0.48, 0.28, 1.0)
	style.set_border_width_all(4)
	style.border_width_top = 8
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.8)
	style.shadow_size = 14
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "⚙️ FACTORY PRODUCTION TERMINAL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.94, 0.8))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	title.add_theme_constant_override("outline_size", 4)
	vbox.add_child(title)
	
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color(0.68, 0.48, 0.28, 0.8)
	vbox.add_child(divider)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(454, 240)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(list_vbox)
	
	var inventory = GameData.crop_inventory if GameData and "crop_inventory" in GameData else {}
	var items_found: int = 0
	
	for product_name in RECIPES.keys():
		var recipe = RECIPES[product_name]
		var input_item = recipe["input"]
		var available_qty = inventory.get(input_item, 0)
		
		if available_qty >= recipe["in_qty"]:
			items_found += 1
			var row = _create_recipe_row(product_name, recipe, available_qty)
			list_vbox.add_child(row)
			
	if items_found == 0:
		var empty_lbl = Label.new()
		empty_lbl.text = "No processable ingredients found in inventory!\nHarvest crops or gather items first."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 11)
		empty_lbl.add_theme_color_override("font_color", Color(0.85, 0.65, 0.5))
		list_vbox.add_child(empty_lbl)
			
	var hint = Label.new()
	hint.text = "Click anywhere outside or press [Esc] to exit"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	vbox.add_child(hint)

func _create_recipe_row(product_name: String, recipe: Dictionary, available_qty: int) -> PanelContainer:
	var row_panel = PanelContainer.new()
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.06, 0.04, 0.95)
	style.border_color = Color(0.4, 0.27, 0.17, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	row_panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	row_panel.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)
	
	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(36, 36)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	if GameData and "SEED_DATA" in GameData and GameData.SEED_DATA.has(product_name):
		var p_data = GameData.SEED_DATA[product_name]
		if p_data.has("crop_icon") and ResourceLoader.exists(p_data["crop_icon"]):
			icon_rect.texture = load(p_data["crop_icon"])
	hbox.add_child(icon_rect)
	
	var label = Label.new()
	var input_name = recipe["input"]
	var req_qty = recipe["in_qty"]
	label.text = input_name + " (" + str(req_qty) + ") [Owned: " + str(available_qty) + "]\n➔ " + product_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 3)
	hbox.add_child(label)
	
	# Kalkulahin kung ilang batch ang magagawa at ang kabuuang oras
	var batches = int(available_qty / recipe["in_qty"])
	var total_time = recipe["time"] * batches
	
	var process_btn = Button.new()
	process_btn.text = "Process All (" + str(total_time) + "s)"
	process_btn.add_theme_font_size_override("font_size", 11)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.25, 0.45, 0.25, 1.0)
	btn_style.set_corner_radius_all(6)
	process_btn.add_theme_stylebox_override("normal", btn_style)
	
	process_btn.pressed.connect(func():
		if target_machine and target_machine.has_method("start_specific_production"):
			# Ipasa ang batches bilang multiplier para ubusin at iproseso lahat
			target_machine.start_specific_production(product_name, recipe, batches)
		_close_panel()
	)
	hbox.add_child(process_btn)
	
	return row_panel

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
			_close_panel()
