extends Node
## Prueba automática del gestor de niveles (1.4.2.1).
##
## Desde el editor: abrir src/debug/prueba_gestor_niveles.tscn y presionar F6.
## El resultado aparece en el panel Salida.
## Desde la terminal (carpeta del proyecto):
##   godot --headless res://src/debug/prueba_gestor_niveles.tscn
##
## Recorre la secuencia completa con la escena principal real y las escenas de
## src/levels: orden, carga y descarga, fundido, aparición de William y fin de
## nivel. La partida arranca a mano para poder observar cada paso.

const ESPERADAS: Array[String] = [
	"Nivel01", "Campamento", "Nivel02", "Campamento", "Nivel03",
	"Campamento", "Nivel04", "Campamento", "Nivel05",
]
## Margen sobre la duración del fundido, en segundos: el reloj real incluye la
## carga de la escena y los cuadros de cada arranque y final.
const TOLERANCIA_FUNDIDO := 0.2
## Margen sobre el tiempo calculado para cruzar la pantalla, por la aceleración.
const MARGEN_CAMINATA := 2.0

var _fallas := 0
var _gestor: GestorNiveles
var _raiz_nivel: Node2D
var _raiz_entidades: Node2D
var _fundido: Fundido


func _ready() -> void:
	var principal: Node = preload("res://src/core/main_game/main_game.tscn").instantiate()
	principal.set(&"iniciar_al_arrancar", false)
	add_child(principal)
	_gestor = principal.get_node("Systems/GestorNiveles")
	_raiz_nivel = principal.get_node("World/LevelRoot")
	_raiz_entidades = principal.get_node("World/EntityRoot")
	_fundido = principal.get_node("TransitionLayer/TransitionRoot/Fundido")

	_probar_secuencia()
	await _probar_inicio()
	await _probar_recorrido()
	await _probar_limpieza_de_william()
	await _probar_muerte_sobre_disparador()
	await _probar_fin_y_reintento()
	await _probar_caminata()
	await _probar_escena_invalida()
	await _probar_sin_detecciones_falsas()

	print("Resultado: ", "todo OK" if _fallas == 0 else "%d fallas" % _fallas)
	get_tree().quit(1 if _fallas > 0 else 0)


func _probar_secuencia() -> void:
	print("Secuencia")
	var secuencia := _gestor.secuencia
	_verificar(secuencia.validar().is_empty(), "secuencia_niveles.tres es válida: %s" % secuencia.validar())
	_verificar(secuencia.cantidad_pasos() == 9, "Son 5 niveles y 4 campamentos.")
	var alternan := true
	for paso in secuencia.cantidad_pasos():
		alternan = alternan and secuencia.es_campamento(paso) == (ESPERADAS[paso] == "Campamento")
	_verificar(alternan, "El campamento va entre cada par de niveles.")


func _probar_inicio() -> void:
	print("Inicio de la partida")
	_verificar(_gestor.obtener_paso() == -1, "Sin partida no hay paso actual.")
	_verificar(_raiz_nivel.get_child_count() == 0, "Sin partida no hay escena cargada.")
	_verificar(is_equal_approx(_fundido.color.a, 1.0), "La pantalla arranca en negro.")
	_gestor.avanzar()
	_verificar(_gestor.obtener_paso() == -1, "No se puede avanzar sin una partida.")

	_gestor.iniciar_partida()
	_verificar(_gestor.esta_en_transicion(), "Iniciar abre una transición.")
	_verificar(get_tree().paused, "El juego queda en pausa durante la transición.")
	await _esperar_fin_transicion()
	_verificar(_escena_actual() == "Nivel01", "Empieza en el nivel 1.")
	_verificar(not get_tree().paused, "Al terminar se quita la pausa.")
	_verificar(is_zero_approx(_fundido.color.a), "La pantalla queda clara.")
	_verificar(_fundido.mouse_filter == Control.MOUSE_FILTER_IGNORE, "El fundido deja pasar los clics.")
	_verificar(_raiz_entidades.get_child_count() == 1, "William vive en EntityRoot.")


func _probar_recorrido() -> void:
	print("Recorrido por la salida de cada escena")
	var william := _gestor.jugador
	for paso in range(1, ESPERADAS.size()):
		var anterior := _gestor.obtener_nivel_actual()
		var inicio := Time.get_ticks_msec()
		await _llevar_a_la_salida()
		var duracion := (Time.get_ticks_msec() - inicio) / 1000.0
		await get_tree().process_frame
		_verificar(_escena_actual() == ESPERADAS[paso], "Paso %d: %s." % [paso, ESPERADAS[paso]])
		_verificar(not is_instance_valid(anterior), "Paso %d: se liberó la escena anterior." % paso)
		_verificar(_raiz_nivel.get_child_count() == 1, "Paso %d: hay una sola escena cargada." % paso)
		_verificar(_gestor.jugador == william and _raiz_entidades.get_child_count() == 1, "Paso %d: sigue siendo el mismo William." % paso)
		var esperada := _duracion_transicion()
		_verificar(absf(duracion - esperada) <= TOLERANCIA_FUNDIDO, "Paso %d: la transición dura %.1f s (da %.2f s)." % [paso, esperada, duracion])


