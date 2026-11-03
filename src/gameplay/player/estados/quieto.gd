extends EstadoJugador
## William en reposo, en el suelo. Si venía corriendo, termina de frenar acá.


func _init() -> void:
	prioridad = 9


func actualizar_fisica(delta: float) -> void:
	jugador.aplicar_gravedad(delta)
	if revisar_acciones_en_suelo():
		return
	var direccion := jugador.obtener_direccion()
	jugador.mover_horizontal(direccion, delta)
	if direccion != 0.0:
		cambiar_a(&"Correr")
