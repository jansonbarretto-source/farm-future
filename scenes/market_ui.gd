extends Control

@onready var money_label: Label = $Panel/MoneyLabel
@onready var buy_container: VBoxContainer = $Panel/MarketTabs/Buy/BuyListContainer
@onready var sell_container: VBoxContainer = $Panel/MarketTabs/Sell/SellListContainer
@onready var close_button: Button = $Panel/CloseButton

func _ready() -> void:
	hide()
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	if GameData.has_signal("data_changed"):
		GameData.data_changed.connect(update_ui)
		
	_populate_market_tabs()

func _populate_market_tabs() -> void:
	# Linisin ang mga lumang buttons sa parehong container
	for child in buy_container.get_children():
		child.queue_free()
	for child in sell_container.get_children():
		child.queue_free()

	# Normal Green Stylebox
	var green_normal_style = StyleBoxFlat.new()
	green_normal_style.bg_color = Color("2d5e43") # Deep Green
	green_normal_style.border_width_left = 2
	green_normal_style.border_width_top = 2
	green_normal_style.border_width_right = 2
	green_normal_style.border_width_bottom = 2
	green_normal_style.border_color = Color("1e3f2d")
	green_normal_style.set_corner_radius_all(3)

	# Hover Green Stylebox
	var green_hover_style = StyleBoxFlat.new()
	green_hover_style.bg_color = Color("3a7956") # Lighter Green
	green_hover_style.border_width_left = 2
	green_hover_style.border_width_top = 2
	green_hover_style.border_width_right = 2
	green_hover_style.border_width_bottom = 2
	green_hover_style.border_color = Color("1e3f2d")
	green_hover_style.set_corner_radius_all(3)

	for seed_name in GameData.SEED_DATA.keys():
		var data = GameData.SEED_DATA[seed_name]
		
		# --- BUY SEED BUTTON (Pupunta sa Buy Tab) ---
		var buy_btn = Button.new()
		buy_btn.text = "Buy 1 " + seed_name + " Seed (₱" + str(data["buy"]) + ")"
		buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buy_btn.custom_minimum_size = Vector2(0, 32)
		
		_apply_button_style(buy_btn, green_normal_style, green_hover_style)
		buy_btn.pressed.connect(func(): _on_buy_seed(seed_name, data["buy"]))
		buy_container.add_child(buy_btn)
		
		# --- SELL CROP BUTTON (Pupunta sa Sell Tab) ---
		var sell_btn = Button.new()
		sell_btn.text = "Sell 1 " + seed_name + " (₱" + str(data["sell"]) + ")"
		sell_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sell_btn.custom_minimum_size = Vector2(0, 32)
		
		_apply_button_style(sell_btn, green_normal_style, green_hover_style)
		sell_btn.pressed.connect(func(): _on_sell_crop(seed_name, data["sell"]))
		sell_container.add_child(sell_btn)

func _apply_button_style(btn: Button, normal_style: StyleBox, hover_style: StyleBox) -> void:
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", normal_style)
	btn.add_theme_color_override("font_color", Color.WHITE)

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
