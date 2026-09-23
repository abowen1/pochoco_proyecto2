# Assembler del proyecto

Implementación propia en Python estándar, sin invocar un assembler RISC-V externo.

## Uso

Desde la raíz del proyecto:

```sh
python3 tools/assembler.py sw/buttons_leds.s -o sw/buttons_leds.hex
make test
make build
```

Cuando exista el juego, el mismo programa podrá usarse con `sw/game.s -o sw/game.hex`.

## Sintaxis y alcance

- Registros explícitos `x0` a `x15`; no se aceptan nombres ABI ni registros superiores.
- Instrucciones en minúsculas, operandos separados por comas, comentarios con `#`.
- Enteros decimales o con prefijos `0x`, `0b`, `0o`, opcionalmente con signo.
- Etiquetas: letras, números y guion bajo; no pueden empezar por un número.
- `.text`, `.section .text` y `.global nombre` se aceptan. Solo hay una sección de código que empieza en dirección cero; no hay enlazador.
- No se admiten pseudoinstrucciones, expresiones, constantes simbólicas, macros ni directivas de datos. Para cargar una constante grande se escriben LUI y ADDI explícitamente.
- Máximo 512 palabras, correspondiente a la memoria configurada actualmente. El programa debe reservar por separado cualquier espacio que pretenda usar como datos.

Instrucciones admitidas:

| Grupo | Instrucciones |
|---|---|
| Registros | add, sub, slt, sltu, xor, or, and |
| Inmediatos | addi, slti, sltiu, xori, ori, andi |
| Parte superior | lui, auipc |
| Memoria | lw, sw |
| Condicionales | beq, bne, blt, bge, bltu, bgeu |
| Saltos | jal, jalr |

LW, SW y JALR usan `registro, desplazamiento(base)`. Las direcciones efectivas deben respetar la alineación necesaria; el assembler no conoce el valor de los registros durante la ejecución.

Los inmediatos de ADDI y las demás operaciones I, LW, SW y JALR son valores con signo entre -2048 y 2047. LUI/AUIPC reciben el campo de 20 bits sin signo, de 0 a 0xfffff; no reciben la constante final de 32 bits.

Los saltos aceptan una etiqueta o un desplazamiento numérico en bytes relativo a la dirección de la propia instrucción. Se exige alineación a cuatro bytes porque este core no implementa instrucciones comprimidas. Rango efectivo de ramas: -4096 a 4092; JAL: -1048576 a 1048572. En JALR la alineación del destino también depende del valor del registro y debe garantizarla el programa.

## Dos pasadas

1. Leer las líneas, quitar comentarios y asignar una dirección a cada etiqueta. Cada instrucción ocupa cuatro bytes.
2. Validar operandos y convertir cada instrucción en una palabra. Para saltos a etiquetas se calcula `dirección_destino - dirección_instrucción`.

Los formatos R, I, S, B, U y J se construyen ubicando opcode, registros, funct3/funct7 e inmediato en sus campos. Los negativos se codifican en complemento a dos. Los inmediatos B y J se distribuyen entre campos no contiguos.

## Ejemplo de la prueba física

`lui x2, 0x80000` se convierte en `80000137`:

- Campo inmediato: `0x80000 << 12`.
- Destino x2: `2 << 7`.
- Opcode de LUI: `0x37`.

La etiqueta `loop` está en dirección 16 y `jal x0, loop` en dirección 24. El desplazamiento es -8; la palabra resultante es `ff9ff06f`.

La salida contiene una palabra por línea, ocho dígitos hexadecimales, sin prefijo. Es el formato de palabras que lee `$readmemh`; no es una lista de bytes.

## Validación realizada

Diez pruebas automatizadas cubren: comparación byte a byte con el hexadecimal original de botones/LEDs (guardado como referencia independiente), vectores de codificación, variantes de ALU, recuperación de inmediatos B/J, etiquetas hacia adelante y atrás, límites de inmediatos, entradas inválidas, límite de memoria y conservación del archivo de salida ante errores de sintaxis.

El programa original de siete instrucciones fue verificado físicamente por el usuario. El assembler produce exactamente esas mismas siete palabras. Esto valida esa traducción concreta; todavía no prueba físicamente todas las instrucciones admitidas ni sustituye las futuras pruebas del juego.

Los desplazamientos se rechazan expresamente porque la ALU del RTL base los tiene desactivados. Las instrucciones no incluidas en este subconjunto también se rechazan aunque algunas existan en el decodificador del core.
