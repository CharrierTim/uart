# NVC Coverage Specification File
# Collect coverage only on RTL sources, exclude testbench and models

+hierarchy LIB_BENCH.TB_UART_TX.DUT*
+hierarchy LIB_BENCH.TB_UART_RX.DUT*

-hierarchy LIB_BENCH.TB_UART_TX.INST_UART_SLAVE*
-hierarchy LIB_BENCH.TB_UART_RX.INST_UART_MASTER*
