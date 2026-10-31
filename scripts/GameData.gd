extends Node

# Item & Crop Data Reference Dictionary (Prices, Growth, and Asset Paths)
var SEED_DATA = {
	"Wheat": {
		"buy": 10,
		"sell": 20,
		"growth_time": 3.0,
		"scale": Vector2(0.2, 0.2),
		"icon": "res://images/assets/seeds/wheat seed pack.png",
		"crop_icon": "res://images/assets/for main (crops)/Wheat.png",
		"harvest_yield": 1
	},
	"Carrot": {
		"buy": 10,
		"sell": 25,
		"growth_time": 5.0,
		"scale": Vector2(0.5, 0.5),
		"icon": "res://images/assets/seeds/carrot seed pack.png",
		"crop_icon": "res://images/assets/for main (crops)/carrot/carrot.png",
		"harvest_yield": 1
	},
	"Potato": {
		"buy": 12,
		"sell": 30,
		"growth_time": 8.0,
		"scale": Vector2(0.5, 0.5),
		"icon": "res://images/assets/seeds/potato seed pack.png",
		"crop_icon": "res://images/assets/for main (crops)/potato/potato.png",
		"harvest_yield": 3
	},
	"Tomato": {
		"buy": 15,
		"sell": 35,
		"growth_time": 10.0,
		"scale": Vector2(0.6, 0.6),
		"icon": "res://images/assets/seeds/tomato seed pack.png",
		"crop_icon": "res://images/assets/for main (crops)/tomato/tomato.png",
		"harvest_yield": 5
	},
	"Rice": {
		"buy": 18,
		"sell": 50,
		"growth_time": 12.0,
		"scale": Vector2(0.5, 0.5),
		"icon": "res://images/assets/seeds/rice seed pack.png",
		"crop_icon": "res://images/assets/for main (crops)/rice/rice.png",
		"harvest_yield": 1
	},
	"Corn": {
		"buy": 20,
		"sell": 45,
		"growth_time": 15.0,
		"scale": Vector2(0.8, 0.8),
		"offset": Vector2(0, -8),
		"icon": "res://images/assets/seeds/corn seed pack.png",
		"crop_icon": "res://images/assets/for main (crops)/corn/corn.png",
		"harvest_yield": 1
	},
	"Strawberry": {
		"buy": 20,
		"sell": 40,
		"growth_time": 18.0,
		"scale": Vector2(0.5, 0.5),
		"icon": "res://images/assets/seeds/strawberry seed pack.png",
		"crop_icon": "res://images/assets/for main (crops)/strawberry/strawberry.png",
		"harvest_yield": 5
	},
	"Banana": {
		"buy": 40,
		"sell": 80,
		"growth_time": 25.0,
		"stage_scales": [Vector2(0.5, 0.5), Vector2(1.0, 1.0), Vector2(1.4, 1.4)],
		"stage_offsets": [Vector2(0, 0), Vector2(0, -50), Vector2(0, -130)],
		"icon": "res://images/assets/seeds/banana seed pack.png",
		"crop_icon": "res://images/assets/for main (crops)/banana/banana.png",
		"harvest_yield": 1
	},
	"Apple": {
		"buy": 50,
		"sell": 100,
		"growth_time": 30.0,
		"stage_scales": [Vector2(0.5, 0.5), Vector2(1.0, 1.0), Vector2(1.6, 1.6)],
		"stage_offsets": [Vector2(0, 0), Vector2(0, -50), Vector2(0, -140)],
		"icon": "res://images/assets/seeds/apple seed pack.png",
		"crop_icon": "res://images/assets/for main (crops)/apple/apple.png",
		"harvest_yield": 5
	},
	"Mango": {
		"buy": 60,
		"sell": 120,
		"growth_time": 40.0,
		"stage_scales": [Vector2(0.5, 0.5), Vector2(1.1, 1.1), Vector2(1.6, 1.6)],
		"stage_offsets": [Vector2(0, 0), Vector2(0, -50), Vector2(0, -140)],
		"icon": "res://images/assets/seeds/mango seed pack.png",
		"crop_icon": "res://images/assets/for main (crops)/mango/mango.png",
		"harvest_yield": 5
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
	"Pesticide": {
		"buy": 0,
		"sell": 60,
		"growth_time": 0.0,
		"crop_icon": "res://images/assets/for main (crops)/pest control station/pesticides.png"
	},
	"Wool": {
		"buy": 0,
		"sell": 40,
		"growth_time": 0.0,
		"crop_icon": "res://images/assets/for main (crops)/wool/wool.png"
	},

	# --- PROCESSED FACTORY GOODS ---
	"Flour": {
		"buy": 0,
		"sell": 40,
		"growth_time": 0.0,
		"crop_icon": "res://images/assets/for factory/flour.png"
	},
	"Cheese": {
		"buy": 0,
		"sell": 75,
		"growth_time": 0.0,
		"crop_icon": "res://images/assets/for factory/cheese.png"
	},
	"Bread": {
		"buy": 0,
		"sell": 120,
		"growth_time": 0.0,
		"crop_icon": "res://images/assets/for factory/bread.png"
	},
	"Yarn": {
		"buy": 0,
		"sell": 100,
		"growth_time": 0.0,
		"crop_icon": "res://images/assets/for factory/yarn.png"
	},
	"Jam": {
		"buy": 0,
		"sell": 90,
		"growth_time": 0.0,
		"crop_icon": "res://images/assets/for factory/jam.png"
	},
	"French Fries": {
		"buy": 0,
		"sell": 85,
		"growth_time": 0.0,
		"crop_icon": "res://images/assets/for factory/french_fries.png"
	},
	"Tomato Ketchup": {
		"buy": 0,
		"sell": 70,
		"growth_time": 0.0,
		"crop_icon": "res://images/assets/for factory/ketchup.png"
	},
	"Popcorn": {
		"buy": 0,
		"sell": 65,
		"growth_time": 0.0,
		"crop_icon": "res://images/assets/for factory/popcorn.png"
	},
	"Banana Smoothie": {
		"buy": 0,
		"sell": 110,
		"growth_time": 0.0,
		"crop_icon": "res://images/assets/for factory/banana_smoothie.png"
	},
	"Polished Rice Box": {
		"buy": 0,
		"sell": 60,
		"growth_time": 0.0,
		"crop_icon": "res://images/assets/for factory/polished_rice.png"
	},
	"Carrot Juice": {
		"buy": 0,
		"sell": 55,
		"growth_time": 0.0,
		"crop_icon": "res://images/assets/for factory/carrot_juice.png"
	}
}

# --- PEST CONTROL RECIPE DEFINITION ---
var PESTICIDE_RECIPE = {
	"Tomato": 2,
	"Potato": 1
}

# Player Currencies & Resources
var money: int = 500

# Getter/Alias para maging compatible ang 'player_money' sa mga bagong scripts gaya ng locked gates
var player_money: int:
	get:
		return money
	set(value):
		money = value

# --- UNLOCKED AREAS & PROGRESSION SYSTEM ---
var unlocked_areas: Dictionary = {
	"Farm": true,          # Day 1: Bukas na agad
	"Market": true,        # Day 1: Bukas na agad
	"Factory": false,      # Day 5 i-aunlock (May bayad na 3,000)
	"Livestock": false     # Day 10 i-aunlock (May bayad na 3,000)
}

# --- INVENTORY SLOT CONFIGURATION ---
var unlocked_slots: int = 6
var max_slots: int = 12

# --- WATER MANAGEMENT SYSTEM VARIABLES ---
var water_tank_level: float = 0.0
var max_water_capacity: float = 100.0
var watering_can_water: float = 0.0
var max_watering_can_cap: float = 25.0
var water_source_is_tank: bool = false

# --- WEATHER SYSTEM VARIABLES ---
var current_weather: String = "Raining" # Pwedeng "Dry" o "Rainy"

func roll_daily_weather() -> void:
	var roll = randf()
	if roll <= 0.30:
		current_weather = "Rainy"
		print("[WEATHER] Today's weather is Rainy 🌧️! Crops will be automatically watered.")
	else:
		current_weather = "Dry"
		print("[WEATHER] Today's weather is Dry ☀️.")
	
	data_changed.emit()

# --- DAY & NIGHT CYCLE TIME TRACKING ---
var current_day: int = 1
var current_hour: int = 6 
var time_minutes: float = 0.0

@export var minutes_per_second: float = 4.0 

signal time_changed(hour: int, day: int)
signal data_changed

func _ready() -> void:
	select_seed_type("Wheat")
	select_item(ActiveItem.SEED)
	current_weather = "Rainy"

func update_game_time(delta: float) -> void:
	var prev_minute = int(time_minutes)
	time_minutes += delta * minutes_per_second
	
	if time_minutes >= 60.0:
		time_minutes -= 60.0
		current_hour += 1
		if current_hour >= 24:
			current_hour = 0
			current_day += 1

	if int(time_minutes) != prev_minute:
		time_changed.emit(current_hour, current_day)
		data_changed.emit()

func can_sleep() -> bool:
	return current_hour >= 20 or current_hour < 6

func sleep_to_next_day() -> void:
	current_day += 1
	current_hour = 6
	time_minutes = 0.0
	
	roll_daily_weather()
	
	time_changed.emit(current_hour, current_day)
	data_changed.emit()
	print("[SLEEP] Woke up on Day ", current_day, " at 06:00. Weather is now: ", current_weather)

# --- WATER MANAGEMENT FUNCTIONS ---
func use_water_for_irrigation(amount: float = 8.34) -> bool:
	if watering_can_water > 0 and water_source_is_tank:
		watering_can_water = max(0.0, watering_can_water - amount)
		if watering_can_water <= 0.0:
			water_source_is_tank = false
		data_changed.emit()
		return true
	return false

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
	"Pesticide": 0,
	"Wool": 0,
	"Flour": 0,
	"Cheese": 0,
	"Bread": 0,
	"Yarn": 0,
	"Jam": 0,
	"French Fries": 0,
	"Tomato Ketchup": 0,
	"Popcorn": 0,
	"Banana Smoothie": 0,
	"Polished Rice Box": 0,
	"Carrot Juice": 0
}

