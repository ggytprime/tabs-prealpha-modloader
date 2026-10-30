# TabsModLoader

A minimal C# Mod Loader and IL Patcher for **Totally Accurate Battle Simulator (Pre-Alpha)** — Unity 5.5, Mono (x64).

- Hooks before Unity initializes game state — injects a call into `GameLogic.Awake()` (main thread) inside `Assembly-CSharp.dll`.
- Loads custom DLLs from the `Mods/` directory. Mods derive from `TabsMod` to access Unity callbacks, logging, and the game's `Assembly-CSharp.dll`.
- To compile a mod, simply reference `Assembly-CSharp.dll`, `UnityEngine.dll`, `System.dll`/`System.Core.dll`, and `TabsModLoader.dll`.

## Project Structure

TabsModLoader/
build/             # Output: TabsModLoader.dll, ExampleMod.dll, GoreMod.dll, Patcher.exe
src/
ModLoader/       # Loader core (Bootstrap, ModLoaderCore, ModEngine, ModApi, GameHooks)
Example/         # Example mod implementation
Gore/            # Gore engine: procedural blood, dismemberment, bone splints, decals
tools/
Patcher/         # Patcher.exe (Mono.Cecil) — injects Bootstrap.Init into Assembly-CSharp
Inspect/         # Assembly inspection tool for development
lib/               # Mono.Cecil (net40)
build.sh           # Builds all projects against game assemblies
install.bat        # Windows installer (requires administrator privileges)
install.sh         # Bash variant installer
uninstall.sh       # Uninstalls loader and restores original Assembly-CSharp.dll
README.md


## Installation

### Windows (Automated Batch)
Run `install.bat` as Administrator:
```cmd
install.bat
Because the game is installed in Program Files (x86) by default, administrator privileges are required to modify:

TotallyAccurateBattleSimulatorPreAlpha_Data/Managed/Assembly-CSharp.dll (patched; original saved to .bak)

TotallyAccurateBattleSimulatorPreAlpha_Data/Managed/TabsModLoader.dll

Mods/ExampleMod.dll

Mods/GoreMod.dll

To target a custom game path, set the GAME environment variable before running:

DOS
set "GAME=C:\Games\TABS_PreAlpha" && install.bat
Linux / Bash
Bash
GAME_DIR="/path/to/game/directory" bash install.sh
Uninstallation
Bash
GAME_DIR="/path/to/game/directory" bash uninstall.sh
This restores the original Assembly-CSharp.dll from the .bak backup and removes all loader files.

How to Create a Mod
Create a C# class deriving from TabsMod.

Decorate it with [TabsMod("ModName")] (version and author optional).

Override Load(ModContext ctx).

Minimal example:

C#
using TabsModLoader;
using UnityEngine;

namespace MyMod
{
    [TabsMod("MyMod", Version = "1.0", Author = "Developer")]
    public class MyMod : TabsMod
    {
        public override void Load(ModContext ctx)
        {
            ctx.Log("MyMod loaded successfully!");
            ctx.OnUpdate(() =>
            {
                if (Input.GetKeyDown(KeyCode.H))
                    ctx.Log("H key pressed!");
            });
        }
    }
}
Compile against Managed/*.dll + TabsModLoader.dll. The Load method runs on the Unity main thread immediately after GameLogic.Awake().

Available API
ModContext (received in Load):

ctx.Name, ctx.Directory, ctx.DataDirectory (%LOCALAPPDATA%\TabsModLoader\<ModName>, guaranteed writable)

ctx.Log, ctx.LogWarning, ctx.LogError, ctx.LogException

ctx.OnUpdate(Action) — Executed every frame on the main thread

ctx.OnUnitDamaged(Action<UnitDamaged>) — Damage hook with contact point, direction, weapon, and target unit

ctx.Unload() — Called on application exit

Mods (Static API):

Mods.GameDirectory, Mods.ModsDirectory, Mods.LoaderVersion

Mods.OnUpdate(Action), Mods.Log, Mods.LogWarning, Mods.LogError, Mods.LogException

LoaderLog.LogFilePath — Points to current active log file path.

Win32 Console & Logging
Upon boot, the loader allocates a dedicated Win32 console (AllocConsole) alongside the game window:

Displays Loader version, Unity version, game path, and mods path.

Lists all discovered and loaded DLLs with status formatting (warnings in yellow, errors in red).

Outputs to TabsModLoader.log in the game root (falls back to %LOCALAPPDATA%\TabsModLoader\loader.log if write access is restricted).

Mirrors output to UnityEngine.Debug.Log.

Included Example Mod (ExampleMod)
Demonstrates baseline functionality: registers an update hook, tracks frame count, creates a test file in its %LOCALAPPDATA% data folder, and logs runtime events.

Included Gore Mod (GoreMod)
A procedural gore system showcasing deep game logic interaction via hooks:

Damage Hook: Receives exact impact positions via UnitHandler.TakeDamage.

Dismemberment: Locates nearest ragdoll Joint to impact, destroys connected joints to prevent physics stretching, unparents severed limbs, and freezes them once settled to prevent perpetual animation jitter.

Procedural Assets: Generates blood textures, splats, meat chunks, and bone shards dynamically at runtime without requiring external Unity AssetBundles.

Performance Budget: Capped at 340 droplets, 190 decals, 70 meat chunks, and 4 severed limbs per unit.

Controls: F3 toggles gore on/off, F4 clears scene decals and gibs.

Building from Source
Bash
GAME_DIR="/path/to/game/directory" bash build.sh
Compiles TabsModLoader.dll, ExampleMod.dll, GoreMod.dll, and Patcher.exe into build/.

Technical Details
IL Patcher:

Injects TabsModLoader.Bootstrap::Init() into GameLogic.Awake().

Injects TabsModLoader.GameHooks::UnitDamage(...) directly before m_health -= damage in UnitHandler.TakeDamage().

Background Execution: Forces Application.runInBackground = true so physics and procedural effects continue rendering when unfocused.
