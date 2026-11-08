# Pocket Arena / UnmatchedPocket

[Русская инструкция](README.ru.md) · [Downloads](https://github.com/kuzurakis/unmatched-pocket/releases/tag/v0.38)

Pocket Arena is an unofficial, offline fan project based on Unmatched. Version 0.38 includes 84 fighters, 34 maps, solo play against bots, and interface text in English, Russian, Norwegian Bokmål, and Spanish.

## Download and play

1. Open the [v0.38 release](https://github.com/kuzurakis/unmatched-pocket/releases/tag/v0.38).
2. On Android, download `UnmatchedPocket-v0.38-android.apk` and open it on the device. If prompted, allow your file manager or browser to install that APK. The APK targets ARM phones and uses a development signature.
3. On Windows x64, download and run `UnmatchedPocket-v0.38-windows.exe`. Godot is only needed to run or build the source project.
4. Start a new game, choose a fighter and map, then pick the bots' skill level. Tap a fighter or a card to see its description.

## Inspect and build

The Godot project is at the repository root. `scripts/` contains the GDScript game logic, `data/` the decks, map definitions and translations, and `assets/` the art used by the game. Start with `project.godot`, `main.tscn`, and `scripts/game_engine.gd` when reviewing the code. Build scripts are in `tools/`, and test scripts are in `tests/`.

Import `project.godot` in Godot 4.7.1 with the Compatibility renderer. Press **F5** to run the project.

For a Windows export, install the matching Godot export templates and run this from the repository root in PowerShell. Replace the example paths with those on your machine.

```powershell
.\tools\build-windows.ps1 -GodotExe 'C:\Godot\Godot_v4.7.1-stable_win64_console.exe' `
  -TemplateDir 'C:\Godot\templates\4.7.1.stable' `
  -OutputExe '..\UnmatchedPocket-v0.38-windows.exe'
```

For Android, install JDK 17 and the Android SDK with Platform Tools and Build Tools 35.0.1. The template directory should contain `android_debug.apk` from the matching Godot templates. The script creates a local development key and verifies the APK signature and alignment.

```powershell
.\tools\build-android.ps1 -GodotExe 'C:\Godot\Godot_v4.7.1-stable_win64_console.exe' `
  -JavaHome 'C:\Program Files\Java\jdk-17' -AndroidSdk 'C:\Android\Sdk' `
  -TemplateDir 'C:\Godot\templates\4.7.1.stable' `
  -OutputApk '..\UnmatchedPocket-v0.38-android.apk'
```

Download `UnmatchedPocket-v0.38-SHA256.txt` from the same release. Calculate a downloaded file's hash and compare it to the line with the same filename.

```powershell
Get-FileHash -Algorithm SHA256 .\UnmatchedPocket-v0.38-android.apk
Get-FileHash -Algorithm SHA256 .\UnmatchedPocket-v0.38-windows.exe
```

The checksum verifies that a download matches the published file. Independent review can start with the source at the release tag or a local build using your own signing key. [Test report](docs/build-v0.38.md)

Unmatched and the third-party characters, artwork, and card scans are credited to their respective rights holders. This project is unaffiliated with the publishers. Public access to this repository does not grant a license to reuse third-party material.
