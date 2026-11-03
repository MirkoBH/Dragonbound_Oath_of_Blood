extends Node2D
## Prueba automática del sistema de daño y resistencias (1.4.5.1).
##
## Desde el editor: abrir src/debug/prueba_danio.tscn y presionar F6.
## El resultado aparece en el panel Salida.
## Desde la terminal (carpeta del proyecto):
##   godot --headless res://src/debug/prueba_danio.tscn
##
## Verifica el redondeo de 1.2.4.1, los ejemplos de cálculo de 1.2.4.2 (8.3) y
## 1.2.4.5, los talismanes, la salud de William y de un enemigo, la
## invulnerabilidad con parpadeo, el golpe sin efecto y el aviso de muerte.

const F := Golpe.TipoDanio.FISICO
const M := Golpe.TipoDanio.MAGICO

var _fallas := 0


func _ready() -> void:
	print("Redondeo (1.2.4.1, sección 2)")
	for caso in [[0.75, 1.0], [0.375, 0.5], [0.25, 0.5], [1.2, 1.0], [1.25, 1.5], [2.25, 2.5], [3.75, 4.0], [0.0, 0.0]]:
		_verificar(is_equal_approx(CalculoDanio.redondear(caso[0]), caso[1]), "%s → %s" % [caso[0], caso[1]])

	print("Daño de William a un enemigo (1.2.4.2, 8.3; 1.2.4.5)")
	var sin_res := Resistencias.new()
	var fis_50 := _res(0.5, 0.0)
	var fis_25 := _res(0.25, 0.0)
	var mag_25 := _res(0.0, 0.25)
	var mag_50 := _res(0.0, 0.5)
	var solo_magia := Resistencias.new()
	solo_magia.solo_danio_magico = true
	_caso(_golpe(1.0, F), sin_res, 1.0, "Espada base sin resistencias: 1 corazón.")
	_caso(_golpe(1.0, F), fis_50, 0.5, "Espada base contra 50 % físico: ½ corazón.")
	_caso(_golpe(1.0, F), fis_25, 1.0, "Espada base contra 25 % físico: 0,75 → 1 corazón.")
	_caso(_golpe(1.0, F, 1.0), fis_50, 1.5, "Espada base + runa contra 50 % físico: ½ + 1 = 1,5.")
	_caso(_golpe(1.0, F, 1.0), solo_magia, 1.0, "Espada base + runa contra enemigo solo dañable con magia: 1.")
	_caso(_golpe(1.0, F), solo_magia, 0.0, "Espada sin runa contra enemigo solo dañable con magia: 0 (sin efecto).")
	_caso(_golpe(2.5, F, 1.0), fis_50, 2.5, "Espada al máximo + runa contra 50 % físico: 2,25 → 2,5 (1.2.4.5, 4.2).")
	_caso(_golpe(1.0, F, 1.0), _res(0.0, 0.5), 1.5, "La runa sí sufre la resistencia mágica: 1 + ½ = 1,5.")
	_caso(_golpe(4.0, M), mag_25, 3.0, "Aliento de 4 contra 25 % mágico: 3 corazones.")
	_caso(_golpe(6.0, M), mag_50, 3.0, "Bola de fuego de 6 contra 50 % mágico: 3 corazones.")
	_caso(_golpe(4.0, M), fis_50, 4.0, "El daño mágico ignora la resistencia física.")
	_verificar(_res(0.3, 0.0).validar().size() == 1 and fis_50.validar().is_empty(), "Las resistencias solo aceptan 0, 25 % o 50 %.")

	print("Daño a William con talismanes (1.2.4.2, sección 6; 1.2.4.5, 4.4)")
	var nada := ProteccionesJugador.new()
	var t_fis := ProteccionesJugador.new()
	t_fis.talisman_fisico = true
	var t_mag := ProteccionesJugador.new()
	t_mag.talisman_magico = true
	_caso_w(_golpe(2.0, F), nada, 2.0, "Sin talismán, un golpe de 2 hace 2.")
	_caso_w(_golpe(0.5, F), t_fis, 0.5, "Talismán físico, golpe de ½: sigue en ½ (nunca anula un golpe).")
	_caso_w(_golpe(1.0, F), t_fis, 1.0, "Talismán físico, golpe de 1: 0,75 → 1 (no reduce los golpes chicos).")
	_caso_w(_golpe(2.0, F), t_fis, 1.5, "Talismán físico, golpe de 2: 1,5.")
	_caso_w(_golpe(3.0, F), t_fis, 2.5, "Talismán físico, golpe de 3: 2,25 → 2,5.")
	_caso_w(_golpe(4.0, F), t_fis, 3.0, "Talismán físico, golpe de 4: 3.")
	_caso_w(_golpe(4.0, M), t_fis, 4.0, "El talismán físico no reduce el daño mágico.")
	_caso_w(_golpe(4.0, M), t_mag, 3.0, "Talismán mágico, golpe mágico de 4: 3.")

	print("Salud")
	var s := Salud.new()
	add_child(s)
	var cambios: Array[float] = []
	var muertes: Array[int] = []
	s.salud_cambiada.connect(func(actual: float, _maxima: float) -> void: cambios.append(actual))
	s.murio.connect(func() -> void: muertes.append(1))
	_verificar(is_equal_approx(s.obtener_actual(), 5.0), "Empieza con 5 corazones (1.2.4.1).")
	s.aplicar_danio(1.5)
	_verificar(is_equal_approx(s.obtener_actual(), 3.5) and cambios == [3.5], "Un golpe de 1,5 deja 3,5 y avisa el cambio.")
	_verificar(is_equal_approx(s.curar(10.0), 1.5) and is_equal_approx(s.obtener_actual(), 5.0), "Curar no pasa del máximo.")
	s.cambiar_maxima(6.0)
	_verificar(is_equal_approx(s.obtener_actual(), 6.0) and is_equal_approx(s.salud_maxima, 6.0), "Mejora de armadura: máximo y actual suben 1 (1.2.4.5, 4.3).")
	s.aplicar_danio(10.0)
	s.aplicar_danio(1.0)
	_verificar(s.obtener_actual() == 0.0 and s.esta_muerto() and muertes.size() == 1, "A 0 corazones avisa la muerte una sola vez, sin bajar de 0.")
	_verificar(s.curar(1.0) == 0.0, "Muerto, ya no se cura.")

	await _probar_enemigo()
	await _probar_william()

	print("Resultado: %s" % ("todo OK" if _fallas == 0 else "%d fallas" % _fallas))
	get_tree().quit(0 if _fallas == 0 else 1)


