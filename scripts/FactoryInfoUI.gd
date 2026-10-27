extends Control

# Master Recipe Dictionary for all 11 Artisan Products
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

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func set_recipe(_product_name: String) -> void:
	pass

func _close_panel() -> void:
	if get_parent() is CanvasLayer:
		get_parent().queue_free()
	else:
		queue_free()

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
		
	# Fullscreen overlay background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.65)
	bg.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			_close_panel()
	)
	add_child(bg)
	
	# Center Container ensures middle alignment
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	# Main Panel Box
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 360)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.05, 0.98)
	style.border_color = Color(0.58, 0.40, 0.22, 1.0)
	style.set_border_width_all(4)
	style.border_width_top = 6
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.7)
	style.shadow_size = 12
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	
	# Margin Container
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	# Title Label
	var title = Label.new()
	title.text = "🏭 FACTORY RECIPE CATALOG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	title.add_theme_constant_override("outline_size", 4)
	vbox.add_child(title)
	
	# Divider
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color(0.58, 0.40, 0.22, 0.8)
	vbox.add_child(divider)
	
	# Scroll Container for 11 recipes
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(420, 240)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(list_vbox)
	
	# Render all 11 recipes
	for product_name in RECIPES.keys():
		var recipe = RECIPES[product_name]
		var recipe_card = _create_recipe_row(product_name, recipe)
		list_vbox.add_child(recipe_card)
		
	# Close Hint
	var hint_label = Label.new()
	hint_label.text = "Press [E] or Click anywhere to close"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 10)
	hint_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	vbox.add_child(hint_label)

func _create_recipe_row(product_name: String, recipe: Dictionary) -> PanelContainer:
	var row_panel = PanelContainer.new()
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var row_style = StyleBoxFlat.new()
	row_style.bg_color = Color(0.08, 0.05, 0.03, 0.9)
	row_style.border_color = Color(0.35, 0.23, 0.14, 0.8)
	row_style.set_border_width_all(2)
	row_style.set_corner_radius_all(6)
	row_panel.add_theme_stylebox_override("panel", row_style)
	
	var row_margin = MarginContainer.new()
	row_margin.add_theme_constant_override("margin_left", 8)
	row_margin.add_theme_constant_override("margin_right", 8)
	row_margin.add_theme_constant_override("margin_top", 6)
	row_margin.add_theme_constant_override("margin_bottom", 6)
	row_panel.add_child(row_margin)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	row_margin.add_child(hbox)
	
	# Input Item
	var input_box = _create_item_box(recipe["input"], recipe["in_qty"])
	hbox.add_child(input_box)
	
	# Arrow
	var arrow = Label.new()
	arrow.text = "➔"
	arrow.add_theme_font_size_override("font_size", 16)
	arrow.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	hbox.add_child(arrow)
	
	# Output Item
	var output_box = _create_item_box(product_name, recipe["out_qty"])
	hbox.add_child(output_box)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	
	# Time
	var time_label = Label.new()
	time_label.text = "⏱️ " + str(recipe["time"]) + "s"
	time_label.add_theme_font_size_override("font_size", 12)
	time_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	hbox.add_child(time_label)
	
	return row_panel

func _create_item_box(item_name: String, qty: int) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	
	var slot = PanelContainer.new()
	slot.custom_minimum_size = Vector2(32, 32)
	
	var slot_style = StyleBoxFlat.new()
	slot_style.bg_color = Color(0.05, 0.03, 0.02, 1.0)
	slot_style.border_color = Color(0.4, 0.3, 0.2, 1.0)
	slot_style.set_border_width_all(1)
	slot_style.set_corner_radius_all(4)
	slot.add_theme_stylebox_override("panel", slot_style)
	hbox.add_child(slot)
	
	var icon_rect = TextureRect.new()
	icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	if GameData and GameData.SEED_DATA.has(item_name):
		var icon_path = GameData.SEED_DATA[item_name].get("crop_icon", "")
		if icon_path != "" and ResourceLoader.exists(icon_path):
			icon_rect.texture = load(icon_path)
	slot.add_child(icon_rect)
	
	var label = Label.new()
	label.text = item_name + " x" + str(qty)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 3)
	hbox.add_child(label)
	
	return hbox

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.physical_keycode == KEY_E or event.keycode == KEY_ESCAPE:
			_close_panel()
