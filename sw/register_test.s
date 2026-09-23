# Basic original hardware; high registers, JAL/JALR, then buttons.
.text
.global start
start:
    lui x1, 0x80000
    addi x9, x0, 85
    sw x9, 0(x1)
    jal x15, subtest
    addi x10, x0, 102
    bne x14, x10, failed
    addi x9, x0, 170
    sw x9, 0(x1)
buttons:
    lw x13, 8(x1)
    sw x13, 4(x1)
    jal x0, buttons
subtest:
    addi x14, x0, 102
    jalr x0, 0(x15)
failed:
    addi x9, x0, 238
    sw x9, 0(x1)
    jal x0, failed