func _probar_enemigo() -> void:
	print("Enemigo con salud y resistencias (golpes de la espada de William)")
	EscenarioPrueba.crear_terreno(self, Rect2(-400, 0, 800, 32))
	var jugador: Jugador = preload("res://src/gameplay/player/player.tscn").instantiate()
	jugador.position = Vector2(0, -1)
	add_child(jugador)
	var enemigo := Munieco.new()
	enemigo.salud_maxima = 3.0
	enemigo.resistencias = _res(0.5, 0.0)
	enemigo.position = Vector2(20, -1)
	add_child(enemigo)
	var muertes: Array[int] = []
	enemigo.salud.murio.connect(func() -> void: muertes.append(1))
	await _esperar(5)
	for i in 6:
		await _atacar()
	_verificar(is_equal_approx(enemigo.danio_recibido, 3.0) and enemigo.muerto, "Con 50 % de resistencia física, 6 espadazos de ½ lo derrotan (3 corazones).")
	_verificar(muertes.size() == 1, "El enemigo avisa su muerte una sola vez.")
	_verificar(enemigo.collision_layer == 0, "El muñeco muerto deja de bloquear el paso.")
	var x_muerto := enemigo.position.x
	Input.action_press(&"mover_derecha")
	await _esperar(40)
	Input.action_release(&"mover_derecha")
	_verificar(jugador.position.x > enemigo.position.x + 10.0, "William lo atraviesa caminando.")
	_verificar(is_equal_approx(enemigo.position.x, x_muerto), "El muñeco muerto no se mueve cuando William pasa.")
	jugador.position = Vector2(0, -1)
	jugador.mirando = 1
	await _esperar(5)
	await _atacar()
	_verificar(enemigo.golpes_recibidos == 6, "Muerto, ya no recibe golpes.")
	enemigo.queue_free()

	var especial := Munieco.new()
	especial.salud_maxima = 2.0
	especial.resistencias = Resistencias.new()
	especial.resistencias.solo_danio_magico = true
	especial.position = Vector2(20, -1)
	add_child(especial)
	await _esperar(5)
	await _atacar()
	_verificar(especial.golpes_sin_efecto == 1 and is_equal_approx(especial.salud.obtener_actual(), 2.0), "Al enemigo que solo recibe magia, la espada sin runa no lo daña y avisa «sin efecto».")
	jugador.espada.danio_magico_extra = 1.0
	await _atacar()
	_verificar(is_equal_approx(especial.salud.obtener_actual(), 1.0), "Con la runa (1 mágico) sí lo daña.")
	jugador.espada.danio_magico_extra = 0.0
	especial.queue_free()
	jugador.queue_free()
	await _esperar(2)


