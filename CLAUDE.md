# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

"Dragonbound: Oath of Blood" is a 2D pixel-art platformer built with **Godot 4.7** and GDScript only. There is no other build system. The player character is **William**.

**Language convention:** all identifiers, class names, node names, input actions, doc comments and commit messages are in **Spanish**, for example `MaquinaEstados`, `recibir_danio`, `mover_derecha`, `prioridad`. Leave out accents and ñ in identifiers (`danio`, `dueno`), but keep them in comments and strings. Follow this convention in new code.

Doc comments use `##` and often cite design-document section numbers, for example `(1.2.6.1)` or `(1.4.5.2)`. These numbers refer to the team's external design and task plan. Keep them when editing, and cite the relevant section for new work. Many systems leave part of their work to a named later task (for example, final damage is calculated in 1.4.5.1 and animations are connected in 1.4.10). Respect those boundaries.

Git workflow: feature branches named `feature/<tema>`, merged into `dev` via PR. Commit subjects are short Spanish phrases that end with the task number, for example `Máquina de estados de William (1.4.3.1)`.

## Commands

Run from the project root (assuming `godot` is on PATH):

```bash
godot --headless --import                                          # required once after cloning (builds .godot/)
godot --editor .                                                   # open the editor
godot .                                                            # run the main scene (MainGame)
godot --headless res://src/debug/prueba_maquina_estados.tscn       # run one test scene
```

`.godot/` is not committed. On a fresh clone, run `--import` first: otherwise `class_name` types are not found, and a test scene prints parse errors and never exits. Wrap test runs in `timeout 120` so that case cannot hang.

There is no test framework. Tests are **self-checking scenes in `src/debug/prueba_*.tscn`**. Each one prints `OK` / `FALLA` lines plus a final `Resultado: ...`, then calls `get_tree().quit(0 or 1)`, so you can read the exit code. Current headless tests:
- `prueba_catalogo_tienda.tscn`: shop catalog
- `prueba_capas_colision.tscn`: collision layers and masks
- `prueba_maquina_estados.tscn`: William's state machine, driven by simulated input
- `prueba_movimiento.tscn`: William's movement and jump
- `prueba_hitboxes.tscn`: hitboxes and hurtboxes
- `prueba_danio.tscn`: damage calculation, resistances, talismans, health, invulnerability blink and death notice
- `prueba_gestor_niveles.tscn`: level sequence, scene loading, fade, William's spawn and end of level (takes about 30 s)
- `prueba_colision.tscn`: collision with tilemap terrain, walls, ceilings, corner correction, one-way platforms and 45°/22.5° slopes

`prueba_jugador.tscn`, `prueba_terreno.tscn` (same controls, on a tilemap with slopes and platforms) and `prueba_golpes.tscn` are interactive playgrounds, not automated tests (A/D, Space, J, R = reset; in `prueba_jugador`, also H = take a 1-heart hit, M = die; in `prueba_golpes`, T = toggle physical talisman, U = toggle fire rune).

To add a test, copy the existing pattern: a `_verificar(condicion, descripcion)` helper, a `_fallas` counter, and a `quit` with the exit code. Use `EscenarioPrueba.crear_terreno()`, `crear_trampa()`, and `crear_tilemap()` / `pintar()` / `pintar_rampa()` for tilemap geometry (`src/debug/escenario_prueba.gd`) to build test geometry in code. `Munieco` (`src/debug/munieco.gd`) is a debug-only dummy enemy. Simulate input with `Input.action_press/release` and wait on `get_tree().physics_frame`.

## Architecture

- **Layout:** `src/core` (engine-level systems), `src/gameplay` (player, combat, enemies, shop, etc.), `src/resources` (data `.tres` + their `Resource` scripts), `src/levels`, `src/debug`. Art and audio go in `assets/`. Many folders are still `.gitkeep` placeholders.
- **Main scene** `src/core/main_game/main_game.tscn` is a fixed skeleton: `Systems`, `World/{LevelRoot,EntityRoot,EffectRoot}`, and CanvasLayers for HUD, pause, transitions and debug. Levels (template: `src/levels/test_level_01.tscn`) use `Background / Tilemaps / LevelObjects / Environment`. No autoloads exist yet.
- **Level manager** (`src/core/niveles/gestor_niveles.gd`, node `Systems/GestorNiveles`): `MainGame` stays loaded and only the scene inside `LevelRoot` changes; do not use `change_scene_to_file()`. The order comes from `SecuenciaNiveles` (`src/resources/secuencia_niveles.tres`), with the camp between levels. Every playable scene has a `Nivel` root script (`src/levels/nivel.gd`) that sets `punto_aparicion` and, except level 5, `disparador_fin`. There is one William for the whole game, in `EntityRoot`; each scene places him with `Jugador.aparecer()`, so add anything that must not carry over between scenes there. The tree is paused during a transition, and the pause menu (1.4.1.2) must check `esta_en_transicion()`. `nivel_01`–`nivel_05` and `campamento` are placeholders (`NivelProvisorio`) until 1.4.2.2–1.4.2.6 and 1.4.2.8 replace them. `iniciar_al_arrancar` in `main_game.gd` is temporary until the main menu (1.4.1.1) starts the game.
- **State machine** (`src/core/state_machine/`): `MaquinaEstados` holds child `EstadoBase` nodes, each keyed by its **node name** (`&"Quieto"`, `&"RecibirDanio"`, ...). Two things matter here:
  - The machine does **not** tick itself. The owner calls `maquina.iniciar(self)` in `_ready` and `maquina.actualizar_fisica(delta)` in `_physics_process` before `move_and_slide()`.
  - `cambiar_a()` is for a state's own transitions and skips priority checks. `interrumpir()` is for external events such as damage or death. It only applies if the current state allows interruption and the new state's `prioridad` is equal or lower (a lower number means higher priority). States set `prioridad` in `_init`.
  - Player states (`src/gameplay/player/estados/`) extend `EstadoJugador`, which gives typed access to `jugador: Jugador` and shared transition helpers (`volver_segun_situacion`, `revisar_acciones_en_suelo`). To add a state, add a script there and a node under `MaquinaEstados` in `player.tscn`. The same machine is meant to be reused for enemies (1.4.6.1).
