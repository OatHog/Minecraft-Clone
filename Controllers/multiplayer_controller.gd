extends Node

@onready var main_menu: PackedScene = preload("res://Scenes/UI/main_menu.tscn")

# Multiplayer related variables
@onready var player_scene: PackedScene = preload("res://Scenes/player.tscn")
const PORT = 6000
@onready var enet_peer = ENetMultiplayerPeer.new()

func _ready():
	pass

func _input(event):
	if event.is_action_pressed("v"):
		print(GameController.players)

@rpc("any_peer")
func send_player_information(name: String, id: int, character: String):
	if !GameController.players.has(id):
		GameController.players[id] = {
			"name" : name,
			"id" : id,
			"character" : character
		}
	if multiplayer.is_server():
		for i in GameController.players:
			send_player_information.rpc(GameController.players[i].name, i, character)

func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)
	
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")
		
	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
		
	print("Success! Join Address: %s" % upnp.query_external_address())

#func connected_to_server():
	#send_player_information.rpc_id(1, name_entry.text, multiplayer.get_unique_id(), "Helmet")

func server_connection_failed():
	print("connection failed.")

func _on_proceed_pressed():
	start_lobby.rpc()

@rpc("any_peer", "call_local")
func start_lobby():
	main_menu.hide()

@rpc("any_peer", "call_local")
func add_character(peer_id: int, character: String):
	if GameController.players[peer_id].character == "Helmet":
		var player = player_scene.instantiate()
		player.name = str(peer_id)
		add_child(player)
		player.global_position = $"../Platform/SpawnPoint".global_position

@rpc("any_peer", "call_local")
func send_helmet_type():
	GameController.players[multiplayer.get_unique_id()].character = "Helmet"

@rpc("any_peer", "call_local")
func _on_start_button_pressed():
	var peer_id = multiplayer.get_unique_id()
	add_character.rpc(peer_id, GameController.players[peer_id].character)
