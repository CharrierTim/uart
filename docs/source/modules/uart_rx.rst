UART RX
=======

Description
-----------

Generics
--------

.. list-table::
    :widths: 25 10 15 60
    :header-rows: 1

    - - Generic Name
      - Type
      - Default Value
      - Description
    - - ``G_CLK_FREQ_HZ``
      - positive
      - 0d50\_000\_000
      - Clock frequency in Hz of ``CLK``
    - - ``G_BAUD_RATE_BPS``
      - positive
      - 0d115\_200
      - Baud rate in bps

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
    - - ``CLK``
      - std_logic
      - in
      - \-
      - Input clock
    - - ``RST_N``
      - std_logic
      - in
      - \-
      - Input asynchronous reset, active low
    - - ``I_UART_RX``
      - std_logic
      - in
      - \-
      - Asynchronous input UART RX line
    - - ``O_BYTE``
      - vector
      - out
      - 0x00
      - Output byte
    - - ``O_BYTE_VALID``
      - std_logic
      - out
      - 0x0
      - Output byte valid flag
    - - ``O_START_BIT_ERROR``
      - std_logic
      - out
      - 0x0
      - Output start bit error flag
    - - ``O_STOP_BIT_ERROR``
      - std_logic
      - out
      - 0x0
      - Output stop bit error flag
