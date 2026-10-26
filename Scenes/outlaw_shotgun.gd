extends CharacterBody2D

@export var speed: float = 25.0
@export var follow_distance: float = 250.0
@export var retreat_distance: float = 150.0
@export var strafe_speed: float = 15.0
@export var strafe_change_time: float = 2.0

@export var health: int = 5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var pivot_point: Node2D = $PivotPoint
@onready var revolver: Sprite2D = $PivotPoint/Shotgun
@onready var fire_point: Node2D = $PivotPoint/Shotgun/FirePoint
@onready var shoot_timer: Timer = $ShootTimer
@onready var dust: AnimatedSprite2D = $Dust


@onready var main = get_tree().current_scene

var player: Node2D
var fire_point_start: Vector2

var strafe_direction: float = 1.0
var strafe_timer: float = 0.0


func _ready() -> void:
	strafe_change_time = randf_range(1.0, 5.0)
	shoot_timer.wait_time = randf_range(3, 6)

	player = get_tree().get_first_node_in_group("Player")
	fire_point_start = fire_point.position

	if player == null:
		push_error("No player found in the Player group!")


func _physics_process(delta: float) -> void:
	if player == null:
		return
	if health <= 0:
		return

	var distance = global_position.distance_to(player.global_position)
	var to_player = (player.global_position - global_position).normalized()
	var direction = Vector2.ZERO

	if distance < retreat_distance:
		# Move backwards away from the player
		direction = -to_player
		velocity = direction * speed

	elif distance > follow_distance:
		# Chase the player
		direction = to_player
		velocity = direction * speed

	else:
		# Randomly strafe left and right near the player
		strafe_timer -= delta

		if strafe_timer <= 0.0:
			strafe_direction = [-1.0, 1.0].pick_random()
			strafe_timer = randf_range(1.0, 5.0)

		direction = to_player.orthogonal() * strafe_direction
		velocity = direction * strafe_speed

	move_and_slide()

	# Aim at the player
	pivot_point.look_at(player.global_position)

	# Flip revolver and character when player is to the left
	var flipped = player.global_position.x < global_position.x
	revolver.flip_v = flipped
	animated_sprite.flip_h = flipped

	# Keep fire point aligned with the barrel
	fire_point.position = Vector2(
		fire_point_start.x,
		-fire_point_start.y if flipped else fire_point_start.y
	)

	# Handle movement animations
	if velocity.length() > 0.0:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")
		
func hit(damage):
	if health >= 0:
		health -= damage
	if health <= 0:
		death()
		
func death():
	player.give_money(5)
	shoot_timer.stop()
	$Sounds/Death.play()
	collision_layer = 0
	collision_mask = 0
	animated_sprite.play("death")
	revolver.visible = false
	if animated_sprite.flip_h:
		global_position.x -= 18
	else: 
		global_position.x += 18


func _on_timer_timeout() -> void:
	shoot_timer.wait_time = randf_range(3, 6)
	$Sounds/Shoot.play()
	shoot_triple(2, 2, Color(0.651, 0.145, 0.0, 1.0), 250, 1)

func shoot_triple(mask: int, layer: int, bullet_color: Color, bullet_speed: int, damage: int) -> void:
	var spread = deg_to_rad(10.0)

	for angle in [-spread, 0.0, spread]:
		main.shoot(
			fire_point.global_position,
			pivot_point.global_rotation + angle,
			mask,
			layer,
			bullet_color,
			bullet_speed,
			damage
		)

func _on_animated_sprite_2d_animation_finished() -> void:
	if health <= 0:
		main.spawn_ghost(global_position)
		dust.visible = true
		dust.play("kickup")
		await get_tree().create_timer(5).timeout
		var tween = create_tween()
		tween.tween_property($AnimatedSprite2D, "modulate", Color(0.0, 0.0, 0.0, 0.0), 1)
		await tween.finished
		queue_free()
