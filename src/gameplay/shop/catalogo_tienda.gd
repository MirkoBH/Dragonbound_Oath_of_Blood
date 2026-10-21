class_name CatalogoTienda
extends Resource
## Catálogo de la tienda del Mago (1.2.4.5) y lógica de qué se ofrece.
##
## Reglas que aplica:
## - Todo el catálogo está a la venta desde el primer campamento y se muestra
##   aunque el oro no alcance.
## - Las mejoras por niveles se ofrecen en orden; tras el último nivel quedan
##   como no disponibles.
## - Los objetos únicos se compran una sola vez.
## - Los consumibles tienen stock ilimitado, con un máximo en el inventario.
## - Los precios son fijos durante toda la partida.

## Objetos a la venta. Cada uno es un DefinicionObjeto (.tres).
@export var objetos: Array[DefinicionObjeto] = []


## Busca un objeto por su id. Devuelve null si no existe.
func obtener_objeto(id: StringName) -> DefinicionObjeto:
	for objeto in objetos:
		if objeto.id == id:
			return objeto
	return null


## Devuelve los objetos ordenados según su campo [member DefinicionObjeto.orden].
func obtener_objetos_ordenados() -> Array[DefinicionObjeto]:
	var lista := objetos.duplicate()
	lista.sort_custom(func(a: DefinicionObjeto, b: DefinicionObjeto) -> bool: return a.orden < b.orden)
	return lista


## Arma la oferta de cada objeto del catálogo, en orden, según [param compras].
func obtener_ofertas(compras: EstadoCompras) -> Array[OfertaTienda]:
	var ofertas: Array[OfertaTienda] = []
	for objeto in obtener_objetos_ordenados():
		ofertas.append(obtener_oferta(objeto, compras))
	return ofertas


## Arma la oferta de un objeto según lo ya comprado y el oro disponible.
func obtener_oferta(objeto: DefinicionObjeto, compras: EstadoCompras) -> OfertaTienda:
	var oferta := OfertaTienda.new(objeto)
	match objeto.tipo_compra:
		DefinicionObjeto.TipoCompra.POR_NIVELES:
			oferta.nivel_actual = mini(compras.obtener_nivel(objeto.id), objeto.limite)
			if oferta.nivel_actual >= objeto.limite:
				oferta.estado = OfertaTienda.Estado.NO_DISPONIBLE
				return oferta
			oferta.nivel_ofrecido = oferta.nivel_actual + 1
			oferta.precio = objeto.obtener_precio(oferta.nivel_ofrecido)
		DefinicionObjeto.TipoCompra.UNICA:
			if compras.tiene_unico(objeto.id):
				oferta.estado = OfertaTienda.Estado.NO_DISPONIBLE
				return oferta
			oferta.precio = objeto.obtener_precio()
		DefinicionObjeto.TipoCompra.REPETIBLE:
			oferta.cantidad_actual = compras.obtener_cantidad(objeto.id)
			oferta.precio = objeto.obtener_precio()
			if oferta.cantidad_actual >= objeto.limite:
				oferta.estado = OfertaTienda.Estado.INVENTARIO_LLENO
				return oferta
	if compras.oro < oferta.precio:
		oferta.estado = OfertaTienda.Estado.ORO_INSUFICIENTE
	return oferta


## Revisa el catálogo completo: datos de cada objeto e ids repetidos.
## Devuelve la lista de errores (vacía si todo está bien).
func validar() -> PackedStringArray:
	var errores := PackedStringArray()
	var ids: Dictionary[StringName, bool] = {}
	for objeto in objetos:
		if objeto == null:
			errores.append("Hay un objeto vacío en el catálogo.")
			continue
		errores.append_array(objeto.validar())
		if ids.has(objeto.id):
			errores.append("Id repetido: %s." % objeto.id)
		ids[objeto.id] = true
	return errores
