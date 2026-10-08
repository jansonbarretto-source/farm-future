extends Control

@onready var money_label: Label = $Panel/MoneyLabel
@onready var buy_seeds_button: Button = $Panel/VBoxContainer/BuySeedsButton
@onready var sell_wheat_button: Button = $Panel/VBoxContainer/SellWheatButton
@onready var close_button: Button = $Panel/CloseButton

func _ready() -> void:
	hide() # Naka-hide sa simula
	update_ui()
	
	# Connect button signals
	buy_seeds_button.pressed.connect(_on_buy_seeds_pressed)
	sell_wheat_button.pressed.connect(_on_sell_wheat_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Listen sa pagbabago ng data
	GameData.data_changed.connect(update_ui)

func update_ui() -> void:
	money_label.text = "Money: ₱" + str(GameData.money) + " | Seeds: " + str(GameData.seeds) + " | Wheat: " + str(GameData.wheat)

func open_market() -> void:
	update_ui()
	show()

func _on_buy_seeds_pressed() -> void:
	if GameData.remove_money(10):
		GameData.seeds += 1
		GameData.data_changed.emit()

func _on_sell_wheat_pressed() -> void:
	if GameData.wheat > 0:
		GameData.wheat -= 1
		GameData.add_money(20)

func _on_close_pressed() -> void:
	hide()
