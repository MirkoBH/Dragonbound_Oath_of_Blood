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
## Tolerancia al medir el fundido (1 s en total: NV-03).
const TOLERANCIA_FUNDIDO := 0.2

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
		_verificar(absf(duracion - 1.0) <= TOLERANCIA_FUNDIDO, "Paso %d: el fundido dura unos 1 s (da %.2f s)." % [paso, duracion])


func _probar_limpieza_de_william() -> void:
	print("William aparece limpio y con la entrada bloqueada durante el fundido")
	_gestor.iniciar_partida()
	await _esperar_fin_transicion()
	var william := _gestor.jugador
	_verificar(_escena_actual() == "Nivel01", "Iniciar otra vez vuelve al nivel 1.")

	william.global_position = Vector2(300, 318)
	william.velocity = Vector2(100, -50)
	william.mirando = -1
	william.area_golpes.aplicar_invulnerabilidad(5.0)
	william.espada.activar()
	william.morir()
	_gestor.avanzar()
	Input.action_press(&"mover_derecha")
	var en_negro := william.global_position
	await get_tree().create_timer(0.3).timeout
	_verificar(_gestor.esta_en_transicion(), "A los 0,3 s el fundido sigue en curso.")
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
	await _esperar_cuadros(5)
	_verificar(william.is_on_floor(), "Queda apoyado en el suelo de la escena nueva.")
	_verificar(not _gestor.esta_en_transicion(), "La transición terminó.")


func _probar_muerte_sobre_disparador() -> void:
	print("Muerte sobre el disparador")
	var william := _gestor.jugador
	var paso := _gestor.obtener_paso()
	william.morir()
	william.global_position = _gestor.obtener_nivel_actual().disparador_fin.global_position
	await _esperar_cuadros(10)
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
	Input.action_press(&"mover_derecha")
	var cuadros := 0
	while _gestor.obtener_paso() == 0 and not _gestor.esta_en_transicion() and cuadros < 600:
		await get_tree().physics_frame
		cuadros += 1
	Input.action_release(&"mover_derecha")
	_verificar(_gestor.esta_en_transicion(), "Llega al disparador corriendo (%.1f s)." % (cuadros / 60.0))
	await _esperar_fin_transicion()
	_verificar(_escena_actual() == "Campamento", "Pasa al campamento.")
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


## Lleva a William a la salida y espera a que termine el cambio de escena.
func _llevar_a_la_salida() -> void:
	_gestor.jugador.global_position = _gestor.obtener_nivel_actual().disparador_fin.global_position
	var cuadros := 0
	while not _gestor.esta_en_transicion() and cuadros < 30:
		await get_tree().physics_frame
		cuadros += 1
	await _esperar_fin_transicion()


func _esperar_fin_transicion() -> void:
	while _gestor.esta_en_transicion():
		await get_tree().process_frame


func _esperar_cuadros(cuadros: int) -> void:
	for _i in cuadros:
		await get_tree().physics_frame


func _escena_actual() -> String:
	var nivel := _gestor.obtener_nivel_actual()
	return String(nivel.name) if nivel != null else ""


func _verificar(condicion: bool, descripcion: String) -> void:
	print("  %s  %s" % ["OK   " if condicion else "FALLA", descripcion])
	if not condicion:
		_fallas += 1
