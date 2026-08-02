# NVC Coverage Specification File
# Collect coverage only on RTL sources, exclude testbench and models
#
# Format:
# (+|-)block <ENTITY_NAME>
# (+|-)hierarchy <HIERARCHY>
# (+|-)fsm-type <TYPE>

# Enable coverage on DUTs
+hierarchy LIB_BENCH.TB_UART_RX.DUT.*
+hierarchy LIB_BENCH.TB_UART_TX.DUT.*

# Disable coverage on models
-block uart_master
-block uart_slave