var inventory: Dictionary:
	get:
		return crop_inventory

enum ActiveItem { HOE, WATERING_CAN, SEED }
var selected_item: ActiveItem = ActiveItem.SEED
var selected_seed_type: String = "Wheat"
var selected_inventory_item: String = ""

func add_money(amount: int) -> void:
	money += amount
	data_changed.emit()

func remove_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		data_changed.emit()
		return true
	return false

func has_item(item_name: String, amount: int = 1) -> bool:
	if crop_inventory.get(item_name, 0) >= amount:
		return true
	if seed_inventory.get(item_name, 0) >= amount:
		return true
	if animal_inventory.get(item_name, 0) >= amount:
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
	if animal_inventory.get(item_name, 0) >= amount:
		animal_inventory[item_name] -= amount
		data_changed.emit()
		return true
	return false

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

func get_unique_item_count() -> int:
	var unique_items = []
	for k in crop_inventory.keys():
		if crop_inventory[k] > 0 and not unique_items.has(k):
			unique_items.append(k)
	for k in animal_inventory.keys():
		if animal_inventory[k] > 0 and not unique_items.has(k):
			unique_items.append(k)
	for k in seed_inventory.keys():
		if seed_inventory[k] > 0 and not unique_items.has(k):
			unique_items.append(k)
	return unique_items.size()

