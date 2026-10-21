extends Node2D
## Prueba de las capas y máscaras de colisión (1.4.4.1).
##
## Desde el editor: abrir src/debug/prueba_capas_colision.tscn y presionar F6.
## El resultado aparece en el panel Salida.
## Desde la terminal (carpeta del proyecto):
##   godot --headless res://src/debug/prueba_capas_colision.tscn

const P := CapasColision.Perfil

var _fallas := 0
var _avisos_superposicion := 0


func _ready() -> void:
	print("Nombres de las capas")
	_probar_nombres()
	print("Qué detecta cada perfil")
	_probar_matriz()
	print("Simulación física")
	await _probar_bloqueos()
	await _probar_golpes()
	await _probar_superposicion()
	print("Tabla de perfiles (capa y máscara de cada tipo de objeto)")
	print(CapasColision.describir())
	print("Resultado: %s" % ("todo OK" if _fallas == 0 else "%d fallas" % _fallas))
	get_tree().quit(0 if _fallas == 0 else 1)


func _probar_nombres() -> void:
	for i in CapasColision.NOMBRES.size():
		var clave := "layer_names/2d_physics/layer_%d" % (i + 1)
		var nombre: String = ProjectSettings.get_setting(clave, "")
		_verificar(nombre == CapasColision.NOMBRES[i], "Capa %d: «%s»." % [i + 1, CapasColision.NOMBRES[i]])


## true si el perfil [param a] detecta al perfil [param b].
func _detecta(a: CapasColision.Perfil, b: CapasColision.Perfil) -> bool:
	return CapasColision.mascara(a) & CapasColision.capa(b) != 0


func _probar_matriz() -> void:
	_verificar(_detecta(P.CUERPO_WILLIAM, P.TERRENO) and _detecta(P.CUERPO_WILLIAM, P.PLATAFORMA), "William choca con el terreno y las plataformas.")
	_verificar(_detecta(P.CUERPO_WILLIAM, P.CUERPO_ENEMIGO) and _detecta(P.CUERPO_ENEMIGO, P.CUERPO_WILLIAM), "William y los enemigos se bloquean.")
	_verificar(not _detecta(P.CUERPO_ENEMIGO, P.CUERPO_ENEMIGO), "Los enemigos se atraviesan entre sí.")
	_verificar(_detecta(P.DETECTOR_SUPERPOSICION, P.CUERPO_ENEMIGO), "El detector de superposición ve a los enemigos.")
	_verificar(_detecta(P.RECIBE_GOLPES_WILLIAM, P.ATAQUE_ENEMIGO) and _detecta(P.RECIBE_GOLPES_WILLIAM, P.PROYECTIL_ENEMIGO), "William recibe los ataques enemigos.")
	_verificar(not _detecta(P.RECIBE_GOLPES_WILLIAM, P.ATAQUE_WILLIAM) and not _detecta(P.RECIBE_GOLPES_WILLIAM, P.PROYECTIL_WILLIAM), "William no recibe sus propios ataques.")
	_verificar(not _detecta(P.RECIBE_GOLPES_WILLIAM, P.CUERPO_ENEMIGO), "Tocar un enemigo no hace daño.")
	_verificar(_detecta(P.RECIBE_GOLPES_ENEMIGO, P.ATAQUE_WILLIAM) and _detecta(P.RECIBE_GOLPES_ENEMIGO, P.PROYECTIL_WILLIAM), "Los enemigos reciben los ataques de William.")
	_verificar(not _detecta(P.RECIBE_GOLPES_ENEMIGO, P.ATAQUE_ENEMIGO), "Los enemigos no se dañan entre sí.")
	_verificar(_detecta(P.RECIBE_GOLPES_WILLIAM, P.TRAMPA) and not _detecta(P.RECIBE_GOLPES_ENEMIGO, P.TRAMPA), "Las trampas dañan a William y no a los enemigos.")
	_verificar(_detecta(P.ZONA_VACIO, P.CUERPO_WILLIAM) and not _detecta(P.ZONA_VACIO, P.RECIBE_GOLPES_WILLIAM), "El vacío actúa sobre el cuerpo: la Armadura no lo evita.")
	_verificar(_detecta(P.PROYECTIL_WILLIAM, P.TERRENO) and not _detecta(P.PROYECTIL_WILLIAM, P.PLATAFORMA), "Los proyectiles chocan con el terreno y atraviesan las plataformas.")
	_verificar(_detecta(P.RECOLECTABLE, P.CUERPO_WILLIAM) and not _detecta(P.RECOLECTABLE, P.CUERPO_ENEMIGO), "Solo William junta monedas y escamas.")
	_verificar(_detecta(P.INTERACTUABLE, P.CUERPO_WILLIAM) and not _detecta(P.INTERACTUABLE, P.CUERPO_ENEMIGO), "Solo William activa los interactuables.")
	_verificar(_detecta(P.DETECTOR_WILLIAM, P.CUERPO_WILLIAM) and CapasColision.capa(P.DETECTOR_WILLIAM) == 0, "Los enemigos ven a William y su detector no ocupa capa.")


