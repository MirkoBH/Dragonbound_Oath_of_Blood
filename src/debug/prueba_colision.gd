extends Node2D
## Prueba automática de la colisión con terreno y plataformas (1.4.3.3).
##
## Desde el editor: abrir src/debug/prueba_colision.tscn y presionar F6.
## El resultado aparece en el panel Salida.
## Desde la terminal (carpeta del proyecto):
##   godot --headless res://src/debug/prueba_colision.tscn
##
## Arma cada caso sobre un TileMapLayer con el tileset provisorio y verifica
## suelo, paredes, techos, corrección de esquinas, plataformas atravesables y
## rampas de 45° y 22,5°.

const T := 16.0
const F := FormasColisionTile.Forma

var _fallas := 0
var _jugador: Jugador
var _capa: TileMapLayer


func _ready() -> void:
	print("Tileset provisorio")
	var tileset: TileSet = preload("res://src/resources/tilesets/tileset_provisorio.tres")
	var errores := FormasColisionTile.validar(tileset)
	_verificar(errores.is_empty(), "Cada tile tiene la forma de FormasColisionTile %s." % ("" if errores.is_empty() else str(errores)))
	_verificar(tileset.get_physics_layer_collision_layer(0) == CapasColision.BIT_TERRENO, "Capa física 0 = «Terreno».")
	_verificar(tileset.get_physics_layer_collision_layer(1) == CapasColision.BIT_PLATAFORMAS, "Capa física 1 = «Plataformas atravesables».")

	print("Suelo")
	await _armar(func(c: TileMapLayer) -> void: EscenarioPrueba.pintar(c, Vector2i(-5, 0), Vector2i(80, 1)), Vector2(0, -1))
	Input.action_press(&"mover_derecha")
	var siempre_en_suelo := true
	var y_min := INF
	var y_max := -INF
	for i in 160:
		await get_tree().physics_frame
		if i > 2:
			siempre_en_suelo = siempre_en_suelo and _jugador.is_on_floor()
			y_min = minf(y_min, _jugador.position.y)
			y_max = maxf(y_max, _jugador.position.y)
	Input.action_release(&"mover_derecha")
	_verificar(siempre_en_suelo, "Corriendo sobre 15 uniones de tiles no se despega del suelo.")
	_verificar(y_max - y_min < 0.5, "No se traba ni salta en las uniones (varía %.2f px)." % (y_max - y_min))
	_verificar(is_equal_approx(_jugador.velocity.x, 7.0 * T), "Corre a 7 tiles/s sobre el tilemap.")

	print("Paredes")
	await _armar(func(c: TileMapLayer) -> void:
		EscenarioPrueba.pintar(c, Vector2i(-5, 0), Vector2i(20, 1))
		EscenarioPrueba.pintar(c, Vector2i(6, -4), Vector2i(7, -1)), Vector2(0, -1))
	await _mantener(&"mover_derecha", 60)
	_verificar(_jugador.is_on_wall(), "Se detecta la pared.")
	_verificar(absf(_jugador.position.x - (6 * T - 6.0)) < 1.0, "Se detiene contra la pared, sin atravesarla (x = %.1f)." % _jugador.position.x)
	_verificar(_jugador.is_on_floor(), "Empujando la pared sigue en el suelo.")
	Input.action_release(&"mover_derecha")

	print("Techos")
	var datos := await _saltar_bajo_techo(3, 9999)
	_verificar(datos.techo, "Saltando bajo un techo a 3 tiles, choca la cabeza.")
	_verificar(datos.altura <= 3 * T - 28.0 + 0.5, "La cabeza no atraviesa el techo (sube %.1f px de 20 posibles)." % datos.altura)
	_verificar(datos.cae_enseguida, "Al chocar deja de subir y empieza a caer.")
	datos = await _saltar_bajo_techo(4, 9999)
	_verificar(datos.techo and absf(datos.altura - (4 * T - 28.0)) < 0.5, "Bajo 4 tiles de alto libre (granero, 1.2.6.2) el salto completo choca con el techo (sube %.2f tiles)." % (datos.altura / T))
	datos = await _saltar_bajo_techo(4, 1)
	_verificar(not datos.techo, "Bajo 4 tiles, un salto corto (1,5 tiles) pasa sin tocar el techo.")

	print("Corrección de esquinas (4 px)")
	datos = await _saltar_bajo_borde(3)
	_verificar(datos.paso and absf(datos.corrimiento) >= 3.0 and absf(datos.corrimiento) <= 5.0, "Rozando el borde 3 px, se corre %.0f px y sigue subiendo." % datos.corrimiento)
	datos = await _saltar_bajo_borde(4)
	_verificar(datos.paso, "Rozando el borde 4 px, también sigue subiendo.")
	datos = await _saltar_bajo_borde(5)
	_verificar(not datos.paso and datos.corrimiento == 0.0, "Rozando el borde 5 px, choca y no se corre.")

	print("Plataformas atravesables")
	await _armar(func(c: TileMapLayer) -> void:
		EscenarioPrueba.pintar(c, Vector2i(-5, 0), Vector2i(20, 1))
		EscenarioPrueba.pintar(c, Vector2i(-2, -3), Vector2i(3, -3), F.PLATAFORMA), Vector2(0, -1))
	var toco_techo := false
	Input.action_press(&"saltar")
	for i in 120:
		await get_tree().physics_frame
		toco_techo = toco_techo or _jugador.is_on_ceiling()
		if i > 10 and _jugador.is_on_floor():
			break
	Input.action_release(&"saltar")
	_verificar(not toco_techo, "Desde abajo se atraviesa sin chocar.")
	_verificar(_jugador.is_on_floor() and absf(_jugador.position.y + 3 * T) < 0.5, "Cae y queda parado encima (y = %.1f)." % _jugador.position.y)
	Input.action_press(&"apuntar_abajo")
	await _tocar(&"saltar")
	await _esperar_suelo()
	Input.action_release(&"apuntar_abajo")
	_verificar(absf(_jugador.position.y + 3 * T) < 0.5, "S + Espacio no la atraviesa hacia abajo: solo salta y vuelve a caer encima.")
	await _mantener(&"apuntar_abajo", 30)
	Input.action_release(&"apuntar_abajo")
	_verificar(absf(_jugador.position.y + 3 * T) < 0.5, "Mantener S tampoco la atraviesa.")
	await _mantener(&"mover_derecha", 60)
	Input.action_release(&"mover_derecha")
	await _esperar_suelo()
	_verificar(absf(_jugador.position.y) < 0.5, "Se baja caminando por el borde.")

	for de_45 in [true, false]:
		var nombre := "45°" if de_45 else "22,5°"
		print("Rampas de %s" % nombre)
		var largo := 4 if de_45 else 8
		await _armar(func(c: TileMapLayer) -> void:
			EscenarioPrueba.pintar(c, Vector2i(-10, 0), Vector2i(60, 1))
			EscenarioPrueba.pintar_rampa(c, Vector2i(5, -1), 4, de_45, 1)
			EscenarioPrueba.pintar(c, Vector2i(5 + largo, -4), Vector2i(5 + largo + 5, -1))
			EscenarioPrueba.pintar_rampa(c, Vector2i(5 + 2 * largo + 5, -1), 4, de_45, -1), Vector2(0, -1))
		var esperado := cos(atan(1.0 if de_45 else 0.5)) * 7.0 * T
		var en_suelo := true
		var vx_rampa := PackedFloat32Array()
		var x_cima := 0.0
		var llego_arriba := false
		var volvio_abajo := false
		Input.action_press(&"mover_derecha")
		for i in 260:
			var x_antes := _jugador.position.x
			await get_tree().physics_frame
			if i > 3:
				en_suelo = en_suelo and _jugador.is_on_floor()
			var y := _jugador.position.y
			if y < -2.0 and y > -4.0 * T + 2.0:
				vx_rampa.append((_jugador.position.x - x_antes) * Engine.physics_ticks_per_second)
			if absf(y + 4 * T) < 0.5:
				llego_arriba = true
			if llego_arriba and absf(y) < 0.5:
				volvio_abajo = true
				break
		Input.action_release(&"mover_derecha")
		var vx_media := 0.0
		for v in vx_rampa:
			vx_media += v
		vx_media /= maxf(vx_rampa.size(), 1.0)
		_verificar(llego_arriba and volvio_abajo, "Sube y baja la loma de 4 tiles.")
		_verificar(en_suelo, "Subiendo y bajando no se despega del suelo en ningún cuadro.")
		_verificar(absf(vx_media - esperado) < esperado * 0.08, "En la rampa avanza a velocidad pareja: %.1f tiles/s en horizontal (7 tiles/s a lo largo de la rampa)." % (vx_media / T))
		# Quieto a mitad de la rampa: no resbala.
		_jugador.position = Vector2((5 + largo / 2.0) * T, -3.0 * T)
		_jugador.velocity = Vector2.ZERO
		await _esperar(5)
		await _esperar_suelo()
		await _esperar(10)
		var quieto_en := _jugador.position
		await _esperar(60)
		_verificar(_jugador.is_on_floor() and _jugador.position.distance_to(quieto_en) < 0.5, "Quieto sobre la rampa, no resbala.")
		await _tocar(&"saltar")
		await _esperar(3)
		_verificar(_jugador.velocity.y < 0.0 and not _jugador.is_on_floor(), "Puede saltar desde la rampa.")
		await _esperar_suelo()

	print("Uniones entre tiles con corrimientos de menos de 1 px")
	# Los redondeos de la física cambian según la computadora: se repite el
	# recorrido de las lomas con el terreno corrido fracciones de píxel.
	var sin_trabarse := 0
	var intentos := 0
	for corrimiento in [Vector2(0.31, 0.17), Vector2(0.73, 0.59), Vector2(0.05, 0.91)]:
		for de_45 in [true, false]:
			intentos += 1
			if await _recorrer_loma(de_45, corrimiento):
				sin_trabarse += 1
	_verificar(sin_trabarse == intentos, "Recorre las lomas de 45° y 22,5° sin trabarse en %d de %d intentos." % [sin_trabarse, intentos])

	print("Resultado: %s" % ("todo OK" if _fallas == 0 else "%d fallas" % _fallas))
	get_tree().quit(0 if _fallas == 0 else 1)


