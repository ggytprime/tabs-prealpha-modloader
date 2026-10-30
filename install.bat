@echo off
setlocal enabledelayedexpansion

set "GAME=C:\Program Files (x86)\Totally Accurate Battle Simulator Pre-Alpha"
set "MANAGED=%GAME%\TotallyAccurateBattleSimulatorPreAlpha_Data\Managed"
set "REPO=C:\Users\gabim\Documents\projeto\tabs-modloader"
set "LOG=%REPO%\build\install.log"

echo === TabsModLoader install === > "%LOG%"

if not exist "%MANAGED%\Assembly-CSharp.dll" (
    echo FAIL: Managed folder or Assembly-CSharp.dll not found>>"%LOG%"
    type "%LOG%"
    exit /b 1
)

echo [1/4] copying TabsModLoader.dll>>"%LOG%"
copy /Y "%REPO%\build\TabsModLoader.dll" "%MANAGED%\TabsModLoader.dll">>"%LOG%" 2>&1
if errorlevel 1 (
    echo FAIL: could not copy TabsModLoader.dll>>"%LOG%"
    type "%LOG%"
    exit /b 1
)

echo [2/4] patching Assembly-CSharp.dll>>"%LOG%"
"%REPO%\build\Patcher.exe" "%MANAGED%\Assembly-CSharp.dll" "%MANAGED%\TabsModLoader.dll">>"%LOG%" 2>&1
if errorlevel 1 (
    echo FAIL: patcher returned an error>>"%LOG%"
    type "%LOG%"
    exit /b 1
)

echo [3/4] Mods folder>>"%LOG%"
if not exist "%GAME%\Mods" mkdir "%GAME%\Mods"

echo [4/5] installing ExampleMod.dll>>"%LOG%"
copy /Y "%REPO%\build\ExampleMod.dll" "%GAME%\Mods\ExampleMod.dll">>"%LOG%" 2>&1
if errorlevel 1 (
    echo WARN: could not copy ExampleMod.dll>>"%LOG%"
)

echo [5/5] installing GoreMod.dll>>"%LOG%"
copy /Y "%REPO%\build\GoreMod.dll" "%GAME%\Mods\GoreMod.dll">>"%LOG%" 2>&1
if errorlevel 1 (
    echo WARN: could not copy GoreMod.dll>>"%LOG%"
)

echo INSTALL_OK>>"%LOG%"
type "%LOG%"
exit /b 0
