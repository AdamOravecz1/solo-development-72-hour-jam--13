extends CharacterBody2D

@export var speed: float = 150.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var pivot_point: Node2D = $PivotPoint
@onready var revolver: Sprite2D = $PivotPoint/Revolver
@onready var fire_point: Node2D = $PivotPoint/Revolver/FirePoint
@onready var cylinder: Sprite2D = $CanvasLayer/Cylinder
@onready var health_bar: TextureProgressBar = $CanvasLayer/HealthBar
@onready var money_label: Label = $CanvasLayer/MoneyLabel
@onready var camera_2d: Camera2D = $Camera2D
@onready var dust: AnimatedSprite2D = $Dust


var bullet_types: Array[String] = ["regular", "regular", "regular", "regular", "regular", "regular"]
var regular_bullet_texture: Texture2D = preload("res://Sprites/RegularBullet.png")
var ghost_bullet_texture: Texture2D = preload("res://Sprites/GhostBullet.png")
var fast_bullet_texture: Texture2D = preload("res://Sprites/FastIcon.png")
var triple_bullet_texture: Texture2D = preload("res://Sprites/TripleIcon.png")
var ghost_fast_bullet_texture: Texture2D = preload("res://Sprites/FastGhostIcon.png")
var ghost_triple_bullet_texture: Texture2D = preload("res://Sprites/TripleGhostIcon.png")
var can_shoot = true
var stopped = false
var reload_needed = false

var chamber_pointer: int = 0

var recoil_offset: float = 0.0
var recoil_tween: Tween

@onready var main = get_tree().current_scene
var fire_point_start: Vector2

@export var dodge_speed: float = 150
var is_dodging: bool = false
var dodge_direction: Vector2 = Vector2.ZERO

var health: int = 10
var money: int = 0

var fast_unlocked: bool = false
var triple_unlocked: bool = false
var ghost_fast_unlocked: bool = false
var ghost_triple_unlocked: bool = false

var single_damage: int = 1
var fast_damage: int = 1
var triple_damage: int = 1
var ghost_damage: int = 1
var ghost_fast_damage: int = 1
var ghost_triple_damage: int = 1

var score: int = 0

func _ready() -> void:
	health_bar.max_value = health
	fire_point_start = fire_point.position

	for i in cylinder.get_children():
		var regular_bullet := Sprite2D.new()
		regular_bullet.texture = regular_bullet_texture
		i.add_child(regular_bullet)


func _process(delta: float) -> void:
	if stopped:
		return
	
	if health <= 0:
		return
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed
	
	if velocity != Vector2.ZERO and not $Control/Walk.playing and not is_dodging:
		print("playing")
		$Control/Walk.pitch_scale = randf_range(0.85, 1.15)
		$Control/Walk.play()
	
	if Input.is_action_just_pressed("dodge") and not is_dodging:
		is_dodging = true
		dodge_direction = Input.get_vector("left", "right", "up", "down")

		if dodge_direction == Vector2.ZERO:
			dodge_direction = Vector2.RIGHT.rotated(animated_sprite.global_rotation)

		$CollisionShape2D.set_deferred("disabled", true)
		animated_sprite.play("dodge")

	if is_dodging:
		velocity = dodge_direction * dodge_speed
		move_and_slide()

		if not animated_sprite.is_playing():
			is_dodging = false
			$CollisionShape2D.set_deferred("disabled", false)

		return
	move_and_slide()

	pivot_point.look_at(get_global_mouse_position())
	pivot_point.rotation += recoil_offset

	var flipped = get_global_mouse_position().x < global_position.x
	revolver.flip_v = flipped

	fire_point.position = Vector2(fire_point_start.x, -fire_point_start.y if flipped else fire_point_start.y)

	if velocity.length() > 0.0:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")

	if direction[0] > 0:
		animated_sprite.flip_h = false
	elif direction[0] < 0:
		animated_sprite.flip_h = true

	if Input.is_action_just_pressed("reload") and can_shoot:
		reload()

	if Input.is_action_just_pressed("shoot") and can_shoot:
		if reload_needed:
			reload()
		else:
			$Control/Shoot.play()
			var bullet_type = bullet_types[chamber_pointer % 6]
			var bullet_speed = 250

			match bullet_type:
				"regular":
					main.shoot(fire_point.global_position, pivot_point.global_rotation, 1, 1, Color(1.0, 0.82, 0.0, 1.0), bullet_speed, single_damage)

				"fast":
					main.shoot(fire_point.global_position, pivot_point.global_rotation, 1, 1, Color(1.0, 0.82, 0.0, 1.0), 900, fast_damage)

				"triple":
					shoot_triple(1, 1, Color(1.0, 0.82, 0.0, 1.0), bullet_speed, triple_damage)

				"ghost":
					main.shoot(fire_point.global_position, pivot_point.global_rotation, 3, 3, Color(1.0, 1.0, 1.0, 1.0), bullet_speed, ghost_damage)

				"ghost_fast":
					main.shoot(fire_point.global_position, pivot_point.global_rotation, 3, 3, Color(1.0, 1.0, 1.0, 1.0), 900, ghost_fast_damage)

				"ghost_triple":
					shoot_triple(3, 3, Color(1.0, 1.0, 1.0, 1.0), bullet_speed, ghost_triple_damage)

			rotate_cylinder()
			recoil()
			bullet_take_out()


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


func hit(dam):
	health -= dam
	health_bar.value = health
	if health <= 0:
		death()
		
func death():
	animated_sprite.play("death")
	$Control/Death.play()

	collision_layer = 0
	collision_mask = 0
	revolver.visible = false
	if animated_sprite.flip_h:
		global_position.x -= 18
		camera_2d.global_position.x += 18
	else: 
		global_position.x += 18
		camera_2d.global_position.x -= 18
		
	await get_tree().create_timer(3).timeout
	main.death()