## Reemplaza el escenario: nuevo tilemap pintado por [param pintar] y William
## en [param posicion], ya apoyado en el suelo.
func _armar(pintar: Callable, posicion: Vector2, corrimiento := Vector2.ZERO) -> void:
	for accion in [&"mover_izquierda", &"mover_derecha", &"saltar", &"apuntar_abajo"]:
		Input.action_release(accion)
	if _capa:
		_capa.queue_free()
	if _jugador:
		_jugador.queue_free()
	await get_tree().physics_frame
	_capa = EscenarioPrueba.crear_tilemap(self)
	_capa.position = corrimiento
	pintar.call(_capa)
	_jugador = preload("res://src/gameplay/player/player.tscn").instantiate()
	_jugador.position = posicion + corrimiento
	add_child(_jugador)
	await _esperar(3)
	await _esperar_suelo()
	await _esperar(5)


## Arma una loma de 4 tiles (45° o 22,5°) corrida [param corrimiento] px y la
## recorre hacia la derecha. Devuelve true si sube y baja sin trabarse.
func _recorrer_loma(de_45: bool, corrimiento: Vector2) -> bool:
	var largo := 4 if de_45 else 8
	await _armar(func(c: TileMapLayer) -> void:
		EscenarioPrueba.pintar(c, Vector2i(-10, 0), Vector2i(60, 1))
		EscenarioPrueba.pintar_rampa(c, Vector2i(5, -1), 4, de_45, 1)
		EscenarioPrueba.pintar(c, Vector2i(5 + largo, -4), Vector2i(5 + largo + 5, -1))
		EscenarioPrueba.pintar_rampa(c, Vector2i(5 + 2 * largo + 5, -1), 4, de_45, -1), Vector2(0, -1), corrimiento)
	var llego_arriba := false
	var resultado := false
	Input.action_press(&"mover_derecha")
	for i in 260:
		await get_tree().physics_frame
		var y := _jugador.position.y - corrimiento.y
		if absf(y + 4 * T) < 0.5:
			llego_arriba = true
		if llego_arriba and absf(y) < 0.5:
			resultado = true
			break
	Input.action_release(&"mover_derecha")
	return resultado


