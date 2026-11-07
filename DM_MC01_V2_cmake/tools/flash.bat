@echo off
rem ============================================================
rem  MX2 flash script  --  STM32C593RET6 / ST-LINK / SWD
rem  (ASCII only: cmd.exe uses GBK on this machine, Chinese
rem   text in .bat gets garbled - keep this file English.)
rem
rem  usage:
rem      flash.bat                auto-find DM_MC01_V2.elf and flash
rem      flash.bat <path.elf>     flash the given elf
rem
rem  requires STM32CubeProgrammer >= 2.21 (C5 / 0x44E in Data_Base)
rem ============================================================
setlocal

set "PROJ=%~dp0.."
set "ELF=%~1"

if not "%ELF%"=="" goto have_elf

if exist "%PROJ%\cmake-build-debug\DM_MC01_V2.elf" set "ELF=%PROJ%\cmake-build-debug\DM_MC01_V2.elf"
if not "%ELF%"=="" goto have_elf

if exist "%PROJ%\build\CLion-Debug\DM_MC01_V2.elf" set "ELF=%PROJ%\build\CLion-Debug\DM_MC01_V2.elf"
if not "%ELF%"=="" goto have_elf

if exist "%PROJ%\build\debug_GCC_STM32C593RET6\DM_MC01_V2.elf" set "ELF=%PROJ%\build\debug_GCC_STM32C593RET6\DM_MC01_V2.elf"
if not "%ELF%"=="" goto have_elf

echo [ERROR] DM_MC01_V2.elf not found. Build in CLion first, or pass the elf path.
exit /b 1

:have_elf
if not exist "%ELF%" goto no_elf

if "%STM32CUBEPROG%"=="" set "STM32CUBEPROG=D:\ENG\stm32\STM32cube\cubeProgrammer"
set "CPCLI=%STM32CUBEPROG%\bin\STM32_Programmer_CLI.exe"
if not exist "%CPCLI%" goto no_tool

echo [INFO] elf : %ELF%
echo [INFO] tool: %CPCLI%
echo.

"%CPCLI%" -c port=SWD freq=4000 -w "%ELF%" -v -rst
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" goto failed
echo [OK] flashed and verified, board reset.
exit /b 0

:no_elf
echo [ERROR] elf not found: %ELF%
exit /b 1

:no_tool
echo [ERROR] STM32_Programmer_CLI.exe not found: %CPCLI%
echo         set env var STM32CUBEPROG to the CubeProgrammer install dir.
exit /b 1

:failed
echo [FAIL] rc=%RC%
echo        - "No ST-Link detected": check the probe is plugged in.
echo        - "Device not supported / 0x44E": CubeProgrammer too old, need >= 2.21.
exit /b %RC%