func _probar_william() -> void:
	print("William recibe golpes")
	var jugador: Jugador = preload("res://src/gameplay/player/player.tscn").instantiate()
	jugador.position = Vector2(0, -1)
	add_child(jugador)
	var muertes: Array[int] = []
	var golpes: Array[int] = []
	jugador.murio.connect(func() -> void: muertes.append(1))
	jugador.golpe_recibido.connect(func(_g: Golpe) -> void: golpes.append(1))
	await _esperar(5)
	var x0 := jugador.position.x
	_verificar(jugador.area_golpes.recibir(_golpe(1.0, F, 0.0, Vector2(30, -14))), "La hurtbox acepta el golpe.")
	await _esperar(1)
	_verificar(is_equal_approx(jugador.salud.obtener_actual(), 4.0) and golpes.size() == 1, "Un golpe de 1 corazón: queda con 4.")
	_verificar(jugador.obtener_estado() == &"RecibirDanio", "Pasa al estado RecibirDanio (retroceso).")
	await _esperar(14)
	_verificar(jugador.position.x < x0, "Retrocede en sentido contrario al golpe.")
	var alfas := {}
	for i in 30:
		await get_tree().physics_frame
		await get_tree().process_frame
		alfas[roundi(jugador.modulate.a * 10.0)] = true
	_verificar(alfas.has(3) and alfas.has(10), "Parpadea durante la invulnerabilidad.")
	_verificar(not jugador.area_golpes.recibir(_golpe(1.0, F)), "Durante 1 s no acepta otro golpe.")
	await get_tree().create_timer(1.1, true, true).timeout
	_verificar(jugador.modulate.a == 1.0 and not jugador.area_golpes.esta_invulnerable(), "Pasado 1 s deja de parpadear.")
	jugador.protecciones.talisman_fisico = true
	jugador.area_golpes.recibir(_golpe(2.0, F))
	await _esperar(1)
	_verificar(is_equal_approx(jugador.salud.obtener_actual(), 2.5), "Con el talismán físico, un golpe de 2 le quita 1,5.")
	jugador.area_golpes.activa = false
	await get_tree().create_timer(1.1, true, true).timeout
	_verificar(not jugador.area_golpes.recibir(_golpe(2.0, F)) and is_equal_approx(jugador.salud.obtener_actual(), 2.5), "Con la hurtbox desactivada (Armadura, 1.4.5.10) no recibe daño.")
	jugador.area_golpes.activa = true
	jugador.area_golpes.recibir(_golpe(3.0, M))
	await _esperar(2)
	_verificar(jugador.salud.esta_muerto() and jugador.obtener_estado() == &"Morir" and muertes.size() == 1, "Un golpe de 3 lo deja en 0: pasa a Morir y avisa la muerte.")
	_verificar(not jugador.area_golpes.recibir(_golpe(1.0, F)), "Muriendo, no acepta más golpes.")
	jugador.queue_free()


## Hace atacar al jugador que haya en escena y espera a que termine el ataque.
func _atacar() -> void:
	Input.action_press(&"atacar")
	await _esperar(2)
	Input.action_release(&"atacar")
	await _esperar(30)


func _golpe(danio: float, tipo: Golpe.TipoDanio, magico_extra: float = 0.0, origen := Vector2(30, 0)) -> Golpe:
	var g := Golpe.new()
	g.danio = danio
	g.tipo = tipo
	g.danio_magico_extra = magico_extra
	g.origen = origen
	return g


func _res(fisica: float, magica: float) -> Resistencias:
	var r := Resistencias.new()
	r.resistencia_fisica = fisica
	r.resistencia_magica = magica
	return r


func _caso(golpe: Golpe, resistencias: Resistencias, esperado: float, texto: String) -> void:
	var obtenido := CalculoDanio.danio_a_enemigo(golpe, resistencias)
	_verificar(is_equal_approx(obtenido, esperado), "%s (da %s)" % [texto, obtenido])


func _caso_w(golpe: Golpe, protecciones: ProteccionesJugador, esperado: float, texto: String) -> void:
	var obtenido := CalculoDanio.danio_a_william(golpe, protecciones)
	_verificar(is_equal_approx(obtenido, esperado), "%s (da %s)" % [texto, obtenido])


func _esperar(cuadros: int) -> void:
	for i in cuadros:
		await get_tree().physics_frame


func _verificar(condicion: bool, descripcion: String) -> void:
	if condicion:
		print("  OK    ", descripcion)
	else:
		_fallas += 1
		print("  FALLA ", descripcion)
