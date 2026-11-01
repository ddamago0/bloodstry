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

---

## 🦴 Mecánica Central: Armas de Extremidades (Gore System)

Al matar enemigos, existe una probabilidad de que cercenes una de sus partes:
* **Cabeza (Proyectil):** Se lanza hacia el cursor a gran velocidad, infligiendo daño crítico concentrated a un solo enemigo.
* **Brazo de Esqueleto (Control de masas):** Funciona como un látigo articulado de huesos, causando daño en un área amplia y empujando a la horda.
* **Brazo de Zombie (Brutalidad física):** Alcance corto pero un impacto demoledor que pulveriza a los enemigos cercanos.
* **Durabilidad Oculta & Alerta:** Las extremidades tienen una resistencia secreta aleatoria. Al restarles pocos golpes, la interfaz y el arma parpadean en rojo sangre.
* **Ataque de Sacrificio (*Last Ditch Attack*):** Con `E` o `Shift`, antes de que el arma se rompa sola, la haces detonar o la disparas con el triple ($3\times$) de daño y área masiva.

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
│   │   └── state_machine.lua    # Gestor de estados de escena
│   ├── entities/
│   │   ├── entity.lua           # Clase base con vida, daño y knockback
│   │   ├── player.lua           # Protagonista, clases, pasivas y armas
│   │   ├── enemy.lua            # Esqueletos comunes, altos, con túnica y zombies
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
