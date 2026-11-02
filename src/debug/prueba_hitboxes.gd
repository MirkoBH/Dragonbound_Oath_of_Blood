extends Node2D
## Prueba automática de hitboxes y hurtboxes (1.4.4.2).
##
## Desde el editor: abrir src/debug/prueba_hitboxes.tscn y presionar F6.
## El resultado aparece en el panel Salida.
## Desde la terminal (carpeta del proyecto):
##   godot --headless res://src/debug/prueba_hitboxes.tscn

var _fallas := 0
var _jugador: Jugador
var _golpes_william: Array[Golpe] = []


func _ready() -> void:
	EscenarioPrueba.crear_terreno(self, Rect2(-3000, 0, 6000, 32))
	_jugador = preload("res://src/gameplay/player/player.tscn").instantiate()
	_jugador.position = Vector2(0, -1)
	add_child(_jugador)
	_jugador.golpe_recibido.connect(func(golpe: Golpe) -> void: _golpes_william.append(golpe))
	await _esperar(10)

	print("Configuración de William")
	_verificar(_jugador.espada.collision_layer == CapasColision.capa(CapasColision.Perfil.ATAQUE_WILLIAM), "La espada usa la capa «Ataques de William».")
	_verificar(_jugador.area_golpes.collision_layer == CapasColision.capa(CapasColision.Perfil.RECIBE_GOLPES_WILLIAM), "El área de golpes usa la capa «Recibe golpes: William».")
	_verificar(not _jugador.espada.esta_activa(), "La espada empieza inactiva.")

	print("La espada de William")
	var blanco := _munieco(Vector2(20, -1))
	await _esperar(5)
	_verificar(blanco.golpes_recibidos == 0, "Sin atacar, la espada no golpea aunque el muñeco esté en su alcance.")
	await _tocar(&"atacar")
	await _esperar(30)
	_verificar(blanco.golpes_recibidos == 1, "Un ataque golpea una sola vez al muñeco, aunque lo toque varios cuadros.")
	var golpe := blanco.ultimo_golpe
	_verificar(golpe != null and golpe.danio == 1.0 and golpe.tipo == Golpe.TipoDanio.FISICO, "El golpe lleva 1 corazón físico (1.2.4.2).")
	_verificar(golpe != null and golpe.fuente == _jugador and is_equal_approx(golpe.origen.x, _jugador.global_position.x), "El golpe indica quién golpea y desde dónde.")
	_verificar(_golpes_william.is_empty(), "La espada no golpea a William.")
	await _tocar(&"atacar")
	await _esperar(30)
	_verificar(blanco.golpes_recibidos == 2, "Cada ataque nuevo vuelve a golpear.")
	blanco.queue_free()

	print("Hacia dónde golpea")
	var izquierda := _munieco(Vector2(-20, -1))
	await _mantener(&"mover_izquierda", 2)
	Input.action_release(&"mover_izquierda")
	await _esperar(2)
	await _tocar(&"atacar")
	await _esperar(30)
	_verificar(izquierda.golpes_recibidos == 1, "Mirando a la izquierda, la espada golpea a la izquierda.")
	izquierda.queue_free()
	await _esperar(2)

	print("Golpe interrumpido")
	var otro := _munieco(Vector2(_jugador.position.x - 20, -1))
	await _tocar(&"atacar")
	await _esperar(2)
	_jugador.recibir_danio(_jugador.position.x - 30.0)
	await _esperar(30)
	_verificar(otro.golpes_recibidos == 0 and not _jugador.espada.esta_activa(), "Si un golpe interrumpe el ataque, la espada no llega a golpear.")
	otro.queue_free()
	await _esperar(70)

	print("Ataques enemigos")
	_golpes_william.clear()
	var atacante := _munieco(_jugador.position + Vector2(20, 0), true)
	await _esperar(3)
	atacante.hitbox.activar(0.2)
	await _esperar(3)
	_verificar(_golpes_william.size() == 1 and _jugador.obtener_estado() == &"RecibirDanio", "Un ataque enemigo golpea a William y lo hace retroceder.")
	_verificar(_golpes_william.size() == 1 and _golpes_william[0].danio == 0.5, "El golpe lleva el daño del atacante.")
	_verificar(_jugador.area_golpes.esta_invulnerable(), "Después del golpe, William queda invulnerable.")
	atacante.position = _jugador.position + Vector2(20, 0)
	await _esperar(2)
	atacante.hitbox.activar(0.2)
	await _esperar(15)
	_verificar(_golpes_william.size() == 1, "Durante la invulnerabilidad, otro ataque no lo golpea.")
	_verificar(atacante.golpes_recibidos == 0, "El ataque enemigo no daña al propio enemigo.")
	atacante.queue_free()
	await _esperar(70)

	print("Sin daño por contacto")
	_golpes_william.clear()
	var pared := _munieco(_jugador.position + Vector2(30, 0))
	await _esperar(3)
	Input.action_press(&"mover_derecha")
	await _esperar(30)
	Input.action_release(&"mover_derecha")
	_verificar(_golpes_william.is_empty(), "Tocar un enemigo no hace daño.")
	_verificar(_jugador.position.x < pared.position.x - 8.0, "El enemigo bloquea el paso de William.")
	pared.queue_free()
	await _esperar(3)

	print("Trampas")
	_golpes_william.clear()
	var trampa := EscenarioPrueba.crear_trampa(self, _jugador.position + Vector2(0, 1), 96.0, 10.0, 0.5)
	var trampa_hitbox := trampa.get_child(0) as Hitbox
	await _esperar(3)
	_verificar(_golpes_william.size() == 1 and _golpes_william[0].danio == 0.5, "Pisar la trampa hace ½ corazón (1.2.6.3).")
	await _esperar(30)
	_verificar(_golpes_william.size() == 1, "Mientras dura la invulnerabilidad, la trampa no vuelve a dañar.")
	_verificar(trampa_hitbox.get_overlapping_areas().has(_jugador.area_golpes), "El retroceso no lo saca de una trampa ancha.")
	await _esperar(40)
	_verificar(_golpes_william.size() == 2, "Si sigue sobre la trampa al terminar la invulnerabilidad, vuelve a recibir daño.")
	var enemigo_en_trampa := _munieco(_jugador.position + Vector2(-25, 0))
	await _esperar(5)
	_verificar(enemigo_en_trampa.golpes_recibidos == 0, "La trampa no daña a los enemigos.")
	enemigo_en_trampa.queue_free()

	print("Área de golpes desactivada")
	await _esperar(70)
	_golpes_william.clear()
	_jugador.area_golpes.activa = false
	await _esperar(70)
	_verificar(_golpes_william.is_empty(), "Con el área de golpes desactivada (Armadura, 1.4.5.10), no recibe daño.")
	_jugador.area_golpes.activa = true
	await _esperar(5)
	_verificar(_golpes_william.size() == 1, "Al reactivarla, vuelve a recibir el daño de la trampa.")

	print("Morir")
	_jugador.morir()
	await _esperar(70)
	_verificar(_golpes_william.size() == 1 and not _jugador.area_golpes.activa, "Muerto, ya no recibe golpes.")
	trampa.queue_free()

	print("Resultado: %s" % ("todo OK" if _fallas == 0 else "%d fallas" % _fallas))
	get_tree().quit(0 if _fallas == 0 else 1)


func _munieco(posicion: Vector2, ataca: bool = false) -> Munieco:
	var munieco := Munieco.new()
	munieco.ataca = ataca
	munieco.intervalo = 1000.0
	munieco.position = posicion
	add_child(munieco)
	return munieco


func _esperar(cuadros: int) -> void:
	for i in cuadros:
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
