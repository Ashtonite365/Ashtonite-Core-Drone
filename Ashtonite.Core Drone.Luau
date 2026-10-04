-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (c) 2026 Ashtonite (Ashtonite365)
-- @name Ashtonite.Core Drone
-- @version 2.0.0
-- @credits Inspired by Scha's Drone Camera (Schafreu); developed with AI assistance (Grok Bot agents)
-- @author Ashtonite365
-- Unofficial community spectator camera script for Orion Drift.
-- Licence: GNU GPL v3 only, with the additional terms in NOTICE (keep the author attribution, mark
--   modified versions). See LICENSE and NOTICE. This program comes with ABSOLUTELY NO WARRANTY.
-- Credits: 2.0.0 is an independent clean-room rewrite from a behaviour spec. Earlier versions (in
--   archive/, not covered by this licence) were built on "Scha's Drone Camera" by Schafreu, itself based
--   on Another Axiom's default drone camera. This version is not derived from the code of either script.
-- This product is not affiliated with Another Axiom Inc. or its videogames Gorilla Tag and Orion Drift and is not endorsed or otherwise sponsored by Another Axiom. Portions of the materials contained herein are property of Another Axiom. ©2025 Another Axiom Inc.
--!nonstrict
-- (nonstrict only because strict mode rejects the host global `metadata`; tools/check.sh also
-- type-checks the rest of the file in strict mode.)

metadata = {
	name = "Ashtonite.Core Drone",
	description = "Acro and Classic FPV drone camera for Spectator (2.0.0)",
	author = "Ashtonite365",
	defaultKeybind = "",
}

-- NOTE on frame rate: drag, contact friction, the collision damping, the self-levelling cap and the
-- mouse response are applied per tick (not per second) on purpose, so the drone feels exactly like
-- earlier versions at the same frame rate.

local BUILD_TAG = "build 2026-10-04d (v2.0.0)" -- shown read-only next to the top buttons, to identify installed builds
local V, Q = Vec3.new, Quat.fromEuler
local abs, max, min, exp, clamp = math.abs, math.max, math.min, math.exp, math.clamp
local sin, cos, rad, sign = math.sin, math.cos, math.rad, math.sign
local ZERO = V(0, 0, 0)

---------------------------------------------------------------------------------------------------
-- Settings. Every saved key, its default and slider range. Section codes (a key may be in several):
--   C Controls, M M&K defaults button, O On Screen Display, o also reloaded by "Reset OSD",
--   D Drone Settings, K Camera Settings, L Colours, R Rendering.
type Setting = { key: string, default: any, lo: number, hi: number, div: number, sec: string }
local SETTINGS: { Setting } = {}
local DEF: { [string]: Setting } = {}
local S: { [string]: any } = {} -- live values

local function settings(sec: string, rows: { { any } }, prefix: string?, suffix: string?)
	for _, r in rows do
		local s: Setting = {
			key = (prefix or "") .. r[1] .. (suffix or ""),
			default = r[2], lo = r[3] or 0, hi = r[4] or 1, div = r[5] or 1, sec = sec,
		}
		table.insert(SETTINGS, s)
		DEF[s.key] = s
	end
end

settings("C", {
	{ "classicDrone", false }, { "autoStabilization", false }, { "autoStabilizationStrength", 10, 0, 30 },
	{ "useKeyboardMouse", false }, { "allowDownThrottle", false }, { "invertPitch", false }, { "invertYaw", false },
	{ "invertRoll", false }, { "invertThrottle", false }, { "swapLeftRightStickControls", false },
	{ "swapTriggers", false }, { "swapLeftStickYAndTriggers", false }, { "invertClassicRoll", false },
	{ "swapBumpersAndTriggers", false }, { "rollSensitivity", 0.75, 0.1, 2.5 },
})
settings("CM", {
	{ "invertMouseX", false }, { "invertMouseY", false }, { "mousePitchSensitivity", 0.2, 0, 0.6, 0.2 },
	{ "mouseXSensitivity", 0.2, 0, 0.6, 0.2 }, { "keyboardYawSensitivity", 0.6, 0.01, 1 },
	{ "throttleUpKey", "W" }, { "throttleDownKey", "S" }, { "yawLeftKey", "A" }, { "yawRightKey", "D" },
	{ "moveForwardKey", "W" }, { "moveBackKey", "S" }, { "moveLeftKey", "A" }, { "moveRightKey", "D" },
	{ "upKey", "SpaceBar" }, { "downKey", "LeftControl" }, { "savePositionKey", "" }, { "respawnDroneKey", "" },
	{ "tempDisableHitboxKey", "" }, { "tempStabilizationKey", "" }, { "toggleAllOsdKey", "" },
})
settings("CO", { { "toggleAllOsd", true } })
settings("O", {
	{ "showCentreCrosshair", true }, { "crosshairHorizontalSize", 6, 1, 20 }, { "crosshairVerticalSize", 3.3, 1, 20 },
	{ "crosshairThickness", 1.35, 0.5, 4 }, { "crosshairRotation", 0, 0, 45 },
	{ "showThrottleBar", true }, { "showSpeedBar", true }, { "topSpeed", 7500, 200, 15000 },
})
for prefix, vOffset in ({ throttleBar = 80, speedBar = 71 } :: { [string]: number }) do
	settings("O", {
		{ "Width", 122, 40, 300 }, { "Height", 6.2, 2, 12 }, { "HorizontalOffset", 0, -150, 150 },
		{ "VerticalOffset", vOffset, -80, 80 }, { "OutlineThickness", 2, 0.5, 2 }, { "Rotation", 0, -180, 180 },
	}, prefix)
end
for _, side in { "L", "R" } do
	settings("O", {
		{ "showZone", true }, { "showStickDisplay", true }, { "showStickCrosshair", true }, { "showStickLine", true },
		{ "stickSize", 1, 0.5, 2 }, { "stickHorizontalOffset", 105, 0, 160 }, { "stickVerticalOffset", 52, -90, 90 },
		{ "zoneQuality", 18, 4, 50 }, { "zoneThickness", 1.8, 0.5, 4 }, { "zoneRotation", 0, 0, 45 },
		{ "stickDisplayQuality", 14, 4, 50 }, { "stickDisplayThickness", 1.5, 0.5, 4 }, { "stickDisplayRotation", 0, 0, 45 },
		{ "stickCrosshairHorizontalSize", 4, 1, 15 }, { "stickCrosshairVerticalSize", 4, 1, 15 },
		{ "stickCrosshairThickness", 1.3, 0.5, 4 }, { "stickCrosshairRotation", 0, 0, 45 },
		{ "stickLineThickness", 1.4, 0.5, 4 },
	}, nil, side)
	for _, item in { "zoneColour", "stickDisplayColour", "stickCrosshairColour", "stickLineColour" } do
		settings("Lo", { { "_R", 1 }, { "_G", 1 }, { "_B", 1 } }, item .. side)
	end
end
for item, rgb in ({ centreCrosshair = { 1, 1, 1 }, throttleBarOutline = { 1, 1, 1 }, throttleBarFill = { 0.4, 0.7, 1 },
	speedBarOutline = { 1, 1, 1 }, speedBarFill = { 0.45, 1, 0.45 } } :: { [string]: { number } }) do
	settings("L", { { "_R", rgb[1] }, { "_G", rgb[2] }, { "_B", rgb[3] } }, item)
