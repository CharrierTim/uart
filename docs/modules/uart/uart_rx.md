# UART RX

## Description

## Generics

| Generic Name      | Type     | Default Value | Description                                    |
| ----------------- | -------- | ------------- | ---------------------------------------------- |
| `G_CLK_FREQ_HZ`   | positive | 0d50_000_000  | Clock frequency in Hz of `CLK`                 |
| `G_BAUD_RATE_BPS` | positive | 0d115_200     | Baud rate in bps                               |
| `G_SAMPLING_RATE` | positive | 0d16          | Sampling rate (number of clock cycles per bit) |
| `G_NB_DATA_BITS`  | positive | 0d8           | Number of data bits                            |

## Inputs and Outputs

| Port Name           | Type        | Direction | Default Value | Description                          |
| ------------------- | ----------- | --------- | ------------- | ------------------------------------ |
| `CLK`               | std_logic   | in        | -             | Input clock                          |
| `RST_N`             | std_logic   | in        | -             | Input asynchronous reset, active low |
| `I_UART_RX`         | std_logic   | in        | -             | Asynchronous input UART RX line      |
| `O_BYTE`            | vector[7:0] | out       | 0x00          | Output byte                          |
| `O_BYTE_VALID`      | std_logic   | out       | 0x0           | Output byte valid flag               |
| `O_START_BIT_ERROR` | std_logic   | out       | 0x0           | Output start bit error flag          |
| `O_STOP_BIT_ERROR`  | std_logic   | out       | 0x0           | Output stop bit error flag           |

## Architecture

The UART receiver must synchronize to incoming data, sample at the correct time, handle noise, and detect framing errors. The receiver uses oversampling, digital filtering, and majority voting to ensure reliable data reception.

### Oversampling Clock

The receiver generates an internal sampling clock that runs at a multiple of the baud rate (configured by `G_SAMPLING_RATE`, typically 16).

The oversampling clock divider generates a tick (`rx_baud_tick`) at the oversampling rate. For example, with 16× oversampling and 115200 baud:

$$f_{oversample} = 115200 \times 16 = 1.8432\text{ MHz}$$

The clock divider is enabled during active reception and reset during idle to ensure proper synchronization with incoming data.

!!! note
    The oversampling rate is configurable via the `G_SAMPLING_RATE` generic. A higher rate provides better noise immunity but requires a faster system clock.

### Input Synchronization and Filtering

The asynchronous UART RX input must be properly synchronized to prevent metastability and filtered to remove noise.

**Synchronization Chain**

A 5-stage shift register processes the incoming signal:

```none
Stage 0-1: Metastability resolution (2 flip-flops)
Stage 2-4: Digital filtering (3 consecutive samples)
I_UART_RX → [FF] → [FF] → [Filter] → [Filter] → [Filter] → i_uart_rx_filtered
```

**Digital Filtering Logic**

The filter uses a simple majority voting algorithm on the last 3 stages:

| Input Samples (bits 4:2) | Filtered Output     | Description            |
| ------------------------ | ------------------- | ---------------------- |
| `000`                    | `0`                 | All zeros → output low |
| `111`                    | `1`                 | All ones → output high |
| Other patterns           | Keep previous value | Insufficient agreement |

!!! important
    The first 2 bits of the shift register are potentially metastable and must NOT be used for any logic decisions. Only bits [4:2] are used for filtering. (I made this mistake)

**Edge Detection**

A delayed version of the filtered signal (`i_uart_rx_filtered_d1`) is maintained to detect edges:

- **Falling edge** (`1` → `0`): Indicates start bit detection
- **Rising edge** (`0` → `1`): Used for stop bit validation

### Oversampling and Bit Timing

Each UART bit period is divided into multiple sampling intervals. With 16× oversampling, each bit period contains 16 ticks.

**Tick Counting**

The `oversampling_counter` counter tracks the position within the current bit period:

- Increments on each `rx_baud_tick`
- Resets to 0 after reaching `C_OVERSAMPLE_MAX` (15 for 16× oversampling)
- When it wraps, one complete bit period has elapsed

**Visual Timing Diagram**

