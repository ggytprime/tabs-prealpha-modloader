#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
echo "=== TabsModLoader uninstaller ==="
: "${GAME_DIR:?set GAME_DIR to the game folder}"
M="$(cygpath -w "$GAME_DIR/TotallyAccurateBattleSimulatorPreAlpha_Data/Managed")"

# restore original DLL (patcher leaves a .bak alongside the managed folder)
if [ -f "$M/Assembly-CSharp.dll.bak" ]; then
    mv -v "$M/Assembly-CSharp.dll.bak" "$M/Assembly-CSharp.dll"
    echo "restored Assembly-CSharp.dll from backup"
else
    echo "WARN: no backup found; leaving Assembly-CSharp.dll as-is"
fi

rm -vf "$M/TabsModLoader.dll"
rm -vf "$GAME_DIR/Mods/Example/ExampleMod.dll"
rm -vf "$GAME_DIR/Mods/Example.dll"          # edge case: flat-style
rm -vf "$GAME_DIR/Mods/ExampleMod.dll"
rm -rf "$GAME_DIR/Mods/Example"
rm -vf "$GAME_DIR/Mods/GoreMod.dll"
echo "uninstalled TabsModLoader + example mod + gore mod"
