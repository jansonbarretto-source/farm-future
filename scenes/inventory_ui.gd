extends Control

@onready var grid_container: GridContainer = $GridContainer

# Map crop & produce names to item textures based on FileSystem paths
@export var crop_textures: Dictionary = {
	"Wheat": preload("res://images/assets/Inventory (Fruits)/Wheattt.png"),
	"Carrot": preload("res://images/assets/Inventory (Fruits)/Carrots.png"),
	"Potato": preload("res://images/assets/Inventory (Fruits)/Potato.png"),
	"Tomato": preload("res://images/assets/Inventory (Fruits)/Tomato.png"),
	"Apple": preload("res://images/assets/Inventory (Fruits)/Apple.png"),
	"Banana": preload("res://images/assets/Inventory (Fruits)/Banana.png"),
	"Corn": preload("res://images/assets/Inventory (Fruits)/Corn.png"),
	"Mango": preload("res://images/assets/Inventory (Fruits)/Mango.png"),
	"Rice": preload("res://images/assets/Inventory (Fruits)/Rice.png"),
	"Strawberry": preload("res://images/assets/Inventory (Fruits)/Straberry.png"),
	
	# UPDATED ITEM TEXTURES FOR LIVESTOCK PRODUCE & FERTILIZER
	"Egg": preload("res://images/assets/Inventory (Fruits)/egg.png"),
	"Milk": preload("res://images/assets/Inventory (Fruits)/milk.png"),
	"Manure": preload("res://images/assets/for main (crops)/manure/manure.png"),
	"Organic Fertilizer": preload("res://images/assets/for main (crops)/fertilizer/fertilizer.png"),
	"Wool": preload("res://images/assets/for main (crops)/wool/wool.png"),
}

@export var lock_texture: Texture2D = preload("res://Lock.png") 

# Slot Configuration: 6 Available + 6 Locked = 12 Total Slots
@export var max_slots: int = 12 
@export var unlocked_slots: int = 6 

# UI Components & Animation Vars
var bg_panel: PanelContainer
var title_label: Label
var is_inventory_open: bool = true
var is_animating: bool = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_setup_code_designed_panel()
	
	if GameData.has_signal("data_changed"):
		GameData.data_changed.connect(update_inventory_ui)
	update_inventory_ui()

func _setup_code_designed_panel() -> void:
	bg_panel = PanelContainer.new()
	bg_panel.name = "CodeBackground"
	bg_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	bg_panel.offset_left = -230
	bg_panel.offset_top = -340
	bg_panel.offset_right = -15
	bg_panel.offset_bottom = -15
	bg_panel.pivot_offset = Vector2(107, 162)
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.12, 0.08, 0.05, 0.96)
	style_box.border_color = Color(0.58, 0.40, 0.22, 1.0)
	style_box.set_border_width_all(4)
	style_box.border_width_top = 6
	style_box.set_corner_radius_all(10)
	style_box.set_expand_margin_all(12)
	style_box.shadow_color = Color(0, 0, 0, 0.6)
	style_box.shadow_size = 10
	bg_panel.add_theme_stylebox_override("panel", style_box)
	
	add_child(bg_panel)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.name = "ContentVBox"
	content_vbox.add_theme_constant_override("separation", 6)
	bg_panel.add_child(content_vbox)
	
	title_label = Label.new()
	title_label.text = "INVENTORY"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	title_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	title_label.add_theme_constant_override("outline_size", 6)
	content_vbox.add_child(title_label)
	
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color(0.58, 0.40, 0.22, 0.8)
	content_vbox.add_child(divider)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 2)
	content_vbox.add_child(spacer)
	
	if grid_container:
		grid_container.reparent(content_vbox)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F or event.physical_keycode == KEY_F:
			toggle_inventory()