func rotate_cylinder() -> void:
	can_shoot = false
	var tween = create_tween()
	tween.tween_property(cylinder, "rotation_degrees", cylinder.rotation_degrees + 60.0, 0.5)
	await tween.finished
	can_shoot = true


func recoil() -> void:
	if recoil_tween and recoil_tween.is_running():
		recoil_tween.kill()

	var deg = -20.0 if not revolver.flip_v else 20.0

	recoil_tween = create_tween()
	recoil_tween.tween_property(self, "recoil_offset", deg_to_rad(deg), 0.03)
	recoil_tween.tween_property(self, "recoil_offset", 0.0, 0.45)
	recoil_tween.set_trans(Tween.TRANS_QUAD)
	recoil_tween.set_ease(Tween.EASE_OUT)


func bullet_take_out():
	cylinder.get_child(chamber_pointer % 6).get_child(0).queue_free()
	chamber_pointer += 1

	if chamber_pointer % 6 == 0:
		reload_needed = true


func reload() -> void:
	$Control/Reload.play()
	can_shoot = false
	reload_needed = false
	bullet_types.clear()

	var chambers = cylinder.get_children()

	# Remove existing chamber icons.
	for chamber in chambers:
		for bullet in chamber.get_children():
			bullet.queue_free()

	# First roll regular vs ghost.
	# Then select a variant from the unlocked types.
	for i in range(chambers.size()):
		var bullet_type: String

		if randf() < 0.5:
			var regular_types: Array[String] = ["regular"]

			if fast_unlocked:
				regular_types.append("fast")
			if triple_unlocked:
				regular_types.append("triple")

			bullet_type = regular_types.pick_random()
		else:
			var ghost_types: Array[String] = ["ghost"]

			if ghost_fast_unlocked:
				ghost_types.append("ghost_fast")
			if ghost_triple_unlocked:
				ghost_types.append("ghost_triple")

			bullet_type = ghost_types.pick_random()

		bullet_types.append(bullet_type)

	# Align the next chamber and spin.
	var current_chamber = chamber_pointer % 6
	var alignment_rotation = (6 - current_chamber) % 6 * 60.0
	var target_rotation = cylinder.rotation_degrees + 360.0 + alignment_rotation

	var tween = create_tween()
	tween.tween_property(
		cylinder,
		"rotation_degrees",
		target_rotation,
		1.0
	)

	# Load the matching icon into each chamber.
	for i in range(chambers.size()):
		if i > 0:
			await get_tree().create_timer(1.0 / 6.0).timeout

		var bullet := Sprite2D.new()

		match bullet_types[i]:
			"regular":
				bullet.texture = regular_bullet_texture
			"fast":
				bullet.texture = fast_bullet_texture
			"triple":
				bullet.texture = triple_bullet_texture
			"ghost":
				bullet.texture = ghost_bullet_texture
			"ghost_fast":
				bullet.texture = ghost_fast_bullet_texture
			"ghost_triple":
				bullet.texture = ghost_triple_bullet_texture

		chambers[i].add_child(bullet)

	await tween.finished

	chamber_pointer = 0
	reload_needed = false
	can_shoot = true


func give_money(n):
	money += n
	money_label.text = str(money) + "$"
	main.spawn_level += 1
	main.update_spawn_interval()
	main.increase_score()
	$CanvasLayer/Score.text = str(main.spawn_level)


func heal():
	if money >= 3:
		$Control/Pay.play()
		money -= 3
		money_label.text = str(money) + "$"
		health = 10
		health_bar.value = health


func unlock_fast():
	if money >= 20 and not fast_unlocked:
		$Control/Pay.play()
		money -= 20
		money_label.text = str(money) + "$"
		fast_unlocked = true


func unlock_triple():
	if money >= 20 and not triple_unlocked:
		$Control/Pay.play()
		money -= 20
		money_label.text = str(money) + "$"
		triple_unlocked = true


func unlock_ghost_fast():
	if money >= 20 and not ghost_fast_unlocked:
		$Control/Pay.play()
		money -= 20
		money_label.text = str(money) + "$"
		ghost_fast_unlocked = true


func unlock_ghost_triple():
	if money >= 20 and not ghost_triple_unlocked:
		$Control/Pay.play()
		money -= 20
		money_label.text = str(money) + "$"
		ghost_triple_unlocked = true
		
func upgrade_single():
	if money >= 5:
		$Control/Pay.play()
		money -= 5
		money_label.text = str(money) + "$"
		single_damage = 2
		print(single_damage)
		
func upgrade_fast():
	if money >= 7:
		$Control/Pay.play()
		money -= 7
		money_label.text = str(money) + "$"
		fast_damage = 2
		
func upgrade_triple():
	if money >= 10:
		$Control/Pay.play()
		money -= 10
		money_label.text = str(money) + "$"
		triple_damage = 2
		
func upgrade_ghost():
	if money >= 5:
		$Control/Pay.play()
		money -= 5
		money_label.text = str(money) + "$"
		ghost_damage = 2
		
func upgrade_ghost_fast():
	if money >= 7:
		$Control/Pay.play()
		money -= 7
		money_label.text = str(money) + "$"
		ghost_fast_damage = 2
		
func upgrade_ghost_triple():
	if money >= 10:
		$Control/Pay.play()
		money -= 10
		money_label.text = str(money) + "$"
		ghost_triple_damage = 2


func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "death":
		dust.show()
		dust.play("kickup")
		print(dust.sprite_frames.has_animation("kickup"))