end
settings("D", {
	{ "overallSensitivity", 1.2, 0, 2.5 }, { "fullStickSpeed", 0.15, 0, 1.5, 0.15 }, { "centerSoftness", 0.07, 0, 0.2 },
	{ "upThrottle", 4000, 0, 10000, 10 }, { "downThrottle", 3000, 0, 10000, 10 }, { "horizontalThrottle", 1500, 0, 10000, 10 },
	{ "gravity", 1500, 0, 3000 }, { "fallAcceleration", 0.5, 0, 1 }, { "surfaceFriction", 0.2, 0, 1 },
	{ "droneCollisionWidth", 9, 0, 100 }, { "droneCollisionLength", 9, 0, 100 }, { "droneCollisionHeight", 4, 0, 100 },
	{ "droneHitbox", true }, { "grandEffect", true },
	{ "gravityAssist", true }, { "gravityAssistStrength", 1, 0, 1 }, { "gravityAssistPerfect", false }, -- Classic only
})
settings("K", {
	{ "viewAngleUp", 30, 0, 90 }, { "viewAngleUpClassic", 0, 0, 90 }, { "fieldOfView", 105, 0, 150 },
	{ "speedFov", false }, { "osdWobble", false }, { "cameraSmoothness", false }, { "smoothness", 0.12, 0.01, 0.5 },
})
settings("KR", { { "showNameTags", true } })
settings("R", { { "hideNearestHead", false }, { "placeBallHereVisuals", true }, { "scrapRunSpinners", true }, { "goalExplosions", false } })
-- rotationSmoothness keeps its live value inside `config` itself, so it is in DEF (for the slider) but
-- not in SETTINGS (the generic load/save/default loops); the section helpers treat it separately.
DEF.rotationSmoothness = { key = "rotationSmoothness", default = 0.12, lo = 0.01, hi = 0.5, div = 1, sec = "" }

local function inSection(s: Setting, code: string?): boolean
	return code == nil or string.find(s.sec, code) ~= nil
end

local function loadSection(code: string?) -- code may be a pattern such as "[Oo]"; nil = everything
	for _, s in SETTINGS do
		if inSection(s, code) then
			local v = config[s.key]
			if v == nil then v = s.default end
			S[s.key] = v
		end
	end
	if code == nil or code == "K" then
		S.smoothness = clamp(S.smoothness, 0.01, 0.5)
		config.rotationSmoothness = clamp(config.rotationSmoothness or 0.12, 0.01, 0.5)
	end
end

local function saveSection(code: string?)
	for _, s in SETTINGS do
		if inSection(s, code) then config[s.key] = S[s.key] end
	end
	if (code == nil or code == "K") and config.rotationSmoothness == nil then config.rotationSmoothness = 0.12 end
end

local function defaultSection(code: string?)
	for _, s in SETTINGS do
		if inSection(s, code) then S[s.key] = s.default end
	end
	if code == nil or code == "K" then config.rotationSmoothness = 0.12 end
end

local function copyOf(t: any): { [any]: any }
	local c = {}
	for k, v in pairs(t) do c[k] = v end
	return c
end

loadSection(nil)

---------------------------------------------------------------------------------------------------
-- Race gates. Ray hits inside these boxes are ignored so the drone can fly through the gates.
-- Axis-aligned gates, 4 numbers each: x, y, z of the corner, facing (1 -Y, 2 +Y, 3 +X, 4 -X).
local GATES_AXIS = {
	-521.518, 7628.015, -29632.256, 2,      -2153.015, 18027.914, -29630.484, 4,
	2153.015, 19071.021, -29630.484, 3,     -2228.015, 26579.072, -29833.324, 4,
	2230.015, 27620.953, -29833.324, 3,     -521.190, 24978.014, -28037.043, 2,
	419.163, 27221.986, -31508.912, 1,
}
-- Per facing: x from/to, y from/to (offsets from the corner), then the home box's x/y shift.
local FACINGS = {
	{ -252, 0, -30, 0, -800, 0 }, { 0, 252, 0, 30, 800, 0 }, { 0, 30, -252, 0, 0, -800 }, { -30, 0, 0, 252, 0, 800 },
}
-- Driftplex gates, 6 numbers each: origin x, y, z, then roll, pitch, yaw in degrees.
local GATES_TILTED = {
	14678.619, 26927.014, -26464.400, 0, 30, 0,      14759.829, 22679.189, -26418.803, 30, 0, 90,
	15497.991, 23717.449, -25989.279, -30, 0, -90,   14758.665, 13079.364, -26416.787, 30, 0, 90,
	15499.341, 14118.737, -25991.615, -30, 0, -90,   14759.743, 5879.726, -26418.654, 30, 0, 90,
	15499.302, 6921.189, -25991.549, -30, 0, -90,
}
local boxes: { number } = {} -- flat: minX, maxX, minY, maxY, minZ, maxZ per box (away and home boxes)
for i = 1, #GATES_AXIS, 4 do
	local x, y, z, f = GATES_AXIS[i], GATES_AXIS[i + 1], GATES_AXIS[i + 2], FACINGS[GATES_AXIS[i + 3]]
	for home = 0, 1 do
		local sx, sy = x + f[5] * home, y + f[6] * home
		for _, n in { sx + f[1], sx + f[2], sy + f[3], sy + f[4], z, z + 165 } do table.insert(boxes, n) end
	end
end
local tilted: { { o: Vec3, inv: Quat } } = {}
for i = 1, #GATES_TILTED, 6 do
	local g = table.pack(table.unpack(GATES_TILTED, i, i + 5))
	table.insert(tilted, { o = V(g[1], g[2], g[3]), inv = Q(g[4], g[5], g[6]):inverse() })
end

local function inGate(p: Vec3): boolean
	local x, y, z = p.x, p.y, p.z
	for i = 1, #boxes, 6 do
		if x >= boxes[i] and x <= boxes[i + 1] and y >= boxes[i + 2] and y <= boxes[i + 3]
			and z >= boxes[i + 4] and z <= boxes[i + 5] then
			return true
		end
	end
	for _, g in tilted do
		local q = g.inv:rotateVector(p - g.o)
		if q.y >= 0 and q.y <= 30 and q.z >= 0 and q.z <= 165
			and ((q.x >= 0 and q.x <= 252) or (q.x >= 800 and q.x <= 1052)) then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------------------------------------
-- Input. Two separate key tables that never cross: keyboard/mouse names (binds, Escape, LeftAlt,
-- mouse buttons) come from Input.Key; gamepad names (sticks, triggers, shoulders, D-pad) come from
-- Input.Gamepad. A name missing from its table reads as 0 / not held.
local KEYBOARD: { [string]: any } = Input.Key :: any
local GAMEPAD: { [string]: any } = (Input :: any).Gamepad or {}
if GAMEPAD.LeftX == nil then warn("Core Drone: Input.Gamepad is unavailable, so controller input will read as zero.") end
local engineKeyDown = (Input :: any).getKeyDown
local keyPressedNow = engineKeyDown or Input.getKey
local mouseDelta = (Input :: any).getMouseDelta
local keyWasHeld: { [string]: boolean } = {}
local padWasHeld: { [string]: boolean } = {}
local padWasTapped: { [string]: boolean } = {}

local function truthy(v: any): boolean
	return v ~= nil and v ~= false and v ~= 0
end
local function rising(memory: { [string]: boolean }, name: string, now: boolean): boolean -- own edge memory
	local before = memory[name]
	memory[name] = now
	return now and not before
end
-- Keyboard / mouse (Input.Key). "" (unbound) never holds.
local function keyHeld(name: string): boolean
	local k = name ~= "" and KEYBOARD[name]
	return k and truthy(Input.getKey(k)) or false
end
local function keyPressed(name: string): boolean -- engine's "this frame" query
	local k = name ~= "" and KEYBOARD[name]
	return k and truthy(keyPressedNow(k)) or false
end
local function keyEdge(name: string): boolean
	return rising(keyWasHeld, name, keyHeld(name))
end
local function keyAxis(posKey: string, negKey: string): number -- bound keyboard keys, by config key
	return (keyHeld(S[posKey]) and 1 or 0) - (keyHeld(S[negKey]) and 1 or 0)
end
-- Gamepad (Input.Gamepad).
local function padAxis(name: string): number
	local k = GAMEPAD[name]
	return k and Input.getAnalog(k) or 0
end
local function padHeld(name: string): boolean
	local k = GAMEPAD[name]
	return k and truthy(Input.getKey(k)) or false
end
local function padEdge(name: string): boolean -- checked every tick
	-- A press = the engine's "pressed this frame" (catches a tap that goes down and up between two ticks), or
	-- the held state turning on when that press wasn't already counted as a tap on the tick before.
	local k = GAMEPAD[name]
	local held = padHeld(name)
	local tapped = k ~= nil and engineKeyDown ~= nil and truthy(engineKeyDown(k))
	local press = tapped or (held and not padWasHeld[name] and not padWasTapped[name])
	padWasHeld[name], padWasTapped[name] = held, tapped
	return press
