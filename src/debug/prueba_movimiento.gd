extends Node2D
## Prueba automática del movimiento horizontal y el salto de William (1.4.3.2).
##
## Desde el editor: abrir src/debug/prueba_movimiento.tscn y presionar F6.
## El resultado aparece en el panel Salida.
## Desde la terminal (carpeta del proyecto):
##   godot --headless res://src/debug/prueba_movimiento.tscn
##
## Verifica las métricas de 1.2.6.1 y las tolerancias de 1.2.3.3 simulando
## las teclas del Mapa de entrada, cuadro por cuadro.

## Tolerancia en tiempos: un cuadro de física (1/60 s) más un margen.
const TOLERANCIA_TIEMPO := 0.025
## Las teclas simuladas con Input.action_press llegan al personaje en el
## cuadro siguiente: los tiempos medidos descuentan ese cuadro de demora.
const CUADROS_DEMORA := 1

var _fallas := 0
var _jugador: Jugador
var _m: MetricasJugador


func _ready() -> void:
	# Piso largo y, a la derecha, una plataforma elevada con borde para el margen.
	EscenarioPrueba.crear_terreno(self, Rect2(-3000, 0, 6000, 32))
	EscenarioPrueba.crear_terreno(self, Rect2(1000, -160, 400, 16))
	_jugador = preload("res://src/gameplay/player/player.tscn").instantiate()
	_jugador.position = Vector2(0, -1)
	add_child(_jugador)
	_m = _jugador.metricas
	await _esperar(5)

	print("Métricas (src/resources/metricas_william.tres)")
	_verificar(_m.resource_path == "res://src/resources/metricas_william.tres", "William usa metricas_william.tres.")
	_verificar(is_equal_approx(_m.obtener_velocidad(), 112.0), "Velocidad: 7 tiles/s = 112 px/s.")
	_verificar(is_equal_approx(_m.obtener_tiempo_hasta_cima(), 5.0 / 7.0 / 2.0), "Sube durante la mitad del vuelo del salto de 5 tiles.")

	print("Correr")
	var t := await _medir_hasta(&"mover_derecha", func() -> bool: return _jugador.velocity.x >= _m.obtener_velocidad())
	_verificar(absf(t - _m.tiempo_aceleracion) <= TOLERANCIA_TIEMPO, "Llega a la velocidad máxima en unos 0,1 s (da %.3f s)." % t)
	await _esperar(20)
	_verificar(is_equal_approx(_jugador.velocity.x, _m.obtener_velocidad()), "No pasa de 7 tiles/s.")
	Input.action_release(&"mover_derecha")
	t = await _medir_hasta(&"", func() -> bool: return _jugador.velocity.x == 0.0)
	_verificar(absf(t - _m.tiempo_frenado) <= TOLERANCIA_TIEMPO, "Al soltar frena en unos 0,05 s (da %.3f s)." % t)
	_verificar(_jugador.obtener_estado() == &"Quieto", "Al frenar queda en Quieto.")

	print("Cambio de dirección")
	await _mantener(&"mover_derecha", 20)
	Input.action_release(&"mover_derecha")
	var t_cero := -1.0
	var tiempo := -CUADROS_DEMORA * _paso()
	Input.action_press(&"mover_izquierda")
	while tiempo < 1.0:
		await get_tree().physics_frame
		tiempo += _paso()
		if t_cero < 0.0 and _jugador.velocity.x <= 0.0:
			t_cero = tiempo
		if _jugador.velocity.x <= -_m.obtener_velocidad():
			break
	Input.action_release(&"mover_izquierda")
	_verificar(absf(t_cero - _m.tiempo_frenado) <= TOLERANCIA_TIEMPO, "Al dar la vuelta frena en unos 0,05 s (da %.3f s)." % t_cero)
	_verificar(absf(tiempo - _m.tiempo_frenado - _m.tiempo_aceleracion) <= TOLERANCIA_TIEMPO * 2.0, "Corre hacia el otro lado en unos 0,15 s (da %.3f s)." % tiempo)
	_verificar(_jugador.mirando == -1, "Mira hacia el nuevo lado.")
	await _esperar(10)

	print("Salto de altura variable")
	var datos := await _saltar(9999)
	_verificar(absf(datos.altura - _m.altura_salto_max) < 0.15, "Manteniendo Espacio sube 3,5 tiles (da %.2f)." % datos.altura)
	_verificar(datos.subida > 0.0 and absf(datos.bajada - datos.subida) < 0.04, "Caída simétrica: baja en el mismo tiempo que sube (%.3f / %.3f s)." % [datos.subida, datos.bajada])
	datos = await _saltar(1)
	_verificar(absf(datos.altura - _m.altura_salto_min) < 0.15, "Con un toque sube 1,5 tiles (da %.2f)." % datos.altura)
	datos = await _saltar(10)
	_verificar(datos.altura > _m.altura_salto_min + 0.3 and datos.altura < _m.altura_salto_max - 0.3, "Soltando a mitad de camino queda entre ambas (da %.2f)." % datos.altura)

	print("Salto con carrera")
	await _mantener(&"mover_izquierda", 20)
	datos = await _saltar(9999)
	Input.action_release(&"mover_izquierda")
	_verificar(absf(datos.distancia - _m.distancia_salto_max) < 0.3, "Corriendo cubre unos 5 tiles en el aire (da %.2f)." % datos.distancia)
	await _esperar(10)

	print("Control en el aire")
	Input.action_press(&"saltar")
	await _esperar(2)
	await _mantener(&"mover_derecha", 6)
	var vx := _jugador.velocity.x
	_verificar(not _jugador.is_on_floor() and is_equal_approx(vx, _m.obtener_velocidad()), "En el aire acelera igual que en el suelo (control completo).")
	Input.action_release(&"mover_derecha")
	await _esperar(4)
	_verificar(_jugador.velocity.x == 0.0 and not _jugador.is_on_floor(), "En el aire también frena al soltar.")
	Input.action_release(&"saltar")
	await _esperar_suelo()

	print("Velocidad máxima de caída")
	_jugador.position = Vector2(-1500, -2000)
	_jugador.velocity = Vector2.ZERO
	var maxima := 0.0
	for i in 240:
		await get_tree().physics_frame
		maxima = maxf(maxima, _jugador.velocity.y)
		if _jugador.is_on_floor():
			break
	_verificar(is_equal_approx(maxima, _m.obtener_velocidad_max_caida()), "La caída se limita a 15 tiles/s (da %.1f tiles/s)." % (maxima / Jugador.TILE))
	await _esperar(10)

	print("Margen al borde (0,1 s)")
	_verificar(await _salir_del_borde_y_saltar(0.05), "Saltando 0,05 s después de salir del borde, salta.")
	_verificar(not await _salir_del_borde_y_saltar(0.2), "Saltando 0,2 s después de salir del borde, no salta.")
	_verificar(await _salir_del_borde_y_saltar(-1.0, true), "Después de un salto, el margen no da un segundo salto en el aire.")

	print("Memoria del salto (0,1 s)")
	_verificar(await _pedir_salto_antes_de_aterrizar(0.05), "Espacio 0,05 s antes de aterrizar: salta al tocar el piso.")
	_verificar(not await _pedir_salto_antes_de_aterrizar(0.2), "Espacio 0,2 s antes de aterrizar: no salta.")

	print("Resultado: %s" % ("todo OK" if _fallas == 0 else "%d fallas" % _fallas))
	get_tree().quit(0 if _fallas == 0 else 1)


