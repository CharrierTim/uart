Top FPGA
========

Description
-----------

Top-Level of the FPGA.

Generics
--------

.. list-table::
    :widths: 25 10 15 60
    :header-rows: 1

    - - Generic Name
      - Type
      - Default Value
      - Description
    - - ``G_GIT_ID_MSB``
      - vector
      - 0x0000
      - 16 MSB of the git ID containing the sources for the bitstream generation
    - - ``G_DIT_ID_LSB``
      - vector
      - 0x0000
      - 16 LSB of the git ID containing the sources for the bitstream generation

Inputs and Outputs
------------------

.. list-table::
    :widths: 25 10 15 15 45
    :header-rows: 1

    - - Port Name
      - Type
      - Direction
      - Default Value
      - Description
    - - ``PAD_I_CLK``
      - std_logic
      - in
      - \-
      - Input clock
    - - ``PAD_RST_N``
      - std_logic
      - in
      - \-
      - Input asynchronous reset, active low
    - - ``PAD_I_UART_RX``
      - std_logic
      - in
      - \-
      - Input UART RX line
    - - ``PAD_O_UART_TX``
      - std_logic
      - out
      - 1
      - Output UART TX line
    - - ``PAD_I_SWITCH_0``
      - std_logic
      - in
      - \-
      - Input switch 0
    - - ``PAD_I_SWITCH_1``
      - std_logic
      - in
      - \-
      - Input switch 1
    - - ``PAD_I_SWITCH_2``
      - std_logic
      - in
      - \-
      - Input switch 2
    - - ``PAD_I_LED_0``
      - std_logic
      - out
      - 1
      - Output LED 0

Overview
--------

The following figure depicts the Top-Level:

.. image:: ../_static/svg/UART-TOP_FPGA.svg

Architecture
------------