end
local function bumperRoll(): number
	return (padHeld("RightShoulder") and 1 or 0) - (padHeld("LeftShoulder") and 1 or 0)
end
local function trigger(side: string): number -- digital-or-analog trigger name first, then the *Axis one
	local v = padAxis(side .. "Trigger")
	return if v == 0 then padAxis(side .. "TriggerAxis") else v
end
local function mouseAxes(): (number, number) -- per-frame delta, no dt scaling (see note at top)
	if not mouseDelta then return 0, 0 end
	local d = mouseDelta()
	local x = if S.invertMouseX then -d.x else d.x
	local y = if S.invertMouseY then -d.y else d.y
	return clamp(x * S.mouseXSensitivity, -1, 1), clamp(-y * S.mousePitchSensitivity, -1, 1)
end

---------------------------------------------------------------------------------------------------
-- Flight state
local LOAD_SPAWN, RESPAWN_FALLBACK = V(209, 2500, -28225), V(209, 2450, -28225) -- fallback is 50 cm lower
local function savedPosition(): Vec3?
	local p = config.position
	if type(p) == "table" then return V(p.x or p.X or 0, p.y or p.Y or 0, p.z or p.Z or 0) end
	return p
end
local spawnPoint = savedPosition() or LOAD_SPAWN
local pos, vel, rot = spawnPoint, ZERO, Q(0, 0, 90)
local camPos, camRot: Quat? = spawnPoint, nil -- smoothed camera state (rotation stays local, not in config)
local lastFree: Vec3? = nil
local fov, hudFov, throttleShown = 105, 105, 0
local sticks = { 0, 0, 0, 0 } -- lx, ly, rx, ry for the OSD, stick up / right = positive (raw, like LeftY)
local started, snapshot = false, nil :: { [any]: any }?
local probeWas = false

-- Returns yaw, throttle, roll, pitch commands and the Classic strafe / forward axes.
local function readControls(): (number, number, number, number, number, number)
	local classic, kbm = S.classicDrone, S.useKeyboardMouse
	local lx, ly, rx, ry, vertical, rollSource = 0, 0, 0, 0, 0, 0
	if kbm then
		rx, ry = mouseAxes()
		if classic then
			lx, ly = keyAxis("moveRightKey", "moveLeftKey"), keyAxis("moveForwardKey", "moveBackKey")
			vertical, rollSource = keyAxis("upKey", "downKey"), bumperRoll()
		else
			lx, ly = S.keyboardYawSensitivity * keyAxis("yawRightKey", "yawLeftKey"), keyAxis("throttleUpKey", "throttleDownKey")
		end
	else
		lx, ly, rx, ry = padAxis("LeftX"), padAxis("LeftY"), padAxis("RightX"), padAxis("RightY")
		if classic then
			local rt, lt = trigger("Right"), trigger("Left")
			if S.swapTriggers then rt, lt = lt, rt end
			local trig, bump = clamp(rt, 0, 1) - clamp(lt, 0, 1), bumperRoll()
			if S.swapBumpersAndTriggers then vertical, rollSource = bump, trig else vertical, rollSource = trig, bump end
		end
	end
	-- OSD values: where the thumb or mouse went, before any invert option (flight uses lx..ry below as they are).
	local showX, showY = rx, ry
	if kbm then showX, showY = if S.invertMouseX then -rx else rx, if S.invertMouseY then -ry else ry end
	sticks[1], sticks[2], sticks[3], sticks[4] = lx, ly, showX, showY
	local yaw, throttle, roll, pitch, moveX, moveY
	if classic then
		moveX, moveY = lx, ly
		if not kbm and S.swapLeftStickYAndTriggers then moveY, vertical = vertical, ly end
		yaw, pitch, throttle, roll = rx, ry, vertical, rollSource * S.rollSensitivity
		if S.invertRoll then moveX = -moveX end -- "Invert Strafe" in Classic
		if S.invertClassicRoll then roll = -roll end
	else
		moveX, moveY = 0, 0
		if S.swapLeftRightStickControls then
			yaw, throttle, roll, pitch = rx, ry, lx, ly
		else
			yaw, throttle, roll, pitch = lx, ly, rx, ry
		end
		if S.invertRoll then roll = -roll end
	end
	if S.invertYaw then yaw = -yaw end
	if S.invertPitch then pitch = -pitch end
	if S.invertThrottle then throttle = -throttle end
	return yaw, throttle, roll, pitch, moveX, moveY
end

-- Rate curve: degrees to turn this tick for a stick value. The curve's 200 units/s scale has always
-- been converted with pi/180 and then handed to the engine as degrees, so full rate is ~209.44 deg/s
-- times shape x boost x sensitivity (~296 deg/s at defaults). Kept as-is for the same feel.
local TURN_SCALE = 200 * math.pi / 180 * 60
local function turnDegrees(v: number, dt: number): number
	local a, soft = abs(v), S.centerSoftness
	local shaped = soft * a ^ 4 + (1 - soft) * a
	local boost = 1 / max(1 - a * S.fullStickSpeed, 0.05)
	return sign(v) * shaped * boost * S.overallSensitivity * TURN_SCALE * dt
end

local function selfLevel(up: Vec3, strength: number, dt: number)
	local f, r, u = rot:getForwardVector(), rot:getRightVector(), rot:getUpVector()
	local axis = u:cross(up)
	if axis:length() < 0.0008 and u:dot(up) < 0 then axis = f end -- upside down: pick a roll axis
	local gain = strength * 8.5 * dt
	local rollFix = clamp(-axis:dot(f) * gain, -0.45, 0.45) -- per-tick cap
	local pitchFix = clamp(-axis:dot(r) * gain, -0.45, 0.45)
	if abs(rollFix) > 0.0002 or abs(pitchFix) > 0.0002 then rot = rot * Q(rollFix, pitchFix, 0) end
end

local function flatten(v: Vec3, up: Vec3): (Vec3, number) -- component perpendicular to up, and its length
	local p = v - up * v:dot(up)
	return p, p:length()
end

-- Classic hands-off fall (neutral vertical throttle, moving down, part of the weight unassisted). Gravity stays the
-- weight that thrust and Gravity Assist work against; while falling hands-off, idle rotor lift carries part of it,
-- so the drone speeds up at Fall Acceleration x the unassisted weight. Air drag on that fall is quadratic and
-- dt-correct (same fall at any frame rate): 1/12000 per cm gives 30 m/s terminal at the default 750 cm/s^2.
-- The hover brake on downward speed fades out as that fall acceleration grows and is gone from 375 cm/s^2, so
-- strength 1 (nothing unassisted) keeps the original brake exactly. Fall Acceleration 0 = idle lift carries it all.
-- Acro uses the same fall (world-vertical, attitude does not matter) whenever there is no thrust. Inside the idle
-- band (|throttle| under 0.1, i.e. under 1% of full thrust) the fall blends in by (1 - |t| / 0.1)^2, so touching
-- the throttle has no velocity jump; from 0.1 up the old Acro model runs unchanged.
local FALL_DRAG, BRAKE_GONE_AT, ACRO_IDLE_BAND = 1 / 12000, 375, 0.1

