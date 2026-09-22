-- @name Ashtonite.Core Drone
-- @credits Scha's Drone Camera + Grok
-- @author Ashtonite365
-- Version: 1.1.0
-- File: Ashtonite.Core Drone.Luau

metadata = {
	name = "Ashtonite.Core Drone",
	description = "Acro and Classic FPV drone camera for Spectator",
	author = "Ashtonite365",
	defaultKeybind = "",
}

local defPosition = config.position or Vec3.new(209, 2500, -28225)
local defRotation = Quat.fromEuler(0, 0, 90)
local droneRotation = Quat.fromEuler(0, 0, 90)
local velocity = Vec3.zeroVector

local function cfg(k, d) if config[k] == nil then return d end return config[k] end

local pitchOffsetFpv = cfg("pitchOffset", 30)
local pitchOffsetClassic = cfg("pitchOffsetClassic", 0)
local thrust = cfg("thrust", 4000)
local reverseThrust = cfg("reverseThrust", 3000)
local gravityStrength = cfg("gravityStrength", 1000)
local surfaceFriction = cfg("surfaceFriction", 0.200)
local fOV = cfg("fOV", 105)
local currentFov, hudFov = fOV, fOV
local showNameTags = cfg("showNameTags", true)
local grandEffect = cfg("grandEffect", true)
local droneWidth, droneLength, droneHeight = cfg("droneWidth", 9), cfg("droneLength", 9), cfg("droneHeight", 4)
local overallSensitivity = cfg("overallSensitivity", 1.2)
local fullStickSpeed = cfg("fullStickSpeed", 0.15)
local centerSoftness = cfg("centerSoftness", 0.07)
local mouseSens = cfg("mouseSens", 0.08)
local mouseYawSens = cfg("mouseYawSens", cfg("mouseRollSens", 0.08))
local keyboardYawSens = cfg("keyboardYawSens", 0.600)

local invertPitch, invertYaw = cfg("invertPitch", false), cfg("invertYaw", false)
local invertRoll, invertThrottle = cfg("invertRoll", false), cfg("invertThrottle", false)
local invertMouseX, invertMouseY = cfg("invertMouseX", false), cfg("invertMouseY", false)
local swapSticks, downThrottle = cfg("swapSticks", false), cfg("downThrottle", false)
local classicDrone = cfg("classicDrone", false)
local swapTriggers = cfg("swapTriggers", false)
local swapStickYTriggers = cfg("swapStickYTriggers", false)
local invertClassicRoll = cfg("invertClassicRoll", false)
local swapBumpersAndTriggers = cfg("swapBumpersAndTriggers", cfg("invertBumpersAndTriggers", false))
local autoStabilize = cfg("autoStabilize", false)
local autoStabilizeStrength = cfg("autoStabilizeStrength", 10.0)
local horizontalThrust = cfg("horizontalThrust", 1500)
local hitboxEnabled, useKeyboardMouse = cfg("hitboxEnabled", true), cfg("useKeyboardMouse", false)
local speedFov = cfg("speedFov", false)
local osdWobble = cfg("osdWobble", false)
local cameraSmooth = cfg("cameraSmooth", false)
local cameraSmoothAmount = math.clamp(cfg("cameraSmoothAmount", 0.12), 0.01, 0.50)
local controllerRollSens = cfg("controllerRollSens", 1.0)
local showOsd = cfg("showOsd", true)
local prevOsdToggle = false

local bindThrottleUp, bindThrottleDown = cfg("bindThrottleUp", "W"), cfg("bindThrottleDown", "S")
local bindYawLeft, bindYawRight = cfg("bindYawLeft", "A"), cfg("bindYawRight", "D")
local bindSavePos, bindRespawn, bindHitboxOff = cfg("bindSavePos", ""), cfg("bindRespawn", ""), cfg("bindHitboxOff", "")
local bindToggleOsd, bindTempStab = cfg("bindToggleOsd", ""), cfg("bindTempStab", "")
local bindMoveForward, bindMoveBack = cfg("bindMoveForward", "W"), cfg("bindMoveBack", "S")
local bindMoveLeft, bindMoveRight = cfg("bindMoveLeft", "A"), cfg("bindMoveRight", "D")
local bindVertUp, bindVertDown = cfg("bindVertUp", "SpaceBar"), cfg("bindVertDown", "LeftControl")
local waitingBind = nil

local showCrosshair = cfg("showCrosshair", true)
local crosshairHSize, crosshairVSize, crosshairThick = cfg("crosshairHSize", 6.0), cfg("crosshairVSize", 3.3), cfg("crosshairThick", 1.35)
local crosshairRot = cfg("crosshairRot", 0)
local colCH = {cfg("colCH_R", 0.95), cfg("colCH_G", 0.95), cfg("colCH_B", 0.95)}
local showThrottleBar = cfg("showThrottleBar", true)
local throttleWidth, throttleHeight = cfg("throttleWidth", 122.0), cfg("throttleHeight", 6.2)
local throttleOffX = cfg("throttleOffX", 0.0)
local throttleOffY = cfg("throttleOffY", cfg("throttleDown", 80.0))
local throttleThick = cfg("throttleThick", 2.0)
local throttleRot = cfg("throttleRot", 0)
local borderInset = 1.9
local colTBOut = {cfg("colTBOut_R", 1), cfg("colTBOut_G", 1), cfg("colTBOut_B", 1)}
local colTBFill = {cfg("colTBFill_R", 0.40), cfg("colTBFill_G", 0.70), cfg("colTBFill_B", 1)}
local showSpeedBar = cfg("showSpeedBar", true)
local speedWidth, speedHeight = cfg("speedWidth", 122.0), cfg("speedHeight", 6.2)
local speedOffX, speedOffY = cfg("speedOffX", 0.0), cfg("speedOffY", 71.0)
local speedThick, speedRot = cfg("speedThick", 2.0), cfg("speedRot", 0)
local topSpeed = cfg("topSpeed", 7500)
local colSBOut = {cfg("colSBOut_R", 1), cfg("colSBOut_G", 1), cfg("colSBOut_B", 1)}
local colSBFill = {cfg("colSBFill_R", 0.55), cfg("colSBFill_G", 1.00), cfg("colSBFill_B", 0.55)}

local HUD_REF_FOV, outerRadiusBase, innerRadiusBase = 105.0, 28.0, 7.0

local function makeStick(side)
	return {
		showOuter = cfg("showOuter"..side, true), showInner = cfg("showInner"..side, true),
		showCross = cfg("showCross"..side, true), showLine = cfg("showLine"..side, true),
		outerSeg = cfg("outerSeg"..side, 18), outerThick = cfg("outerThick"..side, 1.8),
		innerSeg = cfg("innerSeg"..side, 14), innerThick = cfg("innerThick"..side, 1.5),
		zoneRot = cfg("zoneRot"..side, 0), stickRot = cfg("stickRot"..side, 0),
		size = cfg("stickSize"..side, 1.0),
		crossH = cfg("crossHSize"..side, 4.0), crossV = cfg("crossVSize"..side, 4.0), crossThick = cfg("crossThick"..side, 1.3),
		crossRot = cfg("crossRot"..side, 0),
		lineThick = cfg("lineThick"..side, 1.4), offX = cfg("offsetX"..side, 105.0), offY = cfg("offsetY"..side, 52.0),
		colOuter = {cfg("colOuter"..side.."_R", 0.95), cfg("colOuter"..side.."_G", 0.95), cfg("colOuter"..side.."_B", 0.95)},
		colInner = {cfg("colInner"..side.."_R", 0.95), cfg("colInner"..side.."_G", 0.95), cfg("colInner"..side.."_B", 0.95)},
		colCross = {cfg("colCross"..side.."_R", 0.95), cfg("colCross"..side.."_G", 0.95), cfg("colCross"..side.."_B", 0.95)},
		colLine  = {cfg("colLine"..side.."_R", 0.70), cfg("colLine"..side.."_G", 0.70), cfg("colLine"..side.."_B", 1.00)},
	}
end
local stickL, stickR = makeStick("L"), makeStick("R")

local collisionPoints = {Vec3.zeroVector, Vec3.zeroVector, Vec3.zeroVector, Vec3.zeroVector, Vec3.zeroVector, Vec3.zeroVector, Vec3.zeroVector, Vec3.zeroVector}
local collisionEnabled, currentThrottle = true, 0
local visCamPos, dronePos = nil, nil
local stickLx, stickLy, stickRx, stickRy = 0, 0, 0, 0

local BINDABLE = {
	"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
	"Zero","One","Two","Three","Four","Five","Six","Seven","Eight","Nine",
	"SpaceBar","LeftShift","RightShift","LeftControl","RightControl","LeftAlt","RightAlt","Tab",
	"Up","Down","Left","Right","Enter","CapsLock"
}

