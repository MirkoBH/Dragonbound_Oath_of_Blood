class_name CapasColision
extends Object
## Capas y máscaras de colisión de todo el juego (1.4.4.1).
##
## La capa indica «qué soy» y la máscara «qué detecto». Los nombres de las
## capas están cargados en Configuración del proyecto > Nombres de capas >
## Física 2D, así que en el Inspector aparecen por nombre.
##
## Uso desde el código, en lugar de números sueltos:
##   CapasColision.configurar(self, CapasColision.Perfil.CUERPO_ENEMIGO)
##
## Reglas de diseño:
## - William y los enemigos se bloquean entre sí, pero el contacto no hace daño.
## - Los enemigos se atraviesan entre sí; DetectorSuperposicion avisa cuando
##   quedan superpuestos demasiado tiempo.
## - Los ataques de William y los enemigos van en capas distintas: no hay
##   fuego amigo.
## - El cuerpo (choca con el terreno) está separado del área que recibe golpes,
##   para volver invulnerable a alguien sin que atraviese el piso.
## - Los proyectiles se destruyen contra el terreno, pero atraviesan las
##   plataformas atravesables.
## - La zona de caída al vacío detecta el cuerpo, no el área de golpes: la
##   Armadura no evita las caídas (1.2.4.3).

## Número de cada capa (1 a 11), igual que en la configuración del proyecto.
const TERRENO := 1
const PLATAFORMAS := 2
const CUERPO_WILLIAM := 3
const CUERPO_ENEMIGOS := 4
const RECIBE_GOLPES_WILLIAM := 5
const RECIBE_GOLPES_ENEMIGOS := 6
const ATAQUES_WILLIAM := 7
const ATAQUES_ENEMIGOS := 8
const TRAMPAS := 9
const RECOLECTABLES := 10
const INTERACTUABLES := 11

## Valor de bit de cada capa, para armar capas y máscaras.
const BIT_TERRENO := 1 << (TERRENO - 1)
const BIT_PLATAFORMAS := 1 << (PLATAFORMAS - 1)
const BIT_CUERPO_WILLIAM := 1 << (CUERPO_WILLIAM - 1)
const BIT_CUERPO_ENEMIGOS := 1 << (CUERPO_ENEMIGOS - 1)
const BIT_RECIBE_GOLPES_WILLIAM := 1 << (RECIBE_GOLPES_WILLIAM - 1)
const BIT_RECIBE_GOLPES_ENEMIGOS := 1 << (RECIBE_GOLPES_ENEMIGOS - 1)
const BIT_ATAQUES_WILLIAM := 1 << (ATAQUES_WILLIAM - 1)
const BIT_ATAQUES_ENEMIGOS := 1 << (ATAQUES_ENEMIGOS - 1)
const BIT_TRAMPAS := 1 << (TRAMPAS - 1)
const BIT_RECOLECTABLES := 1 << (RECOLECTABLES - 1)
const BIT_INTERACTUABLES := 1 << (INTERACTUABLES - 1)

## Nombres de las capas, en orden. Deben coincidir con project.godot.
const NOMBRES: PackedStringArray = [
	"Terreno",
	"Plataformas atravesables",
	"Cuerpo de William",
	"Cuerpo de enemigos",
	"Recibe golpes: William",
	"Recibe golpes: enemigos",
	"Ataques de William",
	"Ataques enemigos",
	"Trampas",
	"Recolectables",
	"Interactuables",
]

## Tipos de objeto del juego. Cada uno tiene una capa y una máscara fijas.
enum Perfil {
	TERRENO,                ## TileMap y cuerpos estáticos sólidos.
	PLATAFORMA,             ## Plataformas atravesables desde abajo.
	CUERPO_WILLIAM,         ## CharacterBody2D de William.
	CUERPO_ENEMIGO,         ## CharacterBody2D de cada enemigo.
	RECIBE_GOLPES_WILLIAM,  ## Área donde William recibe golpes (hurtbox).
	RECIBE_GOLPES_ENEMIGO,  ## Área donde un enemigo recibe golpes (hurtbox).
	ATAQUE_WILLIAM,         ## Espada y llamarada (hitbox).
	ATAQUE_ENEMIGO,         ## Golpes cuerpo a cuerpo de los enemigos (hitbox).
	PROYECTIL_WILLIAM,      ## Descarga y bola de fuego.
	PROYECTIL_ENEMIGO,      ## Proyectiles de los enemigos.
	TRAMPA,                 ## Trampas que dañan (pinchos, fuego, etc.).
	ZONA_VACIO,             ## Caída al vacío: actúa sobre el cuerpo.
	RECOLECTABLE,           ## Monedas y escamas.
	INTERACTUABLE,          ## Mago, punto de habilidades y cofres.
	DETECTOR_WILLIAM,       ## Zona con la que un enemigo ve a William.
	DETECTOR_SUPERPOSICION, ## Sensor de enemigos superpuestos.
}

