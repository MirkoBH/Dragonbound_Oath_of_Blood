extends Node
## Escena principal: esqueleto fijo del juego. Lo que cambia es lo que el
## gestor de niveles carga dentro de LevelRoot (1.4.2.1).

## Empieza directamente la partida. Es provisorio: desde 1.4.1.1 la inicia el
## menú principal.
@export var iniciar_al_arrancar: bool = true

@onready var _gestor: GestorNiveles = %GestorNiveles


func _ready() -> void:
	if iniciar_al_arrancar:
		_gestor.iniciar_partida()
