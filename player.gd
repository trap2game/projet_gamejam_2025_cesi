extends CharacterBody3D

const SPEED = 10.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENS = 0.25
const PROJECTILE_SCENE = preload("res://projectile.tscn")
const TOWER_SCENE = preload("res://towertemplate.tscn")

@onready var cam: Camera3D = $arm/Camera3D
@onready var pistol: Node3D = $arm/Camera3D/pistol
@onready var wrench: Node3D = $arm/Camera3D/wrench
@onready var blue_filter: ColorRect = $arm/Camera3D/ColorRect

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_weapon = "pistol"

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	blue_filter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	update_weapon()

func _input(event):
	# Toggle mouse capture with left click and Escape
	if event.is_action_pressed("leftclick"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event):
	# Mouse look only when captured
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var delta = event.relative * MOUSE_SENS
		cam.rotation.x -= deg_to_rad(delta.y)
		cam.rotation.x = clamp(cam.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		rotate_y(deg_to_rad(-delta.x))


	# Weapon switching
	if event.is_action_pressed("weapon1"):
		switch_weapon("pistol")
	if event.is_action_pressed("weapon2"):
		switch_weapon("wrench")

func _physics_process(delta):
	# Check si le joueur est tombé trop bas et le remonter
	if position.y <= -100:
		position.y = 100

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Movement input
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (cam.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	# Weapon actions
	if Input.is_action_just_pressed("leftclick"):
		if current_weapon == "pistol":
			shoot_projectile()
		elif current_weapon == "wrench":
			place_tower()


func switch_weapon(new_weapon: String):
	current_weapon = new_weapon
	update_weapon()

func update_weapon():
	if pistol:
		pistol.visible = (current_weapon == "pistol")
	if wrench:
		wrench.visible = (current_weapon == "wrench")
	if blue_filter:
		blue_filter.visible = (current_weapon == "wrench")

func shoot_projectile():
	if not pistol:
		print("Pistol node is missing!")
		return

	var projectile = PROJECTILE_SCENE.instantiate() as RigidBody3D
	if not projectile:
		print("Failed to instantiate projectile.")
		return

	# Ajoute le projectile à la scène d'abord
	get_tree().current_scene.add_child(projectile)

	# Vérifie qu'il est bien dans l'arbre avant d'accéder à global_transform
	if not projectile.is_inside_tree():
		print("Projectile is not inside the tree after adding it!")
		return

	# Positionnement du projectile légèrement devant le pistolet
	var spawn_pos = pistol.global_position + (-pistol.global_transform.basis.z * 0.5)
	var cam_forward = -cam.global_transform.basis.z.normalized()

	projectile.global_transform.origin = spawn_pos

	# Appliquer l'impulsion vers l'avant
	# À la place de apply_impulse


	var initial_impulse = cam_forward * 50
	projectile.linear_velocity = cam_forward * 50

func place_tower():
	if wrench:
		var tower = TOWER_SCENE.instantiate()

		# Ajoute d'abord la tour à la scène
		get_tree().current_scene.add_child(tower)

		# Vérifie qu'elle est bien dans l'arbre
		if not tower.is_inside_tree():
			print("Tower is not inside the tree after adding it!")
			return

		# Raycast to find valid placement location
		var ray_origin = cam.global_position
		var ray_direction = -cam.global_transform.basis.z.normalized()

		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * 10)
		query.exclude = [self]  # Exclude the current object from the raycast

		var ray_result = space_state.intersect_ray(query)

		if ray_result:
			tower.global_transform.origin = ray_result.position
		else:
			print("Invalid tower placement!")
	else:
		print("Wrench node is missing!")
