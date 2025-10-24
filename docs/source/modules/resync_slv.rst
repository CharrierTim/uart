Resync slv
==========

Description
-----------

Re-synchronize asynchronous inputs to a destination clock domain using 3 DFF stages for
each bit of the input vector.

Generics
--------

=================== ======== ============= ==================================
Name                Type     Default Value Description
=================== ======== ============= ==================================
``G_WIDTH``         positive 0d8           Width of the input/output vector
``G_DEFAULT_VALUE`` vector   0x00          Default value of the output vector
=================== ======== ============= ==================================

Inputs and Outputs
------------------

================ ========= ========= =================== ==============================
Name             Type      Direction Default Value       Description
================ ========= ========= =================== ==============================
``CLK``          std_logic in        \-                  Input clock
``RST_N``        std_logic in        \-                  Input asynchronous reset,
                                                         active low
``I_DATA_ASYNC`` vector    in        \-                  Input vector containing
                                                         asynchronous signals
``O_DATA_SYNC``  vector    out       ``G_DEFAULT_VALUE`` Input vector resynchronized in
                                                         ``CLK`` domain
================ ========= ========= =================== ==============================

Overview
--------

.. image:: ../_static/svg/UART-RESYNC_SLV.svg
