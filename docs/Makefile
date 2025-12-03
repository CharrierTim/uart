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
## @file    Makefile
## @version 1.0
## @brief   Compilation file for the UART project documentation using MkDocs
## @author  Timothee Charrier
## @date    03/12/2025
## =====================================================================================================================

# Default target
.PHONY: help
help:
	@echo "UART Project Documentation - MkDocs"
	@echo ""
	@echo "Available targets:"
	@echo "  build  - Build the documentation"
	@echo "  serve  - Start development server"
	@echo "  clean  - Remove built documentation"
	@echo ""

# Build the documentation
.PHONY: build
build:
	@cd .. && mkdocs build

# Start the development server
.PHONY: serve
serve:
	@cd .. && mkdocs serve

# Clean the built documentation
.PHONY: clean
clean:
	@cd .. && rm -rf site/
	@echo "Documentation cleaned"