local gatePosTable = {
	{Vec3.new(-521.518, 7628.015, -29632.256), Vec3.rightVector},
	{Vec3.new(-2153.015, 18027.914, -29630.484), Vec3.backwardVector},
	{Vec3.new(2153.015, 19071.021, -29630.484), Vec3.forwardVector},
	{Vec3.new(-2228.015, 26579.072, -29833.324), Vec3.backwardVector},
	{Vec3.new(2230.015, 27620.953, -29833.324), Vec3.forwardVector},
	{Vec3.new(-521.190, 24978.014, -28037.043), Vec3.rightVector},
	{Vec3.new(419.163, 27221.986, -31508.912), Vec3.leftVector}
}
local gatePosTableDp = {
	{Vec3.new(14678.619, 26927.014, -26464.400), Quat.fromEuler(0, 30, 0)},
	{Vec3.new(14755.499 + 2.5 * math.sqrt(3), 22679.189, -26421.303 + 2.5), Quat.fromEuler(30, 0, 90)},
	{Vec3.new(15502.321 - 2.5 * math.sqrt(3), 23717.449, -25986.779 - 2.5), Quat.fromEuler(-30, 0, -90)},
	{Vec3.new(14754.335 + 2.5 * math.sqrt(3), 13079.364, -26419.287 + 2.5), Quat.fromEuler(30, 0, 90)},
	{Vec3.new(15503.671 - 2.5 * math.sqrt(3), 14118.737, -25989.115 - 2.5), Quat.fromEuler(-30, 0, -90)},
	{Vec3.new(14755.413 + 2.5 * math.sqrt(3), 5879.726, -26421.154 + 2.5), Quat.fromEuler(30, 0, 90)},
	{Vec3.new(15503.632 - 2.5 * math.sqrt(3), 6921.189, -25989.049 - 2.5), Quat.fromEuler(-30, 0, -90)}
}

local bindMap = {
	thrUp = function(v) bindThrottleUp = v end,
	thrDown = function(v) bindThrottleDown = v end,
	yawL = function(v) bindYawLeft = v end,
	yawR = function(v) bindYawRight = v end,
	save = function(v) bindSavePos = v end,
	respawn = function(v) bindRespawn = v end,
	hitbox = function(v) bindHitboxOff = v end,
	osdToggle = function(v) bindToggleOsd = v end,
	tempStab = function(v) bindTempStab = v end,
	moveF = function(v) bindMoveForward = v end,
	moveB = function(v) bindMoveBack = v end,
	moveL = function(v) bindMoveLeft = v end,
	moveR = function(v) bindMoveRight = v end,
	vertUp = function(v) bindVertUp = v end,
	vertDown = function(v) bindVertDown = v end,
}

local function safeNormalize(v)
	local mag = v:length()
	if mag < 0.0001 then return Vec3.zeroVector, 0 end
	return v / mag, mag
end

local function liveCameraFov()
	if camera.getSmoothedFieldOfView then
		return camera:getSmoothedFieldOfView()
	end
	return camera.fieldOfView or currentFov or fOV
end

local function hudFovScale()
	local src
	if speedFov and osdWobble then
		src = hudFov
	else
		src = liveCameraFov()
	end
	return math.tan(math.rad(math.clamp(src, 1, 170)) * 0.5) / math.tan(math.rad(HUD_REF_FOV) * 0.5)
end

local function sliderR(label, value, minV, maxV, def, id, tag)
	value = Gui.sliderFloat(label, value, minV, maxV)
	Gui.sameLine()
	if Gui.button("R##"..id) then value = def end
	if tag then
		Gui.sameLine()
		Gui.text(tag)
	end
	return value
end

local function sliderRotR(label, value, minV, maxV, def, id)
	value = Gui.sliderFloat(label, value, minV, maxV)
	Gui.sameLine()
	if Gui.button("90##"..id) then value = 90 end
	Gui.sameLine()
	if Gui.button("-90##"..id) then value = -90 end
	Gui.sameLine()
	if Gui.button("R##"..id) then value = def end
	return value
end

local function rgbRow(label, col, def)
	Gui.text(label)
	col[1] = sliderR("Red##"..label, col[1], 0, 1, def[1], "R"..label)
	col[2] = sliderR("Green##"..label, col[2], 0, 1, def[2], "G"..label)
	col[3] = sliderR("Blue##"..label, col[3], 0, 1, def[3], "B"..label)
end

local function storeCol(prefix, col)
	config[prefix.."_R"], config[prefix.."_G"], config[prefix.."_B"] = col[1], col[2], col[3]
end

local function saveStick(side, s)
	config["showOuter"..side], config["showInner"..side] = s.showOuter, s.showInner
	config["showCross"..side], config["showLine"..side] = s.showCross, s.showLine
	config["outerSeg"..side], config["outerThick"..side] = s.outerSeg, s.outerThick
	config["innerSeg"..side], config["innerThick"..side] = s.innerSeg, s.innerThick
	config["stickSize"..side], config["crossHSize"..side], config["crossVSize"..side] = s.size, s.crossH, s.crossV
	config["crossThick"..side], config["crossRot"..side], config["lineThick"..side] = s.crossThick, s.crossRot, s.lineThick
	config["offsetX"..side], config["offsetY"..side] = s.offX, s.offY
	config["zoneRot"..side], config["stickRot"..side] = s.zoneRot, s.stickRot
end

local function resetStick(s)
	s.showOuter, s.showInner, s.showCross, s.showLine = true, true, true, true
	s.outerSeg, s.outerThick, s.innerSeg, s.innerThick = 18, 1.8, 14, 1.5
	s.size, s.crossH, s.crossV, s.crossThick, s.crossRot = 1.0, 4.0, 4.0, 1.3, 0
	s.lineThick, s.offX, s.offY = 1.4, 105.0, 52.0
	s.zoneRot, s.stickRot = 0, 0
end

local function resetStickCols(s)
	s.colOuter, s.colInner, s.colCross, s.colLine = {0.95, 0.95, 0.95}, {0.95, 0.95, 0.95}, {0.95, 0.95, 0.95}, {0.70, 0.70, 1.00}
end

local function saveStickCols(side, s)
	storeCol("colOuter"..side, s.colOuter); storeCol("colInner"..side, s.colInner)
	storeCol("colCross"..side, s.colCross); storeCol("colLine"..side, s.colLine)
end

local function stickGui(title, s, id)
	if not Gui.collapsingHeader(title) then return end
	s.showOuter = Gui.checkbox("Show Zone##"..id, s.showOuter)
	s.showInner = Gui.checkbox("Show Stick Display##"..id, s.showInner)
	s.showCross = Gui.checkbox("Show Stick Crosshair##"..id, s.showCross)
	s.showLine  = Gui.checkbox("Show Stick Line##"..id, s.showLine)
	Gui.newLine(); Gui.text("Position & Size")
	s.size = sliderR("Stick Size##"..id, s.size, 0.5, 2.0, 1.0, "size"..id)
	s.offX = sliderR("Horizontal Offset##"..id, s.offX, 0.0, 160.0, 105.0, "offX"..id)
	s.offY = sliderR("Vertical Offset##"..id, s.offY, -90.0, 90.0, 52.0, "offY"..id)
	Gui.newLine(); Gui.text("Zone")
	s.outerSeg = sliderR("Quality (Segments)##o"..id, s.outerSeg, 4, 50, 18, "oSeg"..id)
	s.outerThick = sliderR("Thickness##o"..id, s.outerThick, 0.5, 4.0, 1.8, "oThk"..id)
	s.zoneRot = sliderR("Rotation##o"..id, s.zoneRot, 0, 45, 0, "oRot"..id)
	Gui.newLine(); Gui.text("Stick Display")
	s.innerSeg = sliderR("Quality (Segments)##i"..id, s.innerSeg, 4, 50, 14, "iSeg"..id)
	s.innerThick = sliderR("Thickness##i"..id, s.innerThick, 0.5, 4.0, 1.5, "iThk"..id)
	s.stickRot = sliderR("Rotation##i"..id, s.stickRot, 0, 45, 0, "iRot"..id)
	Gui.newLine(); Gui.text("Stick Crosshair")
	s.crossH = sliderR("Horizontal Size##c"..id, s.crossH, 1.0, 15.0, 4.0, "cH"..id)
	s.crossV = sliderR("Vertical Size##c"..id, s.crossV, 1.0, 15.0, 4.0, "cV"..id)
	s.crossThick = sliderR("Thickness##c"..id, s.crossThick, 0.5, 4.0, 1.3, "cT"..id)
	s.crossRot = sliderR("Rotation##c"..id, s.crossRot, 0, 45, 0, "cRot"..id)
	Gui.newLine(); Gui.text("Stick Line")
	s.lineThick = sliderR("Line Thickness##"..id, s.lineThick, 0.5, 4.0, 1.4, "line"..id)
end

