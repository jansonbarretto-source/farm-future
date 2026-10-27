extends Node2D

var displayed_item: String = ""
var stock_count: int = 0
var player_in_range: bool = false

var customer_queue: Array = []
@export var line_spacing: float = 24.0

@onready var stock_label: Label = $StockLabel
@onready var interaction_area: Area2D = $InteractionArea

var stock_panel_instance: Node = null

signal stock_changed(item_name: String, count: int)

func _ready() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
	
	if stock_label:
		stock_label.add_theme_color_override("font_color", Color.LIGHT_YELLOW)
		stock_label.add_theme_color_override("font_outline_color", Color.DARK_BLUE)
		stock_label.add_theme_constant_override("outline_size", 4)
		stock_label.add_theme_font_size_override("font_size", 14)
		
	_update_display()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_in_range = false
		_close_stock_menu()

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_E or event.keycode == KEY_F:
			if is_instance_valid(stock_panel_instance):
				_close_stock_menu()
			else:
				_open_stock_menu()

# Pop-up Panel displaying current stocked product icon, count, and restock options
func _open_stock_menu() -> void:
	if is_instance_valid(stock_panel_instance):
		return
		
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "StockMenuLayer"
	
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 320)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color("#2d1b0e") # Rustic wood theme
	panel_style.border_color = Color("#8b5a2b")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", panel_style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	
	# Header
	var title = Label.new()
	title.text = "📦 MARKET STALL MANAGEMENT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#fef08a"))
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	# Current Stock Display Box (Picture + Text)
	var current_stock_panel = PanelContainer.new()
	var curr_style = StyleBoxFlat.new()
	curr_style.bg_color = Color("#1e120a")
	curr_style.set_corner_radius_all(6)
	curr_style.set_content_margin_all(10)
	current_stock_panel.add_theme_stylebox_override("panel", curr_style)
	
	var curr_hbox = HBoxContainer.new()
	curr_hbox.add_theme_constant_override("separation", 12)
	
	# Product Image Texture
	var item_icon = TextureRect.new()
	item_icon.custom_minimum_size = Vector2(48, 48)
	item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	if displayed_item != "":
		# Attempt loading product texture from your project folder
		var tex_path = "res://assets/items/" + displayed_item.to_lower().replace(" ", "_") + ".png"
		if ResourceLoader.exists(tex_path):
			item_icon.texture = load(tex_path)
	curr_hbox.add_child(item_icon)
	
	# Currently Stocked Details Label
	var curr_info = Label.new()
	if displayed_item != "" and stock_count > 0:
		curr_info.text = "Currently Stocked:\n" + displayed_item + " (x" + str(stock_count) + ")"
		curr_info.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	else:
		curr_info.text = "Currently Stocked:\nNone (Stall Empty)"
		curr_info.add_theme_color_override("font_color", Color.GRAY)
	curr_hbox.add_child(curr_info)
	
	current_stock_panel.add_child(curr_hbox)
	vbox.add_child(current_stock_panel)
	
	# Factory Items Selection Dropdown & Quantity Control
	var factory_items = [
		"Bread", "Cheese", "Flour", "Jam", "Yarn", 
		"French Fries", "Tomato Ketchup", "Popcorn", 
		"Banana Smoothie", "Polished Rice Box", "Carrot Juice"
	]
	
	var available_items: Array = []
	for item_name in factory_items:
		if GameData.crop_inventory.get(item_name, 0) > 0:
			available_items.append(item_name)
			
	if available_items.size() == 0:
		var empty_lbl = Label.new()
		empty_lbl.text = "No goods in inventory to stock!"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_color_override("font_color", Color("#d1d5db"))
		vbox.add_child(empty_lbl)
	else:
		var item_select = OptionButton.new()
		item_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for item in available_items:
			var inv_count = GameData.crop_inventory.get(item, 0)
			item_select.add_item(item + " (In Inventory: " + str(inv_count) + ")")
		vbox.add_child(item_select)
		
		# Quantity adjustment box
		var qty_wrapper = HBoxContainer.new()
		qty_wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
		qty_wrapper.add_theme_constant_override("separation", 10)
		
		var qty_title = Label.new()
		qty_title.text = "Add Stock:"
		qty_title.add_theme_color_override("font_color", Color.WHITE)
		qty_wrapper.add_child(qty_title)
		
		var qty_spinbox = SpinBox.new()
		qty_spinbox.min_value = 1
		qty_spinbox.step = 1
		qty_spinbox.value = 1
		qty_spinbox.custom_minimum_size = Vector2(90, 32)
		
		var _update_max_qty = func():
			var selected_index = item_select.selected
			if selected_index >= 0 and selected_index < available_items.size():
				var sel_item = available_items[selected_index]
				var max_inv = GameData.crop_inventory.get(sel_item, 1)
				qty_spinbox.max_value = max_inv
				if qty_spinbox.value > max_inv:
					qty_spinbox.value = max_inv
		
		_update_max_qty.call()
		item_select.item_selected.connect(func(_idx): _update_max_qty.call())
		
		var btn_down = Button.new()
		btn_down.text = " - "
		btn_down.custom_minimum_size = Vector2(36, 32)
		btn_down.pressed.connect(func(): qty_spinbox.value = max(qty_spinbox.min_value, qty_spinbox.value - 1))
		
		var btn_up = Button.new()
		btn_up.text = " + "
		btn_up.custom_minimum_size = Vector2(36, 32)
		btn_up.pressed.connect(func(): qty_spinbox.value = min(qty_spinbox.max_value, qty_spinbox.value + 1))
		
		qty_wrapper.add_child(btn_down)
		qty_wrapper.add_child(qty_spinbox)
		qty_wrapper.add_child(btn_up)
		vbox.add_child(qty_wrapper)
		
		# Confirm Stock Button
		var stock_btn = Button.new()
		stock_btn.text = "Add Goods To Stall"
		stock_btn.custom_minimum_size = Vector2(0, 38)
		stock_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color("#d97706")
		btn_style.set_corner_radius_all(6)
		stock_btn.add_theme_stylebox_override("normal", btn_style)
		stock_btn.add_theme_color_override("font_color", Color.WHITE)
		
		stock_btn.pressed.connect(func():
			var selected_idx = item_select.selected
			if selected_idx >= 0 and selected_idx < available_items.size():
				var sel_item = available_items[selected_idx]
				var amount = int(qty_spinbox.value)
				_stock_selected_item(sel_item, amount)
				_close_stock_menu()
		)
		vbox.add_child(stock_btn)
	
	# Close Button
	var close_btn = Button.new()
	close_btn.text = "Close [E]"
	close_btn.custom_minimum_size = Vector2(0, 34)
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color("#4b5563")
	close_style.set_corner_radius_all(6)
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	
	close_btn.pressed.connect(_close_stock_menu)
	vbox.add_child(close_btn)
	
	panel.add_child(vbox)
	center_container.add_child(panel)
	canvas_layer.add_child(center_container)
	get_tree().root.add_child(canvas_layer)
	
	stock_panel_instance = canvas_layer

