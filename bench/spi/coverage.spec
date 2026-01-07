# NVC Coverage Specification File
# Collect coverage only on RTL sources, exclude testbench and models

+hierarchy LIB_BENCH.TB_SPI_MASTER.DUT.*

-hierarchy LIB_BENCH.TB_SPI_MASTER.INST_SPI_SLAVE_MODEL.*
