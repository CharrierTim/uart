"""Sphinx configuration file."""
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
## @file    conf.py
## @version 1.0
## @brief   Configuration file for the Sphinx documentation builder.
##          For the full list of built-in configuration values, see the documentation:
##              - https://www.sphinx-doc.org/en/master/usage/configuration.html
## @author  Timothee Charrier
## @date    23/10/2025
## =====================================================================================================================

# -- Project information -----------------------------------------------------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

import datetime
import sys
from pathlib import Path

base_path: Path = (Path(__file__).parent.parent.parent / "src/bench/").resolve()
sys.path.insert(0, str(base_path))
for path in base_path.rglob("*"):
    if path.is_dir():
        sys.path.insert(0, str(path))

project = "UART Project"
copyright: str = f"{datetime.datetime.now(tz=datetime.UTC).year}, Timothée Charrier"
author = "Timothée Charrier"
release = "0.1"

# -- General configuration ---------------------------------------------------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions: list[str] = [
    "numpydoc",
    "sphinx_copybutton",
    "sphinx.ext.autodoc",
    "sphinx.ext.autosummary",
    "sphinx.ext.imgconverter",
    "sphinx.ext.napoleon",
    "sphinx.ext.viewcode",
    "sphinxcontrib.wavedrom",
]

# For PDF generation
render_using_wavedrompy = True

# -- Options for HTML output -------------------------------------------------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = "pydata_sphinx_theme"
html_static_path: list[str] = ["_static"]

# -- Options for numpydoc ----------------------------------------------------------------------------------------------
# https://numpydoc.readthedocs.io/en/latest/format.html

numpydoc_class_members_toctree = False

# The name of the Pygments (syntax highlighting) style to use.
pygments_style = "sphinx"

html_theme_options = {
    "show_prev_next": False,
    "navbar_end": ["theme-switcher", "navbar-icon-links.html"],
    "icon_links": [
        {
            "name": "PDF Download",
            "url": "./uart.pdf",
            "icon": "fas fa-file-pdf",
            "type": "fontawesome",
        },
    ],
}

html_sidebars = {
    "**": [],
}
html_context: dict[str, str] = {
    "default_mode": "auto",
}

html_title: sys.LiteralString = f"{project}"
html_last_updated_fmt = "%b %d, %Y"
