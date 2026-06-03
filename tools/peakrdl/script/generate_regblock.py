"""Generate VHDL register block implementation."""
## =====================================================================================================================
##  MIT License
##
##  Copyright (c) 2026 Timothee Charrier
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
## @file    generate_regblock.py
## @version 1.0
## @brief   Generate VHDL register block implementation from RDL description.
##          See https://peakrdl-regblock-vhdl.readthedocs.io/en/latest/index.html for more details.
##          Script adapted from the example provided in the documentation of the 'peakrdl-regblock-vhdl' package.
## @author  Timothee Charrier
## @date    16/05/2026
## =====================================================================================================================

import argparse
import logging
from collections.abc import Iterable
from pathlib import Path
from typing import TYPE_CHECKING

from peakrdl_html import HTMLExporter
from peakrdl_markdown import MarkdownExporter
from peakrdl_regblock_vhdl import RegblockExporter
from peakrdl_regblock_vhdl.cpuif.axi4lite import AXI4Lite_Cpuif_flattened
from peakrdl_regblock_vhdl.udps import ALL_UDPS
from systemrdl import RDLCompileError, RDLCompiler
from systemrdl.node import RootNode

if TYPE_CHECKING:
    from systemrdl.node import RootNode

LOGGER: logging.Logger = logging.getLogger(name=__name__)

## =====================================================================================================================
# Configure paths
## =====================================================================================================================

THIS_DIR: Path = Path(__file__).resolve().parent
PRJ_ROOT: Path = THIS_DIR.parent.parent.parent
VHDL_OUTPUT_DIR: Path = PRJ_ROOT / "sources" / "regblock"
HTML_REPORT_OUTPUT_DIR: Path = THIS_DIR.parent / "report"
MARKDOWN_REPORT_OUTPUT_PATH: Path = THIS_DIR.parent / "report" / "markdown" / "regblock.md"
DEFAULT_INPUT_FILES: tuple[Path, ...] = (PRJ_ROOT / "tools" / "peakrdl" / "config" / "regblock.rdl",)


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate VHDL regblock from SystemRDL")
    parser.add_argument(
        "--input",
        nargs="+",
        type=Path,
        default=list(DEFAULT_INPUT_FILES),
        help="RDL files to compile",
    )
    parser.add_argument(
        "--vhdl-out",
        type=Path,
        default=VHDL_OUTPUT_DIR,
        help="Output directory for VHDL files",
    )
    parser.add_argument(
        "--html-report-out",
        type=Path,
        default=HTML_REPORT_OUTPUT_DIR,
        help="Output directory for HTML report",
    )
    parser.add_argument(
        "--markdown-report-out",
        type=Path,
        default=MARKDOWN_REPORT_OUTPUT_PATH.parent,
        help="Output directory for Markdown report",
    )
    parser.add_argument(
        "--skip-html",
        action="store_true",
        help="Skip HTML documentation generation",
    )
    parser.add_argument(
        "--skip-markdown",
        action="store_true",
        help="Skip Markdown documentation generation",
    )
    return parser.parse_args()


def _validate_inputs(input_files: Iterable[Path]) -> None:
    missing: list[Path] = [path for path in input_files if not path.exists()]
    if missing:
        missing_str: str = ", ".join(str(path) for path in missing)
        raise SystemExit(f"ERROR: Missing input RDL file(s): {missing_str}")


def _compile_rdl(input_files: Iterable[Path]) -> "RootNode":
    rdlc = RDLCompiler()
    for udp in ALL_UDPS:
        rdlc.register_udp(definition_cls=udp)

    try:
        for input_file in input_files:
            rdlc.compile_file(path=str(input_file))
        return rdlc.elaborate()
    except RDLCompileError as exc:
        LOGGER.error("RDL compilation failed: %s", exc)
        raise SystemExit(1) from exc


def _export_vhdl(root: "RootNode", output_dir: Path) -> None:
    exporter = RegblockExporter()
    exporter.export(
        node=root,
        output_dir=output_dir,
        cpuif_cls=AXI4Lite_Cpuif_flattened,
        default_reset_async=True,
        err_if_bad_addr=True,
        copy_utils_pkg=True,
    )
    LOGGER.info("VHDL register block implementation generated in %s", output_dir)


def _export_docs(
    root: "RootNode",
    html_report_dir: Path,
    markdown_report_dir: Path,
    skip_html: bool,
    skip_markdown: bool,
) -> None:
    if not skip_html:
        html_output: Path = html_report_dir / "html"
        html_exporter = HTMLExporter()
        html_exporter.export(nodes=root, output_dir=html_output)
        LOGGER.info("HTML documentation generated in %s", html_output)

    if not skip_markdown:
        markdown_output: Path = markdown_report_dir / "regblock" / "regblock.md"
        markdown_exporter = MarkdownExporter()
        markdown_exporter.export(node=root, output_path=str(markdown_output))
        LOGGER.info("Markdown documentation generated in %s", markdown_output)


def main() -> None:
    """Entry point of the script."""
    args: argparse.Namespace = _parse_args()

    _validate_inputs(input_files=args.input)
    root: RootNode = _compile_rdl(input_files=args.input)

    _export_vhdl(root=root, output_dir=args.vhdl_out)
    _export_docs(
        root=root,
        html_report_dir=args.html_report_out,
        markdown_report_dir=args.markdown_report_out,
        skip_html=args.skip_html,
        skip_markdown=args.skip_markdown,
    )


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
    LOGGER.info("Generating VHDL register block implementation...")
    main()
    LOGGER.info("Done!")
