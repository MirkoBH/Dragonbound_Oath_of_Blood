extends EstadoJugador
## William cae (después de la cima del salto o al salir de un borde).


func _init() -> void:
	prioridad = 7


func actualizar_fisica(delta: float) -> void:
	jugador.aplicar_gravedad(delta)
	jugador.mover_horizontal(jugador.obtener_direccion())
	if Input.is_action_just_pressed(&"atacar"):
		cambiar_a(&"Atacar")
	elif jugador.is_on_floor():
		cambiar_a(&"Correr" if jugador.obtener_direccion() != 0.0 else &"Quieto")