local function packControls()
	config.invertPitch, config.invertYaw, config.invertRoll = invertPitch, invertYaw, invertRoll
	config.invertThrottle, config.swapSticks, config.downThrottle = invertThrottle, swapSticks, downThrottle
	config.classicDrone, config.swapTriggers, config.swapStickYTriggers, config.invertClassicRoll, config.swapBumpersAndTriggers = classicDrone, swapTriggers, swapStickYTriggers, invertClassicRoll, swapBumpersAndTriggers
	config.autoStabilize, config.autoStabilizeStrength = autoStabilize, autoStabilizeStrength
	config.invertMouseX, config.invertMouseY = invertMouseX, invertMouseY
	config.useKeyboardMouse, config.mouseSens, config.mouseYawSens, config.keyboardYawSens = useKeyboardMouse, mouseSens, mouseYawSens, keyboardYawSens
	config.bindThrottleUp, config.bindThrottleDown = bindThrottleUp, bindThrottleDown
	config.bindYawLeft, config.bindYawRight = bindYawLeft, bindYawRight
	config.bindMoveForward, config.bindMoveBack = bindMoveForward, bindMoveBack
	config.bindMoveLeft, config.bindMoveRight = bindMoveLeft, bindMoveRight
	config.bindVertUp, config.bindVertDown = bindVertUp, bindVertDown
	config.bindSavePos, config.bindRespawn, config.bindHitboxOff = bindSavePos, bindRespawn, bindHitboxOff
	config.bindTempStab, config.bindToggleOsd, config.controllerRollSens, config.showOsd = bindTempStab, bindToggleOsd, controllerRollSens, showOsd
end

local function packOsd()
	config.showCrosshair, config.crosshairHSize, config.crosshairVSize, config.crosshairThick, config.crosshairRot = showCrosshair, crosshairHSize, crosshairVSize, crosshairThick, crosshairRot
	config.showThrottleBar, config.throttleWidth, config.throttleHeight = showThrottleBar, throttleWidth, throttleHeight
	config.throttleOffX, config.throttleOffY, config.throttleDown, config.throttleThick, config.throttleRot = throttleOffX, throttleOffY, throttleOffY, throttleThick, throttleRot
	config.showSpeedBar, config.speedWidth, config.speedHeight = showSpeedBar, speedWidth, speedHeight
	config.speedOffX, config.speedOffY, config.speedThick, config.speedRot, config.topSpeed = speedOffX, speedOffY, speedThick, speedRot, topSpeed
	config.showOsd = showOsd
	saveStick("L", stickL); saveStick("R", stickR)
end

local function packDrone()
	config.droneWidth, config.droneLength, config.droneHeight = droneWidth, droneLength, droneHeight
	config.thrust, config.reverseThrust, config.gravityStrength = thrust, reverseThrust, gravityStrength
	config.horizontalThrust, config.surfaceFriction, config.hitboxEnabled, config.grandEffect = horizontalThrust, surfaceFriction, hitboxEnabled, grandEffect
end

local function packCamera()
	config.pitchOffset, config.pitchOffsetClassic, config.fOV, config.showNameTags = pitchOffsetFpv, pitchOffsetClassic, fOV, showNameTags
	config.speedFov, config.osdWobble, config.cameraSmooth, config.cameraSmoothAmount = speedFov, osdWobble, cameraSmooth, cameraSmoothAmount
end

local function packColours()
	storeCol("colCH", colCH); storeCol("colTBOut", colTBOut); storeCol("colTBFill", colTBFill)
	storeCol("colSBOut", colSBOut); storeCol("colSBFill", colSBFill)
	saveStickCols("L", stickL); saveStickCols("R", stickR)
end

local function stickColourGui(title, s, side)
	if not Gui.collapsingHeader(title) then return end
	rgbRow(side.." Zone", s.colOuter, {0.95, 0.95, 0.95}); Gui.newLine()
	rgbRow(side.." Stick Display", s.colInner, {0.95, 0.95, 0.95}); Gui.newLine()
	rgbRow(side.." Stick Crosshair", s.colCross, {0.95, 0.95, 0.95}); Gui.newLine()
	rgbRow(side.." Stick Line", s.colLine, {0.70, 0.70, 1.00})
end

local function keyEnum(name)
	return (name and name ~= "" and Input.Key and Input.Key[name]) or nil
end
local function keyHeld(name)
	local k = keyEnum(name)
	return k ~= nil and Input.getKey(k)
end
local function keyDown(name)
	local k = keyEnum(name)
	if not k then return false end
	if Input.getKeyDown then return Input.getKeyDown(k) end
	return Input.getKey(k)
end

local function pollNewBind()
	if not waitingBind then return end
	local esc = keyEnum("Escape") or keyEnum("EscapeKey")
	local pressed = function(k) return k and ((Input.getKeyDown and Input.getKeyDown(k)) or Input.getKey(k)) end
	if pressed(esc) then bindMap[waitingBind](""); waitingBind = nil; return end
	for _, name in ipairs(BINDABLE) do
		if pressed(keyEnum(name)) then bindMap[waitingBind](name); waitingBind = nil; return end
	end
end

local function bindRow(label, value, def, id)
	Gui.text(label); Gui.sameLine()
	local shown = (value == nil or value == "") and "None" or value
	if waitingBind == id then shown = "Press key (ESC = blank)" end
	if Gui.button(shown.."##bind"..id) then waitingBind = id end
	Gui.sameLine()
	if Gui.button("R##bind"..id) then bindMap[id](def); if waitingBind == id then waitingBind = nil end end
end

local function gateShape(originPoint, gateAngle)
	local awayGate, homeGate = {Vec3.zeroVector, Vec3.zeroVector}, {Vec3.zeroVector, Vec3.zeroVector}
	if gateAngle == Vec3.new(0, -1, 0) then
		awayGate[1] = Vec3.new(originPoint.X - 252, originPoint.Y - 30, originPoint.Z)
		awayGate[2] = Vec3.new(originPoint.X, originPoint.Y, originPoint.Z + 165)
		homeGate[1] = Vec3.new(originPoint.X - 252 - 800, originPoint.Y - 30, originPoint.Z)
		homeGate[2] = Vec3.new(originPoint.X - 800, originPoint.Y, originPoint.Z + 165)
	elseif gateAngle == Vec3.new(0, 1, 0) then
		awayGate[1] = Vec3.new(originPoint.X, originPoint.Y, originPoint.Z)
		awayGate[2] = Vec3.new(originPoint.X + 252, originPoint.Y + 30, originPoint.Z + 165)
		homeGate[1] = Vec3.new(originPoint.X + 800, originPoint.Y, originPoint.Z)
		homeGate[2] = Vec3.new(originPoint.X + 252 + 800, originPoint.Y + 30, originPoint.Z + 165)
	elseif gateAngle == Vec3.new(1, 0, 0) then
		awayGate[1] = Vec3.new(originPoint.X, originPoint.Y - 252, originPoint.Z)
		awayGate[2] = Vec3.new(originPoint.X + 30, originPoint.Y, originPoint.Z + 165)
		homeGate[1] = Vec3.new(originPoint.X, originPoint.Y - 252 - 800, originPoint.Z)
		homeGate[2] = Vec3.new(originPoint.X + 30, originPoint.Y - 800, originPoint.Z + 165)
	elseif gateAngle == Vec3.new(-1, 0, 0) then
		awayGate[1] = Vec3.new(originPoint.X - 30, originPoint.Y, originPoint.Z)
		awayGate[2] = Vec3.new(originPoint.X, originPoint.Y + 252, originPoint.Z + 165)
		homeGate[1] = Vec3.new(originPoint.X - 30, originPoint.Y + 800, originPoint.Z)
		homeGate[2] = Vec3.new(originPoint.X, originPoint.Y + 252 + 800, originPoint.Z + 165)
	end
	return awayGate, homeGate
end

local function gateShapeDriftplex(originPoint, gateAngle)
	local sizeX, sizeY, sizeZ = 252, 30, 165
	local awayBases = {
		Vec3.zeroVector, Vec3.new(sizeX, 0, 0), Vec3.new(0, sizeY, 0), Vec3.new(sizeX, sizeY, 0),
		Vec3.new(0, 0, sizeZ), Vec3.new(sizeX, 0, sizeZ), Vec3.new(0, sizeY, sizeZ), Vec3.new(sizeX, sizeY, sizeZ)
	}
	local awayGate, homeGate = {}, {}
	for i, point in ipairs(awayBases) do
		awayGate[i] = gateAngle:rotateVector(point) + originPoint
		homeGate[i] = gateAngle:rotateVector(point + Vec3.new(800, 0, 0)) + originPoint
	end
	return awayGate, homeGate
end

local function gateBoundsTable()
	local boundsTable = {}
	for _, g in ipairs(gatePosTable) do
		local a, h = gateShape(g[1], g[2])
		table.insert(boundsTable, {a[1], a[2]}); table.insert(boundsTable, {h[1], h[2]})
	end
	return boundsTable
end

local function gateBoundsTableDp()
	local gateBounds = {}
	for _, g in ipairs(gatePosTableDp) do
		local a, h = gateShapeDriftplex(g[1], g[2])
		table.insert(gateBounds, {awayGate = a, homeGate = h})
	end
	return gateBounds
end

local gateBounds, gateBoundsDp = gateBoundsTable(), gateBoundsTableDp()

