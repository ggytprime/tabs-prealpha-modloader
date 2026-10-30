#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
ROOT="$PWD"
OUT="$ROOT/build"
echo "=== TabsModLoader installer ==="
echo "root: $ROOT"
echo "build: $OUT"
echo

: "${GAME_DIR:?set GAME_DIR to the game folder}"
if [ ! -d "$GAME_DIR" ]; then
    echo "ERROR: game folder not found: $GAME_DIR" >&2; exit 2
fi

EXE_TAG="$(find "$GAME_DIR" -maxdepth 1 -name "*TotallyAccurateBattleSimulator*.exe" | head -n 1)"
EXE="$(cygpath -w "$EXE_TAG")"
M="$(cygpath -w "$GAME_DIR/TotallyAccurateBattleSimulatorPreAlpha_Data/Managed")"

if [ -z "$EXE" ]; then echo "no game exe found" >&2; exit 3; fi
echo "game exe: $EXE"
echo "managed:  $M"
echo

# 1) verify build outputs
for f in TabsModLoader.dll ExampleMod.dll Patcher.exe; do
    if [ ! -f "$OUT/$f" ]; then echo "build missing: $OUT/$f" >&2; exit 4; fi
done
echo "build outputs OK"

# 2) backup + patch Assembly-CSharp.dll
ASM="$M/Assembly-CSharp.dll"
if [ ! -f "$ASM" ]; then echo "Assembly-CSharp.dll missing" >&2; exit 5; fi
echo
echo "patching $ASM ..."
"$OUT/Patcher.exe" "$ASM" "$OUT/TabsModLoader.dll" || { echo "patching failed"; exit 6; }

# 3) copy loader to managed
cp -v "$OUT/TabsModLoader.dll"     "$M/TabsModLoader.dll"
# 4) mods folder + example
mkdir -p "$GAME_DIR/Mods/Example"
cp -v "$OUT/ExampleMod.dll" "$GAME_DIR/Mods/Example/ExampleMod.dll"

# 5) report
echo
echo "installed into: $GAME_DIR"
echo "  Managed/TabsModLoader.dll"
echo "  Managed/Assembly-CSharp.dll (patched, original in *bak)"
echo "  Mods/Example/ExampleMod.dll"
echo
echo "Starting game from the same dir shows [TabsModLoader] INFO lines."
echo "Controls in-game: F1 restart, F2 export units.txt"
echo
echo "To remove: run uninstall.sh"
unset EXE_TAG
