extends Area2D

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

@export var machine_name: String = "Factory Processing Station"

var is_processing: bool = false
var is_product_ready: bool = false

var current_product: String = ""
var current_output_qty: int = 1

var process_timer: Timer
var status_label: Label
var float_tween: Tween
var pulse_tween: Tween

@export var label_offset_y: float = -32.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	input_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_setup_timer()
	_setup_status_label()
	
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

func _on_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _setup_timer() -> void:
	process_timer = Timer.new()
	process_timer.one_shot = true
	process_timer.timeout.connect(_on_processing_finished)
	add_child(process_timer)

func _setup_status_label() -> void:
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.position = Vector2(-30, label_offset_y)
	status_label.custom_minimum_size = Vector2(60, 20)
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	status_label.add_theme_constant_override("outline_size", 4)
	add_child(status_label)
	status_label.visible = false

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_interaction()
		get_viewport().set_input_as_handled()

func _handle_interaction() -> void:
	# --- SURIN KUNG SARADO NA ANG MACHINE (8:00 PM HANGGANG 6:00 AM) ---
	if GameData and "current_hour" in GameData:
		var current_hour = GameData.current_hour
		if current_hour >= 20 or current_hour < 6:
			_show_closed_popup()
			return

	if is_product_ready:
		_collect_product()
		return
		
	if is_processing:
		var time_left = ceil(process_timer.time_left)
		print("[FACTORY] ", machine_name, " is processing! ", time_left, "s remaining.")
		return
		
	_open_input_panel()