-- Returns true when this tick was a hands-off fall, whose vertical speed then skips the per-tick drag.
local function classicThrust(up: Vec3, up0: Vec3, vertical: number, moveX: number, moveY: number, dt: number): boolean
	local fwd, fl = flatten(rot:getForwardVector(), up)
	if fl < 0.0001 then
		local u, ul = flatten(rot:getUpVector(), up)
		fwd = if ul < 0.0001 then ZERO else u / ul
	else
		fwd = fwd / fl
	end
	local right, rl = flatten(rot:getRightVector(), up)
	right = if rl < 0.0001 then rot:getRightVector() else right / rl

	local t = clamp(vertical, -1, 1)
	throttleShown = t
	-- Gravity Assist is the only gravity compensation in Classic; off = none (the drone sinks at neutral).
	-- Normal: push along the drone's up axis (before this tick's rotation) while it is within ~78 deg of
	-- upright, so a tilted drone leans and drifts. Perfect: push straight up in world space, with no
	-- cutoff and no drift. Both are gravity x strength, dt-scaled like gravity.
	local held = 0 -- share of the weight the assist holds up (its vertical part)
	if S.gravityAssist then
		local push = S.gravity * S.gravityAssistStrength * dt
		if S.gravityAssistPerfect then
			vel += up * push
			held = S.gravityAssistStrength
		elseif up0:dot(up) > 0.2 then
			vel += up0 * push
			held = S.gravityAssistStrength * up0:dot(up)
		end
	end
	local handsOffFall = false
	if abs(t) < 0.04 then
		local unheld = S.gravity * (1 - held) -- weight nothing holds up, cm/s^2
		local fall = S.fallAcceleration * unheld
		local vz = vel:dot(up)
		if unheld > 0 and vz < 0 then
			vz += (unheld - fall) * dt -- idle lift: only Fall Acceleration x the unheld weight is felt
			local d = max(-vz, 0) * exp(-3.2 * max(1 - fall / BRAKE_GONE_AT, 0) ^ 2 * dt) -- fading hover brake
			d = d / (1 + FALL_DRAG * d * dt) -- quadratic air drag, exact for this step
			vel -= up * (vel:dot(up) + d)
			handsOffFall = true
		else
			vel -= up * (vz * (1 - exp(-3.2 * dt)))
		end
	else
		vel += up * (t * 0.5 * (if t < 0 then S.downThrottle else S.upThrottle) * dt)
	end
	local mx, my = clamp(moveX, -1, 1), clamp(moveY, -1, 1)
	if abs(mx) < 0.04 and abs(my) < 0.04 then
		vel -= flatten(vel, up) * (1 - exp(-1.35 * dt))
	else
		vel += (fwd * my + right * mx) * (S.horizontalThrottle * dt)
	end
	return handsOffFall
end

-- Returns how idle the throttle is: 1 = no thrust (centre, or below centre without Allow Down Throttle) down to
-- 0 at the edge of the idle band and beyond.
local function acroThrust(up0: Vec3, throttle: number, dt: number): number
	local t = clamp(throttle, -1, 1)
	if t < 0 and not S.allowDownThrottle then t = 0 end
	throttleShown = t
	local response = sign(t) * t * t -- squared, keeps the sign
	local accel = response * (if t < 0 then S.downThrottle else S.upThrottle)
	-- "GrandEffect": earlier versions added at most 1 cm/s^2 x t^2 here (thrust is thousands of
	-- cm/s^2), which nobody can feel. Kept at that same negligible size so the setting still exists.
	if S.grandEffect then accel += response end
	vel += up0 * (accel * dt)
	return if abs(t) < ACRO_IDLE_BAND then (1 - abs(t) / ACRO_IDLE_BAND) ^ 2 else 0
end

---------------------------------------------------------------------------------------------------
-- Collision
local CORNERS = { 1, 1, 1, 1, 1, -1, 1, -1, 1, 1, -1, -1, -1, 1, 1, -1, 1, -1, -1, -1, 1, -1, -1, -1 }

local function ray(from: Vec3, to: Vec3): RayHit?
	local h = camera:castRay(from, to)
	if h and h.successful and not inGate(h.position) then return h end
	return nil
end

local function outward(h: RayHit): Vec3 -- normal flipped to face the last free position
	local n, free = h.normal, lastFree
	if free and (free - h.position):dot(n) < 0 then return -n end
	return n
end

-- Moves the drone for this tick and returns the resolved position. rotBefore = orientation before
-- this tick's rotation. Updates vel and lastFree.
local function resolveMove(up: Vec3, rotBefore: Quat, collide: boolean, dt: number): Vec3
	local start, touching = pos, false
	local W, L, H = S.droneCollisionWidth, S.droneCollisionLength, S.droneCollisionHeight
	local function bounciness(n: Vec3): number
		return if n:dot(up) > 0.55 then 1.05 else 1.35 -- floors bounce less than walls
	end
	local function stopInto(n: Vec3, k: number)
		local into = vel:dot(n)
		if into < 0 then vel -= n * (into * k) end
		touching = true
	end
	local offsets: { Vec3 } = {}
	if collide then
		for i = 1, #CORNERS, 3 do table.insert(offsets, V(CORNERS[i] * W, CORNERS[i + 1] * L, CORNERS[i + 2] * H)) end
	end

	-- Stage 1: corner probes reshape the velocity.
	local speed = vel:length()
	if collide and speed > 0.0001 then
		local dir = vel / speed
		local fwd, right, upAxis = rot:getForwardVector(), rot:getRightVector(), rot:getUpVector()
		local total, hits = ZERO, 0
		for _, o in offsets do
			local now = rot:rotateVector(o)
			local spin = now - rotBefore:rotateVector(o)
			local corner = start + now
			local n: Vec3?, push = nil, ZERO
			local near = ray(corner - dir * 2, corner)
			if near then
				n = outward(near)
			else
				local far = ray(corner - (dir - spin) * 100, corner)
				if far then
					local d = far.position - start
					if abs(d:dot(right)) <= 2.1 * W and abs(d:dot(upAxis)) <= 2.1 * H and abs(d:dot(fwd)) <= 2.1 * L then
						local fn = outward(far)
						local kick = corner:distance(far.position)
						if fn:dot(up) > 0.55 then kick *= 0.12 end
						n, push = fn, fn * kick
					end
				end
			end
			if n then
				total = (total + (vel - n * (bounciness(n) * vel:dot(n))) + push - spin) * 0.98
				hits += 1
				touching = true
			end
		end
		if hits > 0 then vel = total / hits end
	end

	-- Stage 2: sweep from the last free position and push out of geometry.
	local free = lastFree or start
	lastFree = free
	local target = start + vel * dt
	if collide then
		if (free - start):length() > 1 then
			local h = ray(free, start)
			if h then
				local n = outward(h)
				start = h.position + n * 8
				pos = start
				stopInto(n, bounciness(n))
				target = start + vel * dt
			end
		end
		local h = ray(free, target)
		if h then
			local n = outward(h)
			target = h.position + n * 8
			stopInto(n, bounciness(n))
		end
		for _, o in offsets do
			local corner = target + rot:rotateVector(o)
			local hc = ray(free, corner)
			if hc then
				local n = outward(hc)
				local depth = (hc.position + n * 8 - corner):dot(n)
				if depth > 0 then
					target += n * depth
					stopInto(n, bounciness(n))
				end
			end
		end
		local clearance = H + 2 + abs(rot:getForwardVector():dot(up)) * L + abs(rot:getRightVector():dot(up)) * W
		local floor = ray(target, target - up * max(clearance + H, 8))
		if floor and target:distance(floor.position) < clearance then
			target = floor.position + floor.normal * clearance
			stopInto(floor.normal, 1)
		end
		if not touching then lastFree = target end
	else
		lastFree = target
	end
	if touching then vel *= 1 / (1 + max(S.surfaceFriction, 0) * 0.8) end -- per-tick contact friction
	return target
end

---------------------------------------------------------------------------------------------------
-- Field of view and camera output
local function easeFactor(rate: number, dt: number): number
	return 1 - exp(-rate * dt)
end

local function updateFov(dt: number)
	local base, target = S.fieldOfView, S.fieldOfView
	if S.speedFov then
		-- Ramps toward 132 deg (the real cap; a base FOV above 132 is held at 132).
		local ramp = clamp((vel:length() - 400) / 3800, 0, 1) ^ 1.45
		target = clamp(base + (132 - base) * ramp, min(base, 132), 132)
	end
	local step = max(dt or 0.016, 0.0001)
	fov += (target - fov) * easeFactor(7, step)
	if S.speedFov and S.osdWobble then
		local slowing = target < fov or fov < hudFov
		hudFov += (fov - hudFov) * easeFactor(if slowing then 6.8 else 3.2, step)
	else
		hudFov = camera:getSmoothedFieldOfView() or camera.fieldOfView or fov
	end
	camera.fieldOfView = fov
	camera.fieldOfViewSmoothing = 0
end

