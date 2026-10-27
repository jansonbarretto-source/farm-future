extends Control

@onready var grid_container: GridContainer = $GridContainer

# Map crop, produce, livestock, and factory names to item textures based on FileSystem paths
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
	
	# LIVESTOCK PRODUCE & FERTILIZER
	"Egg": preload("res://images/assets/for main (crops)/egg/egg.png"),
	"Milk": preload("res://images/assets/for main (crops)/milk/milk.png"),
	"Manure": preload("res://images/assets/for main (crops)/manure/manure.png"),
	"Organic Fertilizer": preload("res://images/assets/for main (crops)/fertilizer/fertilizer.png"),
	"Wool": preload("res://images/assets/for main (crops)/wool/wool.png"),

	# LIVESTOCK ANIMALS (BOUGHT FROM MARKET)
	"Chicken": preload("res://images/assets/for livestock/chicken/chicken.png"),
	"Cow": preload("res://images/assets/for livestock/cow/cow.png"),
	"Pig": preload("res://images/assets/for livestock/pig/pig.png"),
	"Sheep": preload("res://images/assets/for livestock/sheep/with wool/sheep.png"),

	# PROCESSED FACTORY GOODS
	"Flour": preload("res://images/assets/for factory/flour.png"),
	"Cheese": preload("res://images/assets/for factory/cheese.png"),
	"Bread": preload("res://images/assets/for factory/bread.png"),
	"Yarn": preload("res://images/assets/for factory/yarn.png"),
	"Jam": preload("res://images/assets/for factory/jam.png"),
	"French Fries": preload("res://images/assets/for factory/french_fries.png"),
	"Tomato Ketchup": preload("res://images/assets/for factory/ketchup.png"),
	"Popcorn": preload("res://images/assets/for factory/popcorn.png"),
	"Banana Smoothie": preload("res://images/assets/for factory/banana_smoothie.png"),
	"Polished Rice Box": preload("res://images/assets/for factory/polished_rice.png"),
	"Carrot Juice": preload("res://images/assets/for factory/carrot_juice.png")
}

@export var lock_texture: Texture2D = preload("res://Lock.png") 

# Slot Configuration: 6 Available + 6 Locked = 12 Total Slots
@export var max_slots: int = 12 
@export var unlocked_slots: int = 6 

# UI Components & Animation Vars
var bg_panel: PanelContainer
var title_label: Label
var toggle_label: Label
var toggle_badge: PanelContainer
var is_inventory_open: bool = true
var is_animating: bool = false

# Keep track of previous inventory item quantities to detect new harvests/acquisitions
var _last_item_counts: Dictionary = {}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_setup_code_designed_panel()
	_setup_persistent_f_toggle_badge()
	
	if GameData.has_signal("data_changed"):
		GameData.data_changed.connect(_on_game_data_changed)
		
	_cache_item_counts()
	update_inventory_ui()

func _cache_item_counts() -> void:
	_last_item_counts.clear()
	if GameData:
		if "crop_inventory" in GameData:
			for k in GameData.crop_inventory.keys():
				_last_item_counts[k] = GameData.crop_inventory[k]
		if "animal_inventory" in GameData:
			for k in GameData.animal_inventory.keys():
				_last_item_counts[k] = GameData.animal_inventory.get(k, 0)

func _on_game_data_changed() -> void:
	# Check if any item count increased (meaning a harvest or item addition occurred)
	var item_increased = false
	if GameData:
		var current_inv = GameData.crop_inventory if "crop_inventory" in GameData else {}
		var current_animal_inv = GameData.animal_inventory if "animal_inventory" in GameData else {}
		
		for k in current_inv.keys():
			var prev_qty = _last_item_counts.get(k, 0)
			var curr_qty = current_inv[k]
			if curr_qty > prev_qty:
				item_increased = true
				break
				
		if not item_increased:
			for k in current_animal_inv.keys():
				var prev_qty = _last_item_counts.get(k, 0)
				var curr_qty = current_animal_inv[k]
				if curr_qty > prev_qty:
					item_increased = true
					break

		_cache_item_counts()
		
		# If an item count increased, force open the inventory panel if it's currently closed
		if item_increased and not is_inventory_open:
			toggle_inventory() # Opens it up automatically

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
	
	# Header HBox (Title + F Key Hint Symbol)
	var header_hbox = HBoxContainer.new()
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_hbox.add_theme_constant_override("separation", 8)
	content_vbox.add_child(header_hbox)
	
	title_label = Label.new()
	title_label.text = "INVENTORY"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	title_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	title_label.add_theme_constant_override("outline_size", 6)
	header_hbox.add_child(title_label)
	
	# [F] Key Hide Label Symbol Header
	toggle_label = Label.new()
	toggle_label.text = "⌨️ [F] Hide"
	toggle_label.add_theme_font_size_override("font_size", 10)
	toggle_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	toggle_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	toggle_label.add_theme_constant_override("outline_size", 3)
	header_hbox.add_child(toggle_label)
	
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color(0.58, 0.40, 0.22, 0.8)
	content_vbox.add_child(divider)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 2)
	content_vbox.add_child(spacer)
	
	if grid_container:
		grid_container.reparent(content_vbox)

