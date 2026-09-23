# Changelog

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
