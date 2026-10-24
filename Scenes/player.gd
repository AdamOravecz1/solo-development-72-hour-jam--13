extends CharacterBody2D

@export var speed: float = 150.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var pivot_point: Node2D = $PivotPoint
@onready var revolver: Sprite2D = $PivotPoint/Revolver
@onready var fire_point: Node2D = $PivotPoint/Revolver/FirePoint
@onready var cylinder: Sprite2D = $CanvasLayer/Cylinder

var can_shoot = true

@onready var main = get_tree().current_scene
var fire_point_start: Vector2

func _ready() -> void:
	fire_point_start = fire_point.position

func _process(delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed
	move_and_slide()
	
	pivot_point.look_at(get_global_mouse_position())

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
		
		
	if Input.is_action_just_pressed("shoot") and can_shoot:
		rotate_cylinder()
		main.shoot(fire_point.global_position, pivot_point.global_rotation, 1, 1, Color(1.0, 1.0, 1.0, 1.0))
		
func hit(dam):
	return
	

func rotate_cylinder() -> void:
	can_shoot = false
	var tween = create_tween()
	tween.tween_property(cylinder, "rotation_degrees", cylinder.rotation_degrees + 60.0, 0.5)
	await tween.finished
	can_shoot = true