func add_crop(crop_name: String, amount: int = 1) -> void:
	var already_owned: bool = (crop_inventory.get(crop_name, 0) > 0) or (animal_inventory.get(crop_name, 0) > 0) or (seed_inventory.get(crop_name, 0) > 0)
	
	if not already_owned and get_unique_item_count() >= unlocked_slots:
		print("[INVENTORY] Inventory Full!")
		return
		
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

func select_item(item: ActiveItem) -> void:
	selected_item = item
	data_changed.emit()

func select_seed_type(seed_name: String) -> void:
	selected_seed_type = seed_name
	selected_inventory_item = ""
	selected_item = ActiveItem.SEED
	data_changed.emit()

func select_inventory_item(item_name: String) -> void:
	selected_inventory_item = item_name
	selected_seed_type = ""
	data_changed.emit()

func deselect_current_item() -> void:
	selected_seed_type = ""
	selected_inventory_item = ""
	data_changed.emit()

var ANIMAL_DATA = {
	"Chicken": {
		"buy": 150,
		"icon": "res://images/assets/for livestock/chicken/chicken.png",
		"description": "Produces Eggs when fed Wheat."
	},
	"Cow": {
		"buy": 400,
		"icon": "res://images/assets/for livestock/cow/cow.png",
		"description": "Produces Milk when fed Wheat."
	},
	"Pig": {
		"buy": 300,
		"icon": "res://images/assets/for livestock/pig/pig.png",
		"description": "Produces Manure when fed Carrot."
	},
	"Sheep": {
		"buy": 350,
		"icon": "res://images/assets/for livestock/sheep/with wool/sheep.png",
		"description": "Produces Wool when fed Wheat."
	}
}

var animal_inventory: Dictionary = {
	"Chicken": 0,
	"Cow": 0,
	"Pig": 0,
	"Sheep": 0
}

func add_animal_to_inventory(animal_name: String, amount: int = 1) -> void:
	var already_owned: bool = (crop_inventory.get(animal_name, 0) > 0) or (animal_inventory.get(animal_name, 0) > 0) or (seed_inventory.get(animal_name, 0) > 0)
	
	if not already_owned and get_unique_item_count() >= unlocked_slots:
		print("[INVENTORY] Puno na ang imbentaryo para sa hayop: ", animal_name)
		return
		
	if animal_inventory.has(animal_name):
		animal_inventory[animal_name] += amount
	else:
		animal_inventory[animal_name] = amount
	data_changed.emit()

func remove_animal_from_inventory(animal_name: String, amount: int = 1) -> bool:
	if animal_inventory.get(animal_name, 0) >= amount:
		animal_inventory[animal_name] -= amount
		data_changed.emit()
		return true
	return false
