# Ashtonite.Core Drone

Unofficial community Acro + Classic FPV drone camera script for Orion Drift Spectator.

> **Disclaimer:** This product is not affiliated with Another Axiom Inc. or its videogames Gorilla Tag and Orion Drift and is not endorsed or otherwise sponsored by Another Axiom. Portions of the materials contained herein are property of Another Axiom. ©2025 Another Axiom Inc.

**Current version: 2.1.0** (version lives here, in the changelog and in `package.json`, not in the filename)

2.0.0 is an independent rewrite. It's shorter and optimised, with the same controls, GUI and saved settings.
See [CHANGELOG.md](CHANGELOG.md).

## Install

1. [Download Ashtonite.Core Drone.Luau](https://github.com/Ashtonite365/Ashtonite-Core-Drone/raw/main/Ashtonite.Core%20Drone.Luau)

   Current version: **2.1.0**
2. Put that file in `Documents\\Another-Axiom\\A2\\Cameras\\Behaviors`
3. In Spectator, open Cameras (`F2`), **Reload All**, and activate **Ashtonite.Core Drone**

The build tag next to the top buttons (`build: v2.1.0`) shows which build you have installed.

## Modes

- **Acro**: rate drone (throttle + attitude)
- **Classic**: triggers up/down, left stick move, right stick look, bumpers roll, optional Gravity Assist

## Tabs

Controls, On Screen Display, Drone Settings (includes Sensitivity), Camera Settings, Colour, Rendering

## Credits

- Author: **Ashtonite (Ashtonite365)**
- **2.0.0 is an independent clean-room rewrite.** It was written from a description of how the drone behaves, not from
  anyone else's code. A similarity check found no code in common with Another Axiom's default drone camera, and only a
  handful of generic API lines in common with Scha's script.
- Thanks to **Schafreu ("Scha")**: earlier versions (1.0.0 to 1.1.2, in `archive/`) were inspired by and built on
  **Scha's Drone Camera** (`F1n_VR_FPV.luau`), which is itself based on Another Axiom's default Orion Drift drone camera.
- Developed with AI assistance (Grok Bot agents).

See [CHANGELOG.md](CHANGELOG.md) for what changed in each version.  
Older drops: [`archive/`](archive/).

## Licence

Copyright (c) 2026 Ashtonite (Ashtonite365).

Ashtonite.Core Drone **2.0.0 and later** is free software under the **GNU General Public License v3.0 only**
(`GPL-3.0-only`, see [LICENSE](LICENSE)), with the additional terms in [NOTICE](NOTICE):

- You can use, study, change and share it.
- If you share it or a modified version, you must share the full source under the same licence, keep the credit to
  Ashtonite (Ashtonite365) and the NOTICE, and mark your version as modified. Nobody may turn it into a closed-source script.
- It comes with no warranty.

**Archived versions before 2.0.0 are not covered by this licence.** They contain code derived from Scha's Drone Camera
(Schafreu) and Another Axiom's default drone camera, so they stay under their original terms (all rights reserved by their
respective owners). See [archive/README.md](archive/README.md).

The GPL grants no rights in Another Axiom material. Use of Orion Drift game material is subject to Another Axiom's
[Fan Content & Mod Policy](https://oriondriftvr.com/asset-kit) (non-commercial, community use only).
