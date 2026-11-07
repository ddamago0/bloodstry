# 🩸 Implementación Técnica: Bloodsty

> **Documento Maestro de Arquitectura, Sistemas y Contexto Técnico Completo.**  
> Este documento unifica todo el diseño, código, dependencias, mecánicas y decisiones técnicas implementadas para el equipo de 5 desarrolladores.

---

## 1. Visión General del Proyecto

* **Nombre del Juego:** Bloodsty (El Turno de Guardia).
* **Género:** *Horde Survival* visceral (*Brotato*, *Vampire Survivors*) combinado con atmósfera y tensión de *Survival Horror* (*Darkwood*, *Diablo 1*, estética retro gore).
* **Perspectiva:** 2.5D / Cenital $\frac{3}{4}$ con ordenamiento dinámico de profundidad (*Y-Sorting*) y proyección elíptica de sombras.
* **Motor & Lenguaje:** **LÖVE 2D (v11.5)** con **Lua / LuaJIT**.
* **Resolución Virtual:** $480 \times 270$ píxeles escalados dinámicamente con filtro `nearest` (*pixel-perfect* sin distorsión) mediante la librería `push.lua`. Ventana base de $1280 \times 720$.

---

## 2. Lore y Premisa Narrativa

1. **El Origen:** El protagonista es un joven sepulturero novato y mal remunerado. Su huraño superior, **Don Evaristo**, le encomienda un turno de guardia nocturno de última hora en el camposanto para *"cuidar el muro norte y evitar que algo brote de la tierra consagrada"*, entregándole las llaves de la cripta central antes de escapar.
2. **La Traición:** Don Evaristo es el heraldo de un culto nigromántico clandestino. Usó al joven como sacrificio vivo en suelo consagrado para romper el sello arcano de **La Parca**.
3. **El Estado Liminal:** Acorralado y desangrándose en el mausoleo central, la sangre del joven se fusiona con los restos del sello roto. No fallece del todo: queda atrapado en un estado liminal como semi-muerto viviente, demacrado y con sus ropas de trabajo empapadas en sangre.
4. **La Cacería:** Para conservar su consciencia y evitar que su cuerpo colapse, debe absorber la violencia y los restos de la horda desatada, persiguiendo a Don Evaristo a través de 4 biomas fúnebres.

---

## 3. Clases de Personajes y Estadísticas Base

Cada clase representa el pasado del joven antes de ingresar al cementerio, con estadísticas asimétricas y pasivas vinculadas al sistema de gore:

| Clase | Vida (PS) | Fuerza | Velocidad | Arma Primaria Inicial | Pasiva Especial |
| :--- | :---: | :---: | :---: | :--- | :--- |
| **Guerrero** *(Ex-cantero y herrero de mausoleos)* | 150 | 1.0x | 92 px/s | **Espada Bastarda:** Tajo frontal en arco equilibrado ($120^\circ$). | **Escudo Óseo:** Genera un escudo temporal de hasta +45 PS al romperse o sacrificar cualquier extremidad. |
| **Bárbaro** *(Cavador de fosas y leñador)* | 115 | 1.45x | 86 px/s | **Murakumogiri:** Alabarda gigante con barridos lentos de alto impacto y masivo *knockback*. | **Doble Empuñadura:** Puede atacar con su arma principal y su extremidad secundaria sin demora compartida. |
| **Asesino** *(Fugitivo y profanador de tumbas)* | 85 | 0.82x | 135 px/s | **2 Dagas:** Ráfaga rápida y letal de estocadas alternadas a corta distancia. | **Letalidad Impía:** Lanza cabezas al doble ($2\times$) de velocidad y aplica sangrado continuo (*DoT*) con brazos de zombie. |

---

## 4. Mecánica Central: Armas de Extremidades (Gore System)

Al matar enemigos existe una probabilidad del $22\%$ de cercenar una extremidad que queda como drop físico en el suelo:

```text
               ┌───────────────────────────────┐
               │    ENEMIGO NO-MUERTO DERROTADO │
               └───────────────┬───────────────┘
                               │ (22% drop rate)
                               ▼
            ┌──────────────────────────────────────┐
            │   EXTREMIDAD CERCENADA EN EL SUELO   │
            │ (Cabeza / Brazo Esqueleto / Zombie)  │
            └──────────────────┬───────────────────┘
                               │ Al caminar sobre ella
                               ▼
            ┌──────────────────────────────────────┐
            │       EXTREMIDAD EQUIPADA EN MANO    │
            │   Durabilidad Oculta: [ 6 / 6 usos ] │
            └──────┬────────────────────────┬──────┘
                   │ [Clic Derecho]         │ [E / Shift]
                   ▼                        ▼
        ┌─────────────────────┐   ┌─────────────────────────┐
        │   ATAQUE SECUNDARIO │   │ SACRIFICIO (LAST DITCH) │
        │ Consume 1 uso       │   │ Detonación instantánea  │
        │ Alerta roja con <=2 │   │ Daño x3 en área masiva  │
        └─────────────────────┘   └─────────────────────────┘
```

* **Tipos de Extremidad:**
  1. **Cabeza Cercenada (Proyectil):** Se arroja con trayectoria recta infligiendo daño crítico masivo a un único objetivo.
  2. **Brazo de Esqueleto (Control de Masas):** Funciona como un látigo de vértebras articuladas con amplio rango de barrido y aturdimiento.
  3. **Brazo de Zombie (Brutalidad Física):** Rango muy corto pero impacto demoledor que machaca a los enemigos próximos.
* **Durabilidad Oculta & Alerta:** Cada extremidad posee un número aleatorio y secreto de golpes (entre 4 y 14). Al restar $\le 2$ golpes o $< 30\%$ de vida, la UI y el sprite parpadean en rojo sangre indicando inestabilidad.
* **Mecánica de Sacrificio (*Last Ditch Attack*):** Con `E`, `Shift` o `Clic Central`, el jugador detona deliberadamente la extremidad antes de que se autodestruya, provocando una explosión ósea/necrótica con **$3\times$ de daño** y empuje monumental.

---

## 5. Progresión, Menú de Mejoras y Pactos Malditos

* **Almas y Sangre:** Los enemigos derrotados liberan orbes de sangre con imán de atracción hacia el protagonista.
* **Ritmo de Sangre:** Los orbes escalan con la criatura: sabueso 9, esqueleto común 10, arrastrado 12, pálido 14, licántropo 20, gólem 30, élite 50, mini-jefe 90 y 60 por orbe del jefe. El primer nivel cuesta 160 y cada nivel siguiente multiplica el umbral por 1.38, así que el nivel 2 exige unas 15 bajas y un nivel tardío supera las 100. Si un solo orbe cruza varios umbrales, se consumen todos en el mismo instante (la barra nunca pasa del 100%).
* **Menú Modal de Nivel:** Al subir de nivel (o mediante `Tab` / `U`) se congela el combate y se despliegan **3 cartas aleatorias**:
  * **Bendiciones Estándar:** Vigor Impío (+25 Vida), Fuerza Cadavérica (+22% Daño), Paso del Sepulturero (+15% Velocidad), Imán Sanguíneo (+45% Radio), Sed Insaciable (+5% Robo de Vida).
  * **Pactos Malditos (Trade-offs extremos):**
    * *Pacto de Hemofilia:* -30% Vida Máxima a cambio de +10% robo de vida y rastro de sangre hirviente en el suelo.
    * *Frenesí Ciego:* Reduce el campo de visión un 50% (estilo linterna Survival Horror) a cambio de +100% Fuerza bruta y +40% cadencia.
    * *Huesos de Cristal:* Las extremidades duran 50% menos, pero el daño y área del Sacrificio (*Last Ditch*) se triplican.
  * **Reroll:** Botón `[R]` con cupo de 2 tiradas por intento para renovar las 3 cartas.

---

## 6. Los 4 Stages y Jefes del Juego