local function placeCamera(at: Vec3, dt: number)
	local tilt = if S.classicDrone then S.viewAngleUpClassic else S.viewAngleUp
	local aim = rot * Q(0, tilt, 0)
	if S.cameraSmoothness then
		local step = max(dt, 0.0001)
		local function halfLifeBlend(h: number): number
			return easeFactor(math.log(2) / max(0.28 * h, 0.002), step)
		end
		camPos += (at - camPos) * halfLifeBlend(S.smoothness)
		aim = Quat.slerp(camRot or aim, aim, halfLifeBlend(config.rotationSmoothness or 0.12))
	else
		camPos = at
	end
	camRot = aim
	camera.position = camPos
	camera.rotation = aim
end

local function flightStep(dt: number)
	local up = gravity.upDirection
	local rotBefore = rot
	local up0 = rot:getUpVector()
	local collide = S.droneHitbox and not (padHeld("DPad_Down") or keyHeld(S.tempDisableHitboxKey))
	local yaw, throttle, roll, pitch, moveX, moveY = readControls()

	rot = rot * Q(turnDegrees(roll, dt), turnDegrees(pitch, dt), turnDegrees(yaw, dt))
	local boostLevel = padHeld("DPad_Left") or keyHeld(S.tempStabilizationKey)
	if S.classicDrone and (S.autoStabilization or boostLevel) then
		selfLevel(up, if boostLevel then 30 else S.autoStabilizationStrength, dt)
	end

	vel -= up * (S.gravity * dt)
	local handsOffFall, idle = false, 0
	if S.classicDrone then handsOffFall = classicThrust(up, up0, throttle, moveX, moveY, dt) else idle = acroThrust(up0, throttle, dt) end
	local vz = vel:dot(up)
	if handsOffFall then -- Classic: its vertical drag was dt-correct above; the rest gets the usual per-tick drag
		vel = (vel - up * vz) * 0.993 + up * vz
	elseif idle > 0 and S.gravity > 0 and vz < 0 then
		-- Acro hands-off fall: idle lift leaves Fall Acceleration x Gravity, then the dt-correct quadratic drag,
		-- blended with the old per-tick drag by how idle the throttle is. Horizontal keeps the per-tick drag.
		local d = max(-(vz + (1 - S.fallAcceleration) * S.gravity * dt), 0)
		d = d / (1 + FALL_DRAG * d * dt)
		vel = (vel - up * vz) * 0.993 + up * (vz * 0.993 * (1 - idle) - d * idle)
	else
		vel *= 0.993 -- per-tick air drag
	end

	local resolved = resolveMove(up, rotBefore, collide, dt)
	updateFov(dt)
	placeCamera(resolved, dt)
	pos = resolved
end

---------------------------------------------------------------------------------------------------
-- On screen display: world-space lines 10 cm in front of the camera, designed at 105 deg FOV.
local HUD_DEPTH, DESIGN_TAN = 10, math.tan(rad(52.5))
local hudOrigin, hudF, hudR, hudU, hudScale = ZERO, ZERO, ZERO, ZERO, 1
local rgbKeys: { [string]: { string } } = {}

local function colourOf(item: string): (number, number, number)
	local k = rgbKeys[item]
	if not k then
		k = { item .. "_R", item .. "_G", item .. "_B" }
		rgbKeys[item] = k
	end
	return S[k[1]], S[k[2]], S[k[3]]
end

local function keyset(prefix: string, suffix: string): { [string]: string } -- memoised key names
	return setmetatable({}, { __index = function(t: any, name: string)
		local full = prefix .. name .. suffix
		t[name] = full
		return full
	end }) :: any
end
local BAR_KEYS = { keyset("throttleBar", ""), keyset("speedBar", "") }
local STICK_KEYS = { keyset("", "L"), keyset("", "R") }

-- HUD units: x right, y down. depth lets a line sit behind others at the same screen spot.
local function hudLine(x1: number, y1: number, x2: number, y2: number, width: number,
	r: number, g: number, b: number, depth: number?)
	local d = depth or HUD_DEPTH
	local k = hudScale * d / HUD_DEPTH
	local base = hudOrigin + hudF * d
	WorldDraw.drawLine(base + hudR * (x1 * k) - hudU * (y1 * k), base + hudR * (x2 * k) - hudU * (y2 * k),
		r, g, b, width * hudScale, 0.05)
end

local function crosshair(cx: number, cy: number, halfW: number, halfH: number, width: number, degrees: number,
	r: number, g: number, b: number)
	local c, s = cos(rad(degrees)), sin(rad(degrees)) -- positive = clockwise on screen
	hudLine(cx - halfW * c, cy - halfW * s, cx + halfW * c, cy + halfW * s, width, r, g, b)
	hudLine(cx + halfH * s, cy - halfH * c, cx - halfH * s, cy + halfH * c, width, r, g, b)
end

local function ring(cx: number, cy: number, radius: number, segments: number, width: number, degrees: number,
	r: number, g: number, b: number)
	local n = max(math.round(segments), 3)
	local rr = max(radius - width / 2, 0.05)
	local px, py
	for i = 0, n do -- anticlockwise on screen, starting at screen-right
		local a = 2 * math.pi * i / n + rad(degrees)
		local x, y = cx + rr * cos(a), cy - rr * sin(a)
		if px then hudLine(px, py, x, y, width, r, g, b) end
		px, py = x, y
	end
end

local function drawBar(k: { [string]: string }, amount: number)
	local w, h = S[k.Width], S[k.Height]
	local cx, cy = S[k.HorizontalOffset], S[k.VerticalOffset]
	local c, s = cos(rad(S[k.Rotation])), sin(rad(S[k.Rotation]))
	local function at(along: number, across: number): (number, number)
		return cx + along * c - across * s, cy + along * s + across * c
	end
	local r, g, b = colourOf(k.Outline)
	local corners = { -w / 2, -h / 2, w / 2, -h / 2, w / 2, h / 2, -w / 2, h / 2, -w / 2, -h / 2 }
	for i = 1, 7, 2 do
		local x1, y1 = at(corners[i], corners[i + 1])
		local x2, y2 = at(corners[i + 2], corners[i + 3])
		hudLine(x1, y1, x2, y2, S[k.OutlineThickness], r, g, b)
	end
	local fill = clamp(abs(amount), 0, 1)
	if fill <= 0.01 then return end
	local inset, spread = 1.8, h / 2 - 1.805
	local from = -w / 2 + inset
	local to = from + (w - 2 * inset) * fill
	r, g, b = colourOf(k.Fill)
	for i = 0, 5 do
		local across = -spread + 2 * spread * i / 5
		local x1, y1 = at(from, across)
		local x2, y2 = at(to, across)
		hudLine(x1, y1, x2, y2, 1.7, r, g, b)
	end
end

local function drawStick(k: { [string]: string }, side: number, x: number, y: number)
	local z = S[k.stickSize]
	local outer, inner = 28 * z, 7 * z
	local travel = max(outer - inner - 0.5 * (S[k.zoneThickness] + S[k.stickDisplayThickness]), 0)
	local bx, by = side * S[k.stickHorizontalOffset], S[k.stickVerticalOffset]
	local dx, dy = bx + x * travel, by - y * travel
	if S[k.showZone] then
		ring(bx, by, outer, S[k.zoneQuality], S[k.zoneThickness], S[k.zoneRotation], colourOf(k.zoneColour))
	end
	if S[k.showStickLine] then
		local r, g, b = colourOf(k.stickLineColour)
		hudLine(bx, by, dx, dy, S[k.stickLineThickness], r, g, b, HUD_DEPTH + 1.5 * hudScale)
	end
	if S[k.showStickDisplay] then
		ring(dx, dy, inner, S[k.stickDisplayQuality], S[k.stickDisplayThickness], S[k.stickDisplayRotation],
			colourOf(k.stickDisplayColour))
	end
	if S[k.showStickCrosshair] then
		crosshair(bx, by, S[k.stickCrosshairHorizontalSize] * z, S[k.stickCrosshairVerticalSize] * z,
			S[k.stickCrosshairThickness], S[k.stickCrosshairRotation], colourOf(k.stickCrosshairColour))
	end
end

