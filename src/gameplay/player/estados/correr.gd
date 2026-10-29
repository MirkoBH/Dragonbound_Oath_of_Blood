extends EstadoJugador
## William corre en el suelo.


func _init() -> void:
	prioridad = 8


func actualizar_fisica(delta: float) -> void:
	jugador.aplicar_gravedad(delta)
	if revisar_acciones_en_suelo():
		return
	var direccion := jugador.obtener_direccion()
	if direccion == 0.0:
		cambiar_a(&"Quieto")
		return
	jugador.mover_horizontal(direccion)
