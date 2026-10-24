extends CharacterBody2D

@export var speed: float = 0.0

@export var health: int = 5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var main = get_tree().current_scene

var player: Node2D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	if player == null:
		push_error("No player found in the Player group!")
		
func _physics_process(delta: float) -> void:
	if player == null:
		return
	if health <= 0:
		return

	var direction = (player.global_position - global_position).normalized()
	

	velocity = direction * speed
	
	move_and_slide()
	
func hit(damage):
	if health >= 0:
		health -= damage
	if health <= 0:
		death()
		
func death():
	animated_sprite.play("death")


func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "spawn":
		animated_sprite.play("walk")
		speed = 50.0
