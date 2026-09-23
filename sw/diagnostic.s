# Diagnostico progresivo. Cada codigo dura aprox. dos segundos.
.text
.global start
start:
    lui x1, 0x80000
    addi x2, x0, 17
    sw x2, 0(x1) # 11: primera escritura con registros bajos
    addi x2, x0, 1
    sw x2, 4(x1)
    lui x3, 12207
    addi x3, x3, 128 # 50 000 000
    lw x4, 12(x1)
wait1:
    lw x5, 12(x1)
    sub x5, x5, x4
    bltu x5, x3, wait1
    addi x9, x0, 34
    sw x9, 0(x1) # 22: escritura usando x9
    addi x9, x0, 2
    sw x9, 4(x1)
    lw x4, 12(x1)
wait2:
    lw x5, 12(x1)
    sub x5, x5, x4
    bltu x5, x3, wait2
    jal x15, subtest
    addi x9, x0, 68
    sw x9, 0(x1) # 44: retorno JALR correcto
    addi x9, x0, 8
    sw x9, 4(x1)
    lw x4, 12(x1)
wait4:
    lw x5, 12(x1)
    sub x5, x5, x4
    bltu x5, x3, wait4
    addi x9, x0, 170
    sw x9, 0(x1) # AA: espejo de botones para verificar entradas
buttons:
    lw x9, 8(x1)
    sw x9, 4(x1)
    jal x0, buttons
subtest:
    addi x9, x0, 51
    sw x9, 0(x1) # 33: salto JAL correcto
    addi x9, x0, 4
    sw x9, 4(x1)
    lw x4, 12(x1)
wait3:
    lw x5, 12(x1)
    sub x5, x5, x4
    bltu x5, x3, wait3
    jalr x0, 0(x15)