local function drawOsd()
	if keyEdge(S.toggleAllOsdKey) then S.toggleAllOsd = not S.toggleAllOsd end
	if not S.toggleAllOsd then return end
	local view = camera.rotation
	hudOrigin, hudF, hudR, hudU = camera.position, view:getForwardVector(), view:getRightVector(), view:getUpVector()
	local shownFov = if S.speedFov and S.osdWobble then hudFov else camera:getSmoothedFieldOfView()
	hudScale = math.tan(rad(clamp(shownFov, 1, 170)) / 2) / DESIGN_TAN * (10 / 120)
	if S.showCentreCrosshair then
		crosshair(0, 0, S.crosshairHorizontalSize, S.crosshairVerticalSize, S.crosshairThickness,
			S.crosshairRotation, colourOf("centreCrosshair"))
	end
	if S.showThrottleBar then drawBar(BAR_KEYS[1], throttleShown) end
	if S.showSpeedBar then drawBar(BAR_KEYS[2], vel:length() / max(S.topSpeed, 1)) end
	drawStick(STICK_KEYS[1], -1, sticks[1], sticks[2])
	drawStick(STICK_KEYS[2], 1, sticks[3], sticks[4])
end

---------------------------------------------------------------------------------------------------
-- Tick
local function firstTick()
	started = true
	snapshot = snapshot or copyOf(config)
	fov, hudFov = S.fieldOfView, S.fieldOfView
	camera.fieldOfView = fov
	camera.fieldOfViewSmoothing = 0
	pos, camPos, lastFree = spawnPoint, spawnPoint, spawnPoint
	camera.position = spawnPoint
	camera.rotation = Q(0, 0, 90)
end

local function applyView() -- engine smoothing off (we smooth ourselves), render flags, no DOF focus
	camera.positionSmoothing = 0
	camera.rotationSmoothing = 0
	camera.fieldOfViewSmoothing = 0
	camera.showNameTags = S.showNameTags
	camera.hideNearestHead = S.hideNearestHead
	local dbg = spectatorDebug :: SpectatorDebug?
	if dbg then
		dbg.placeBallHereVisuals = S.placeBallHereVisuals
		dbg.scrapRunSpinners = S.scrapRunSpinners
		dbg.goalExplosions = S.goalExplosions
	end
	postProcessSettings.depthOfFieldFocalDistance = 0
end

local function positionKeys()
	local save = padEdge("DPad_Up")
	if keyPressed(S.savePositionKey) then save = true end
	local respawn = padEdge("DPad_Right")
	if keyPressed(S.respawnDroneKey) then respawn = true end
	if save then config.position = pos end -- in memory; written by the next Save button
	if respawn then
		local p = savedPosition() or RESPAWN_FALLBACK
		pos, camPos, lastFree, vel = p, p, p, ZERO
		camera.position = p
	end
end

function tick(dt: number)
	if not (camera.isActive or camera.isFollowed) then return end
	if not started then firstTick() end
	applyView()
	flightStep(dt)
	WorldDraw.clear()
	drawOsd()
	local probing = keyHeld("LeftAlt") and keyHeld("LeftMouseButton") -- Alt+click: log the world point once
	if probing and not probeWas then
		local hit = camera:castRayFromMouse()
		if hit and hit.successful then debug("Core Drone: mouse ray hit at " .. tostring(hit.position)) end
	end
	probeWas = probing
	positionKeys()
end

---------------------------------------------------------------------------------------------------
-- GUI
local capturing: string? = nil -- config key of the bind row waiting for a key
local picker = LinearColor.new(1, 1, 1, 1)
local BINDABLE = string.split("Zero One Two Three Four Five Six Seven Eight Nine SpaceBar LeftShift RightShift "
	.. "LeftControl RightControl LeftAlt RightAlt Tab Up Down Left Right Enter CapsLock", " ")
for c = string.byte("Z"), string.byte("A"), -1 do table.insert(BINDABLE, 1, string.char(c)) end

local TIPS = {
	classicDrone = "Triggers = up/down. Left stick = move. Right stick = turn and pitch.",
	autoStabilization = "Levels pitch and roll toward upright in Classic Drone.",
	toggleAllOsd = "Optional keyboard bind is in Keyboard & Mouse. No controller bind.",
	topSpeed = "Speed bar fills to this velocity.",
	overallSensitivity = "How fast the drone rotates for any stick movement. Higher = faster everywhere.",
	fullStickSpeed = "Extra speed only near full stick. Center stays similar; the ends get snappier.",
	centerSoftness = "Softens small stick movements for finer aim. Does not change the maximum speed.",
	upThrottle = "Up / down power. In Classic Drone this is halved.",
	horizontalThrottle = "Forward / back / left / right power used only in Classic Drone.",
	surfaceFriction = "How hard the drone slows when touching geometry",
	gravity = "The drone's weight in cm/s^2: what throttle, climbing and Gravity Assist work against (real gravity is 981).",
	fallAcceleration = "How fast a hands-off drone speeds up while falling, in every mode, as a share of Gravity: 0.5 x 1500 = 750 cm/s^2, about 3/4 of real gravity. Air drag then caps the fall near 30 m/s after a few seconds. Classic: vertical throttle centred; only the weight Gravity Assist doesn't hold counts (strength 1 hovers, 0.5 falls half as hard). Acro: no thrust (throttle centred, or below centre unless Allow Down Throttle is on); any real thrust flies exactly as before. 0 = no fall.",
	droneCollisionWidth = "xSize x2cm",
	droneCollisionLength = "ySize x2cm",
	droneCollisionHeight = "zSize x2cm",
	droneHitbox = "Turn off to fly through walls and floors",
	speedFov = "FOV ramps with flight speed only.",
	osdWobble = "When on, OSD lags/drifts with FOV. Off = OSD stays locked on screen.",
	gravityAssist = "Classic Drone only. On = an upward push that cancels gravity x strength. Off = no assist: thrust works against full gravity and a hands-off drone falls (see Fall Acceleration).",
	gravityAssistStrength = "Share of gravity the assist cancels, in normal and Perfect mode alike. 1 = hovers, 0.5 = falls at half the Fall Acceleration, 0 = no assist.",
	gravityAssistPerfect = "Push straight up in world space instead of along the drone's up axis: no tilt limit, no sideways drift. At strength 1 a hands-off drone holds still at any tilt; strength still multiplies it.",
} :: { [string]: string }

local function tip(key: string)
	local t = TIPS[key]
	if t then Gui.setItemTooltip(t) end
end
local function indent()
	Gui.text("      ")
	Gui.sameLine()
end
local function checkbox(key: string, label: string, tag: string?)
	S[key] = Gui.checkbox(label .. "##" .. key, S[key])
	tip(key)
	if tag then
		Gui.sameLine()
		Gui.text(tag)
	end
end
local function slider(key: string, label: string, tag: string?, rotButtons: boolean?, store: { [string]: any }?)
	local t, d = store or S, DEF[key]
	local shown = (t[key] or d.default) / d.div
	local picked = Gui.sliderFloat(label .. "##" .. key, shown, d.lo / d.div, d.hi / d.div)
	if picked ~= shown then t[key] = picked * d.div end
	tip(key)
	if rotButtons then
		Gui.sameLine()
		if Gui.button("90##" .. key) then t[key] = 90 end
		Gui.sameLine()
		if Gui.button("-90##" .. key) then t[key] = -90 end
	end
	Gui.sameLine()
	if Gui.button("R##" .. key) then t[key] = d.default end
	if tag then
		Gui.sameLine()
		Gui.text(tag)
	end
end
local function lines(list: { string })
	for _, s in list do Gui.text(s) end
end
local function bindRows(list: { string }) -- pairs of config key, label
	for i = 1, #list, 2 do
		local key = list[i]
		Gui.text(list[i + 1])
		Gui.sameLine()
		local shown = if capturing == key then "Press key (ESC = blank)" elseif S[key] == "" then "None" else S[key]
		if Gui.button(shown .. "##bind" .. key) then capturing = key end
		Gui.sameLine()
		if Gui.button("R##bind" .. key) then
			S[key] = DEF[key].default
			if capturing == key then capturing = nil end
		end
	end
end

