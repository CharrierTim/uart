UART PROJECT
============

Documentation of the UART Project.

Tools Versions
--------------

- **NVC**: ``nvc 1.18.1 (Using LLVM 18.1.3)``
- **Vunit**: ``commit 4e30fa124ea84609af0f957dbc55b82adaed1d76``
- **VSG**: ``VHDL Style Guide (VSG) version: 3.35.0``
- **Vivado**: ``2025.1``

Clocking Configuration
----------------------

The FPGA uses a PLL (``clk_wiz_0``) to generate internal clocks from the input clock.

.. raw:: html
    :file: _static/html/clock_configuration.html

Inputs and Outputs
------------------

The FPGA defines the following inputs/outputs:

============== ========== ========= ======== ==== ==========
Pin Name       Pin Number Direction Resistor Slew IOSTANDARD
============== ========== ========= ======== ==== ==========
PAD_I_CLK      Y9         in        \-       \-   LVCMOS33
PAD_RST_H      BTN6       in        \-       \-   LVCMOS18
PAD_I_UART_RX  Y11        in        PULL-UP  \-   LVCMOS33
PAD_O_UART_TX  AA11       out       PULL-UP  \-   LVCMOS33
PAD_I_SWITCH_0 F22        in        \-       \-   LVCMOS18
PAD_I_SWITCH_1 G22        in        \-       \-   LVCMOS18
PAD_I_SWITCH_2 H22        in        \-       \-   LVCMOS18
PAD_O_LED_0    T22        out       \-       \-   LVCMOS33
============== ========== ========= ======== ==== ==========

.. toctree::
    :maxdepth: 2
    :caption: Architecture:

    modules/top_fpga
    modules/resync_slv
    modules/regfile
    modules/uart
