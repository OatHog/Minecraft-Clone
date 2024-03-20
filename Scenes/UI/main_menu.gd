extends Control

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

func _ready():
	host_label.hide()
	address_warning_label.hide()
	name_warning_label.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func connected_to_server():
	MultiplayerController.send_player_information.rpc_id(1, name_entry.text, MultiplayerController.multiplayer.get_unique_id(), "Bean")

func _on_host_pressed():
	MultiplayerController.enet_peer.create_server(MultiplayerController.PORT, 5)
	MultiplayerController.multiplayer.multiplayer_peer = MultiplayerController.enet_peer
	
	MultiplayerController.upnp_setup()
	
	MultiplayerController.send_player_information(name_entry.text, multiplayer.get_unique_id(), "")
	
	host_label.text = "Hosting. Waiting for players..."
	host_label.show()

@rpc("any_peer", "call_local")
func _on_join_pressed():
	if (address_entry.text != "") and (name_entry.text != ""):
		MultiplayerController.enet_peer.create_client(address_entry.text, MultiplayerController.PORT)
		MultiplayerController.multiplayer.multiplayer_peer = MultiplayerController.enet_peer
		
		var id = multiplayer.get_unique_id()
		MultiplayerController.multiplayer.connected_to_server.connect(MultiplayerController.connected_to_server)
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

