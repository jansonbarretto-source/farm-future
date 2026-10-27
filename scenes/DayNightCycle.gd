extends CanvasModulate

# Color gradients for different times of day (RGB)
const MORNING_COLOR = Color(1.0, 0.95, 0.85, 1.0)  # Soft warm morning light
const DAY_COLOR = Color(1.0, 1.0, 1.0, 1.0)       # Bright daylight
const SUNSET_COLOR = Color(0.9, 0.6, 0.4, 1.0)    # Orange/Pink sunset
const NIGHT_COLOR = Color(0.15, 0.2, 0.35, 1.0)   # Deep dark blue night

func _process(_delta: float) -> void:
	if not GameData:
		return
		
	# Calculate total time in minutes passed today (0 to 1440 minutes)
	var total_minutes: float = (GameData.current_hour * 60.0) + GameData.time_minutes
	
	# Convert into a normalized 0.0 to 1.0 progression fraction
	var time_fraction: float = total_minutes / 1440.0
	
	# Update CanvasModulate tint
	color = _get_time_color(time_fraction)

func _get_time_color(t: float) -> Color:
	# 0.0 to 0.25 = Morning (Sunrise to Day)
	# 0.25 to 0.65 = Day
	# 0.65 to 0.75 = Evening (Sunset)
	# 0.75 to 1.0  = Night back to Sunrise
	
	if t < 0.25:
		# Sunrise transition (Morning -> Day)
		var progress = t / 0.25
		return MORNING_COLOR.lerp(DAY_COLOR, progress)
	elif t < 0.65:
		# Midday
		return DAY_COLOR
	elif t < 0.75:
		# Sunset transition (Day -> Sunset)
		var progress = (t - 0.65) / 0.1
		return DAY_COLOR.lerp(SUNSET_COLOR, progress)
	elif t < 0.85:
		# Dusk transition (Sunset -> Night)
		var progress = (t - 0.75) / 0.1
		return SUNSET_COLOR.lerp(NIGHT_COLOR, progress)
	else:
		# Night transition (Night -> Morning sunrise)
		var progress = (t - 0.85) / 0.15
		return NIGHT_COLOR.lerp(MORNING_COLOR, progress)
