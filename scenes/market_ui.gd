extends Control

@onready var money_label: Label = $Panel/MoneyLabel
@onready var buy_seeds_button: Button = $Panel/VBoxContainer/BuySeedsButton
@onready var sell_wheat_button: Button = $Panel/VBoxContainer/SellWheatButton
@onready var close_button: Button = $Panel/CloseButton

func _ready() -> void:
	hide() # Hidden by default
	
	if buy_seeds_button:
		buy_seeds_button.pressed.connect(_on_buy_seeds_pressed)
	if sell_wheat_button:
		sell_wheat_button.pressed.connect(_on_sell_wheat_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	if GameData.has_signal("data_changed"):
		GameData.data_changed.connect(update_ui)

func update_ui() -> void:
	if money_label and "money" in GameData:
		money_label.text = "Money: ₱" + str(GameData.money) + " | Seeds: " + str(GameData.seeds) + " | Wheat: " + str(GameData.wheat)

func open_market() -> void:
	update_ui()
	show()

func _on_buy_seeds_pressed() -> void:
	if GameData.remove_money(10):
		GameData.add_seeds(1)
		update_ui()

func _on_sell_wheat_pressed() -> void:
	if GameData.remove_wheat(1):
		GameData.add_money(20)
		update_ui()

func _on_close_pressed() -> void:
	hide()
