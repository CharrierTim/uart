# UART AXI Lite Bridge

## Description

The UART AXI Lite Bridge module implements a UART controller that interfaces with an AXI Lite bus.
It allows reading and writing 32-bit values to/from the AXI Lite bus through a simple ASCII-based UART protocol.

---

## Generics

<div class="generics-table" markdown="1">

| Generic Name      | Type     | Default Value | Description                                    |
| ----------------- | -------- | ------------- | ---------------------------------------------- |
| `G_CLK_FREQ_HZ`   | positive | 0d50_000_000  | Clock frequency in Hz of `CLK`                 |
| `G_BAUD_RATE_BPS` | positive | 0d115_200     | Baud rate in bps                               |
| `G_SAMPLING_RATE` | positive | 0d16          | Sampling rate (number of clock cycles per bit) |

</div>

---

## Inputs and Outputs

<div class="ports-table" markdown="1">

| Port Name        | Type                          | Direction | Default Value | Description                                |
| ---------------- | ----------------------------- | :-------: | ------------- | ------------------------------------------ |
| `CLK`            | std_logic                     |    in     | -             | Input clock                                |
| `ARST_P`         | std_logic                     |    in     | -             | Input asynchronous reset, active high      |
| `I_UART_RX`      | std_logic                     |    in     | -             | Asynchronous input UART RX line            |
| `O_UART_TX`      | std_logic                     |    out    | 0b1           | Output UART TX line                        |
| `M_AXIL_AWREADY` | std_logic                     |    in     | -             | AXI Lite write address ready (from slave)  |
| `M_AXIL_AWVALID` | std_logic                     |    out    | 0b0           | AXI Lite master write address valid        |
| `M_AXIL_AWADDR`  | std_logic_vector(7 downto 0)  |    out    | 0x00          | AXI Lite master write address              |
| `M_AXIL_AWPROT`  | std_logic_vector(2 downto 0)  |    out    | 0b000         | AXI Lite master write protection           |
| `M_AXIL_WREADY`  | std_logic                     |    in     | -             | AXI Lite write data ready (from slave)     |
| `M_AXIL_WVALID`  | std_logic                     |    out    | 0b0           | AXI Lite master write data valid           |
| `M_AXIL_WDATA`   | std_logic_vector(31 downto 0) |    out    | 0x00000000    | AXI Lite master write data                 |
| `M_AXIL_WSTRB`   | std_logic_vector(3 downto 0)  |    out    | 0b0000        | AXI Lite master write strobe               |
| `M_AXIL_BREADY`  | std_logic                     |    out    | 0b0           | AXI Lite master write response ready       |
| `M_AXIL_BVALID`  | std_logic                     |    in     | -             | AXI Lite write response valid (from slave) |
| `M_AXIL_BRESP`   | std_logic_vector(1 downto 0)  |    in     | -             | AXI Lite master write response             |
| `M_AXIL_ARREADY` | std_logic                     |    in     | -             | AXI Lite read address ready (from slave)   |
| `M_AXIL_ARVALID` | std_logic                     |    out    | 0b0           | AXI Lite master read address valid         |
| `M_AXIL_ARADDR`  | std_logic_vector(7 downto 0)  |    out    | 0x00          | AXI Lite master read address               |
| `M_AXIL_ARPROT`  | std_logic_vector(2 downto 0)  |    out    | 0b000         | AXI Lite master read protection            |
| `M_AXIL_RREADY`  | std_logic                     |    out    | 0b0           | AXI Lite master read data ready            |
| `M_AXIL_RVALID`  | std_logic                     |    in     | -             | AXI Lite read data valid (from slave)      |
| `M_AXIL_RDATA`   | std_logic_vector(31 downto 0) |    in     | -             | AXI Lite master read data                  |
| `M_AXIL_RRESP`   | std_logic_vector(1 downto 0)  |    in     | -             | AXI Lite master read response              |

</div>

---

## Architecture

![UART Architecture](../../assets/uart.drawio){ page="UART" }

---

## Sub-modules

The UART controller module instantiates the [UART RX](uart_rx.md) module with the following generics:

<div class="generics-table" markdown="1">

| Generic Name      | Type     | Default Value     | Description                                    |
| ----------------- | -------- | ----------------- | ---------------------------------------------- |
| `G_CLK_FREQ_HZ`   | positive | `G_CLK_FREQ_HZ`   | Clock frequency in Hz of `CLK`                 |
| `G_BAUD_RATE_BPS` | positive | `G_BAUD_RATE_BPS` | Baud rate in bps                               |
| `G_SAMPLING_RATE` | positive | `G_SAMPLING_RATE` | Sampling rate (number of clock cycles per bit) |

