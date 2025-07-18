@echo off
rem --- '1_sm_compile.cmd' v3.2 by KdL (2025.06.29)

set TIMEOUT=1
set PROJECT=ocm_sm
set OUTPUT=output_files\
set QPATH=C:\altera_lite\24.1std\quartus\
if "%1"=="" color 87&title COMPILE for %PROJECT%
if not exist %PROJECT%_device.env goto err_init
set /P DEVICE=<%PROJECT%_device.env
if not exist %PROJECT%.qpf goto err_msg

:compile
if exist %QPATH%bin64\quartus.exe (
    start "" %QPATH%bin64\quartus.exe %PROJECT%.qpf
    goto init
)
if exist %QPATH%bin\quartus.exe (
    start "" %QPATH%bin\quartus.exe %PROJECT%.qpf
    goto init
)
if not exist "%QUARTUS_ROOTDIR%\common\devinfo\cycloneive" goto err_quartus
explorer %PROJECT%.qpf

:init
del "## BUILDING FAILED ##.log" >nul 2>nul
md %OUTPUT% >nul 2>nul
echo /* Quartus Prime Version 24.1std.0 Build 1077 03/04/2025 SC Lite Edition */>%OUTPUT%%PROJECT%.cdf
echo JedecChain;>>%OUTPUT%%PROJECT%.cdf
echo     FileRevision(JESD32A);>>%OUTPUT%%PROJECT%.cdf
echo     DefaultMfr(6E);>>%OUTPUT%%PROJECT%.cdf
echo.>>%OUTPUT%%PROJECT%.cdf
echo     P ActionCode(Cfg)>>%OUTPUT%%PROJECT%.cdf
if not "%DEVICE%"=="sxe" echo         Device PartName(EP4CE22) Path("../") File("ocm_sm.jic") MfrSpec(OpMask(1) SEC_Device(EPCS64) Child_OpMask(1 3));>>%OUTPUT%%PROJECT%.cdf
if "%DEVICE%"=="sxe" echo         Device PartName(EP4CE55) Path("../") File("ocm_sm.jic") MfrSpec(OpMask(1) SEC_Device(EPCQ64) Child_OpMask(1 3));>>%OUTPUT%%PROJECT%.cdf
echo.>>%OUTPUT%%PROJECT%.cdf
echo ChainEnd;>>%OUTPUT%%PROJECT%.cdf
echo.>>%OUTPUT%%PROJECT%.cdf
echo AlteraBegin;>>%OUTPUT%%PROJECT%.cdf
echo     ChainType(JTAG);>>%OUTPUT%%PROJECT%.cdf
echo AlteraEnd;>>%OUTPUT%%PROJECT%.cdf
goto quit

:err_init
if "%1"=="" color f0
echo.&echo Please initialize a device first!
goto timer

:err_quartus
if "%1"=="" color f0
echo.&echo Quartus Prime was not found or unsupported device!
goto timer

:err_msg
if "%1"=="" color f0
echo.&echo '%PROJECT%.qpf' not found!

:timer
if "%1"=="" waitfor /T %TIMEOUT% pause >nul 2>nul

:quit
