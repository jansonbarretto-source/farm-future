extends Node

signal data_changed

var days_progress: int = 1
var coins: int = 500

var unlocked_slots: int = 6
# Start empty locally. The dashboard supplies starter Wheat only for accounts
# that have never saved inventory before.
var crop_inventory: Dictionary = {}
var animal_inventory: Dictionary = {}
var seed_inventory: Dictionary = {}


func _ready() -> void:
	if OS.has_feature("web"):
		var url_days = JavaScriptBridge.eval(
            "new URLSearchParams(window.location.search).get('days');"
		)
		var url_coins = JavaScriptBridge.eval(
            "new URLSearchParams(window.location.search).get('coins');"
		)
		var url_inventory = JavaScriptBridge.eval(
            "new URLSearchParams(window.location.search).get('inventory');"
		)

		if url_days != null and url_days != "":
			days_progress = int(url_days)

		if url_coins != null and url_coins != "":
			coins = int(url_coins)

		# Load inventory passed by dashboard.php.
		if url_inventory != null and url_inventory != "":
			var saved_inventory = JSON.parse_string(str(url_inventory))

			if saved_inventory is Dictionary:
				var saved_crops = saved_inventory.get("crop_inventory", {})
				var saved_animals = saved_inventory.get("animal_inventory", {})
				var saved_seeds = saved_inventory.get("seed_inventory", {})

				if saved_crops is Dictionary:
					crop_inventory = saved_crops
				if saved_animals is Dictionary:
					animal_inventory = saved_animals
				if saved_seeds is Dictionary:
					seed_inventory = saved_seeds

				unlocked_slots = int(saved_inventory.get("unlocked_slots", 6))

		print("[LOAD] Days: ", days_progress)
		print("[LOAD] Coins: ", coins)
		print("[LOAD] Crops: ", crop_inventory)
		print("[LOAD] Animals: ", animal_inventory)
		print("[LOAD] Seeds: ", seed_inventory)
		print("[LOAD] Unlocked Slots: ", unlocked_slots)

	data_changed.emit()


func update_progress_and_sync(new_days: int, new_coins: int) -> void:
	days_progress = new_days
	coins = new_coins
	data_changed.emit()


func add_coins(amount: int) -> void:
	coins += amount
	update_progress_and_sync(days_progress, coins)


func remove_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		update_progress_and_sync(days_progress, coins)
		return true

	return false


func exit_to_dashboard() -> void:
	if OS.has_feature("web"):
		# Save the complete current state for the logged-in player.
		var payload = {
			"days_progress": days_progress,
			"coins": coins,
			"crop_inventory": crop_inventory,
			"animal_inventory": animal_inventory,
			"seed_inventory": seed_inventory,
			"unlocked_slots": unlocked_slots
		}

		var payload_json = JSON.stringify(payload)
		# Encode the JSON payload as a safe JavaScript string literal.
		var body_string = JSON.stringify(payload_json)

		var save_script = """
        fetch('/GameLauncher/update_progress.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            credentials: 'same-origin',
            body: %s
        })
        .then(function(response) {
            return response.json().then(function(data) {
                if (!response.ok) {
                    throw new Error(data.message || 'Save request failed');
                }
                return data;
            });
        })
        .then(function(data) {
            console.log('[SAVE RESPONSE]', data);
            if (data.status === 'success') {
                window.location.href = '/GameLauncher/dashboard.php';
            } else {
                alert('Save failed: ' + JSON.stringify(data));
            }
        })
        .catch(function(error) {
            console.error('[SAVE ERROR]', error);
            alert('Unable to save progress: ' + error.message);
        });
		""" % [body_string]

		JavaScriptBridge.eval(save_script)
	else:
		get_tree().quit()
