UART
====

.. toctree::
    :maxdepth: 1
    :caption: Architecture:

    uart_rx
    uart_tx

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
    - - ``O_UART_TX``
      - std_logic
      - out
      - 0x1
      - Output UART TX line
    - - ``O_READ_ADDR``
      - vector
      - out
      - 0x00
      - Output read address
    - - ``O_READ_ADDR_VALID``
      - std_logic
      - out
      - 0x0
      - Output read address valid flag
    - - ``I_READ_DATA``
      - vector
      - in
      - \-
      - Input read data
    - - ``I_READ_DATA_ADDR_VALID``
      - std_logic
      - in
      - \-
      - Input read data valid
    - - ``O_WRITE_ADDR``
      - vector
      - out
      - 0x00
      - Output write address
    - - ``O_WRITE_DATA``
      - vector
      - out
      - 0x0000
      - Output write data
    - - ``O_WRITE_VALID``
      - std_logic
      - out
      - 0x0
      - Output write valid flag