| Stage | Bioma & Atmósfera | Horda de Enemigos | Jefe de Nivel (Boss) |
| :--- | :--- | :--- | :--- |
| **1. El Cementerio** *(Implementado)* | Niebla nocturna, lápidas agrietadas y la cripta central rota. | Bestiario importado: sabuesos, esqueletos, arrastrados, pálidos que disparan huesos, licántropos, gólems de huesos, un élite lánguido y un mini-jefe de carne. | **La Parca:** Teletransporte, cortes de guadaña espectral, ráfagas de cráneos e invocación de escolta ósea al 50% de PS. |
| **2. Clínica Abandonada** | Sanatorio clausurado con tráfico de cadáveres frescos. | Zombies putrefactos, corredores mutilados y esqueletos remanentes. | **Paciente Cero:** Zombie que escupe ácido corrosivo y viste la túnica robada de La Parca. |
| **3. La Granja Marchita** | Campo fúnebre con icor y niebla de hierba alta que oculta enemigos. | Espantapájaros poseídos y quimeras de paja. | **El Caballo de Paja:** Doble fase (1: Carga veloz de arrollamiento; 2: Arde en llamas montado por un jinete esqueleto). |
| **4. El Matadero Abisal** | Laboratorio subterráneo con cintas mecánicas y pozas de sangre. | Carniceros desollados, sabuesos veloces y quimeras de carne. | **Don Evaristo, El Cosechador:** Anciano transfigurado en una amalgama necrótica de extremidades. |

---

## 7. Arquitectura del Código y Estructura de Directorios

```text
Bloodstry/
├── conf.lua                     # Configuración de ventana (1280x720 resizable, vsync activado)
├── main.lua                     # Entry point, carga de assets, máquina de estados y loop de juego
├── README.md                    # Guía rápida para ejecución y comandos
├── Implementacion_Tecnica.md    # Este documento
├── lib/
│   ├── classic.lua              # Sistema de clases OOP por metatablas (rxi/classic)
│   └── push.lua                 # Gestor de resolución virtual pixel-perfect (Ulydev/push)
├── assets/
│   ├── fonts/
│   │   └── m5x7.ttf             # Tipografía pixel art nativa (Monospaced & legible)
│   └── sprites/
│       ├── cemetery_tiles.png   # Tileset de lápidas, cruces y árboles secos
│       ├── player_guerrero.png  # Spritesheet animado del Guerrero
│       ├── player_barbaro.png   # Spritesheet animado del Bárbaro
│       ├── player_asesino.png   # Spritesheet animado del Asesino
│       ├── enemy_skeleton.png   # Spritesheet animado de esqueletos (fallback)
│       ├── horror_bestiary.png  # Atlas del bestiario importado (9 criaturas + ángel)
│       ├── boss_la_parca.png    # Spritesheet animado de La Parca
│       └── limbs_and_blood.png  # Extremidades y manchas de sangre para el HUD/suelo
└── src/
    ├── core/
    │   ├── assets.lua           # Gestor central de texturas, quads y fuentes tipográficas
    │   ├── camera.lua           # Cámara con lerp suave, bounds y screenshake procedural
    │   ├── input.lua            # Unificación de teclado WASD, ratón y teclas de acción
    │   ├── spatial_hash.lua     # Cuadrícula espacial O(1) para manejo de hordas masivas
    │   ├── bestiary_atlas.lua   # Rectángulos de frames generados por el importador
    │   └── state_machine.lua    # Administrador de estados de escena
    ├── entities/
    │   ├── entity.lua           # Clase base de entidad (x, y, vida, daño, knockback)
    │   ├── player.lua           # Entidad del jugador, pasivas, 3 clases y armas
    │   ├── enemy.lua            # Bestiario data-driven, animación multi-frame y drops
    │   ├── limb_drop.lua        # Extremidad interactiva tirada en el suelo
    │   ├── soul_drop.lua        # Orbes de experiencia con imán hacia el protagonista
    │   └── bosses/
    │       └── la_parca.lua     # Patrones de ataque, fases e IA del jefe del Stage 1
    ├── combat/
    │   ├── weapon.lua           # Armas primarias de clase (Espada, Alabarda, Dagas)
    │   ├── limb.lua             # Armas de extremidades, durabilidad y Last Ditch
    │   └── projectile.lua       # Proyectiles (cráneos arrojados, ácido, huesos)
    ├── stages/
    │   └── stage1_cemetery.lua  # Bioma de cementerio infinito, decoraciones y oleadas
    ├── progression/
    │   └── skills_data.lua      # Base de datos de bendiciones y pactos malditos
    ├── ui/
    │   ├── hud.lua              # Barras de vida, escudo, indicador de armas y contador
    │   └── upgrade_menu.lua     # Modal con 3 cartas aleatorias y reroll
    ├── vfx/
    │   ├── blood_canvas.lua     # Lienzo estático para hornear miles de manchas de sangre sin lag
    │   └── particles.lua        # Emisores de partículas de hueso, sangre y almas
    └── states/
        ├── class_select_state.lua # Menú inicial de elección de clase
        ├── play_state.lua         # Bucle principal de gameplay y combate
        └── game_over_state.lua    # Pantalla de victoria y muerte con estadísticas
```

