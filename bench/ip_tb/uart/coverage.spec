# NVC Coverage Specification File
# Collect coverage only on RTL sources, exclude testbench and models

+hierarchy LIB_BENCH.TB_UART_RX.DUT.*
+hierarchy LIB_BENCH.TB_UART_TX.DUT.*

-block uart_master
-block uart_slave
