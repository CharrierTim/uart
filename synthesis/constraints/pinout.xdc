## =====================================================================================================================
##  MIT License
##
##  Copyright (c) 2025 Timothee Charrier
##
##  Permission is hereby granted, free of charge, to any person obtaining a copy
##  of this software and associated documentation files (the "Software"), to deal
##  in the Software without restriction, including without limitation the rights
##  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
##  copies of the Software, and to permit persons to whom the Software is
##  furnished to do so, subject to the following conditions:
##
##  The above copyright notice and this permission notice shall be included in all
##  copies or substantial portions of the Software.
##
##  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
##  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
##  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
##  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
##  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
##  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
##  SOFTWARE.
## =====================================================================================================================
## @project uart
## @file    pinout.xdc
## @version 1.0
## @brief   Pinout constraints for the FPGA
## @author  Timothee Charrier
## @date    29/10/2025
## =====================================================================================================================

# Clock and reset
set_property -dict {PACKAGE_PIN Y9   IOSTANDARD LVCMOS33}             [get_ports {PAD_I_CLK}];      # CLK
set_property -dict {PACKAGE_PIN R16  IOSTANDARD LVCMOS18}             [get_ports {PAD_I_RST_H}];    # BTND

# UART
set_property -dict {PACKAGE_PIN Y11  IOSTANDARD LVCMOS33 PULLUP TRUE} [get_ports {PAD_I_UART_RX}];  # JA1 - P1
set_property -dict {PACKAGE_PIN AA11 IOSTANDARD LVCMOS33 PULLUP TRUE} [get_ports {PAD_O_UART_TX}];  # JA2 - P2

# SPI
set_property -dict {PACKAGE_PIN W12  IOSTANDARD LVCMOS33}             [get_ports {PAD_O_SCLK}];     # JB1 - P1
set_property -dict {PACKAGE_PIN W11  IOSTANDARD LVCMOS33}             [get_ports {PAD_O_MOSI}];     # JB1 - P2
set_property -dict {PACKAGE_PIN W10  IOSTANDARD LVCMOS33}             [get_ports {PAD_I_MISO}];     # JB1 - P3
set_property -dict {PACKAGE_PIN W8   IOSTANDARD LVCMOS33 PULLUP TRUE} [get_ports {PAD_O_CS}];       # JB1 - P4

# Switches
set_property -dict {PACKAGE_PIN F22  IOSTANDARD LVCMOS18}             [get_ports {PAD_I_SWITCH_0}]; # SW0
set_property -dict {PACKAGE_PIN G22  IOSTANDARD LVCMOS18}             [get_ports {PAD_I_SWITCH_1}]; # SW1
set_property -dict {PACKAGE_PIN H22  IOSTANDARD LVCMOS18}             [get_ports {PAD_I_SWITCH_2}]; # SW2

# LED
set_property -dict {PACKAGE_PIN T22  IOSTANDARD LVCMOS33}             [get_ports {PAD_O_LED_0}];    # LD0