## Salta manteniendo Espacio [param cuadros] cuadros y mide el salto hasta
## aterrizar. Devuelve altura y distancia en tiles, y tiempos de subida y bajada.
func _saltar(cuadros: int) -> Dictionary:
	await _esperar_suelo()
	var y0 := _jugador.position.y
	var x0 := _jugador.position.x
	var y_min := y0
	var subida := 0.0
	var bajada := 0.0
	var tiempo_total := 0.0
	Input.action_press(&"saltar")
	var mantenido := 0
	for i in 400:
		await get_tree().physics_frame
		mantenido += 1
		if mantenido == cuadros:
			Input.action_release(&"saltar")
		tiempo_total += _paso()
		if _jugador.position.y < y_min:
			y_min = _jugador.position.y
			subida = tiempo_total
		if _jugador.is_on_floor() and i > 2:
			break
	Input.action_release(&"saltar")
	bajada = tiempo_total - subida
	var distancia := absf(_jugador.position.x - x0) / Jugador.TILE
	await _esperar(6)
	return {
		"altura": (y0 - y_min) / Jugador.TILE,
		"distancia": distancia,
		"subida": subida,
		"bajada": bajada,
	}


## Camina hacia la derecha por la plataforma elevada, sale del borde y pide el
## salto [param retraso] segundos después de salir. Devuelve si saltó.
## Con [param despues_de_saltar], sale del borde saltando y pide otro salto
## enseguida; devuelve true si ese segundo salto NO ocurre.
func _salir_del_borde_y_saltar(retraso: float, despues_de_saltar := false) -> bool:
	_jugador.position = Vector2(1300, -162)
	_jugador.velocity = Vector2.ZERO
	await _esperar(3)
	await _esperar_suelo()
	Input.action_press(&"mover_derecha")
	if despues_de_saltar:
		while _jugador.position.x < 1390:
			await get_tree().physics_frame
		await _tocar(&"saltar")
		while _jugador.velocity.y < 0.0:
			await get_tree().physics_frame
		await _esperar(2)
		var vy_antes := _jugador.velocity.y
		await _tocar(&"saltar")
		Input.action_release(&"mover_derecha")
		var no_salto := _jugador.velocity.y >= vy_antes
		await _esperar_suelo()
		return no_salto
	while _jugador.is_on_floor():
		await get_tree().physics_frame
	Input.action_release(&"mover_derecha")
	var tiempo := _paso()
	while tiempo < retraso:
		await get_tree().physics_frame
		tiempo += _paso()
	Input.action_press(&"saltar")
	await _esperar(1 + CUADROS_DEMORA)
	var salto := _jugador.obtener_estado() == &"Saltar"
	Input.action_release(&"saltar")
	await _esperar_suelo()
	return salto


