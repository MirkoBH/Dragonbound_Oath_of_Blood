class_name OfertaTienda
extends RefCounted
## Cómo se ofrece un objeto en la tienda en este momento.
##
## La arma el catálogo. La pantalla de la tienda (1.4.1.7) la usa para
## mostrar el objeto y la compra (1.4.9.2) para validar.

## Estado de la oferta según lo ya comprado y el oro disponible.
enum Estado {
	DISPONIBLE,        ## Se puede comprar ahora.
	ORO_INSUFICIENTE,  ## Se muestra, pero el oro no alcanza.
	INVENTARIO_LLENO,  ## Consumible: ya se lleva el máximo.
	NO_DISPONIBLE,     ## Ya se compró el último nivel o el objeto único.
}

var objeto: DefinicionObjeto
var estado: Estado = Estado.DISPONIBLE
## Precio de la próxima compra (-1 si no hay nada más para comprar).
var precio: int = -1
## Para mejoras por niveles: el nivel que se compraría (0 si no aplica).
var nivel_ofrecido: int = 0
## Para mejoras por niveles: el nivel ya comprado.
var nivel_actual: int = 0
## Para consumibles: la cantidad que ya se lleva.
var cantidad_actual: int = 0


func _init(p_objeto: DefinicionObjeto = null) -> void:
	objeto = p_objeto


## Indica si la compra se puede hacer ahora.
func se_puede_comprar() -> bool:
	return estado == Estado.DISPONIBLE
