extends Node

# Seed at Market Prices (Data Reference)
# Sa GameData.gd:

# Sa GameData.gd:

var SEED_DATA = {
	"Wheat": {"buy": 10, "sell": 20, "growth_time": 3.0, "scale": Vector2(0.5, 0.5), "icon": "res://images/assets/seeds/wheat seed pack.jpeg"},
	"Carrot": {"buy": 10, "sell": 25, "growth_time": 5.0, "scale": Vector2(0.5, 0.5), "icon": "res://images/assets/seeds/carrot seed pack.jpeg"},
	"Potato": {"buy": 12, "sell": 30, "growth_time": 8.0, "scale": Vector2(0.5, 0.5), "icon": "res://images/assets/seeds/potato seed pack.jpeg"},
	"Tomato": {"buy": 15, "sell": 35, "growth_time": 10.0, "scale": Vector2(0.6, 0.6), "icon": "res://images/assets/seeds/tomato seed pack.jpeg"},
	"Rice": {"buy": 18, "sell": 50, "growth_time": 12.0, "scale": Vector2(0.5, 0.5), "icon": "res://images/assets/seeds/rice seed pack.jpeg"},
	"Corn": {"buy": 20, "sell": 45, "growth_time": 15.0, "scale": Vector2(0.6, 0.6), "icon": "res://images/assets/seeds/corn seed pack.jpeg"},
	"Strawberry": {"buy": 20, "sell": 40, "growth_time": 18.0, "scale": Vector2(0.5, 0.5), "icon": "res://images/assets/seeds/strawberrt seed pack.jpeg"},
	"Banana": {"buy": 40, "sell": 80, "growth_time": 25.0, "scale": Vector2(0.7, 0.7), "icon": "res://images/assets/seeds/banana seed pack.jpeg"},
	"Apple": {"buy": 50, "sell": 100, "growth_time": 30.0, "scale": Vector2(0.7, 0.7), "icon": "res://images/assets/seeds/apple seed pack.jpeg"},
	"Mango": {"buy": 60, "sell": 120, "growth_time": 40.0, "scale": Vector2(0.8, 0.8), "icon": "res://images/assets/seeds/mango seed pack.jpeg"}
}

# Player Currencies & Resources
var money: int = 500

# Dynamic Inventories (Name: Quantity)
var seed_inventory: Dictionary = {
	"Wheat": 10,
	"Carrot": 0,
	"Potato": 0,
	"Tomato": 0,
	"Rice": 0,
	"Corn": 0,
	"Strawberry": 0,
	"Banana": 0,
	"Apple": 0,
	"Mango": 0
}

var crop_inventory: Dictionary = {
	"Carrot": 0,
	"Potato": 0,
	"Tomato": 0,
	"Rice": 0,
	"Corn": 0,
	"Strawberry": 0,
	"Banana": 0,
	"Apple": 0,
	"Mango": 0,
	"Wheat": 0 # Para sa lumang wheat system mo
}

# Hotbar Item Selection
enum ActiveItem { HOE, WATERING_CAN, SEED }
var selected_item: ActiveItem = ActiveItem.HOE
var selected_seed_type: String = "Carrot" # Default na nakapiling seed

# Signal to notify UI when data changes
signal data_changed

# --- MONEY FUNCTIONS ---
func add_money(amount: int) -> void:
	money += amount
	data_changed.emit()

func remove_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		data_changed.emit()
		return true
	return false

# --- SEED INVENTORY FUNCTIONS ---
func add_seeds(seed_name: String, amount: int) -> void:
	if seed_inventory.has(seed_name):
		seed_inventory[seed_name] += amount
	else:
		seed_inventory[seed_name] = amount
	data_changed.emit()

func remove_seeds(seed_name: String, amount: int) -> bool:
	if seed_inventory.get(seed_name, 0) >= amount:
		seed_inventory[seed_name] -= amount
		data_changed.emit()
		return true
	return false

func get_total_seeds() -> int:
	var total: int = 0
	for count in seed_inventory.values():
		total += count
	return total

# --- CROP INVENTORY FUNCTIONS ---
func add_crop(crop_name: String, amount: int) -> void:
	if crop_inventory.has(crop_name):
		crop_inventory[crop_name] += amount
	else:
		crop_inventory[crop_name] = amount
	data_changed.emit()

func remove_crop(crop_name: String, amount: int) -> bool:
	if crop_inventory.get(crop_name, 0) >= amount:
		crop_inventory[crop_name] -= amount
		data_changed.emit()
		return true
	return false

# --- ITEM SELECTION FUNCTIONS ---
func select_item(item: ActiveItem) -> void:
	selected_item = item
	data_changed.emit()

func select_seed_type(seed_name: String) -> void:
	if SEED_DATA.has(seed_name):
		selected_seed_type = seed_name
		data_changed.emit()
