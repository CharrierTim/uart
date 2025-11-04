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
    - - ``G_SAMPLING_RATE``
      - positive
      - 0d16
      - Sampling rate (number of clock cycles per bit)

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
      - vector[7:0]
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

Architecture
------------

The UART receiver must synchronize to incoming data, sample at the correct time, handle
noise, and detect framing errors. The receiver uses oversampling, digital filtering, and
majority voting to ensure reliable data reception.

Oversampling Clock
~~~~~~~~~~~~~~~~~~

The receiver generates an internal sampling clock that runs at a multiple of the baud
rate (configured by ``G_SAMPLING_RATE``, typically 16).

The oversampling clock divider generates a tick (``rx_baud_tick``) at the oversampling
rate. For example, with 16× oversampling and 115200 baud:

.. math::

    f_{oversample} = 115200 \times 16 = 1.8432\text{ MHz}

The clock divider is enabled during active reception and reset during idle to ensure
proper synchronization with incoming data.

.. note::

    The oversampling rate is configurable via the ``G_SAMPLING_RATE`` generic. A higher
    rate provides better noise immunity but requires a faster system clock.

Input Synchronization and Filtering
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The asynchronous UART RX input must be properly synchronized to prevent metastability
and filtered to remove noise.

**Synchronization Chain**

A 5-stage shift register processes the incoming signal:

.. code-block:: none

    Stage 0-1: Metastability resolution (2 flip-flops)
    Stage 2-4: Digital filtering (3 consecutive samples)

    I_UART_RX → [FF] → [FF] → [Filter] → [Filter] → [Filter] → i_uart_rx_filtered

**Digital Filtering Logic**

The filter uses a simple majority voting algorithm on the last 3 stages:

.. list-table:: Digital Filter Truth Table
    :widths: 40 30 30
    :header-rows: 1

    - - Input Samples (bits 4:2)
      - Filtered Output
      - Description
    - - ``000``
      - ``0``
      - All zeros → output low
    - - ``111``
      - ``1``
      - All ones → output high
    - - Other patterns
      - Keep previous value
      - Insufficient agreement

This filtering approach requires **3 consecutive identical samples** before changing the
output, providing excellent noise rejection.

.. important::

    The first 2 bits of the shift register are potentially metastable and must NOT be
    used for any logic decisions. Only bits [4:2] are used for filtering. (I made this
    mistake)

**Edge Detection**

A delayed version of the filtered signal (``i_uart_rx_filtered_d1``) is maintained to
detect edges:

- **Falling edge** (``1`` → ``0``): Indicates start bit detection
- **Rising edge** (``0`` → ``1``): Used for stop bit validation

Oversampling and Bit Timing
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Each UART bit period is divided into multiple sampling intervals. With 16× oversampling,
each bit period contains 16 ticks.

**Tick Counting**

The ``oversampling_count`` counter tracks the position within the current bit period:

- Increments on each ``rx_baud_tick``
- Resets to 0 after reaching ``C_OVERSAMPLE_MAX`` (15 for 16× oversampling)
- When it wraps, one complete bit period has elapsed

**Visual Timing Diagram**

.. code-block:: none

    Idle/Previous Bit                           Current Data Bit                           Next Bit
         (High)                                     (Low)                                   (High)
    ________________                                                                 __________________
                    \                                                               /
                     \                                                             /
                      \                                                           /
                       \_________________________________________________________/

    Tick:                 0  1  2  3  4  5  6  7  8  9  10  11  12  13  14  15
    Samples:                                   ^  ^  ^
                                           Sample Points (Ticks 7, 8, 9)

    Legend:
    - 16 ticks per bit period (numbered 0-15)
    - Samples taken at ticks 7, 8, 9 (center of bit period)
    - Provides maximum timing margin from bit edges

**Sample Point Selection**

The mid-bit sample point is calculated as:

.. math::

    \text{mid bit} = \frac{G\_BAUD\_RATE\_BPS - 1}{2} = \frac{15}{2} = 7

Three consecutive samples are taken at ticks mid bit - 1, mid bit and mid bit + 1.

Majority Voting
~~~~~~~~~~~~~~~

To determine the actual value of each received bit, the receiver uses majority voting on
three consecutive samples taken at the center of the bit period.

**Sampling Process**

At each bit center, three samples are captured:

.. list-table:: Sample Timing
    :widths: 30 70
    :header-rows: 1

    - - Tick Number
      - Action
    - - 7 (C_MID_BIT_SAMPLE_POINT - 1)
      - Capture ``uart_rx_mid_bit_samples(0)``
    - - 8 (C_MID_BIT_SAMPLE_POINT)
      - Capture ``uart_rx_mid_bit_samples(1)``
    - - 9 (C_MID_BIT_SAMPLE_POINT + 1)
      - Capture ``uart_rx_mid_bit_samples(2)``

**Voting Logic**

The sampled bit value is determined by majority vote:

.. list-table:: Majority Voting Truth Table
    :widths: 30 20 50
    :header-rows: 1

    - - Samples [2:0]
      - Result
      - Description
    - - ``000``
      - ``0``
      - Clean zero (3/3 agree)
    - - ``001``
      - ``0``
      - Majority zero (2/3 agree)
    - - ``010``
      - ``0``
      - Majority zero (2/3 agree)
    - - ``100``
      - ``0``
      - Majority zero (2/3 agree)
    - - ``111``
      - ``1``
      - Clean one (3/3 agree)
    - - ``110``
      - ``1``
      - Majority one (2/3 agree)
    - - ``101``
      - ``1``
      - Majority one (2/3 agree)
    - - ``011``
      - ``1``
      - Majority one (2/3 agree)

.. note::

    This majority voting scheme provides immunity against single-tick noise spikes,
    significantly improving reception reliability in noisy environments.

Bit Counter
~~~~~~~~~~~

The ``data_bit_count`` counter tracks how many data bits have been received:

- Initialized to 0 at the start of data reception
- Increments by 1 after each complete bit period (when ``oversampling_count`` wraps)
- Only increments in the ``STATE_DATA_BITS`` state
- After reaching 7 (8 bits total: 0-7), transitions to stop bit state

This ensures exactly 8 data bits are received per frame.

Data Shift Register
~~~~~~~~~~~~~~~~~~~

The ``received_byte`` register accumulates the incoming data bits.

**Shifting Operation**

Data is received **LSB first** (UART standard). Each new bit is shifted in from the left
(MSB side):

.. code-block:: vhdl

    received_byte <= uart_rx_sampled_bit & received_byte(7 downto 1);

**Example Reception Sequence**

Receiving byte ``0x5A`` (``0b01011010``):

.. code-block:: none

    Initial:      received_byte = xxxxxxxx

    Bit 0 (D0=0): received_byte = 0xxxxxxx  (shift in 0)
    Bit 1 (D1=1): received_byte = 10xxxxxx  (shift in 1)
    Bit 2 (D2=0): received_byte = 010xxxxx  (shift in 0)
    Bit 3 (D3=1): received_byte = 1010xxxx  (shift in 1)
    Bit 4 (D4=1): received_byte = 11010xxx  (shift in 1)
    Bit 5 (D5=0): received_byte = 011010xx  (shift in 0)
    Bit 6 (D6=1): received_byte = 1011010x  (shift in 1)
    Bit 7 (D7=0): received_byte = 01011010  (shift in 0)

    Final:        received_byte = 0x5A ✓

The byte is complete after 8 bits and ready to be latched to the output if the stop bit
is valid.

FSM
~~~

The UART RX FSM is defined as:

.. image:: ../_static/svg/UART-UART-RX_FSM.svg

Where the following transitions are defined:

.. list-table:: FSM transitions
    :widths: 25 75
    :header-rows: 1

    - - Transition
      - Condition(s)
    - - T0
      - ``i_uart_rx_filtered_d1 = 1`` **AND** ``i_uart_rx_filtered = 0`` (falling edge
        on the UART line)
    - - T1
      - ``rx_baud_tick = 1`` **AND** ``oversampling_count = 15`` **AND**
        ``uart_rx_sampled_bit = 1`` (start bit = 1)
    - - T2
      - Automatic
    - - T3
      - ``rx_baud_tick = 1`` **AND** ``oversampling_count = 15`` **AND**
        ``uart_rx_sampled_bit = 0`` (start bit = 0)
    - - T4
      - ``rx_baud_tick = 1`` **AND** ``oversampling_count = 15`` **AND**
        ``data_bit_count = 7``
    - - T5
      - ``rx_baud_tick = 1`` **AND** ``oversampling_count = 15`` **AND**
        ``uart_rx_sampled_bit = 0`` (stop bit = 0)
    - - T6
      - Automatic
    - - T7
      - ``rx_baud_tick = 1`` **AND** ``oversampling_count = 15`` **AND**
        ``uart_rx_sampled_bit = 1`` (stop bit = 1)
    - - T8
      - Automatic
