Registers
=========

Summary
-------

============== ======= ==== ===================================================
Name           Address Mode Description
============== ======= ==== ===================================================
REG_GIT_ID_MSB 0x00    R    16 MSB of the git ID containing the sources for the
                            bitstream generation
REG_GIT_ID_LSB 0x01    R    16 LSB of the git ID containing the sources for the
                            bitstream generation
REG_12         0x02    R    Internal register 1
REG_34         0x03    R    Internal register 2
REG_56         0x04    R    Internal register 3
REG_78         0x05    R    Internal register 4
REG_9A         0xAB    R    Internal register 5
REG_CD         0xAC    R    Internal register 6
REG_EF         0xDC    R    Internal register 7
REG_SWITCHES   0xB1    R    Status from the input switches
REG_LED        0xEF    RW   Register with LSB bit writable controlling an LED
REG_16_BITS    0xFF    RW   Register with all bits writable
============== ======= ==== ===================================================

Detailed register descriptions
------------------------------

REG_GIT_ID_MSB
~~~~~~~~~~~~~~

16 MSB of the git ID containing the sources for the bitstream generation

- Address: ``0x00``

Fields
++++++

.. wavedrom::

    {"reg": [{"name": "GIT_ID_MSB", "bits": 16, "attr": ["ro"], "rotate": 0, "type": 3}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80}}

==== ===== ========== =============================================
Bits Reset Name       Description
==== ===== ========== =============================================
15:0 0x0   GIT_ID_MSB Most significant 16 bits of the Git commit ID
==== ===== ========== =============================================

REG_GIT_ID_LSB
~~~~~~~~~~~~~~

16 LSB of the git ID containing the sources for the bitstream generation

- Address: ``0x01``

Fields
++++++

.. wavedrom::

    {"reg": [{"name": "GIT_ID_LSB", "bits": 16, "attr": ["ro"], "rotate": 0, "type": 3}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80}}

==== ===== ========== ==============================================
Bits Reset Name       Description
==== ===== ========== ==============================================
15:0 0x0   GIT_ID_LSB Least significant 16 bits of the Git commit ID
==== ===== ========== ==============================================

REG_12
~~~~~~

Internal register 1

- Address: ``0x02``

Fields
++++++

.. wavedrom::

    {"reg": [{"name": "0x1212", "bits": 16, "attr": ["ro"], "rotate": 0, "type": 3}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80, "bits": 16}}

==== ====== ==== ===========
Bits Reset  Name Description
==== ====== ==== ===========
15:0 0x1212      Constant
==== ====== ==== ===========

REG_34
~~~~~~

Internal register 2

- Address: ``0x03``
- Reset default: ``0x3434``

Fields
++++++

.. wavedrom::

    {"reg": [{"name": "0x3434", "bits": 16, "attr": ["ro"], "rotate": 0, "type": 3}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80, "bits": 16}}

==== ====== ==== ===========
Bits Reset  Name Description
==== ====== ==== ===========
15:0 0x3434      Constant
==== ====== ==== ===========

REG_56
~~~~~~

Internal register 3

- Address: ``0x04``
- Reset default: ``0x5656``

Fields
++++++

.. wavedrom::

    {"reg": [{"name": "0x5656", "bits": 16, "attr": ["ro"], "rotate": 0, "type": 3}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80, "bits": 16}}

==== ====== ==== ===========
Bits Reset  Name Description
==== ====== ==== ===========
15:0 0x5656      Constant
==== ====== ==== ===========

REG_78
~~~~~~

Internal register 4

- Address: ``0x05``
- Reset default: ``0x7878``

Fields
++++++

.. wavedrom::

    {"reg": [{"name": "0x7878", "bits": 16, "attr": ["ro"], "rotate": 0, "type": 3}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80, "bits": 16}}

==== ====== ==== ===========
Bits Reset  Name Description
==== ====== ==== ===========
15:0 0x7878      Constant
==== ====== ==== ===========

REG_9A
~~~~~~

Internal register 5

- Address: ``0xAB``
- Reset default: ``0x9A9A``

Fields
++++++

.. wavedrom::

    {"reg": [{"name": "0x9A9A", "bits": 16, "attr": ["ro"], "rotate": 0, "type": 3}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80, "bits": 16}}

==== ====== ==== ===========
Bits Reset  Name Description
==== ====== ==== ===========
15:0 0x9A9A      Constant
==== ====== ==== ===========

REG_CD
~~~~~~

Internal register 6

- Address: ``0xAC``
- Reset default: ``0xCDCD``

Fields
++++++

.. wavedrom::

    {"reg": [{"name": "0xCDCD", "bits": 16, "attr": ["ro"], "rotate": 0, "type": 3}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80, "bits": 16}}

==== ====== ==== ===========
Bits Reset  Name Description
==== ====== ==== ===========
15:0 0xCDCD      Constant
==== ====== ==== ===========

REG_EF
~~~~~~

Internal register 7

- Address: ``0xDC``
- Reset default: ``0xEFEF``

Fields
++++++

.. wavedrom::

    {"reg": [{"name": "0xEFEF", "bits": 16, "attr": ["ro"], "rotate": 0, "type": 3}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80, "bits": 16}}

==== ====== ==== ===========
Bits Reset  Name Description
==== ====== ==== ===========
15:0 0xEFEF      Constant
==== ====== ==== ===========

REG_SWITCHES
~~~~~~~~~~~~

Register returning the status of the input switches

- Address: ``0xB1``
- Reset default: ``0x0000``

Fields
++++++

.. wavedrom::

    {"reg": [{"name": "SWITCH_0", "bits": 1, "attr": ["ro"], "rotate": -90, "type": 3}, {"name": "SWITCH_1", "bits": 1, "attr": ["ro"], "rotate": -90, "type": 3}, {"name": "SWITCH_2", "bits": 1, "attr": ["ro"], "rotate": -90, "type": 3}, {"name": "Reserved", "bits": 13, "attr": ["ro"], "rotate": 0, "type": 2}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80}}

==== ===== ======== ==========================
Bits Reset Name     Description
==== ===== ======== ==========================
15:3 0x0            Reserved
2    0x0   SWITCH_2 Signal from PAD_I_SWITCH_2
2    0x0   SWITCH_1 Signal from PAD_I_SWITCH_1
0    0x0   SWITCH_0 Signal from PAD_I_SWITCH_0
==== ===== ======== ==========================

REG_LED
~~~~~~~

Register with LSB bit writable controlling an LED

- Address: ``0xEF``
- Reset default: ``0x0001``

Fields
++++++

.. wavedrom::

    {"reg": [{"name": "LED_0", "bits": 1, "attr": ["rw"], "rotate": -90, "type": 3}, {"name": "Reserved", "bits": 15, "attr": ["ro"], "rotate": 0, "type": 2}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80}}

==== ===== ===== ============
Bits Reset Name  Description
==== ===== ===== ============
15:1 0x0         Reserved
0    0x1   LED_0 Writable bit
==== ===== ===== ============

REG_16_BITS
~~~~~~~~~~~

Register with all bits writable

- Address: ``0xFF``
- Reset default: ``0x0000``

Fields
++++++

.. wavedrom::

    {"reg": [{"name": "DATA", "bits": 16, "attr": ["rw"], "rotate": 0, "type": 3}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80}}

==== ===== ==== ==========================
Bits Reset Name Description
==== ===== ==== ==========================
15:0 0x0   DATA 16-bit writable data field
==== ===== ==== ==========================
