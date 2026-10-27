extends Control

var color_rect: ColorRect
var summary_panel: PanelContainer
var day_title_label: Label
var big_day_label: Label
var continue_btn: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 100 # Ensure it renders above everything in the world
	
	_build_ui_elements()
	_run_sleep_sequence()

func _build_ui_elements() -> void:
	# 1. Cinematic Night Fade Overlay
	color_rect = ColorRect.new()
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.color = Color(0.02, 0.02, 0.06, 0.0)
	add_child(color_rect)
	
	# 2. Center Container for Summary Report Box
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	# 3. Summary Panel Box (Stardew-inspired wooden RPG aesthetic)
	summary_panel = PanelContainer.new()
	summary_panel.custom_minimum_size = Vector2(380, 240)
	summary_panel.modulate.a = 0.0 # Hidden initially for fade-in animation
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.05, 0.96) # Deep warm wood brown
	style.border_color = Color(0.85, 0.65, 0.4, 1.0) # Golden-wood accent border
	style.set_border_width_all(3)
	style.border_width_top = 10 # Thick decorative top banner border
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0, 0, 0, 0.75)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0, 6)
	summary_panel.add_theme_stylebox_override("panel", style)
	center.add_child(summary_panel)
	
	# 4. Margins & Content Layout
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	summary_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	
	# Header Title
	day_title_label = Label.new()
	day_title_label.text = "🌙 RESTING..."
	day_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_title_label.add_theme_font_size_override("font_size", 14)
	day_title_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7))
	day_title_label.add_theme_constant_override("outline_size", 4)
	vbox.add_child(day_title_label)
	
	# Elegant Divider line
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color(0.85, 0.65, 0.4, 0.6)
	vbox.add_child(divider)
	
	# Prominent Big Day Display Label (DAY 2, DAY 3, etc.)
	big_day_label = Label.new()
	big_day_label.text = "DAY 2"
	big_day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big_day_label.add_theme_font_size_override("font_size", 28)
	big_day_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	big_day_label.add_theme_constant_override("outline_size", 6)
	vbox.add_child(big_day_label)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer)
	
	# Continue / Start Day Button
	continue_btn = Button.new()
	continue_btn.text = "Start Day 2"
	continue_btn.custom_minimum_size = Vector2(0, 40)
	continue_btn.add_theme_font_size_override("font_size", 13)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.45, 0.25, 1.0) # Forest green
	btn_style.border_color = Color(0.4, 0.7, 0.4, 1.0)
	btn_style.set_border_width_all(2)
	btn_style.set_corner_radius_all(8)
	continue_btn.add_theme_stylebox_override("normal", btn_style)
	
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(0.26, 0.56, 0.32, 1.0)
	continue_btn.add_theme_stylebox_override("hover", btn_hover)
	
	continue_btn.pressed.connect(_on_continue_pressed)
	vbox.add_child(continue_btn)

func _run_sleep_sequence() -> void:
	# Cinematic Fade to Black
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.85, 0.7).set_trans(Tween.TRANS_SINE)
	await tween.finished
	
	# Advance Game Time & Day via GameData
	if GameData:
		GameData.sleep_to_next_day()
		day_title_label.text = "☀️ AWAKENING"
		big_day_label.text = "DAY " + str(GameData.current_day)
		continue_btn.text = "Start Day " + str(GameData.current_day)
	
	# Smooth Fade-in of the Summary Box & Morning Light
	var panel_tween = create_tween().set_parallel(true)
	panel_tween.tween_property(summary_panel, "modulate:a", 1.0, 0.4)
	panel_tween.tween_property(color_rect, "color:a", 0.4, 0.4)

func _on_continue_pressed() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(summary_panel, "modulate:a", 0.0, 0.3)
	tween.tween_property(color_rect, "color:a", 0.0, 0.3)
	
	await tween.finished
	queue_free()
