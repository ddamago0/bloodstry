# Créditos y Licencias

## ⚠️ Pendiente de verificación

Dos de los packs usados para el bestiario llegaron **sin LICENSE, sin README y sin autor**. El repositorio es público (`github.com/ddamago0/bloodstry`), así que antes de distribuir el juego o el atlas derivado hay que confirmar su procedencia:

| Archivo | Contenido usado | Estado |
|---|---|---|
| `external_assets/scarymobs.zip` | `undead.png`, `werebeasts.png`, `beasts.png`, `smallbeasts.png`, `cosmic_horror_dude.png` | **Licencia desconocida** |
| `external_assets/Asset Pack.zip` | `Monsters/DICE 3/Walk/*.png`, `Monsters/DICE 5/Walk/*.png` | **Licencia desconocida** |

Qué hacer cuando se confirmen:

1. Añadir aquí el nombre del pack, autor, licencia y URL de origen.
2. Si la licencia es **CC0**: no hace falta atribución, pero se conserva este archivo igualmente.
3. Si la licencia es **CC-BY**: añadir el crédito también en la pantalla de créditos del juego.
4. Si la licencia prohíbe redistribuir: sustituir los frames por arte propio (`tools/artgen`) y borrar `assets/sprites/horror_bestiary.png`.

Mientras tanto, `external_assets/` está excluido del control de versiones (ver `.gitignore`) para no publicar los ZIP originales.

## Arte propio

Todo lo demás es generado de forma determinista por el proyecto:

* `tools/generate_assets.py` + `tools/artgen/` — tilesets, props, jugadores, enemigos de respaldo, HUD, iconos, viñeta, niebla.
* `tools/import_external.py` — recorte por clústeres, pase de corrupción de paleta y empaquetado del atlas externo.

## Tipografía

* **m5x7** — Daniel Linssen, CC0 1.0. <https://managore.itch.io/m5x7>

## Motor y librerías

* **LÖVE 11.x** — zlib/libpng. <https://love2d.org>
* **push** — Ulydev, MIT. <https://github.com/Ulydev/push>
* **classic** — rxi, MIT. <https://github.com/rxi/classic>

## Nota sobre assets de terceros descartados

Se evaluaron y **no** se incorporaron:

* **DawnLike** — CC-BY-SA 3.0: obligaría a liberar el tileset derivado con la misma licencia.
* **Mystic Woods (versión gratuita)** — prohíbe el uso comercial.
* **Kokoro Reflections** — prohíbe redistribuir los tiles, incluso en repos públicos.
