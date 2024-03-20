extends Control

@export var spawn_points: Array[Marker3D]

#region Buttons
@onready var host_button: Button = $Host
@onready var join_button: Button = $Join
@onready var proceed_button: Button = $Proceed
#endregion

#region Line Edits
@onready var name_entry: LineEdit = $NameEntry
@onready var address_entry: LineEdit = $AddressEntry
#endregion

#region Labels
@onready var host_label: Label = $HostLabel
@onready var address_warning_label: Label = $AddressWarningLabel
@onready var name_warning_label: Label = $NameWarningLabel
#endregion

var enet_peer

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	self.show()
	host_label.hide()
	address_warning_label.hide()
	name_warning_label.hide()
	proceed_button.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func connected_to_server():
	MultiplayerController.send_player_information.rpc_id(1, name_entry.text, MultiplayerController.multiplayer.get_unique_id(), "Bean")

func _on_host_pressed():
	enet_peer = MultiplayerController.enet_peer
	enet_peer.create_server(MultiplayerController.PORT, 5)
	multiplayer.multiplayer_peer = enet_peer
	
	MultiplayerController.upnp_setup()
	
	MultiplayerController.send_player_information(name_entry.text, multiplayer.get_unique_id(), "")
	
	multiplayer.peer_connected.connect(add_character)
	
	host_label.text = "Hosting. Waiting for players..."
	host_label.show()
	if (multiplayer.is_server()):
		proceed_button.show()

@rpc("any_peer", "call_local")
func _on_join_pressed():
	if (address_entry.text != "") and (name_entry.text != ""):
		MultiplayerController.enet_peer.create_client(address_entry.text, MultiplayerController.PORT)
		multiplayer.multiplayer_peer = MultiplayerController.enet_peer
		
		var id = multiplayer.get_unique_id()
		MultiplayerController.multiplayer.connected_to_server.connect(connected_to_server)
		host_label.text = "Joined. Waiting for host to start..."
		host_label.show()
	
	if (address_entry.text == ""):
		address_warning_label.text = "Enter an IP address."
		address_warning_label.show()
		
		await get_tree().create_timer(5).timeout
		address_warning_label.hide()
	
	if (name_entry.text == ""):
		name_warning_label.text = "Please enter a username."
		name_warning_label.show()
		
		await get_tree().create_timer(5).timeout
		name_warning_label.text = ""
		address_warning_label.hide()

@rpc("call_local")
func add_character(peer_id: int, character: String):
	var player = MultiplayerController.player_scene.instantiate()
	player.name = str(peer_id)
	add_child(player)
	player.global_position = spawn_points.pick_random().global_position

@rpc("any_peer", "call_local")
func _on_proceed_pressed():
	var peer_id = multiplayer.get_unique_id()
	print(peer_id)
	start_lobby.rpc()
	add_character.rpc(peer_id, GameController.players[peer_id].character)

@rpc("any_peer", "call_local")
func start_lobby():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	self.hide()
	
