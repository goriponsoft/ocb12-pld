--
-- PhaseMemory.vhd
--
-- Copyright (c) 2006 Mitsutaka Okazaki (brezza@pokipoki.org)
-- All rights reserved.
--
-- Redistribution and use of this source code or any derivative works, are
-- permitted provided that the following conditions are met:
--
-- 1. Redistributions of source code must retain the above copyright notice,
--    this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in the
--    documentation and/or other materials provided with the distribution.
-- 3. Redistributions may not be sold, nor may they be used in a commercial
--    product or activity without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
-- "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
-- TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
-- CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
-- EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
-- PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
-- OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
-- WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
-- OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
-- ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.VM2413.ALL;

entity PhaseMemory is
  port (
    clk     : in std_logic;
    reset   : in std_logic;
    slot    : in SLOT_TYPE;
    memwr   : in std_logic;
    memout  : out PHASE_TYPE;
    memin   : in  PHASE_TYPE
  );
end PhaseMemory;

architecture RTL of PhaseMemory is

  type PHASE_ARRAY_TYPE is array (0 to 18-1) of PHASE_TYPE;
  signal phase_array : PHASE_ARRAY_TYPE;

begin

  process (reset, clk)

    variable init_slot : integer range 0 to 18;

  begin

   if reset = '1' then

      init_slot := 0;

   elsif clk'event and clk = '1' then

     if init_slot /= 18 then

       phase_array(init_slot) <= (others => '0');
       init_slot := init_slot + 1;

     elsif memwr = '1' then

         phase_array(conv_integer(slot)) <= memin;

     end if;

     memout <= phase_array(conv_integer(slot));

    end if;

  end process;

end RTL;