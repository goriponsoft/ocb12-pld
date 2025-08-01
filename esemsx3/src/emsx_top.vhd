--
-- emsx_top.vhd
--   ESE MSX-SYSTEM3 / MSX clone on a Cyclone FPGA (ALTERA)
--   Revision 1.00
--
-- Copyright (c) 2006 Kazuhiro Tsujikawa (ESE Artists' factory)
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
----------------------------------------------------------------------------------
-- OCM-PLD Pack v3.9.2 by KdL (2025.06.29) / MSX2+ Stable Release for 1chipMSX
-- Special thanks to t.hara, caro, mygodess & all MRC users [https://www.msx.org]
----------------------------------------------------------------------------------
-- Setup for XTAL 21.47727MHz
----------------------------------------------------------------------------------
--

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_unsigned.all;
    use work.vdp_package.all;

entity emsx_top is
    generic(
        use_wifi_g          : boolean := true;
        use_midi_g          : boolean := false;
        set_low_scanlines_g : boolean := true
    );
    port(
        -- Clock, Reset ports
        pClk21m         : in    std_logic;                                      -- VDP Clock ... 21.48MHz
        pExtClk         : in    std_logic;                                      -- Reserved (for multi FPGAs)
        pCpuClk         : out   std_logic;                                      -- CPU Clock ... 3.58MHz (up to 10.74MHz/21.48MHz)

        -- MSX cartridge slot ports
        pSltClk         : in    std_logic;                                      -- pCpuClk returns here, for Z80, etc.
        pSltRst_n       : in    std_logic;                                      -- RESET_n  (with external pull-up)
        pSltSltsl_n     : inout std_logic;
        pSltSlts2_n     : inout std_logic;
        pSltIorq_n      : inout std_logic;
        pSltRd_n        : inout std_logic;
        pSltWr_n        : inout std_logic;
        pSltAdr         : inout std_logic_vector( 15 downto 0 );
        pSltDat         : inout std_logic_vector(  7 downto 0 );
        pSltBdir_n      : out   std_logic;                                      -- Bus direction (not used in master mode)

        pSltCs1_n       : inout std_logic;
        pSltCs2_n       : inout std_logic;
        pSltCs12_n      : inout std_logic;
        pSltRfsh_n      : inout std_logic;
        pSltWait_n      : inout std_logic;                                      -- WAIT_n   (with external pull-up)
        pSltInt_n       : inout std_logic;                                      -- INT_n    (with external pull-up)
        pSltM1_n        : inout std_logic;
        pSltMerq_n      : inout std_logic;

        pSltRsv5        : inout std_logic;                                      -- Reserved
        pSltRsv16       : inout std_logic;                                      -- Reserved (with external pull-up)
        pSltSw1         : inout std_logic;                                      -- Reserved
        pSltSw2         : inout std_logic;                                      -- Reserved

        -- SDRAM ports
        pMemClk         : out   std_logic;                                      -- SDRAM Clock
        pMemCke         : out   std_logic;                                      -- SDRAM Clock enable
        pMemCs_n        : out   std_logic;                                      -- SDRAM Chip select
        pMemRas_n       : out   std_logic;                                      -- SDRAM Row/RAS
        pMemCas_n       : out   std_logic;                                      -- SDRAM /CAS
        pMemWe_n        : out   std_logic;                                      -- SDRAM /WE
        pMemUdq         : out   std_logic;                                      -- SDRAM UDQM
        pMemLdq         : out   std_logic;                                      -- SDRAM LDQM
        pMemBa1         : out   std_logic;                                      -- SDRAM Bank select address 1
        pMemBa0         : out   std_logic;                                      -- SDRAM Bank select address 0
        pMemAdr         : out   std_logic_vector( 12 downto 0 );                -- SDRAM Address
        pMemDat         : inout std_logic_vector( 15 downto 0 );                -- SDRAM Data

        -- PS/2 keyboard ports
        pPs2Clk         : inout std_logic;
        pPs2Dat         : inout std_logic;

        -- Joystick ports (Port_A, Port_B)
        pJoyA           : inout std_logic_vector(  5 downto 0 );
        pStrA           : out   std_logic;
        pJoyB           : inout std_logic_vector(  5 downto 0 );
        pStrB           : out   std_logic;

        -- SD/MMC slot ports
        pSd_Ck          : out   std_logic;                                      -- pin 5
        pSd_Cm          : out   std_logic;                                      -- pin 2
        pSd_Dt          : inout std_logic_vector(  3 downto 0 );                -- pin 1(D3), 9(D2), 8(D1), 7(D0)

        -- DIP switch, Lamp ports
        pDip            : in    std_logic_vector(  7 downto 0 );                -- 0=On, 1=Off (default on shipment)
        pLed            : out   std_logic_vector(  7 downto 0 );                -- 0=Off, 1=On (green)
        pLedPwr         : out   std_logic;                                      -- 0=Off, 1=On (red)

        -- Video, Audio/CMT ports
        pDac_VR         : out   std_logic_vector(  5 downto 0 );                -- RGB_Red   / Svideo_C
        pDac_VG         : out   std_logic_vector(  5 downto 0 );                -- RGB_Green / Svideo_Y
        pDac_VB         : out   std_logic_vector(  5 downto 0 );                -- RGB_Blue  / Composite Video
        pDac_SL         : out   std_logic_vector(  5 downto 0 ) := "ZZZZZZ";    -- Sound-L
        pDac_SR         : inout std_logic_vector(  5 downto 0 ) := "ZZZZZZ";    -- Sound-R / CMT

        pVideoHS_n      : out   std_logic;                                      -- Csync(RGB15K), HSync(VGA31K)
        pVideoVS_n      : out   std_logic;                                      -- Audio(RGB15K), VSync(VGA31K)

        pVideoClk       : out   std_logic;                                      -- (Reserved)
        pVideoDat       : out   std_logic;                                      -- (Reserved)

        -- Reserved ports (USB)
        pUsbP1          : in    std_logic := 'Z';
        pUsbN1          : out   std_logic := 'Z';
        pUsbP2          : out   std_logic;
        pUsbN2          : out   std_logic;

        -- Reserved ports
        pIopRsv14       : in    std_logic;
        pIopRsv15       : in    std_logic;
        pIopRsv16       : in    std_logic;
        pIopRsv17       : in    std_logic;
        pIopRsv18       : in    std_logic;
        pIopRsv19       : in    std_logic;
        pIopRsv20       : in    std_logic;
        pIopRsv21       : in    std_logic
    );
end emsx_top;

architecture RTL of emsx_top is

    -- Clock generator ( Altera specific component )
    component pll4x
        port(
            inclk0  : in    std_logic := '0';   -- 21.48MHz input to PLL    (external I/O pin, from crystal oscillator)
            c0      : out   std_logic;          -- 21.48MHz output from PLL (internal LEs, for VDP, internal-bus, etc.)
            c1      : out   std_logic;          -- 85.92MHz output from PLL (internal LEs, for SDRAM)
            e0      : out   std_logic           -- 85.92MHz output from PLL (external I/O pin, for SDRAM)
        );
    end component;

    -- CPU
    component t80a
        port(
            RESET_n     : in    std_logic;
            R800_mode   : in    std_logic;
            CLK_n       : in    std_logic;
            WAIT_n      : in    std_logic;
            INT_n       : in    std_logic;
            NMI_n       : in    std_logic;
            BUSRQ_n     : in    std_logic;
            M1_n        : out   std_logic;
            MREQ_n      : out   std_logic;
            IORQ_n      : out   std_logic;
            RD_n        : out   std_logic;
            WR_n        : out   std_logic;
            RFSH_n      : out   std_logic;
            HALT_n      : out   std_logic;
            BUSAK_n     : out   std_logic;
            A           : out   std_logic_vector( 15 downto 0 );
            D           : inout std_logic_vector(  7 downto 0 )
        );
    end component;

    -- boot loader ROM (initial program loader)
    component iplrom
        port(
            clk     : in    std_logic;
            adr     : in    std_logic_vector( 15 downto 0 );
            dbi     : out   std_logic_vector(  7 downto 0 )
        );
    end component;

    -- MEGA-SD (SD controller)
    component megasd
        port(
            clk21m  : in    std_logic;
            reset   : in    std_logic;
            req     : in    std_logic;
            wrt     : in    std_logic;
            adr     : in    std_logic_vector( 15 downto 0 );
            dbo     : in    std_logic_vector(  7 downto 0 );

            ramreq  : out   std_logic;
            ramwrt  : out   std_logic;
            ramadr  : out   std_logic_vector( 19 downto 0 );

            mmcdbi  : out   std_logic_vector(  7 downto 0 );
            mmcena  : out   std_logic;
            mmcact  : out   std_logic;

            mmc_ck  : out   std_logic;
            mmc_cs  : out   std_logic;
            mmc_di  : out   std_logic;
            mmc_do  : in    std_logic;

            epc_ck  : out   std_logic;
            epc_cs  : out   std_logic;
            epc_oe  : out   std_logic;
            epc_di  : out   std_logic;
            epc_do  : in    std_logic;

            debug   : out   std_logic_vector(  7 downto 0 )
        );
    end component;

    -- ASMI (Altera specific component)
    component cyclone_asmiblock
        port(
            dclkin      : in    std_logic;      -- DCLK
            scein       : in    std_logic;      -- nCSO
            sdoin       : in    std_logic;      -- ASDO
            oe          : in    std_logic;      -- 1=disable(Hi-Z)
            data0out    : out   std_logic       -- DATA0
        );
    end component;

    component mapper
        port(
            clk21m      : in    std_logic;
            reset       : in    std_logic;
            req         : in    std_logic;
            ack         : out   std_logic;
            mem         : in    std_logic;
            wrt         : in    std_logic;
            adr         : in    std_logic_vector( 15 downto 0 );
            dbi         : out   std_logic_vector(  7 downto 0 );
            dbo         : in    std_logic_vector(  7 downto 0 );

            ramreq      : out   std_logic;
            ramwrt      : out   std_logic;
            ramadr      : out   std_logic_vector( 21 downto 0 );
            ramdbi      : in    std_logic_vector(  7 downto 0 );
            ramdbo      : out   std_logic_vector(  7 downto 0 )
        );
    end component;

    component eseps2
        port(
            clk21m      : in     std_logic;
            reset       : in     std_logic;
            clkena      : in     std_logic;

            Kmap        : in     std_logic;

            Caps        : inout  std_logic;
            Kana        : inout  std_logic;
            Paus        : inout  std_logic;
            Scro        : inout  std_logic;
            Reso        : inout  std_logic;

            FKeys       : buffer std_logic_vector(  7 downto 0 );

            pPs2Clk     : inout  std_logic;
            pPs2Dat     : inout  std_logic;

            PpiPortC    : in     std_logic_vector(  7 downto 0 );
            pKeyX       : out    std_logic_vector(  7 downto 0 );

            CmtScro     : inout  std_logic;

            Ps2Sel      : in     std_logic
        );
    end component;

    component rtc
        port(
            clk21m      : in    std_logic;
            reset       : in    std_logic;
            clkena      : in    std_logic;
            req         : in    std_logic;
            ack         : out   std_logic;
            wrt         : in    std_logic;
            adr         : in    std_logic_vector( 15 downto 0 );
            dbi         : out   std_logic_vector(  7 downto 0 );
            dbo         : in    std_logic_vector(  7 downto 0 )
        );
    end component;

    component kanji
        port(
            clk21m          : in    std_logic;
            reset           : in    std_logic;
            req             : in    std_logic;
            ack             : out   std_logic;
            wrt             : in    std_logic;
            adr             : in    std_logic_vector( 15 downto 0 );
            dbi             : out   std_logic_vector(  7 downto 0 );
            dbo             : in    std_logic_vector(  7 downto 0 );

            ramreq          : out   std_logic;
            ramadr          : out   std_logic_vector( 17 downto 0 );
            ramdbi          : in    std_logic_vector(  7 downto 0 );
            ramdbo          : out   std_logic_vector(  7 downto 0 )
        );
    end component;

    component vdp
        port(
            -- VDP Clock ... 21.477MHz
            clk21m          : in    std_logic;
            reset           : in    std_logic;
            req             : in    std_logic;
            ack             : out   std_logic;
            wrt             : in    std_logic;
            adr             : in    std_logic_vector( 15 downto 0 );
            dbi             : out   std_logic_vector(  7 downto 0 );
            dbo             : in    std_logic_vector(  7 downto 0 );

            int_n           : out   std_logic;

            pRamOe_n        : out   std_logic;
            pRamWe_n        : out   std_logic;
            pRamAdr         : out   std_logic_vector( 16 downto 0 );
            pRamDbi         : in    std_logic_vector( 15 downto 0 );
            pRamDbo         : out   std_logic_vector(  7 downto 0 );

            RatioMode       : in    std_logic_vector(  2 downto 0 );    -- for TH9958 VDP core
            centerYJK_R25_n : in    std_logic;                          -- for TH9958 VDP core

            -- Video Output
            pVideoR         : out   std_logic_vector(  5 downto 0 );
            pVideoG         : out   std_logic_vector(  5 downto 0 );
            pVideoB         : out   std_logic_vector(  5 downto 0 );

            pVideoHS_n      : out   std_logic;
            pVideoVS_n      : out   std_logic;
            pVideoCS_n      : out   std_logic;

            pVideoDHClk     : out   std_logic;
            pVideoDLClk     : out   std_logic;

            BLANK_o         : out   std_logic;
            InterlaceMode   : out   std_logic;

            -- Display resolution (0=15kHz, 1=31kHz)
            DispReso        : in    std_logic;

            ntsc_pal_type   : in    std_logic;
            forced_v_mode   : in    std_logic;
            legacy_vga      : in    std_logic;
            vga_int_field   : in    std_logic;

            spMaxSpr        : in    std_logic;

            VDP_ID          : in    std_logic_vector(  4 downto 0 );
            OFFSET_Y        : in    std_logic_vector(  6 downto 0 )
        );
    end component;

    component vencode
        port(
            clk21m      : in    std_logic;
            reset       : in    std_logic;
            videoR      : in    std_logic_vector(  5 downto 0 );
            videoG      : in    std_logic_vector(  5 downto 0 );
            videoB      : in    std_logic_vector(  5 downto 0 );
            videoHS_n   : in    std_logic;
            videoVS_n   : in    std_logic;
            videoY      : out   std_logic_vector(  5 downto 0 );
            videoC      : out   std_logic_vector(  5 downto 0 );
            videoV      : out   std_logic_vector(  5 downto 0 )
        );
    end component;

    component psg
        port(
            clk21m      : in    std_logic;
            reset       : in    std_logic;
            clkena      : in    std_logic;
            req         : in    std_logic;
            ack         : out   std_logic;
            wrt         : in    std_logic;
            adr         : in    std_logic_vector( 15 downto 0 );
            dbi         : out   std_logic_vector(  7 downto 0 );
            dbo         : in    std_logic_vector(  7 downto 0 );

            joya        : inout std_logic_vector(  5 downto 0 );
            stra        : out   std_logic;
            joyb        : inout std_logic_vector(  5 downto 0 );
            strb        : out   std_logic;

            kana        : out   std_logic;
            cmtin       : in    std_logic;
            keymode     : in    std_logic;

            wave        : out   std_logic_vector(  7 downto 0 )
        );
    end component;

    component megaram   -- ESE-MegaSCC+ / ESE-MegaRAM (not a brazilian MegaRAM)
        port(
            clk21m      : in    std_logic;
            reset       : in    std_logic;
            clkena      : in    std_logic;
            req         : in    std_logic;
            ack         : out   std_logic;
            wrt         : in    std_logic;
            adr         : in    std_logic_vector( 15 downto 0 );
            dbi         : out   std_logic_vector(  7 downto 0 );
            dbo         : in    std_logic_vector(  7 downto 0 );

            ramreq      : out   std_logic;
            ramwrt      : out   std_logic;
            ramadr      : out   std_logic_vector( 21 downto 0 );
            ramdbi      : in    std_logic_vector(  7 downto 0 );
            ramdbo      : out   std_logic_vector(  7 downto 0 );

            mapsel      : in    std_logic_vector(  1 downto 0 );        -- "0-":SCC+, "10":ASC8K, "11":ASC16K

            wavl        : out   std_logic_vector( 14 downto 0 );
            wavr        : out   std_logic_vector( 14 downto 0 );

            -- Extended MegaROM Reading                                 -- Added by KdL, 2024/Feb/03rd
            xmr_ena     : in    std_logic
        );
    end component;

    component eseopll
        port(
            clk21m      : in    std_logic;
            reset       : in    std_logic;
            clkena      : in    std_logic;
            enawait     : in    std_logic;
            req         : in    std_logic;
            ack         : out   std_logic;
            wrt         : in    std_logic;
            adr         : in    std_logic_vector( 15 downto 0 );
            dbo         : in    std_logic_vector(  7 downto 0 );
            wav         : out   std_logic_vector(  9 downto 0 )
            );
    end component;

    component esepwm
        generic(
            msbi    : integer
        );
        port(
            clk     : in    std_logic;
            reset   : in    std_logic;
            DACin   : in    std_logic_vector( msbi downto 0 );
            DACout  : out   std_logic
        );
    end component;

    component scc_mix_mul
        port(
            a           : in    std_logic_vector( 15 downto 0 );        -- 16bits signed
            b           : in    std_logic_vector(  2 downto 0 );        --  3bits unsigned
            c           : out   std_logic_vector( 18 downto 0 )         -- 19bits signed
        );
    end component;

    -- low pass filter 1
    component lpf1
        generic(
            msbi    : integer
        );
        port(
            clk21m  : in    std_logic;
            reset   : in    std_logic;
            clkena  : in    std_logic;
            idata   : in    std_logic_vector( msbi downto 0 );
            odata   : out   std_logic_vector( msbi downto 0 )
        );
    end component;

    -- low pass filter 2
    component lpf2
        generic(
            msbi    : integer
        );
        port(
            clk21m  : in    std_logic;
            reset   : in    std_logic;
            clkena  : in    std_logic;
            idata   : in    std_logic_vector( msbi downto 0 );
            odata   : out   std_logic_vector( msbi downto 0 )
        );
    end component;

    -- sound interpolation
    component interpo
        generic(
            msbi    : integer
        );
        port(
            clk21m  : in    std_logic;
            reset   : in    std_logic;
            clkena  : in    std_logic;
            idata   : in    std_logic_vector( msbi downto 0 );
            odata   : out   std_logic_vector( msbi downto 0 )
        );
    end component;

    component switched_io_ports
        generic(
            use_wifi_g      : boolean
        );
        port(
            clk21m          : in    std_logic;
            reset           : in    std_logic;
            power_on_reset  : in    std_logic;
            req             : in    std_logic;
            ack             : out   std_logic;
            wrt             : in    std_logic;
            adr             : in    std_logic_vector( 15 downto 0 );
            dbi             : out   std_logic_vector(  7 downto 0 );
            dbo             : in    std_logic_vector(  7 downto 0 );

            io40_n          : inout std_logic_vector(  7 downto 0 );            -- ID Manufacturers/Devices :   $08 (008), $D4 (212=OCM ID, now MSX++ ID), $FF (255=null)
            io41_id212_n    : inout std_logic_vector(  7 downto 0 );            -- $41 ID212 states         :   Smart Commands
            io42_id212      : inout std_logic_vector(  7 downto 0 );            -- $42 ID212 states         :   Virtual DIP-SW states
            io43_id212      : inout std_logic_vector(  7 downto 0 );            -- $43 ID212 states         :   Lock Mask for port $42 functions, CMT and System Reset
            io44_id212      : inout std_logic_vector(  7 downto 0 );            -- $44 ID212 states         :   Lights Mask has the green leds control when Lights Mode is On

            display_mode_req : inout std_logic_vector(  1 downto 0 );

            PsgVol          : inout std_logic_vector(  2 downto 0 );            -- PSG Volume
            MstrVol         : inout std_logic_vector(  2 downto 0 );            -- Master Volume
            OpllVol         : inout std_logic_vector(  2 downto 0 );            -- OPLL Volume
            SccVol          : inout std_logic_vector(  2 downto 0 );            -- SCC-I Volume

            CustomSpeed     : inout std_logic_vector(  3 downto 0 );            -- Counter limiter of CPU wait control
            tMegaSD         : inout std_logic;                                  -- Turbo on MegaSD access   :   3.58MHz to 5.37MHz auto selection
            tPanaRedir      : inout std_logic;                                  -- tPana Redirection switch
            Mapper_req      : inout std_logic;                                  -- Mapper req               :   Warm Reset is required to complete the request
            Mapper_ack      : out   std_logic;                                  -- Current Mapper state
            MegaSD_req      : inout std_logic;                                  -- MegaSD req               :   Warm Reset is required to complete the request
            MegaSD_ack      : out   std_logic;                                  -- Current MegaSD state

            io41_id008_n    : inout std_logic;                                  -- $41 ID008 BIT-0 state    :   0=5.37MHz, 1=3.58MHz (write_n only)
            swioKmap        : inout std_logic;                                  -- Keyboard layout selector
            CmtScro         : inout std_logic;                                  -- CMT state
            swioCmt         : inout std_logic;                                  -- CMT enabler              :   This toggle is used for the Internal OPL3 on SM-X, SX-2 and SX-E
            LightsMode      : inout std_logic;                                  -- Custom green led states
            Red_sta         : inout std_logic;                                  -- Custom red led state
            LastRst_sta     : inout std_logic;                                  -- Last reset state         :   0=F4 Cold Reset, 1=F4 Warm Reset (MSX2+) / 1=F4 Cold Reset, 0=F4 Warm Reset (MSXtR)
            RstReq_sta      : inout std_logic;                                  -- Reset request state      :   0=No, 1=Yes
            Blink_ena       : inout std_logic;                                  -- MegaSD blink led enabler

            pseudoStereo    : inout std_logic;                                  -- RCA-LEFT(red)=External Audio Card / RCA-RIGHT(white)=Internal Sounds
            extclk3m        : inout std_logic;                                  -- External Clock 3.58MHz   :   0=No, 1=Yes
            ntsc_pal_type   : inout std_logic;                                  -- NTSC/PAL Type            :   0=Forced, 1=Auto
            forced_v_mode   : inout std_logic;                                  -- Forced Video Mode        :   0=60Hz, 1=50Hz

            right_inverse   : inout std_logic;                                  -- Right Inverse Audio      :   0=Off (normal wave), 1=On (inverse wave)
            centerYJK_R25_n : inout std_logic;                                  -- Centering YJK Modes/R25 Mask (0=centered, 1=shifted to the right)
            legacy_sel      : inout std_logic;                                  -- Legacy Output selector   :   0=Assigned to VGA, 1=Assigned to VGA+
            iSlt1_linear    : inout std_logic;                                  -- Internal Slot1 Linear    :   0=Disabled, 1=Enabled
            iSlt2_linear    : inout std_logic;                                  -- Internal Slot2 Linear    :   0=Disabled, 1=Enabled

            btn_scan        : in    std_logic;                                  -- Scanlines button
            vga_scanlines   : inout std_logic_vector(  1 downto 0 );            -- VGA Scanlines None, Light, Medium or Heavy (default is None)
            bios_reload_ack : out   std_logic;                                  -- OCM-BIOS Reloading ack
            Mapper0_req     : inout std_logic;                                  -- Extra-Mapper req         :   Warm Reset is required to complete the request

            xmr_ena         : inout std_logic;                                  -- Extended MegaROM Reading :   0=Off (default for compatibility), 1=On
            OFFSET_Y        : inout std_logic_vector(  6 downto 0 );            -- Vertical Offset ID 16-24

            spMaxSpr        : inout std_logic;                                  -- Sprite Limit             :   0=4/8 (standard), 1=8/8 (enhanced)
            vga_int_field   : inout std_logic;                                  -- VGA Interlace Field      :   0=Single (default), 1=Duplicate
            low_scale_n     : in    std_logic;                                  -- VGA Scanlines variant    :   0=Low-Scale (0%|12%|25%|50%), 1=High-Scale (0%|25%|50%|75%)
            Mapper0_ack     : inout std_logic;                                  -- Current Extra-Mapper state
            safe_mode       : inout std_logic;                                  -- Safe Mode                :   0=Off (default), 1=On [Reserved for IPL-ROM]
            portF2_ena      : inout std_logic;                                  -- F2 Device enabler

            ff_dip_req      : in    std_logic_vector(  7 downto 0 );            -- DIP-SW states/reqs
            ff_dip_ack      : inout std_logic_vector(  7 downto 0 );            -- DIP-SW acks

            DefKmap         : inout std_logic;                                  -- Default keyboard layout  :   0=JP, 1=Non-JP (BR, ES, FR, IT, US, ...)

            ff_ldbios_n     : in    std_logic;                                  -- OCM-BIOS loading status
            VDP_ID          : out   std_logic_vector(  4 downto 0 );            -- VDP ID 0 (V9938) or VDP ID 2 (V9958)
            JIS2_ena        : inout std_logic;                                  -- JIS2 enabler             :   0=JIS1 only (BIOS 384 KB), 1=JIS1+JIS2 (BIOS 512 KB)

            Scro            : in    std_logic;
            ff_Scro         : in    std_logic;
            Reso            : in    std_logic;
            ff_Reso         : in    std_logic;
            FKeys           : in    std_logic_vector(  7 downto 0 );
            vFKeys          : in    std_logic_vector(  7 downto 0 );
            LevCtrl         : inout std_logic_vector(  2 downto 0 );            -- Volume and high-speed level
            GreenLvEna      : out   std_logic;

            swioRESET_n     : inout std_logic;                                  -- Reset Pulse
            warmRESET       : inout std_logic;                                  -- 0=Cold Reset, 1=Warm Reset
            WarmMSXlogo     : inout std_logic;                                  -- Show MSX logo with Warm Reset
            full_reset_comb : in    std_logic;                                  -- Full Reset combination
            cold_reset_comb : in    std_logic                                   -- Cold Reset combination
        );
    end component;

    -- Switched I/O ports
    signal  swio_req        : std_logic;
    signal  swio_dbi        : std_logic_vector(  7 downto 0 );
    signal  io40_n          : std_logic_vector(  7 downto 0 ) := (others => '1');
    signal  io41_id212_n    : std_logic_vector(  7 downto 0 );
    signal  io42_id212      : std_logic_vector(  7 downto 0 );
    signal  io43_id212      : std_logic_vector(  7 downto 0 ) := (others => '0');
    alias   RstKeyLock      : std_logic is io43_id212(5);                           -- RESET_n lock does not work on Cyclone I machine slot pins without a hardware patch
    signal  io44_id212      : std_logic_vector(  7 downto 0 );
    alias   GreenLeds       : std_logic_vector(  7 downto 0 ) is io44_id212;
    signal  CustomSpeed     : std_logic_vector(  3 downto 0 );
    signal  tMegaSD         : std_logic;
    signal  tPanaRedir      : std_logic;
    signal  Mapper_req      : std_logic;
    signal  Mapper_ack      : std_logic;
    signal  MegaSD_req      : std_logic;
    signal  MegaSD_ack      : std_logic;
    signal  io41_id008_n    : std_logic;
    signal  swioKmap        : std_logic;
    signal  CmtScro         : std_logic := '0';
    signal  swioCmt         : std_logic := '0';
    signal  LightsMode      : std_logic;
    signal  Red_sta         : std_logic;
    signal  LastRst_sta     : std_logic;
    signal  RstReq_sta      : std_logic;
    signal  Blink_ena       : std_logic;
    signal  pseudoStereo    : std_logic;
    signal  extclk3m        : std_logic;
    signal  right_inverse   : std_logic;
    signal  centerYJK_R25_n : std_logic;
    signal  legacy_sel      : std_logic;
    signal  iSlt1_linear    : std_logic;
    signal  iSlt2_linear    : std_logic;
    signal  btn_scan        : std_logic := '1';
    signal  vga_scanlines   : std_logic_vector(  1 downto 0 ) := "00";
    signal  bios_reload_ack : std_logic := '0';
    signal  Mapper0_req     : std_logic;
    signal  xmr_ena         : std_logic;
    signal  low_scale_n     : std_logic;
    signal  Mapper0_ack     : std_logic;
    signal  safe_mode       : std_logic := '0';
    signal  ff_dip_req      : std_logic_vector(  7 downto 0 ) := "10000011";        -- overwrites any startup errors with the most common settings
    signal  ff_dip_ack      : std_logic_vector(  7 downto 0 );
    signal  DefKmap         : std_logic;
    signal  JIS2_ena        : std_logic;
    signal  LevCtrl         : std_logic_vector(  2 downto 0 );
    signal  GreenLvEna      : std_logic;
    signal  swioRESET_n     : std_logic := '1';
    signal  warmRESET       : std_logic := '0';
    signal  WarmMSXlogo     : std_logic;
    signal  full_reset_comb : std_logic;
    signal  cold_reset_comb : std_logic;

    -- Operation mode
    signal  w_key_mode      : std_logic;                                            -- Kana keyboard layout: 1=JIS layout (PSG)
    signal  Kmap            : std_logic;                                            -- '0': Japanese-106    '1': Non-Japanese (English-101, French, ..)
    signal  DisplayMode     : std_logic_vector(  1 downto 0 ) := "00";
    signal  display_mode_req : std_logic_vector(  1 downto 0 );
    signal  odd_line_s      : std_logic := '0';
    signal  Slot1Mode       : std_logic;
    signal  Slot2Mode       : std_logic_vector(  1 downto 0 );
    signal  iSlt0_1         : std_logic := '0';                                     -- '0': disable Slot0-1 '1': enable Slot0-1
    alias   FullRAM         : std_logic is Mapper_ack;                              -- '0': 2048 KB RAM     '1': 4096 KB RAM
    alias   MmcMode         : std_logic is MegaSD_ack;                              -- '0': disable SD/MMC  '1': enable SD/MMC

    -- Clock, Reset control signals
    signal  clk21m          : std_logic;
    signal  memclk          : std_logic;
    signal  cpuclk          : std_logic := '1';
    signal  clkena          : std_logic := '0';
    signal  clkdiv          : std_logic_vector(  1 downto 0 ) := "10";              -- sync at 5.37MHz
    signal  ff_clksel       : std_logic;
    signal  ff_clksel5m_n   : std_logic;
    signal  hybridclk_n     : std_logic;
    signal  hybstartcnt     : std_logic_vector(  2 downto 0 );
    signal  hybtoutcnt      : std_logic_vector(  2 downto 0 );
    signal  reset           : std_logic;
    signal  RstSeq          : std_logic_vector(  4 downto 0 ) := (others => '0');
    signal  FreeCounter     : std_logic_vector( 15 downto 0 ) := (others => '0');
    signal  HardRst_cnt     : std_logic_vector(  3 downto 0 ) := (others => '0');
    signal  LogoRstCnt      : std_logic_vector(  5 downto 0 ) := (others => '0');
    signal  logo_timeout    : std_logic_vector(  1 downto 0 );
    signal  iCpuClk         : std_logic;
    signal  power_on_reset  : std_logic := '0';

    -- MSX cartridge slot control signals
    signal  iSltRst_n       : std_logic := '0';
    signal  xSltRst_n       : std_logic := '1';
    signal  BusDir          : std_logic;
    signal  BusDir_o        : std_logic;
    signal  iSltRfsh_n      : std_logic;
    signal  iSltMerq_n      : std_logic;
    signal  iSltIorq_n      : std_logic;
    signal  xSltRd_n        : std_logic;
    signal  xSltWr_n        : std_logic;
    signal  iSltAdr         : std_logic_vector( 15 downto 0 );
    signal  iSltDat         : std_logic_vector(  7 downto 0 );
    signal  dlydbi          : std_logic_vector(  7 downto 0 );
    signal  CpuM1_n         : std_logic;
    signal  CpuRfsh_n       : std_logic;
    signal  wait_n_s        : std_logic := '1';

    -- Internal bus signals (common)
    signal  req             : std_logic;
    signal  ack             : std_logic;
    signal  iack            : std_logic;
    signal  mem             : std_logic;
    signal  wrt             : std_logic;
    signal  adr             : std_logic_vector( 15 downto 0 );
    signal  dbi             : std_logic_vector(  7 downto 0 );
    signal  dbo             : std_logic_vector(  7 downto 0 );

    -- Primary, Expansion slot signals
    signal  ExpDbi          : std_logic_vector(  7 downto 0 );
    signal  ExpSlot0        : std_logic_vector(  7 downto 0 );
    signal  ExpSlot3        : std_logic_vector(  7 downto 0 );
    signal  PriSltNum       : std_logic_vector(  1 downto 0 );
    signal  ExpSltNum0      : std_logic_vector(  1 downto 0 );
    signal  ExpSltNum3      : std_logic_vector(  1 downto 0 );

    -- Slot decode signals
    signal  iSltBot         : std_logic;
    signal  iSltMap0        : std_logic := '0';
    signal  iSltMap         : std_logic;
    signal  jSltMem         : std_logic;
    signal  iSltScc1        : std_logic;
    signal  jSltScc1        : std_logic;
    signal  iSltScc2        : std_logic;
    signal  jSltScc2        : std_logic;
    signal  iSltErm         : std_logic;
    signal  iSltLin1        : std_logic;
    signal  iSltLin2        : std_logic;

    -- BIOS-ROM decode signals
    signal  RomReq          : std_logic;
    signal  rom_main        : std_logic;
    signal  rom_opll        : std_logic;
    signal  rom_extd        : std_logic;
    signal  rom_kanj        : std_logic;
    signal  rom_xbas        : std_logic;
    signal  rom_free        : std_logic;

    -- IPL-ROM signals
    signal  RomDbi          : std_logic_vector(  7 downto 0 );
    signal  ff_ldbios_n     : std_logic := '0';
    signal  ff_reload_n     : std_logic := '0';

    -- ESE-RAM signals
    signal  ErmReq          : std_logic;
    signal  ErmRam          : std_logic;
    signal  ErmWrt          : std_logic;
    signal  ErmAdr          : std_logic_vector( 19 downto 0 );

    -- SD/MMC signals
    signal  MmcEna          : std_logic;
    signal  MmcAct          : std_logic;
    signal  MmcDbi          : std_logic_vector(  7 downto 0 );
    signal  MmcEnaLed       : std_logic;
    signal  Blink_s         : std_logic;

    -- EPCS/ASMI signals
    signal  EPC_CK          : std_logic;
    signal  EPC_CS          : std_logic;
    signal  EPC_OE          : std_logic;
    signal  EPC_DI          : std_logic;
    signal  EPC_DO          : std_logic;

    -- Mapper RAM signals
    signal  MapReq          : std_logic;
    signal  MapDbi          : std_logic_vector(  7 downto 0 );
    signal  MapRam          : std_logic;
    signal  MapWrt          : std_logic;
    signal  MapAdr          : std_logic_vector( 21 downto 0 );

    -- PPI(8255) signals
    signal  PpiReq          : std_logic;
    signal  PpiDbi          : std_logic_vector(  7 downto 0 );
    signal  PpiPortA        : std_logic_vector(  7 downto 0 );
    signal  PpiPortB        : std_logic_vector(  7 downto 0 );
    signal  PpiPortC        : std_logic_vector(  7 downto 0 );

    signal  w_page_dec      : std_logic_vector(  3 downto 0 );
    signal  w_prislt_dec    : std_logic_vector(  3 downto 0 );
    signal  w_expslt0_dec   : std_logic_vector(  3 downto 0 );
    signal  w_expslt3_dec   : std_logic_vector(  3 downto 0 );

    -- PS/2 signals
    signal  Paus            : std_logic;
    signal  Scro            : std_logic;
    signal  Reso            : std_logic;
    signal  Reso_v          : std_logic;
    signal  Kana            : std_logic;
    signal  Caps            : std_logic;
    signal  Fkeys           : std_logic_vector(  7 downto 0 );

    -- CMT signals
    signal  CmtIn           : std_logic;
    alias   CmtOut          : std_logic is PpiPortC(5);

    -- 1bit sound port signal
    alias   KeyClick        : std_logic is PpiPortC(7);

    -- RTC signals
    signal  RtcReq          : std_logic;
    signal  RtcDbi          : std_logic_vector(  7 downto 0 );
    signal  rtcclk          : std_logic := '1';
    signal  rtcena          : std_logic := '0';
    signal  rtcdiv3         : std_logic_vector(  1 downto 0 ) := "10";

    -- Kanji signals
    signal  KanReq          : std_logic;
    signal  KanDbi          : std_logic_vector(  7 downto 0 );
    signal  KanRom          : std_logic;
    signal  KanAdr          : std_logic_vector( 17 downto 0 );

    -- VDP signals
    signal  VdpReq          : std_logic;
    signal  VdpDbi          : std_logic_vector(  7 downto 0 );
    signal  VideoSC         : std_logic;
    signal  VideoDLClk      : std_logic;
    signal  VideoDHClk      : std_logic;
    signal  WeVdp_n         : std_logic;
    signal  VdpAdr          : std_logic_vector( 16 downto 0 );
    signal  VrmDbo          : std_logic_vector(  7 downto 0 );
    signal  VrmDbi          : std_logic_vector( 15 downto 0 );
    signal  pVdpInt_n       : std_logic;
    signal  centerYJK_R25_s : std_logic;
    signal  interlace_mode  : std_logic;
    signal  ntsc_pal_type   : std_logic;
    signal  forced_v_mode   : std_logic;
    signal  legacy_vga      : std_logic;
    signal  vga_int_field   : std_logic;
    signal  spMaxSpr        : std_logic;
    signal  VDP_ID          : std_logic_vector(  4 downto 0 );
    signal  OFFSET_Y        : std_logic_vector(  6 downto 0 );

    -- Video signals
    signal  VideoR          : std_logic_vector( 5 downto 0 );                       -- RGB Red
    signal  VideoG          : std_logic_vector( 5 downto 0 );                       -- RGB Green
    signal  VideoB          : std_logic_vector( 5 downto 0 );                       -- RGB Blue
    signal  VideoHS_n       : std_logic;                                            -- Horizontal Sync
    signal  VideoVS_n       : std_logic;                                            -- Vertical Sync
    signal  VideoCS_n       : std_logic;                                            -- Composite Sync
    signal  videoY          : std_logic_vector(  5 downto 0 );                      -- S-Video Y
    signal  videoC          : std_logic_vector(  5 downto 0 );                      -- S-Video C
    signal  videoV          : std_logic_vector(  5 downto 0 );                      -- Composite Video

    -- PSG signals
    signal  PsgReq          : std_logic;
    signal  PsgDbi          : std_logic_vector(  7 downto 0 );
    signal  PsgAmp          : std_logic_vector(  7 downto 0 );

    -- SCC signals
    signal  Scc1Req         : std_logic;
    signal  Scc1Ack         : std_logic;
    signal  Scc1Dbi         : std_logic_vector(  7 downto 0 );
    signal  Scc1Ram         : std_logic;
    signal  Scc1Wrt         : std_logic;
    signal  Scc1Adr         : std_logic_vector( 21 downto 0 );
    signal  Scc1AmpL        : std_logic_vector( 14 downto 0 );

    signal  Scc2Req         : std_logic;
    signal  Scc2Ack         : std_logic;
    signal  Scc2Dbi         : std_logic_vector(  7 downto 0 );
    signal  Scc2Ram         : std_logic;
    signal  Scc2Wrt         : std_logic;
    signal  Scc2Adr         : std_logic_vector( 21 downto 0 );
    signal  Scc2AmpL        : std_logic_vector( 14 downto 0 );

    signal  Scc1Type        : std_logic_vector(  1 downto 0 );

    -- OPLL signals
    signal  OpllReq         : std_logic;
    signal  OpllAck         : std_logic;
    signal  OpllAmp         : std_logic_vector(  9 downto 0 );
    signal  OpllEnaWait     : std_logic;

    -- Sound signals
    constant DAC_msbi       : integer := 13;
    signal  DACin           : std_logic_vector( DAC_msbi downto  0 );
    signal  DACout          : std_logic;

    signal  OpllVol         : std_logic_vector(  2 downto 0 ) := "100";
    signal  SccVol          : std_logic_vector(  2 downto 0 ) := "100";
    signal  PsgVol          : std_logic_vector(  2 downto 0 ) := "100";
    signal  MstrVol         : std_logic_vector(  2 downto 0 ) := "000";

    -- External memory signals
    signal  RamReq          : std_logic;
    signal  RamAck          : std_logic;
    signal  RamDbi          : std_logic_vector(  7 downto 0 );
    signal  CpuAdr          : std_logic_vector( 24 downto 0 );

    -- SDRAM control signals
    signal  SdrSta          : std_logic_vector(  2 downto 0 );
    signal  SdrCmd          : std_logic_vector(  3 downto 0 );
    signal  SdrBa           : std_logic_vector(  1 downto 0 ) := "00";
    signal  SdrUdq          : std_logic;
    signal  SdrLdq          : std_logic;
    signal  SdrAdr          : std_logic_vector( 12 downto 0 ) := (others => '0');
    signal  SdrDat          : std_logic_vector( 15 downto 0 );

    constant SdrCmd_de      : std_logic_vector(  3 downto 0 ) := "1111";            -- deselect
    constant SdrCmd_pr      : std_logic_vector(  3 downto 0 ) := "0010";            -- precharge all
    constant SdrCmd_re      : std_logic_vector(  3 downto 0 ) := "0001";            -- refresh
    constant SdrCmd_ms      : std_logic_vector(  3 downto 0 ) := "0000";            -- mode register set

    constant SdrCmd_xx      : std_logic_vector(  3 downto 0 ) := "0111";            -- no operation
    constant SdrCmd_ac      : std_logic_vector(  3 downto 0 ) := "0011";            -- activate
    constant SdrCmd_rd      : std_logic_vector(  3 downto 0 ) := "0101";            -- read
    constant SdrCmd_wr      : std_logic_vector(  3 downto 0 ) := "0100";            -- write

    -- Clock divider
    signal  clkdiv3         : std_logic_vector(  1 downto 0 ) := "10";
    signal  ff_mem_seq      : std_logic_vector(  1 downto 0 );

    -- Operation mode
    signal  ff_clk21m_cnt   : std_logic_vector( 20 downto 0 ) := (others => '0');   -- free run counter
    signal  GreenLv         : std_logic_vector(  6 downto 0 );                      -- green level
    signal  GreenLv_cnt     : std_logic_vector(  3 downto 0 );                      -- green level counter
    alias   FadedRed        : std_logic is ff_clk21m_cnt(0);
    alias   FadedGreen      : std_logic is ff_clk21m_cnt(12);

    -- w_10hz with LFSR counter
    signal  w_10hz_lfsr     : std_logic_vector( 21 downto 0 ) := (others => '0');
    signal  w_10hz_d0       : std_logic;
    signal  w_10hz          : std_logic := '1';

    -- Sound output, toggle keys
    signal  vFKeys          : std_logic_vector(  7 downto 0 );
    signal  ff_Scro         : std_logic;
    signal  ff_Reso         : std_logic;

    -- DRAM arbiter
    signal  w_wrt_req       : std_logic;

    -- SDRAM controller
    signal  ff_sdr_seq      : std_logic_vector(  2 downto 0 );

    -- F2 Device (ESP8266 BIOS)
    signal  portF2_ena      : std_logic := '1';
    signal  portF2_req      : std_logic;
    signal  portF2          : std_logic_vector(  7 downto 0 ) := (others => '1');

    -- F4 device
    signal  portF4_req      : std_logic;
    signal  portF4_bit7     : std_logic;                                            -- 1=hard reset, 0=soft reset

    -- Mixer
    signal  ff_prepsg       : std_logic_vector(  8 downto 0 );
    signal  ff_prescc       : std_logic_vector( 15 downto 0 );
    signal  ff_psg          : std_logic_vector( DACin'high + 2 downto DACin'low );
    signal  ff_scc          : std_logic_vector( DACin'high + 2 downto DACin'low );
    signal  w_scc           : std_logic_vector( 18 downto 0 );
    signal  m_SccVol        : std_logic_vector(  2 downto 0 );
    signal  ff_opll         : std_logic_vector( DACin'high + 2 downto DACin'low );
    signal  ff_psg_offset   : std_logic_vector( DACin'high + 2 downto DACin'low );
    signal  ff_scc_offset   : std_logic_vector( DACin'high + 2 downto DACin'low );
    signal  ff_pre_dacin    : std_logic_vector( DACin'high + 2 downto DACin'low );
    constant c_opll_offset  : std_logic_vector( DACin'high + 2 downto DACin'low ) := (ff_pre_dacin'high => '1', others => '0');
    constant c_opll_zero    : std_logic_vector( OpllAmp'range ) := (OpllAmp'high => '1', others => '0');

    -- Sound output filter
    signal  lpf1_wave       : std_logic_vector( DACin'high downto 0 );
    signal  lpf5_wave       : std_logic_vector( DACin'high downto 0 );

    -- ESP signals
    signal  esp_dout_s      : std_logic_vector(  7 downto 0 ) := (others => '1');
    signal  esp_wait_s      : std_logic := '1';
    signal  esp_tx_i        : std_logic;
    signal  esp_rx_o        : std_logic;

    -- MIDI signals
    signal  midi_o          : std_logic := 'Z';
    signal  midi_active_o   : std_logic := '0';
    signal  midi_dout_s     : std_logic_vector(  7 downto 0 ) := (others => '1');

begin

    ----------------------------------------------------------------
    -- Clock generator (21.48MHz > 3.58MHz)
    -- pCpuClk should be independent from reset
    ----------------------------------------------------------------

    -- Clock enabler : 3.58MHz = 21.48MHz / 6
    process( reset, clk21m )
    begin
        if( reset = '1' )then
            clkena <= '0';
        elsif( clk21m'event and clk21m = '1' )then
            if( clkdiv3 = "00" )then
                clkena <= cpuclk;
            else
                clkena <= '0';
            end if;
        end if;
    end process;

    -- CPUCLK : 3.58MHz = 21.48MHz / 6
    process( reset, clk21m )
    begin
        if( reset = '1' )then
            cpuclk <= '1';
        elsif( clk21m'event and clk21m = '1' )then
            if( clkdiv3 = "10" )then
                cpuclk <= not cpuclk;
            else
                -- hold
            end if;
        end if;
    end process;

    -- CPUCLK Prescaler : 21.48MHz / 6
    process( reset, clk21m )
    begin
        if( reset = '1' )then
            clkdiv3 <= "10";
        elsif( clk21m'event and clk21m = '1' )then
            if( clkdiv3 = "00" )then
                clkdiv3 <= "10";
            else
                clkdiv3 <= clkdiv3 - 1;
            end if;
        end if;
    end process;

    -- Turbo Clocks Prescaler : 21.48MHz / 4
    process( reset, clk21m )
    begin
        if( reset = '1' )then
            clkdiv <= "10";                                                             -- sync at 5.37MHz
        elsif( clk21m'event and clk21m = '1' )then
            clkdiv <= clkdiv - 1;
        end if;
    end process;

    -- hybrid clock start counter
    process( reset, clk21m )
    begin
        if( reset = '1' )then
            hybstartcnt <= (others => '0');
        elsif( clk21m'event and clk21m = '1' )then
            if( ff_clk21m_cnt( 16 downto 0 ) = "00000000000000000" )then
                if( MmcEna = '0' )then
                    hybstartcnt <= "111";                                               -- begin after 48ms
                elsif( hybstartcnt /= "000" )then
                    hybstartcnt <= hybstartcnt - 1;
                end if;
            end if;
        end if;
    end process;

    -- hybrid clock timeout counter
    process( reset, clk21m )
    begin
        if( reset = '1' )then
            hybtoutcnt <= (others => '0');
        elsif( clk21m'event and clk21m = '1' )then
            if( hybstartcnt = "000" or hybtoutcnt /= "000" )then
                if( MmcEna = '1' )then
                    hybtoutcnt <= "111";                                                -- timeout after 96ms
                elsif( ff_clk21m_cnt( 17 downto 0 ) = "000000000000000000" )then
                    hybtoutcnt <= hybtoutcnt - 1;
                end if;
            end if;
        end if;
    end process;

    -- hybrid clock enabler
    process( reset, clk21m )
    begin
        if( reset = '1' )then
            hybridclk_n <= '1';
        elsif( clk21m'event and clk21m = '1' )then
            if( hybtoutcnt = "000" )then
                hybridclk_n <= '1';
            else
                hybridclk_n <= not tMegaSD;
            end if;
        end if;
    end process;

    -- logo speed limiter
    process( reset, clk21m )
    begin
        if( reset = '1' )then
            logo_timeout <= "00";
        elsif( clk21m'event and clk21m = '1' )then
            if( ff_ldbios_n = '0' )then                                                 -- times change depending on the mappers installed
                if( LastRst_sta = '0' )then
                    LogoRstCnt <= "110000";                                             -- 4800ms : OCM-BIOS begins
                end if;
            elsif( w_10hz = '1' and LogoRstCnt /= "000000" )then
                LogoRstCnt <= LogoRstCnt - 1;
                if( LogoRstCnt = "100010" )then                                         -- 3400ms : MSX2+ animation starts here if no external mapper has been found
                    logo_timeout <= "01";
                elsif( LogoRstCnt = "001010" )then                                      -- 1000ms : MSX2+ logo ends
                    logo_timeout <= "10";
                end if;
            elsif( LogoRstCnt = "000000" )then                                          -- 0ms : BEEP sound ends if 5.37MHz
                logo_timeout <= "11";
            end if;
        end if;
    end process;

    -- virtual DIP-SW assignment (1/2)
    process( clk21m )
    begin
        if( clk21m'event and clk21m = '0' )then
            if( cpuclk = '0' and clkdiv = "00" and wait_n_s = '0' )then
                case logo_timeout is
                    when "00" =>                                                        -- ultra-fast boot : 8.06MHz when IPL-ROM is running
                        ff_clksel5m_n       <=  '1';                                    -- set 8.06MHz
                        ff_clksel           <=  '1';
                    when "01" =>                                                        -- logo speed limiter : 3.58MHz for 3800ms after startup
                        ff_clksel5m_n       <=  '1';                                    -- set 3.58MHz
                        ff_clksel           <=  '0';
                    when "10" =>                                                        -- reduce 8.06MHz to 5.37MHz for 1000ms : helps to recognize some cartridges
                        ff_clksel5m_n       <=  not io42_id212(0);                      -- set 5.37MHz otherwise stay at 3.58MHz
                        ff_clksel           <=  '0';
                    when others =>
                        if( io42_id212(0) = '0' )then                                   -- hybrid clock enabled : 3.58MHz to 5.37MHz + VDP fast mode, if mmcena = '1'
                            ff_clksel5m_n   <=  io41_id008_n    and hybridclk_n;
                            ff_clksel       <=  io42_id212(0)   and hybridclk_n;
                        else                                                            -- hybrid clock disabled
                            ff_clksel5m_n   <=  io41_id008_n;
                            ff_clksel       <=  io42_id212(0);
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- virtual DIP-SW assignment (2/2)
    process( clk21m )
    begin
        if( clk21m'event and clk21m = '1' )then
            Kmap            <=  swioKmap;                                               -- keyboard layout assignment
            CmtScro         <=  swioCmt;
            Slot1Mode       <=  io42_id212(3);
            Slot2Mode(1)    <=  io42_id212(4);
            Slot2Mode(0)    <=  io42_id212(5);
        end if;
    end process;

    -- cpu clock assignment
    iCpuClk <=  '1'         when( power_on_reset = '0' )else
                rtcclk      when( reset = '1' )else                                     --  3.58MHz
                clkdiv(0)   when( ff_clksel = '1' )else                                 -- 10.74MHz
                clkdiv(1)   when( ff_clksel5m_n = '0' )else                             --  5.37MHz
                cpuclk;                                                                 --  3.58MHz

    -- clock assignment for external slots
    pCpuClk <=  '1'         when( power_on_reset = '0' )else
                rtcclk      when( reset = '1' )else                                     --  3.58MHz
                clkdiv(0)   when( extclk3m = '0' and ff_clksel = '1' )else              -- 10.74MHz
                clkdiv(1)   when( extclk3m = '0' and ff_clksel5m_n = '0' )else          --  5.37MHz
                cpuclk;                                                                 --  3.58MHz

    ----------------------------------------------------------------
    -- Real Time Clock enabler
    ----------------------------------------------------------------

    -- RTC enabler : 3.58MHz = 21.48MHz / 6
    process( clk21m )
    begin
        if( clk21m'event and clk21m = '1' )then
            if( rtcdiv3 = "00" )then
                rtcena <= rtcclk;
            else
                rtcena <= '0';
            end if;
        end if;
    end process;

    -- RTCCLK : 3.58MHz = 21.48MHz / 6
    process( clk21m )
    begin
        if( clk21m'event and clk21m = '1' )then
            if( rtcdiv3 = "10" )then
                rtcclk <= not rtcclk;
            else
                -- hold
            end if;
        end if;
    end process;

    -- RTC Prescaler : 21.48MHz / 6
    process( clk21m )
    begin
        if( clk21m'event and clk21m = '1' )then
            if( rtcdiv3 = "00" )then
                rtcdiv3 <= "10";
            else
                rtcdiv3 <= rtcdiv3 - 1;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- Reset control
    -- "RstSeq" should be cleared when power-on reset
    ----------------------------------------------------------------

    process( memclk )
    begin
        if( memclk'event and memclk = '1' )then
            -- 00 > 01 > 11 > 10
            ff_mem_seq <= ff_mem_seq(0) & (not ff_mem_seq(1));
        end if;
    end process;

    process( memclk )
    begin
        if( memclk'event and memclk = '1' )then
            if( ff_mem_seq = "00" )then
                FreeCounter <= FreeCounter + 1;
            end if;
        end if;
    end process;

    -- hard reset timer
    process( clk21m )
    begin
        if( clk21m'event and clk21m = '1' )then
            if( xSltRst_n = '0' )then
                -- hard reset is held down
                iSltRst_n <= '0';                                                       -- reset = '1'
                if( HardRst_cnt = "0000" )then
                    if( ff_reload_n = '0' )then
                        HardRst_cnt <= "0010";                                          -- 100ms to timeout
                    else
                        HardRst_cnt <= "1110";                                          -- short click < 800ms (M51953BFP introduces an additional delay of about 500ms)
                    end if;
                elsif( w_10hz = '1' and HardRst_cnt /= "0001" )then                     -- timeout
                    HardRst_cnt <= HardRst_cnt - 1;
                end if;
            else
                -- hard reset has been released
                HardRst_cnt <= "0000";
                iSltRst_n <= '1';                                                       -- reset = '0'
            end if;
        end if;
    end process;

    -- RstSeq count
    process( memclk )
    begin
        if( memclk'event and memclk = '1' )then
            if( HardRst_cnt = "0010" or bios_reload_ack = '1' )then                     -- long click > 800ms
                RstSeq <= "00000";                                                      -- RstSeq is required
                ff_reload_n <= '0';                                                     -- OCM-BIOS is partial
            elsif( ff_mem_seq = "00" and FreeCounter = X"FFFF" and RstSeq /= "11111" )then
                RstSeq <= RstSeq + 1;                                                   -- 3ms (= 65536 / 21.48MHz)
            elsif( ff_ldbios_n = '1' )then
                ff_reload_n <= '1';                                                     -- OCM-BIOS is complete
            end if;
        end if;
    end process;

    -- hard reset button
    process( memclk )
    begin
        if( memclk'event and memclk = '1' )then
            xSltRst_n <= pSltRst_n or RstKeyLock;                                       -- hard reset with lock
        end if;
    end process;

    -- reset assignment
    process( memclk )
    begin
        if( memclk'event and memclk = '1' )then
            if( RstSeq = "11111" )then
                -- RstSeq has finished
                reset <= not (iSltRst_n and swioRESET_n);                               -- global reset
            else
                -- RstSeq is in progress
                reset <= '1';                                                           -- SDRAM integrity protection
            end if;
        end if;
    end process;

    -- power-on reset
    process( memclk )
    begin
        if( memclk'event and memclk = '1' )then
            if( ff_clk21m_cnt( 19 downto 15 ) = "11001" )then                           -- about 38ms
                power_on_reset <= '1';
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- Operation mode
    ----------------------------------------------------------------

    -- free run counter
    process( clk21m )
    begin
        if( clk21m'event and clk21m = '1' )then
            ff_clk21m_cnt <= ff_clk21m_cnt + 1;
        end if;
    end process;

    -- w_10hz with LFSR counter = 100ms
    -- http://outputlogic.com/?page_id=275
    w_10hz_d0 <= w_10hz_lfsr(21) xnor w_10hz_lfsr(20);

    process( w_10hz_lfsr )
    begin
        -- XTAL 21.47727MHz (ratio 1:1 + 150 clock ticks for aging)
        if( w_10hz_lfsr = "0001011110000110010111" )then    -- x"05E197" / LFSR count = 2147878 clock ticks
            w_10hz <= '1';
        else
            w_10hz <= '0';
        end if;
    end process;

    process( clk21m )
    begin
        if( clk21m'event and clk21m = '1' )then
            if( w_10hz = '1' )then
                w_10hz_lfsr <= (others => '0');
            else
                w_10hz_lfsr <= (w_10hz_lfsr( 20 downto 0 ) & w_10hz_d0);
            end if;
        end if;
    end process;

    -- green level counter
    process( reset, clk21m )
    begin
        if( reset = '1' )then
            GreenLv_cnt <= "0000";
        elsif( clk21m'event and clk21m = '1' )then
            if( GreenLvEna = '1' )then
                GreenLv_cnt <= "1111";                      -- 1600ms
            elsif( w_10hz = '1' and GreenLv_cnt /= "0000" )then
                GreenLv_cnt <= GreenLv_cnt - 1;
            end if;
        end if;
    end process;

    -- green level assignment
    process( reset, clk21m )
    begin
        if( reset = '1' )then
            GreenLv <= (others => '0');
        elsif( clk21m'event and clk21m = '1' )then
            case LevCtrl is
                when "111"  =>  GreenLv <= "1111111";
                when "110"  =>  GreenLv <= "0111111";
                when "101"  =>  GreenLv <= "0011111";
                when "100"  =>  GreenLv <= "0001111";
                when "011"  =>  GreenLv <= "0000111";
                when "010"  =>  GreenLv <= "0000011";
                when "001"  =>  GreenLv <= "0000001";
                when others =>  GreenLv <= "0000000";
            end case;
        end if;
    end process;

    -- blink assignment (specific for 1chipMSX)
    process( clk21m )
    begin
        if( clk21m'event and clk21m = '1' )then
            Blink_s <= ff_clk21m_cnt(20) or (not ff_clk21m_cnt(19));
            if( Blink_ena = '1' and MmcEna = '1' )then
                MmcEnaLed <= Blink_s and FadedGreen;
            elsif( Blink_ena = '0' and LightsMode = '0' )then
                MmcEnaLed <= MmcMode and FadedGreen;
            elsif( LightsMode = '1' )then
                MmcEnaLed <= GreenLeds(7) and FadedGreen;
            else
                MmcEnaLed <= '0';
            end if;
        end if;
    end process;

    -- power LED assignment (specific for 1chipMSX)
    pLedPwr <=  (clk21m                              )      -- pLedPwr test on reset
                                                            when( power_on_reset = '0' or iSltRst_n = '0' )else
                (FadedRed                            )      -- On
                                                            when( Paus = '0' and Red_sta = '1' and GreenLv_cnt = "0000" )else
                ('0'                                 );     -- Off

    -- LEDs assignment (specific for 1chipMSX)
    pLed    <=  (others     => FreeCounter(0)        )      -- pLed test on reset
                                                            when( power_on_reset = '0' or iSltRst_n = '0' )else

                (others     => '0'                   )      -- Blackout Mode
                                                            when( Paus = '1' )else

                (MmcEnaLed                           ) &    -- Blink + Lights Mode
                (GreenLeds(6)   and FadedGreen       ) &
                (GreenLeds(5)   and FadedGreen       ) &
                (GreenLeds(4)   and FadedGreen       ) &
                (GreenLeds(3)   and FadedGreen       ) &
                (GreenLeds(2)   and FadedGreen       ) &
                (GreenLeds(1)   and FadedGreen       ) &
                (GreenLeds(0)   and FadedGreen       )      when( LightsMode = '1' )else

                (MmcEnaLed                           ) &    -- Blink + Volume
                (GreenLv(6)     and FadedGreen       ) &
                (GreenLv(5)     and FadedGreen       ) &
                (GreenLv(4)     and FadedGreen       ) &
                (GreenLv(3)     and FadedGreen       ) &
                (GreenLv(2)     and FadedGreen       ) &
                (GreenLv(1)     and FadedGreen       ) &
                (GreenLv(0)     and FadedGreen       )      when( GreenLv_cnt /= "0000" )else

                (MmcEnaLed                           ) &    -- Blink + Virtual DIP-SW (Auto)
                (FullRAM        and FadedGreen       ) &
                (Slot2Mode(0)   and FadedGreen       ) &
                (Slot2Mode(1)   and FadedGreen       ) &
                (Slot1Mode      and FadedGreen       ) &
                (DisplayMode(0) and FadedGreen       ) &
                (DisplayMode(1) and FadedGreen       ) &
                (io42_id212(0)  and FadedGreen       );

    -- DIP-SW latch
    process( clk21m )
    begin
        if( clk21m'event and clk21m = '1' )then
            ff_dip_req <= not pDip;                         -- convert negative logic to positive logic, and latch
        end if;
    end process;

    -- Kana keyboard layout: 1=JIS layout (PSG)
    w_key_mode  <=  '1';

    ----------------------------------------------------------------
    -- MSX cartridge slot control
    ----------------------------------------------------------------
    pSltCs1_n   <=  pSltRd_n when( pSltAdr(15 downto 14) = "01" )else '1';
    pSltCs2_n   <=  pSltRd_n when( pSltAdr(15 downto 14) = "10" )else '1';
    pSltCs12_n  <=  pSltRd_n when( pSltAdr(15 downto 14) = "01" )else
                    pSltRd_n when( pSltAdr(15 downto 14) = "10" )else '1';
    pSltM1_n    <=  CpuM1_n;
    pSltRfsh_n  <=  CpuRfsh_n;

    pSltInt_n   <=  '0' when( pVdpInt_n = '0' )else
                    'Z';

    pSltSltsl_n <=  '1' when( Scc1Type /= "00" )else
                    '0' when( pSltMerq_n = '0' and CpuRfsh_n = '1' and PriSltNum = "01" )else
                    '1';

    pSltSlts2_n <=  '1' when( Slot2Mode /= "00" )else
                    '0' when( pSltMerq_n = '0' and CpuRfsh_n = '1' and PriSltNum = "10" )else
                    '1';

    pSltBdir_n  <=  'Z';

    BusDir_o    <=  '0' when( pSltRd_n = '1' )else
                    '1' when( pSltIorq_n = '0' and BusDir = '1' )else
                    '1' when( pSltMerq_n = '0' and PriSltNum = "00" )else
                    '1' when( pSltMerq_n = '0' and PriSltNum = "11" )else
                    '1' when( pSltMerq_n = '0' and PriSltNum = "01" and Scc1Type /= "00" )else
                    '1' when( pSltMerq_n = '0' and PriSltNum = "10" and Slot2Mode /= "00" )else
                    '0';

    pSltDat     <=  dbi when( BusDir_o = '1' )else
                    (others => 'Z');

    pSltRsv5    <=  'Z';
    pSltRsv16   <=  'Z';
    pSltSw1     <=  'Z';
    pSltSw2     <=  'Z';

    pSltWait_n  <=  'Z';

    ----------------------------------------------------------------
    -- Z80 CPU wait control
    ----------------------------------------------------------------
    process( reset, iCpuClk )

        variable iCpuM1_n   : std_logic;                                -- slack 1.759ns
        variable jSltMerq_n : std_logic;
        variable jSltIorq_n : std_logic;
        variable count      : std_logic_vector(3 downto 0);             -- slack 0.822ns

    begin

        if( reset = '1' )then
            iCpuM1_n    := '1';
            jSltIorq_n  := '1';
            jSltMerq_n  := '1';
            count       := "0000";
            wait_n_s    <= '1';                                         -- WAIT_n fix by Victor Trucco

        elsif( iCpuClk'event and iCpuClk = '1' )then

            if( pSltMerq_n = '0' and jSltMerq_n = '1' )then
                if( ff_clksel = '1' )then
                    if( ff_ldbios_n = '0' )then
                        count := "0010";                                -- 8.06MHz (simulated)
                    else
                        count := CustomSpeed;                           -- 4.10MHz up to 8.06MHz (simulated)
                    end if;
                elsif( ff_clksel5m_n = '0' and (iSltScc1 = '1' or iSltScc2 = '1') )then
                    count := "0001";
                end if;
            elsif( pSltIorq_n = '0' and jSltIorq_n = '1' )then          -- wait for external bus
                if( ff_clksel = '1' )then
                    count := "0110";                                    -- "0011" = original value, "0110" = better reading the pull-up states at 10.74MHz
                elsif( ff_clksel5m_n = '0' )then
                    if( extclk3m = '0' )then
                        count := "0010";                                -- "0010" = calibrated to minimize artifacts in Gradius 2 Enhanced at 5.37MHz
                    else
                        count := "0110";                                -- "0110" = calibrated to properly access the ADPCM unit (NMS-1205) with async 5.37MHz
                    end if;
                end if;
            elsif( count /= "0000" )then                                -- countdown timer
                count := count - 1;
            end if;

            if( (CpuM1_n = '0' and iCpuM1_n = '1') or pSltWait_n = '0' or esp_wait_s = '0' )then
                wait_n_s <= '0';
            elsif( count /= "0000" )then
                wait_n_s <= '0';
            elsif( (ff_clksel = '1' or ff_clksel5m_n = '0') and OpllReq = '1' and OpllAck = '0' )then
                wait_n_s <= '0';
            elsif( ErmReq = '1' and adr(15 downto 13) = "010" and MmcAct = '1' )then
                wait_n_s <= '0';
            else
                wait_n_s <= '1';
            end if;

            iCpuM1_n    := CpuM1_n;
            jSltIorq_n  := pSltIorq_n;
            jSltMerq_n  := pSltMerq_n;

        end if;

    end process;

    ----------------------------------------------------------------
    -- On chip internal bus control
    ----------------------------------------------------------------
    process( reset, clk21m )

        variable ExpDec : std_logic;

    begin

        if( reset = '1' )then

            iSltRfsh_n      <= '1';
            iSltMerq_n      <= '1';
            iSltIorq_n      <= '1';
            xSltRd_n        <= '1';
            xSltWr_n        <= '1';
            iSltAdr         <= (others => '1');
            iSltDat         <= (others => '1');

            iack            <= '0';

            ExpDec          := '0';

        elsif( clk21m'event and clk21m = '1' )then

            -- MSX slot signals
            iSltRfsh_n      <= pSltRfsh_n;
            iSltMerq_n      <= pSltMerq_n;
            iSltIorq_n      <= pSltIorq_n;
            xSltRd_n        <= pSltRd_n;
            xSltWr_n        <= pSltWr_n;
            iSltAdr         <= pSltAdr;
            iSltDat         <= pSltDat;

            if( iSltMerq_n  = '1' and iSltIorq_n = '1' )then
                iack <= '0';
            elsif( ack = '1' )then
                iack <= '1';
            end if;

            -- input assignments for internal devices
            if( mem = '1' and ExpDec = '1' )then
                dlydbi <= ExpDbi;
            elsif( mem = '1' and iSltBot = '1' )then                                                        -- IPL-ROM
                dlydbi <= RomDbi;
            elsif( mem = '1' and iSltErm = '1' and MmcEna = '1' )then                                       -- MegaSD
                dlydbi <= MmcDbi;
            elsif( mem = '0' and adr(  7 downto 2 ) = "100110" )then                                        -- VDP (V9938/V9958)
                dlydbi <= VdpDbi;
            elsif( mem = '0' and adr(  7 downto 2 ) = "101000" )then                                        -- PSG (AY-3-8910)
                dlydbi <= PsgDbi;
            elsif( mem = '0' and adr(  7 downto 2 ) = "101010" )then                                        -- PPI (8255)
                dlydbi <= PpiDbi;
            elsif( mem = '0' and adr(  7 downto 2 ) = "110110" and JIS2_ena = '1' )then                     -- Kanji-data (JIS1+JIS2)
                dlydbi <= KanDbi;
            elsif( mem = '0' and adr(  7 downto 1 ) = "1101100" )then                                       -- Kanji-data (JIS1 only)
                dlydbi <= KanDbi;
            elsif( mem = '0' and adr(  7 downto 2 ) = "111111" and (FullRAM or iSlt0_1) = '1' )then         -- Memory-mapper 4096 KB | Extra-mapper 4096 KB
                dlydbi <= MapDbi;
            elsif( mem = '0' and adr(  7 downto 2 ) = "111111" )then                                        -- Memory-mapper 2048 KB
                dlydbi <= "1" & MapDbi(  6 downto 0 );
            elsif( mem = '0' and adr(  7 downto 1 ) = "1011010" )then                                       -- RTC (RP-5C01)
                dlydbi <= RtcDbi;
            elsif( mem = '0' and adr(  7 downto 4 ) = "0100" and io40_n /= "11111111" )then                 -- Switched I/O ports
                dlydbi <= swio_dbi;
            elsif( mem = '0' and adr(  7 downto 0 ) = "11110010" and portF2_ena = '1' and use_wifi_g )then  -- F2 Device (ESP8266 BIOS)
                dlydbi <= portF2;
            elsif( mem = '0' and adr(  7 downto 0 ) = "11110100" )then                                      -- F4 Device inverted
                dlydbi <= portF4_bit7 & "1111111";
            elsif( mem = '0' and adr(  7 downto 1 ) = "0000011" and use_wifi_g )then                        -- ESP ports 06-07h
                dlydbi <= esp_dout_s;
            elsif( mem = '0' and adr(  7 downto 0 ) = "11101001" and use_midi_g )then                       -- MIDI port E9h
                dlydbi <= midi_dout_s;
            else
                dlydbi <= (others => '1');
            end if;

            if( adr = X"FFFF" )then
                ExpDec := '1';
            else
                ExpDec := '0';
            end if;

        end if;

    end process;

    ----------------------------------------------------------------
    process( reset, clk21m )

    begin

        if( reset = '1' )then

            jSltScc1    <= '0';
            jSltScc2    <= '0';
            jSltMem     <= '0';

            wrt <= '0';

        elsif( clk21m'event and clk21m = '0' )then

            if( mem = '1' and iSltScc1 = '1' )then
                jSltScc1 <= '1';
            else
                jSltScc1 <= '0';
            end if;

            if( mem = '1' and iSltScc2 = '1' )then
                jSltScc2 <= '1';
            else
                jSltScc2 <= '0';
            end if;

            if( mem = '1' and iSltErm = '1' )then
                if( MmcEna = '1' and adr(15 downto 13) = "010" )then
                    jSltMem <= '0';
                elsif( MmcMode = '1' or ff_ldbios_n = '0' )then         -- enable SD/MMC drive
                    jSltMem <= '1';
                else                                                    -- disable SD/MMC drive
                    jSltMem <= '0';
                end if;
            elsif( mem = '1' and ((iSltMap0 or iSltMap or rom_main or rom_opll or rom_extd or rom_xbas or rom_free or iSltLin1 or iSltLin2) = '1') )then
                jSltMem <= '1';
            else
                jSltMem <= '0';
            end if;

            if( req = '0' )then
                wrt <= not pSltWr_n;                                    -- 1=write, 0=read
            end if;

        end if;

    end process;

    -- access request, CPU > Components
    req     <=  '1'         when( ((iSltMerq_n = '0') or (iSltIorq_n = '0')) and
                                  ((xSltRd_n = '0') or (xSltWr_n = '0')) and iack = '0' )else '0';

    mem     <=  iSltIorq_n;                                             -- 1=memory area, 0=I/O area
    dbo     <=  iSltDat;                                                -- CPU data (CPU > device)
    adr     <=  iSltAdr;                                                -- CPU address (CPU > device)

    -- access acknowledge, Components > CPU
    ack     <=  RamAck      when( RamReq   = '1' )else                  -- ErmAck, MapAck, KanAck
                Scc1Ack     when( jSltScc1 = '1' )else                  -- Scc1Ack
                Scc2Ack     when( jSltScc2 = '1' )else                  -- Scc2Ack
                OpllAck     when( OpllReq  = '1' )else                  -- OpllAck
                req;                                                    -- PsgAck, PpiAck, VdpAck, RtcAck, ...

    dbi     <=  Scc1Dbi     when( jSltScc1 = '1' )else
                Scc2Dbi     when( jSltScc2 = '1' )else
                RamDbi      when( jSltMem  = '1' )else
                dlydbi      when( reset    = '0' )else                  -- Modified by KdL, 2025/Jan/24th
                (others => '1');

    ----------------------------------------------------------------
    -- F2 Device (ESP8266 BIOS)
    ----------------------------------------------------------------
    -- this device allows to program operating states of ESP8266 and
    -- to distinguish whether the system boot was cold (power off or
    -- hard reset) or warm (RESET or GETRESET from command line)
    ----------------------------------------------------------------
    process( clk21m )
    begin
        if( clk21m'event and clk21m = '1' )then
            if( reset = '1' and warmRESET /= '1' )then
                portF2 <= (others => '1');
            elsif( portF2_req = '1' and wrt = '1' )then
                portF2 <= dbo;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- F4 Device
    ----------------------------------------------------------------
    process( reset, LastRst_sta, clk21m )
    begin
        if( reset = '1' )then
            portF4_bit7 <= not LastRst_sta;
        elsif( clk21m'event and clk21m = '1' )then
            if( portF4_req = '1' and wrt = '1' )then
                portF4_bit7 <= dbo(7);
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- PPI(8255) / primary-slot, keyboard, 1bit sound port
    ----------------------------------------------------------------
    process( reset, clk21m )
    begin
        if( reset = '1' )then
            PpiPortA    <= "11111111";          -- primary slot : page 0 => boot-rom, page 1/2 => ese-mmc, page 3 => mapper
            PpiPortC    <= (others => '0');
            ff_ldbios_n <= '0';                 -- OCM-BIOS is required
        elsif( clk21m'event and clk21m = '1' )then
            -- I/O port access on A8-ABh ... PPI(8255) access
            if( PpiReq = '1' )then
                if( wrt = '1' and adr(1 downto 0) = "00" )then
                    PpiPortA    <= dbo;
                    ff_ldbios_n <= '1';         -- OCM-BIOS is ready
                elsif( wrt = '1' and adr(1 downto 0) = "10" )then
                    PpiPortC  <= dbo;
                elsif( wrt = '1' and adr(1 downto 0) = "11" and dbo(7) = '0' )then
                    case dbo(3 downto 1) is
                        when "000"  => PpiPortC(0) <= dbo(0); -- key_matrix Y(0)
                        when "001"  => PpiPortC(1) <= dbo(0); -- key_matrix Y(1)
                        when "010"  => PpiPortC(2) <= dbo(0); -- key_matrix Y(2)
                        when "011"  => PpiPortC(3) <= dbo(0); -- key_matrix Y(3)
                        when "100"  => PpiPortC(4) <= dbo(0); -- cassete motor (0=On,1=Off)
                        when "101"  => PpiPortC(5) <= dbo(0); -- cassete audio out
                        when "110"  => PpiPortC(6) <= dbo(0); -- CAPS lamp (0=On,1=Off)
                        when others => PpiPortC(7) <= dbo(0); -- 1bit sound port
                    end case;
                end if;
            end if;
        end if;
    end process;

    Caps    <=  PpiPortC(6);

    -- I/O port access on A8-ABh ... PPI(8255) register read
    PpiDbi  <=  PpiPortA    when( adr(1 downto 0) = "00" )else
                PpiPortB    when( adr(1 downto 0) = "01" )else
                PpiPortC    when( adr(1 downto 0) = "10" )else
                (others => '1');

    ----------------------------------------------------------------
    -- Expansion slot
    ----------------------------------------------------------------

    -- slot #0
    process( reset, clk21m )
    begin
        if( reset = '1' )then
            ExpSlot0    <= (others => '0');
        elsif( clk21m'event and clk21m = '1' )then
            -- Memory mapped I/O port access on FFFFh ... expansion slot register (master mode)
            if( req = '1' and iSltMerq_n = '0' and wrt = '1' and adr = X"FFFF" )then
                if( PpiPortA(7 downto 6) = "00" )then
                    ExpSlot0 <= dbo;
                end if;
            end if;
        end if;
    end process;

    -- slot #3
    process( reset, clk21m )
    begin
        if( reset = '1' )then
            ExpSlot3    <= "00101011";          -- primary slot : page 0 => ipl-rom / xbasic, page 1/2 => megasd, page 3 => mapper
        elsif( clk21m'event and clk21m = '1' )then
            -- Memory mapped I/O port access on FFFFh ... expansion slot register (master mode)
            if( req = '1' and iSltMerq_n = '0' and wrt = '1' and adr = X"FFFF" )then
                if( PpiPortA(7 downto 6) = "11" )then
                    ExpSlot3 <= dbo;
                end if;
            end if;
        end if;
    end process;

    -- primary slot number (master mode)
    with adr(15 downto 14) select PriSltNum <=
        PpiPortA(1 downto 0) when "00",
        PpiPortA(3 downto 2) when "01",
        PpiPortA(5 downto 4) when "10",
        PpiPortA(7 downto 6) when others;

    -- expansion slot number : slot 0 (master mode)
    with adr(15 downto 14) select ExpSltNum0 <=
        ExpSlot0(1 downto 0) when "00",
        ExpSlot0(3 downto 2) when "01",
        ExpSlot0(5 downto 4) when "10",
        ExpSlot0(7 downto 6) when others;

    -- expansion slot number : slot 3 (master mode)
    with adr(15 downto 14) select ExpSltNum3 <=
        ExpSlot3(1 downto 0) when "00",
        ExpSlot3(3 downto 2) when "01",
        ExpSlot3(5 downto 4) when "10",
        ExpSlot3(7 downto 6) when others;

    -- expansion slot register read
    with PpiPortA(7 downto 6) select ExpDbi <=
        not ExpSlot0         when "00",
        not ExpSlot3         when "11",
        (others => '1')      when others;

    ----------------------------------------------------------------
    -- Slot/Page Decode
    ----------------------------------------------------------------
    with( adr(15 downto 14) ) select w_page_dec <=
        "0001"      when "00",
        "0010"      when "01",
        "0100"      when "10",
        "1000"      when "11",
        "XXXX"      when others;

    with( PriSltNum ) select w_prislt_dec <=
        "0001"      when "00",
        "0010"      when "01",
        "0100"      when "10",
        "1000"      when "11",
        "XXXX"      when others;

    with( ExpSltNum0 ) select w_expslt0_dec <=
        "0001"      when "00",
        "0010"      when "01",
        "0100"      when "10",
        "1000"      when "11",
        "XXXX"      when others;

    with( ExpSltNum3 ) select w_expslt3_dec <=
        "0001"      when "00",
        "0010"      when "01",
        "0100"      when "10",
        "1000"      when "11",
        "XXXX"      when others;

    ----------------------------------------------------------------
    -- Address Decode for CPU
    ----------------------------------------------------------------
    -- Slot0-X
    rom_main    <=  mem when( (w_prislt_dec(0) and w_expslt0_dec(0) and (w_page_dec(0) or w_page_dec(1))) = '1'                                 )else   -- 0-0 (0000-7FFFh)    32 KB  MSX2P   .ROM / MSXTR   .ROM
                    '0';
    iSltMap0    <=  mem when( (w_prislt_dec(0) and w_expslt0_dec(1) and iSlt0_1 ) = '1' and adr /= X"FFFF"                                      )else   -- 0-1 (0000-FFFEh)  4096 KB  Extra-Mapper
                    '0';
    rom_opll    <=  mem when( (w_prislt_dec(0) and w_expslt0_dec(2) and w_page_dec(1)) = '1'                                                    )else   -- 0-2 (4000-7FFFh)    16 KB  MSX2PMUS.ROM / MSXTRMUS.ROM
                    '0';
    rom_free    <=  mem when( (w_prislt_dec(0) and w_expslt0_dec(3) and w_page_dec(1)) = '1'                                                    )else   -- 0-3 (4000-7FFFh)    16 KB  FREE16KB.ROM / MSXTROPT.ROM
                    '0';
    -- Slot1
    iSltScc1    <=  mem when( (w_prislt_dec(1) and (w_page_dec(1) or w_page_dec(2)) and (not iSlt1_linear)) = '1' and Scc1Type /= "00"          )else   -- 1   (4000-BFFFh)  2048 KB  ESE-SCC1
                    '0';
    iSltLin1    <=  mem when( (w_prislt_dec(1) and iSlt1_linear) = '1' and Scc1Type /= "00"                                                     )else   -- 1   (0000-FFFFh)    64 KB  Linear over ESE-SCC1
                    '0';
    -- Slot2
    iSltScc2    <=  mem when( (w_prislt_dec(2) and (w_page_dec(1) or w_page_dec(2)) and (not iSlt2_linear)) = '1' and Slot2Mode /= "00"         )else   -- 2   (4000-BFFFh)  2048 KB  ESE-SCC2
                    '0';
    iSltLin2    <=  mem when( (w_prislt_dec(2) and iSlt2_linear) = '1' and Slot2Mode /= "00"                                                    )else   -- 2   (0000-FFFFh)    64 KB  Linear over ESE-SCC2
                    '0';
    -- Slot3-X
    iSltMap     <=  mem when( (w_prislt_dec(3) and w_expslt3_dec(0)) = '1' and adr /= X"FFFF"                                                   )else   -- 3-0 (0000-FFFEh)  4096 KB  Internal Mapper
                    '0';
    rom_extd    <=  mem when( (w_prislt_dec(3) and w_expslt3_dec(1) and (w_page_dec(0) or w_page_dec(1) or w_page_dec(2))) = '1'                )else   -- 3-1 (0000-BFFFh)    48 KB  (MSX2PEXT.ROM or MSXTREXT.ROM) + MSXKANJI.ROM
                    '0';
    iSltErm     <=  mem when( (w_prislt_dec(3) and w_expslt3_dec(2) and (w_page_dec(1) or w_page_dec(2))) = '1'                                 )else   -- 3-2 (4000-BFFFh)  1024 KB  ESE-RAM (start with MEGASDHC.ROM or NEXTOR16.ROM)
                    '0';
    rom_xbas    <=  mem when( (w_prislt_dec(3) and w_expslt3_dec(3) and w_page_dec(1) and ff_ldbios_n) = '1'                                    )else   -- 3-3 (4000-7FFFh)    16 KB  XBASIC2 .ROM / XBASIC21.ROM
                    '0';
    iSltBot     <=  mem when( (w_prislt_dec(3) and w_expslt3_dec(3) and (w_page_dec(0) or w_page_dec(3)) and (not ff_ldbios_n)) = '1'           )else   -- 3-3 (0000-3FFFh & C000-FFFFh)   < 3 KB  IPL-ROM (pre-boot state)
                    '0';
    -- I/O
    rom_kanj    <=  not mem     when( adr(7 downto 2) = "110110" )else
                    '0';

    -- RamX / RamY access request
    RamReq  <=  Scc1Ram or Scc2Ram or ErmRam or MapRam or RomReq or KanRom;

    -- access request to component
    VdpReq      <=  req when( mem = '0' and adr(7 downto 2) = "100110"                                                  )else '0';  -- I/O:98-9Bh / VDP (V9938/V9958)
    PsgReq      <=  req when( mem = '0' and adr(7 downto 2) = "101000"                                                  )else '0';  -- I/O:A0-A3h / PSG (AY-3-8910)
    PpiReq      <=  req when( mem = '0' and adr(7 downto 2) = "101010"                                                  )else '0';  -- I/O:A8-ABh / PPI (8255)
    OpllReq     <=  req when( mem = '0' and adr(7 downto 1) = "0111110"                                                 )else '0';  -- I/O:7C-7Dh / OPLL (YM2413)
    KanReq      <=  req when( mem = '0' and adr(7 downto 2) = "110110"                                                  )else '0';  -- I/O:D8-DBh / Kanji-data
    RomReq      <=  req when( (rom_main or rom_opll or rom_extd or rom_xbas or rom_free or iSltLin1 or iSltLin2) = '1'  )else '0';
    MapReq      <=  req when( mem = '0' and adr(7 downto 2) = "111111"                                                  )else       -- I/O:FC-FFh / Memory-mapper
                    req when( iSltMap0 = '1' or iSltMap  = '1'                                                          )else '0';  -- MEM:       / Extra-mapper, Memory-mapper
    Scc1Req     <=  req when( iSltScc1 = '1'                                                                            )else '0';  -- MEM:       / ESE-SCC1
    Scc2Req     <=  req when( iSltScc2 = '1'                                                                            )else '0';  -- MEM:       / ESE-SCC2
    ErmReq      <=  req when( iSltErm  = '1'                                                                            )else '0';  -- MEM:       / ESE-RAM, MegaSD
    RtcReq      <=  req when( mem = '0' and adr(7 downto 1) = "1011010"                                                 )else '0';  -- I/O:B4-B5h / RTC (RP-5C01)
    swio_req    <=  req when( mem = '0' and adr(7 downto 4) = "0100"                                                    )else '0';  -- I/O:40-4Fh / Switched I/O ports
    portF2_req  <=  req when( mem = '0' and adr(7 downto 0) = "11110010" and portF2_ena = '1' and use_wifi_g            )else '0';  -- I/O:F2h    / F2 Device (ESP8266 BIOS)
    portF4_req  <=  req when( mem = '0' and adr(7 downto 0) = "11110100"                                                )else '0';  -- I/O:F4h    / F4 Device

    BusDir  <=  '1' when( pSltAdr(7 downto 2) = "100110"                                        )else   -- I/O:98-9Bh / VDP (V9938/V9958)
                '1' when( pSltAdr(7 downto 2) = "101000"                                        )else   -- I/O:A0-A3h / PSG (AY-3-8910)
                '1' when( pSltAdr(7 downto 2) = "101010"                                        )else   -- I/O:A8-ABh / PPI (8255)
                '1' when( pSltAdr(7 downto 2) = "110110" and JIS2_ena = '1'                     )else   -- I/O:D8-DBh / Kanji-data (JIS1+JIS2)
                '1' when( pSltAdr(7 downto 1) = "1101100"                                       )else   -- I/O:D8-D9h / Kanji-data (JIS1 only)
                '1' when( pSltAdr(7 downto 2) = "111111"                                        )else   -- I/O:FC-FFh / Memory-mapper
                '1' when( pSltAdr(7 downto 1) = "1011010"                                       )else   -- I/O:B4-B5h / RTC (RP-5C01)
                '1' when( pSltAdr(7 downto 4) = "0100" and io40_n /= "11111111"                 )else   -- I/O:40-4Fh / Switched I/O ports
                '1' when( pSltAdr(7 downto 0) = "11110010" and portF2_ena = '1' and use_wifi_g  )else   -- I/O:F2h    / F2 Device (ESP8266 BIOS)
                '1' when( pSltAdr(7 downto 0) = "11110100"                                      )else   -- I/O:F4h    / F4 Device
                '1' when( pSltAdr(7 downto 1) = "0000011" and use_wifi_g                        )else   -- I/O:06-07h / ESP
                '1' when( pSltAdr(7 downto 0) = "11101001" and use_midi_g                       )else   -- I/O:E9h    / MIDI
                '0';

    ----------------------------------------------------------------
    -- Video output
    ----------------------------------------------------------------
    process( clk21m )
        variable r_v : unsigned(  5 downto 0 );
        variable g_v : unsigned(  5 downto 0 );
        variable b_v : unsigned(  5 downto 0 );
    begin
        if( clk21m'event and clk21m = '1' )then
            case DisplayMode is
                when "00" =>                                        -- TV 15kHz
                    pDac_VR     <= videoC;                          -- Chrominance for S-Video Out
                    pDac_VG     <= videoY;                          -- Luminance for S-Video Out
                    pDac_VB     <= videoV;                          -- Composite Video Out
                    Reso_v      <= '0';                             -- Hsync:15kHz
                    pVideoHS_n  <= 'Z';                             -- CSync Disabled
                    pVideoVS_n  <= DACout;                          -- Audio Out (Mono)

                when "01" =>                                        -- RGB 15kHz
                    pDac_VR     <= "0" & VideoR( 5 downto 1 );      -- 50% Brightness
                    pDac_VG     <= "0" & VideoG( 5 downto 1 );
                    pDac_VB     <= "0" & VideoB( 5 downto 1 );
                    Reso_v      <= '0';                             -- Hsync:15kHz
                    pVideoHS_n  <= VideoCS_n;                       -- CSync Enabled
                    pVideoVS_n  <= DACout;                          -- Audio Out (Mono)

                when others =>                                      -- VGA / VGA+ 31kHz
                    pDac_VR     <= "0" & VideoR( 5 downto 1 );      -- 50% Brightness
                    pDac_VG     <= "0" & VideoG( 5 downto 1 );
                    pDac_VB     <= "0" & VideoB( 5 downto 1 );
                    Reso_v      <= '1';                             -- Hsync:31kHz
                    pVideoHS_n  <= VideoHS_n;
                    pVideoVS_n  <= VideoVS_n;
                    if( legacy_sel = '0' )then                      -- Assignment of Legacy Output  (for TH9958 VDP core)
                        legacy_vga  <= not DisplayMode(0);          -- to VGA
                    else
                        legacy_vga  <= DisplayMode(0);              -- to VGA+
                    end if;
            end case;

            if( odd_line_s = '0' and DisplayMode(1) = '1' and (interlace_mode = '0' or vga_int_field = '1') )then
                if( set_low_scanlines_g )then
                    low_scale_n <= '0';

                    if( vga_scanlines = "11" )then
                        -- VGA Scanlines 50% of 6-bit DAC half-scale brightness
                        pDac_VR <= "00" & VideoR(  5 downto 2 );
                        pDac_VG <= "00" & VideoG(  5 downto 2 );
                        pDac_VB <= "00" & VideoB(  5 downto 2 );
                    elsif( vga_scanlines = "10" )then
                        -- VGA Scanlines 25% of 6-bit DAC half-scale brightness
                        r_v := unsigned("0" & VideoR(  5 downto 1 )) - unsigned("000" & VideoR(  5 downto 3 ));
                        g_v := unsigned("0" & VideoG(  5 downto 1 )) - unsigned("000" & VideoG(  5 downto 3 ));
                        b_v := unsigned("0" & VideoB(  5 downto 1 )) - unsigned("000" & VideoB(  5 downto 3 ));
                        pDac_VR <= std_logic_vector(r_v);
                        pDac_VG <= std_logic_vector(g_v);
                        pDac_VB <= std_logic_vector(b_v);
                    elsif( vga_scanlines = "01" )then
                        -- VGA Scanlines 12% of 6-bit DAC half-scale brightness
                        r_v := unsigned("0" & VideoR(  5 downto 1 )) - unsigned("0000" & VideoR(  5 downto 4 ));
                        g_v := unsigned("0" & VideoG(  5 downto 1 )) - unsigned("0000" & VideoG(  5 downto 4 ));
                        b_v := unsigned("0" & VideoB(  5 downto 1 )) - unsigned("0000" & VideoB(  5 downto 4 ));
                        pDac_VR <= std_logic_vector(r_v);
                        pDac_VG <= std_logic_vector(g_v);
                        pDac_VB <= std_logic_vector(b_v);
                    end if;

                else
                    low_scale_n <= '1';

                    if( vga_scanlines = "11" )then
                        -- VGA Scanlines 75% of 6-bit DAC half-scale brightness
                        pDac_VR <= "000" & VideoR(  5 downto 3 );
                        pDac_VG <= "000" & VideoG(  5 downto 3 );
                        pDac_VB <= "000" & VideoB(  5 downto 3 );
                    elsif( vga_scanlines = "10" )then
                        -- VGA Scanlines 50% of 6-bit DAC half-scale brightness
                        pDac_VR <= "00" & VideoR(  5 downto 2 );
                        pDac_VG <= "00" & VideoG(  5 downto 2 );
                        pDac_VB <= "00" & VideoB(  5 downto 2 );
                    elsif( vga_scanlines = "01" )then
                        -- VGA Scanlines 25% of 6-bit DAC half-scale brightness
                        r_v := unsigned("0" & VideoR(  5 downto 1 )) - unsigned("000" & VideoR(  5 downto 3 ));
                        g_v := unsigned("0" & VideoG(  5 downto 1 )) - unsigned("000" & VideoG(  5 downto 3 ));
                        b_v := unsigned("0" & VideoB(  5 downto 1 )) - unsigned("000" & VideoB(  5 downto 3 ));
                        pDac_VR <= std_logic_vector(r_v);
                        pDac_VG <= std_logic_vector(g_v);
                        pDac_VB <= std_logic_vector(b_v);
                    end if;

                end if;
            end if;
        end if;
    end process;

    process( VideoVS_n, VideoHS_n )
    begin
        if( VideoVS_n = '0' )then
            odd_line_s <= '0';
            DisplayMode(0) <= display_mode_req(1);
            DisplayMode(1) <= display_mode_req(0);
        elsif( VideoHS_n'event and VideoHS_n = '1' )then
            odd_line_s <= not odd_line_s;
        end if;
    end process;

    -- PRTSCR key
    process( clk21m )
    begin
        if( clk21m'event and clk21m = '1' )then
            ff_Reso <= Reso;
        end if;
    end process;

    pVideoClk <= 'Z';
    pVideoDat <= 'Z';

    ----------------------------------------------------------------
    -- Sound output
    ----------------------------------------------------------------

    -- | b7    | b6    | b5   | b4   | b3  | b2  | b1  | b0  |
    -- | SHIFT | LCTRL | PgUp | PgDn | F9  | F10 | F11 | F12 |          Added the CTRL status by t.hara, 2021/Aug/6th, Left-CTRL since 2024/Jan/21st
    process( clk21m )
    begin
        if( clk21m'event and clk21m = '1' )then
            vFkeys  <=  Fkeys;
        end if;
    end process;

    -- mixer (pipe lined)
    u_mul: scc_mix_mul
    port map(
        a   => ff_prescc    ,               -- 16bits signed
        b   => m_SccVol     ,               --  3bits unsigned
        c   => w_scc                        -- 19bits signed
    );

    process( clk21m )
        constant h_ramp     : integer := -1;                        -- h_ramp selector -4 to 0 <= lv1-3, lv2-4, lv3-5, lv4-6 (in use), lv5-7
        constant m_ramp     : integer :=  2;                        -- m_ramp selector -1 to 3 <= lv1-3, lv2-4, lv3-5, lv4-6 (in use), lv5-7
        constant l_ramp     : integer :=  6;                        -- l_ramp <= level 1-7 (steps 3, 4, 5, 6, 7, 8, 9)
        constant h_thrd     : integer := 12;                        -- h_ramp threshold (steps 13, 14, 15)
        constant m_thrd     : integer :=  9;                        -- m_ramp threshold (steps 10, 11, 12)
        constant x_thrd     : integer :=  1;                        -- extra threshold (PsgVol goes up one level when x_thrd = 1)
        variable c_Psg      : std_logic_vector(  3 downto  0 );     -- combine PsgVol and MstrVol
        variable c_Scc      : std_logic_vector(  3 downto  0 );     -- combine SccVol and MstrVol
        variable c_Opll     : std_logic_vector(  3 downto  0 );     -- combine OpllVol and MstrVol
        variable chPsg      : std_logic_vector( ff_prepsg'range );
        variable chOpll     : std_logic_vector( ff_pre_dacin'range );
    begin
        if( clk21m'event and clk21m = '1' )then

            -- amplitude ramp of the PSG (full range)
            ff_prepsg   <= ("0" & PsgAmp) + (KeyClick & "00000");
            c_Psg       := ("1" & PsgVol) - ("0" & MstrVol);
            if( PsgVol = "000" or MstrVol = "111" )then
                ff_psg      <= (others => '0');
            elsif( c_Psg > h_thrd )then
                chPsg       := ff_prepsg;
                ff_psg      <= "0" & ("0" & (chPsg * (PsgVol - MstrVol + h_ramp + x_thrd)) + chPsg( chPsg'high - 4 downto  0 )) & "00";
            elsif( c_Psg > (m_thrd - x_thrd) )then
                chPsg       := "0" & ff_prepsg( ff_prepsg'high downto 1 );
                ff_psg      <= "0" & ("0" & (chPsg * (PsgVol - MstrVol + m_ramp + x_thrd)) + chPsg( chPsg'high - 4 downto  0 )) & "00";
            else
                chPsg       := "00" & ff_prepsg( ff_prepsg'high downto 2 );
                ff_psg      <= "0" & ("0" & (chPsg * (PsgVol - MstrVol + l_ramp + x_thrd)) + chPsg( chPsg'high - 4 downto  0 )) & "00";
            end if;

            -- amplitude ramp of the SCC-I (full range)
            ff_prescc   <= (Scc1AmpL(14) & Scc1AmpL) + (Scc2AmpL(14) & Scc2AmpL);
            c_Scc       := ("1" & SccVol) - ("0" & MstrVol);
            if( SccVol = "000" or MstrVol = "111" )then
                m_SccVol    <= "000";
                ff_scc      <= (others => w_scc(18));
            elsif( c_Scc > h_thrd )then
                m_SccVol    <= SccVol - MstrVol + h_ramp;
                ff_scc      <= w_scc(18) & w_scc( 18 downto  4 );
            elsif( c_Scc > m_thrd )then
                m_SccVol    <= SccVol - MstrVol + m_ramp;
                ff_scc      <= w_scc(18) & w_scc(18) & w_scc( 18 downto  5 );
            else
                m_SccVol    <= SccVol - MstrVol + l_ramp;
                ff_scc      <= w_scc(18) & w_scc(18) & w_scc(18) & w_scc( 18 downto  6 );
            end if;

            -- amplitude ramp of the OPLL (full range)
            c_Opll      := ("1" & OpllVol) - ("0" & MstrVol);
            if( OpllVol = "000" or MstrVol = "111" )then
                ff_opll <= c_opll_offset;
            elsif( OpllAmp < c_opll_zero )then
                if( c_Opll > h_thrd )then
                    chOpll   := ((c_opll_zero - OpllAmp) * (OpllVol - MstrVol + h_ramp)) & "000";
                elsif( c_Opll > m_thrd )then
                    chOpll   := "0" & ((c_opll_zero - OpllAmp) * (OpllVol - MstrVol + m_ramp)) & "00";
                else
                    chOpll   := "00" & ((c_opll_zero - OpllAmp) * (OpllVol - MstrVol + l_ramp)) & "0";
                end if;
                ff_opll <= c_opll_offset - (chOpll - chOpll( chOpll'high downto  3 ));
            else
                if( c_Opll > h_thrd )then
                    chOpll   := ((OpllAmp - c_opll_zero) * (OpllVol - MstrVol + h_ramp)) & "000";
                elsif( c_Opll > m_thrd )then
                    chOpll   := "0" & ((OpllAmp - c_opll_zero) * (OpllVol - MstrVol + m_ramp)) & "00";
                else
                    chOpll   := "00" & ((OpllAmp - c_opll_zero) * (OpllVol - MstrVol + l_ramp)) & "0";
                end if;
                ff_opll <= c_opll_offset + (chOpll - chOpll( chOpll'high downto  3 ));
            end if;
       end if;
    end process;

    process( clk21m )
    begin
        if( clk21m'event and clk21m = '1' )then

            -- ff_pre_dacin assignment
            ff_pre_dacin <= (not ff_psg) + ff_scc + ff_opll;

            -- amplitude limiter
            case ff_pre_dacin( ff_pre_dacin'high downto ff_pre_dacin'high - 2 ) is
                when "100" => DACin <= ff_pre_dacin( ff_pre_dacin'high ) & ff_pre_dacin( ff_pre_dacin'high - 3 downto 0 );
                when "011" => DACin <= ff_pre_dacin( ff_pre_dacin'high ) & ff_pre_dacin( ff_pre_dacin'high - 3 downto 0 );
                when others => DACin <= (others => ff_pre_dacin( ff_pre_dacin'high ));
            end case;

        end if;
    end process;

    -- left audio channel
    pDac_SL <= null                                         when( power_on_reset = '0' )else
               "ZZZZZZ"                                     when( pseudoStereo = '1' and CmtScro = '0' )else
               DACout & "ZZZZ" & DACout;                    -- multiple DACout lines are used to balance the audio cartridges on Cyclone I machines

    -- Cassette Magnetic Tape (CMT) interface / right audio channel
    process( clk21m )
    begin
        if( clk21m'event and clk21m = '1' )then
            if( power_on_reset = '1' )then
                if( CmtScro = '1' )then
                    pDac_SR(5 downto 4) <= "ZZ";
                    pDac_SR(3 downto 1) <= CmtIn & (not CmtIn) & "0";
                    pDac_SR(0)          <= CmtOut;
                    CmtIn               <= pDac_SR(5);      -- CMT enabled  (SCRLK = On, MSX2+)
--                  pSltRsv5            <= PpiPortC(4);     -- cassete motor (0=On, 1=Off)
                else                                        -- CMT data input is always '0' on MSXtR
--                  pSltRsv5            <= 'Z';             -- not connected (without external pull-up)
                    CmtIn               <= '0';             -- CMT disabled (default)
                    if( right_inverse = '1' )then
                        pDac_SR         <= not DACout & "ZZZZ" & not DACout;
                    else
                        pDac_SR         <= DACout & "ZZZZ" & DACout;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- SCRLK key
    process( clk21m )
    begin
        if( clk21m'event and clk21m = '1' )then
            ff_Scro <= Scro;
        end if;
    end process;

    -----------------------------------------------------------------
    -- External memory access
    -----------------------------------------------------------------
    -- Slot map / SDRAM memory map      (SDRAM 8 MB at least)
    --
    -- Slot 0-0 : MainROM               [ D ]020000-027FFF (  32 KB)
    -- Slot 3-3 : XBASIC                [ D ]028000-02BFFF (  16 KB)
    -- Slot 0-2 : FM-BIOS               [ D ]02C000-02FFFF (  16 KB)
    -- Slot 0-3 : rom_free(OPT)         [ D ]03C000-03FFFF (  16 KB)
    -- Slot 1   : (EXTERNAL-SLOT)
    --            / ESE-SCC1-SMN(M4)    [A~B]100000-xFFFFF (2048 KB)        <= only for SDRAM < 16 MB + Mapper 4096 KB / shared with Mapper(RAM) starting from 1024 KB
    --            / Linear-1-SMN(M4)    [ A ]100000-10FFFF (  64 KB)        <= only for SDRAM < 16 MB + Mapper 4096 KB / shared with ESE-SCC1-SMN(M4)
    --            / ESE-SCC1-SMN(M2)    [ B ]000000-1FFFFF (2048 KB)        <= only for SDRAM < 16 MB + Mapper 2048 KB
    --            / Linear-1-SMN(M2)    [ B ]000000-10FFFF (  64 KB)        <= only for SDRAM < 16 MB + Mapper 2048 KB / shared with ESE-SCC1-SMN(M2)
    -- Slot 2   : (EXTERNAL-SLOT)
    --            / ESE-SCC2(L)         [ C ]000000-1FFFFF (2048 KB)        <= alias ESE-SCC2-SMN(L)
    --            / Linear-2            [ C ]000000-00FFFF (  64 KB)        <= alias Linear-2-SMN / shared with ESE-SCC2(L)
    --            / ESE-SCC2-SMN(H)(M4) [A~B]100000-xFFFFF (2048 KB)        <= only for SDRAM < 16 MB + Mapper 4096 KB / shared with ESE-SCC1-SMN(M4) in read-only mode
    --            / ESE-SCC2-SMN(H)(M2) [ B ]000000-1FFFFF (2048 KB)        <= only for SDRAM < 16 MB + Mapper 2048 KB / shared with ESE-SCC1-SMN(M2) in read-only mode
    -- Slot 3-0 : Mapper(RAM)           [A+B]000000-1FFFFF (4096 KB)        <= recognized as Main-RAM by the system if Extra-Mapper is disabled
    -- Slot 3-1 : ExtROM + KanjiROM     [ D ]030000-03BFFF (  48 KB)
    -- Slot 3-2 : ESE-RAM: BIOS         [ D ]000000-07FFFF ( 512 KB)        <= MegaSDHC at [ D ]000000-00FFFF (  64 KB) / NEXTOR at [ D ]000000-01FFFF ( 128 KB)
    --            ESE-RAM: FREE         [ D ]080000-0FF3FF ( 509 KB)        <= originally intended for RAMDISK but not implemented
    --            ESE-RAM: IPL-ROM(hex) [ D ]0FF400-0FFFFF (   3 KB)        <= 2944 bytes for IPL-ROM + 128 bytes for IGX Smart Profile
    -- Slot 3-3 : IPL-ROM(preloader)    (blockRAM: < 3 KB, see IPLROM*.ASM) <= swapped with XBASIC at boot time
    -- VRAM     : VRAM                  [ D ]100000-1FFFFF (1024 KB)
    -- I/O      : Kanji-data            [ D ]040000-07FFFF ( 256 KB)
    -----------------------------------------------------------------
    -- Slot map / SDRAM memory map      (SDRAM 16 MB at least)
    --
    -- Slot 0-1 : Extra-Mapper(RAM)     [A+B]200000-3FFFFF (4096 KB)        <= recognized as Main-RAM by the system if enabled
    -- Slot 1   : ESE-SCC1              [ C ]200000-3FFFFF (2048 KB)
    --            / Linear-1            [ C ]200000-20FFFF (  64 KB)        <= shared with ESE-SCC1
    -- Slot 2   : ESE-SCC2(H)           [ C ]200000-3FFFFF (2048 KB)        <= shared with ESE-SCC1 in read-only mode
    -----------------------------------------------------------------
    -- Memo: SdrAdr(12 downto 11) <= CpuAdr(24 downto 23);
    --       SdrBa ( 1 downto  0) <= CpuAdr(22 downto 21);
    -----------------------------------------------------------------
    CpuAdr(24 downto 20) <= "01" & "0"  & MapAdr(21 downto 20)              when( iSltMap0 = '1' and iSlt0_1 = '1' )else        -- [A+B]2xxxxx => 4096 KB Extra-Mapper(RAM)
                            "00" & "0"  & MapAdr(21 downto 20)              when( iSltMap  = '1' and FullRAM = '1' )else        -- [A+B]0xxxxx => 4096 KB Mapper(RAM)
                            "00" & "00" & MapAdr(20)                        when( iSltMap  = '1' )else                          -- [ A ]0xxxxx => 2048 KB Mapper(RAM)
                            "00" & "100"                                    when( iSltLin2 = '1' )else                          -- [ C ]0xxxxx =>   64 KB Linear over ESE-SCC2(L) / ESE-SCC2-SMN(L)
                            "0" & Scc2Adr(21) & "10" & Scc2Adr(20)          when( iSltScc2 = '1' )else                          -- [ C ]0xxxxx => 4096 KB ESE-SCC2(L) + ESE-SCC2(H)
                            "01" & "100"                                    when( iSltLin1 = '1' )else                          -- [ C ]2xxxxx =>   64 KB Linear over ESE-SCC1
                            "01" & "10" & Scc1Adr(20)                       when( iSltScc1 = '1' )else                          -- [ C ]2xxxxx => 2048 KB ESE-SCC1
                            "00" & "110";                                                                                       -- [ D ]0xxxxx => 1024 KB ESE-RAM

    CpuAdr(19 downto  0) <= MapAdr(19 downto  0)                            when( iSltMap0 = '1' or iSltMap  = '1' )else        -- [A+B]200000-3FFFFF (4096 KB) Internal Slot0-1
                                                                                                                                -- [A+B]000000-1FFFFF (4096 KB) Internal Slot3-0
                            "0000"   & adr(15 downto  0)                    when( iSltLin1 = '1' or iSltLin2 = '1' )else        -- [ C ]000000-00FFFF (  64 KB) Internal Slot2 Linear
                                                                                                                                -- [ C ]200000-20FFFF (  64 KB) Internal Slot1 Linear
                                                                                                                                -- [ A ]100000-10FFFF (  64 KB) Internal Slot1 Linear   <= only for SDRAM < 16 MB + Mapper 4096 KB
                                                                                                                                -- [ B ]000000-00FFFF (  64 KB) Internal Slot1 Linear   <= only for SDRAM < 16 MB + Mapper 2048 KB
                            Scc2Adr(19 downto  0)                           when( iSltScc2 = '1' )else                          -- [ C ]000000-3FFFFF (4096 KB) Internal Slot2
                                                                                                                                -- [CAB]000000-xFFFFF (4096 KB) Internal Slot2          <= only for SDRAM < 16 MB + Mapper 4096 KB
                                                                                                                                -- [C+B]000000-1FFFFF (4096 KB) Internal Slot2          <= only for SDRAM < 16 MB + Mapper 2048 KB
                            Scc1Adr(19 downto  0)                           when( iSltScc1 = '1' )else                          -- [ C ]200000-3FFFFF (2048 KB) Internal Slot1
                                                                                                                                -- [A~B]100000-xFFFFF (2048 KB) Internal Slot1          <= only for SDRAM < 16 MB + Mapper 4096 KB
                                                                                                                                -- [ B ]000000-1FFFFF (2048 KB) Internal Slot1          <= only for SDRAM < 16 MB + Mapper 2048 KB
                            ErmAdr                                          when( iSltErm  = '1' )else                          -- [ D ]000000-07FFFF (1024 KB) Internal Slot3-2
                            "00100"  & adr(14 downto  0)                    when( rom_main = '1' )else                          -- [ D ]020000-027FFF (  32 KB) Internal Slot0-0
                            "001010" & adr(13 downto  0)                    when( rom_xbas = '1' )else                          -- [ D ]028000-02BFFF (  16 KB) Internal Slot3-3
                            "001011" & adr(13 downto  0)                    when( rom_opll = '1' )else                          -- [ D ]02C000-02FFFF (  16 KB) Internal Slot0-2
                            "0011"   & adr(15 downto  0)                    when( rom_extd = '1' )else                          -- [ D ]030000-03BFFF (  48 KB) Internal Slot3-1
                            "001111" & adr(13 downto  0)                    when( rom_free = '1' )else                          -- [ D ]03C000-03FFFF (  16 KB) Internal Slot0-3
                            "01"     & KanAdr(17 downto  0)                 when( rom_kanj = '1' )else                          -- [ D ]040000-07FFFF ( 256 KB) Kanji-data (JIS1+JIS2)
                            (others => '0');

    ----------------------------------------------------------------
    -- SDRAM access
    ----------------------------------------------------------------
    -- SdrSta = "000" => idle
    -- SdrSta = "001" => precharge all
    -- SdrSta = "010" => refresh
    -- SdrSta = "011" => mode register set
    -- SdrSta = "100" => read cpu
    -- SdrSta = "101" => write cpu
    -- SdrSta = "110" => read vdp
    -- SdrSta = "111" => write vdp
    ----------------------------------------------------------------
    w_wrt_req   <=  (RamReq and (
                        (Scc1Wrt and iSltScc1 ) or
                        (Scc2Wrt and iSltScc2 ) or
                        (ErmWrt  and iSltErm  ) or
                        (MapWrt  and iSltMap0 ) or
                        (MapWrt  and iSltMap  )));

    process( memclk )
    begin
        if( memclk'event and memclk = '1' )then
            if( ff_sdr_seq = "111" )then
                if( RstSeq(4 downto 2) = "000" )then
                    SdrSta <= "000";                                                -- idle
                elsif( RstSeq(4 downto 2) = "001" )then
                    SdrSta <= "0" & RstSeq(1 downto 0);
                elsif( RstSeq(4 downto 3) /= "11" )then
                    SdrSta <= "101";                                                -- Write (Initialize memory content)
                elsif( iSltRfsh_n = '0' and VideoDLClk = '1' )then
                    SdrSta <= "010";                                                -- refresh
                else
                    -- Normal memory access mode
                    SdrSta(2) <= '1';                                               -- read/write cpu/vdp
                end if;
            elsif( ff_sdr_seq = "001" and SdrSta(2) = '1' and RstSeq(4 downto 3) = "11" )then
                SdrSta(1) <= VideoDLClk;                                            -- 0:cpu, 1:vdp
                if( VideoDLClk = '0' )then
                    SdrSta(0) <= w_wrt_req;         -- for cpu
                else
                    SdrSta(0) <= not WeVdp_n;       -- for vdp
                end if;
            end if;
        end if;
    end process;

    process( memclk )
    begin
        if( memclk'event and memclk = '1' )then
            case ff_sdr_seq is
                when "000" =>
                    if( SdrSta(2) = '1' )then               -- cpu/vdp read/write
                        SdrCmd <= SdrCmd_ac;
                    elsif( SdrSta(1 downto 0) = "00" )then  -- idle
                        SdrCmd <= SdrCmd_xx;
                    elsif( SdrSta(1 downto 0) = "01" )then  -- precharge all
                        SdrCmd <= SdrCmd_pr;
                    elsif( SdrSta(1 downto 0) = "10" )then  -- refresh
                        SdrCmd <= SdrCmd_re;
                    else                                    -- mode register set
                        SdrCmd <= SdrCmd_ms;
                    end if;
                when "001" =>
                    SdrCmd <= SdrCmd_xx;
                when "010" =>
                    if( SdrSta(2) = '1' )then
                        if( SdrSta(0) = '0' )then
                            SdrCmd <= SdrCmd_rd;            -- "100"(cpu read) / "110"(vdp read)
                        else
                            SdrCmd <= SdrCmd_wr;            -- "101"(cpu write) / "111"(vdp write)
                        end if;
                    end if;
                when "011" =>
                    SdrCmd <= SdrCmd_xx;
                when others =>
                    null;
            end case;
        end if;
    end process;

    process( memclk )
    begin
        if( memclk'event and memclk = '1' )then
            case ff_sdr_seq is
                when "000" =>
                    SdrUdq <= '1';
                    SdrLdq <= '1';
                when "010" =>
                    if( SdrSta(2) = '1' )then
                        if( SdrSta(0) = '0' )then
                            SdrUdq <= '0';
                            SdrLdq <= '0';
                        else
                            if( RstSeq(4 downto 3) /= "11" )then
                                SdrUdq <= '0';
                                SdrLdq <= '0';
                            elsif( VideoDLClk = '0' )then
                                SdrUdq <= not CpuAdr(0);
                                SdrLdq <= CpuAdr(0);
                            else
                                SdrUdq <= not VdpAdr(16);
                                SdrLdq <= VdpAdr(16);
                            end if;
                        end if;
                    end if;
                when "011" =>
                    SdrUdq <= '1';
                    SdrLdq <= '1';
                when others =>
                    null;
            end case;
        end if;
    end process;

    --------------------------------------------------------------------------------
    -- SDRAM controller compatible with 8 MB, 16 MB, 32 MB single chip and above
    -- STABLE VERSION 2025.01.21 by KdL          [ USE AT YOUR OWN RISK!! ]
    --------------------------------------------------------------------------------
    -- * ClrAdr counter has been removed
    -- * Other SDRAM processes are unchanged
    --
    -- Memo:    SdrAdr(12 downto 11) <= CpuAdr(24 downto 23);
    --          SdrBa ( 1 downto  0) <= CpuAdr(22 downto 21);
    --------------------------------------------------------------------------------
    process( memclk )
    begin
        if( memclk'event and memclk = '1' )then
            case ff_sdr_seq is
                when "000" =>
                    if( SdrSta(2) = '0' )then                                       -- set [command mode]
                        --           WBL=single TM=off CL=2 WT=0(seq) BL=1
                        SdrAdr <= "00" & "010" & "0" & "010" & "0" & "000";
                        SdrBa  <= "00";                                             -- bank A
                    else                                                            -- set [row address]
                        if( RstSeq(4 downto 2) = "010" and warmRESET /= '1' )then
                            SdrAdr <= "0100000000000";                              -- clear "AB" mark : ESE-SCC1
                            SdrBa  <= "1" & RstSeq(1);                              -- set bank C+D
                        elsif( RstSeq(4 downto 2) = "011" and warmRESET /= '1' )then
                            SdrAdr <= (others => '0');                              -- clear "AB" mark : ESE-SCC2 >> ESE-RAM
                            SdrBa  <= "1" & RstSeq(1);                              -- set bank C+D
                        elsif( VideoDLClk = '0' )then
                            SdrAdr <= CpuAdr(24 downto 23) & CpuAdr(11 downto 1);   -- cpu read/write
                            SdrBa  <= CpuAdr(22 downto 21);                         -- set bank A+B+C+D
                        else
                            SdrAdr <= "00" & VdpAdr(10 downto 0);                   -- vdp read/write
                            SdrBa  <= "11";                                         -- set bank D
                        end if;
                    end if;
                when "010" =>                                                                               -- set [column address]
                    SdrAdr(10 downto 9) <= "10";                                                            -- A10=1 => enable auto precharge, A9 can be used if SDRAM >= 64 MB (currently not used)
                    -- when A10=1, SdrBa is ignored and all banks are selected
                    -- be careful not to assign SdrBa during auto precharge, otherwise it will cause instability
                    if( RstSeq(4 downto 1) = "0110" and warmRESET /= '1' )then
                        SdrAdr(12 downto 11) <= CpuAdr(24 downto 23);
                        SdrAdr(8 downto 0) <= RstSeq(0) & "00000000";                                       -- clear ESE-SCC2 >> ESE-SCC1 (also Mapper(RAM) >> ESE-SCC1-SMN if SDRAM = 8 MB)
                    elsif( RstSeq(4 downto 1) = "0111" and warmRESET /= '1' )then
                        SdrAdr(12 downto 11) <= CpuAdr(24 downto 23);
                        SdrAdr(8 downto 0) <= (others => '0');                                              -- clear ESE-RAM
                    elsif( VideoDLClk = '0' )then
                        SdrAdr(12 downto 11) <= CpuAdr(24 downto 23);
                        SdrAdr(8 downto 0) <= CpuAdr(20 downto 12);                                         -- cpu read/write
                    elsif( VdpAdr(15) = '0' )then
                        SdrAdr(12 downto 11) <= "00";
                        SdrAdr(8 downto 0) <= "10000" & VdpAdr(14 downto 11);                               -- vdp read/write (even)
                    else
                        SdrAdr(12 downto 11) <= "00";
                        SdrAdr(8 downto 0) <= "10001" & VdpAdr(14 downto 11);                               -- vdp read/write (odd)
                    end if;
                when others =>
                    null;
            end case;
        end if;
    end process;

    -- SDRAM constraints
    process( memclk )
    begin
        if( memclk'event and memclk = '1' )then
            iSlt0_1 <= Mapper0_ack;
        end if;
    end process;

    process( memclk )
    begin
        if( memclk'event and memclk = '1' )then
            if( ff_sdr_seq = "010" )then
                if( SdrSta(2) = '1' )then
                    if( SdrSta(0) = '0' )then
                        SdrDat <= (others => 'Z');
                    else
                        if( RstSeq(4 downto 3) /= "11" )then
                            SdrDat <= (others => '0');
                        elsif( VideoDLClk = '0' )then
                            SdrDat <= dbo & dbo;                -- "101"(cpu write)
                        else
                            SdrDat <= VrmDbo & VrmDbo;          -- "111"(vdp write)
                        end if;
                    end if;
                end if;
            else
                SdrDat <= (others => 'Z');
            end if;
        end if;
    end process;

    -- Data read latch for CPU
    process( memclk )
    begin
        if( memclk'event and memclk = '1' )then
            if( ff_sdr_seq = "101" )then
                if( SdrSta = "100" )then                        -- read cpu
                    if( CpuAdr(0) = '0' )then
                        RamDbi <= pMemDat(  7 downto 0 );
                    else
                        RamDbi <= pMemDat( 15 downto 8 );
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Data read latch for VDP
    process( memclk )
    begin
        if( memclk'event and memclk = '1' )then
            if( ff_sdr_seq = "101" )then
                if( SdrSta = "110" )then                        -- read vdp
                    VrmDbi <= pMemDat( 15 downto 0 );
                end if;
            end if;
        end if;
    end process;

    -- SDRAM controller state
    process( memclk )
    begin
        if( memclk'event and memclk = '1' )then
            case ff_sdr_seq is
                when "000" =>
                    if( VideoDHClk = '1' or RstSeq(4 downto 3) /= "11" )then
                        ff_sdr_seq <= "001";
                    end if;
                when "111" =>
                    if( VideoDHClk = '0' or RstSeq(4 downto 3) /= "11" )then
                        ff_sdr_seq <= "000";
                    end if;
                when others =>
                    ff_sdr_seq <= ff_sdr_seq + 1;
            end case;
        end if;
    end process;

    process( reset, clk21m )
    begin
        if( reset = '1' )then
            RamAck <= '0';
        elsif( clk21m'event and clk21m = '1' )then
            if( RamReq = '0' )then
                RamAck <= '0';
            elsif( VideoDLClk = '0' and VideoDHClk = '1' )then
                RamAck <= '1';
            end if;
        end if;
    end process;

    pMemCke     <= '1';
    pMemCs_n    <= SdrCmd(3);
    pMemRas_n   <= SdrCmd(2);
    pMemCas_n   <= SdrCmd(1);
    pMemWe_n    <= SdrCmd(0);

    pMemUdq     <= SdrUdq;
    pMemLdq     <= SdrLdq;
    pMemBa1     <= SdrBa(1);
    pMemBa0     <= SdrBa(0);

    pMemAdr     <= SdrAdr;
    pMemDat     <= SdrDat;

    ----------------------------------------------------------------
    -- Reserved ports (USB)
    ----------------------------------------------------------------
--  pUsbP1      <= 'Z';
--  pUsbN1      <= 'Z';
    pUsbP2      <= 'Z';
    pUsbN2      <= 'Z';

    ----------------------------------------------------------------
    -- Connect components
    ----------------------------------------------------------------
    U00 : pll4x
        port map(
            inclk0   => pClk21m         ,   -- 21.48MHz external
            c0       => clk21m          ,   -- 21.48MHz internal
            c1       => memclk          ,   -- 85.92MHz = 21.48MHz x 4
            e0       => pMemClk             -- 85.92MHz external
        );

    U01 : t80a
        port map(
            RESET_n     => not reset    ,
            R800_mode   => '0'          ,   -- '0' => no MULU, '1' => MULU with LEs
            CLK_n       => iCpuClk      ,
            WAIT_n      => wait_n_s     ,
            INT_n       => pSltInt_n    ,
            NMI_n       => '1'          ,
            BUSRQ_n     => '1'          ,
            M1_n        => CpuM1_n      ,
            MREQ_n      => pSltMerq_n   ,
            IORQ_n      => pSltIorq_n   ,
            RD_n        => pSltRd_n     ,
            WR_n        => pSltWr_n     ,
            RFSH_n      => CpuRfsh_n    ,
            HALT_n      => open         ,
            BUSAK_n     => open         ,
            A           => pSltAdr      ,
            D           => pSltDat
        );

    U02 : iplrom
        port map(clk21m, adr, RomDbi);

    U03 : megasd
        port map(
            clk21m      => clk21m       ,
            reset       => reset        ,
            req         => ErmReq       ,
            wrt         => wrt          ,
            adr         => adr          ,
            dbo         => dbo          ,
            ramreq      => ErmRam       ,
            ramwrt      => ErmWrt       ,
            ramadr      => ErmAdr       ,
            mmcdbi      => MmcDbi       ,
            mmcena      => MmcEna       ,
            mmcact      => MmcAct       ,
            mmc_ck      => pSd_Ck       ,
            mmc_cs      => pSd_Dt(3)    ,
            mmc_di      => pSd_Cm       ,
            mmc_do      => pSd_Dt(0)    ,
            epc_ck      => EPC_CK       ,
            epc_cs      => EPC_CS       ,
            epc_oe      => EPC_OE       ,
            epc_di      => EPC_DI       ,
            epc_do      => EPC_DO       ,
            debug       => open
        );

    pSd_Dt(  2 downto 0 ) <= (others => 'Z');

    U04 : cyclone_asmiblock
        port map(EPC_CK, EPC_CS, EPC_DI, EPC_OE, EPC_DO);

    U05 : mapper
        port map(clk21m, reset, MapReq, open, mem, wrt, adr, MapDbi, dbo,
                        MapRam, MapWrt, MapAdr, RamDbi, open);

    U06 : eseps2
        port map(clk21m, reset, clkena, Kmap, Caps, Kana, Paus, Scro, Reso, Fkeys,
                        pPs2Clk, pPs2Dat, PpiPortC, PpiPortB, CmtScro, '0');

    U07 : rtc
        port map(clk21m, '0', rtcena, RtcReq, open, wrt, adr, RtcDbi, dbo);

    U08 : kanji
        port map(clk21m, reset, KanReq, open, wrt, adr, KanDbi, dbo,
                        KanRom, KanAdr, RamDbi, open);

    U20 : vdp
        -- TH9958 VDP core
        port map(clk21m, reset, VdpReq, open, wrt, adr, VdpDbi, dbo, pVdpInt_n,
                        open, WeVdp_n, VdpAdr, VrmDbi, VrmDbo, "000", centerYJK_R25_s,
                        VideoR, VideoG, VideoB, VideoHS_n, VideoVS_n, VideoCS_n,
                        VideoDHClk, VideoDLClk, open, interlace_mode, Reso_v, ntsc_pal_type, forced_v_mode, legacy_vga,
                        vga_int_field, spMaxSpr, VDP_ID, OFFSET_Y);

    centerYJK_R25_s <= centerYJK_R25_n or (not logo_timeout(1));

    U21 : vencode
        port map(clk21m, reset, VideoR, VideoG, videoB, VideoHS_n, VideoVS_n,
                        videoY, videoC, videoV);

    U30 : psg
        port map(clk21m, reset, clkena, PsgReq, open, wrt, adr, PsgDbi, dbo,
                        pJoyA, pStrA, pJoyB, pStrB, Kana, CmtIn, w_key_mode, PsgAmp);

    U31_1 : megaram
        port map(clk21m, reset, clkena, Scc1Req, Scc1Ack, wrt, adr, Scc1Dbi, dbo,
                        Scc1Ram, Scc1Wrt, Scc1Adr, RamDbi, open, Scc1Type, Scc1AmpL, open, '0');

    Scc1Type <= Slot1Mode & "0";

    U31_2 : megaram
        port map(clk21m, reset, clkena, Scc2Req, Scc2Ack, wrt, adr, Scc2Dbi, dbo,
                        Scc2Ram, Scc2Wrt, Scc2Adr, RamDbi, open, Slot2Mode, Scc2AmpL, open, xmr_ena);

    U32 : eseopll
        port map(clk21m, reset, clkena, OpllEnaWait, OpllReq, OpllAck, wrt, adr, dbo, OpllAmp);

    -- OPLL wait enabler
    OpllEnaWait <= ff_clksel xnor ff_clksel5m_n;

    -- sound output lowpass filter (sccic)
    u_interpo : interpo
        generic map(
            msbi    => DACin'high
        )
        port map(
            clk21m  => clk21m               ,
            reset   => not power_on_reset   ,
            clkena  => clkena               ,
            idata   => DACin                ,
            odata   => lpf1_wave
        );

    -- low pass filter
    u_lpf2 : lpf2
        generic map(
            msbi    => DACin'high
        )
        port map(
            clk21m  => clk21m               ,
            reset   => not power_on_reset   ,
            clkena  => clkena               ,
            idata   => lpf1_wave            ,
            odata   => lpf5_wave
        );

    U33 : esepwm
        generic map(DAC_msbi) port map(clk21m, not power_on_reset, lpf5_wave, DACout);

    U35 : switched_io_ports
        generic map(
            use_wifi_g      => use_wifi_g
        )
        port map(
            clk21m          => clk21m           ,
            reset           => reset            ,
            power_on_reset  => power_on_reset   ,
            req             => swio_req         ,
            ack             => open             ,
            wrt             => wrt              ,
            adr             => adr              ,
            dbi             => swio_dbi         ,
            dbo             => dbo              ,

            io40_n          => io40_n           ,
            io41_id212_n    => io41_id212_n     ,
            io42_id212      => io42_id212       ,
            io43_id212      => io43_id212       ,
            io44_id212      => io44_id212       ,

            display_mode_req => display_mode_req  ,

            PsgVol          => PsgVol           ,
            MstrVol         => MstrVol          ,
            OpllVol         => OpllVol          ,
            SccVol          => SccVol           ,

            CustomSpeed     => CustomSpeed      ,
            tMegaSD         => tMegaSD          ,
            tPanaRedir      => tPanaRedir       ,
            Mapper_req      => Mapper_req       ,
            Mapper_ack      => Mapper_ack       ,
            MegaSD_req      => MegaSD_req       ,
            MegaSD_ack      => MegaSD_ack       ,

            io41_id008_n    => io41_id008_n     ,
            swioKmap        => swioKmap         ,
            CmtScro         => CmtScro          ,
            swioCmt         => swioCmt          ,
            LightsMode      => LightsMode       ,
            Red_sta         => Red_sta          ,
            LastRst_sta     => LastRst_sta      ,
            RstReq_sta      => RstReq_sta       ,
            Blink_ena       => Blink_ena        ,

            pseudoStereo    => pseudoStereo     ,
            extclk3m        => extclk3m         ,
            ntsc_pal_type   => ntsc_pal_type    ,
            forced_v_mode   => forced_v_mode    ,

            right_inverse   => right_inverse    ,
            centerYJK_R25_n => centerYJK_R25_n  ,
            legacy_sel      => legacy_sel       ,
            iSlt1_linear    => iSlt1_linear     ,
            iSlt2_linear    => iSlt2_linear     ,

            btn_scan        => '1'              ,
            vga_scanlines   => vga_scanlines    ,
            bios_reload_ack => bios_reload_ack  ,
            Mapper0_req     => Mapper0_req      ,

            xmr_ena         => xmr_ena          ,
            OFFSET_Y        => OFFSET_Y         ,

            spMaxSpr        => spMaxSpr         ,
            vga_int_field   => vga_int_field    ,
            low_scale_n     => low_scale_n      ,
            Mapper0_ack     => Mapper0_ack      ,
            safe_mode       => safe_mode        ,
            portF2_ena      => portF2_ena       ,

            ff_dip_req      => ff_dip_req       ,
            ff_dip_ack      => ff_dip_ack       ,

            DefKmap         => DefKmap          ,

            ff_ldbios_n     => ff_ldbios_n      ,
            VDP_ID          => VDP_ID           ,
            JIS2_ena        => JIS2_ena         ,

            Scro            => Scro             ,
            ff_Scro         => ff_Scro          ,
            Reso            => Reso             ,
            ff_Reso         => ff_Reso          ,
            FKeys           => FKeys            ,
            vFKeys          => vFKeys           ,
            LevCtrl         => LevCtrl          ,
            GreenLvEna      => GreenLvEna       ,

            swioRESET_n     => swioRESET_n      ,
            warmRESET       => warmRESET        ,
            WarmMSXlogo     => WarmMSXlogo      ,
            full_reset_comb => full_reset_comb  ,
            cold_reset_comb => cold_reset_comb
        );

    wifi : if use_wifi_g generate
        uwifi : work.wifi
            port map(
                clk_i       => clk21m           ,
                wait_o      => esp_wait_s       ,
                reset_i     => xSltRst_n        ,   -- swioRESET_n was purposely excluded here
                iorq_i      => iSltIorq_n       ,
                wrt_i       => xSltWr_n         ,
                rd_i        => xSltRd_n         ,
                tx_i        => esp_tx_i         ,
                rx_o        => esp_rx_o         ,
                adr_i       => adr              ,
                db_i        => dbo              ,
                db_o        => esp_dout_s
            );
    end generate;

    esp_tx_i <= pUsbP1;
    pUsbN1 <= esp_rx_o;

    midi : if use_midi_g generate
        umidi : work.midi
            port map(
                clk_i       => clk21m           ,
                reset_i     => not reset        ,
                iorq_i      => iSltIorq_n       ,
                wrt_i       => xSltWr_n         ,
                rd_i        => xSltRd_n         ,
                tx_i        => '0'              ,
                rx_o        => midi_o           ,   -- module output pin
                adr_i       => adr              ,
                db_i        => dbo              ,
                db_o        => midi_dout_s      ,
                tx_active_o => midi_active_o
            );
    end generate;

    pJoyB(0) <= midi_o when( midi_active_o = '1' and use_midi_g )else
                'Z';

    -- | b7    | b6    | b5   | b4   | b3  | b2  | b1  | b0  |
    -- | SHIFT | LCTRL | PgUp | PgDn | F9  | F10 | F11 | F12 |

    -- Full Reset and Cold Reset combinations
    full_reset_comb  <=      vFkeys(7)  and vFkeys(6) and (vFkeys(0) xor Fkeys(0));     -- [LCTRL+SHIFT+F12]
    cold_reset_comb  <= (not vFkeys(7)) and vFkeys(6) and (vFkeys(0) xor Fkeys(0));     -- [LCTRL+F12]

end RTL;
