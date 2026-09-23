# Prueba del contador: LEDs encendidos 3 s, apagados 3 s, repetir.
# Reloj 25 MHz: 3 segundos = 75 000 000 ciclos.
# Sin shifts, pseudoinstrucciones ni assembler externo.
.text
.global start
start:
    lui x1, 0x80000
    lui x2, 18311 # WAIT_HI
    addi x2, x2, -1856 # WAIT_LO
    addi x3, x0, 15
on:
    sw x3, 4(x1)
    addi x4, x0, 3
    sw x4, 0(x1)
    lw x5, 12(x1)
wait_on:
    lw x6, 12(x1)
    sub x7, x6, x5
    bltu x7, x2, wait_on
    sw x0, 4(x1)
    sw x0, 0(x1)
    lw x5, 12(x1)
wait_off:
    lw x6, 12(x1)
    sub x7, x6, x5
    bltu x7, x2, wait_off
    jal x0, on
