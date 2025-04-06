# Modified collectible effects that integrate with your player system

extends Area2D
class_name Collectable

signal collected(points)

@export var points: int = 10
var collected_flag = false

func _ready():
	# Set up collision detection
	body_entered.connect(_on_body_entered)
	# Add to collectables group
	add_to_group("collectables")

func _on_body_entered(body):
	if body is CharacterBody2D and body.name == "Player" and not collected_flag:
		collected_flag = true
		
		# Play collection effect before disappearing
		play_collection_effect(body)
		
		# Show score popup
		var popup_script = load("res://score_popup.gd")
		if popup_script:
			popup_script.show_popup(get_parent(), global_position, points)
		
		# Emit collected signal
		collected.emit(points)
		
		# Make the sprite bounce up and fade out
		var sprite = get_node("Sprite2D") if has_node("Sprite2D") else null
		if sprite:
			var tween = create_tween().set_parallel(true)
			tween.tween_property(sprite, "position:y", sprite.position.y - 20, 0.3).set_ease(Tween.EASE_OUT)
			tween.tween_property(sprite, "modulate:a", 0, 0.3)
			await tween.finished
		
		# Remove from scene
		queue_free()

func play_collection_effect(player_body):
	# Create particles effect
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 20  # Significantly more particles
	particles.lifetime = 0.9  # Longer lifetime to travel farther
	
	# Check player direction to bias particles correctly
	var direction_bias = Vector2(2, -0.3)  # Stronger bias to right (2x horizontal component)
	
	# If player is moving left, reverse the bias
	if player_body and player_body.has_node("Sprite2D"):
		var sprite = player_body.get_node("Sprite2D")
		if sprite.flip_h:  # If sprite is flipped, player is facing left
			direction_bias.x = -2  # Bias particles to the left
	
	# Set directional parameters
	particles.direction = direction_bias.normalized()
	particles.spread = 50  # Even narrower spread for more focused direction
	particles.initial_velocity_min = 100  # Much faster particles
	particles.initial_velocity_max = 160  # Higher max velocity for greater distance
	
	# Add some gravity to pull particles down after initial burst
	particles.gravity = Vector2(0, 150)
	
	# Make particles a bit larger
	particles.scale_amount_min = 3.5
	particles.scale_amount_max = 5.5  # Varying sizes for visual interest
	
	# Set particle color based on collectible type
	var particle_color
	if points == 10:  # Teal
		particle_color = Color(0, 0.8, 0.8)
	elif points == 20:  # Pink
		particle_color = Color(1, 0.4, 0.7)
	elif points == 30:  # Purple
		particle_color = Color(0.6, 0.3, 0.9)
	else:
		particle_color = Color(1, 1, 1)
	
	particles.color = particle_color
	
	# Add trail effect by creating a second particle system with different parameters
	var trail_particles = CPUParticles2D.new()
	trail_particles.emitting = true
	trail_particles.one_shot = true
	trail_particles.explosiveness = 0.6
	trail_particles.amount = 8
	trail_particles.lifetime = 1.1
	trail_particles.direction = direction_bias.normalized()
	trail_particles.spread = 30
	trail_particles.initial_velocity_min = 70
	trail_particles.initial_velocity_max = 90
	trail_particles.scale_amount_min = 2.5
	trail_particles.scale_amount_max = 3.5
	trail_particles.color = particle_color
	trail_particles.gravity = Vector2(0, 100)
	
	# Add both particle systems to the scene
	get_parent().add_child(particles)
	get_parent().add_child(trail_particles)
	particles.global_position = global_position
	trail_particles.global_position = global_position
	
	# Remove particles after they finish
	await get_tree().create_timer(particles.lifetime * 1.5).timeout
	particles.queue_free()
	trail_particles.queue_free()
	
	# Rest of the function remains the same...
	# Add player feedback effects
	if player_body:
		# 1. Check if player has a sprite to animate
		var player_sprite = player_body.get_node("Sprite2D") if player_body.has_node("Sprite2D") else null
		if player_sprite:
			# Create a quick squash and stretch animation
			var squash_tween = create_tween()
			squash_tween.tween_property(player_sprite, "scale", Vector2(1.2, 0.8), 0.1)
			squash_tween.tween_property(player_sprite, "scale", Vector2(0.9, 1.1), 0.1)
			squash_tween.tween_property(player_sprite, "scale", Vector2(1.0, 1.0), 0.1)
		
		# 2. For higher value collectibles, add a small jump boost
		if points >= 20:
			if points == 30:  # Purple - highest value
				player_body.velocity.y = player_body.jump_speed * 0.4  # 40% of a normal jump
			else:  # Pink
				player_body.velocity.y = player_body.jump_speed * 0.3  # 30% of a normal jump
		
		# 3. Small camera shake for special collectibles
		if player_body.has_node("Camera2D") and points >= 20:
			var camera = player_body.get_node("Camera2D")
			var original_offset = camera.offset
			var shake_intensity = points / 10.0  # Scale with point value
			var shake_duration = 0.2
			
			# Create a timer for the shake effect
			var timer = Timer.new()
			player_body.add_child(timer)
			timer.wait_time = 0.02  # Shake frequency
			timer.autostart = true
			
			var shake_timer = 0.0
			timer.timeout.connect(func():
				shake_timer += timer.wait_time
				
				if shake_timer < shake_duration:
					# Apply random offset based on intensity
					var offset = Vector2(
						randf_range(-shake_intensity, shake_intensity),
						randf_range(-shake_intensity, shake_intensity)
					)
					camera.offset = original_offset + offset
				else:
					# Reset camera position and stop the timer
					camera.offset = original_offset
					timer.queue_free()
			)
	
	# Also add a small "pop" animation at the position with directional bias
	var pop = Node2D.new()
	var pop_sprite = Sprite2D.new()
	
	# You could replace this with an actual sprite if you have one
	# For now, we'll create a circle that expands and fades
	pop_sprite.scale = Vector2(0.1, 0.1)
	
	pop.add_child(pop_sprite)
	get_parent().add_child(pop)
	
	# Position the pop farther ahead in the movement direction
	pop.global_position = global_position + (direction_bias * 20)
	
	# Animation
	var tween = create_tween().set_parallel(true)
	tween.tween_property(pop_sprite, "scale", Vector2(1, 1), 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(pop_sprite, "modulate:a", 0, 0.3)
	
	await tween.finished
	pop.queue_free()
