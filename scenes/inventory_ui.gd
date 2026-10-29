extends Control

@onready var grid_container: GridContainer = $GridContainer

@export var crop_textures: Dictionary = {
	"Wheat": preload("res://images/assets/Inventory (Fruits)/Wheattt.png"),
	"Carrot": preload("res://images/assets/Inventory (Fruits)/Carrots.png"),
	"Potato": preload("res://images/assets/for main (crops)/potato/potato.png"),
	"Tomato": preload("res://images/assets/for main (crops)/tomato/tomato.png"),
	"Apple": preload("res://images/assets/for main (crops)/apple/apple.png"),
	"Banana": preload("res://images/assets/for main (crops)/banana/banana.png"),
	"Corn": preload("res://images/assets/for main (crops)/corn/corn.png"),
	"Mango": preload("res://images/assets/for main (crops)/mango/mango.png"),
	"Rice": preload("res://images/assets/for main (crops)/rice/rice.png"),
	"Strawberry": preload("res://images/assets/for main (crops)/strawberry/strawberry.png"),
	
	# LIVESTOCK PRODUCE & FERTILIZER
	"Egg": preload("res://images/assets/for main (crops)/egg/egg.png"),
	"Milk": preload("res://images/assets/for main (crops)/milk/milk.png"),
	"Manure": preload("res://images/assets/for main (crops)/manure/manure.png"),
	"Organic Fertilizer": preload("res://images/assets/for main (crops)/fertilizer/fertilizer.png"),
	"Wool": preload("res://images/assets/for main (crops)/wool/wool.png"),
	"Pesticide": preload("res://images/assets/for main (crops)/pest control station/pesticides.png"),

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

@export var max_slots: int = 12 
@export var unlocked_slots: int = 6 
@export var slot_cost: int = 100 

var bg_panel: PanelContainer
var title_label: Label
var toggle_label: Label
var toggle_badge: PanelContainer
var is_inventory_open: bool = true
var is_animating: bool = false

var _last_item_counts: Dictionary = {}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	if GameData and "unlocked_slots" in GameData:
		unlocked_slots = GameData.unlocked_slots
	elif GameData:
		GameData.unlocked_slots = unlocked_slots
		
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
		if "seed_inventory" in GameData:
			for k in GameData.seed_inventory.keys():
				_last_item_counts[k] = GameData.seed_inventory.get(k, 0)

func _get_unique_item_count() -> int:
	var unique_items = []
	var inv = GameData.crop_inventory if GameData and "crop_inventory" in GameData else {}
	var animal_inv = GameData.animal_inventory if GameData and "animal_inventory" in GameData else {}
	var seed_inv = GameData.seed_inventory if GameData and "seed_inventory" in GameData else {}
	
	for k in inv.keys():
		if inv[k] > 0 and not unique_items.has(k):
			unique_items.append(k)
	for k in animal_inv.keys():
		if animal_inv[k] > 0 and not unique_items.has(k):
			unique_items.append(k)
	for k in seed_inv.keys():
		if seed_inv[k] > 0 and not unique_items.has(k):
			unique_items.append(k)
			
	return unique_items.size()

func _is_inventory_full() -> bool:
	var current_limit = GameData.unlocked_slots if GameData and "unlocked_slots" in GameData else unlocked_slots
	return _get_unique_item_count() >= current_limit

func _on_game_data_changed() -> void:
	update_inventory_ui()

func show_buy_slot_confirmation() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 129
	
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.05, 0.98)
	style.border_color = Color(0.95, 0.75, 0.35, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_expand_margin_all(18)
	style.shadow_color = Color(0, 0, 0, 0.7)
	style.shadow_size = 12
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)
	
	var msg_label = Label.new()
	msg_label.text = "🔒 UNLOCK INVENTORY SLOT?\n\nAre you sure you want to buy this slot\nfor ₱" + str(slot_cost) + "?"
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.add_theme_font_size_override("font_size", 15)
	msg_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	msg_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	msg_label.add_theme_constant_override("outline_size", 4)
	vbox.add_child(msg_label)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(hbox)
	
	var yes_btn = Button.new()
	yes_btn.text = "Yes, Buy"
	yes_btn.custom_minimum_size = Vector2(90, 36)
	
	var yes_style = StyleBoxFlat.new()
	yes_style.bg_color = Color(0.2, 0.5, 0.25, 1.0)
	yes_style.border_color = Color(0.4, 0.8, 0.45, 1.0)
	yes_style.set_border_width_all(2)
	yes_style.set_corner_radius_all(6)
	yes_btn.add_theme_stylebox_override("normal", yes_style)
	
	yes_btn.pressed.connect(func():
		var cost: int = 100
		if GameData and GameData.has_method("remove_money"):
			if GameData.remove_money(cost):
				unlocked_slots = min(unlocked_slots + 1, max_slots)
				if GameData:
					GameData.unlocked_slots = unlocked_slots 
				update_inventory_ui()
		canvas.queue_free()
	)
	hbox.add_child(yes_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(90, 36)
	
	var cancel_style = StyleBoxFlat.new()
	cancel_style.bg_color = Color(0.45, 0.2, 0.2, 1.0)
	cancel_style.border_color = Color(0.8, 0.4, 0.4, 1.0)
	cancel_style.set_border_width_all(2)
	cancel_style.set_corner_radius_all(6)
	cancel_btn.add_theme_stylebox_override("normal", cancel_style)
	
	cancel_btn.pressed.connect(func():
		canvas.queue_free()
	)
	hbox.add_child(cancel_btn)
	
	canvas.add_child(panel)
	get_tree().current_scene.add_child(canvas)

func show_pesticide_hint() -> void:
	# Hanapin ang Player node sa scene
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().current_scene.find_node("Player", true, false)

	if not player:
		return

	# Alisin muna ang lumang hint kung meron man para hindi magpatong-patong sa player
	var existing = player.find_child("PesticideHintPopup", false, false)
	if existing:
		existing.queue_free()

	var panel = PanelContainer.new()
	panel.name = "PesticideHintPopup"
	panel.z_index = 2000
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.05, 0.95)
	style.border_color = Color(0.95, 0.75, 0.35, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = "🧴 Press [E] to apply"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 3)
	panel.add_child(label)
	
	# Pwesto sa ibabaw mismo ng ulo/katawan ng player (local offset)
	panel.position = Vector2(-40, -55)
	
	panel.scale = Vector2(0.4, 0.4)
	panel.pivot_offset = Vector2(40, 15)
	
	# Ilagay DIRECTLY bilang child ng player para sumunod kahit saan magpunta ang player sa map
	player.add_child(panel)
	
	var tween = panel.create_tween()
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(func():
		if is_instance_valid(panel):
			var fade_tween = panel.create_tween().set_parallel(true)
			fade_tween.tween_property(panel, "modulate:a", 0.0, 0.4)
			fade_tween.tween_property(panel, "position:y", panel.position.y - 15, 0.4)
			fade_tween.chain().tween_callback(panel.queue_free)
	)

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
	toggle_badge.visible = false

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
	else:
		toggle_badge.visible = true
	
	var tween = create_tween().set_parallel(true)
	if is_inventory_open:
		tween.tween_property(bg_panel, "modulate:a", target_alpha, 0.25)
		tween.tween_property(bg_panel, "scale", target_scale, 0.25)
	else:
		tween.tween_property(bg_panel, "modulate:a", target_alpha, 0.18)
		tween.tween_property(bg_panel, "scale", target_scale, 0.18)
	
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

	var inv: Dictionary = GameData.crop_inventory if GameData and "crop_inventory" in GameData else {}
	var animal_inv: Dictionary = GameData.animal_inventory if GameData and "animal_inventory" in GameData else {}
	var seed_inv: Dictionary = GameData.seed_inventory if GameData and "seed_inventory" in GameData else {}
	
	var owned_items = []
	
	for item_name in inv.keys():
		if inv[item_name] > 0 and not owned_items.has(item_name):
			owned_items.append(item_name)

	for animal_name in animal_inv.keys():
		if animal_inv[animal_name] > 0 and not owned_items.has(animal_name):
			owned_items.append(animal_name)

	for seed_name in seed_inv.keys():
		if seed_inv[seed_name] > 0 and not owned_items.has(seed_name):
			owned_items.append(seed_name)

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
			var locked_style = StyleBoxFlat.new()
			locked_style.bg_color = Color(0.05, 0.035, 0.025, 0.95)
			locked_style.border_color = Color(0.25, 0.17, 0.11, 1.0)
			locked_style.set_border_width_all(2)
			locked_style.set_corner_radius_all(6)
			slot_panel.add_theme_stylebox_override("panel", locked_style)

			var vbox = VBoxContainer.new()
			vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
			vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			vbox.add_theme_constant_override("separation", 3)
			vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot_panel.add_child(vbox)

			var lock_rect = TextureRect.new()
			lock_rect.custom_minimum_size = Vector2(14, 14)
			lock_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			lock_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			lock_rect.modulate = Color(0.85, 0.75, 0.55, 0.9)
			lock_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if lock_texture:
				lock_rect.texture = lock_texture
			vbox.add_child(lock_rect)

			var buy_btn = Button.new()
			buy_btn.text = "Buy Slot"
			buy_btn.add_theme_font_size_override("font_size", 9)
			buy_btn.mouse_filter = Control.MOUSE_FILTER_STOP
			
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.3, 0.19, 0.11, 1.0)
			btn_style.border_color = Color(0.75, 0.55, 0.3, 1.0)
			btn_style.set_border_width_all(1)
			btn_style.set_corner_radius_all(4)
			buy_btn.add_theme_stylebox_override("normal", btn_style)
			
			buy_btn.pressed.connect(func():
				show_buy_slot_confirmation()
			)
			vbox.add_child(buy_btn)
			
			slot_panel.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					show_buy_slot_confirmation()
			)
			
		elif i < owned_items.size():
			var item_name = owned_items[i]
			var count = inv.get(item_name, animal_inv.get(item_name, seed_inv.get(item_name, 0)))
			
			slot_panel.tooltip_text = item_name + " (x" + str(count) + ")"
			
			var is_selected = false
			if GameData:
				if seed_inv.has(item_name):
					if "selected_seed_type" in GameData and GameData.selected_seed_type == item_name:
						is_selected = true
				else:
					if "selected_inventory_item" in GameData and GameData.selected_inventory_item == item_name:
						is_selected = true
			
			var slot_style = default_style.duplicate()
			if is_selected:
				slot_style.border_color = Color(0.95, 0.75, 0.35, 1.0)
				slot_style.set_border_width_all(3)
			slot_panel.add_theme_stylebox_override("panel", slot_style)
			
			var icon_rect = TextureRect.new()
			icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			icon_rect.offset_left = 4
			icon_rect.offset_top = 4
			icon_rect.offset_right = -4
			icon_rect.offset_bottom = -4
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			if crop_textures.has(item_name):
				icon_rect.texture = crop_textures[item_name]
			slot_panel.add_child(icon_rect)
			
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
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot_panel.add_child(label)
			
			var hover_style = slot_style.duplicate()
			hover_style.border_color = Color(0.95, 0.75, 0.35, 1.0)
			hover_style.set_border_width_all(3)

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

			slot_panel.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed:
					if event.button_index == MOUSE_BUTTON_LEFT:
						if GameData:
							if seed_inv.has(item_name):
								if GameData.has_method("select_seed_type"):
									GameData.select_seed_type(item_name)
							else:
								if GameData.has_method("select_inventory_item"):
									GameData.select_inventory_item(item_name)
								elif "selected_inventory_item" in GameData:
									GameData.selected_inventory_item = item_name
									GameData.selected_seed_type = ""
									GameData.data_changed.emit()
							
							# I-trigger ang hint directly sa ibabaw ng player kung nasaan man siya sa map
							if item_name == "Pesticide":
								show_pesticide_hint()
							
							print("[INVENTORY] Na-select ang item/hayop: ", item_name)
						
						Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
							
					elif event.button_index == MOUSE_BUTTON_RIGHT:
						if GameData:
							if GameData.has_method("deselect_current_item"):
								GameData.deselect_current_item()
							else:
								if "selected_inventory_item" in GameData:
									GameData.selected_inventory_item = ""
								if "selected_seed_type" in GameData:
									GameData.selected_seed_type = ""
								GameData.data_changed.emit()
							print("[INVENTORY] Na-deselect ang item.")
						Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			)

		grid_container.add_child(slot_panel)