```none
Idle/Previous Bit                           Current Data Bit                           Next Bit
     (High)                                     (Low)                                   (High)
________________                                                                 __________________
                \                                                               /
                 \                                                             /
                  \                                                           /
                   \_________________________________________________________/
Tick:                 0  1  2  3  4  5  6  7  8  9  10  11  12  13  14  15
Samples:                                      ^
                                       Sample Point
Legend:
- 16 ticks per bit period (numbered 0-15)
- Samples taken at tick
- Provides maximum timing margin from bit edges
```

**Sample Point Selection**

The mid-bit sample point is calculated as:

$$\text{mid bit} = \frac{G\_BAUD\_RATE\_BPS - 1}{2}$$

### Bit Counter

The `data_counter` counter tracks how many data bits have been received.

### Data Shift Register

The `next_o_byte` register accumulates the incoming data bits.

**Shifting Operation**

Data is received **LSB first** (UART standard). Each new bit is shifted in from the left (MSB side):

```vhdl
next_o_byte <= uart_rx_sampled_bit & next_o_byte(7 downto 1);
```

**Example Reception Sequence**

Receiving byte `0x5A` (`0b01011010`):

```none
Initial:      next_o_byte = xxxxxxxx
Bit 0 (D0=0): next_o_byte = 0xxxxxxx  (shift in 0)
Bit 1 (D1=1): next_o_byte = 10xxxxxx  (shift in 1)
Bit 2 (D2=0): next_o_byte = 010xxxxx  (shift in 0)
Bit 3 (D3=1): next_o_byte = 1010xxxx  (shift in 1)
Bit 4 (D4=1): next_o_byte = 11010xxx  (shift in 1)
Bit 5 (D5=0): next_o_byte = 011010xx  (shift in 0)
Bit 6 (D6=1): next_o_byte = 1011010x  (shift in 1)
Bit 7 (D7=0): next_o_byte = 01011010  (shift in 0)
Final:        next_o_byte = 0x5A ✓
```

The byte is complete after 8 bits and ready to be latched to the output if the stop bit is valid.

### Error Recovery Mechanism

When an invalid start bit is detected, the module enters an error recovery state to prevent false triggering on glitches or noise.

The module then waits for the following time before going back to idle and accept new RX requests:

$$\text{RECOVERY\_PERIOD} = G\_SAMPLING\_RATE \times (G\_NB\_DATA\_BITS + 1)$$

This represents the time for almost one complete UART frame (data bits + stop bit) at the configured baud rate.

### FSM

The UART RX FSM is defined as:

![UART RX FSM](../../assets/uart.drawio){ page="UART-RX-FSM" })

Where the following transitions are defined:

| Transition | Condition(s)                                                                                                                           |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| T0         | `i_uart_rx_filtered_d1 = 1` **AND** `i_uart_rx_filtered = 0` (falling edge on the UART line)                                           |
| T1         | `rx_baud_tick = 1` **AND** `oversampling_counter = G_SAMPLING_RATE - 1` **AND** `uart_rx_sampled_bit = 1` (invalid start bit = 1)      |
| T2         | Automatic                                                                                                                              |
| T3         | `recovery_elapsed = 1`                                                                                                                 |
| T4         | `rx_baud_tick = 1` **AND** `oversampling_counter = G_SAMPLING_RATE - 1` **AND** `uart_rx_sampled_bit = 0` (valid start bit = 0)        |
| T5         | `rx_baud_tick = 1` **AND** `oversampling_counter = G_SAMPLING_RATE - 1` **AND** `data_counter = G_NB_DATA_BITS - 1`                    |
| T6         | `rx_baud_tick = 1` **AND** `oversampling_counter = C_THREE_QUARTER_POINT - 1` **AND** `uart_rx_sampled_bit = 0` (invalid stop bit = 0) |
| T7         | Automatic                                                                                                                              |
| T8         | `rx_baud_tick = 1` **AND** `oversampling_counter = C_THREE_QUARTER_POINT - 1` **AND** `uart_rx_sampled_bit = 1` (valid stop bit = 1)   |
| T9         | Automatic                                                                                                                              |

!!! note
    **Early Stop Bit Exit for Burst Support**

    The module exits the stop bit at **3/4 of the bit period** (tick 12 of 16) after validation at mid-point (tick 8). This enables zero-gap back-to-back frame reception for burst transmissions.
