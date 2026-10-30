#!/usr/bin/env bash
# Builds TabsModLoader.dll, ExampleMod.dll and Patcher.exe with the .NET Framework
# compiler that ships with Windows, using response files (MSYS would otherwise
# rewrite /option arguments into Windows paths).
#
# usage: bash build.sh
set -euo pipefail
cd "$(dirname "$0")"

REPO="$(cygpath -w "$PWD")"
GAME="${GAME_DIR:-/c/Program Files (x86)/Totally Accurate Battle Simulator Pre-Alpha}"
MANAGED_WIN="$(cygpath -w "$GAME/TotallyAccurateBattleSimulatorPreAlpha_Data/Managed")"
OUT="$PWD/build"
mkdir -p "$OUT"
OUT_WIN="$(cygpath -w "$OUT")"

CSC=/c/Windows/Microsoft.NET/Framework64/v4.0.30319/csc.exe

echo "repo    : $REPO"
echo "managed : $MANAGED_WIN"
echo "output  : $OUT_WIN"
echo

# 1) TabsModLoader.dll -------------------------------------------------------
cat > "$OUT/loader.rsp" <<EOF
/nologo
/noconfig
/nostdlib
/target:library
/out:"$OUT_WIN\\TabsModLoader.dll"
/r:"$MANAGED_WIN\\mscorlib.dll"
/r:"$MANAGED_WIN\\System.dll"
/r:"$MANAGED_WIN\\System.Core.dll"
/r:"$MANAGED_WIN\\UnityEngine.dll"
/r:"$MANAGED_WIN\\Assembly-CSharp.dll"
"$REPO\\src\\ModLoader\\Bootstrap.cs"
"$REPO\\src\\ModLoader\\ModLoaderCore.cs"
"$REPO\\src\\ModLoader\\ModEngine.cs"
"$REPO\\src\\ModLoader\\ModApi.cs"
"$REPO\\src\\ModLoader\\ConsoleWindow.cs"
"$REPO\\src\\ModLoader\\GameHooks.cs"
EOF
"$CSC" -noconfig @"$OUT_WIN\\loader.rsp"
echo "built TabsModLoader.dll"

# 2) ExampleMod.dll ----------------------------------------------------------
cat > "$OUT/example.rsp" <<EOF
/nologo
/noconfig
/nostdlib
/target:library
/out:"$OUT_WIN\\ExampleMod.dll"
/r:"$MANAGED_WIN\\mscorlib.dll"
/r:"$MANAGED_WIN\\System.dll"
/r:"$MANAGED_WIN\\System.Core.dll"
/r:"$OUT_WIN\\TabsModLoader.dll"
"$REPO\\src\\Example\\ExampleMod.cs"
EOF
"$CSC" -noconfig @"$OUT_WIN\\example.rsp"
echo "built ExampleMod.dll"

# 2b) GoreMod.dll ------------------------------------------------------------
cat > "$OUT/gore.rsp" <<EOF
/nologo
/noconfig
/nostdlib
/target:library
/out:"$OUT_WIN\\GoreMod.dll"
/r:"$MANAGED_WIN\\mscorlib.dll"
/r:"$MANAGED_WIN\\System.dll"
/r:"$MANAGED_WIN\\System.Core.dll"
/r:"$MANAGED_WIN\\UnityEngine.dll"
/r:"$MANAGED_WIN\\Assembly-CSharp.dll"
/r:"$OUT_WIN\\TabsModLoader.dll"
"$REPO\\src\\Gore\\GoreMod.cs"
"$REPO\\src\\Gore\\BloodSystem.cs"
"$REPO\\src\\Gore\\GoreMaterials.cs"
"$REPO\\src\\Gore\\Dismemberment.cs"
EOF
"$CSC" -noconfig @"$OUT_WIN\\gore.rsp"
echo "built GoreMod.dll"

# 3) Patcher.exe -------------------------------------------------------------
cp -f "$PWD/lib/Mono.Cecil.dll" "$OUT/" 2>/dev/null || true
cat > "$OUT/patcher.rsp" <<EOF
/nologo
/target:exe
/out:"$OUT_WIN\\Patcher.exe"
/r:"$REPO\\lib\\Mono.Cecil.dll"
"$REPO\\tools\\Patcher\\Patcher.cs"
EOF
"$CSC" -noconfig @"$OUT_WIN\\patcher.rsp"
echo "built Patcher.exe"

echo
ls -la "$OUT" | sed 's/^/  /'
echo "DONE"
