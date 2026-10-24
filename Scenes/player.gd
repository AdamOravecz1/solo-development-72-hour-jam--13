extends CharacterBody2D

@export var speed: float = 150.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var pivot_point: Node2D = $PivotPoint
@onready var revolver: Sprite2D = $PivotPoint/Revolver
@onready var fire_point: Node2D = $PivotPoint/Revolver/FirePoint
@onready var cylinder: Sprite2D = $CanvasLayer/Cylinder
@onready var health_bar: TextureProgressBar = $CanvasLayer/HealthBar


var bullet_types: Array[String] = ["regular", "regular", "regular", "regular", "regular", "regular"]
var regular_bullet_texture: Texture2D = preload("res://Sprites/RegularBullet.png")
var ghost_bullet_texture: Texture2D = preload("res://Sprites/GhostBullet.png")

var can_shoot = true
var reload_needed = false

var chamber_pointer: int = 0

var recoil_offset: float = 0.0
var recoil_tween: Tween

@onready var main = get_tree().current_scene
var fire_point_start: Vector2

var health: int = 10

func _ready() -> void:
	health_bar.max_value = health
	fire_point_start = fire_point.position

	for i in cylinder.get_children():
		var regular_bullet := Sprite2D.new()
		regular_bullet.texture = preload("res://Sprites/RegularBullet.png")
		i.add_child(regular_bullet)

func _process(delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed
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
			print(bullet_types[chamber_pointer%6])
			if bullet_types[chamber_pointer%6] == "regular":
				main.shoot(fire_point.global_position, pivot_point.global_rotation, 1, 1, Color(1.0, 0.82, 0.0, 1.0), 500)
			else:
				main.shoot(fire_point.global_position, pivot_point.global_rotation, 3, 3, Color(1.0, 1.0, 1.0, 1.0), 500)
			rotate_cylinder()
			recoil()
			bullet_take_out()

		
func hit(dam):
	health -= dam
	health_bar.value = health
	

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
	cylinder.get_child(chamber_pointer%6).get_child(0).queue_free()
	chamber_pointer += 1
	if chamber_pointer%6 == 0:
		reload_needed = true
		


func reload() -> void:
	can_shoot = false
	reload_needed = false
	bullet_types.clear()

	var chambers = cylinder.get_children()

	# Remove existing bullets.
	for chamber in chambers:
		for bullet in chamber.get_children():
			bullet.queue_free()

	# Determine bullet types before spinning.
	for i in range(chambers.size()):
		bullet_types.append("regular" if randf() < 0.5 else "ghost")

	# Start the cylinder spin.
	var tween = create_tween()
	tween.tween_property(
		cylinder,
		"rotation_degrees",
		cylinder.rotation_degrees + 360.0,
		1.0
	)

	# Place bullets at 1/6-second intervals.
	for i in range(chambers.size()):
		if i > 0:
			await get_tree().create_timer(1.0 / 6.0).timeout

		var bullet := Sprite2D.new()
		bullet.texture = regular_bullet_texture if bullet_types[i] == "regular" else ghost_bullet_texture
		chambers[i].add_child(bullet)

	# Wait for the actual animation to finish.
	await tween.finished
	
	chamber_pointer = 0
	chamber_pointer = 0
	reload_needed = false
	can_shoot = true
