UART PROJECT
============

Documentation of the UART Project.

Tools Versions
--------------

- **NVC**: ``nvc 1.18.1 (Using LLVM 18.1.3)``
- **Vunit**: ``commit 4e30fa124ea84609af0f957dbc55b82adaed1d76``
- **VSG**: ``VHDL Style Guide (VSG) version: 3.35.0``
- **Vivado**: ``2025.1``

Inputs and Outputs
------------------

============== ========== ========= ======== ====
Pin Name       Pin Number Direction Resistor Slew
============== ========== ========= ======== ====
PAD_I_CLK      Y9         in        \-       \-
PAD_RST_N      BTN6       in        \-       \-
PAD_I_UART_RX  Y11        in        \-       \-
PAD_O_UART_TX  AA11       out       \-       \-
PAD_I_SWITCH_0 F22        in        \-       \-
PAD_I_SWITCH_1 G22        in        \-       \-
PAD_I_SWITCH_2 H22        in        \-       \-
PAD_O_LED_0    T22        out       \-       \-
============== ========== ========= ======== ====

.. toctree::
    :maxdepth: 2
    :caption: Architecture:

    modules/top_fpga
    modules/resync_slv
    modules/regfile
    modules/uart