## Salta quieto bajo un techo con [param alto_libre] tiles de alto libre,
## manteniendo Espacio [param cuadros] cuadros. Devuelve la altura subida en px,
## si tocó el techo y si empezó a caer justo después de tocarlo.
func _saltar_bajo_techo(alto_libre: int, cuadros: int) -> Dictionary:
	await _armar(func(c: TileMapLayer) -> void:
		EscenarioPrueba.pintar(c, Vector2i(-8, 0), Vector2i(8, 1))
		EscenarioPrueba.pintar(c, Vector2i(-8, -alto_libre - 2), Vector2i(8, -alto_libre - 1)), Vector2(0, -1))
	var y0 := _jugador.position.y
	var y_min := y0
	var techo := false
	var cae_enseguida := false
	Input.action_press(&"saltar")
	for i in 120:
		await get_tree().physics_frame
		if i + 1 == cuadros:
			Input.action_release(&"saltar")
		y_min = minf(y_min, _jugador.position.y)
		if _jugador.is_on_ceiling() and not techo:
			techo = true
			await get_tree().physics_frame
			cae_enseguida = _jugador.velocity.y >= 0.0
		if i > 5 and _jugador.is_on_floor():
			break
	Input.action_release(&"saltar")
	return {"altura": y0 - y_min, "techo": techo, "cae_enseguida": cae_enseguida}


## Salta con la cabeza [param roce] px por debajo del borde izquierdo de un
## techo a 3 tiles. Devuelve si la cabeza pasó por encima del techo y cuánto
## se corrió William de costado.
func _saltar_bajo_borde(roce: int) -> Dictionary:
	var borde := 4 * T
	await _armar(func(c: TileMapLayer) -> void:
		EscenarioPrueba.pintar(c, Vector2i(-8, 0), Vector2i(12, 1))
		EscenarioPrueba.pintar(c, Vector2i(4, -4), Vector2i(10, -4)), Vector2(borde - 6.0 + roce, -1))
	var x0 := _jugador.position.x
	var paso := false
	Input.action_press(&"saltar")
	for i in 90:
		await get_tree().physics_frame
		if _jugador.position.y - 28.0 < -4 * T:
			paso = true
		if i > 5 and _jugador.is_on_floor():
			break
	Input.action_release(&"saltar")
	return {"paso": paso, "corrimiento": _jugador.position.x - x0}


func _esperar(cuadros: int) -> void:
	for i in cuadros:
		await get_tree().physics_frame


func _esperar_suelo() -> void:
	for i in 400:
		if _jugador.is_on_floor() and _jugador.velocity.y >= 0.0:
			return
		await get_tree().physics_frame


func _tocar(accion: StringName) -> void:
	Input.action_press(accion)
	await _esperar(2)
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
