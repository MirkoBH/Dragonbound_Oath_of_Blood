extends Node
## Prueba del catálogo de la tienda (1.4.9.1).
##
## Desde el editor: abrir src/debug/prueba_catalogo_tienda.tscn y presionar F6.
## El resultado aparece en el panel Salida.
## Desde la terminal (carpeta del proyecto):
##   godot --headless res://src/debug/prueba_catalogo_tienda.tscn
## Termina con código 0 si todas las verificaciones pasan.

const RUTA_CATALOGO := "res://src/resources/catalogo_tienda.tres"

var _fallas := 0


func _ready() -> void:
	var catalogo := load(RUTA_CATALOGO) as CatalogoTienda
	_verificar(catalogo != null, "El catálogo se carga.")
	if catalogo == null:
		get_tree().quit(1)
		return
	var errores := catalogo.validar()
	_verificar(errores.is_empty(), "El catálogo no tiene errores de datos. %s" % ", ".join(errores))
	_verificar(catalogo.objetos.size() == 7, "Hay 7 objetos.")

	# Inicio de la partida: todo se ofrece, pero sin oro nada se puede comprar.
	var compras := EstadoCompras.new()
	var ofertas := catalogo.obtener_ofertas(compras)
	_verificar(ofertas.size() == 7, "Se ofrecen los 7 objetos desde el inicio.")
	_verificar(ofertas[0].objeto.id == &"mejora_espada", "El orden empieza por la mejora de espada.")
	for oferta in ofertas:
		_verificar(oferta.estado == OfertaTienda.Estado.ORO_INSUFICIENTE, "%s: se muestra sin oro." % oferta.objeto.id)

	# Mejoras por niveles: se ofrecen en orden con el precio de cada nivel.
	compras.oro = 160
	var espada := catalogo.obtener_objeto(&"mejora_espada")
	var oferta := catalogo.obtener_oferta(espada, compras)
	_verificar(oferta.nivel_ofrecido == 1 and oferta.precio == 100 and oferta.se_puede_comprar(), "Espada: se ofrece el nivel 1 a 100.")
	compras.niveles_comprados[&"mejora_espada"] = 1
	oferta = catalogo.obtener_oferta(espada, compras)
	_verificar(oferta.nivel_ofrecido == 2 and oferta.precio == 150 and oferta.se_puede_comprar(), "Espada: con el nivel 1, se ofrece el 2 a 150.")
	compras.niveles_comprados[&"mejora_espada"] = 2
	oferta = catalogo.obtener_oferta(espada, compras)
	_verificar(oferta.precio == 200 and oferta.estado == OfertaTienda.Estado.ORO_INSUFICIENTE, "Espada: el nivel 3 cuesta 200 y no alcanza con 160.")
	compras.niveles_comprados[&"mejora_espada"] = 3
	oferta = catalogo.obtener_oferta(espada, compras)
	_verificar(oferta.estado == OfertaTienda.Estado.NO_DISPONIBLE and oferta.precio == -1, "Espada: tras el nivel 3 queda no disponible.")

	# Objetos únicos.
	compras.oro = 1000
	var runa := catalogo.obtener_objeto(&"runa_fuego")
	_verificar(catalogo.obtener_oferta(runa, compras).se_puede_comprar(), "Runa: se puede comprar con oro suficiente.")
	compras.unicos_comprados[&"runa_fuego"] = true
	_verificar(catalogo.obtener_oferta(runa, compras).estado == OfertaTienda.Estado.NO_DISPONIBLE, "Runa: después de comprarla queda no disponible.")

	# Consumibles: máximo 3 en el inventario.
	var pocion := catalogo.obtener_objeto(&"pocion_curacion")
	compras.consumibles[&"pocion_curacion"] = 2
	_verificar(catalogo.obtener_oferta(pocion, compras).se_puede_comprar(), "Poción: con 2 se puede comprar otra.")
	compras.consumibles[&"pocion_curacion"] = 3
	_verificar(catalogo.obtener_oferta(pocion, compras).estado == OfertaTienda.Estado.INVENTARIO_LLENO, "Poción: con 3 el inventario está lleno.")

	# Costos de referencia de 1.2.4.5 (sección 6.1): equipamiento completo = 1.850.
	var total := 0
	for objeto in catalogo.objetos:
		if objeto.categoria == DefinicionObjeto.Categoria.EQUIPAMIENTO:
			total += objeto.obtener_costo_total()
	_verificar(total == 1850, "El equipamiento completo cuesta 1.850 de oro (da %d)." % total)

	print("Resultado: %s" % ("todo OK" if _fallas == 0 else "%d fallas" % _fallas))
	get_tree().quit(0 if _fallas == 0 else 1)


func _verificar(condicion: bool, descripcion: String) -> void:
	if condicion:
		print("  OK    ", descripcion)
	else:
		_fallas += 1
		print("  FALLA ", descripcion)