- **Collision** (`src/core/physics/capas_colision.gd`): never hard-code layer or mask bits. Call `CapasColision.configurar(obj, CapasColision.Perfil.X)` in `_ready`. The 11 named layers in `project.godot` `[layer_names]` must stay in sync with `CapasColision.NOMBRES`/constants. The file header lists the design rules: body is separate from hurtbox, no friendly fire, enemies pass through each other, and projectiles pass through platforms. `CapasColision.describir()` prints a readable table.
- **Tile collision** (`src/core/physics/formas_colision_tile.gd`, 1.4.3.3): tile collision shapes follow the 16 px grid, not the art. Every tile uses one standard `FormasColisionTile.Forma` (BLOQUE, PLATAFORMA one-way, 45° and 22.5° slopes, NINGUNA for decoration), stored in the TileSet custom data layer `forma`. Physics layer 0 = Terreno, 1 = Plataformas atravesables. William cannot drop through one-way platforms. `src/resources/tilesets/tileset_provisorio.tres` is a **placeholder test tileset** (regenerate with `godot --headless -s res://src/debug/generar_tileset_provisorio.gd`). **Pending:** each real level tileset (1.4.2.2–1.4.2.6, 1.4.2.8) must call `FormasColisionTile.preparar_tileset()`/`aplicar()` (or set the same polygons in the editor) and pass `FormasColisionTile.validar()`.
- **Combat** (`src/gameplay/combat/`): a `Hitbox` delivers a `Golpe` to each `Hurtbox` it touches. Its mode is `POR_ACTIVACION` (once per target per activation) or `CONTINUO` (retries during contact). The `Hurtbox` only accepts or rejects the hit (inactive or invulnerable targets reject it). Only hitboxes deal damage: body contact does not. Damage (1.4.5.1): `CalculoDanio` (static) applies enemy `Resistencias` (0/25/50 %, or `solo_danio_magico`) or William's `ProteccionesJugador` talismans (provisional until 1.4.11.1) and rounds to ½-heart steps with ties up and a ½ minimum. `Salud` is a reusable node (hearts; signals `salud_cambiada`, `danio_recibido`, `golpe_sin_efecto` for 0-damage hits, `murio`). A `Golpe` has a main `danio`/`tipo` plus `danio_magico_extra` (fire rune, set by 1.4.5.2 via `Hitbox.danio_magico_extra`). William blinks via `modulate.a` while invulnerable; the Dragon Armor (1.4.5.10) works by setting `area_golpes.activa = false`. Enemy hit reaction (knockback etc.) belongs to 1.4.6.1.
- **Data resources:** William's movement values are `MetricasJugador` data in `src/resources/metricas_william.tres`, in tiles and seconds, so they can be calibrated without touching code; the script converts them to pixels. Shop items are `DefinicionObjeto` `.tres` files in `src/resources/item_definitions/`, listed in `src/resources/catalogo_tienda.tres` (`CatalogoTienda`). The catalog never reads global game state. It takes an `EstadoCompras` (a temporary stand-in until the global game state of 1.4.11.1 exists) and returns `OfertaTienda` objects. `validar()` methods on items and the catalog return a list of error strings.
- **Input actions** are defined in `project.godot` with Spanish names (`mover_izquierda`, `saltar`, `atacar`, `aliento`, `armadura`, `pocion_curacion`, `interactuar`, `pausa`, ...). Expected key bindings are checked by `prueba_maquina_estados.gd`.
- **Pixel-art settings:** 640×360 viewport, integer scaling, nearest filtering, 2D pixel snapping. Gameplay units are tiles of 16 px (`Jugador.TILE`). Values kept in code are written as `n * TILE`.

## Conventions

- Use static typing everywhere, `StringName` literals (`&"..."`) for state names and actions, and typed dictionaries (`Dictionary[StringName, int]`).
- Commit the `.uid` files that Godot creates next to scripts.
- Edit `.tscn`/`.tres`/`project.godot` by hand carefully. Keep `ext_resource` ids and node paths consistent.
