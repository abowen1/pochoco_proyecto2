# Proyecto 2 — base inicial de diagnóstico

Esta carpeta contiene el juego de reflejos, el assembler propio y las pruebas. El juego está validado en simulación y compilado; la prueba física del juego y el informe final están pendientes.

Origen: https://github.com/nic0villegasc/pochoco_soc
Revisión: 33e8b5ae78faad7a9a36431d5ee8cf145e8573ec

## Prueba inicial

`make build` genera el archivo de programación sin tocar la placa.
`iceprog -t` comprueba acceso al programador y lectura del identificador de flash.
`make program` programa el ejemplo original que copia el estado de los botones a los LEDs.

`make assemble` regenera `sw/buttons_leds.hex` con nuestro assembler en Python. `make build` también lo regenera si cambia el assembly o el assembler. `make test` ejecuta las pruebas. La sintaxis, los límites y ejemplos están en `docs/assembler.md`. Los otros ejemplos originales se conservan como referencia y pueden usar sintaxis fuera del subconjunto admitido.

## Cambios de preparación

- Módulo `board_test_top` para seleccionar explícitamente la imagen del ejemplo.
- Makefile con construcción y programación separadas, rutas desde la raíz y dependencia del archivo hexadecimal.
- Restricciones UART quitadas porque el SoC no expone esos puertos.
- RTL original del procesador sin modificaciones.

## Hallazgos confirmados

- Banco de 16 registros, x0 sin escrituras.
- Desplazamientos desactivados en la ALU: no deben usarse.
- MMIO: displays 0x80000000, LEDs 0x80000004, botones 0x80000008.
- Los displays reciben dos dígitos hexadecimales: el juego deberá convertir sus tiempos a decimal antes de mostrarlos.
- Contador de ciclos incorporado en 0x8000000c, con captura de la última escritura de LEDs en 0x80000010. Ver `docs/contador.md`.
- Síntesis de la base original con blink: 888 LUT4 y 12 bloques RAM; ubicación y ruteo completados. Esto no garantiza el espacio ni la temporización del juego final.
- Prueba física completada por el usuario: programación con VERIFY OK; displays 00 y cada botón controla su LED mientras está presionado. iceprog funciona desde la terminal del usuario, aunque no pudo abrir el dispositivo desde la sesión de Codex.

## Siguiente etapa

Botones/LEDs verificados físicamente. Assembler propio con diez pruebas aprobadas y salida idéntica al ejemplo original. Contador y prueba de espera simulados. Siguiente: comprobar los tres segundos físicamente, luego implementar el juego, diez rondas y promedio.

## Prueba del contador

`make test-counter` y `make test-soc` verifican el contador y el programa en simulación. `make build-timer` construye la prueba de tres segundos; `make program-timer` la carga en la placa. Alterna LEDs encendidos/display 03 y LEDs apagados/display 00, cada fase de al menos tres segundos. La comprobación física de esta prueba fue completada por el usuario: alternancia 03/00 y LEDs correcta.

## Juego de reflejos

`make build-game` compila el juego y `make program-game` lo programa. Al inicio aparece AA: presionar y soltar un botón. Después de diez aciertos, AA anuncia el promedio final. Ver `docs/juego.md` para controles, unidades, registros, pruebas y la decisión añadida de timeout a los diez segundos. `make test-game` verifica el juego completo en simulación acelerada.

## Frecuencia actual

La placa entrega25MHz y el SoC usa3,125MHz mediante un divisor por ocho. El contador a esta frecuencia fue comprobado físicamente; el juego completo aún requiere prueba física. Las constantes de espera, décimas y límite fueron recalculadas; `make test` comprueba su consistencia. Ver `docs/diagnostico.md` para las pruebas fallidas y la evidencia disponible; la causa exacta del fallo a25MHz todavía no está confirmada.
