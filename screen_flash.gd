# screen_flash.gd - faster version
extends CanvasLayer

var flash_color: Color = Color.WHITE
var flash_duration: float = 0.5
var layer_priority: int = 10  # Higher = on top

func _ready():
	# Set the layer number so it renders on top
	layer = layer_priority
	
	# Create a ColorRect that covers the entire screen
	var rect = ColorRect.new()
	rect.color = flash_color
	rect.modulate.a = 0  # Start transparent
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't catch mouse events
	add_child(rect)
	
	# Faster flash animation - quick in, quick out
	var tween = create_tween()
	tween.tween_property(rect, "modulate:a", flash_color.a, flash_duration * 0.15)  # Very quick fade in
	tween.tween_property(rect, "modulate:a", 0, flash_duration * 0.25)  # Quicker fade out
	
	# Remove self when done
	await tween.finished
	queue_free()

# Static method to create a flash
static func flash(parent_node = null, color = Color.WHITE, duration = 0.5, priority = 10):
	var flash_node = CanvasLayer.new()
	flash_node.set_script(load("res://screen_flash.gd"))
	
	# Make sure we're assigning a Color object
	if color is Color:
		flash_node.flash_color = color
	else:
		# If somehow a non-Color was passed, default to white
		flash_node.flash_color = Color.WHITE
		
	flash_node.flash_duration = duration
	flash_node.layer_priority = priority
	
	# If parent node provided, add it there, otherwise add to current scene
	if parent_node:
		parent_node.add_child(flash_node)
	else:
		var current_scene = Engine.get_main_loop().get_current_scene()
		current_scene.add_child(flash_node)
	
	return flash_node
