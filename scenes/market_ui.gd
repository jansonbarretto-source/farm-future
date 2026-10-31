extends Control

@onready var money_label: Label = $Panel/MoneyLabel
@onready var buy_container: VBoxContainer = $Panel/MarketTabs/Buy/BuyListContainer
@onready var sell_container: VBoxContainer = $Panel/MarketTabs/Sell/SellListContainer
@onready var animal_container: VBoxContainer = $Panel/MarketTabs/Animals/AnimalListContainer if $Panel/MarketTabs.has_node("Animals/AnimalListContainer") else null
@onready var close_button: Button = $Panel/CloseButton

# Store Operating Hours (6:00 AM to 8:00 PM / 20:00)
const OPEN_HOUR: int = 6
const CLOSE_HOUR: int = 20

# Seed Pack Image Textures (located inside res://images/assets/seeds/)
@export var seed_textures: Dictionary = {
	"Wheat": preload("res://images/assets/seeds/wheat seed pack.png"),
	"Carrot": preload("res://images/assets/seeds/carrot seed pack.png"),
	"Potato": preload("res://images/assets/seeds/potato seed pack.png"),
	"Tomato": preload("res://images/assets/seeds/tomato seed pack.png"),
	"Apple": preload("res://images/assets/seeds/apple seed pack.png"),
	"Banana": preload("res://images/assets/seeds/banana seed pack.png"),
	"Corn": preload("res://images/assets/seeds/corn seed pack.png"),
	"Mango": preload("res://images/assets/seeds/mango seed pack.png"),
	"Rice": preload("res://images/assets/seeds/rice seed pack.png"),
	"Strawberry": preload("res://images/assets/seeds/strawberry seed pack.png")
}

func _ready() -> void:
	hide()
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	if GameData.has_signal("data_changed"):
		GameData.data_changed.connect(_on_game_data_changed)
		
	_adjust_container_sizes()
	_populate_market_tabs()

func is_store_open() -> bool:
	if GameData and "current_hour" in GameData:
		var hour = GameData.current_hour
		return hour >= OPEN_HOUR and hour < CLOSE_HOUR
	return true

func _on_game_data_changed() -> void:
	update_ui()
	if visible and not is_store_open():
		hide()
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("error")
		_spawn_market_notification("❌ Store is now Closed! (Opens at 6:00 AM)")

func _adjust_container_sizes() -> void:
	var tabs = $Panel/MarketTabs
	if tabs:
		tabs.custom_minimum_size = Vector2(280, 200)
		tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if buy_container:
		buy_container.custom_minimum_size = Vector2(260, 0)
		buy_container.add_theme_constant_override("separation", 8)
		
	if sell_container:
		sell_container.custom_minimum_size = Vector2(260, 0)
		sell_container.add_theme_constant_override("separation", 8)

	if animal_container:
		animal_container.custom_minimum_size = Vector2(260, 0)
		animal_container.add_theme_constant_override("separation", 8)

func _populate_market_tabs() -> void:
	for child in buy_container.get_children():
		child.queue_free()
	for child in sell_container.get_children():
		child.queue_free()
	if animal_container:
		for child in animal_container.get_children():
			child.queue_free()

	if not GameData or not "SEED_DATA" in GameData:
		return

	for item_name in GameData.SEED_DATA.keys():
		var data = GameData.SEED_DATA[item_name]
		var buy_price = data.get("buy", 0)
		var sell_price = data.get("sell", 0)
		
		var seed_icon: Texture2D = seed_textures.get(item_name)
		var crop_icon_texture: Texture2D = seed_icon
		
		if not crop_icon_texture and data.has("crop_icon") and ResourceLoader.exists(data["crop_icon"]):
			crop_icon_texture = load(data["crop_icon"])

		if buy_price > 0 and seed_textures.has(item_name):
			var buy_card = _create_market_card(
				item_name + " Seed",
				buy_price,
				"Buy",
				Color(0.18, 0.42, 0.22, 1.0),
				func(): _on_buy_seed(item_name, buy_price),
				seed_icon
			)
			buy_container.add_child(buy_card)
		
		if sell_price > 0:
			var sell_card = _create_market_card(
				item_name,
				sell_price,
				"Sell",
				Color(0.55, 0.22, 0.18, 1.0),
				func(): _on_sell_crop(item_name, sell_price),
				crop_icon_texture
			)
			sell_container.add_child(sell_card)

	if animal_container and "ANIMAL_DATA" in GameData:
		for animal_name in GameData.ANIMAL_DATA.keys():
			var a_data = GameData.ANIMAL_DATA[animal_name]
			var animal_price = a_data.get("buy", 150)
			var animal_icon: Texture2D = null
			
			if a_data.has("icon") and ResourceLoader.exists(a_data["icon"]):
				animal_icon = load(a_data["icon"])

			var animal_card = _create_market_card(
				animal_name,
				animal_price,
				"Buy",
				Color(0.18, 0.35, 0.58, 1.0),
				func(): _on_buy_animal(animal_name, animal_price),
				animal_icon
			)
			animal_container.add_child(animal_card)

