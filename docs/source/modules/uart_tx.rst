UART TX
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
    - - ``I_BYTE``
      - vector
      - in
      - \-
      - Input byte to send
    - - ``I_BYTE_VALID``
      - std_logic
      - in
      - \-
      - Input byte to send valid flag
    - - ``O_UART_TX``
      - std_logic
      - out
      - 0x1
      - Output UART TX line
    - - ``O_DONE``
      - std_logic
      - out
      - 0x0
      - Byte send flag
