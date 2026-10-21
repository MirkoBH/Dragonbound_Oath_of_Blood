class_name DefinicionObjeto
extends Resource
## Datos de un objeto que vende el Mago en el campamento.
##
## Cada objeto del catálogo de 1.2.4.5 es un archivo .tres con este script.
## Solo guarda datos: qué es, cuánto cuesta, cuántas veces se puede comprar
## y qué efecto tiene. Aplicar el efecto es tarea de 1.4.8.3 y 1.4.9.4.

## Categoría del objeto en la tienda.
enum Categoria {
	EQUIPAMIENTO, ## Se aplica al comprarlo y queda activo de forma permanente.
	CONSUMIBLE,   ## Va al inventario y se usa después (pociones).
}

## Cómo se compra el objeto.
enum TipoCompra {
	POR_NIVELES, ## Mejoras de espada y armadura: niveles en orden.
	UNICA,       ## Runa de fuego y talismanes: una sola vez por partida.
	REPETIBLE,   ## Pociones: stock ilimitado, con un máximo en el inventario.
}

## Qué efecto produce el objeto. El valor va en [member valor_efecto].
enum TipoEfecto {
	DANIO_FISICO_ESPADA,     ## Corazones de daño físico que suma cada nivel.
	DANIO_MAGICO_ESPADA,     ## Corazones de daño mágico que suma la runa.
	SALUD_MAXIMA,            ## Corazones de salud máxima que suma cada nivel.
	RESISTENCIA_FISICA,      ## Fracción del daño físico recibido que se reduce.
	RESISTENCIA_MAGICA,      ## Fracción del daño mágico recibido que se reduce.
	RESTAURA_SALUD,          ## Fracción de la salud máxima que se restaura.
	RESTAURA_ENERGIA,        ## Puntos de energía que se restauran.
}

## Identificador único y estable del objeto (por ejemplo, &"mejora_espada").
@export var id: StringName = &""
## Nombre que se muestra en la tienda.
@export var nombre: String = ""
## Descripción breve para el jugador (sección 5 de 1.2.4.5).
@export_multiline var descripcion: String = ""
## Ícono del objeto. Queda vacío hasta tener los assets de 1.3.3.4.
@export var icono: Texture2D
## Posición en la lista de la tienda (de menor a mayor).
@export var orden: int = 0

@export_group("Compra")
@export var categoria: Categoria = Categoria.EQUIPAMIENTO
@export var tipo_compra: TipoCompra = TipoCompra.UNICA
## Precio en oro. Para POR_NIVELES hay un precio por nivel, en orden;
## para UNICA y REPETIBLE, un solo precio.
@export var precios: PackedInt32Array = PackedInt32Array()
## Para POR_NIVELES: cantidad de niveles. Para UNICA: 1.
## Para REPETIBLE: cantidad máxima en el inventario.
@export var limite: int = 1

@export_group("Efecto")
@export var tipo_efecto: TipoEfecto = TipoEfecto.DANIO_FISICO_ESPADA
## Valor del efecto por compra o por nivel, en la unidad de [enum TipoEfecto].
@export var valor_efecto: float = 0.0


## Devuelve el precio de la compra número [param numero_compra] (empieza en 1).
## Para POR_NIVELES es el precio de ese nivel; para el resto, el precio único.
## Devuelve -1 si ese nivel no existe.
func obtener_precio(numero_compra: int = 1) -> int:
	if tipo_compra == TipoCompra.POR_NIVELES:
		if numero_compra < 1 or numero_compra > precios.size():
			return -1
		return precios[numero_compra - 1]
	if precios.is_empty():
		return -1
	return precios[0]


## Costo total de comprar todos los niveles o la unidad (sin consumibles).
func obtener_costo_total() -> int:
	if tipo_compra == TipoCompra.REPETIBLE:
		return obtener_precio()
	var total := 0
	for precio in precios:
		total += precio
	return total


## Revisa que los datos sean coherentes. Devuelve la lista de errores
## (vacía si todo está bien).
func validar() -> PackedStringArray:
	var errores := PackedStringArray()
	if id == &"":
		errores.append("Falta el id.")
	if nombre.is_empty():
		errores.append("%s: falta el nombre." % id)
	if limite < 1:
		errores.append("%s: el límite debe ser al menos 1." % id)
	if tipo_compra == TipoCompra.POR_NIVELES:
		if precios.size() != limite:
			errores.append("%s: tiene %d niveles y %d precios." % [id, limite, precios.size()])
	elif precios.size() != 1:
		errores.append("%s: debe tener un solo precio." % id)
	if tipo_compra == TipoCompra.UNICA and limite != 1:
		errores.append("%s: un objeto único debe tener límite 1." % id)
	var es_consumible := categoria == Categoria.CONSUMIBLE
	if es_consumible != (tipo_compra == TipoCompra.REPETIBLE):
		errores.append("%s: solo los consumibles se compran de forma repetible." % id)
	for precio in precios:
		if precio <= 0:
			errores.append("%s: hay un precio menor o igual a 0." % id)
	return errores
