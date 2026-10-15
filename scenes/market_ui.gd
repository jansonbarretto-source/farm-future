extends Control

@onready var money_label: Label = $Panel/MoneyLabel
@onready var buy_container: VBoxContainer = $Panel/MarketTabs/Buy/BuyListContainer
@onready var sell_container: VBoxContainer = $Panel/MarketTabs/Sell/SellListContainer
@onready var close_button: Button = $Panel/CloseButton

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
		GameData.data_changed.connect(update_ui)
		
	_adjust_container_sizes()
	_populate_market_tabs()

# Forces the scrollable area and containers to expand cleanly inside the market window
func _adjust_container_sizes() -> void:
	var tabs = $Panel/MarketTabs
	if tabs:
		tabs.custom_minimum_size = Vector2(280, 200) # Expands tab view area
		tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if buy_container:
		buy_container.custom_minimum_size = Vector2(260, 0)
		buy_container.add_theme_constant_override("separation", 8)
		
	if sell_container:
		sell_container.custom_minimum_size = Vector2(260, 0)
		sell_container.add_theme_constant_override("separation", 8)

func _populate_market_tabs() -> void:
	for child in buy_container.get_children():
		child.queue_free()
	for child in sell_container.get_children():
		child.queue_free()

	for item_name in GameData.SEED_DATA.keys():
		var data = GameData.SEED_DATA[item_name]
		var seed_icon: Texture2D = seed_textures.get(item_name)
		
		# --- 1. BUY TAB ITEM CARD ---
		var buy_card = _create_market_card(
			item_name + " Seed",
			data["buy"],
			"Buy",
			Color(0.18, 0.42, 0.22, 1.0), # Green button
			func(): _on_buy_seed(item_name, data["buy"]),
			seed_icon
		)
		buy_container.add_child(buy_card)
		
		# --- 2. SELL TAB ITEM CARD ---
		var sell_card = _create_market_card(
			item_name,
			data["sell"],
			"Sell",
			Color(0.55, 0.22, 0.18, 1.0), # Red/Brown button
			func(): _on_sell_crop(item_name, data["sell"]),
			seed_icon
		)
		sell_container.add_child(sell_card)

# Helper function to generate visual market cards
func _create_market_card(item_title: String, price: int, action_text: String, btn_color: Color, on_click_callable: Callable, texture: Texture2D = null) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 54) # Height for clear visibility
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Dark wooden card frame
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
	
	# Item Image Icon (Enlarged for clear visual recognition)
	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(40, 40)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	if texture:
		icon_rect.texture = texture
		
	hbox.add_child(icon_rect)
	
	# Text Info
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
	
	# Buy / Sell Button
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
	update_ui()
	show()

func _on_buy_seed(seed_name: String, price: int) -> void:
	if GameData.remove_money(price):
		GameData.add_seeds(seed_name, 1)

func _on_sell_crop(crop_name: String, price: int) -> void:
	if GameData.remove_crop(crop_name, 1):
		GameData.add_money(price)

func _on_close_pressed() -> void:
	hide()
