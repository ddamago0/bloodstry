# 🩸 Bloodsty: El Turno de Guardia

**BLOODSTRY** (Intento de sangre), es un Horde Survival que consiste en sobrevivir rondas entre 4 stages, Un cementerio (El unico implementado hasta el momento), un hospital abandonado, una granja y un matadero con enemigos referentes a cada una de las zonas exploradas.

Con Jefes como **La Parca**, en la primera stage y en la segunda su fusion con un zombie mutante, volviendolo **"El cadaver de la Parca"** y el ultimo boss siendo un caballo en vuelto en paja que al vencerlo se torna fuego y dandole paso a su jinete [el boss de la segunda stage], como **El primer jinete del apocalipsis**.

La historia esta en desarrollo junto a la implementacion de las demas zonas, una vez pulido se subira a itch.io de gustarles podrian dejar comentarios al respecto, sobre que cosas les gustaria que estuviese en el juego final :)

. Desarrollado en Lua con el framework **LÖVE 2D**.

**Video promocional del juego:** https://youtu.be/CAdc_X7BwO0?si=ABXmyLEv_STZmR6f

---

## 🎮 Controles

| Acción | Teclado / Ratón |
| :--- | :--- |
| **Movimiento** | `W`, `A`, `S`, `D` o `Flechas` (8 direcciones normalizadas) |
| **Apuntar** | Puntero del Ratón (360°) |
| **Ataque Primario de Clase** | `Clic Izquierdo` o `Espacio` |
| **Ataque con Extremidad Equipada** | `Clic Derecho` o `K` |
| **Sacrificio / Last Ditch Attack** | `E`, `F`, `Shift Izquierdo` o `Clic Central` |
| **Menú de Mejoras y Pactos** | `Tab` o `U` |
| **Reroll de Cartas** | `R` (en el menú de mejoras) |
| **Navegación en Menús** | Teclas `1`, `2`, `3` o Clic Izquierdo |
| **[Atajo Dev] Forzar Jefe (La Parca)** | `B` (durante la partida) |
| **[Atajo Dev] Nivel Inmediato** | `L` (durante la partida) |

---

## ⚔️ Las 3 Clases

1. **Guerrero (Ex-cantero y herrero):**
   * *Vida:* Alta (150 PS) | *Fuerza:* Media (1.0x) | *Velocidad:* Baja (92 px/s)
   * *Arma inicial:* **Espada Bastarda** (corte circular frontal en arco).
   * *Pasiva:* Gana un **Escudo Óseo temporal** que absorbe daño cada vez que se le rompe o sacrifica una extremidad.
2. **Bárbaro (Cavador de fosas y leñador):**
   * *Vida:* Media (115 PS) | *Fuerza:* Alta (1.45x) | *Velocidad:* Baja (86 px/s)
   * *Arma inicial:* **Murakumogiri** (alabarda gigante de barrido pesado y masivo empuje).
   * *Pasiva:* Empuña una extremidad en su mano secundaria sin pausar ni guardar su arma principal.
3. **Asesino (Fugitivo y profanador de tumbas):**
   * *Vida:* Baja (85 PS) | *Fuerza:* Baja (0.82x) | *Velocidad:* Alta (135 px/s)
   * *Arma inicial:* **2 Dagas** (estocadas rápidas y letales a corta distancia).
   * *Pasiva:* Lanza cabezas al doble de velocidad y aplica **Sangrado DoT** con brazos de zombie.

> Los tres supervivientes comparten la paleta de ceniza, hueso y sangre seca del bestiario y tienen un ciclo de caminata de 4 poses (contacto, paso, contacto inverso, paso). Ver §7.2 de `Implementacion_Tecnica.md`.

---

## 🦴 Mecánica Central: Armas de Extremidades (Gore System)

Al matar enemigos, existe una probabilidad de que cercenes una de sus partes:
* **Cabeza (Proyectil):** Se lanza hacia el cursor a gran velocidad, infligiendo daño crítico concentrated a un solo enemigo.
* **Brazo de Esqueleto (Control de masas):** Funciona como un látigo articulado de huesos, causando daño en un área amplia y empujando a la horda.
* **Brazo de Zombie (Brutalidad física):** Alcance corto pero un impacto demoledor que pulveriza a los enemigos cercanos.
* **Durabilidad Oculta & Alerta:** Las extremidades tienen una resistencia secreta aleatoria. Al restarles pocos golpes, la interfaz y el arma parpadean en rojo sangre.
* **Ataque de Sacrificio (*Last Ditch Attack*):** Con `E` o `Shift`, antes de que el arma se rompa sola, la haces detonar o la disparas con el triple ($3\times$) de daño y área masiva.

