# UART TX

## Description

## Generics

<div class="generics-table" markdown="1">

| Generic Name      | Type     | Default Value | Description                    |
| ----------------- | -------- | ------------- | ------------------------------ |
| `G_CLK_FREQ_HZ`   | positive | 0d50_000_000  | Clock frequency in Hz of `CLK` |
| `G_BAUD_RATE_BPS` | positive | 0d115_200     | Baud rate in bps               |

</div>

## Inputs and Outputs

<div class="ports-table" markdown="1">

| Port Name      | Type        | Direction | Default Value | Description                          |
| -------------- | ----------- | :-------: | ------------- | ------------------------------------ |
| `CLK`          | std_logic   |    in     | -             | Input clock                          |
| `RST_N`        | std_logic   |    in     | -             | Input asynchronous reset, active low |
| `I_BYTE`       | vector[7:0] |    in     | -             | Input byte to send                   |
| `I_BYTE_VALID` | std_logic   |    in     | -             | Input byte to send valid flag        |
| `O_UART_TX`    | std_logic   |    out    | 0b1           | Output UART TX line                  |
| `O_DONE`       | std_logic   |    out    | 0b0           | Byte send flag                       |

</div>

## Architecture

The UART transmitter consists of three main components that work together to serialize and transmit data at the
configured baud rate.

![UART TX Architecture](../../assets/uart.drawio){ page="UART-TX" }

### Clock Divider

A clock operating at the baud rate is generated internally to control the bit timing. This clock is activated when the
transmitter enters the `STATE_SEND_BYTE` state.

The clock divider process increment the bit count and shift the data every time it reaches one baud tick.

### Bit Counter

This counter ensures that:

- Exactly 8 data bits are transmitted
- The stop bit is sent after all data bits
- The transmitter returns to idle state after completing the frame

The transmission sequence includes:

1. Start bit (1 bit)
2. Data bits (8 bits, LSB first)
3. Stop bit (1 bit)

**Total frame length**: 10 bits per byte

### Data Loading and Shifting

The transmitter operates in two distinct modes for data handling:

#### STATE_IDLE Mode

In the `STATE_IDLE` state, the shift register is loaded with the complete transmission frame when the valid flag is
asserted. The frame structure is:

```none
  [Stop bit | Data byte | Start bit]
  [    1    | D7 ... D0 |     0    ]
       ↑                      ↑
     MSB of                 LSB of
shift register         shift register
```

The frame is constructed as follows:

- **Bit 0** (LSB): Start bit (logic '0')
- **Bits 1-8**: Data byte (D0 to D7)
- **Bit 9** (MSB): Stop bit (logic '1')

#### STATE_SEND_BYTE Mode

In the `STATE_SEND_BYTE` state, the shift register is shifted right by one position at each baud tick overflow. A logic
'1' is shifted in from the left (MSB) side.

This right-shift operation ensures that:

- Data bits are transmitted LSB first (as per UART standard)
- After all data bits are sent, logic '1' values (stop bit) are transmitted
- The shift register naturally returns to an idle-high state

#### Output Signal

The output signal `O_UART_TX` continuously reflects the LSB (bit 0) of the shift register, which contains the current
bit being transmitted.

```none
Transmission sequence for data byte 0x5A (0b01011010):
Time →
Bit  : [START| D0 | D1 | D2 | D3 | D4 | D5 | D6 | D7 |STOP]
Value:   0     0    1    0    1    1    0    1    0    1
         └─────────────────────────────────────────────┘
                   Transmitted on O_UART_TX
```

### FSM

The UART FSM handling is defined as:

![UART TX FSM](../../assets/uart.drawio){ page="UART-TX-FSM" }

Where the following transitions are defined:

| Transition | Condition(s)                |
| ---------- | --------------------------- |
| T0         | `I_BYTE_VALID = 1`          |
| T1         | `tx_current_bit_index >= 9` |
| T2         | Automatic                   |