func _create_market_card(item_title: String, price: int, action_text: String, btn_color: Color, on_click_callable: Callable, texture: Texture2D = null) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 54)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.1, 0.07, 0.04, 0.9)
	card_style.border_color = Color(0.38, 0.25, 0.15, 1.0)
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(6)
	card.add_theme_stylebox_override("panel", card_style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 8
	hbox.offset_right = -8
	hbox.offset_top = 4
	hbox.offset_bottom = -4
	card.add_child(hbox)
	
	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(40, 40)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	if texture:
		icon_rect.texture = texture
		
	hbox.add_child(icon_rect)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var title_lbl = Label.new()
	title_lbl.text = item_title
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.75))
	title_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	title_lbl.add_theme_constant_override("outline_size", 3)
	vbox.add_child(title_lbl)
	
	var price_lbl = Label.new()
	price_lbl.text = "₱" + str(price)
	price_lbl.add_theme_font_size_override("font_size", 11)
	price_lbl.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	price_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	price_lbl.add_theme_constant_override("outline_size", 3)
	vbox.add_child(price_lbl)
	
	hbox.add_child(vbox)
	
	var action_btn = Button.new()
	action_btn.text = action_text
	action_btn.custom_minimum_size = Vector2(64, 34)
	action_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = btn_color
	btn_normal.border_color = btn_color.darkened(0.3)
	btn_normal.set_border_width_all(2)
	btn_normal.set_corner_radius_all(4)
	
	var btn_hover = btn_normal.duplicate()
	btn_hover.bg_color = btn_color.lightened(0.15)
	
	action_btn.add_theme_stylebox_override("normal", btn_normal)
	action_btn.add_theme_stylebox_override("hover", btn_hover)
	action_btn.add_theme_stylebox_override("pressed", btn_normal)
	action_btn.add_theme_color_override("font_color", Color.WHITE)
	action_btn.add_theme_color_override("font_outline_color", Color.BLACK)
	action_btn.add_theme_constant_override("outline_size", 3)
	
	action_btn.pressed.connect(on_click_callable)
	hbox.add_child(action_btn)
	
	return card

func update_ui() -> void:
	if money_label:
		money_label.text = "Money: ₱" + str(GameData.money) + " | Total Seeds: " + str(GameData.get_total_seeds())

func open_market() -> void:
	if not is_store_open():
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("error")
		_spawn_market_notification("❌ Store is Closed! Opens at 6:00 AM")
		return
		
	update_ui()
	_populate_market_tabs()
	show()

func _spawn_market_notification(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color("#ef4444"))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_font_size_override("font_size", 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var canvas = CanvasLayer.new()
	canvas.layer = 150
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.add_child(label)
	canvas.add_child(center)
	get_tree().root.add_child(canvas)
	
	var tween = create_tween()
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.0)
	# --- NAINDAHAN NA: I-fade ang label sa halip na canvas para mawala ang error ---
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(canvas.queue_free)

func _on_buy_seed(seed_name: String, price: int) -> void:
	if not is_store_open():
		return
	if GameData.remove_money(price):
		GameData.add_seeds(seed_name, 1)
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("buy")
	else:
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("error")
		_spawn_market_notification("⚠️ Not enough money!")

func _on_buy_animal(animal_name: String, price: int) -> void:
	if not is_store_open():
		return
	if GameData.remove_money(price):
		if GameData.has_method("add_animal_to_inventory"):
			GameData.add_animal_to_inventory(animal_name, 1)
		elif "animal_inventory" in GameData:
			GameData.animal_inventory[animal_name] = GameData.animal_inventory.get(animal_name, 0) + 1
			
		if "crop_inventory" in GameData:
			GameData.crop_inventory[animal_name] = GameData.crop_inventory.get(animal_name, 0) + 1
		elif "inventory" in GameData:
			GameData.inventory[animal_name] = GameData.inventory.get(animal_name, 0) + 1
			
		if GameData.has_signal("data_changed"):
			GameData.data_changed.emit()
			
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("buy")
	else:
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("error")
		_spawn_market_notification("⚠️ Not enough money!")

func _on_sell_crop(crop_name: String, price: int) -> void:
	if not is_store_open():
		return
	if GameData.remove_crop(crop_name, 1):
		GameData.add_money(price)
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("coin")
	else:
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("error")
		_spawn_market_notification("⚠️ No item to sell!")

func _on_close_pressed() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("click") # Pinalitan ng click sound para sa close button
	hide()
