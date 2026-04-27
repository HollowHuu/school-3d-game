extends CharacterBody3D

enum State { IDLE, CHASE, ATTACK, DIE }

const GRAVITY := 9.8

var state: State = State.IDLE
var hp := 15
var speed := 2.0
var accel := 10.0
var damage := 10
var target: Node3D = null

# Flocking weights — tweak these in the Inspector or here
@export var separation_weight := 2.0
@export var alignment_weight := 1.0
@export var cohesion_weight := 1.0
@export var flock_radius := 3.0  # How far away an enemy counts as a neighbour

@export var nav_agent: NavigationAgent3D
@export var anim_player: AnimationPlayer


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	match state:
		State.IDLE:
			velocity = Vector3(0.0, velocity.y, 0.0)
			anim_player.play("Idle")

		State.CHASE:
			_face_target()
			nav_agent.target_position = target.global_position

			var next_pos := nav_agent.get_next_path_position()
			var nav_dir := (next_pos - global_position).normalized()

			# Blend navmesh direction with flock steering
			var flock := _get_flock_force()
			var combined := (nav_dir + flock).normalized()

			velocity = velocity.lerp(Vector3(combined.x, velocity.y, combined.z) * speed, accel * delta)
			anim_player.play("Walk")

		State.ATTACK:
			_face_target()
			velocity = Vector3(0.0, velocity.y, 0.0)
			anim_player.play("Punch")

		State.DIE:
			velocity = Vector3(0.0, velocity.y, 0.0)
			anim_player.play("Die")

	move_and_slide()


func _process(_delta: float) -> void:
	if hp <= 0 and state != State.DIE:
		_die()


func _get_flock_force() -> Vector3:
	var neighbours: Array[CharacterBody3D] = []

	# Collect nearby enemies
	for body in get_tree().get_nodes_in_group("enemies"):
		if body == self:
			continue
		if body.global_position.distance_to(global_position) <= flock_radius:
			neighbours.append(body)

	if neighbours.is_empty():
		return Vector3.ZERO

	var separation := Vector3.ZERO
	var alignment := Vector3.ZERO
	var cohesion := Vector3.ZERO

	for n in neighbours:
		var to_me := global_position - n.global_position

		# Separation — push away, stronger when closer
		var dist := to_me.length()
		if dist > 0.0:
			separation += to_me.normalized() / dist

		# Alignment — match neighbour velocity direction
		alignment += Vector3(n.velocity.x, 0.0, n.velocity.z)

		# Cohesion — pull toward group center
		cohesion += n.global_position

	var count := float(neighbours.size())

	alignment /= count
	cohesion = (cohesion / count) - global_position  # Direction toward center

	# Normalise each force before weighting so no single one dominates by magnitude
	if separation.length() > 0.0:
		separation = separation.normalized()
	if alignment.length() > 0.0:
		alignment = alignment.normalized()
	if cohesion.length() > 0.0:
		cohesion = cohesion.normalized()

	return (separation * separation_weight) + (alignment * alignment_weight) + (cohesion * cohesion_weight)


func _face_target() -> void:
	if target:
		look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP, true)


func _attack() -> void:
	if target and is_instance_valid(target):
		target.hp -= damage


func _die() -> void:
	state = State.DIE
	give_loot()


func give_loot() -> void:
	if target and is_instance_valid(target):
		target.gold += 50


func is_enemy() -> bool:
	return true


func _on_chase_area_body_entered(body: Node3D) -> void:
	if body.has_method("is_player"):
		target = body
		state = State.CHASE


func _on_chase_area_body_exited(body: Node3D) -> void:
	if body.has_method("is_player"):
		target = null
		state = State.IDLE


func _on_attack_area_body_entered(body: Node3D) -> void:
	if body.has_method("is_player"):
		state = State.ATTACK


func _on_attack_area_body_exited(body: Node3D) -> void:
	if body.has_method("is_player"):
		state = State.CHASE
