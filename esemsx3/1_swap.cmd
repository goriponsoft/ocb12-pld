@echo off
rem --- '1_swap.cmd' v3.2 by KdL (2025.06.29)

set TIMEOUT=1
set PROJECT=emsx_top
if "%1"=="" if exist "__1chipmsx__" color 4f
if "%1"=="" if exist "__onechipbook12__" color 1f
if "%1"=="" title SWAP for %PROJECT%
rem ---------------cleanup----------------
call 3_finalize.cmd --no-wait
rem --------------------------------------

:onechipbook12
if not exist %PROJECT%_304k.hex.backslash.onechipbook12 goto msxplusplus
ren %PROJECT%_304k.hex %PROJECT%_304k.hex.backslash.msxplusplus
ren %PROJECT%_304k.hex.backslash.onechipbook12 %PROJECT%_304k.hex
if exist %PROJECT%.pld ren %PROJECT%.pld %PROJECT%.pld.1chipmsx >nul 2>nul
if exist recovery.pof ren recovery.pof recovery.pof.1chipmsx >nul 2>nul
if exist %PROJECT%.fit.summary ren %PROJECT%.fit.summary %PROJECT%.fit.summary.1chipmsx >nul 2>nul
del "__1chipmsx__"
rem.>"__onechipbook12__"
cd src\peripheral\
ren swioports.vhd swioports.vhd.1chipmsx >nul 2>nul
ren swioports.vhd.japanese swioports.vhd.japanese.1chipmsx >nul 2>nul
ren swioports.vhd.onechipbook12 swioports.vhd >nul 2>nul
ren swioports.vhd.japanese.onechipbook12 swioports.vhd.japanese >nul 2>nul
cd ..
ren emsx_top.vhd emsx_top.vhd.1chipmsx >nul 2>nul
ren emsx_top.vhd.onechipbook12 emsx_top.vhd >nul 2>nul
cd ..

if "%1"=="" cls
if not "%1"=="--no-wait" echo.&echo OneChipBook-12 is ready to compile!
goto timer

:msxplusplus
if not exist %PROJECT%_304k.hex.backslash.msxplusplus goto err_msg
ren %PROJECT%_304k.hex %PROJECT%_304k.hex.backslash.onechipbook12
ren %PROJECT%_304k.hex.backslash.msxplusplus %PROJECT%_304k.hex
if exist %PROJECT%.pld ren %PROJECT%.pld %PROJECT%.pld.onechipbook12 >nul 2>nul
if exist recovery.pof ren recovery.pof recovery.pof.onechipbook12 >nul 2>nul
if exist %PROJECT%.fit.summary ren %PROJECT%.fit.summary %PROJECT%.fit.summary.onechipbook12 >nul 2>nul
del "__onechipbook12__"
rem.>"__1chipmsx__"
cd src\peripheral\
ren swioports.vhd swioports.vhd.onechipbook12 >nul 2>nul
ren swioports.vhd.japanese swioports.vhd.japanese.onechipbook12 >nul 2>nul
ren swioports.vhd.1chipmsx swioports.vhd >nul 2>nul
ren swioports.vhd.japanese.1chipmsx swioports.vhd.japanese >nul 2>nul
cd ..
ren emsx_top.vhd emsx_top.vhd.onechipbook12 >nul 2>nul
ren emsx_top.vhd.1chipmsx emsx_top.vhd >nul 2>nul

if "%1"=="" cls&echo.&echo 1chipMSX is ready to compile!  ^(default^)&goto timer
if not "%1"=="--no-wait" echo.&echo 1chipMSX is ready to compile!
goto timer

:err_msg
if "%1"=="" color f0
echo.&echo '%PROJECT%_304k.hex.backslash.???' not found!

:timer
if "%1"=="" waitfor /T %TIMEOUT% pause >nul 2>nul

:quit
cd ..