function isPointInGate(hitPoint, gateVertices)
	local center = Vec3.zeroVector
	for _, v in ipairs(gateVertices) do center = center + v end
	center = center / 8
	local function len(v) return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z) end
	local right = (gateVertices[2] - gateVertices[1]):normalize()
	local up = (gateVertices[3] - gateVertices[1]):normalize()
	local forward = (gateVertices[5] - gateVertices[1]):normalize()
	local hx = len(gateVertices[2] - gateVertices[1]) / 2
	local hy = len(gateVertices[3] - gateVertices[1]) / 2
	local hz = len(gateVertices[5] - gateVertices[1]) / 2
	local p = hitPoint - center
	return math.abs(p:dot(right)) <= hx and math.abs(p:dot(up)) <= hy and math.abs(p:dot(forward)) <= hz
end

local function isInsideAnyGate(point)
	for _, b in ipairs(gateBounds) do
		local a, c = b[1], b[2]
		if point.x >= a.x and point.x <= c.x and point.y >= a.y and point.y <= c.y and point.z >= a.z and point.z <= c.z then
			return true
		end
	end
	for i = 1, #gateBoundsDp do
		if isPointInGate(point, gateBoundsDp[i].awayGate) or isPointInGate(point, gateBoundsDp[i].homeGate) then return true end
	end
	return false
end

local function readMouseDelta()
	local x, y = 0, 0
	if Input.getMouseDelta then
		local d = Input.getMouseDelta()
		if d then x = d.X or d.x or 0; y = d.Y or d.y or 0 end
	elseif Input.mouseDeltaX ~= nil then
		x, y = Input.mouseDeltaX, Input.mouseDeltaY or 0
	end
	if invertMouseX then x = -x end
	if invertMouseY then y = -y end
	return math.clamp(x * mouseYawSens, -1, 1), math.clamp(-y * mouseSens, -1, 1)
end

local function gamepadAnalog(name)
	local g = Input.Gamepad
	if not g or g[name] == nil then return 0 end
	local v = Input.getAnalog(g[name])
	if v == nil then return 0 end
	return v
end

local function triggerAxis()
	local rt = gamepadAnalog("RightTrigger")
	if rt == 0 then rt = gamepadAnalog("RightTriggerAxis") end
	local lt = gamepadAnalog("LeftTrigger")
	if lt == 0 then lt = gamepadAnalog("LeftTriggerAxis") end
	if swapTriggers then rt, lt = lt, rt end
	return math.clamp(rt, 0, 1), math.clamp(lt, 0, 1)
end

local function padValue(key)
	if key == nil then return false end
	local v = Input.getKey(key)
	if v == nil or v == false or v == 0 then return false end
	return true
end
local function gamepadHeld(name)
	local g = Input.Gamepad
	if not g then return false end
	if g[name] ~= nil and padValue(g[name]) then return true end
	return false
end
local prevPadHeld = {}
local function gamepadDown(name)
	local held = gamepadHeld(name)
	local edge = held and not prevPadHeld[name]
	prevPadHeld[name] = held
	return edge
end

local function bumperRoll()
	local right = gamepadHeld("RightShoulder") or gamepadHeld("RightBumper") or gamepadHeld("RightShoulderButton")
	local left = gamepadHeld("LeftShoulder") or gamepadHeld("LeftBumper") or gamepadHeld("LeftShoulderButton")
	local roll = 0
	if right then roll += 1 end
	if left then roll -= 1 end
	return roll
end

local function getMappedInputs()
	local lx, ly, rx, ry
	local moveX, moveY, vert, rxRollFromTrig = 0, 0, 0, nil
	if useKeyboardMouse then
		if classicDrone then
			if keyHeld(bindMoveLeft) then moveX -= 1 end
			if keyHeld(bindMoveRight) then moveX += 1 end
			if keyHeld(bindMoveBack) then moveY -= 1 end
			if keyHeld(bindMoveForward) then moveY += 1 end
			if keyHeld(bindVertDown) then vert -= 1 end
			if keyHeld(bindVertUp) then vert += 1 end
			lx, ly = moveX, moveY
			local mx, my = readMouseDelta()
			rx, ry = mx, my
		else
			lx = 0
			if keyHeld(bindYawLeft) then lx -= keyboardYawSens end
			if keyHeld(bindYawRight) then lx += keyboardYawSens end
			ly = 0
			if keyHeld(bindThrottleDown) then ly -= 1 end
			if keyHeld(bindThrottleUp) then ly += 1 end
			local mx, my = readMouseDelta()
			rx, ry = mx, my
		end
	else
		lx = gamepadAnalog("LeftX")
		ly = gamepadAnalog("LeftY")
		rx = gamepadAnalog("RightX")
		ry = gamepadAnalog("RightY")
		if classicDrone then
			local rt, lt = triggerAxis()
			local bump = bumperRoll()
			if swapBumpersAndTriggers then
				moveX, moveY, vert = lx, ly, bump
				rxRollFromTrig = rt - lt
			else
				moveX, moveY, vert = lx, ly, rt - lt
				rxRollFromTrig = bump
			end
			if swapStickYTriggers then
				moveY, vert = vert, ly
			end
		end
	end

	local yawIn, thrIn, rollIn, pitchIn
	if classicDrone then
		yawIn, pitchIn = rx, ry
		rollIn = (rxRollFromTrig or bumperRoll()) * controllerRollSens
		thrIn = vert
		if invertYaw then yawIn = -yawIn end
		if invertPitch then pitchIn = -pitchIn end
		if invertThrottle then thrIn = -thrIn end
		if invertRoll then moveX = -moveX end
		if invertClassicRoll then rollIn = -rollIn end
		return yawIn, thrIn, rollIn, pitchIn, lx, ly, rx, ry, moveX, moveY
	end

	yawIn, thrIn, rollIn, pitchIn = lx, ly, rx, ry
	if swapSticks then yawIn, thrIn, rollIn, pitchIn = rx, ry, lx, ly end
	if invertYaw then yawIn = -yawIn end
	if invertThrottle then thrIn = -thrIn end
	if invertRoll then rollIn = -rollIn end
	if invertPitch then pitchIn = -pitchIn end
	return yawIn, thrIn, rollIn, pitchIn, lx, ly, rx, ry, 0, 0
end

