
# Proyecto 2 — Juego de reflejos en FPGA

Proyecto desarrollado para la asignatura Arquitectura de Computadores de la Universidad de los Andes. Consiste en un juego de reflejos implementado sobre Pochoco SoC, utilizando el procesador Espino y una FPGA Lattice iCE40 HX1K Go Board.

El juego, su contador de tiempo y sus principales funcionalidades fueron verificados físicamente en la FPGA.

## 1. Proyecto original

El desarrollo utiliza como base Pochoco SoC:

https://github.com/nic0villegasc/pochoco_soc

Revisión original: `33e8b5ae78faad7a9a36431d5ee8cf145e8573ec`

Se conserva el RTL original del procesador Espino. El proyecto incorpora periféricos, programas Assembly, un ensamblador propio en Python y pruebas para implementar el juego de reflejos.

## 2. Funcionamiento del juego

El juego utiliza los cuatro botones, los cuatro LED y los dos displays de siete segmentos de la Go Board.

Al iniciar, los displays muestran `AA` y esperan que el jugador presione y suelte un botón.

En cada ronda:

1. Los cuatro LED se encienden durante aproximadamente tres segundos.
2. Se selecciona uno de los cuatro LED como objetivo.
3. El jugador debe presionar el botón correspondiente.
4. Se mide y muestra el tiempo de reacción.
5. Una respuesta incorrecta no cuenta como acierto y permite repetir la ronda.

El juego termina después de diez aciertos y muestra el promedio de los tiempos de reacción. La secuencia `AA` anuncia la presentación del promedio final.

Se incorporó además un límite de respuesta de diez segundos (*timeout*).

## 3. Arquitectura

El sistema utiliza Pochoco SoC con el procesador Espino, una memoria para el programa Assembly y periféricos mapeados en memoria.

### Mapa de memoria

| Dirección | Función |
|---|---|
| `0x80000000` | Displays de siete segmentos |
| `0x80000004` | LED |
| `0x80000008` | Botones |
| `0x8000000C` | Contador de ciclos |
| `0x80000010` | Captura del contador asociada a la última escritura de LED |

El programa principal está en `sw/game.s`. El ensamblador propio está en `tools/assembler.py`.

Los detalles de la arquitectura, el contador y el funcionamiento del juego se encuentran en `docs/`.

## 4. Reloj y medición del tiempo

La Go Board proporciona un reloj de 25 MHz. La implementación funcional utiliza un divisor por ocho, de modo que el SoC funciona a 3,125 MHz.

El contador permite medir intervalos de tiempo mediante diferencias entre valores de ciclos. Las constantes del juego fueron ajustadas a la frecuencia utilizada.

La implementación a 3,125 MHz fue comprobada físicamente. La causa exacta de los problemas observados anteriormente a 25 MHz no está confirmada; las pruebas históricas se documentan en `docs/diagnostico.md`.

## 5. Compilación y programación

Los siguientes comandos se ejecutan desde la raíz del repositorio.

### Compilar el juego

```bash
make build-game
```

### Programar la FPGA

Con la Go Board conectada al computador:

```bash
make program-game
```

El comando construye lo necesario y utiliza `iceprog` para programar la placa.

### Ejecutar las pruebas

```bash
make test
```

Para ejecutar las pruebas específicas del juego:

```bash
make test-game
```

También existen objetivos de compilación y prueba para los módulos de diagnóstico, el contador y los programas de ejemplo.

**Importante:** `make` a secas utiliza el programa de prueba predeterminado. Para compilar o cargar el juego debe utilizarse explícitamente `build-game` o `program-game`.

## 6. Ensamblador

El proyecto incluye un ensamblador propio en Python para el subconjunto de instrucciones utilizado por Espino.

El programa principal del juego se encuentra en `sw/game.s` y su representación en código máquina en `sw/game.hex`.

La sintaxis admitida, las restricciones y los ejemplos están documentados en `docs/assembler.md`.

## 7. Verificación

Se realizaron pruebas de simulación y pruebas físicas sobre la Go Board.

Entre las funcionalidades comprobadas físicamente se encuentran:

- Programación de la FPGA mediante `iceprog`, con verificación correcta.
- Lectura de los botones y control de los LED.
- Funcionamiento del contador y de las esperas temporizadas.
- Inicio de partida y reinicio.
- Secuencia completa de diez aciertos.
- Medición y visualización de los tiempos de reacción.
- Cálculo y visualización del promedio final.
- Manejo de respuestas incorrectas.
- Funcionamiento del timeout.

Las pruebas automatizadas y sus archivos se encuentran en `tests/`.

## 8. Organización del repositorio

| Ruta | Contenido |
|---|---|
| `rtl/` | Procesador Espino, SoC, periféricos y módulos Verilog |
| `sw/` | Programas Assembly y archivos hexadecimales |
| `tools/` | Ensamblador propio en Python |
| `tests/` | Pruebas y bancos de simulación |
| `docs/` | Documentación técnica y diagnósticos |
| `Makefile` | Compilación, pruebas y programación |
| `goboard.pcf` | Restricciones de pines de la FPGA |

Los archivos temporales de síntesis y los bitstreams están excluidos del repositorio mediante `.gitignore`. Pueden regenerarse a partir del código fuente y las herramientas de compilación.

## 9. Documentación adicional

- `docs/assembler.md`: funcionamiento del ensamblador.
- `docs/contador.md`: contador de ciclos y medición del tiempo.
- `docs/juego.md`: funcionamiento, registros y pruebas del juego.
- `docs/diagnostico.md`: diagnóstico y pruebas históricas.
- `README_UPSTREAM.md`: documentación del proyecto original.