## Capa y máscara de cada perfil: [capa, máscara].
const CONFIGURACION := {
	Perfil.TERRENO: [BIT_TERRENO, 0],
	Perfil.PLATAFORMA: [BIT_PLATAFORMAS, 0],
	Perfil.CUERPO_WILLIAM: [BIT_CUERPO_WILLIAM, BIT_TERRENO | BIT_PLATAFORMAS | BIT_CUERPO_ENEMIGOS],
	Perfil.CUERPO_ENEMIGO: [BIT_CUERPO_ENEMIGOS, BIT_TERRENO | BIT_PLATAFORMAS | BIT_CUERPO_WILLIAM],
	Perfil.RECIBE_GOLPES_WILLIAM: [BIT_RECIBE_GOLPES_WILLIAM, BIT_ATAQUES_ENEMIGOS | BIT_TRAMPAS],
	Perfil.RECIBE_GOLPES_ENEMIGO: [BIT_RECIBE_GOLPES_ENEMIGOS, BIT_ATAQUES_WILLIAM],
	Perfil.ATAQUE_WILLIAM: [BIT_ATAQUES_WILLIAM, BIT_RECIBE_GOLPES_ENEMIGOS],
	Perfil.ATAQUE_ENEMIGO: [BIT_ATAQUES_ENEMIGOS, BIT_RECIBE_GOLPES_WILLIAM],
	Perfil.PROYECTIL_WILLIAM: [BIT_ATAQUES_WILLIAM, BIT_RECIBE_GOLPES_ENEMIGOS | BIT_TERRENO],
	Perfil.PROYECTIL_ENEMIGO: [BIT_ATAQUES_ENEMIGOS, BIT_RECIBE_GOLPES_WILLIAM | BIT_TERRENO],
	Perfil.TRAMPA: [BIT_TRAMPAS, BIT_RECIBE_GOLPES_WILLIAM],
	Perfil.ZONA_VACIO: [BIT_TRAMPAS, BIT_CUERPO_WILLIAM | BIT_CUERPO_ENEMIGOS],
	Perfil.RECOLECTABLE: [BIT_RECOLECTABLES, BIT_CUERPO_WILLIAM],
	Perfil.INTERACTUABLE: [BIT_INTERACTUABLES, BIT_CUERPO_WILLIAM],
	Perfil.DETECTOR_WILLIAM: [0, BIT_CUERPO_WILLIAM],
	Perfil.DETECTOR_SUPERPOSICION: [0, BIT_CUERPO_ENEMIGOS],
}


## Capa (collision_layer) de un perfil.
static func capa(perfil: Perfil) -> int:
	return CONFIGURACION[perfil][0]


## Máscara (collision_mask) de un perfil.
static func mascara(perfil: Perfil) -> int:
	return CONFIGURACION[perfil][1]


## Aplica la capa y la máscara del perfil a un objeto con colisión
## (CharacterBody2D, Area2D o StaticBody2D). El terreno de un TileMapLayer se
## configura en las capas físicas de su TileSet, con la capa Terreno o
## Plataformas atravesables.
static func configurar(objeto: CollisionObject2D, perfil: Perfil) -> void:
	objeto.collision_layer = capa(perfil)
	objeto.collision_mask = mascara(perfil)


## Nombres de las capas presentes en [param bits], separados por coma.
static func nombres_de(bits: int) -> String:
	var nombres := PackedStringArray()
	for i in NOMBRES.size():
		if bits & (1 << i):
			nombres.append("%d %s" % [i + 1, NOMBRES[i]])
	return ", ".join(nombres) if not nombres.is_empty() else "—"


## Tabla legible con la capa y lo que detecta cada perfil.
static func describir() -> String:
	var lineas := PackedStringArray()
	for perfil in Perfil.values():
		lineas.append("%s\n    Capa:    %s\n    Detecta: %s" % [
			Perfil.keys()[perfil], nombres_de(capa(perfil)), nombres_de(mascara(perfil))])
	return "\n".join(lineas)
