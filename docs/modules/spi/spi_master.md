# SPI Master

## Description

---

## Generics

<div class="generics-table" markdown="1">

| Generic Name     | Type      | Default Value | Description                                    |
| ---------------- | --------- | ------------- | ---------------------------------------------- |
| `G_CLK_FREQ_HZ`  | positive  | 0d50_000_000  | Clock frequency in Hz of `internal_clk`        |
| `G_SPI_FREQ_HZ`  | positive  | 0d500_000     | SPI clock frequency in Hz                      |
| `G_NB_DATA_BITS` | positive  | 0d8           | Number of data bits within the SPI transaction |
| `G_CLK_POLARITY` | std_logic | 0b0           | Generated SPI clock polarity                   |
| `G_CLK_PHASE`    | std_logic | 0b0           | Generated SPI clock phase                      |

</div>

---

## Inputs and Outputs

<div class="ports-table" markdown="1">

| Port Name         | Type                       | Direction | Default Value    | Description                                                                         |
| ----------------- | -------------------------- | :-------: | ---------------- | ----------------------------------------------------------------------------------- |
| `CLK`             | std_logic                  |    in     | -                | Input clock                                                                         |
| `RST_P`           | std_logic                  |    in     | -                | Input asynchronous reset, active low                                                |
| `O_SCLK`          | std_logic                  |    out    | `G_CLK_POLARITY` | Output SPI serial clock                                                             |
| `O_MOSI`          | std_logic                  |    out    | 0b0              | Output Master Out Slave In                                                          |
| `I_MISO`          | std_logic                  |    in     | -                | Input Master In Slave Out                                                           |
| `O_CS`            | std_logic                  |    out    | 0b1              | Output chip select                                                                  |
| `I_TX_DATA`       | vector[G_NB_DATA_BITS-1:0] |    in     | -                | Data to be sent                                                                     |
| `I_TX_DATA_VALID` | std_logic                  |    in     | -                | Data to be sent flag valid. Must be a rising edge to start the transaction (0 -> 1) |
| `O_TX_DATA`       | vector[G_NB_DATA_BITS-1:0] |    out    | 0x00             | Data received from the slave                                                        |
| `O_TX_DATA_VALID` | std_logic                  |    out    | 0b0              | Data Data received from the slave flag valid                                        |

</div>

---

## Architecture

![SPI Master Architecture](../../assets/uart.drawio){ page="SPI-MASTER" }

### Configurations

The SPI master supports all four standard SPI modes, determined by the Clock Polarity (CPOL) and Clock Phase (CPHA) settings:

#### Mode 0: CPOL=0, CPHA=0

![SPI timing diagram for CPOL=0, CPHA=0](../../assets/uart.drawio){ page="SPI-MASTER-CPOL0-CPHA0" }

In this mode:

- Clock idles low
- Data is output on the rising edge of SCLK
- Input data is sampled on the falling edge of SCLK

---

#### Mode 1: CPOL=0, CPHA=1

![SPI timing diagram for CPOL=0, CPHA=1](../../assets/uart.drawio){ page="SPI-MASTER-CPOL0-CPHA1" }

In this mode:

- Clock idles low
- Data is output on the falling edge of SCLK
- Input data is sampled on the rising edge of SCLK

---

#### Mode 2: CPOL=1, CPHA=0

![SPI timing diagram for CPOL=1, CPHA=0](../../assets/uart.drawio){ page="SPI-MASTER-CPOL1-CPHA0" }

In this mode:

- Clock idles high
- Data is output on the falling edge of SCLK
- Input data is sampled on the rising edge of SCLK

---

#### Mode 3: CPOL=1, CPHA=1

![SPI timing diagram for CPOL=1, CPHA=1](../../assets/uart.drawio){ page="SPI-MASTER-CPOL1-CPHA1" }

In this mode:

- Clock idles high
- Data is output on the rising edge of SCLK
- Input data is sampled on the falling edge of SCLK

---

!!! note
    "Output" refers to when data is driven onto the MOSI/MISO lines. "Sampled" refers to when data is captured/registered
    from the input line.

---

### FSM

The UART FSM handling is defined as:

![SPI Master FSM](../../assets/uart.drawio){ page="SPI-MASTER-FSM" }

Where the following transitions are defined:

| Transition | Condition(s)                                                                          |
| ---------- | ------------------------------------------------------------------------------------- |
| T0         | `i_data_valid_d1 = 0` **AND** `I_DATA_VALID = 1` (rising edge)                        |
| T1         | `spi_enable_sampling = 1` (trailing edge)                                             |
| T2         | `spi_enable_shifting = 1` (leading edge)                                              |
| T3         | `bit_counter >= G_NB_DATA_BITS - 1` **AND** `spi_enable_shifting = 1` (all bits sent) |
| T4         | `spi_enable_sampling = 1` (trailing edge)                                             |
| T5         | Automatic                                                                             |
