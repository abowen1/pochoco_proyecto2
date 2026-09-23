# Prueba del contador: LEDs encendidos 3 s, apagados 3 s, repetir.
# Reloj 3.125 MHz: 3 segundos = 9 375 000 ciclos.
# Sin shifts, pseudoinstrucciones ni assembler externo.
.text
.global start
start:
    lui x1, 0x80000
    lui x2, 2289 # WAIT_HI
    addi x2, x2, -744 # WAIT_LO
    addi x3, x0, 15
on:
    sw x3, 4(x1)
    addi x4, x0, 3
    sw x4, 0(x1)
    lw x5, 16(x1)
wait_on:
    lw x6, 12(x1)
    sub x7, x6, x5
    bltu x7, x2, wait_on
    sw x0, 4(x1)
    sw x0, 0(x1)
    lw x5, 16(x1)
wait_off:
    lw x6, 12(x1)
    sub x7, x6, x5
    bltu x7, x2, wait_off
    jal x0, on
