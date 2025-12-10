-- =====================================================================================================================
--  MIT License
--
--  Copyright (c) 2025 Timothee Charrier
--
--  Permission is hereby granted, free of charge, to any person obtaining a copy
--  of this software and associated documentation files (the "Software"), to deal
--  in the Software without restriction, including without limitation the rights
--  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--  copies of the Software, and to permit persons to whom the Software is
--  furnished to do so, subject to the following conditions:
--
--  The above copyright notice and this permission notice shall be included in all
--  copies or substantial portions of the Software.
--
--  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--  SOFTWARE.
-- =====================================================================================================================
-- @project uart
-- @file    resync_slv.vhd
-- @version 1.1
-- @brief   Re-synchronize asynchronous inputs to a destination clock domain.
-- @author  Timothee Charrier
-- @date    10/12/2025
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      23/10/2025  Timothee Charrier   Initial release
-- 1.1      10/12/2025  Timothee Charrier   Rename generics
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;

-- =====================================================================================================================
-- ENTITY
-- =====================================================================================================================

entity RESYNC_SLV is
    generic (
        G_DATA_WIDTH         : positive := 8;
        G_DATA_DEFAULT_VALUE : std_logic_vector(G_DATA_WIDTH - 1 downto 0)
    );
    port (
        CLK          : in    std_logic;
        RST_N        : in    std_logic;
        I_DATA_ASYNC : in    std_logic_vector(G_DATA_DEFAULT_VALUE'range);
        O_DATA_SYNC  : out   std_logic_vector(G_DATA_DEFAULT_VALUE'range)
    );
end entity RESYNC_SLV;

-- =====================================================================================================================
-- ARCHITECTURE
-- =====================================================================================================================

architecture RESYNC_SLV_ARCH of RESYNC_SLV is

begin

    -- =================================================================================================================
    -- Generate the 3 DFF stages for each bit
    -- =================================================================================================================

    gen_resync : for data_idx in I_DATA_ASYNC'range generate
        signal reg_i_data_async    : std_logic;
        signal reg_i_data_async_d1 : std_logic;
        signal reg_i_data_async_d2 : std_logic;
    begin

        -- =============================================================================================================
        -- RESYNCHRONIZATION PROCESS
        -- =============================================================================================================

        p_sync : process (CLK, RST_N) is
        begin

            if (RST_N = '0') then

                reg_i_data_async    <= G_DATA_DEFAULT_VALUE(data_idx);
                reg_i_data_async_d1 <= G_DATA_DEFAULT_VALUE(data_idx);
                reg_i_data_async_d2 <= G_DATA_DEFAULT_VALUE(data_idx);

            elsif rising_edge(CLK) then

                reg_i_data_async    <= I_DATA_ASYNC(data_idx);
                reg_i_data_async_d1 <= reg_i_data_async;
                reg_i_data_async_d2 <= reg_i_data_async_d1;

            end if;

        end process p_sync;

        O_DATA_SYNC(data_idx) <= reg_i_data_async_d2;

    end generate gen_resync;

end architecture RESYNC_SLV_ARCH;
