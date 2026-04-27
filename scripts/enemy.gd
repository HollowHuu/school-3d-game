extends CharacterBody3D

enum States {
	Attack,
	Idle,
	Chase,
	Die
}

var state = States.Idle

var hp = 15
var speed = 2
var accel = 10
var gravity = 9.8
var target = null
var damage = 10

@export var navAgent: NavigationAgent3D
@export var animPlayer: AnimationPlayer

func enemy():
	pass
	
func give_loot():
	target.gold += 50

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity
	
	if state == States.Idle:
		velocity = Vector3(0, velocity.y, 0)
		animPlayer.play("Idle")
	elif state == States.Chase:
		look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP, true)
		navAgent.target_position = target.global_position
		
		var direction = navAgent.get_next_path_position() - global_position
		direction = direction.normalized()
		
		velocity = velocity.lerp(direction * speed, accel * delta)
		animPlayer.play("Walk")
		
		pass
	elif state == States.Attack:
		look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP, true)
		animPlayer.play("Punch")
		pass
	elif state == States.Die:
		print("Dead")
		velocity = Vector3.ZERO
		animPlayer.play("Die")
		pass
		
	move_and_slide()

func _process(delta: float) -> void:
	if hp <= 0:
		state = States.Die


func attack():
	target.hp -= damage

func _on_chase_area_body_entered(body: Node3D) -> void:
	if body.has_method("player"):
		target = body
		state = States.Chase

func _on_chase_area_body_shape_exited(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	if body.has_method("player"):
		target = null
		state = States.Idle


func _on_attack_area_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	if body.has_method("player"):
		state = States.Attack


func _on_attack_area_body_shape_exited(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	if body.has_method("player"):
		state = States.Chase
