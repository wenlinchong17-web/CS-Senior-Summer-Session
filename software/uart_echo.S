# UART echo. MMIO: 0x80000000 data, 0x80000004 status
# status bit0 = tx_busy, bit1 = rx_ready
# After reset, send 0x55 once, then CPU-polled echo.

        lui     x1, 0x80000
        addi    x2, x0, 0x55
        sw      x2, 0(x1)
wait_rx:
        lw      x3, 4(x1)
        andi    x3, x3, 2
        beq     x3, x0, wait_rx
        lw      x2, 0(x1)
wait_tx:
        lw      x3, 4(x1)
        andi    x3, x3, 1
        bne     x3, x0, wait_tx
        sw      x2, 0(x1)
        beq     x0, x0, wait_rx
