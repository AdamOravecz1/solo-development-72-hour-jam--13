extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: InteractionArea = $InteractionArea
@onready var canvas_layer: CanvasLayer = $CanvasLayer


@onready var player = get_tree().get_first_node_in_group("Player")


func _ready():
	if not Engine.is_editor_hint():
		interaction_area.interact = Callable(self, "_shop")
		
func _shop():
	canvas_layer.visible = !canvas_layer.visible
	player.can_shoot = !canvas_layer.visible
	if canvas_layer.visible:
		animated_sprite.play("up")
		$Sounds/GetUp.play()
	else:
		animated_sprite.play("down")
		$Sounds/GetDown.play()



func _on_body_exited(body: Node2D) -> void:
	if body == player and canvas_layer.visible:
		$Sounds/GetDown.play()
		animated_sprite.play("down")
		player.can_shoot = true
		canvas_layer.visible = false


func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "up":
		animated_sprite.play("idle")


func _on_button_pressed() -> void:
	player.heal()