func _show_closed_popup() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 200
	
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.modulate.a = 0.0 # Magsisimula sa transparent para sa smooth fade-in
	
	# Pinalinis at pinaganda ang UI Design (Modern Aesthetic)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.07, 0.15, 0.96) # Mas malalim at eleganteng kulay
	style.border_color = Color(1.0, 0.82, 0.40, 1.0) # Ginintuang border para mas lutang
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(22)
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 12
	panel.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = "🔒  FACTORY IS CLOSED  🔒\n\nOperating Hours:\n6:00 AM – 8:00 PM"
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.08))
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)
	
	canvas.add_child(panel)
	get_tree().root.add_child(canvas)
	
	# Eksaktong nakagitna ang pivot para sa smooth scaling mula center
	panel.scale = Vector2(0.8, 0.8)
	panel.pivot_offset = Vector2(140, 45)
	
	# Makinis at mas pinabilis na transition para sa panel
	var tween = create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Timer para sa awtomatikong pagkawala pagkalipas ng 3 segundo na may smooth fade-out
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(func():
		var fade = create_tween().set_parallel(true)
		fade.tween_property(panel, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fade.tween_property(panel, "scale", Vector2(0.9, 0.9), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fade.chain().tween_callback(canvas.queue_free)
	)

func _open_input_panel() -> void:
	var main_scene = get_tree().current_scene
	var existing_layer = main_scene.get_node_or_null("MachineInputUILayer")
	
	if existing_layer:
		existing_layer.queue_free()
		return

	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "MachineInputUILayer"
	
	var ui_node = Control.new()
	ui_node.name = "MachineInputUI"
	
	var ui_script = load("res://scripts/MachineInputUI.gd")
	if ui_script:
		ui_node.set_script(ui_script)
		canvas_layer.add_child(ui_node)
		main_scene.add_child(canvas_layer)
		ui_node.setup(self)
	else:
		print("[FACTORY ERROR] Could not find MachineInputUI.gd at res://scripts/MachineInputUI.gd!")

func start_specific_production(product_name: String, recipe: Dictionary, batches: int) -> void:
	var ingredient = recipe["input"]
	var req_amount = recipe["in_qty"] * batches
	
	if "crop_inventory" in GameData and GameData.crop_inventory.get(ingredient, 0) >= req_amount:
		GameData.crop_inventory[ingredient] -= req_amount
		GameData.data_changed.emit()
		
		current_product = product_name
		current_output_qty = recipe["out_qty"] * batches
		
		is_processing = true
		process_timer.wait_time = recipe["time"] * batches
		process_timer.start()
		
		if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("working"):
			sprite.play("working")
			
		_set_status_text("⚙️ PROCESSING...", Color(0.9, 0.7, 0.2))
		print("[FACTORY] Started making ", current_product, " (x", current_output_qty, ") in ", machine_name)
	else:
		print("[FACTORY WARNING] Not enough ", ingredient, " to process!")

func _on_processing_finished() -> void:
	is_processing = false
	is_product_ready = true
	
	if sprite and sprite.sprite_frames:
		if sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")
		else:
			sprite.stop()
			sprite.frame = 0
	
	_set_status_text("✨ " + current_product.to_upper() + " READY!", Color(0.2, 1.0, 0.4))
	_start_ready_animations()
	print("[FACTORY] ", current_product, " is ready to collect in ", machine_name, "!")

func _collect_product() -> void:
	if GameData:
		var already_owned = (GameData.crop_inventory.get(current_product, 0) > 0) or (GameData.animal_inventory.get(current_product, 0) > 0)
		var current_limit = GameData.unlocked_slots if "unlocked_slots" in GameData else 6
		
		if not already_owned and GameData.has_method("get_unique_item_count") and GameData.get_unique_item_count() >= current_limit:
			print("[FACTORY] Puno na ang imbentaryo! Hindi makolekta ang: ", current_product)
			
			var inventory_ui = get_tree().get_first_node_in_group("inventory_ui")
			if inventory_ui and inventory_ui.has_method("show_inventory_full_popup"):
				inventory_ui.show_inventory_full_popup()
			else:
				_trigger_fallback_inventory_full_popup()
				
			return

	is_product_ready = false
	_stop_label_animations()
	
	if "crop_inventory" in GameData:
		GameData.crop_inventory[current_product] = GameData.crop_inventory.get(current_product, 0) + current_output_qty
		GameData.data_changed.emit()
		
	print("[FACTORY] Collected x", current_output_qty, " ", current_product, "!")
	
	var tween = create_tween()
	tween.tween_property(status_label, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(func(): status_label.visible = false)
	
	_open_inventory_ui()

func _trigger_fallback_inventory_full_popup() -> void:
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.z_index = 1000
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.05, 0.95)
	style.border_color = Color(0.95, 0.75, 0.35, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.set_expand_margin_all(10)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = "⚠️ INVENTORY IS FULL\nBuy more slots to collect!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02, 1.0))
	label.add_theme_constant_override("outline_size", 4)
	panel.add_child(label)
	
	var canvas = CanvasLayer.new()
	canvas.layer = 128
	canvas.add_child(panel)
	get_tree().current_scene.add_child(canvas)
	
	panel.scale = Vector2(0.6, 0.6)
	panel.pivot_offset = Vector2(150, 30)
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.25)
	
	var timer = get_tree().create_timer(1.8)
	timer.timeout.connect(func():
		var fade_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		fade_tween.tween_property(panel, "modulate:a", 0.0, 0.4)
		fade_tween.chain().tween_callback(canvas.queue_free)
	)

func _open_inventory_ui() -> void:
	var main_scene = get_tree().current_scene
	var inv_node = main_scene.find_child("InventoryUI", true, false)
	
	if inv_node:
		if "is_inventory_open" in inv_node and not inv_node.is_inventory_open:
			if inv_node.has_method("toggle_inventory"):
				inv_node.toggle_inventory()
		elif inv_node.has_method("update_inventory_ui"):
			inv_node.update_inventory_ui()

func _set_status_text(text_string: String, text_color: Color) -> void:
	if not status_label:
		return
		
	_stop_label_animations()
	status_label.text = text_string
	status_label.add_theme_color_override("font_color", text_color)
	status_label.visible = true
	status_label.pivot_offset = Vector2(30, 10)
	status_label.scale = Vector2(0.5, 0.5)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(status_label, "modulate:a", 1.0, 0.2)
	tween.tween_property(status_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _stop_label_animations() -> void:
	if float_tween and float_tween.is_running():
		float_tween.kill()
	if pulse_tween and pulse_tween.is_running():
		pulse_tween.kill()
		
	if status_label:
		status_label.position.y = label_offset_y
		status_label.scale = Vector2.ONE

func _start_ready_animations() -> void:
	_stop_label_animations()
	if not status_label:
		return
		
	status_label.pivot_offset = Vector2(30, 10)
	
	float_tween = create_tween().set_loops()
	float_tween.tween_property(status_label, "position:y", label_offset_y - 5.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(status_label, "position:y", label_offset_y, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(status_label, "scale", Vector2(1.1, 1.1), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(status_label, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
