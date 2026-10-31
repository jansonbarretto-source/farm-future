extends StaticBody2D

@export_enum("Factory", "Livestock") var target_area: String = "Factory"
@export var unlock_day: int = 5
@export var unlock_fee: int = 500

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual_node: Node2D = $Sprite2D # O ColorRect kung yun ang ginamit mo
@onready var info_label: Label = $Label # Opsyonal para sa status text

var is_unlocked: bool = false

func _ready() -> void:
	input_pickable = true # Para ma-click ng player ang gate/harang
	_check_status()
	
	if GameData and GameData.has_signal("data_changed"):
		GameData.data_changed.connect(_check_status)

func _check_status() -> void:
	if not GameData:
		return
		
	if "unlocked_areas" in GameData and GameData.unlocked_areas.get(target_area, false):
		is_unlocked = true
		_open_gate()

func _open_gate() -> void:
	if collision_shape:
		collision_shape.disabled = true
	if visual_node:
		visual_node.visible = false
	if info_label:
		info_label.visible = false
		
	print(target_area, " Gate is now OPEN!")

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if is_unlocked:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_gate_click()

func _handle_gate_click() -> void:
	if not GameData:
		return
		
	var current_day = GameData.current_day if "current_day" in GameData else 1
	
	# 1. Kung hindi pa abot ang tamang araw
	if current_day < unlock_day:
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("error")
		_show_feedback_message("🔒  LOCKED AREA  🔒\n\nThis area unlocks on\nDay " + str(unlock_day) + ".", Color(1.0, 0.45, 0.45))
		return
		
	# 2. Kung abot na ang araw, ipakita ang "Buy this Area" Prompt na may Yes/Cancel buttons
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("click")
	_show_buy_prompt()

# --- MAGANDANG UI POPUP NA MAY YES AT CANCEL BUTTONS ---
func _show_buy_prompt() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 150
	
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.modulate.a = 0.0 # Dito inilagay sa panel sa halip na canvas
	
	# Modern at Eleganteng UI Styling
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.07, 0.15, 0.96)
	style.border_color = Color(1.0, 0.82, 0.40, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(24)
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 12
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "🗺️  UNLOCK " + target_area.to_upper() + "  🗺️\n\nBuy this Area for " + str(unlock_fee) + " Coins?"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.08))
	lbl.add_theme_constant_override("outline_size", 4)
	vbox.add_child(lbl)
	
	# Horizontal Container para sa Buttons
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 15)
	vbox.add_child(hbox)
	
	# YES BUTTON
	var btn_yes = Button.new()
	btn_yes.text = "  Yes  "
	btn_yes.custom_minimum_size = Vector2(90, 35)
	_style_button(btn_yes, Color(0.20, 0.65, 0.30), Color(0.25, 0.75, 0.35))
	btn_yes.pressed.connect(func():
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("click")
		_process_purchase(canvas)
	)
	hbox.add_child(btn_yes)
	
	# CANCEL BUTTON
	var btn_cancel = Button.new()
	btn_cancel.text = "  Cancel  "
	btn_cancel.custom_minimum_size = Vector2(90, 35)
	_style_button(btn_cancel, Color(0.65, 0.20, 0.20), Color(0.75, 0.25, 0.25))
	btn_cancel.pressed.connect(func():
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("click")
		_close_popup(canvas)
	)
	hbox.add_child(btn_cancel)
	
	canvas.add_child(panel)
	get_tree().root.add_child(canvas)
	
	panel.scale = Vector2(0.8, 0.8)
	panel.pivot_offset = Vector2(130, 60)
	
	# Smooth Fade-in at Scale-up animation para sa panel
	var tween = create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process_purchase(canvas: CanvasLayer) -> void:
	var player_money = GameData.money if "money" in GameData else 0
	
	if player_money >= unlock_fee:
		GameData.remove_money(unlock_fee)
		GameData.unlocked_areas[target_area] = true
		
		if GameData.has_signal("data_changed"):
			GameData.data_changed.emit()
			
		# --- TUGTUGIN ANG UNLOCK SOUND KAPAG MATAGUMPAY NA NABUKSAN ---
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("unlock")
			
		_open_gate()
		_close_popup(canvas)
		_show_feedback_message("✨ Successfully Unlocked " + target_area + "!", Color(0.3, 1.0, 0.4))
	else:
		# KUNG KULANG ANG PERA
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("error")
		_close_popup(canvas)
		_show_feedback_message("⚠️ NOT ENOUGH MONEY!\nRequired: " + str(unlock_fee) + " Coins", Color(1.0, 0.35, 0.35))

# --- STYLING NG BUTTONS PARA MAGING MODERN ---
func _style_button(btn: Button, bg_col: Color, hover_col: Color) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = bg_col
	style_normal.set_corner_radius_all(6)
	style_normal.set_content_margin_all(6)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = hover_col
	style_hover.set_corner_radius_all(6)
	style_hover.set_content_margin_all(6)
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color.WHITE)

# --- STANDARD FEEDBACK POPUP MESSAGE (PARA SA NOT ENOUGH MONEY O SUCCESS) ---
func _show_feedback_message(msg: String, text_color: Color) -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 160
	
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.modulate.a = 0.0 # Nakalagay na rin sa panel
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.18, 0.96)
	style.border_color = Color(1.0, 0.82, 0.40, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(20)
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 10
	panel.add_theme_stylebox_override("panel", style)
	
	var lbl = Label.new()
	lbl.text = msg
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", text_color)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.08))
	lbl.add_theme_constant_override("outline_size", 4)
	panel.add_child(lbl)
	
	canvas.add_child(panel)
	get_tree().root.add_child(canvas)
	
	panel.scale = Vector2(0.85, 0.85)
	panel.pivot_offset = Vector2(120, 40)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Mawawala pagkalipas ng 2.5 segundo
	var timer = get_tree().create_timer(2.5)
	timer.timeout.connect(func():
		_close_popup(canvas)
	)

func _close_popup(canvas: CanvasLayer) -> void:
	if not canvas or not canvas.is_inside_tree():
		return
	var panel = canvas.get_child(0) if canvas.get_child_count() > 0 else null
	if panel:
		var fade = create_tween()
		fade.tween_property(panel, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fade.chain().tween_callback(canvas.queue_free)
	else:
		canvas.queue_free()
