extends Node2D
## Prueba automática de la máquina de estados de William (1.4.3.1).
##
## Desde el editor: abrir src/debug/prueba_maquina_estados.tscn y presionar F6.
## El resultado aparece en el panel Salida.
## Desde la terminal (carpeta del proyecto):
##   godot --headless res://src/debug/prueba_maquina_estados.tscn
##
## Simula las teclas del Mapa de entrada y verifica cada paso entre estados y
## la prioridad de 1.2.5.1 (sección 5.3).

const TECLAS := {
	&"mover_izquierda": KEY_A, &"mover_derecha": KEY_D, &"apuntar_arriba": KEY_W,
	&"apuntar_abajo": KEY_S, &"saltar": KEY_SPACE, &"impulso": KEY_SHIFT,
	&"atacar": KEY_J, &"aliento": KEY_K, &"armadura": KEY_Q,
	&"pocion_curacion": KEY_1, &"pocion_energia": KEY_2, &"interactuar": KEY_E,
	&"inventario": KEY_I, &"pausa": KEY_ESCAPE,
}

var _fallas := 0
var _jugador: Jugador
var _golpes := 0
var _muertes_terminadas := 0
var _cambios: Array[StringName] = []


func _ready() -> void:
	print("Mapa de entrada (1.2.3.3)")
	_probar_teclas()
	EscenarioPrueba.crear_terreno(self, Rect2(-2000, 0, 4000, 32))
	_jugador = preload("res://src/gameplay/player/player.tscn").instantiate()
	_jugador.position = Vector2(0, -40)
	add_child(_jugador)
	_jugador.golpe_activado.connect(func() -> void: _golpes += 1)
	_jugador.muerte_terminada.connect(func() -> void: _muertes_terminadas += 1)
	_jugador.estado_cambiado.connect(func(_a: StringName, nuevo: StringName) -> void: _cambios.append(nuevo))

	print("Configuración")
	_verificar(_jugador.collision_layer == CapasColision.capa(CapasColision.Perfil.CUERPO_WILLIAM), "William usa la capa «Cuerpo de William».")
	_verificar(_jugador.obtener_estado() == &"Quieto", "Arranca en Quieto.")

	print("Caer y aterrizar")
	await _esperar(2)
	_verificar(_jugador.obtener_estado() == &"Caer", "En el aire pasa a Caer.")
	await _esperar_estado(&"Quieto", 120)
	_verificar(_jugador.obtener_estado() == &"Quieto" and _jugador.is_on_floor(), "Al tocar el piso vuelve a Quieto.")

	print("Correr")
	await _mantener(&"mover_derecha", 5)
	_verificar(_jugador.obtener_estado() == &"Correr" and _jugador.velocity.x > 0.0, "Con D corre a la derecha.")
	_verificar(is_equal_approx(_jugador.velocity.x, 7.0 * Jugador.TILE), "Corre a 7 tiles/s (1.2.6.1).")
	Input.action_release(&"mover_derecha")
	await _esperar(2)
	_verificar(_jugador.obtener_estado() == &"Quieto" and _jugador.velocity.x == 0.0, "Al soltar vuelve a Quieto.")
	await _mantener(&"mover_izquierda", 3)
	Input.action_release(&"mover_izquierda")
	await _esperar(2)
	_verificar(_jugador.mirando == -1, "Mira hacia el último lado al que se movió.")

	print("Saltar")
	var y_inicial := _jugador.position.y
	await _tocar(&"saltar")
	_verificar(_jugador.obtener_estado() == &"Saltar" and _jugador.velocity.y < 0.0, "Espacio en el suelo pasa a Saltar.")
	var y_minima := y_inicial
	var paso_por_caer := false
	for i in 120:
		await get_tree().physics_frame
		y_minima = minf(y_minima, _jugador.position.y)
		if _jugador.obtener_estado() == &"Caer":
			paso_por_caer = true
		if paso_por_caer and _jugador.obtener_estado() == &"Quieto":
			break
	_verificar(paso_por_caer, "Pasada la cima pasa a Caer.")
	_verificar(_jugador.obtener_estado() == &"Quieto", "Al aterrizar vuelve a Quieto.")
	var altura := (y_inicial - y_minima) / Jugador.TILE
	_verificar(absf(altura - 3.5) < 0.25, "El salto llega a unos 3,5 tiles (da %.2f)." % altura)

	print("Atacar en el suelo")
	_golpes = 0
	Input.action_press(&"mover_derecha")
	await _esperar(3)
	await _tocar(&"atacar")
	_verificar(_jugador.obtener_estado() == &"Atacar", "J pasa a Atacar.")
	await _esperar(3)
	_verificar(_jugador.velocity.x == 0.0, "En el suelo se detiene durante el golpe, aunque se mantenga D (AW-02).")
	await _esperar_estado(&"Correr", 40)
	Input.action_release(&"mover_derecha")
	_verificar(_golpes == 1, "El golpe se activa una sola vez por ataque.")
	_verificar(_cambios.slice(-2) == [&"Atacar", &"Correr"], "Al terminar el ataque, con D pulsada, vuelve a Correr.")
	await _esperar(2)

	print("Atacar en el aire")
	Input.action_press(&"mover_derecha")
	await _tocar(&"saltar")
	await _esperar(4)
	await _tocar(&"atacar")
	_verificar(_jugador.obtener_estado() == &"Atacar", "Se puede atacar en el aire (AW-01).")
	Input.action_release(&"mover_derecha")
	await _esperar(3)
	_verificar(_jugador.velocity.x > 0.0 and not _jugador.is_on_floor(), "En el aire conserva el impulso horizontal (AW-02).")
	await _esperar_estado(&"Quieto", 120)
	_verificar(_jugador.obtener_estado() == &"Quieto", "Después del ataque en el aire cae y aterriza.")

	print("Recibir daño")
	await _tocar(&"atacar")
	await _esperar(2)
	var x_antes := _jugador.position.x
	_golpes = 0
	var aplicado := _jugador.recibir_danio(_jugador.position.x + 10.0)
	_verificar(aplicado and _jugador.obtener_estado() == &"RecibirDanio", "Un golpe interrumpe el ataque.")
	await _esperar(6)
	_verificar(_golpes == 0, "El golpe de espada que estaba saliendo se cancela.")
	Input.action_press(&"mover_derecha")
	await _esperar(2)
	_verificar(_jugador.position.x < x_antes, "El retroceso empuja en sentido contrario al golpe, sin control del jugador.")
	await _esperar_estado(&"Correr", 30)
	Input.action_release(&"mover_derecha")
	var retroceso := (x_antes - _jugador.position.x) / Jugador.TILE
	_verificar(_jugador.obtener_estado() == &"Correr", "Pasado el retroceso, recupera el control.")
	_verificar(retroceso > 0.3 and retroceso < 0.7, "El retroceso es de unos ½ tile (da %.2f)." % retroceso)
	await _esperar(3)

	print("Morir")
	_muertes_terminadas = 0
	_verificar(_jugador.morir() and _jugador.obtener_estado() == &"Morir", "Morir interrumpe cualquier estado.")
	_verificar(not _jugador.recibir_danio(_jugador.position.x + 10.0), "Mientras muere, un golpe no lo interrumpe.")
	_verificar(not _jugador.morir(), "Morir no se vuelve a aplicar.")
	Input.action_press(&"mover_derecha")
	await _tocar(&"saltar")
	await _tocar(&"atacar")
	_verificar(_jugador.obtener_estado() == &"Morir" and _jugador.velocity.x == 0.0, "Mientras muere ignora las teclas.")
	Input.action_release(&"mover_derecha")
	await _esperar(90)
	_verificar(_muertes_terminadas == 1, "Al terminar la animación avisa una sola vez que murió.")

	print("Resultado: %s" % ("todo OK" if _fallas == 0 else "%d fallas" % _fallas))
	get_tree().quit(0 if _fallas == 0 else 1)


func _probar_teclas() -> void:
	for accion in TECLAS:
		var tecla_ok := false
		if InputMap.has_action(accion):
			for evento in InputMap.action_get_events(accion):
				if evento is InputEventKey and evento.physical_keycode == TECLAS[accion]:
					tecla_ok = true
		_verificar(tecla_ok, "%s → %s" % [accion, OS.get_keycode_string(TECLAS[accion])])


func _esperar(cuadros: int) -> void:
	for i in cuadros:
		await get_tree().physics_frame


func _esperar_estado(estado: StringName, maximo: int) -> void:
	for i in maximo:
		if _jugador.obtener_estado() == estado:
			return
		await get_tree().physics_frame


func _tocar(accion: StringName) -> void:
	Input.action_press(accion)
	await _esperar(1)
	Input.action_release(accion)
	await _esperar(1)


func _mantener(accion: StringName, cuadros: int) -> void:
	Input.action_press(accion)
	await _esperar(cuadros)


func _verificar(condicion: bool, descripcion: String) -> void:
	if condicion:
		print("  OK    ", descripcion)
	else:
		_fallas += 1
		print("  FALLA ", descripcion)