function onGui()
	pollNewBind()
	if Gui.button(Icon.Save .. " Save All") then
		packControls(); packOsd(); packDrone(); packCamera(); packColours()
		config.overallSensitivity, config.fullStickSpeed, config.centerSoftness = overallSensitivity, fullStickSpeed, centerSoftness
		saveConfig()
		originalConfig = table.clone(config)
	end
	Gui.sameLine()
	if Gui.button(Icon.Undo .. " Reset") then
		if originalConfig then config = table.clone(originalConfig) end
	end
	Gui.sameLine()
	if Gui.button(Icon.Undo .. " Reset Defaults") then
		showOsd, controllerRollSens = true, 1.0
		bindToggleOsd, bindTempStab = "", ""
		classicDrone, autoStabilize, autoStabilizeStrength = false, false, 10.0
		swapBumpersAndTriggers, swapTriggers, swapStickYTriggers = false, false, false
		useKeyboardMouse, downThrottle = false, false
		showCrosshair, showThrottleBar, showSpeedBar = true, true, true
		cameraSmooth, cameraSmoothAmount, speedFov, osdWobble = false, 0.12, false, false
	end
	Gui.newLine()
	if not Gui.beginTabBar("MainTabs") then return end

	if Gui.beginTabItem("Controls") then
		Gui.text(useKeyboardMouse and "Active input: Keyboard + Mouse" or "Active input: Controller")
		Gui.text(classicDrone and "Flight mode: Classic Drone" or "Flight mode: Acro")
		classicDrone = Gui.checkbox("Classic Drone", classicDrone)
		Gui.setItemTooltip("Triggers = up/down. Left stick = move. Right stick = turn and pitch.")
		if classicDrone then
			Gui.text("      ")
			Gui.sameLine()
			autoStabilize = Gui.checkbox("Auto Stabilization", autoStabilize)
			Gui.setItemTooltip("Levels pitch and roll toward upright in Classic Drone.")
			if autoStabilize then
				Gui.text("      ")
				Gui.sameLine()
				autoStabilizeStrength = sliderR("Stabilize Strength", autoStabilizeStrength, 0, 30, 10.0, "autoStab")
			end
		end
		useKeyboardMouse = Gui.checkbox("Use Keyboard + Mouse", useKeyboardMouse)
		if not classicDrone then
			downThrottle = Gui.checkbox("Down Throttle", downThrottle)
		end
		Gui.newLine()
		if Gui.collapsingHeader("Controller") then
			if classicDrone then
				local upTrig = swapTriggers and "LT" or "RT"
				local downTrig = swapTriggers and "RT" or "LT"
				local leftBump, rightBump = "LB", "RB"
				if invertClassicRoll then leftBump, rightBump = "RB", "LB" end
				if swapBumpersAndTriggers then
					if swapStickYTriggers then
						Gui.text(leftBump.." / "..rightBump.." = forward / back")
						Gui.text("Left stick X = strafe")
						Gui.text("Left stick Y = up / down")
					else
						Gui.text(rightBump.." = up")
						Gui.text(leftBump.." = down")
						Gui.text("Left stick = forward / back / left / right")
					end
					Gui.text("Right stick = yaw / pitch")
					Gui.text(downTrig.." = roll left")
					Gui.text(upTrig.." = roll right")
				else
				if swapStickYTriggers then
					Gui.text(upTrig.." = forward")
					Gui.text(downTrig.." = back")
					Gui.text("Left stick X = strafe")
					Gui.text("Left stick Y = up / down")
				else
					Gui.text(upTrig.." = up")
					Gui.text(downTrig.." = down")
					Gui.text("Left stick = forward / back / left / right")
				end
				Gui.text("Right stick = yaw / pitch")
				Gui.text(leftBump.." = roll left")
				Gui.text(rightBump.." = roll right")
				end
				Gui.text("D-Pad Up = save position")
				Gui.text("D-Pad Right = respawn drone")
				Gui.text("D-Pad Down = temp disable hitbox")
				Gui.text("D-Pad Left = temp stabilization (max)")
				Gui.newLine()
				swapTriggers = Gui.checkbox("Swap Triggers", swapTriggers)
				swapBumpersAndTriggers = Gui.checkbox("Swap Bumpers and Triggers", swapBumpersAndTriggers)
				swapStickYTriggers = Gui.checkbox("Swap Left Stick Y and Triggers", swapStickYTriggers)
				if swapStickYTriggers then
					Gui.text("      ")
					Gui.sameLine()
					invertThrottle = Gui.checkbox("Invert Vertical", invertThrottle)
				end
				invertPitch = Gui.checkbox("Invert Pitch", invertPitch)
				invertYaw = Gui.checkbox("Invert Yaw", invertYaw)
				invertClassicRoll = Gui.checkbox("Invert Roll", invertClassicRoll)
				invertRoll = Gui.checkbox("Invert Strafe", invertRoll)
				controllerRollSens = sliderR("Roll Sensitivity", controllerRollSens, 0.10, 2.50, 1.0, "padRollSens")
			else
				if swapSticks then
					Gui.text("Left stick = pitch / roll")
					Gui.text("Right stick = throttle / yaw")
				else
					Gui.text("Left stick = throttle / yaw")
					Gui.text("Right stick = pitch / roll")
				end
				Gui.text("D-Pad Up = save position")
				Gui.text("D-Pad Right = respawn drone")
				Gui.text("D-Pad Down = temp disable hitbox")
				Gui.text("D-Pad Left = temp stabilization (max)")
				Gui.newLine()
				invertPitch = Gui.checkbox("Invert Pitch", invertPitch)
				invertYaw = Gui.checkbox("Invert Yaw", invertYaw)
				invertRoll = Gui.checkbox("Invert Roll", invertRoll)
				invertThrottle = Gui.checkbox("Invert Throttle", invertThrottle)
				swapSticks = Gui.checkbox("Swap Left / Right Stick Controls", swapSticks)
			end
		end
		if Gui.collapsingHeader("Keyboard & Mouse") then
			Gui.text("Click a bind, then press a key. ESC sets it to blank.")
			Gui.newLine()
			if classicDrone then
				bindRow("Move Forward", bindMoveForward, "W", "moveF")
				bindRow("Move Back", bindMoveBack, "S", "moveB")
				bindRow("Move Left", bindMoveLeft, "A", "moveL")
				bindRow("Move Right", bindMoveRight, "D", "moveR")
				bindRow("Up", bindVertUp, "SpaceBar", "vertUp")
				bindRow("Down", bindVertDown, "LeftControl", "vertDown")
				Gui.newLine(); Gui.text("DPad equivalents")
				bindRow("Save Position", bindSavePos, "", "save")
				bindRow("Respawn Drone", bindRespawn, "", "respawn")
				bindRow("Temp Disable Hitbox", bindHitboxOff, "", "hitbox")
				bindRow("Temp Stabilization", bindTempStab, "", "tempStab")
				bindRow("Toggle All OSD", bindToggleOsd, "", "osdToggle")
				Gui.newLine(); Gui.text("Mouse X = yaw    Mouse Y = pitch")
				invertMouseX = Gui.checkbox("Invert Mouse X (Yaw)", invertMouseX)
				invertMouseY = Gui.checkbox("Invert Mouse Y (Pitch)", invertMouseY)
				mouseSens = sliderR("Mouse Pitch Sensitivity", mouseSens, 0.01, 0.4, 0.08, "mouseSens")
				mouseYawSens = sliderR("Mouse Yaw Sensitivity", mouseYawSens, 0.01, 0.4, 0.08, "mouseYawSens")
			else
				bindRow("Throttle Up", bindThrottleUp, "W", "thrUp")
				bindRow("Throttle Down", bindThrottleDown, "S", "thrDown")
				bindRow("Yaw Left", bindYawLeft, "A", "yawL")
				bindRow("Yaw Right", bindYawRight, "D", "yawR")
				keyboardYawSens = sliderR("Keyboard Yaw Sensitivity", keyboardYawSens, 0.01, 1.0, 0.600, "keyYawSens")
				Gui.newLine(); Gui.text("DPad equivalents")
				bindRow("Save Position", bindSavePos, "", "save")
				bindRow("Respawn Drone", bindRespawn, "", "respawn")
				bindRow("Temp Disable Hitbox", bindHitboxOff, "", "hitbox")
				bindRow("Temp Stabilization", bindTempStab, "", "tempStab")
				bindRow("Toggle All OSD", bindToggleOsd, "", "osdToggle")
				Gui.newLine(); Gui.text("Mouse X = roll    Mouse Y = pitch")
				invertMouseX = Gui.checkbox("Invert Mouse X (Roll)", invertMouseX)
				invertMouseY = Gui.checkbox("Invert Mouse Y (Pitch)", invertMouseY)
				mouseSens = sliderR("Mouse Pitch Sensitivity", mouseSens, 0.01, 0.4, 0.08, "mouseSens")
				mouseYawSens = sliderR("Mouse Roll Sensitivity", mouseYawSens, 0.01, 0.4, 0.08, "mouseYawSens")
			end
			Gui.newLine()
			if Gui.button(Icon.Undo .. " Reset M&K Defaults") then
				bindThrottleUp, bindThrottleDown, bindYawLeft, bindYawRight = "W", "S", "A", "D"
				bindMoveForward, bindMoveBack, bindMoveLeft, bindMoveRight = "W", "S", "A", "D"
				bindVertUp, bindVertDown = "SpaceBar", "LeftControl"
				bindSavePos, bindRespawn, bindHitboxOff, bindTempStab, bindToggleOsd = "", "", "", "", ""
				invertMouseX, invertMouseY, mouseSens, mouseYawSens, keyboardYawSens = false, false, 0.08, 0.08, 0.600
				waitingBind = nil
			end
		end
		Gui.newLine()
		if Gui.button(Icon.Save .. " Save Controls") then
			packControls(); saveConfig()
		end
		if Gui.button(Icon.Undo .. " Reset Controls") then
			invertPitch, invertYaw, invertRoll, invertThrottle, swapSticks, downThrottle = false, false, false, false, false, false
			classicDrone, swapTriggers, swapStickYTriggers, invertClassicRoll, swapBumpersAndTriggers = false, false, false, false, false
			autoStabilize, autoStabilizeStrength = false, 10.0
			useKeyboardMouse, mouseSens, mouseYawSens, keyboardYawSens = false, 0.08, 0.08, 0.600
			invertMouseX, invertMouseY = false, false
			bindThrottleUp, bindThrottleDown, bindYawLeft, bindYawRight = "W", "S", "A", "D"
			bindMoveForward, bindMoveBack, bindMoveLeft, bindMoveRight = "W", "S", "A", "D"
			bindVertUp, bindVertDown = "SpaceBar", "LeftControl"
			bindSavePos, bindRespawn, bindHitboxOff, bindTempStab, bindToggleOsd = "", "", "", "", ""
			controllerRollSens, showOsd = 1.0, true
			waitingBind = nil
		end
		Gui.endTabItem()
	end

	if Gui.beginTabItem("On Screen Display") then
		showOsd = Gui.checkbox("Toggle All OSD", showOsd)
		Gui.setItemTooltip("Optional keyboard bind is in Keyboard & Mouse. No controller bind.")
		Gui.newLine()
		if Gui.collapsingHeader("Crosshair") then
			showCrosshair = Gui.checkbox("Show Centre Crosshair", showCrosshair)
			Gui.newLine()
			crosshairHSize = sliderR("Horizontal Size##c", crosshairHSize, 1.0, 20.0, 6.0, "chH")
			crosshairVSize = sliderR("Vertical Size##c", crosshairVSize, 1.0, 15.0, 3.3, "chV")
			crosshairThick = sliderR("Thickness##c", crosshairThick, 0.5, 4.0, 1.35, "chT")
			crosshairRot = sliderR("Rotation##c", crosshairRot, 0, 45, 0, "chRot")
		end
		if Gui.collapsingHeader("Throttle Bar") then
			showThrottleBar = Gui.checkbox("Show Throttle Bar", showThrottleBar)
			Gui.newLine()
			throttleWidth = sliderR("Width##tb", throttleWidth, 40.0, 250.0, 122.0, "tbW")
			throttleHeight = sliderR("Height##tb", throttleHeight, 2.0, 12.0, 6.2, "tbH")
			throttleOffX = sliderR("Horizontal Offset##tb", throttleOffX, -150.0, 150.0, 0.0, "tbX")
			throttleOffY = sliderR("Vertical Offset##tb", throttleOffY, -80.0, 80.0, 80.0, "tbY")
			throttleThick = sliderR("Outline Thickness##tb", throttleThick, 0.5, 2.0, 2.0, "tbT")
			throttleRot = sliderRotR("Rotation##tb", throttleRot, -180, 180, 0, "tbRot")
		end
		if Gui.collapsingHeader("Speed Bar") then
			showSpeedBar = Gui.checkbox("Show Speed Bar", showSpeedBar)
			Gui.newLine()
			speedWidth = sliderR("Width##sb", speedWidth, 40.0, 250.0, 122.0, "sbW")
			speedHeight = sliderR("Height##sb", speedHeight, 2.0, 12.0, 6.2, "sbH")
			speedOffX = sliderR("Horizontal Offset##sb", speedOffX, -150.0, 150.0, 0.0, "sbX")
			speedOffY = sliderR("Vertical Offset##sb", speedOffY, -80.0, 80.0, 71.0, "sbY")
			speedThick = sliderR("Outline Thickness##sb", speedThick, 0.5, 2.0, 2.0, "sbT")
			speedRot = sliderRotR("Rotation##sb", speedRot, -180, 180, 0, "sbRot")
			topSpeed = sliderR("Top Speed##sb", topSpeed, 200, 15000, 7500, "sbTop")
			Gui.setItemTooltip("Speed bar fills to this velocity.")
		end
		stickGui("Left Stick", stickL, "L")
		stickGui("Right Stick", stickR, "R")
		Gui.newLine()
		if Gui.button(Icon.Save .. " Save OSD") then
			packOsd(); saveConfig()
		end
		if Gui.button(Icon.Undo .. " Reset OSD") then
			showCrosshair, crosshairHSize, crosshairVSize, crosshairThick, crosshairRot = true, 6.0, 3.3, 1.35, 0
			showThrottleBar, throttleWidth, throttleHeight, throttleOffX, throttleOffY, throttleThick, throttleRot = true, 122.0, 6.2, 0.0, 80.0, 2.0, 0
			showSpeedBar, speedWidth, speedHeight, speedOffX, speedOffY, speedThick, speedRot, topSpeed = true, 122.0, 6.2, 0.0, 71.0, 2.0, 0, 7500
			showOsd = true
			resetStick(stickL); resetStick(stickR)
		end
		Gui.endTabItem()
	end

	if Gui.beginTabItem("Input Processing") then
		Gui.text("These only change how the sticks turn the drone. They do not change thrust or FOV.")
		Gui.newLine()
		overallSensitivity = sliderR("Overall Sensitivity", overallSensitivity, 0, 2.5, 1.2, "overallSens")
		Gui.setItemTooltip("How fast the drone rotates for any stick movement. Higher = faster everywhere.")
		fullStickSpeed = sliderR("Full-Stick Speed", fullStickSpeed, 0, 1.6, 0.15, "fullStick")
		Gui.setItemTooltip("Extra speed only near full stick. Center stays similar; the ends get snappier.")
		centerSoftness = sliderR("Center Softness", centerSoftness, 0, 0.2, 0.07, "centerSoft")
		Gui.setItemTooltip("Softens small stick movements for finer aim. Does not change the maximum speed.")
		if Gui.button(Icon.Undo .. " Def Rate") then
			overallSensitivity, fullStickSpeed, centerSoftness = 1.2, 0.15, 0.07
			config.overallSensitivity, config.fullStickSpeed, config.centerSoftness = overallSensitivity, fullStickSpeed, centerSoftness
			saveConfig()
		end
		if Gui.button(Icon.Save .. "Save Rate") then
			config.overallSensitivity, config.fullStickSpeed, config.centerSoftness = overallSensitivity, fullStickSpeed, centerSoftness
			saveConfig()
		end
		Gui.endTabItem()
	end

	if Gui.beginTabItem("Drone Settings") then
		thrust = sliderR("Vertical Throttle", thrust, 0, 10000, 4000, "thrust")
		Gui.setItemTooltip("Up / down power. In Classic Drone this is halved.")
		reverseThrust = sliderR("Reverse Throttle", reverseThrust, 0, 10000, 3000, "revThrust")
		horizontalThrust = sliderR("Horizontal Throttle", horizontalThrust, 0, 8000, 1500, "horizThrust", "(classic mode)")
		Gui.setItemTooltip("Forward / back / left / right power used only in Classic Drone.")
		gravityStrength = sliderR("Gravity", gravityStrength, 0, 3000, 1000, "grav")
		surfaceFriction = sliderR("Surface Friction", surfaceFriction, 0, 1.000, 0.200, "friction")
		Gui.setItemTooltip("How hard the drone slows when touching geometry")
		droneWidth = sliderR("Drone collision Width", droneWidth, 0, 100, 9, "droneWidth"); Gui.setItemTooltip("xSize x2cm")
		droneLength = sliderR("Drone collision Length", droneLength, 0, 100, 9, "droneLength"); Gui.setItemTooltip("ySize x2cm")
		droneHeight = sliderR("Drone collision Height", droneHeight, 0, 100, 4, "droneHeight"); Gui.setItemTooltip("zSize x2cm")
		hitboxEnabled = Gui.checkbox("Drone Hitbox", hitboxEnabled)
		Gui.setItemTooltip("Turn off to fly through walls and floors")
		grandEffect = Gui.checkbox("GrandEffect", grandEffect)
		if Gui.button(Icon.Undo .. " Def setting##foo1") then
			droneWidth, droneLength, droneHeight, thrust, reverseThrust, gravityStrength = 9, 9, 4, 4000, 3000, 1000
			horizontalThrust, surfaceFriction, hitboxEnabled, grandEffect = 1500, 0.200, true, true
			packDrone(); saveConfig()
		end
		if Gui.button(Icon.Save .. "Save Setting##foo1") then
			packDrone(); saveConfig()
		end
		Gui.endTabItem()
	end

	if Gui.beginTabItem("Camera Settings") then
		if classicDrone then
			pitchOffsetClassic = sliderR("View Angle Up", pitchOffsetClassic, 0, 90, 0, "viewAngleClassic", "(classic mode)")
		else
			pitchOffsetFpv = sliderR("View Angle Up", pitchOffsetFpv, 0, 90, 30, "viewAngleFpv")
		end
		fOV = sliderR("Field of View", fOV, 0, 150, 105, "fOV")
		speedFov = Gui.checkbox("Speed FOV (max 150 at high speed)", speedFov)
		Gui.setItemTooltip("FOV ramps with flight speed only.")
		if speedFov then
			Gui.text("      ")
			Gui.sameLine()
			osdWobble = Gui.checkbox("OSD Wobble", osdWobble)
			Gui.setItemTooltip("When on, OSD lags/drifts with FOV. Off = OSD stays locked on screen.")
		end
		showNameTags = Gui.checkbox("Show name tags", showNameTags)
		cameraSmooth = Gui.checkbox("Camera Smoothness", cameraSmooth)
		if cameraSmooth then
			Gui.text("      ")
			Gui.sameLine()
			cameraSmoothAmount = sliderR("Smoothness", cameraSmoothAmount, 0.01, 0.50, 0.12, "camSmooth")
		end
		if Gui.button(Icon.Undo .. " Def setting##foo2") then
			pitchOffsetFpv, pitchOffsetClassic, fOV, showNameTags, speedFov, osdWobble = 30, 0, 105, true, false, false
			cameraSmooth, cameraSmoothAmount = false, 0.12
			packCamera(); saveConfig()
		end
		if Gui.button(Icon.Save .. "Save Setting##foo2") then
			packCamera(); saveConfig()
		end
		Gui.endTabItem()
	end

	if Gui.beginTabItem("Colour") then
		if Gui.collapsingHeader("Crosshair") then rgbRow("Centre Crosshair", colCH, {0.95, 0.95, 0.95}) end
		if Gui.collapsingHeader("Throttle Bar") then
			rgbRow("Throttle Outline", colTBOut, {1.0, 1.0, 1.0}); Gui.newLine()
			rgbRow("Throttle Fill", colTBFill, {0.40, 0.70, 1.0})
		end
		if Gui.collapsingHeader("Speed Bar") then
			rgbRow("Speed Outline", colSBOut, {1.0, 1.0, 1.0}); Gui.newLine()
			rgbRow("Speed Fill", colSBFill, {0.55, 1.00, 0.55})
		end
		stickColourGui("Left Stick", stickL, "Left")
		stickColourGui("Right Stick", stickR, "Right")
		Gui.newLine()
		if Gui.button(Icon.Save .. " Save Colours") then
			packColours(); saveConfig()
		end
		if Gui.button(Icon.Undo .. " Reset Colours") then
			colCH, colTBOut, colTBFill = {0.95, 0.95, 0.95}, {1.0, 1.0, 1.0}, {0.40, 0.70, 1.0}
			colSBOut, colSBFill = {1.0, 1.0, 1.0}, {0.55, 1.00, 0.55}
			resetStickCols(stickL); resetStickCols(stickR)
		end
		Gui.endTabItem()
	end
	Gui.endTabBar()
