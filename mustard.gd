extends Area2D

@export var pickup_sound: AudioStreamPlayer2D
@export var flash_sound: AudioStreamPlayer2D
@export var flash_rect_path: NodePath 
@export var flash_colors = [Color.RED, Color.BLUE, Color.WHITE, Color.YELLOW]
@export var flash_interval = 0.1

var _flashing = false
var _player = null

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body) -> void:
	if (!_flashing):
		print("PLayer inside me")
		_player = body
		#_player.freeze()  
		pickup_sound.play()
		await pickup_sound.finished
		await start_flashing()

func start_flashing() -> void:
	_flashing = true
	flash_sound.play()
	var flash_rect = get_node(flash_rect_path)
	flash_rect.visible = true
	var i = 0
	while flash_sound.playing:
		flash_rect.color = flash_colors[i % flash_colors.size()]
		i += 1
		await get_tree().create_timer(flash_interval).timeout
	flash_rect.color = Color(0, 0, 0, 0) 
	_player.unfreeze()
	queue_free()
