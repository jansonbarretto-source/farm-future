extends Node

# Item & Crop Data Reference Dictionary (Prices, Growth, and Asset Paths)
var SEED_DATA = {
	"Wheat": {
		"buy": 10, 
		"sell": 20, 
		"growth_time": 3.0, 
		"scale": Vector2(0.2, 0.2), 
		"icon": "res://images/assets/seeds/wheat seed pack.png", 
		"crop_icon": "res://images/assets/for main (crops)/Wheat.png"
	},
	"Carrot": {
		"buy": 10, 
		"sell": 25, 
		"growth_time": 5.0, 
		"scale": Vector2(0.5, 0.5), 
		"icon": "res://images/assets/seeds/carrot seed pack.png", 
		"crop_icon": "res://images/assets/for main (crops)/carrot/carrot.png"
	},
	"Potato": {
		"buy": 12, 
		"sell": 30, 
		"growth_time": 8.0, 
		"scale": Vector2(0.5, 0.5), 
		"icon": "res://images/assets/seeds/potato seed pack.png", 
		"crop_icon": "res://images/assets/for main (crops)/potato/potato.png"
	},
	"Tomato": {
		"buy": 15, 
		"sell": 35, 
		"growth_time": 10.0, 
		"scale": Vector2(0.6, 0.6), 
		"icon": "res://images/assets/seeds/tomato seed pack.png", 
		"crop_icon": "res://images/assets/for main (crops)/tomato/tomato.png"
	},
	"Rice": {
		"buy": 18, 
		"sell": 50, 
		"growth_time": 12.0, 
		"scale": Vector2(0.5, 0.5), 
		"icon": "res://images/assets/seeds/rice seed pack.png", 
		"crop_icon": "res://images/assets/for main (crops)/rice/rice.png"
	},
	"Corn": {
		"buy": 20, 
		"sell": 45, 
		"growth_time": 15.0, 
		"scale": Vector2(0.8, 0.8), 
		"offset": Vector2(0, -8), 
		"icon": "res://images/assets/seeds/corn seed pack.png", 
		"crop_icon": "res://images/assets/for main (crops)/corn/corn.png"
	},
	"Strawberry": {
		"buy": 20, 
		"sell": 40, 
		"growth_time": 18.0, 
		"scale": Vector2(0.5, 0.5), 
		"icon": "res://images/assets/seeds/strawberry seed pack.png", 
		"crop_icon": "res://images/assets/for main (crops)/strawberry/strawberry.png"
	},
	"Banana": {
		"buy": 40, 
		"sell": 80, 
		"growth_time": 25.0, 
		"stage_scales": [Vector2(0.5, 0.5), Vector2(1.0, 1.0), Vector2(1.4, 1.4)], 
		"stage_offsets": [Vector2(0, 0), Vector2(0, -50), Vector2(0, -130)],
		"icon": "res://images/assets/seeds/banana seed pack.png",
		"crop_icon": "res://images/assets/for main (crops)/banana/banana.png"
	},
	"Apple": {
		"buy": 50, 
		"sell": 100, 
		"growth_time": 30.0, 
		"stage_scales": [Vector2(0.5, 0.5), Vector2(1.0, 1.0), Vector2(1.6, 1.6)], 
		"stage_offsets": [Vector2(0, 0), Vector2(0, -50), Vector2(0, -140)],
		"icon": "res://images/assets/seeds/apple seed pack.png",
		"crop_icon": "res://images/assets/for main (crops)/apple/apple.png"
	},
	"Mango": {
		"buy": 60, 
		"sell": 120, 
		"growth_time": 40.0, 
		"stage_scales": [Vector2(0.5, 0.5), Vector2(1.1, 1.1), Vector2(1.6, 1.6)], 
		"stage_offsets": [Vector2(0, 0), Vector2(0, -50), Vector2(0, -140)],
		"icon": "res://images/assets/seeds/mango seed pack.png",
		"crop_icon": "res://images/assets/for main (crops)/mango/mango.png"
	},
	
	# --- LIVESTOCK PRODUCE & FERTILIZER DEFINITIONS ---
	"Egg": {
		"buy": 0, 
		"sell": 15, 
		"growth_time": 0.0,
		"crop_icon": "res://images/assets/for main (crops)/egg/egg.png"
	},
	"Milk": {
		"buy": 0, 
		"sell": 30, 
		"growth_time": 0.0,
		"crop_icon": "res://images/assets/for main (crops)/milk/milk.png"
	},
	"Manure": {
		"buy": 0, 
		"sell": 5, 
		"growth_time": 0.0,
		"crop_icon": "res://images/assets/for main (crops)/manure/manure.png"
	},
	"Organic Fertilizer": {
		"buy": 0, 
		"sell": 50, 
		"growth_time": 0.0,
		"crop_icon": "res://images/assets/for main (crops)/fertilizer/fertilizer.png"
	},
	"Wool": {
		"buy": 0, 
		"sell": 40, 
		"growth_time": 0.0,
		"crop_icon": "res://images/assets/for main (crops)/wool/wool.png" # Siguraduhing tugma sa totoong PNG path mo
	}
}

# Player Currencies & Resources
var money: int = 500

# Dynamic Inventories (Item Name: Quantity)
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
	"Wheat": 0,
	"Carrot": 0,
	"Potato": 0,
	"Tomato": 0,
	"Rice": 0,
	"Corn": 0,
	"Strawberry": 0,
	"Banana": 0,
	"Apple": 0,
	"Mango": 0,
	"Egg": 0,
	"Milk": 0,
	"Manure": 0,
	"Organic Fertilizer": 0,
	"Wool": 0
}

# Getter for Inventory UI Compatibility
var inventory: Dictionary:
	get:
		return crop_inventory

# Hotbar Item Selection
enum ActiveItem { HOE, WATERING_CAN, SEED }
var selected_item: ActiveItem = ActiveItem.HOE
var selected_seed_type: String = "Carrot"

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

# --- GENERAL ITEM CHECKING & REMOVAL ---
func has_item(item_name: String, amount: int = 1) -> bool:
	if crop_inventory.get(item_name, 0) >= amount:
		return true
	if seed_inventory.get(item_name, 0) >= amount:
		return true
	return false

func remove_item(item_name: String, amount: int = 1) -> bool:
	if crop_inventory.get(item_name, 0) >= amount:
		crop_inventory[item_name] -= amount
		data_changed.emit()
		return true
	if seed_inventory.get(item_name, 0) >= amount:
		seed_inventory[item_name] -= amount
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

func remove_seeds(seed_name: String, amount: int = 1) -> bool:
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

# --- CROP & PRODUCE INVENTORY FUNCTIONS ---
func add_crop(crop_name: String, amount: int = 1) -> void:
	if crop_inventory.has(crop_name):
		crop_inventory[crop_name] += amount
	else:
		crop_inventory[crop_name] = amount
	data_changed.emit()

func remove_crop(crop_name: String, amount: int = 1) -> bool:
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
	selected_seed_type = seed_name
	data_changed.emit()