func _probar_limpieza_de_william() -> void:
	print("William aparece limpio y con la entrada bloqueada durante el fundido")
	_gestor.iniciar_partida()
	await _esperar_fin_transicion()
	var william := _gestor.jugador
	_verificar(_escena_actual() == "Nivel01", "Iniciar otra vez vuelve al nivel 1.")

	william.global_position = _punto_medio_del_suelo()
	william.velocity = Vector2.RIGHT * william.metricas.obtener_velocidad()
	william.mirando = -1
	william.area_golpes.aplicar_invulnerabilidad(_duracion_transicion() * 2.0)
	william.espada.activar()
	william.morir()
	_gestor.avanzar()
	Input.action_press(&"mover_derecha")
	var en_negro := william.global_position
	await get_tree().create_timer(_fundido.duracion_tramo / 2.0).timeout
	_verificar(_gestor.esta_en_transicion(), "A mitad del oscurecimiento el fundido sigue en curso.")
	_verificar(william.global_position == en_negro, "William no se mueve durante el fundido.")
	_gestor.avanzar()
	_gestor.iniciar_partida()
	await _esperar_fin_transicion()
	Input.action_release(&"mover_derecha")
	_verificar(_gestor.obtener_paso() == 1, "Pedir otro cambio durante el fundido no hace nada.")
	_verificar(william.obtener_estado() == &"Quieto" or william.obtener_estado() == &"Correr", "Sale de Morir.")
	_verificar(william.area_golpes.activa, "Vuelve a recibir golpes.")
	_verificar(not william.area_golpes.esta_invulnerable(), "No arrastra invulnerabilidad.")
	_verificar(not william.espada.esta_activa(), "La espada queda inactiva.")
	_verificar(william.mirando == 1, "Mira a la derecha.")
	await _esperar_hasta(william.is_on_floor, 1.0)
	_verificar(william.is_on_floor(), "Queda apoyado en el suelo de la escena nueva.")
	_verificar(not _gestor.esta_en_transicion(), "La transición terminó.")


func _probar_muerte_sobre_disparador() -> void:
	print("Muerte sobre el disparador")
	var william := _gestor.jugador
	var paso := _gestor.obtener_paso()
	var disparador := _gestor.obtener_nivel_actual().disparador_fin
	william.morir()
	william.global_position = disparador.global_position
	await _esperar_hasta(func() -> bool: return disparador.overlaps_body(william), 1.0)
	_verificar(disparador.overlaps_body(william), "William está sobre el disparador.")
	await get_tree().physics_frame
	_verificar(_gestor.obtener_paso() == paso and not _gestor.esta_en_transicion(), "Si William muere, el disparador no se activa.")


func _probar_fin_y_reintento() -> void:
	print("Fin de la secuencia y reintento")
	while _gestor.obtener_paso() < _gestor.secuencia.cantidad_pasos() - 1:
		_gestor.avanzar()
		await _esperar_fin_transicion()
	var nivel := _gestor.obtener_nivel_actual()
	_verificar(_escena_actual() == "Nivel05", "Se llega al nivel 5.")
	_verificar(nivel.disparador_fin == null, "El nivel 5 no tiene disparador.")
	var terminada := [false]
	_gestor.secuencia_terminada.connect(func() -> void: terminada[0] = true)
	_gestor.avanzar()
	_verificar(terminada[0], "Avanzar desde el nivel 5 avisa el fin de la secuencia.")
	_verificar(_gestor.obtener_nivel_actual() == nivel and not _gestor.esta_en_transicion(), "El nivel 5 queda cargado para 1.4.2.7.")
	_gestor.iniciar_partida()
	await _esperar_fin_transicion()
	_verificar(_escena_actual() == "Nivel01", "Reintentar vuelve al nivel 1.")


func _probar_caminata() -> void:
	print("William camina hasta la salida con las teclas")
	var william := _gestor.jugador
	var distancia := _gestor.obtener_nivel_actual().disparador_fin.global_position.x - william.global_position.x
	Input.action_press(&"mover_derecha")
	await _esperar_hasta(_gestor.esta_en_transicion, distancia / william.metricas.obtener_velocidad() + MARGEN_CAMINATA)
	Input.action_release(&"mover_derecha")
	_verificar(_gestor.esta_en_transicion(), "Llega al disparador corriendo.")
	await _esperar_fin_transicion()
	_verificar(_escena_actual() == "Campamento", "Pasa al campamento.")
	# La salida del nivel y la del campamento están en el mismo lugar: William
	# no debe activarla por venir de ahí (la física retoma la posición vieja).
	await _esperar_segundos_de_fisica(1.0)
	_verificar(_escena_actual() == "Campamento" and not _gestor.esta_en_transicion(), "Sin moverse, sigue en el campamento.")
	_verificar(_gestor.jugador.is_on_floor(), "Queda parado en el punto de aparición.")
	_gestor.iniciar_partida()
	await _esperar_fin_transicion()