func toggle_inventory() -> void:
	if is_animating:
		return
		
	is_animating = true
	is_inventory_open = not is_inventory_open
	
	var target_alpha: float = 1.0 if is_inventory_open else 0.0
	var target_scale: Vector2 = Vector2.ONE if is_inventory_open else Vector2(0.8, 0.8)
	
	if is_inventory_open:
		bg_panel.visible = true
	
	var tween = create_tween().set_parallel(true)
	if is_inventory_open:
		tween.tween_property(bg_panel, "modulate:a", target_alpha, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(bg_panel, "scale", target_scale, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		tween.tween_property(bg_panel, "modulate:a", target_alpha, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(bg_panel, "scale", target_scale, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	tween.chain().tween_callback(func():
		is_animating = false
		if not is_inventory_open:
			bg_panel.visible = false
	)

func update_inventory_ui() -> void:
	if not grid_container:
		return

	for child in grid_container.get_children():
		child.queue_free()

	grid_container.columns = 3
	grid_container.add_theme_constant_override("h_separation", 8)
	grid_container.add_theme_constant_override("v_separation", 8)

	var inv = GameData.crop_inventory if "crop_inventory" in GameData else GameData.inventory
	var owned_crops = []
	for crop_name in inv.keys():
		if inv[crop_name] > 0:
			owned_crops.append(crop_name)

	for i in range(max_slots):
		var slot_panel = PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(58, 58)
		slot_panel.pivot_offset = Vector2(29, 29)
		
		var default_style = StyleBoxFlat.new()
		default_style.bg_color = Color(0.09, 0.06, 0.04, 0.95)
		default_style.border_color = Color(0.35, 0.23, 0.14, 1.0)
		default_style.set_border_width_all(2)
		default_style.set_corner_radius_all(6)
		slot_panel.add_theme_stylebox_override("panel", default_style)

		if i >= unlocked_slots:
			# --- LOCKED SLOT ---
			var locked_style = StyleBoxFlat.new()
			locked_style.bg_color = Color(0.04, 0.03, 0.02, 0.95)
			locked_style.border_color = Color(0.2, 0.13, 0.08, 1.0)
			locked_style.set_border_width_all(2)
			locked_style.set_corner_radius_all(6)
			slot_panel.add_theme_stylebox_override("panel", locked_style)

			var lock_rect = TextureRect.new()
			lock_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			lock_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			lock_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			lock_rect.modulate = Color(0.5, 0.5, 0.5, 0.6)
			if lock_texture:
				lock_rect.texture = lock_texture
			slot_panel.add_child(lock_rect)
			
		elif i < owned_crops.size():
			# --- UNLOCKED & FILLED SLOT ---
			var crop_name = owned_crops[i]
			var count = inv[crop_name]
			
			slot_panel.tooltip_text = crop_name + " (x" + str(count) + ")"
			
			# Check if selected
			var is_selected = ("selected_seed_type" in GameData and GameData.selected_seed_type == crop_name)
			
			var slot_style = default_style.duplicate()
			if is_selected:
				slot_style.border_color = Color(0.95, 0.75, 0.35, 1.0)
				slot_style.set_border_width_all(2)
			slot_panel.add_theme_stylebox_override("panel", slot_style)
			
			# Crop/Produce Icon
			var icon_rect = TextureRect.new()
			icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			icon_rect.offset_left = 4
			icon_rect.offset_top = 4
			icon_rect.offset_right = -4
			icon_rect.offset_bottom = -4
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			if crop_textures.has(crop_name):
				icon_rect.texture = crop_textures[crop_name]
			slot_panel.add_child(icon_rect)
			
			# Count Label
			var label = Label.new()
			label.text = "x" + str(count)
			label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			label.offset_left = -22
			label.offset_top = -16
			label.offset_right = -4
			label.offset_bottom = -2
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			label.add_theme_font_size_override("font_size", 11)
			label.add_theme_color_override("font_color", Color(1, 1, 1))
			label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
			label.add_theme_constant_override("outline_size", 4)
			slot_panel.add_child(label)
			
			# Hover Style
			var hover_style = slot_style.duplicate()
			hover_style.border_color = Color(0.95, 0.75, 0.35, 1.0)
			hover_style.set_border_width_all(2)

			slot_panel.mouse_entered.connect(func():
				slot_panel.add_theme_stylebox_override("panel", hover_style)
				var tween = create_tween()
				tween.tween_property(slot_panel, "scale", Vector2(1.08, 1.08), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			)
			
			slot_panel.mouse_exited.connect(func():
				slot_panel.add_theme_stylebox_override("panel", slot_style)
				var tween = create_tween()
				tween.tween_property(slot_panel, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			)

			# Click slot to select item & change cursor state
			slot_panel.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					if GameData.has_method("select_seed_type"):
						GameData.select_seed_type(crop_name)
					
					# Set pointing hand shape when selecting Wheat, Feed, Produce, or Fertilizer
					if crop_name in ["Wheat", "Egg", "Milk", "Manure", "Organic Fertilizer"]:
						Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
					else:
						Input.set_default_cursor_shape(Input.CURSOR_ARROW)
						
					print("Selected item from inventory: ", crop_name)
			)

		grid_container.add_child(slot_panel)