end

function Start()
	currentFov, hudFov = fOV, fOV
	camera.fieldOfView = currentFov
	camera.fieldOfViewSmoothing = 0
	dronePos = defPosition
	visCamPos = defPosition
	camera.position = defPosition
	camera.rotation = defRotation
end

local MayStartFlag, startOnce = false, false
local function startTest()
	MayStartFlag = not startOnce
	startOnce = true
end

local function drawLineCol(a, b, col, thick)
	WorldDraw.drawLine(a, b, col[1], col[2], col[3], thick, 0.05)
end

local function rot2(x, y, deg)
	local a = math.rad(deg or 0)
	local c, s = math.cos(a), math.sin(a)
	return x * c - y * s, x * s + y * c
end

local function drawCrosshair(camPos, camRot, distance, sc)
	local f, r, u = camRot:getForwardVector(), camRot:getRightVector(), camRot:getUpVector()
	local c = camPos + f * distance
	local hx, hy = rot2(crosshairHSize * sc, 0, crosshairRot)
	local vx, vy = rot2(0, crosshairVSize * sc, crosshairRot)
	drawLineCol(c - r * hx + u * hy, c + r * hx - u * hy, colCH, crosshairThick * sc)
	drawLineCol(c - r * vx + u * vy, c + r * vx - u * vy, colCH, crosshairThick * sc)
