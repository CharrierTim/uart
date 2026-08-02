# NVC Coverage Specification File
# Collect coverage only on RTL sources, exclude testbench and models
#
# Format:
# (+|-)block <ENTITY_NAME>
# (+|-)hierarchy <HIERARCHY>
# (+|-)fsm-type <TYPE>

# Enable coverage on custom IPs
+block clk_rst_manager
+block uart_tx
+block uart_rx
+block uart_axi_lite_bridge
+block spi_master
+block vga_controller
+block top_fpga

# Enable coverage on generated IPs
+block regblock
