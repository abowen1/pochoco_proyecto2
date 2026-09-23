# Contador de ciclos y prueba de tres segundos

## Hardware

La Go Board aporta 25 MHz (40 ns). Un divisor de tres bits genera un único reloj de 3,125 MHz (320 ns) para todo el SoC.
Fuente del fabricante: https://nandland.com/the-go-board/

`pochoco_periph.v` agrega un contador libre de 32 bits. Se pone en cero durante reset y aumenta en uno por flanco ascendente. No se reinicia al comenzar una ronda.

| Dirección | Lectura | Escritura |
|---|---|---|
| 0x8000000c | Contador actual, capturado al atender LW | Sin efecto |
| 0x80000010 | Contador capturado en la última escritura de LEDs | Sin efecto |

Toda escritura a 0x80000004 actualiza los LEDs y captura el contador en el mismo flanco, aunque se escriba el mismo patrón. La captura y la lectura del contador usan el valor previo al incremento del flanco; así ambas referencias son consistentes. El programa puede leer después la captura sin introducir una diferencia entre encender el LED e iniciar la referencia temporal.

Las lecturas siguen el protocolo registrado ya existente de los periféricos. Los offsets 0, 4 y 8 de displays, LEDs y botones se conservan.

## Cálculo del tiempo

- Tres segundos: 9 375 000 ciclos.
- Una décima: 312 500 ciclos.
- Tiempo transcurrido: resta sin signo de 32 bits `actual - inicio`.
- El contador vuelve a cero cada 2^32 ciclos, aproximadamente 1374,390 segundos. La resta modular funciona incluso cruzando ese punto, siempre que el intervalo medido sea menor que una vuelta completa.

El juego futuro deberá definir cómo tratar esperas largas y convertir el resultado a décimas. El contador no implementa por sí solo la lógica del juego ni el promedio.

## Prueba en assembly

`sw/timer_test.s` carga 9 375 000 mediante LUI 2289 y ADDI -744. Enciende los cuatro LEDs, muestra 03, lee el instante capturado y consulta el contador hasta que la diferencia es al menos 9 375 000. Luego apaga los LEDs, muestra 00 y repite otra espera idéntica.

La transición ocurre después de alcanzar el umbral, con unos ciclos extra debidos a las instrucciones de consulta y escritura. La espera es de al menos tres segundos; no se afirma exactitud de flanco a flanco de tres segundos. El número 03 identifica la fase de espera, no es una cuenta regresiva.

## Comandos

```sh
make test
make test-counter
make test-soc
make build-timer
make program-timer
```

El último comando programa la placa. Los anteriores prueban o construyen archivos sin programarla. `make program` conserva la prueba de botones/LEDs como destino predeterminado.

`test-counter` verifica incremento, reset, lecturas, captura simultánea con LEDs, escrituras sin efecto al contador, desbordamiento y lectura de botones. `test-soc` ejecuta el programa en el SoC completo con el modelo de RAM iCE40: solo reduce la constante a 128 ciclos para acelerar la simulación y verifica varias alternancias y su duración. Esa imagen solo está en `build/timer_test_fast.hex`; el diseño para la placa usa `sw/timer_test.hex` con los 75 millones de ciclos reales.

La simulación puede avisar que el archivo no llena las 512 palabras de memoria: el programa usa solo 18 palabras y no accede al resto. No se trata de un fallo de las pruebas.

El flujo de ubicación y ruteo exige conservadoramente 25 MHz. El SoC funciona realmente a 3,125 MHz; el divisor recibe los25MHz de la placa.

## Resultado histórico de implementación a 25 MHz

La prueba ocupa 1013 LUT4, 1216/1280 celdas lógicas (95%) y 12/16 bloques RAM. La frecuencia máxima estimada tras ruteo fue 46,46 MHz, con objetivo de 25 MHz aprobado. Queda poco margen para agregar lógica: volver a medir en cada cambio. La versión anterior falló en comprobaciones físicas posteriores. La prueba de contador mínimo con reloj dividido por ocho sí fue confirmada por el usuario. Los resultados posteriores se registran en `diagnostico.md`.