</div>

The UART controller module instantiates the [UART TX](uart_tx.md) module with the following generics:

<div class="generics-table" markdown="1">

| Generic Name      | Type     | Default Value     | Description                    |
| ----------------- | -------- | ----------------- | ------------------------------ |
| `G_CLK_FREQ_HZ`   | positive | `G_CLK_FREQ_HZ`   | Clock frequency in Hz of `CLK` |
| `G_BAUD_RATE_BPS` | positive | `G_BAUD_RATE_BPS` | Baud rate in bps               |

</div>

---

## About

### Protocol

The implemented UART protocol is an ASCII-based protocol to access the internal registers of the FPGA.
All commands and responses are ASCII text and every message is terminated by a mandatory carriage-return (CR, `\r`).
A line-feed (LF, `\n`) may follow CR but is optional and ignored by the device.

The following fields are defined:

- `AA`: 8-bit address (two ASCII hex characters)
- `DDDD`: 16-bit data (four ASCII hex characters)

![UART Protocol Diagram](../../assets/uart.drawio){ page="UART-PROTOCOL" }

#### Read Mode

The read mode allows reading a 16-bit value from a specified 8-bit register address. The device responds with the
current register value.

**Command Format**:

```raw
R + AA + \r[\n]
```

- `R`: literal ASCII 'R' (read command)
- `AA`: two ASCII hex characters representing an 8-bit address (`00` .. `FF`)
- `\r`: mandatory CR terminator (ASCII 0x0D)
- `\n`: optional LF (ASCII 0x0A), if present it is ignored by the device

**Response Format**:

```raw
DDDD + \r[\n]
```

- `DDDD`: four ASCII hex characters representing the 16-bit register value, MSB first (`0000` .. `FFFF`)
- `\r`: mandatory CR terminator
- `\n`: optional LF (ASCII 0x0A)

**Examples**:

```none
# Read address 0x1A
Sent                   : R1A\r\n
Bytes transmitted (hex): 0x52 0x31 0x41 0x0D 0x0A
Reply                  : 0F3C\r
Bytes received    (hex): 0x30 0x46 0x33 0x43 0x0D
```

```none
# Read address 0xFF
Sent                   : RFF\r
Bytes transmitted (hex): 0x52 0x46 0x46 0x0D
Reply                  : DEAD\r
Bytes received    (hex): 0x44 0x45 0x39 0x44 0x0D
```

---

#### Write Mode

The write mode allows writing a 16-bit value to a specified 8-bit register address.
The device does not send any acknowledgment response after a successful write operation.

**Command Format**:

```raw
W + AA + DDDD + \r[\n]
```

- `W`: literal ASCII 'W' (write command)
- `AA`: two ASCII hex characters representing an 8-bit address (`00` .. `FF`)
- `DDDD`: four ASCII hex characters representing the 16-bit data value to write, MSB first (`0000` .. `FFFF`)
- `\r`: mandatory CR terminator (ASCII 0x0D)
- `\n`: optional LF (ASCII 0x0A), if present it is ignored by the device

**Response Format**:

No response is expected or generated by the device for write commands.

!!! important
    To verify that data was correctly written to the given address, perform a read-back operation using the read
    command on the same register address.

**Example**:

```none
# Write value 0x1234 to address 0x1A
Sent                   : W1A1234\r\n
Bytes transmitted (hex): 0x57 0x31 0x41 0x31 0x32 0x33 0x34 0x0D 0x0A
Reply                  : (no reply expected)
```

```none
# Write value 0x0001 to address 0x01
Sent                   : W010001\r
Bytes transmitted (hex): 0x57 0x30 0x31 0x30 0x30 0x30 0x31 0x0D
Reply                  : (no reply expected)
```

#### Special behavior

Some transitions have special behavior: at every character received, the FSM checks if it is an `R` or `W` character.
If detected, the FSM immediately abandons any ongoing operation and starts processing the new command.

This means that a new read or write command can interrupt and completely override a partially received command, even if
the previous command was not yet complete.

**Example**: Interrupted Write Command

```none
# Sending the following ASCII characters: W001R00\r
#                                             ↑
#                              Sudden change to read command,
#                              even though write command was incomplete
Sent       : W001R00\r
Expected   : Write incomplete data to address 0x00
Actual     : Read from address 0x00
Result     : Returns the data at address 0x00
             No write operation is performed
```

---

### FSM

The UART FSM handling the above protocol is defined as:

![UART FSM](../../assets/uart.drawio){ page="UART-FSM" }

Where the following transitions are defined:

| Transition | Condition(s)                                                |
| ---------- | ----------------------------------------------------------- |
| T0         | `rst_soft_p = 1`                                            |
| T1         | `rx_byte = W character`                                     |
| T2         | `rx_byte /= CR (\r) character` **AND** `rx_byte_count >= 3` |
| T3         | `rx_byte = CR (\r) character` **AND** `rx_byte_count >= 3`  |
| T4         | Automatic                                                   |
| T5         | `rx_byte = R character`                                     |
| T6         | `rx_byte /= CR (\r) character` **AND** `rx_byte_count >= 7` |
| T7         | `rx_byte = CR (\r) character` **AND** `rx_byte_count >= 7`  |
| T8         | Automatic                                                   |
| T9         | `I_READ_DATA_VALID = 1`                                     |
| T10        | `tx_byte_count >= 5`                                        |

---

### Data decoding

The received data needs to be decoded from ASCII to hexadecimal to be usable in the registers.
To do so, the signal `rx_byte_decoded` receives:

#### ASCII to Hexadecimal Decoding

| Decoded Value | ASCII Character | Condition        |
| ------------- | --------------- | ---------------- |
| `0x0`         | '0'             | `rx_byte = 0x30` |
| `0x1`         | '1'             | `rx_byte = 0x31` |
| `0x2`         | '2'             | `rx_byte = 0x32` |
| `0x3`         | '3'             | `rx_byte = 0x33` |
| `0x4`         | '4'             | `rx_byte = 0x34` |
| `0x5`         | '5'             | `rx_byte = 0x35` |
| `0x6`         | '6'             | `rx_byte = 0x36` |
| `0x7`         | '7'             | `rx_byte = 0x37` |
| `0x8`         | '8'             | `rx_byte = 0x38` |
| `0x9`         | '9'             | `rx_byte = 0x39` |
| `0xA`         | 'A'             | `rx_byte = 0x41` |
| `0xB`         | 'B'             | `rx_byte = 0x42` |
| `0xC`         | 'C'             | `rx_byte = 0x43` |
| `0xD`         | 'D'             | `rx_byte = 0x44` |
| `0xE`         | 'E'             | `rx_byte = 0x45` |
| `0xF`         | 'F'             | `rx_byte = 0x46` |

#### Decoding Special Characters

| Character       | ASCII Value | Condition      |
| --------------- | ----------- | -------------- |
| Default/Invalid | `0x00`      | No match found |

---

### Data encoding

The transmit data needs to be encoded from hexadecimal to ASCII before being sent over UART.
To do so, the signal `tx_byte_to_send_encoded` receives:

#### Hexadecimal to ASCII Encoding

| Input Value | ASCII Character | Encoded Value                    |
| ----------- | --------------- | -------------------------------- |
| `0x0`       | '0'             | `tx_byte_to_send_encoded = 0x30` |
| `0x1`       | '1'             | `tx_byte_to_send_encoded = 0x31` |
| `0x2`       | '2'             | `tx_byte_to_send_encoded = 0x32` |
| `0x3`       | '3'             | `tx_byte_to_send_encoded = 0x33` |
| `0x4`       | '4'             | `tx_byte_to_send_encoded = 0x34` |
| `0x5`       | '5'             | `tx_byte_to_send_encoded = 0x35` |
| `0x6`       | '6'             | `tx_byte_to_send_encoded = 0x36` |
| `0x7`       | '7'             | `tx_byte_to_send_encoded = 0x37` |
| `0x8`       | '8'             | `tx_byte_to_send_encoded = 0x38` |
| `0x9`       | '9'             | `tx_byte_to_send_encoded = 0x39` |
| `0xA`       | 'A'             | `tx_byte_to_send_encoded = 0x41` |
| `0xB`       | 'B'             | `tx_byte_to_send_encoded = 0x42` |
| `0xC`       | 'C'             | `tx_byte_to_send_encoded = 0x43` |
| `0xD`       | 'D'             | `tx_byte_to_send_encoded = 0x44` |
| `0xE`       | 'E'             | `tx_byte_to_send_encoded = 0x45` |
| `0xF`       | 'F'             | `tx_byte_to_send_encoded = 0x46` |

#### Encoding Special Characters

| Character            | ASCII Value | Condition                         |
| -------------------- | ----------- | --------------------------------- |
| Carriage Return (CR) | `0x0D`      | `tx_byte_count = C_TX_DATA_BYTES` |
| Default/Invalid      | `0x00`      | No match found                    |

---
