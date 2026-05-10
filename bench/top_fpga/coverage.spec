# NVC Coverage Specification File
# Collect coverage only on RTL sources, exclude testbench and models

# Enable coverage on main RTL library
+hierarchy LIB_BENCH.TB_TOP_FPGA.DUT.*

# Excluse OLO library modules (IP)
-block olo_base_reset_gen
-block olo_intf_sync
-block olo_base_cc_status

# Exclude PLL/clock generation (vendor IP)
-block clk_wiz_0

# Exclude testbench model
-hierarchy LIB_BENCH.TB_TOP_FPGA.INST_UART_MODEL.*