end

local function drawHudBar(camPos, camRot, distance, sc, value, width, height, offX, offY, thick, rotDeg, colOut, colFill)
	local f, r, u = camRot:getForwardVector(), camRot:getRightVector(), camRot:getUpVector()
	local bar = camPos + f * distance + r * (offX * sc) - u * (offY * sc)
	local rx, ry = rot2(1, 0, rotDeg)
	local ux, uy = rot2(0, 1, rotDeg)
	local along = r * rx - u * ry
	local across = r * ux - u * uy
	local hw, hh = width * 0.5 * sc, height * 0.5 * sc
	local bl = bar - along * hw - across * hh
	local br = bar + along * hw - across * hh
	local tl = bar - along * hw + across * hh
	local tr = bar + along * hw + across * hh
	local ot = thick * sc
	drawLineCol(bl, br, colOut, ot); drawLineCol(br, tr, colOut, ot)
	drawLineCol(tr, tl, colOut, ot); drawLineCol(tl, bl, colOut, ot)
	local fillAmount = math.clamp(math.abs(value), 0, 1)
	if fillAmount <= 0.01 then return end
	local inset = (borderInset - 0.1) * sc
	local fillW = (width * sc - inset * 2) * fillAmount
	local fillLeft = bar - along * (hw - inset)
	local fillRight = fillLeft + along * fillW
	local fillHalfH = hh - borderInset * 0.95 * sc
	for i = 0, 5 do
		local yOff = -fillHalfH + (fillHalfH * 2) * (i / 5)
		drawLineCol(fillLeft + across * yOff, fillRight + across * yOff, colFill, 1.7 * sc)
	end
end

local function drawCircleAt(camPos, camRot, distance, ox, oy, radius, segments, thickness, col, rotDeg)
	local f, r, u = camRot:getForwardVector(), camRot:getRightVector(), camRot:getUpVector()
	local center = camPos + f * distance + r * ox - u * oy
	local segs = math.max(math.floor(segments), 3)
	local spin = math.rad(rotDeg or 0)
	local function pt(i)
		local a = (i / segs) * math.pi * 2 + spin
		return center + r * (math.cos(a) * radius) + u * (math.sin(a) * radius)
	end
	local prev = pt(0)
	for i = 1, segs do
		local nxt = pt(i)
		drawLineCol(prev, nxt, col, thickness)
		prev = nxt
	end
end

local function drawStickCrossAt(camPos, camRot, distance, ox, oy, hSize, vSize, thickness, col, rotDeg)
	local f, r, u = camRot:getForwardVector(), camRot:getRightVector(), camRot:getUpVector()
	local c = camPos + f * distance + r * ox - u * oy
	local hx, hy = rot2(hSize, 0, rotDeg)
	local vx, vy = rot2(0, vSize, rotDeg)
	drawLineCol(c - r * hx + u * hy, c + r * hx - u * hy, col, thickness)
	drawLineCol(c - r * vx + u * vy, c + r * vx - u * vy, col, thickness)
end

local function drawStick(s, signX, ax, ay, camPos, camRot, hudDistance, lineDistance, lineScale, f, r, u, sc)
	local outerR, innerR = outerRadiusBase * s.size * sc, innerRadiusBase * s.size * sc
	local travel = math.max(outerR - innerR, 0)
	local bx, by = signX * s.offX * sc, s.offY * sc
	local ix, iy = bx + ax * travel, by - ay * travel
	local a = camPos + f * lineDistance + r * (bx * lineScale) - u * (by * lineScale)
	local b = camPos + f * lineDistance + r * (ix * lineScale) - u * (iy * lineScale)
	if s.showOuter then drawCircleAt(camPos, camRot, hudDistance, bx, by, outerR, s.outerSeg, s.outerThick * sc, s.colOuter, s.zoneRot) end
	if s.showLine then drawLineCol(a, b, s.colLine, s.lineThick * sc) end
	if s.showInner then drawCircleAt(camPos, camRot, hudDistance, ix, iy, innerR, s.innerSeg, s.innerThick * sc, s.colInner, s.stickRot) end
	if s.showCross then drawStickCrossAt(camPos, camRot, hudDistance, bx, by, s.crossH * s.size * sc, s.crossV * s.size * sc, s.crossThick * sc, s.colCross, s.crossRot) end
end

local function updateSpeedFov(dt)
	local target = fOV
	if speedFov then
		local speed = velocity:length()
		local startSpeed = 400
		local fullSpeed = 4200
		local speedT = math.clamp((speed - startSpeed) / (fullSpeed - startSpeed), 0, 1) ^ 1.45
		target = math.clamp(fOV + (132 - fOV) * speedT, math.min(fOV, 132), 132)
	end
	dt = math.max(dt or 0.016, 0.0001)
	currentFov += (target - currentFov) * (1 - math.exp(-dt * 7))
	if speedFov and osdWobble then
		local slowing = target < currentFov or currentFov < hudFov
		local hudK = slowing and 6.8 or 3.2
		hudFov += (currentFov - hudFov) * (1 - math.exp(-dt * hudK))
	else
		hudFov = liveCameraFov()
	end
end

