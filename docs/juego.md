# Juego de reflejos — primera versión para prueba física

## Uso

```sh
make test
make test-counter
make test-soc
make test-game
make build-game
make program-game
```

`program-game` carga la FPGA. Los otros comandos no la programan. El punto de entrada es `rtl/game_top.v`, que instancia Pochoco SoC con `sw/game.hex`. El programa se regenera con `python3 tools/assembler.py sw/game.s -o sw/game.hex` usando el assembler propio.

## Secuencia visible

1. Al encender: AA y LEDs apagados. Presionar y soltar cualquier botón inicia una partida.
2. Cuatro LEDs encendidos durante al menos tres segundos. Los displays muestran 00. Si hay un botón mantenido, se espera hasta que todos estén liberados durante 20 ms.
3. Solo un LED queda encendido. Presionar su botón asociado.
4. Acierto: LEDs apagados; resultado durante al menos un segundo. Los dos dígitos son décimas de segundo: 07 = 0,7 s; 12 = 1,2 s. Se trunca la fracción de décima, no se redondea al más cercano.
5. Error: EE durante al menos un segundo; se repite la ronda actual, conservando los aciertos y la suma anteriores. Dos botones detectados simultáneamente también son error.
6. Después del décimo acierto: se muestra su tiempo, luego AA durante un segundo, y finalmente el promedio en décimas. El promedio permanece con LEDs apagados. Presionar y soltar un botón inicia otra partida.

## Decisión de rango que debe revisarse con el profesor

Esta primera versión limita cada intento a menos de diez segundos para poder mostrar todos sus resultados como 00..99 décimas en dos displays. Llegar a diez segundos produce EE y repite la ronda sin descontar aciertos. El enunciado no especifica un timeout: es una decisión añadida de esta implementación, no un requisito del profesor. Si se requiere aceptar respuestas arbitrariamente largas, hay que acordar otra representación y ampliar la acumulación de tiempos; no basta con quitar el límite.

## División hardware/software

Hardware reutilizado: Espino Core, RAM, SPI, decodificador de displays y registros de periféricos.

Hardware agregado: contador de ciclos de 32 bits, captura del contador en cada escritura de LEDs y dos etapas de sincronización de botones. Toda la secuencia, selección del LED, espera de tres segundos, conteo de aciertos, división, conversión decimal y promedio se ejecutan en assembly. No se agregaron instrucciones a la ALU ni unidades de multiplicación/división.

Los botones son asíncronos al reloj. Dos flip-flops por entrada reducen el riesgo de metastabilidad. No se retarda la primera pulsación con un filtro de 20 ms; se acepta la primera muestra no nula. La liberación se verifica estable durante 20 ms antes de otra ronda. Esto evita reutilizar un botón mantenido; no distingue pulsaciones que comienzan en instantes diferentes aunque un humano las considere simultáneas.

## Medición

Oscilador de placa de 25 MHz dividido por ocho: el SoC completo funciona a 3,125 MHz, documentado en `contador.md`. El contador leído en 0x8000000c nunca se detiene. Cada escritura a LEDs en 0x80000004 captura el contador en 0x80000010 en el mismo flanco que cambia el patrón.

El programa resta a la lectura actual la captura del LED objetivo. La lectura se hace por polling después de leer botones. El final de la medición incluye el pequeño retardo del sincronizador y de las instrucciones de consulta, no es una captura hardware del instante físico del botón. La referencia inicial sí coincide con el cambio de LED.

Una décima equivale a 312 500 ciclos. Las divisiones son restas sucesivas; por el límite de diez segundos necesitan menos de 100 restas para mostrar un resultado. La conversión a BCD resta diez y suma 16 al dígito superior, sin desplazamientos.

La suma conserva los ciclos originales de cada acierto. Promedio mostrado = floor(suma_ciclos / 3 125 000), equivalente a promediar diez respuestas y convertir a décimas. No promedia los valores ya truncados de cada pantalla. Diez respuestas menores de 31 250 000 ciclos acumulan menos de 312 500 000, dentro del rango sin signo de 32 bits; por eso se usa BLTU en comparaciones.

La resta de tiempos es modular a 32 bits, correcta al cruzar el desbordamiento del contador siempre que el intervalo sea menor que una vuelta. Los intentos están limitados a diez segundos; las otras esperas son mucho menores que los aproximadamente 1374,4 segundos de una vuelta.

## Selección del LED

La pulsación de inicio proporciona una semilla del contador libre. En cada ronda se actualiza `semilla = (5*semilla + contador_actual + 1) & 2047`. Se obtiene el índice de los dos bits superiores de ese estado de 11 bits dividiendo por 512 mediante restas (a lo sumo tres). Cada resta duplica la máscara para obtener 1, 2, 4 u 8. Así la selección no depende únicamente de los dos bits más rápidos del contador. Las pulsaciones y sus duraciones afectan la lectura del contador. Pueden repetirse LEDs entre rondas, lo cual es válido.

Es un generador sencillo para un juego, no criptográfico ni una garantía estadística de uniformidad. No usa una tabla fija de diez objetivos. Las pruebas con tiempos de inicio distintos verifican si cambian las secuencias; la percepción de variedad también debe comprobarse en la placa.

## Registros

| Registro | Uso |
|---|---|
| x0 | Cero |
| x1 | Base MMIO 0x80000000 |
| x2 | Ciclos por décima |
| x3 | Ciclos de preparación |
| x4 | Límite de un intento |
| x5 | Aciertos, de 0 a 10 |
| x6 | Suma de ciclos correctos |
| x7 | Máscara LED objetivo |
| x8 | Estado de selección pseudoaleatoria |
| x9..x11 | Conversión, divisiones y temporales |
| x12 | Instante inicial de medición o espera |
| x13 | Botones o lectura temporal |
| x14 | Tiempo transcurrido |
| x15 | Retorno de subrutinas |

Las subrutinas no se llaman entre sí; pueden compartir x15 sin pila. No hay escrituras a RAM de datos. El juego ocupa 107 palabras de las 512 configuradas.

## Validación y límites

Simulación del SoC completo con programa generado por el assembler propio. Se reducen únicamente las constantes temporales para acelerar la prueba; se conservan las diez rondas. Incluye botones mantenidos, tiempos variables, errores después de varios aciertos, pulsación múltiple, timeout, conservación de aciertos, comprobación exacta de cada resultado decimal y promedio, persistencia del promedio y comienzo de otra partida.

Los resultados de recursos anteriores correspondían a la versión de 25 MHz que falló físicamente. La nueva versión divide el reloj por ocho; los resultados de su compilación se registran en `diagnostico.md`. El objetivo de ruteo se mantiene conservador en 25 MHz aunque el SoC opere a 3,125 MHz.

El contador a 3,125 MHz fue confirmado físicamente por el usuario antes y después de reconectar USB. Esto no confirma aún el juego completo. Pendiente: prueba física del juego, validación de variedad entre partidas y revisión de la decisión de timeout. El informe PDF final todavía no se ha preparado.

Dos ejecuciones de simulación con instantes de inicio diferentes produjeron las secuencias de máscaras `4122122842122` y `1188282128224`, ambas con los cuatro objetivos presentes. Esto no reemplaza la comprobación de variedad física.
