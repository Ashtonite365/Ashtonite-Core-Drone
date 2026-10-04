# Changelog

## 2.0.0

Partial rewrite to shorten and optimise the code. The script was re-implemented from scratch with the same controls,
GUI, labels and saved-setting keys, so existing settings carry over. It's about 22% smaller (54.7 KB, 1,235 lines,
was 69.9 KB, 1,365 lines). Settings are now table-driven and the GUI sections are generated from short descriptions.
It's now licensed under GPL-3.0-only (see Licence below).

Added
- Gravity Assist for Classic mode: on/off toggle, Gravity Assist Strength (0 to 1, share of gravity cancelled) and
  Perfect Assist (push straight up in world space: no tilt limit, no sideways drift)
- Fall Acceleration in every mode (default 0.5): how fast a hands-off drone speeds up while falling, as a share of Gravity
- Build tag shown next to the top buttons, to identify the installed build

Changed
- Surface Friction moved above Gravity in Drone Settings > Physics

Fixed
- Right-stick OSD dot now follows the thumb on a controller (up/down was shown flipped)
- D-pad short taps (save position / respawn) no longer get missed between two ticks

Licence
- Licensed under GPL-3.0-only with NOTICE additional terms (keep the author attribution, mark modified versions).
  Added LICENSE, NOTICE and `package.json` licence field
- Archived versions before 2.0.0 are not covered by the new licence (see `archive/README.md`)
- 1.1.2 archived (`archive/1.1.2/`, frozen file at commit `dc53a20`)

## 1.1.2

Added
- Separate Movement Smoothness and Rotation Smoothness sliders
- Rendering tab for name tags and spectator debug visuals
- Colour picker apply-to-item flow

Changed
- Drone Sensitivity lives in Drone Settings
- HUD drawn closer to the camera (less ground / wall clip)

Fixed
- Rotation smoothness no longer throwing the OSD off screen
- Script vanishing from the camera list (200 local register cap)
- Thin-wall / editor-geo collision pop and wrong-side eject
- Colour tab crash from passing a table into colorEdit

## 1.1.1

Added
- Sensitivity tab tips for full-stick curve
- GrandEffect ground-boost tip
- Drone Settings sections: Throttle, Physics, Hitbox

Changed
- Input Processing tab renamed Sensitivity
- Defaults: classic roll 0.750, mouse pitch/X 0.200 (slider shows 1), gravity 1500
- Mouse / full-stick sliders remapped so 1 = the default
- Throttle sliders show /10 (400 instead of 4000)
- Vertical / Reverse throttle renamed Up / Down Throttle
- Horizontal throttle slider max 1000 (display)
- Full-stick slider max 10
- Centre crosshair size max 20
- Throttle and speed bar width max 300
- Save keys renamed to match labels

Fixed
- Mouse Y useful invert is in code; Invert Mouse Y box stays off by default

Removed
- Compatibility with 1.1.0 saved configs (keys renamed)

## 1.1.0

Added
- Classic drone mode and hover / stabilize options
- Speed bar plus rotatable HUD bars
- Stick zone / stick display OSD
- Speed FOV, optional OSD wobble, camera smoothness
- Keyboard + mouse binds with reset
- Surface friction and hitbox toggle
- Save All / Reset / Reset Defaults

Changed
- Rate sliders renamed to Overall Sensitivity, Full-Stick Speed, Center Softness
- Pitch offset split: FPV default 30, Classic default 0
- Reverse throttle defaults and down-throttle off by default

Fixed
- Camera smoothness no longer slowing flight
- OSD staying locked when wobble is off
- Rate settings saving under the slider names
- D-Pad save / respawn firing once per press

Removed
- Controller Y OSD toggle (checkbox + optional keyboard bind only)

## 1.0.0

- First public FPV+ drop (acro, throttle bar, centre crosshair, basic settings)