# Persistent HUD badge that stays visible on HUD when inventory is closed
func _setup_persistent_f_toggle_badge() -> void:
	toggle_badge = PanelContainer.new()
	toggle_badge.name = "FToggleHUDHint"
	toggle_badge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	toggle_badge.offset_left = -160
	toggle_badge.offset_top = -45
	toggle_badge.offset_right = -15
	toggle_badge.offset_bottom = -15
	
	var badge_style = StyleBoxFlat.new()
	badge_style.bg_color = Color(0.12, 0.08, 0.05, 0.9)
	badge_style.border_color = Color(0.58, 0.40, 0.22, 1.0)
	badge_style.set_border_width_all(2)
	badge_style.set_corner_radius_all(6)
	toggle_badge.add_theme_stylebox_override("panel", badge_style)
	
	var badge_label = Label.new()
	badge_label.text = "🎒 Press [F] Inventory"
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.add_theme_font_size_override("font_size", 11)
	badge_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	badge_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	badge_label.add_theme_constant_override("outline_size", 4)
	
	toggle_badge.add_child(badge_label)
	add_child(toggle_badge)
	toggle_badge.visible = false # Only visible when inventory panel is closed

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
		toggle_badge.visible = false
		if toggle_label:
			toggle_label.text = "⌨️ [F] Hide"
	else:
		toggle_badge.visible = true
	
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

	var inv: Dictionary = {}
	if GameData and "crop_inventory" in GameData:
		inv = GameData.crop_inventory
	elif GameData and "inventory" in GameData:
		inv = GameData.inventory

	var animal_inv: Dictionary = {}
	if GameData and "animal_inventory" in GameData:
		animal_inv = GameData.animal_inventory
	
	var owned_items = []
	
	# 1. Collect Crops, Produce, & Factory Goods
	for item_name in inv.keys():
		if inv[item_name] > 0 and not owned_items.has(item_name):
			owned_items.append(item_name)

	# 2. Collect Bought Animals
	for animal_name in animal_inv.keys():
		if animal_inv[animal_name] > 0 and not owned_items.has(animal_name):
			owned_items.append(animal_name)

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
			
		elif i < owned_items.size():
			# --- UNLOCKED & FILLED SLOT ---
			var item_name = owned_items[i]
			var count = inv.get(item_name, animal_inv.get(item_name, 0))
			
			slot_panel.tooltip_text = item_name + " (x" + str(count) + ")"
			
			# Check if selected
			var is_selected = ("selected_seed_type" in GameData and GameData.selected_seed_type == item_name)
			
			var slot_style = default_style.duplicate()
			if is_selected:
				slot_style.border_color = Color(0.95, 0.75, 0.35, 1.0)
				slot_style.set_border_width_all(2)
			slot_panel.add_theme_stylebox_override("panel", slot_style)
			
			# Icon Texture
			var icon_rect = TextureRect.new()
			icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			icon_rect.offset_left = 4
			icon_rect.offset_top = 4
			icon_rect.offset_right = -4
			icon_rect.offset_bottom = -4
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			if crop_textures.has(item_name):
				icon_rect.texture = crop_textures[item_name]
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

			# Click slot to select item/animal or Right-Click to deselect
			slot_panel.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed:
					if event.button_index == MOUSE_BUTTON_LEFT:
						if GameData.has_method("select_seed_type"):
							GameData.select_seed_type(item_name)
						
						# Items that use pointing hand cursor
						var hand_cursor_items = [
							"Wheat", "Egg", "Milk", "Manure", "Organic Fertilizer", "Wool",
							"Chicken", "Cow", "Pig", "Sheep",
							"Flour", "Cheese", "Bread", "Yarn", "Jam", "French Fries",
							"Tomato Ketchup", "Popcorn", "Banana Smoothie", "Polished Rice Box", "Carrot Juice"
						]
						
						if item_name in hand_cursor_items:
							Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
						else:
							Input.set_default_cursor_shape(Input.CURSOR_ARROW)
							
						print("Selected item from inventory: ", item_name)
						
					elif event.button_index == MOUSE_BUTTON_RIGHT:
						if GameData:
							GameData.selected_seed_type = ""
							GameData.data_changed.emit()
							Input.set_default_cursor_shape(Input.CURSOR_ARROW)
							print("[INVENTORY] Item deselected via right-click.")
			)

		grid_container.add_child(slot_panel)
