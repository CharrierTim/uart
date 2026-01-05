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
## @version 1.1
## @brief   Pinout constraints for the FPGA
## @author  Timothee Charrier
## @date    29/10/2025
## =====================================================================================================================
## REVISION HISTORY
##
## Version  Date        Author              Description
## -------  ----------  ------------------  ----------------------------------------------------------------------------
## 1.0      29/10/2025  Timothee Charrier   Initial release
## 1.1      05/01/2026  Timothee Charrier   Add VGA constraints
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
set_property -dict {PACKAGE_PIN W8   IOSTANDARD LVCMOS33 PULLUP TRUE} [get_ports {PAD_O_CS_N}];     # JB1 - P4

# VGA
set_property -dict {PACKAGE_PIN Y21  IOSTANDARD LVCMOS33}             [get_ports {PAD_O_VGA_BLUE[0]}];  # "VGA-B0"
set_property -dict {PACKAGE_PIN Y20  IOSTANDARD LVCMOS33}             [get_ports {PAD_O_VGA_BLUE[1]}];  # "VGA-B1“
set_property -dict {PACKAGE_PIN AB20 IOSTANDARD LVCMOS33}             [get_ports {PAD_O_VGA_BLUE[2]}];  # "VGA-B2“
set_property -dict {PACKAGE_PIN AB19 IOSTANDARD LVCMOS33}             [get_ports {PAD_O_VGA_BLUE[3]}];  # "VGA-B3“
set_property -dict {PACKAGE_PIN AB22 IOSTANDARD LVCMOS33}             [get_ports {PAD_O_VGA_GREEN[0]}]; # "VGA-G0“
set_property -dict {PACKAGE_PIN AA22 IOSTANDARD LVCMOS33}             [get_ports {PAD_O_VGA_GREEN[1]}]; # "VGA-G1“
set_property -dict {PACKAGE_PIN AB21 IOSTANDARD LVCMOS33}             [get_ports {PAD_O_VGA_GREEN[2]}]; # "VGA-G2“
set_property -dict {PACKAGE_PIN AA21 IOSTANDARD LVCMOS33}             [get_ports {PAD_O_VGA_GREEN[3]}]; # "VGA-G3“
set_property -dict {PACKAGE_PIN V20  IOSTANDARD LVCMOS33}             [get_ports {PAD_O_VGA_RED[0]}];   # "VGA-R0“
set_property -dict {PACKAGE_PIN U20  IOSTANDARD LVCMOS33}             [get_ports {PAD_O_VGA_RED[1]}];   # "VGA-R1“
set_property -dict {PACKAGE_PIN V19  IOSTANDARD LVCMOS33}             [get_ports {PAD_O_VGA_RED[2]}];   # "VGA-R2“
set_property -dict {PACKAGE_PIN V18  IOSTANDARD LVCMOS33}             [get_ports {PAD_O_VGA_RED[3]}];   # "VGA-R3“
set_property -dict {PACKAGE_PIN AA19 IOSTANDARD LVCMOS33}             [get_ports {PAD_O_VGA_HSYNC}];    # "VGA-HS“
set_property -dict {PACKAGE_PIN Y19  IOSTANDARD LVCMOS33}             [get_ports {PAD_O_VGA_VSYNC}];    # "VGA-VS“

# Switches
set_property -dict {PACKAGE_PIN F22  IOSTANDARD LVCMOS18}             [get_ports {PAD_I_SWITCH_0}]; # SW0
set_property -dict {PACKAGE_PIN G22  IOSTANDARD LVCMOS18}             [get_ports {PAD_I_SWITCH_1}]; # SW1
set_property -dict {PACKAGE_PIN H22  IOSTANDARD LVCMOS18}             [get_ports {PAD_I_SWITCH_2}]; # SW2

# LED
set_property -dict {PACKAGE_PIN T22  IOSTANDARD LVCMOS33}             [get_ports {PAD_O_LED_0}];    # LD0