---

## 7.1 Pipeline del Bestiario Externo

El bestiario se genera con `tools/import_external.py`, que lee directamente los ZIP de `external_assets/` (no requiere descomprimirlos) y produce dos artefactos versionables:

* `assets/sprites/horror_bestiary.png` — atlas empaquetado por *shelf packing*.
* `src/core/bestiary_atlas.lua` — tabla de rectángulos, FPS y nombres de animación.

El script soporta dos modos porque los packs no comparten formato:

1. **Modo clúster:** `scarymobs` flota poses sueltas en lienzos transparentes. Se hace *flood fill* 8-conectado, se ordenan los componentes por fila y columna, y se recortan los índices pedidos en `ANIMS`.
2. **Modo `anim_dir`:** los monstruos de dado traen un PNG por frame (150×150). Se recortan todos con **una caja común** para que el movimiento relativo no se pierda, y se escalan con `NEAREST` a la mitad.

**Pase de corrupción** (`horror_pass`): desatura al 60 %, oscurece al 94 %, tiñe solo las sombras con violeta (`#0E0A18`) y añade un borde casi negro de 1 px. El resultado comparte la paleta de ceniza/hueso/sangre seca del resto del juego, sin perder el sombreado original del artista.

**Anclaje y animación:**

* Cada frame se dibuja con origen `(w/2, h)`, de modo que los pies coinciden con `entity.y` y el Y-sort sigue funcionando (props incluidos).
* `Enemy.animTime` avanza solo si el set tiene `fps > 0`; si no, la criatura respira con el *wobble* procedural ya existente.
* Los sprites dibujados mirando a la izquierda declaran `flip = true` para que el espejado no invierta la orientación.

**Directorio de oleadas** (`stage1_cemetery.lua`): una tabla de pesos desbloquea criaturas con el tiempo (sabuesos a los 12 s, arrastrados a los 25 s, licántropos a los 45 s, gólems a los 70 s, pálidos a los 80 s, lánguido a los 105 s, tejedor a los 125 s) y un mini-jefe aparece una sola vez a los 112 s. Los comunes siguen siendo el 40-60 % de la horda para no romper el ritmo de sangre.

> **Licencias:** `scarymobs.zip` y `Asset Pack.zip` llegaron sin LICENSE ni autor. Ver `CREDITS.md`; no redistribuir el atlas derivado hasta confirmar su procedencia.

---

## 7.2 Rediseño de los Supervivientes

Los tres jugadores se redibujaron con el mismo registro visual que el bestiario para que no parezcan invitados de otro juego. Siguen generándose con `tools/artgen/characters.py` y se empaquetan en hojas de `128×40` (4 frames de `32×40`).

**Paleta:** constantes propias en `characters.py` (`ASH_*`, `SKIN_M*`, `STEEL_M*`, `LEATH_M*`, `CLOTH_M*`, `BLOOD_M*`). Son versiones desaturadas de la paleta vieja: gris ceniza, hueso sucio, cuero apagado y sangre seca. La armadura ya no es el objeto más brillante de la pantalla.

**Ciclo de caminata de 4 pasos:**

| Frame | Pose | Pie cercano | Pie lejano |
| :---: | :--- | :--- | :--- |
| 1 | Contacto (también *idle*) | Plantado, adelantado | Plantado, atrasado |
| 2 | Paso | Plantado | Elevado 3 px |
| 3 | Contacto inverso | Plantado, atrasado | Plantado, adelantado |
| 4 | Paso | Elevado 3 px | Plantado |

* `NEAR_STANCE`/`FAR_STANCE` hunden el pie adelantado 1 px y `NEAR_LIFT`/`FAR_LIFT` elevan el que pasa; el frame 1 tiene ambos pies en el suelo, así que el personaje no flota cuando está quieto.
* Los brazos oscilan en contrafase (`ARM_SWING`) y el torso sube 1 px en los frames de paso (`BOB`).
* El atlas se sigue dibujando con origen `(16, 40)` y escala 1, igual que antes: no hubo que tocar `player.lua` ni `assets.lua`.
* `Player:draw` usa el frame 1 cuando `moving` es falso y avanza a 8 fps al caminar.

