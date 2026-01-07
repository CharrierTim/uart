# NVC Coverage Specification File
# Collect coverage only on RTL sources, exclude testbench and models

# Enable coverage on main RTL library
+hierarchy LIB_BENCH.TB_TOP_FPGA.DUT.*

# Exclude PLL/clock generation (vendor IP)
-block CLK_WIZ_0

# Exclude testbench model
-hierarchy LIB_BENCH.TB_TOP_FPGA.INST_UART_MODEL.*