-- Static GUI sections are written as short item strings, compiled once:
--   ""  blank line      "#text"  text        "^Title"  collapsing header (until the next ^)
--   "?key|Label"  checkbox     "=key|Label|tag"  slider + R     "@key|Label"  slider + 90/-90/R
--   "!colourKey|Label"  apply picker colour      a leading ">" indents the item. Leading "+"s nest it:
--   an item with n "+" shows only while the nearest checkbox above with n-1 "+" is shown and on.
-- "$X" is replaced from the vars table (used for the bar and stick templates).
type Item = { op: string, a: string, b: string, c: string?, ind: boolean, depth: number }
local function compile(src: { string }, vars: { [string]: string }?, into: { Item }?): { Item }
	local out = into or {}
	for _, line in src do
		if vars then line = (string.gsub(line, "%$(%u)", vars)) end
		local pluses = string.match(line, "^%+*") :: string
		line = string.sub(line, #pluses + 1)
		local ind = string.sub(line, 1, 1) == ">"
		if ind then line = string.sub(line, 2) end
		local parts = string.split(string.sub(line, 2), "|")
		table.insert(out, { op = string.sub(line, 1, 1), a = parts[1] or "", b = parts[2] or "", c = parts[3], ind = ind, depth = #pluses })
	end
	return out
end

local function run(items: { Item })
	local open, ticked = true, {} :: { [number]: boolean } -- ticked[d]: last depth-d checkbox shown and on
	local function setTicked(depth: number, on: boolean)
		ticked[depth] = on
		local k = depth + 1
		while ticked[k] ~= nil do -- a new parent state invalidates its old children
			ticked[k] = nil
			k += 1
		end
	end
	for _, it in items do
		local shown = it.depth == 0 or ticked[it.depth - 1] == true
		if it.op == "^" then
			open = Gui.collapsingHeader(it.a)
			table.clear(ticked)
		elseif it.op == "?" and not (open and shown) then
			setTicked(it.depth, false)
		elseif open and shown then
			if it.ind then indent() end
			local op = it.op
			if op == "" then
				Gui.newLine()
			elseif op == "#" then
				Gui.text(it.a)
			elseif op == "?" then
				checkbox(it.a, it.b, it.c)
				setTicked(it.depth, S[it.a] == true)
			elseif op == "=" or op == "@" then
				slider(it.a, it.b, it.c, op == "@")
			elseif op == "!" and Gui.button(it.b) then
				S[it.a .. "_R"], S[it.a .. "_G"], S[it.a .. "_B"] = picker.R, picker.G, picker.B
			end
		end
	end
end

local BAR_VARS = { { N = "Throttle", P = "throttleBar" }, { N = "Speed", P = "speedBar" } }
local STICK_VARS = { { N = "Left", S = "L" }, { N = "Right", S = "R" } }

local OSD_GUI = compile({
	"?toggleAllOsd|Toggle All OSD", "", "^Crosshair", "?showCentreCrosshair|Show Centre Crosshair", "",
	"=crosshairHorizontalSize|Horizontal Size", "=crosshairVerticalSize|Vertical Size",
	"=crosshairThickness|Thickness", "=crosshairRotation|Rotation",
})
for i, vars in BAR_VARS do
	compile({ "^$N Bar", "?show$NBar|Show $N Bar", "", "=$PWidth|Width", "=$PHeight|Height",
		"=$PHorizontalOffset|Horizontal Offset", "=$PVerticalOffset|Vertical Offset",
		"=$POutlineThickness|Outline Thickness", "@$PRotation|Rotation" }, vars, OSD_GUI)
	if i == 2 then compile({ "=topSpeed|Top Speed" }, nil, OSD_GUI) end
end
for _, vars in STICK_VARS do
	compile({ "^$N Stick", "?showZone$S|Show Zone", "?showStickDisplay$S|Show Stick Display",
		"?showStickCrosshair$S|Show Stick Crosshair", "?showStickLine$S|Show Stick Line", "",
		"#Position & Size", "=stickSize$S|Stick Size", "=stickHorizontalOffset$S|Horizontal Offset",
		"=stickVerticalOffset$S|Vertical Offset", "",
		"#Zone", "=zoneQuality$S|Quality (Segments)", "=zoneThickness$S|Thickness", "=zoneRotation$S|Rotation", "",
		"#Stick Display", "=stickDisplayQuality$S|Quality (Segments)", "=stickDisplayThickness$S|Thickness",
		"=stickDisplayRotation$S|Rotation", "",
		"#Stick Crosshair", "=stickCrosshairHorizontalSize$S|Horizontal Size",
		"=stickCrosshairVerticalSize$S|Vertical Size", "=stickCrosshairThickness$S|Thickness",
		"=stickCrosshairRotation$S|Rotation", "",
		"#Stick Line", "=stickLineThickness$S|Line Thickness" }, vars, OSD_GUI)
end

local DRONE_GUI = compile({
	"^Sensitivity",
	"#These only change how the sticks turn the drone. They do not change thrust or FOV.",
	"#If the drone turns too quickly at full stick, lower Full-Stick Speed. That is the end of the sensitivity curve.",
	"=overallSensitivity|Overall Sensitivity", "=fullStickSpeed|Full-Stick Speed", "=centerSoftness|Center Softness",
	"^Throttle", "=upThrottle|Up Throttle", "=downThrottle|Down Throttle",
	"=horizontalThrottle|Horizontal Throttle|(classic mode)",
	"^Physics", "=surfaceFriction|Surface Friction", "=gravity|Gravity", ">=fallAcceleration|Fall Acceleration",
	"?gravityAssist|Gravity Assist|(classic mode)", "+>=gravityAssistStrength|Gravity Assist Strength|(classic mode)",
	"+>?gravityAssistPerfect|Perfect Assist|(classic mode)",
	"^Hitbox", "=droneCollisionWidth|Drone collision Width", "=droneCollisionLength|Drone collision Length",
	"=droneCollisionHeight|Drone collision Height", "?droneHitbox|Drone Hitbox", "?grandEffect|GrandEffect",
	"#      The closer you are to the ground, the more extra boost you get.",
})

local COLOUR_GUI = compile({ "^Crosshair", "!centreCrosshair|Apply Centre Crosshair" })
for _, vars in BAR_VARS do
	compile({ "^$N Bar", "!$POutline|Apply $N Outline", "!$PFill|Apply $N Fill" }, vars, COLOUR_GUI)
end
for _, vars in STICK_VARS do
	compile({ "^$N Stick", "!zoneColour$S|Apply $N Zone", "!stickDisplayColour$S|Apply $N Stick Display",
		"!stickCrosshairColour$S|Apply $N Stick Crosshair", "!stickLineColour$S|Apply $N Stick Line" }, vars, COLOUR_GUI)
end

local RENDER_GUI = compile({
	"#These use the Spectator render flags. Players and other spectator cameras cannot be hidden from scripts.",
	"?showNameTags|Name tags", "?hideNearestHead|Hide nearest head", "?placeBallHereVisuals|Ball place visuals",
	"?scrapRunSpinners|Scrap Run spinners", "?goalExplosions|Goal explosions",
})

local CLASSIC_PAD_GUI = compile({
	"?swapTriggers|Swap Triggers", "?swapBumpersAndTriggers|Swap Bumpers and Triggers",
	"?swapLeftStickYAndTriggers|Swap Left Stick Y and Triggers",
})
local CLASSIC_INVERT_GUI = compile({
	"?invertPitch|Invert Pitch", "?invertYaw|Invert Yaw", "?invertClassicRoll|Invert Roll",
	"?invertRoll|Invert Strafe", "=rollSensitivity|Roll Sensitivity",
})
local ACRO_PAD_GUI = compile({
	"?invertPitch|Invert Pitch", "?invertYaw|Invert Yaw", "?invertRoll|Invert Roll",
	"?invertThrottle|Invert Throttle", "?swapLeftRightStickControls|Swap Left / Right Stick Controls",
})
local DPAD_HELP = { "D-Pad Up = save position", "D-Pad Right = respawn drone", "D-Pad Down = temp disable hitbox",
	"D-Pad Left = temp stabilization (max)" }
local CLASSIC_BINDS = { "moveForwardKey", "Move Forward", "moveBackKey", "Move Back", "moveLeftKey", "Move Left",
	"moveRightKey", "Move Right", "upKey", "Up", "downKey", "Down" }
local ACRO_BINDS = { "throttleUpKey", "Throttle Up", "throttleDownKey", "Throttle Down", "yawLeftKey", "Yaw Left",
	"yawRightKey", "Yaw Right" }
local DPAD_BINDS = { "savePositionKey", "Save Position", "respawnDroneKey", "Respawn Drone", "tempDisableHitboxKey",
	"Temp Disable Hitbox", "tempStabilizationKey", "Temp Stabilization", "toggleAllOsdKey", "Toggle All OSD" }

-- Classic controller help, built from the real mapping (including the swap and invert options).
local function classicPadHelp()
	local up, down = if S.swapTriggers then "LT" else "RT", if S.swapTriggers then "RT" else "LT"
	local vPlus, vMinus, rollRight, rollLeft = up, down, "RB", "LB"
	if S.swapBumpersAndTriggers then vPlus, vMinus, rollRight, rollLeft = "RB", "LB", up, down end
	if S.invertClassicRoll then rollRight, rollLeft = rollLeft, rollRight end
	if S.swapLeftStickYAndTriggers then
		if S.swapBumpersAndTriggers then
			Gui.text(vPlus .. " / " .. vMinus .. " = forward / back")
		else
			lines({ vPlus .. " = forward", vMinus .. " = back" })
		end
		lines({ "Left stick X = strafe", "Left stick Y = up / down" })
	else
		if S.invertThrottle then vPlus, vMinus = vMinus, vPlus end
		lines({ vPlus .. " = up", vMinus .. " = down", "Left stick = forward / back / left / right" })
	end
	lines({ "Right stick = yaw / pitch", rollLeft .. " = roll left", rollRight .. " = roll right" })
end

local function controlsTab()
	local classic = S.classicDrone
	Gui.text(if S.useKeyboardMouse then "Active input: Keyboard + Mouse" else "Active input: Controller")
	Gui.text(if classic then "Flight mode: Classic Drone" else "Flight mode: Acro")
	checkbox("classicDrone", "Classic Drone")
	if classic then
		indent()
		checkbox("autoStabilization", "Auto Stabilization")
		if S.autoStabilization then
			indent()
			slider("autoStabilizationStrength", "Stabilize Strength")
		end
	end
	checkbox("useKeyboardMouse", "Use Keyboard + Mouse")
	if not classic then checkbox("allowDownThrottle", "Down Throttle") end
	Gui.newLine()
	if Gui.collapsingHeader("Controller") then
		if classic then
			classicPadHelp()
			lines(DPAD_HELP)
			Gui.newLine()
			run(CLASSIC_PAD_GUI)
			if S.swapLeftStickYAndTriggers then
				indent()
				checkbox("invertThrottle", "Invert Vertical")
			end
			run(CLASSIC_INVERT_GUI)
		else
			if S.swapLeftRightStickControls then
				lines({ "Left stick = pitch / roll", "Right stick = throttle / yaw" })
			else
				lines({ "Left stick = throttle / yaw", "Right stick = pitch / roll" })
			end
			lines({ DPAD_HELP[1], DPAD_HELP[2], DPAD_HELP[3] }) -- temp stabilization does nothing in Acro
			Gui.newLine()
			run(ACRO_PAD_GUI)
		end
	end
	if Gui.collapsingHeader("Keyboard & Mouse") then
		Gui.text("Click a bind, then press a key. ESC sets it to blank.")
		Gui.newLine()
		if classic then
			bindRows(CLASSIC_BINDS)
		else
			bindRows(ACRO_BINDS)
			slider("keyboardYawSensitivity", "Keyboard Yaw Sensitivity")
		end
		Gui.newLine()
		Gui.text("DPad equivalents")
		bindRows(DPAD_BINDS)
		Gui.newLine()
		local mx = if classic then "Yaw" else "Roll"
		Gui.text("Mouse X = " .. string.lower(mx) .. "    Mouse Y = pitch")
		checkbox("invertMouseX", "Invert Mouse X (" .. mx .. ")")
		checkbox("invertMouseY", "Invert Mouse Y (Pitch)")
		slider("mousePitchSensitivity", "Mouse Pitch Sensitivity")
		slider("mouseXSensitivity", "Mouse " .. mx .. " Sensitivity")
		Gui.newLine()
		if Gui.button(Icon.Undo .. " Reset M&K Defaults") then
			defaultSection("M")
			capturing = nil
		end
	end
end

local function cameraTab()
	if S.classicDrone then
		slider("viewAngleUpClassic", "View Angle Up", "(classic mode)")
	else
		slider("viewAngleUp", "View Angle Up")
	end
	slider("fieldOfView", "Field of View")
	checkbox("speedFov", "Speed FOV (max 132 at high speed)")
	if S.speedFov then
		indent()
		checkbox("osdWobble", "OSD Wobble")
	end
	checkbox("showNameTags", "Show name tags")
	checkbox("cameraSmoothness", "Camera Smoothness")
	if S.cameraSmoothness then
		indent()
		slider("smoothness", "Movement Smoothness")
		indent()
		slider("rotationSmoothness", "Rotation Smoothness", nil, nil, config)
	end
end

local function colourTab()
	Gui.text("Set the picker, then Apply it to an item.")
	picker = Gui.colorEdit("Colour picker", picker)
	Gui.newLine()
	run(COLOUR_GUI)
end

local TABS: { { name: string, code: string, label: string, draw: () -> () } } = {
	{ name = "Controls", code = "C", label = "Controls", draw = controlsTab },
	{ name = "On Screen Display", code = "O", label = "OSD", draw = function() run(OSD_GUI) end },
	{ name = "Drone Settings", code = "D", label = "Drone Settings", draw = function() run(DRONE_GUI) end },
	{ name = "Camera Settings", code = "K", label = "Camera Settings", draw = cameraTab },
	{ name = "Colour", code = "L", label = "Colours", draw = colourTab },
	{ name = "Rendering", code = "R", label = "Rendering", draw = function() run(RENDER_GUI) end },
}

local function sectionButtons(code: string, label: string)
	Gui.newLine()
	if Gui.button(Icon.Save .. " Save " .. label) then
		saveSection(code)
		saveConfig()
	end
	Gui.sameLine()
	if Gui.button(Icon.Undo .. " Reset " .. label) then
		loadSection(if code == "O" then "[Oo]" else code) -- OSD reload also re-reads the stick colours
		if code == "C" then capturing = nil end
	end
	Gui.sameLine()
	if Gui.button(Icon.Undo .. " Reset Default") then defaultSection(code) end
end

local function pollCapture()
	local key = capturing
	if not key then return end
	if keyHeld("Escape") or keyPressed("Escape") then
		S[key], capturing = "", nil
		return
	end
	for _, name in BINDABLE do
		if keyPressed(name) or keyHeld(name) then
			S[key], capturing = name, nil
			return
		end
	end
end

function onGui()
	pollCapture()
	if Gui.button(Icon.Save .. " Save All") then
		saveSection(nil)
		saveConfig()
		snapshot = copyOf(config)
	end
	Gui.sameLine()
	if Gui.button(Icon.Undo .. " Reset") then
		local snap = snapshot
		if snap then -- restore the snapshot into the same config table, then write it
			for k in pairs(config) do
				if snap[k] == nil then config[k] = nil end
			end
			for k, v in pairs(snap) do config[k] = v end
		end
		loadSection(nil)
		capturing = nil
		if snap then saveConfig() end
	end
	Gui.sameLine()
	if Gui.button(Icon.Undo .. " Reset Defaults") then defaultSection(nil) end
	Gui.sameLine()
	Gui.text(BUILD_TAG)
	Gui.newLine()
	if Gui.beginTabBar("CoreDroneTabs") then
		for _, tab in TABS do
			if Gui.beginTabItem(tab.name) then
				tab.draw()
				sectionButtons(tab.code, tab.label)
				Gui.endTabItem()
			end
		end
		Gui.endTabBar()
	end
end