local function droneMovement(dt: number)
	local up, down = droneRotation:getUpVector(), -droneRotation:getUpVector()
	collisionEnabled = hitboxEnabled and not (gamepadHeld("DPad_Down") or keyHeld(bindHitboxOff))
	if dronePos == nil then dronePos = camera.position end
	local oldPos, oldPts, oldRot = dronePos, collisionPoints, droneRotation
	local yawIn, thrIn, rollIn, pitchIn, moveX, moveY
	yawIn, thrIn, rollIn, pitchIn, stickLx, stickLy, stickRx, stickRy, moveX, moveY = getMappedInputs()
	local sm = 60
	droneRotation = droneRotation * Quat.fromEuler(
		CalcBetaFlightRate(rollIn, overallSensitivity, fullStickSpeed, centerSoftness) * sm * dt,
		CalcBetaFlightRate(pitchIn, overallSensitivity, fullStickSpeed, centerSoftness) * sm * dt,
		CalcBetaFlightRate(yawIn, overallSensitivity, fullStickSpeed, centerSoftness) * sm * dt
	)
	local tempStab = gamepadHeld("DPad_Left") or keyHeld(bindTempStab)
	local stabNow = classicDrone and (autoStabilize or tempStab)
	local stabPower = tempStab and 30 or autoStabilizeStrength
	if stabNow then
		local worldUp = gravity.upDirection
		local droneUp = droneRotation:getUpVector()
		local fwd = droneRotation:getForwardVector()
		local right = droneRotation:getRightVector()
		local ax = droneUp.y * worldUp.z - droneUp.z * worldUp.y
		local ay = droneUp.z * worldUp.x - droneUp.x * worldUp.z
		local az = droneUp.x * worldUp.y - droneUp.y * worldUp.x
		local axis = Vec3.new(ax, ay, az)
		local align = math.clamp(droneUp:dot(worldUp), -1, 1)
		if axis:length() < 0.0008 and align < 0 then
			axis = fwd
		end
		local gain = stabPower * 8.5 * dt
		local rollCorr = math.clamp(-axis:dot(fwd) * gain, -0.45, 0.45)
		local pitchCorr = math.clamp(-axis:dot(right) * gain, -0.45, 0.45)
		if math.abs(rollCorr) > 0.0002 or math.abs(pitchCorr) > 0.0002 then
			droneRotation = droneRotation * Quat.fromEuler(rollCorr, pitchCorr, 0)
		end
	end
	velocity -= gravity.upDirection * gravityStrength * dt
	if classicDrone then
		local worldUp = gravity.upDirection
		local fwd = droneRotation:getForwardVector()
		local horizFwd, fwdMag = safeNormalize(fwd - worldUp * fwd:dot(worldUp))
		if fwdMag < 0.0001 then
			local alt = droneRotation:getUpVector()
			horizFwd = select(1, safeNormalize(alt - worldUp * alt:dot(worldUp)))
		end
		local right = droneRotation:getRightVector()
		local horizRight, rightMag = safeNormalize(right - worldUp * right:dot(worldUp))
		if rightMag < 0.0001 then
			horizRight = right
		end
		local thrustAxis = math.clamp(thrIn, -1, 1)
		currentThrottle = thrustAxis
			if up:dot(worldUp) > 0.2 then
			velocity += up * gravityStrength * dt
		end
		if math.abs(thrustAxis) < 0.04 then
			local vertVel = velocity:dot(worldUp)
			velocity -= worldUp * vertVel * (1 - math.exp(-dt * 3.2))
		else
			local vertPower = (thrustAxis < 0 and reverseThrust or thrust) * 0.5
			velocity += worldUp * thrustAxis * vertPower * dt
		end
		local mx = math.clamp(moveX, -1, 1)
		local my = math.clamp(moveY, -1, 1)
		if math.abs(mx) < 0.04 and math.abs(my) < 0.04 then
			local vertVel = velocity:dot(worldUp)
			local horizVel = velocity - worldUp * vertVel
			velocity -= horizVel * (1 - math.exp(-dt * 1.35))
		else
			velocity += horizFwd * my * horizontalThrust * dt
			velocity += horizRight * mx * horizontalThrust * dt
		end
	else
		local thrustAxis = math.clamp(thrIn, -1, 1)
		if thrustAxis < 0 and not downThrottle then thrustAxis = 0 end
		currentThrottle = thrustAxis
		local usedThrust = thrustAxis < 0 and reverseThrust or thrust
		velocity += up * math.sign(thrustAxis) * (thrustAxis ^ 2) * usedThrust * dt
		local geh = camera:castRay(dronePos, down * (droneWidth + droneLength) / 2)
		if grandEffect and geh.successful then
			local g = math.clamp(((droneWidth + droneLength) / 2 - geh.position:distance(dronePos)) ^ 2, 0, 1)
			velocity += up * math.sign(thrustAxis) * (thrustAxis ^ 2) * g * dt
		end
	end
	velocity *= 0.993

	local velDir, velMag = safeNormalize(velocity)
	local localPts = {
		Vec3.new(droneWidth, droneLength, droneHeight), Vec3.new(-droneWidth, droneLength, droneHeight),
		Vec3.new(droneWidth, droneLength, -droneHeight), Vec3.new(-droneWidth, droneLength, -droneHeight),
		Vec3.new(droneWidth, -droneLength, droneHeight), Vec3.new(-droneWidth, -droneLength, droneHeight),
		Vec3.new(droneWidth, -droneLength, -droneHeight), Vec3.new(-droneWidth, -droneLength, -droneHeight)
	}
	for i = 1, 8 do collisionPoints[i] = dronePos + droneRotation:rotateVector(localPts[i]) end

	local function insideOBB(point, center, axes, ext)
		local rel = point - center
		for i = 1, 3 do if math.abs(rel:dot(axes[i])) > ext[i] then return false end end
		return true
	end
	local obbC = dronePos
	local obbA = {droneRotation:getRightVector(), droneRotation:getUpVector(), droneRotation:getForwardVector()}
	local obbE = {droneWidth * 2.1, droneHeight * 2.1, droneLength * 2.1}
	local totalRef, hitCount, touching = Vec3.zeroVector, 0, false

	if collisionEnabled and velMag > 0.0001 then
		for i = 1, 8 do
			local rotD = droneRotation:rotateVector(localPts[i]) - oldRot:rotateVector(localPts[i])
			local already = camera:castRay(oldPts[i] - (velDir * 2), collisionPoints[i])
			local hit = camera:castRay(collisionPoints[i] - (velDir - rotD) * 100, collisionPoints[i])
			if already.successful and not isInsideAnyGate(already.position) then
				totalRef = (totalRef + (velocity - already.normal * (1.35 * velocity:dot(already.normal))) - rotD) * 0.98
				hitCount += 1; touching = true
			elseif hit.successful and not isInsideAnyGate(hit.position) and insideOBB(hit.position, obbC, obbA, obbE) then
				totalRef = (totalRef + (velocity - hit.normal * (1.35 * velocity:dot(hit.normal)) + hit.normal * collisionPoints[i]:distance(hit.position)) - rotD) * 0.98
				hitCount += 1; touching = true
			end
		end
	end
	if hitCount > 0 then velocity = totalRef / hitCount end

	local desired = dronePos + velocity * dt
	if collisionEnabled then
		local moveHit = camera:castRay(oldPos, desired)
		if moveHit.successful and not isInsideAnyGate(moveHit.position) then
			desired = moveHit.position + moveHit.normal * 4.0
			local vn = velocity:dot(moveHit.normal)
			if vn < 0 then velocity -= moveHit.normal * vn * 1.35 end
			touching = true
		end
		local floorHit = camera:castRay(desired, desired + gravity.upDirection * -math.max(droneHeight * 2, 8))
		if floorHit.successful and not isInsideAnyGate(floorHit.position) and desired:distance(floorHit.position) < droneHeight + 2 then
			desired = floorHit.position + floorHit.normal * (droneHeight + 2)
			local vn = velocity:dot(floorHit.normal)
			if vn < 0 then velocity -= floorHit.normal * vn end
			touching = true
		end
	end
	if touching then velocity *= (1 / (1 + math.max(surfaceFriction, 0) * 0.8)) end
	updateSpeedFov(dt)
	camera.fieldOfView = currentFov
	camera.fieldOfViewSmoothing = 0
	local targetRot = droneRotation * Quat.fromEuler(0, classicDrone and pitchOffsetClassic or pitchOffsetFpv, 0)
	dronePos = desired
	if cameraSmooth then
		if visCamPos == nil then visCamPos = dronePos end
		local ht = math.max(cameraSmoothAmount * 0.28, 0.002)
		local a = 1 - math.exp(-0.693147 / ht * math.max(dt, 0.0001))
		visCamPos = visCamPos + (dronePos - visCamPos) * a
		camera.position, camera.rotation = visCamPos, targetRot
	else
		visCamPos = dronePos
		camera.position, camera.rotation = dronePos, targetRot
	end
end

function tick(dt: number)
	if not camera.isActive and not camera.isFollowed then return end
	startTest()
	if MayStartFlag then Start() end
	camera.positionSmoothing, camera.rotationSmoothing = 0, 0
	camera.fieldOfViewSmoothing = 0
	camera.showNameTags = showNameTags
	postProcessSettings.depthOfFieldFocalDistance = 0
	droneMovement(dt)
	WorldDraw.clear()
	local sc, hudD = hudFovScale(), 120.0
	local lineD, lineS = hudD + 1.5 * sc, (hudD + 1.5 * sc) / hudD
	local p, rot = camera.position, camera.rotation
	local osdDown = keyHeld(bindToggleOsd)
	if osdDown and not prevOsdToggle then showOsd = not showOsd end
	prevOsdToggle = osdDown

	if showOsd then
	if showCrosshair then drawCrosshair(p, rot, hudD, sc) end
	if showThrottleBar then drawHudBar(p, rot, hudD, sc, currentThrottle, throttleWidth, throttleHeight, throttleOffX, throttleOffY, throttleThick, throttleRot, colTBOut, colTBFill) end
	if showSpeedBar then
		local speedT = math.clamp(velocity:length() / math.max(topSpeed, 1), 0, 1)
		drawHudBar(p, rot, hudD, sc, speedT, speedWidth, speedHeight, speedOffX, speedOffY, speedThick, speedRot, colSBOut, colSBFill)
	end
	local f, r, u = rot:getForwardVector(), rot:getRightVector(), rot:getUpVector()
	drawStick(stickL, -1, stickLx, stickLy, p, rot, hudD, lineD, lineS, f, r, u, sc)
	drawStick(stickR,  1, stickRx, stickRy, p, rot, hudD, lineD, lineS, f, r, u, sc)
	end
	if Input.getKey(Input.Key.LeftAlt) and Input.getKey(Input.Key.LeftMouseButton) then
		local hit = camera:castRayFromMouse()
		if hit.successful then debug(hit.position) end
	end
	if gamepadDown("DPad_Up") or keyDown(bindSavePos) then savePosition() end
	if gamepadDown("DPad_Right") or keyDown(bindRespawn) then respawnDrone() end
end

function CalcBetaFlightRate(value, overallSensitivity, fullStickSpeed, centerSoftness)
	local sign, absV = math.sign(value), math.abs(value)
	local endBoost = 1.0 / math.max(1.0 - (absV * fullStickSpeed), 0.05)
	local shaped = (absV^4 * centerSoftness) + absV * (1 - centerSoftness)
	return 200 * shaped * overallSensitivity * endBoost * (math.pi / 180) * sign
end

function savePosition()
	config.position = dronePos or camera.position
end

function respawnDrone()
	dronePos = config.position or Vec3.new(209, 2450, -28225)
	visCamPos = dronePos
	camera.position = dronePos
	velocity = Vec3.zeroVector
end
