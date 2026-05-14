# NVC Coverage Specification File
# Collect coverage only on RTL sources, exclude testbench and models

# Enable coverage on main RTL library
+hierarchy LIB_BENCH.TB_TOP_FPGA.DUT.*

# Excluse OLO library modules (IP)
-hierarchy LIB_BENCH.TB_TOP_FPGA.DUT.INST_OLO_BASE_SYS_RESET_GEN.*
-hierarchy LIB_BENCH.TB_TOP_FPGA.DUT.INST_OLO_BASE_VGA_RESET_GEN.*
-hierarchy LIB_BENCH.TB_TOP_FPGA.DUT.INST_VGA.INST_OLO_BASE_CC_STATUS.*

# Exclude PLL/clock generation (vendor IP)
-block clk_wiz_0
