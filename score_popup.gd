# score_popup.gd
extends Node2D

func _ready():
	# Start the animation immediately
	play_animation()

func play_animation():
	# Float upward and fade out
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 30, 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0, 0.5).set_delay(0.3)
	
	# Remove when animation is done
	await tween.finished
	queue_free()

# Function to create and show a score popup
static func show_popup(parent_node, position, points):
	# Create the node
	var popup = Node2D.new()
	popup.set_script(load("res://score_popup.gd"))
	popup.position = position
	
	# Create the label
	var label = Label.new()
	label.text = "+" + str(points)
	
	# Style the label
	var font = load("res://assets/fonts/Baumans-Regular.ttf")  # Adjust path as needed
	if font:
		var font_variation = FontVariation.new()
		font_variation.base_font = font
		label.add_theme_font_override("font", font_variation)
		label.add_theme_font_size_override("font_size", 16)
	
	# Set color based on points
	if points == 10:  # Teal
		label.add_theme_color_override("font_color", Color(0, 0.8, 0.8))
	elif points == 20:  # Pink
		label.add_theme_color_override("font_color", Color(1, 0.4, 0.7))
	elif points == 30:  # Purple
		label.add_theme_color_override("font_color", Color(0.6, 0.3, 0.9))
	
	# Add shadow for better visibility
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	
	popup.add_child(label)
	parent_node.add_child(popup)
	
	return popup
