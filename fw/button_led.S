    .section .text
    .globl _start
_start:
    lui     t0, 0x40000          # GPIO base 0x40000000
    lw      t1, 4(t0)            # read GPIO_DIR
    ori     t1, t1, 0x2          # bit 1 = output
    sw      t1, 4(t0)            # write GPIO_DIR
main_loop:
    lw      t1, 0(t0)            # read GPIO_DATA
    andi    t2, t1, 0x1          # isolate button
    beq     t2, zero, main_loop  # wait for press
    lw      t1, 0(t0)
    xori    t1, t1, 0x2          # toggle LED bit
    sw      t1, 0(t0)
    addi    t3, zero, 100        # delay
delay_loop:
    addi    t3, t3, -1
    bne     t3, zero, delay_loop
wait_release:
    lw      t1, 0(t0)
    andi    t2, t1, 0x1
    bne     t2, zero, wait_release
    jal     zero, main_loop
