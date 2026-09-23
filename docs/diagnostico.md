# Diagnóstico del arranque físico

La programación del juego reportó VERIFY OK, pero el usuario observó LEDs apagados y display 00 incluso después de reconectar alimentación. La simulación RTL, la netlist sintetizada y la reconstrucción del bitstream muestran AA. La causa física todavía no está confirmada.

`make program-diagnostic` carga una prueba con el mismo hardware y otro programa:

- 11: primera escritura usando registros bajos.
- 22: escritura con x9.
- 33: llamada JAL con retorno en x15.
- 44: retorno JALR completado.
- AA: prueba terminada; botones copiados a LEDs.

Cada etapa numerada espera al menos dos segundos. Anotar todas las etapas visibles o si se mantiene 00. El diagnóstico no es una corrección del fallo ni el juego final.

## Actualización: también falla la referencia anterior

El usuario informa que el diagnóstico queda en 00 y que volver a cargar directamente `build/timer_test_top.bin` tampoco recupera la alternancia que antes funcionaba. Se verificaron los SHA-256 de las copias del Escritorio y de trabajo: coinciden con los archivos originales. Por tanto, todavía no hay evidencia suficiente para culpar al nuevo assembly o al sincronizador de botones. Pendiente comprobar de nuevo la primera prueba de botones/LEDs tras cargar y reconectar.

Los documentos en `docs/` son explicaciones y registros de pruebas; no forman parte del circuito ni del programa ejecutado. Las simulaciones aprobadas no equivalen a validación física del juego.

## Referencia recuperada y prueba de registros

El usuario volvió a cargar `board_test_top.bin`, reconectó USB y confirmó que botones/LEDs funcionan. Se preparó `register_test_top.bin`: sus líneas de configuración FPGA fuera de los bloques RAM son idénticas a las del archivo funcional (comparación de 17984 líneas). Solo cambia el contenido de memoria. La simulación de la netlist sintetizada muestra AA. En la placa, AA y botones funcionales indicarían éxito; 55 indicaría llegada a la primera escritura; EE indica retorno con resultado inesperado. La prueba física está pendiente.

## Prueba de registros confirmada físicamente

El usuario cargó register_test_top.bin: AA aparece y los botones controlan los LEDs. Se confirman registros altos, JAL/JALR y escritura a displays en el hardware básico.

Se prepara counter_minimal_top.bin desde el RTL original, agregando únicamente un contador libre en 0x8000000c. No incluye captura de LED ni sincronizador. Usa un programa de 18 instrucciones que alterna 03/00 y LEDs cada tres segundos, tomando el inicio mediante LW del contador. Por ello es una prueba aislada, no la implementación temporal final del juego. Simulación acelerada aprobada; 1161/1280 celdas, objetivo 25 MHz aprobado. Comprobación física pendiente.

## Contador mínimo falla; indicadores internos

El usuario confirma counter_minimal_top.bin permanece en 00. La simulación con lecturas simultáneas a escritura de RAM marcadas desconocidas tampoco reprodujo el fallo. Se prepara startup_probe_top.bin con el mismo programa del contador y LEDs dedicados: LED1 parpadea desde un contador independiente del reset; LED2 indica reset liberado; LED3 retiene evidencia de una solicitud de instrucción en dirección distinta de cero; LED4 retiene evidencia de una escritura a periféricos. Estos indicadores no prueban por sí solos ejecución correcta; permiten localizar dónde se detiene. Los displays permanecen bajo control del procesador. No es el juego ni una corrección confirmada. Simulación de netlist aprobada: display 03 y LEDs 2/3/4 encendidos al inicio. Frecuencia objetivo 25 MHz aprobada.

## Resultado de indicadores y captura de escritura

Startup probe físico: display 00, LED1 parpadea, LEDs2/3 encendidos, LED4 apagado. Confirma reloj/reset/solicitud de instrucciones, pero no escritura a periféricos. No prueba que la CPU se haya detenido: podría escribir en RAM por dirección incorrecta.

Execution probe captura la primera transacción de escritura de cualquier dirección, no solo MMIO. Sin pulsar muestra dirección [31:24], o EE si no hubo escritura. Botón1 muestra dirección [7:0]; botón2 dato [7:0]; botón3 muestra dirección de fetch [9:2] muestreada al ciclo 1023. Datos de escritura quedan congelados. Simulación netlist: 80, 04, 0F para dirección alta, baja y dato. Objetivo25MHz aprobado. Pendiente resultado físico.

## Escritura física incorrecta confirmada

Execution probe físico: sin pulsar 00; botón1 04; botón2 sin cambio (00); botón3 11; LED1 parpadea y LEDs2/3/4 encendidos. Primera escritura con byte alto de dirección 00, byte bajo04 y dato bajo00, frente a los esperados80/04/0F. Los bytes centrales de la dirección no se capturaron: no afirmar que sean cero. Se añadió instruction_probe.bin: el botón4 muestra instr_rdata[31:24] capturado mientras instr_addr=4 e instr_req=0, correspondiente al primer LUI en la prueba de simulación. Valor esperado80. Comparación física pendiente.

## Captura de instrucción física y corrección candidata

Instruction probe físico: 00 sin pulsar, 04 con botón1, 00 con botón2, 0E tras programar/11 tras reconectar con botón3, 00 con botón4. No se observó el byte80 esperado de la primera instrucción. Esta captura puede depender del arranque; no prueba por sí sola corrupción del contenido de RAM.

Se preparó memory_stable.bin: mantiene la última dirección de instrucción solicitada mediante un registro y lee continuamente esa dirección mientras la CPU se pausa. La RAM inferida tiene RCLKE constante1 en todos los puertos de lectura. El programa es la misma prueba del contador mínimo. Simulación acelerada y arranque de netlist aprobados; 1143/1280 celdas; objetivo25MHz aprobado. Es una corrección candidata, no una causa confirmada. No se aplicó aún a los archivos principales del juego. Comprobación física pendiente.

## Lectura estable no corrige; prueba de frecuencia

El usuario confirma memory_stable.bin permanece en00 antes y después de reconectar. No se incorpora ese cambio como solución del proyecto.

slow_clock.bin parte del contador mínimo con su RAM original; divide el reloj de25MHz por8 para todo el SoC (3,125MHz), y usa9 375 000 ciclos para los3segundos. La frecuencia del reloj es la variable de prueba; al dividirlo también aumenta la duración física del reset de15ciclos. Simulación de espera escalada y ubicación/ruteo aprobados. Todavía no identifica la causa ni es una corrección confirmada.

## Reloj reducido confirmado; juego adaptado

El usuario confirmó slow_clock.bin: alternancia03/00 y LEDs correcta antes y después de reconectar. Esto muestra que la modificación del reloj cambia el comportamiento; no prueba por sí sola la causa exacta (también cambia el emplazamiento y la duración física del reset).

Se aplicó el divisor por8 a la versión completa del SoC y se ajustaron todas las constantes del juego:312500ciclos/décima,9375000preparación,31250000límite,62500liberación,3125000resultado. Pruebas del assembler, coherencia de constantes, contador, espera y juego completo aprobadas. Recurso juego:991LUT4,1208/1280celdas,12RAM; objetivo conservador25MHz aprobado; funcionamiento real3,125MHz. Prueba física del juego aún pendiente. No se incorporó el cambio de RAM memory_stable que no solucionó el fallo.
