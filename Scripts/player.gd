extends CharacterBody3D


const SPEED = 8.0
const JUMP_VELOCITY = 12.0

@onready var camera: Camera3D = $Camera3D
@onready var ray_cast_3d: RayCast3D = $Camera3D/RayCast3D
@onready var name_label: Label = $Node3D/SubViewport/Label

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 24.0
var sensitivity: float = 0.002

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if !is_multiplayer_authority(): return
	update_name_label.rpc()
	
	camera.make_current()

func _unhandled_input(event):
	if !is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion:
		rotation.y = rotation.y - event.relative.x * sensitivity
		camera.rotation.x = camera.rotation.x - event.relative.y * sensitivity
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(80))

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("a", "d", "w", "s")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# Handle mouse clicks
	if Input.is_action_just_pressed("left_click"):
		hit_block.rpc()
	
	if Input.is_action_just_pressed("right_click"):
		place_block.rpc()

	move_and_slide()

@rpc("any_peer", "call_local")
func update_name_label():
	var player_name: String = GameController.players[multiplayer.get_unique_id()].name 
	name_label.text = str(player_name)

@rpc("authority", "call_local")
func hit_block():
	if ray_cast_3d.is_colliding():
			if ray_cast_3d.get_collider().has_method("destroy_block"):
				ray_cast_3d.get_collider().destroy_block(ray_cast_3d.get_collision_point() - 
														ray_cast_3d.get_collision_normal())
														
@rpc("authority", "call_local")
func place_block():
	if ray_cast_3d.is_colliding():
			if ray_cast_3d.get_collider().has_method("place_block"):
				ray_cast_3d.get_collider().place_block(ray_cast_3d.get_collision_point() + 
														ray_cast_3d.get_collision_normal(), 5)
