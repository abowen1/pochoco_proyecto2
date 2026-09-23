# Juego de reflejos RV32E. Ver docs/juego.md para registros y decisiones.
.text
.global start
start:
    lui x1, 0x80000
    lui x2, 76 # TENTH_HI
    addi x2, x2, 1204 # TENTH_LO: 312500 cycles at 3.125 MHz
    lui x3, 2289 # PREP_HI
    addi x3, x3, -744 # PREP_LO: 9375000 cycles at 3.125 MHz
    lui x4, 7629 # LIMIT_HI
    addi x4, x4, 1616 # LIMIT_LO: 31250000 cycles at 3.125 MHz
    addi x8, x0, 1
    sw x0, 4(x1)
    addi x9, x0, 170
    sw x9, 0(x1)
new_game:
    jal x15, release
start_press:
    lw x13, 8(x1)
    beq x13, x0, start_press
    lw x8, 12(x1)
    addi x5, x0, 0 # correct rounds
    addi x6, x0, 0 # sum of raw response cycles
    jal x15, release
round:
    addi x9, x0, 15
    sw x9, 4(x1)
    addi x9, x0, 0
    sw x9, 0(x1)
    lw x12, 16(x1)
prepare:
    lw x14, 12(x1)
    sub x14, x14, x12
    bltu x14, x3, prepare
    jal x15, release
    # Mix human timing into an 11-bit state; use its upper two bits.
    lw x13, 12(x1)
    add x9, x8, x8
    add x9, x9, x9
    add x8, x8, x9
    add x8, x8, x13
    addi x8, x8, 1
    andi x8, x8, 2047
    add x9, x8, x0
    addi x10, x0, 512
    addi x7, x0, 1
select:
    bltu x9, x10, target
    add x7, x7, x7
    sub x9, x9, x10
    jal x0, select
target:
    sw x7, 4(x1)
    lw x12, 16(x1)
response:
    lw x13, 8(x1)
    lw x14, 12(x1)
    sub x14, x14, x12
    bgeu x14, x4, error
    beq x13, x0, response
    bne x13, x7, error
    add x6, x6, x14
    addi x5, x5, 1
    sw x0, 4(x1)
    addi x9, x0, 0
    add x10, x14, x0
response_divide:
    bltu x10, x2, response_ready
    sub x10, x10, x2
    addi x9, x9, 1
    jal x0, response_divide
response_ready:
    jal x15, decimal_display
    jal x15, hold_result
    addi x9, x0, 10
    bne x5, x9, round
    # Announce average with AA, then leave it visible until new press.
    addi x9, x0, 170
    sw x9, 0(x1)
    jal x15, hold_result
    # Average in tenths = floor(sum_cycles / (10 * cycles_per_tenth)).
    add x10, x2, x2
    add x11, x10, x10
    add x11, x11, x11
    add x11, x11, x10
    add x10, x6, x0
    addi x9, x0, 0
average_divide:
    bltu x10, x11, average_ready
    sub x10, x10, x11
    addi x9, x9, 1
    jal x0, average_divide
average_ready:
    jal x15, decimal_display
    jal x0, new_game
error:
    sw x0, 4(x1)
    addi x9, x0, 238
    sw x9, 0(x1)
    jal x15, hold_result
    jal x0, round

# Wait until ALL buttons remain released for 20 ms. x11..x14 scratch.
release:
    lui x11, 15 # RELEASE_HI
    addi x11, x11, 1060 # RELEASE_LO: 62500 cycles at 3.125 MHz
release_restart:
    lw x12, 12(x1)
release_poll:
    lw x13, 8(x1)
    bne x13, x0, release_restart
    lw x14, 12(x1)
    sub x14, x14, x12
    bltu x14, x11, release_poll
    jalr x0, 0(x15)

# Convert 0..99 to two decimal digits (packed BCD), no shifts.
decimal_display:
    addi x10, x0, 10
    addi x11, x0, 0
decimal_tens:
    bltu x9, x10, decimal_ready
    sub x9, x9, x10
    addi x11, x11, 16
    jal x0, decimal_tens
decimal_ready:
    add x9, x9, x11
    sw x9, 0(x1)
    jalr x0, 0(x15)

# Result/error visible for at least one second, then return.
hold_result:
    lui x11, 763 # HOLD_HI
    addi x11, x11, -248 # HOLD_LO: 3125000 cycles at 3.125 MHz
    lw x12, 12(x1)
hold_poll:
    lw x14, 12(x1)
    sub x14, x14, x12
    bltu x14, x11, hold_poll
    jalr x0, 0(x15)
