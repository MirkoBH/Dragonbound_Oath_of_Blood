extends EstadoJugador
## William en reposo, en el suelo.


func _init() -> void:
	prioridad = 9


func entrar(_datos: Dictionary = {}) -> void:
	jugador.velocity.x = 0.0


func actualizar_fisica(delta: float) -> void:
	jugador.aplicar_gravedad(delta)
	if revisar_acciones_en_suelo():
		return
	if jugador.obtener_direccion() != 0.0:
		cambiar_a(&"Correr")