---

## 📈 Progresión y Ritmo de Sangre

Los enemigos sueltan orbes de sangre que atraen hacia el jugador con el imán:
* **Sabueso:** 9 de sangre.
* **Esqueleto común:** 10 de sangre.
* **Arrastrado (zombi):** 12 de sangre.
* **Pálido encapuchado:** 14 de sangre.
* **Licántropo (mutado):** 20 de sangre.
* **Gólem de huesos:** 30 de sangre.
* **Lánguido (élite):** 50 de sangre.
* **Guardián de carne (mini-jefe):** 90 de sangre.
* **Orbes del jefe:** 60 cada uno.

El primer nivel cuesta **160** de sangre (unas 15 bajas) y cada nivel siguiente multiplica el umbral por **1.38**. Un nivel tardío pide más de 100 bajas, así que una partida completa termina alrededor del **nivel 7-11** en lugar de encadenar menús cada pocos segundos. El menú de mejoras se abre solo al acumular niveles pendientes, pero **nunca durante la intro de un jefe**.

---

## 🧟 Bestiario importado

Las criaturas ya no son cuatro esqueletos dibujados a mano: el cementerio usa un bestiario de nueve siluetas importadas de packs externos, oscurecidas y cuantizadas a la paleta de ceniza, hueso y sangre seca.

| Criatura | Rol | Silueta | Desde |
|---|---|---|---|
| `hound` | Enjambre rápido y frágil | 29×21 | sabueso de `scarymobs` |
| `skeleton_common` | Base de la horda | 16×31 (2 frames) | esqueleto de `scarymobs` |
| `zombie` (arrastrado) | Rápido, se pega al suelo | 36×16 | bestia reptante de `scarymobs` |
| `skeleton_robed` (pálido) | Hostigador a distancia | 21×34 | figura sin rostro de `scarymobs` |
| `skeleton_tall` (licántropo) | Bruto de melé | 25×48 (2 frames) | hombre lobo de `scarymobs` |
| `bone_golem` | Tanque lento | 40×52 (2 frames) | masa de huesos de `scarymobs` |
| `lanker` (élite) | Amenaza alta y delgada | 19×63 | `cosmic_horror_dude` |
| `warden` (mini-jefe) | Muro de carne | 64×66 (6 frames) | `DICE 3` de `Asset Pack` |
| `weaver` (élite) | Arácnido de dado | 54×59 (4 frames) | `DICE 5` de `Asset Pack` |

Reglas de integración que se mantienen:

* **Anclaje por pies:** cada frame se recorta y se dibuja con origen `(w/2, h)`, así entra en el Y-sort sin desplazar la sombra.
* **Sombra fuera del sprite:** la elipse se dibuja aparte; nunca está horneada en el PNG.
* **Pase de corrupción:** `horror_pass()` desatura al 60 %, oscurece, tiñe las sombras de violeta y añade un borde casi negro. Es lo que impide que se note el cambio de artista.
* **Escala exacta:** el tamaño final se hornea en el atlas (`NEAREST`), nunca se escala en tiempo de dibujo.
* **Animación opcional:** `animFrame`/`animTime` avanzan solo si el set tiene `fps > 0`; las criaturas de una sola pose respiran con el *wobble* procedural.

Para regenerar el atlas tras cambiar recortes o escalas:

```bash
python3 tools/import_external.py --preview   # atlas + Lua + hoja de contactos
BLOODSTY_AUTOTEST=bestiary love .            # alineación de las 9 criaturas
```

> La procedencia y el estado de licencias de cada pack están en **[CREDITS.md](CREDITS.md)**.

---

## 📁 Estructura del Código para el Equipo