func _close_stock_menu() -> void:
	if is_instance_valid(stock_panel_instance):
		stock_panel_instance.queue_free()
		stock_panel_instance = null

func _stock_selected_item(item_name: String, amount: int) -> void:
	stock_item(item_name, amount)

func register_customer(customer: Node2D) -> Vector2:
	if not customer in customer_queue:
		customer_queue.append(customer)
	return get_queue_position(customer)

func unregister_customer(customer: Node2D) -> void:
	if customer in customer_queue:
		customer_queue.erase(customer)
		_update_queue_positions()

func get_queue_position(customer: Node2D) -> Vector2:
	var index = customer_queue.find(customer)
	if index == -1:
		return global_position
	return global_position + Vector2(0, (index + 1) * line_spacing)

func is_first_in_line(customer: Node2D) -> bool:
	return customer_queue.size() > 0 and customer_queue[0] == customer

func get_customer_count() -> int:
	return customer_queue.size()

func _update_queue_positions() -> void:
	for i in range(customer_queue.size()):
		var customer = customer_queue[i]
		if is_instance_valid(customer) and customer.has_method("update_target_position"):
			customer.update_target_position(global_position + Vector2(0, (i + 1) * line_spacing))

func stock_item(item_name: String, amount: int = 1) -> bool:
	if GameData.has_item(item_name, amount):
		GameData.remove_item(item_name, amount)
		if displayed_item == item_name:
			stock_count += amount
		else:
			displayed_item = item_name
			stock_count = amount
		
		stock_changed.emit(displayed_item, stock_count)
		_update_display()
		return true
	return false

func get_item_price() -> int:
	var price = 50 
	if GameData.SEED_DATA.has(displayed_item):
		price = GameData.SEED_DATA[displayed_item].get("sell", 50)
	return price

func buy_item() -> bool:
	if stock_count > 0:
		stock_count -= 1
		var item_sold = displayed_item
		var price = get_item_price()
			
		GameData.add_money(price)
		_spawn_stall_sold_text("Sold " + item_sold + " (+₱" + str(price) + ")")
		
		stock_changed.emit(displayed_item, stock_count)
		if stock_count <= 0:
			displayed_item = ""
			
		_update_display()
		return true
	return false

func _spawn_stall_sold_text(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.modulate = Color.GOLD
	label.global_position = global_position + Vector2(-30, -35)
	label.z_index = 10
	get_parent().add_child(label)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 20.0, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.chain().tween_callback(label.queue_free)

func _update_display() -> void:
	if not stock_label:
		return
		
	# World space label clean hint
	stock_label.text = "[E] Market Stall"
	stock_label.show()