## Deja caer a William desde arriba y presiona Espacio [param anticipacion]
## segundos antes de que toque el piso. Devuelve si saltó al aterrizar.
func _pedir_salto_antes_de_aterrizar(anticipacion: float) -> bool:
	await _esperar_suelo()
	_jugador.position.x = -800.0
	_jugador.position.y = -400.0
	_jugador.velocity = Vector2.ZERO
	await get_tree().physics_frame
	# Calcula cuándo va a tocar el piso siguiendo la misma física.
	while true:
		var vy := _jugador.velocity.y
		var y := _jugador.position.y
		var t := 0.0
		while y < -1.0:
			vy = minf(vy + _jugador.obtener_gravedad() * _paso(), _m.obtener_velocidad_max_caida())
			y += vy * _paso()
			t += _paso()
		if t <= anticipacion + 0.001:
			break
		await get_tree().physics_frame
	Input.action_press(&"saltar")
	await get_tree().physics_frame
	Input.action_release(&"saltar")
	var salto := false
	for i in 30:
		await get_tree().physics_frame
		if _jugador.obtener_estado() == &"Saltar":
			salto = true
			break
	await _esperar_suelo()
	return salto


## Mantiene [param accion] (o nada, si está vacía) hasta que se cumpla
## [param condicion]. Devuelve el tiempo que tardó.
func _medir_hasta(accion: StringName, condicion: Callable) -> float:
	if accion != &"":
		Input.action_press(accion)
	var tiempo := 0.0
	while not condicion.call() and tiempo < 2.0:
		await get_tree().physics_frame
		tiempo += _paso()
	return tiempo - CUADROS_DEMORA * _paso()


func _paso() -> float:
	return 1.0 / Engine.physics_ticks_per_second


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