```text
Bloodstry/
├── conf.lua                     # Configuración de ventana (1280x720 resizable, vsync)
├── main.lua                     # Entry point y bucle de juego con LÖVE
├── lib/
│   ├── classic.lua              # Sistema de clases OOP
│   └── push.lua                 # Escalado de resolución virtual retro (480x270)
├── src/
│   ├── core/
│   │   ├── camera.lua           # Cámara con lerp, bounds y screenshake
│   │   ├── spatial_hash.lua     # Cuadrícula espacial O(N) para hordas de 500+ entidades
│   │   ├── input.lua            # Abstracción de controles y ratón
│   │   ├── bestiary_atlas.lua   # Quads generados del bestiario importado
│   │   └── state_machine.lua    # Gestor de estados de escena
│   ├── entities/
│   │   ├── entity.lua           # Clase base con vida, daño y knockback
│   │   ├── player.lua           # Protagonista, clases, pasivas y armas
│   │   ├── enemy.lua            # Bestiario: 9 criaturas con animación multi-frame
│   │   ├── limb_drop.lua        # Extremidades recogibles en el suelo
│   │   ├── soul_drop.lua        # Orbes de sangre / almas con imán
│   │   └── bosses/
│   │       └── la_parca.lua     # Jefe Stage 1: teletransporte, guadaña y barrajes
│   ├── combat/
│   │   ├── weapon.lua           # Espada bastarda, Murakumogiri y 2 Dagas
│   │   ├── limb.lua             # Cabeza, Brazo Esqueleto, Brazo Zombie y Sacrificio
│   │   └── projectile.lua       # Proyectiles (cráneos, huesos, etc.)
│   ├── stages/
│   │   └── stage1_cemetery.lua  # Bioma de cementerio, decorados y director de oleadas
│   ├── progression/
│   │   └── skills_data.lua      # Bendiciones y Pactos Malditos (Hemofilia, Frenesí Ciego)
│   ├── ui/
│   │   ├── hud.lua              # Barras de vida, escudo óseo, extremidad y temporizador
│   │   └── upgrade_menu.lua     # Cartas de selección aleatorias y sistema de reroll
│   ├── vfx/
│   │   ├── blood_canvas.lua     # Canvas estático para miles de manchas de sangre sin lag
│   │   └── particles.lua        # Emisores de partículas de sangre, hueso y almas
│   └── states/
│       ├── class_select_state.lua # Pantalla de selección de Guerrero, Bárbaro o Asesino
│       ├── play_state.lua         # Core gameplay loop
│       └── game_over_state.lua    # Pantalla de victoria y derrota
├── tools/
│   ├── generate_assets.py       # Pipeline determinista del arte propio
│   ├── import_external.py       # Recorte, corrupción de paleta y atlas externo
│   └── artgen/                  # Módulos de dibujo procedural
```

---

## 🚀 Cómo Ejecutar

Asegúrate de tener [LÖVE](https://love2d.org/) (versión 11.4+) instalado en tu sistema.

Desde la terminal en el directorio del proyecto:
```bash
love .
```
O arrastrando la carpeta `Bloodstry` directamente sobre el ejecutable de `love.exe` en Windows.

---

## 🎬 Trailer de 30 segundos

El archivo `bloodsty_trailer_30s.mp4` (1920×1080, 30 fps, H.264 + audio) muestra la Fase 1 jugable, las tres clases, la horda, las extremidades, el Sacrificio, el Escudo Óseo, las Maldiciones y el combate contra La Parca. Las Fases 2-4 aparecen como fichas conceptuales marcadas **«EN DISEÑO»**, porque todavía no están implementadas.

Para regenerarlo:

```bash
# 1. Graba 900 fotogramas a 480x270 en la carpeta de guardado de LÖVE
BLOODSTY_TRAILER=1 love .

# 2. Genera la banda sonora ambiental
python3 tools/make_trailer_audio.py /tmp/opencode/bloodsty_trailer_audio.wav

# 3. Codifica el MP4 (desde la carpeta trailer_frames)
cd ~/.local/share/love/bloodsty/trailer_frames
ffmpeg -y -framerate 30 -start_number 0 -i frame_%05d.png \
  -i /tmp/opencode/bloodsty_trailer_audio.wav \
  -vf "scale=1920:1080:flags=neighbor" \
  -c:v libx264 -preset slow -crf 18 -tune animation -pix_fmt yuv420p \
  -c:a aac -b:a 160k -shortest -movflags +faststart \
  /ruta/a/Bloodstry/bloodsty_trailer_30s.mp4
```