func _cuerpo(perfil: CapasColision.Perfil, posicion: Vector2) -> CharacterBody2D:
	var cuerpo := CharacterBody2D.new()
	CapasColision.configurar(cuerpo, perfil)
	cuerpo.position = posicion
	cuerpo.add_child(_forma(Vector2(12, 24)))
	add_child(cuerpo)
	return cuerpo


func _area(perfil: CapasColision.Perfil, posicion: Vector2) -> Area2D:
	var area := Area2D.new()
	CapasColision.configurar(area, perfil)
	area.position = posicion
	area.add_child(_forma(Vector2(16, 16)))
	add_child(area)
	return area


func _forma(tamanio: Vector2) -> CollisionShape2D:
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = tamanio
	forma.shape = rect
	return forma


func _esperar_fisica(cuadros: int = 2) -> void:
	for i in cuadros:
		await get_tree().physics_frame


func _probar_bloqueos() -> void:
	var william := _cuerpo(P.CUERPO_WILLIAM, Vector2(0, 0))
	var enemigo := _cuerpo(P.CUERPO_ENEMIGO, Vector2(40, 0))
	var otro_enemigo := _cuerpo(P.CUERPO_ENEMIGO, Vector2(200, 0))
	await _esperar_fisica()
	var choque := william.move_and_collide(Vector2(60, 0))
	_verificar(choque != null and choque.get_collider() == enemigo, "William se frena contra un enemigo.")
	var choque_enemigos := otro_enemigo.move_and_collide(Vector2(-200, 0), true)
	_verificar(choque_enemigos == null or choque_enemigos.get_collider() != enemigo, "Un enemigo atraviesa a otro.")
	for nodo in [william, enemigo, otro_enemigo]:
		nodo.queue_free()
	await _esperar_fisica()


func _probar_golpes() -> void:
	var recibe := _area(P.RECIBE_GOLPES_WILLIAM, Vector2(400, 0))
	var espada := _area(P.ATAQUE_WILLIAM, Vector2(400, 0))
	var golpe_enemigo := _area(P.ATAQUE_ENEMIGO, Vector2(400, 0))
	await _esperar_fisica(3)
	var areas := recibe.get_overlapping_areas()
	_verificar(golpe_enemigo in areas, "El área de William detecta un golpe enemigo superpuesto.")
	_verificar(not espada in areas, "El área de William ignora su propia espada superpuesta.")
	for nodo in [recibe, espada, golpe_enemigo]:
		nodo.queue_free()
	await _esperar_fisica()


func _probar_superposicion() -> void:
	var a := _cuerpo(P.CUERPO_ENEMIGO, Vector2(800, 0))
	var b := _cuerpo(P.CUERPO_ENEMIGO, Vector2(805, 0))
	var detector := DetectorSuperposicion.new()
	detector.umbral_segundos = 0.5
	detector.add_child(_forma(Vector2(12, 24)))
	a.add_child(detector)
	detector.superposicion_prolongada.connect(func(_otro: Node2D) -> void: _avisos_superposicion += 1)
	await _esperar_fisica(10)
	_verificar(_avisos_superposicion == 0 and detector.obtener_tiempo_superpuesto(b) > 0.0, "Al principio solo cuenta el tiempo superpuesto.")
	await _esperar_fisica(30)
	_verificar(_avisos_superposicion >= 1, "Tras superar el umbral, avisa la superposición prolongada.")
	_verificar(detector.obtener_direccion_separacion(b) == -1, "Indica hacia qué lado separarse.")
	b.position = Vector2(1000, 0)
	await _esperar_fisica(5)
	_verificar(detector.obtener_tiempo_superpuesto(b) == 0.0, "Al separarse, el contador vuelve a 0.")
	a.queue_free()
	b.queue_free()


func _verificar(condicion: bool, descripcion: String) -> void:
	if condicion:
		print("  OK    ", descripcion)
	else:
		_fallas += 1
		print("  FALLA ", descripcion)