**Siluetas diferenciadas:** el Guerrero lleva yelmo cerrado con visera oscura y dos destellos de ojos, tabardo sangriento y escarcelas; el Bárbaro es más ancho, con piel de animal sobre los hombros, torso desnudo y barba gris (un valor más frío que la piel para que la cara no se funda con el pelaje); el Asesino es más estrecho, con capucha, bufanda y máscara de tela que solo deja ver los ojos.

**Verificación:** `BLOODSTY_AUTOTEST=walk love .` captura cuatro poses sucesivas mientras el jugador camina, útil para revisar el ciclo sin grabar vídeo.

---

## 8. Rendimiento y Optimizaciones Clave

1. **Spatial Hashing Grid (`src/core/spatial_hash.lua`):**
   * En lugar de comparar $500 \times 500 = 250,000$ colisiones por frame ($O(N^2)$), el mapa se divide en celdas de $64 \times 64$ px indexadas por hash numérico.
   * La detección de colisiones, ataques de armas y separación de hordas se resuelve en $O(1)$ por celda, garantizando **60 FPS estables**.
2. **Lienzo de Sangre Horneada (`src/vfx/blood_canvas.lua`):**
   * Las manchas de sangre y fragmentos óseos se dibujan una sola vez sobre un `love.graphics.Canvas` estático de fondo.
   * Esto permite acumular miles de salpicaduras permanentes a lo largo de la partida en **un único draw call**.
3. **Y-Sorting en Vista 2.5D (`src/states/play_state.lua`):**
   * Las entidades se anclan en los pies (`x, y`) y se ordenan por su coordenada vertical antes de dibujarse (`table.sort`), permitiendo que el jugador camine frente o detrás de tumbas y esqueletos con volumen tridimensional.

---

## 9. Análisis del Repositorio de Referencia: `GameOffProject`

El usuario sugirió el repositorio [GameOffProject](https://github.com/Null-Bot9875/GameOffProject.git). Tras clonar e inspeccionar su estructura completa:

* **Naturaleza del Proyecto:** Es un proyecto desarrollado en **Unity (C#)** para una Game Jam (GitHub Game Off).
* **Elementos Valiosos Reutilizables en Bloodsty:**
  1. **Tipografía Pixel Art (`m5x7.ttf`):** Se extrajo de `Unity/Assets/GameData/Art/Font/m5x7.ttf` e integró en Bloodsty. Resuelve al 100% la legibilidad y nitidez de textos en resolución retro.
  2. **Efectos de Animación 2D:** Contiene spritesheets de efectos elementales (*FireEffect, Explosion, Smoke*) y trampas/mecanismos en `Unity/Assets/GameData/Art/Animation/`, que pueden convertirse a spritesheets de LÖVE para los biomas 2 (Clínica) y 3 (Granja).
  3. **Diseño de Interfaz:** Los paneles de pausa, marcos fúnebres y botones de `Unity/Assets/GameData/Art/UI/` sirven de inspiración para los siguientes menús.

---

## 10. Controles del Juego

| Acción | Teclado / Ratón |
| :--- | :--- |
| **Moverse** | `W`, `A`, `S`, `D` o `Flechas` (8 direcciones normalizadas) |
| **Apuntar** | Puntero del Ratón en 360° |
| **Ataque Primario de Clase** | `Clic Izquierdo` o `Espacio` (Uso infinito) |
| **Ataque con Extremidad** | `Clic Derecho` o `K` (Consume durabilidad) |
| **Sacrificio / Last Ditch Attack** | `E`, `Shift Izquierdo` o `Clic Central` (Detona con $3\times$ daño) |
| **Pausar / Reanudar** | `ESC` o `P` |
| **Menú de Mejoras** | `Tab` o `U` (al subir de nivel) |
| **Reroll de Mejoras** | `R` (dentro del menú de cartas) |
| **[Debug] Invocar a La Parca** | `B` (durante la partida) |
| **[Debug] Ganar Nivel Inmediato** | `L` (durante la partida) |

---

## 11. Ejecución del Proyecto

Asegúrate de contar con LÖVE instalado en tu distribución de Linux (`sudo pacman -S love` en Arch/CachyOS).

```bash
cd ~/Projects/Bloodstry
love .
```
