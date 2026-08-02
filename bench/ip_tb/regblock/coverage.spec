# NVC Coverage Specification File
# Collect coverage only on RTL sources, exclude testbench and models
#
# Format:
# (+|-)block <ENTITY_NAME>
# (+|-)hierarchy <HIERARCHY>
# (+|-)fsm-type <TYPE>

# Enable coverage on DUT
+hierarchy LIB_BENCH.TB_REGBLOCK.DUT.*
