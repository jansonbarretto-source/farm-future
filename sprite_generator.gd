@tool
extends EditorScript

func _run() -> void:
	var frame_width = 32
	var frame_height = 32
	var total_frames = 8
	
	# Create empty 8-frame strip image (256x32)
	var sheet = Image.create(frame_width * total_frames, frame_height, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0)) # Transparent background
	
	# Color Palette
	var c_metal = Color("4a525d")
	var c_metal_dark = Color("2d3238")
	var c_metal_light = Color("788391")
	var c_oil = Color("e5a93b")
	var c_oil_bubble = Color("ffeb85")
	var c_gear = Color("8c97a5")
	var c_smoke = Color(0.9, 0.9, 0.95, 0.7)
	
	for f in range(total_frames):
		var offset_x = f * frame_width
		
		# 1. Base Machine Body (Metallic Fryer Box)
		for x in range(6, 26):
			for y in range(12, 28):
				var col = c_metal
				if x == 6 or y == 12: col = c_metal_light
				elif x == 25 or y == 27: col = c_metal_dark
				sheet.set_pixel(offset_x + x, y, col)
				
		# 2. Front Control Dial / Gear (Rotates across 8 frames)
		var center_x = 11
		var center_y = 22
		var angle = (float(f) / 8.0) * TAU
		var gear_x = center_x + int(round(cos(angle) * 2.0))
		var gear_y = center_y + int(round(sin(angle) * 2.0))
		sheet.set_pixel(offset_x + center_x, center_y, c_metal_dark)
		sheet.set_pixel(offset_x + gear_x, gear_y, c_gear)
		
		# 3. Oil Basin & Bubbling Animation
		for x in range(9, 23):
			for y in range(14, 18):
				sheet.set_pixel(offset_x + x, y, c_oil)
				
		# Animating Oil Bubbles
		var b1_x = 10 + ((f * 2) % 12)
		var b1_y = 16 - ((f) % 3)
		var b2_x = 21 - ((f * 3) % 11)
		var b2_y = 16 - ((f + 1) % 3)
		sheet.set_pixel(offset_x + b1_x, b1_y, c_oil_bubble)
		sheet.set_pixel(offset_x + b2_x, b2_y, c_oil_bubble)
		
		# 4. Chimney & Smoke
		for x in range(20, 24):
			for y in range(6, 12):
				sheet.set_pixel(offset_x + x, y, c_metal_dark)
				
		var smoke_y = 5 - (f % 6)
		var smoke_x = 22 + (f / 2)
		if smoke_y >= 0:
			sheet.set_pixel(offset_x + smoke_x, smoke_y, c_smoke)
			sheet.set_pixel(offset_x + smoke_x + 1, smoke_y, c_smoke)

	# Save PNG image to factory assets folder
	var save_path = "res://images/assets/for factory/deep_fryer_animated.png"
	sheet.save_png(save_path)
	print("[ASSET GENERATOR] Successfully created 8-frame sprite sheet at: ", save_path)