func _probar_escena_invalida() -> void:
	print("Escena inexistente (el error en la consola es esperado)")
	var original := _gestor.secuencia
	var rota := SecuenciaNiveles.new()
	rota.niveles = original.niveles
	rota.campamento = "res://src/levels/no_existe.tscn"
	_gestor.secuencia = rota
	_verificar(not rota.validar().is_empty(), "validar() detecta la escena que falta.")
	var nivel := _gestor.obtener_nivel_actual()
	_gestor.avanzar()
	await _esperar_fin_transicion()
	_gestor.secuencia = original
	_verificar(_gestor.obtener_nivel_actual() == nivel and _gestor.obtener_paso() == 0, "Se queda en la escena actual.")
	_verificar(not get_tree().paused and is_zero_approx(_fundido.color.a), "El juego no queda trabado en negro.")


## Ninguna área de la escena nueva debe detectar a William en el lugar donde
## estaba en la escena anterior (monedas, vacíos, compuertas, trampas).
func _probar_sin_detecciones_falsas() -> void:
	print("La escena nueva no detecta a William donde estaba antes")
	var william := _gestor.jugador
	var anterior := _punto_medio_del_suelo()
	william.global_position = anterior
	await _esperar_hasta(func() -> bool: return _posicion_en_fisica().is_equal_approx(anterior), 1.0)
	_verificar(_posicion_en_fisica().is_equal_approx(anterior), "La física tiene a William en el medio de la pantalla.")
	var cuerpos := [0]
	var golpes := [0]
	var al_golpe := func(_golpe: Golpe) -> void: golpes[0] += 1
	william.area_golpes.golpe_recibido.connect(al_golpe)
	var preparar := func(_paso: int, _es_campamento: bool) -> void:
		var escena := _gestor.obtener_nivel_actual()
		_verificar(_posicion_en_fisica().is_equal_approx(william.global_position), "La escena entra con la física ya actualizada.")
		var area := Area2D.new()
		CapasColision.configurar(area, CapasColision.Perfil.DETECTOR_WILLIAM)
		var forma := CollisionShape2D.new()
		forma.shape = (william.get_node(^"CajaColision") as CollisionShape2D).shape
		forma.position = (william.get_node(^"CajaColision") as CollisionShape2D).position
		area.add_child(forma)
		area.position = anterior
		area.body_entered.connect(func(_cuerpo: Node2D) -> void: cuerpos[0] += 1)
		escena.add_child(area)
		EscenarioPrueba.crear_trampa(escena, anterior)
	_gestor.escena_cambiada.connect(preparar, CONNECT_ONE_SHOT)
	_gestor.avanzar()
	await _esperar_fin_transicion()
	await _esperar_segundos_de_fisica(1.0)
	william.area_golpes.golpe_recibido.disconnect(al_golpe)
	_verificar(cuerpos[0] == 0, "Un detector no se activa (avisos: %d)." % cuerpos[0])
	_verificar(golpes[0] == 0, "Una trampa no golpea (golpes: %d)." % golpes[0])


## Lleva a William a la salida y espera a que termine el cambio de escena.
func _llevar_a_la_salida() -> void:
	_gestor.jugador.global_position = _gestor.obtener_nivel_actual().disparador_fin.global_position
	await _esperar_hasta(_gestor.esta_en_transicion, 1.0)
	await _esperar_fin_transicion()


func _esperar_fin_transicion() -> void:
	while _gestor.esta_en_transicion():
		await get_tree().process_frame


## Espera a que [param condicion] se cumpla, con un límite de seguridad para
## que la prueba falle en lugar de colgarse.
func _esperar_hasta(condicion: Callable, limite_segundos: float) -> void:
	var limite := Time.get_ticks_msec() + int(limite_segundos * 1000.0)
	while not condicion.call() and Time.get_ticks_msec() < limite:
		await get_tree().physics_frame


## Para comprobar que algo NO pasa, deja correr la física ese tiempo.
func _esperar_segundos_de_fisica(segundos: float) -> void:
	for _cuadro in int(segundos * Engine.physics_ticks_per_second):
		await get_tree().physics_frame


func _duracion_transicion() -> float:
	return _fundido.duracion_tramo * 2.0


## Un punto del suelo lejos de la salida y del punto de aparición.
func _punto_medio_del_suelo() -> Vector2:
	var escena := _gestor.obtener_nivel_actual()
	return escena.punto_aparicion.global_position + Vector2.RIGHT * get_viewport().get_visible_rect().size.x / 2.0


func _posicion_en_fisica() -> Vector2:
	var estado: Transform2D = PhysicsServer2D.body_get_state(_gestor.jugador.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM)
	return estado.origin


func _escena_actual() -> String:
	var nivel := _gestor.obtener_nivel_actual()
	return String(nivel.name) if nivel != null else ""


func _verificar(condicion: bool, descripcion: String) -> void:
	print("  %s  %s" % ["OK   " if condicion else "FALLA", descripcion])
	if not condicion:
		_fallas += 1
