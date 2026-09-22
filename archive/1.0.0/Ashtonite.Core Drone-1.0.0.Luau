-- @name Ashtonite365's PFV+
-- @credits Scha's Drone Camera + Grok
-- @author Another Axiom

metadata = {
	name = "Ashtonite365's FPV+",
	description = "Simulates a 5″ FPV drone in acro mode",
	author = "Ashtonite365",
	defaultKeybind = "",
}

local defPosition = config.position or Vec3.new(209, 2500, -28225)
local defRotation = Quat.fromEuler(0, 0, 90)
local droneRotation = Quat.fromEuler(0, 0, 90)
local velocity = Vec3.zeroVector

local function cfg(k, d) if config[k] == nil then return d end return config[k] end

local pitchOffset = cfg("pitchOffset", 30)
local thrust = cfg("thrust", 4000)
local reverseThrust = cfg("reverseThrust", 3000)
local gravityStrength = cfg("gravityStrength", 1000)
local surfaceFriction = cfg("surfaceFriction", 0.200)
local fOV = cfg("fOV", 105)
local currentFov, hudFov = fOV, fOV
local showNameTags = cfg("showNameTags", true)
local grandEffect = cfg("grandEffect", true)
local droneWidth, droneLength, droneHeight = cfg("droneWidth", 9), cfg("droneLength", 9), cfg("droneHeight", 4)
local rcRate, superRate, expo = cfg("rcRate", 1.2), cfg("superRate", 0.15), cfg("expo", 0.07)
local mouseSens = cfg("mouseSens", 0.08)
local mouseYawSens = cfg("mouseYawSens", cfg("mouseRollSens", 0.08))
local keyboardYawSens = cfg("keyboardYawSens", 1.0)

local invertPitch, invertYaw = cfg("invertPitch", false), cfg("invertYaw", false)
local invertRoll, invertThrottle = cfg("invertRoll", false), cfg("invertThrottle", false)
local invertMouseX, invertMouseY = cfg("invertMouseX", false), cfg("invertMouseY", false)
local swapSticks, downThrottle = cfg("swapSticks", false), cfg("downThrottle", false)
local hitboxEnabled, useKeyboardMouse = cfg("hitboxEnabled", true), cfg("useKeyboardMouse", false)
local speedFov = cfg("speedFov", false)

local bindThrottleUp, bindThrottleDown = cfg("bindThrottleUp", "W"), cfg("bindThrottleDown", "S")
local bindYawLeft, bindYawRight = cfg("bindYawLeft", "A"), cfg("bindYawRight", "D")
local bindSavePos, bindRespawn, bindHitboxOff = cfg("bindSavePos", ""), cfg("bindRespawn", ""), cfg("bindHitboxOff", "")
local waitingBind = nil

local showCrosshair = cfg("showCrosshair", true)
local crosshairHSize, crosshairVSize, crosshairThick = cfg("crosshairHSize", 6.0), cfg("crosshairVSize", 3.3), cfg("crosshairThick", 1.35)
local colCH = {cfg("colCH_R", 0.95), cfg("colCH_G", 0.95), cfg("colCH_B", 0.95)}
local showThrottleBar = cfg("showThrottleBar", true)
local throttleWidth, throttleHeight = cfg("throttleWidth", 122.0), cfg("throttleHeight", 6.2)
local throttleDown, throttleThick = cfg("throttleDown", 78.0), cfg("throttleThick", 2.0)
local borderInset = 1.9
local colTBOut = {cfg("colTBOut_R", 1), cfg("colTBOut_G", 1), cfg("colTBOut_B", 1)}
local colTBFill = {cfg("colTBFill_R", 0.40), cfg("colTBFill_G", 0.70), cfg("colTBFill_B", 1)}

local HUD_REF_FOV, outerRadiusBase, innerRadiusBase = 105.0, 28.0, 7.0

local function makeStick(side)
	return {
		showOuter = cfg("showOuter"..side, true), showInner = cfg("showInner"..side, true),
		showCross = cfg("showCross"..side, true), showLine = cfg("showLine"..side, true),
		outerSeg = cfg("outerSeg"..side, 18), outerThick = cfg("outerThick"..side, 1.8),
		innerSeg = cfg("innerSeg"..side, 14), innerThick = cfg("innerThick"..side, 1.5),
		size = cfg("stickSize"..side, 1.0),
		crossH = cfg("crossHSize"..side, 4.0), crossV = cfg("crossVSize"..side, 4.0), crossThick = cfg("crossThick"..side, 1.3),
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
}

local function safeNormalize(v)
	local mag = v:length()
	if mag < 0.0001 then return Vec3.zeroVector, 0 end
	return v / mag, mag
end

local function hudFovScale()
	return math.tan(math.rad(math.clamp(hudFov, 1, 170)) * 0.5) / math.tan(math.rad(HUD_REF_FOV) * 0.5)
end

local function sliderR(label, value, minV, maxV, def, id)
	value = Gui.sliderFloat(label, value, minV, maxV)
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
	config["crossThick"..side], config["lineThick"..side] = s.crossThick, s.lineThick
	config["offsetX"..side], config["offsetY"..side] = s.offX, s.offY
end

local function resetStick(s)
	s.showOuter, s.showInner, s.showCross, s.showLine = true, true, true, true
	s.outerSeg, s.outerThick, s.innerSeg, s.innerThick = 18, 1.8, 14, 1.5
	s.size, s.crossH, s.crossV, s.crossThick = 1.0, 4.0, 4.0, 1.3
	s.lineThick, s.offX, s.offY = 1.4, 105.0, 52.0
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
	s.showOuter = Gui.checkbox("Show Outer Circle##"..id, s.showOuter)
	s.showInner = Gui.checkbox("Show Inner Circle##"..id, s.showInner)
	s.showCross = Gui.checkbox("Show Stick Crosshair##"..id, s.showCross)
	s.showLine  = Gui.checkbox("Show Stick Line##"..id, s.showLine)
	Gui.newLine(); Gui.text("Position & Size")
	s.size = sliderR("Stick Size##"..id, s.size, 0.5, 2.0, 1.0, "size"..id)
	s.offX = sliderR("Horizontal Offset##"..id, s.offX, 60.0, 140.0, 105.0, "offX"..id)
	s.offY = sliderR("Vertical Offset##"..id, s.offY, 20.0, 90.0, 52.0, "offY"..id)
	Gui.newLine(); Gui.text("Outer Circle")
	s.outerSeg = sliderR("Quality (Segments)##o"..id, s.outerSeg, 8, 50, 18, "oSeg"..id)
	s.outerThick = sliderR("Thickness##o"..id, s.outerThick, 0.5, 4.0, 1.8, "oThk"..id)
	Gui.newLine(); Gui.text("Inner Circle")
	s.innerSeg = sliderR("Quality (Segments)##i"..id, s.innerSeg, 8, 50, 14, "iSeg"..id)
	s.innerThick = sliderR("Thickness##i"..id, s.innerThick, 0.5, 4.0, 1.5, "iThk"..id)
	Gui.newLine(); Gui.text("Stick Crosshair")
	s.crossH = sliderR("Horizontal Size##c"..id, s.crossH, 1.0, 15.0, 4.0, "cH"..id)
	s.crossV = sliderR("Vertical Size##c"..id, s.crossV, 1.0, 15.0, 4.0, "cV"..id)
	s.crossThick = sliderR("Thickness##c"..id, s.crossThick, 0.5, 4.0, 1.3, "cT"..id)
	Gui.newLine(); Gui.text("Stick Line")
	s.lineThick = sliderR("Line Thickness##"..id, s.lineThick, 0.5, 4.0, 1.4, "line"..id)
end

local function stickColourGui(title, s, side)
	if not Gui.collapsingHeader(title) then return end
	rgbRow(side.." Outer Circle", s.colOuter, {0.95, 0.95, 0.95}); Gui.newLine()
	rgbRow(side.." Inner Circle", s.colInner, {0.95, 0.95, 0.95}); Gui.newLine()
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

local function getMappedInputs()
	local lx, ly, rx, ry
	if useKeyboardMouse then
		lx = 0
		if keyHeld(bindYawLeft) then lx -= keyboardYawSens end
		if keyHeld(bindYawRight) then lx += keyboardYawSens end
		ly = 0
		if keyHeld(bindThrottleDown) then ly -= 1 end
		if keyHeld(bindThrottleUp) then ly += 1 end
		local mx, my = readMouseDelta()
		rx, ry = mx, my
	else
		lx = Input.getAnalog(Input.Gamepad.LeftX)
		ly = Input.getAnalog(Input.Gamepad.LeftY)
		rx = Input.getAnalog(Input.Gamepad.RightX)
		ry = Input.getAnalog(Input.Gamepad.RightY)
	end
	local yawIn, thrIn, rollIn, pitchIn = lx, ly, rx, ry
	if swapSticks then yawIn, thrIn, rollIn, pitchIn = rx, ry, lx, ly end
	if invertYaw then yawIn = -yawIn end
	if invertThrottle then thrIn = -thrIn end
	if invertRoll then rollIn = -rollIn end
	if invertPitch then pitchIn = -pitchIn end
	return yawIn, thrIn, rollIn, pitchIn, lx, ly, rx, ry
end

function onGui()
	pollNewBind()
	if not Gui.beginTabBar("MainTabs") then return end

	if Gui.beginTabItem("Controls") then
		Gui.text(useKeyboardMouse and "Active input: Keyboard + Mouse" or "Active input: Controller")
		useKeyboardMouse = Gui.checkbox("Use Keyboard + Mouse", useKeyboardMouse)
		downThrottle = Gui.checkbox("Down Throttle", downThrottle)
		Gui.newLine()
		if Gui.collapsingHeader("Controller") then
			Gui.text("Left stick = throttle / yaw")
			Gui.text("Right stick = pitch / roll")
			Gui.text("DPad_Up = save position")
			Gui.text("DPad_Right = respawn drone")
			Gui.text("DPad_Down = temp disable hitbox")
			Gui.newLine()
			invertPitch = Gui.checkbox("Invert Pitch", invertPitch)
			invertYaw = Gui.checkbox("Invert Yaw", invertYaw)
			invertRoll = Gui.checkbox("Invert Roll", invertRoll)
			invertThrottle = Gui.checkbox("Invert Throttle", invertThrottle)
			swapSticks = Gui.checkbox("Swap Left / Right Stick Controls", swapSticks)
		end
		if Gui.collapsingHeader("Keyboard & Mouse") then
			Gui.text("Click a bind, then press a key. ESC sets it to blank.")
			Gui.newLine()
			bindRow("Throttle Up", bindThrottleUp, "W", "thrUp")
			bindRow("Throttle Down", bindThrottleDown, "S", "thrDown")
			bindRow("Yaw Left", bindYawLeft, "A", "yawL")
			bindRow("Yaw Right", bindYawRight, "D", "yawR")
			keyboardYawSens = sliderR("Keyboard Yaw Sensitivity", keyboardYawSens, 0.01, 1.0, 1.0, "keyYawSens")
			Gui.newLine(); Gui.text("DPad equivalents")
			bindRow("Save Position", bindSavePos, "", "save")
			bindRow("Respawn Drone", bindRespawn, "", "respawn")
			bindRow("Temp Disable Hitbox", bindHitboxOff, "", "hitbox")
			Gui.newLine(); Gui.text("Mouse X = roll    Mouse Y = pitch")
			invertMouseX = Gui.checkbox("Invert Mouse X (Roll)", invertMouseX)
			invertMouseY = Gui.checkbox("Invert Mouse Y (Pitch)", invertMouseY)
			mouseSens = sliderR("Mouse Pitch Sensitivity", mouseSens, 0.01, 0.4, 0.08, "mouseSens")
			mouseYawSens = sliderR("Mouse Roll Sensitivity", mouseYawSens, 0.01, 0.4, 0.08, "mouseYawSens")
			Gui.newLine()
			if Gui.button(Icon.Undo .. " Reset M&K Defaults") then
				bindThrottleUp, bindThrottleDown, bindYawLeft, bindYawRight = "W", "S", "A", "D"
				bindSavePos, bindRespawn, bindHitboxOff = "", "", ""
				invertMouseX, invertMouseY, mouseSens, mouseYawSens, keyboardYawSens = false, false, 0.08, 0.08, 1.0
				waitingBind = nil
			end
		end
		Gui.newLine()
		if Gui.button(Icon.Save .. " Save Controls") then
			config.invertPitch, config.invertYaw, config.invertRoll = invertPitch, invertYaw, invertRoll
			config.invertThrottle, config.swapSticks, config.downThrottle = invertThrottle, swapSticks, downThrottle
			config.invertMouseX, config.invertMouseY = invertMouseX, invertMouseY
			config.useKeyboardMouse, config.mouseSens, config.mouseYawSens, config.keyboardYawSens = useKeyboardMouse, mouseSens, mouseYawSens, keyboardYawSens
			config.bindThrottleUp, config.bindThrottleDown = bindThrottleUp, bindThrottleDown
			config.bindYawLeft, config.bindYawRight = bindYawLeft, bindYawRight
			config.bindSavePos, config.bindRespawn, config.bindHitboxOff = bindSavePos, bindRespawn, bindHitboxOff
			saveConfig()
		end
		if Gui.button(Icon.Undo .. " Reset Controls") then
			invertPitch, invertYaw, invertRoll, invertThrottle, swapSticks, downThrottle = false, false, false, false, false, false
			useKeyboardMouse, mouseSens, mouseYawSens, keyboardYawSens = false, 0.08, 0.08, 1.0
			invertMouseX, invertMouseY = false, false
			bindThrottleUp, bindThrottleDown, bindYawLeft, bindYawRight = "W", "S", "A", "D"
			bindSavePos, bindRespawn, bindHitboxOff = "", "", ""
			waitingBind = nil
		end
		Gui.endTabItem()
	end

	if Gui.beginTabItem("On Screen Display") then
		if Gui.collapsingHeader("Crosshair") then
			showCrosshair = Gui.checkbox("Show Centre Crosshair", showCrosshair)
			Gui.newLine()
			crosshairHSize = sliderR("Horizontal Size##c", crosshairHSize, 1.0, 20.0, 6.0, "chH")
			crosshairVSize = sliderR("Vertical Size##c", crosshairVSize, 1.0, 15.0, 3.3, "chV")
			crosshairThick = sliderR("Thickness##c", crosshairThick, 0.5, 4.0, 1.35, "chT")
		end
		if Gui.collapsingHeader("Throttle Bar") then
			showThrottleBar = Gui.checkbox("Show Throttle Bar", showThrottleBar)
			Gui.newLine()
			throttleWidth = sliderR("Width", throttleWidth, 40.0, 250.0, 122.0, "tbW")
			throttleHeight = sliderR("Height", throttleHeight, 2.0, 12.0, 6.2, "tbH")
			throttleDown = sliderR("Vertical Offset##throttle", throttleDown, 20.0, 83.8, 78.0, "tbD")
			throttleThick = sliderR("Outline Thickness", throttleThick, 0.5, 2.0, 2.0, "tbT")
		end
		stickGui("Left Stick", stickL, "L")
		stickGui("Right Stick", stickR, "R")
		Gui.newLine()
		if Gui.button(Icon.Save .. " Save OSD") then
			config.showCrosshair, config.crosshairHSize, config.crosshairVSize, config.crosshairThick = showCrosshair, crosshairHSize, crosshairVSize, crosshairThick
			config.showThrottleBar, config.throttleWidth, config.throttleHeight, config.throttleDown, config.throttleThick = showThrottleBar, throttleWidth, throttleHeight, throttleDown, throttleThick
			saveStick("L", stickL); saveStick("R", stickR); saveConfig()
		end
		if Gui.button(Icon.Undo .. " Reset OSD") then
			showCrosshair, crosshairHSize, crosshairVSize, crosshairThick = true, 6.0, 3.3, 1.35
			showThrottleBar, throttleWidth, throttleHeight, throttleDown, throttleThick = true, 122.0, 6.2, 78.0, 2.0
			resetStick(stickL); resetStick(stickR)
		end
		Gui.endTabItem()
	end

	if Gui.beginTabItem("Rate Settings") then
		rcRate = sliderR("RC Rate", rcRate, 0, 2.5, 1.2, "rcRate")
		superRate = sliderR("Super Rate", superRate, 0, 1.6, 0.15, "superRate")
		expo = sliderR("Expo", expo, 0, 0.2, 0.07, "expo")
		if Gui.button(Icon.Undo .. " Def Rate") then rcRate, superRate, expo = 1.2, 0.15, 0.07; config.rcRate, config.expo, config.superRate = rcRate, expo, superRate; saveConfig() end
		if Gui.button(Icon.Save .. "Save Rate") then config.rcRate, config.expo, config.superRate = rcRate, expo, superRate; saveConfig() end
		Gui.endTabItem()
	end

	if Gui.beginTabItem("Drone Settings") then
		thrust = sliderR("Thrust", thrust, 0, 10000, 4000, "thrust")
		reverseThrust = sliderR("Reverse Thrust", reverseThrust, 0, 10000, 3000, "revThrust")
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
			surfaceFriction, hitboxEnabled, grandEffect = 0.200, true, true
			config.droneWidth, config.droneLength, config.droneHeight = droneWidth, droneLength, droneHeight
			config.thrust, config.reverseThrust, config.gravityStrength = thrust, reverseThrust, gravityStrength
			config.surfaceFriction, config.hitboxEnabled, config.grandEffect = surfaceFriction, hitboxEnabled, grandEffect
			saveConfig()
		end
		if Gui.button(Icon.Save .. "Save Setting##foo1") then
			config.droneWidth, config.droneLength, config.droneHeight = droneWidth, droneLength, droneHeight
			config.thrust, config.reverseThrust, config.gravityStrength = thrust, reverseThrust, gravityStrength
			config.surfaceFriction, config.hitboxEnabled, config.grandEffect = surfaceFriction, hitboxEnabled, grandEffect
			saveConfig()
		end
		Gui.endTabItem()
	end

	if Gui.beginTabItem("Camera Settings") then
		pitchOffset = sliderR("Pitch Offset", pitchOffset, 0, 90, 30, "pitchOffset")
		fOV = sliderR("Field of View", fOV, 0, 150, 105, "fOV")
		speedFov = Gui.checkbox("Speed FOV (max 150 at high speed)", speedFov)
		Gui.setItemTooltip("FOV ramps with throttle and speed. HUD scale lags slightly to match zoom.")
		showNameTags = Gui.checkbox("Show name tags", showNameTags)
		if Gui.button(Icon.Undo .. " Def setting##foo2") then
			pitchOffset, fOV, showNameTags, speedFov = 30, 105, true, false
			config.pitchOffset, config.fOV, config.showNameTags, config.speedFov = pitchOffset, fOV, showNameTags, speedFov
			saveConfig()
		end
		if Gui.button(Icon.Save .. "Save Setting##foo2") then
			config.pitchOffset, config.fOV, config.showNameTags, config.speedFov = pitchOffset, fOV, showNameTags, speedFov
			saveConfig()
		end
		Gui.endTabItem()
	end

	if Gui.beginTabItem("Colour") then
		if Gui.collapsingHeader("Crosshair") then rgbRow("Centre Crosshair", colCH, {0.95, 0.95, 0.95}) end
		if Gui.collapsingHeader("Throttle Bar") then
			rgbRow("Throttle Outline", colTBOut, {1.0, 1.0, 1.0}); Gui.newLine()
			rgbRow("Throttle Fill", colTBFill, {0.40, 0.70, 1.0})
		end
		stickColourGui("Left Stick", stickL, "Left")
		stickColourGui("Right Stick", stickR, "Right")
		Gui.newLine()
		if Gui.button(Icon.Save .. " Save Colours") then
			storeCol("colCH", colCH); storeCol("colTBOut", colTBOut); storeCol("colTBFill", colTBFill)
			saveStickCols("L", stickL); saveStickCols("R", stickR); saveConfig()
		end
		if Gui.button(Icon.Undo .. " Reset Colours") then
			colCH, colTBOut, colTBFill = {0.95, 0.95, 0.95}, {1.0, 1.0, 1.0}, {0.40, 0.70, 1.0}
			resetStickCols(stickL); resetStickCols(stickR)
		end
		Gui.endTabItem()
	end
	Gui.endTabBar()
end

function Start()
	currentFov, hudFov = fOV, fOV
	camera.fieldOfView = currentFov
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

local function drawCrosshair(camPos, camRot, distance, sc)
	local f, r, u = camRot:getForwardVector(), camRot:getRightVector(), camRot:getUpVector()
	local c = camPos + f * distance
	drawLineCol(c - r * (crosshairHSize * sc), c + r * (crosshairHSize * sc), colCH, crosshairThick * sc)
	drawLineCol(c - u * (crosshairVSize * sc), c + u * (crosshairVSize * sc), colCH, crosshairThick * sc)
end

local function drawThrottleBar(camPos, camRot, throttleValue, distance, sc)
	local f, r, u = camRot:getForwardVector(), camRot:getRightVector(), camRot:getUpVector()
	local bar = camPos + f * distance - u * (throttleDown * sc)
	local hw, hh = throttleWidth * 0.5 * sc, throttleHeight * 0.5 * sc
	local bl, br = bar - r * hw - u * hh, bar + r * hw - u * hh
	local tl, tr = bar - r * hw + u * hh, bar + r * hw + u * hh
	local ot = throttleThick * sc
	drawLineCol(bl, br, colTBOut, ot); drawLineCol(br, tr, colTBOut, ot)
	drawLineCol(tr, tl, colTBOut, ot); drawLineCol(tl, bl, colTBOut, ot)
	local fillAmount = math.clamp(math.abs(throttleValue), 0, 1)
	if fillAmount <= 0.01 then return end
	local inset = (borderInset - 0.1) * sc
	local fillW = (throttleWidth * sc - inset * 2) * fillAmount
	local fillLeft = bar - r * (hw - inset)
	local fillRight = fillLeft + r * fillW
	local fillHalfH = hh - borderInset * 0.95 * sc
	for i = 0, 5 do
		local yOff = -fillHalfH + (fillHalfH * 2) * (i / 5)
		drawLineCol(fillLeft + u * yOff, fillRight + u * yOff, colTBFill, 1.7 * sc)
	end
end

local function drawCircleAt(camPos, camRot, distance, ox, oy, radius, segments, thickness, col)
	local f, r, u = camRot:getForwardVector(), camRot:getRightVector(), camRot:getUpVector()
	local center = camPos + f * distance + r * ox - u * oy
	local segs = math.floor(segments)
	local prev = center + r * radius
	for i = 1, segs do
		local a = (i / segs) * math.pi * 2
		local nxt = center + r * (math.cos(a) * radius) + u * (math.sin(a) * radius)
		drawLineCol(prev, nxt, col, thickness)
		prev = nxt
	end
end

local function drawStickCrossAt(camPos, camRot, distance, ox, oy, hSize, vSize, thickness, col)
	local f, r, u = camRot:getForwardVector(), camRot:getRightVector(), camRot:getUpVector()
	local c = camPos + f * distance + r * ox - u * oy
	drawLineCol(c - r * hSize, c + r * hSize, col, thickness)
	drawLineCol(c - u * vSize, c + u * vSize, col, thickness)
end

local function drawStick(s, signX, ax, ay, camPos, camRot, hudDistance, lineDistance, lineScale, f, r, u, sc)
	local outerR, innerR = outerRadiusBase * s.size * sc, innerRadiusBase * s.size * sc
	local travel = math.max(outerR - innerR, 0)
	local bx, by = signX * s.offX * sc, s.offY * sc
	local ix, iy = bx + ax * travel, by - ay * travel
	local a = camPos + f * lineDistance + r * (bx * lineScale) - u * (by * lineScale)
	local b = camPos + f * lineDistance + r * (ix * lineScale) - u * (iy * lineScale)
	if s.showOuter then drawCircleAt(camPos, camRot, hudDistance, bx, by, outerR, s.outerSeg, s.outerThick * sc, s.colOuter) end
	if s.showLine then drawLineCol(a, b, s.colLine, s.lineThick * sc) end
	if s.showInner then drawCircleAt(camPos, camRot, hudDistance, ix, iy, innerR, s.innerSeg, s.innerThick * sc, s.colInner) end
	if s.showCross then drawStickCrossAt(camPos, camRot, hudDistance, bx, by, s.crossH * s.size * sc, s.crossV * s.size * sc, s.crossThick * sc, s.colCross) end
end

local function updateSpeedFov(dt)
	local target = fOV
	if speedFov then
		local thr = math.clamp(math.abs(currentThrottle), 0, 1)
		local speed = velocity:length()
		local startSpeed = 250 + 700 * (1 - thr)
		local fullSpeed = 1100 + 3000 * (1 - 0.5 * thr)
		if fullSpeed <= startSpeed + 1 then fullSpeed = startSpeed + 1 end
		local speedT = math.clamp((speed - startSpeed) / (fullSpeed - startSpeed), 0, 1) ^ 1.45
		local t = math.clamp(speedT * 0.38 + (thr ^ 1.4) * 0.22, 0, 1)
		target = math.clamp(fOV + (132 - fOV) * t, math.min(fOV, 132), 132)
	end
	dt = math.max(dt or 0.016, 0.0001)
	currentFov += (target - currentFov) * (1 - math.exp(-dt * 7))
	hudFov += (currentFov - hudFov) * (1 - math.exp(-dt * 3.2))
end

local function droneMovement(dt: number)
	local up, down = droneRotation:getUpVector(), -droneRotation:getUpVector()
	collisionEnabled = hitboxEnabled and not (Input.getKey(Input.Gamepad.DPad_Down) or keyHeld(bindHitboxOff))
	local oldPos, oldPts, oldRot = camera.position, collisionPoints, droneRotation
	local yawIn, thrIn, rollIn, pitchIn = getMappedInputs()
	local sm = 60
	droneRotation = droneRotation * Quat.fromEuler(
		CalcBetaFlightRate(rollIn, rcRate, superRate, expo) * sm * dt,
		CalcBetaFlightRate(pitchIn, rcRate, superRate, expo) * sm * dt,
		CalcBetaFlightRate(yawIn, rcRate, superRate, expo) * sm * dt
	)
	velocity -= gravity.upDirection * gravityStrength * dt
	local thrustAxis = math.clamp(thrIn, -1, 1)
	if thrustAxis < 0 and not downThrottle then thrustAxis = 0 end
	currentThrottle = thrustAxis
	local usedThrust = thrustAxis < 0 and reverseThrust or thrust
	velocity += up * math.sign(thrustAxis) * (thrustAxis ^ 2) * usedThrust * dt
	local geh = camera:castRay(camera.position, down * (droneWidth + droneLength) / 2)
	if grandEffect and geh.successful then
		local g = math.clamp(((droneWidth + droneLength) / 2 - geh.position:distance(camera.position)) ^ 2, 0, 1)
		velocity += up * math.sign(thrustAxis) * (thrustAxis ^ 2) * g * dt
	end
	velocity *= 0.993

	local velDir, velMag = safeNormalize(velocity)
	local localPts = {
		Vec3.new(droneWidth, droneLength, droneHeight), Vec3.new(-droneWidth, droneLength, droneHeight),
		Vec3.new(droneWidth, droneLength, -droneHeight), Vec3.new(-droneWidth, droneLength, -droneHeight),
		Vec3.new(droneWidth, -droneLength, droneHeight), Vec3.new(-droneWidth, -droneLength, droneHeight),
		Vec3.new(droneWidth, -droneLength, -droneHeight), Vec3.new(-droneWidth, -droneLength, -droneHeight)
	}
	for i = 1, 8 do collisionPoints[i] = camera.position + droneRotation:rotateVector(localPts[i]) end

	local function insideOBB(point, center, axes, ext)
		local rel = point - center
		for i = 1, 3 do if math.abs(rel:dot(axes[i])) > ext[i] then return false end end
		return true
	end
	local obbC = camera.position
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

	local desired = camera.position + velocity * dt
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
	camera.position = desired
	camera.rotation = droneRotation * Quat.fromEuler(0, pitchOffset, 0)
end

function tick(dt: number)
	if not camera.isActive and not camera.isFollowed then return end
	startTest()
	if MayStartFlag then Start() end
	camera.positionSmoothing, camera.rotationSmoothing = 0, 0
	camera.showNameTags = showNameTags
	postProcessSettings.depthOfFieldFocalDistance = 0
	droneMovement(dt)
	WorldDraw.clear()
	local sc, hudD = hudFovScale(), 120.0
	local lineD, lineS = hudD + 1.5 * sc, (hudD + 1.5 * sc) / hudD
	local p, rot = camera.position, camera.rotation
	if showCrosshair then drawCrosshair(p, rot, hudD, sc) end
	if showThrottleBar then drawThrottleBar(p, rot, currentThrottle, hudD, sc) end
	local _, _, _, _, lx, ly, rx, ry = getMappedInputs()
	local f, r, u = rot:getForwardVector(), rot:getRightVector(), rot:getUpVector()
	drawStick(stickL, -1, lx, ly, p, rot, hudD, lineD, lineS, f, r, u, sc)
	drawStick(stickR,  1, rx, ry, p, rot, hudD, lineD, lineS, f, r, u, sc)
	if Input.getKey(Input.Key.LeftAlt) and Input.getKey(Input.Key.LeftMouseButton) then
		local hit = camera:castRayFromMouse()
		if hit.successful then debug(hit.position) end
	end
	if Input.getKeyDown(Input.Gamepad.DPad_Up) or keyDown(bindSavePos) then savePosition() end
	if Input.getKeyDown(Input.Gamepad.DPad_Right) or keyDown(bindRespawn) then respawnDrone() end
end

function CalcBetaFlightRate(value, rcRate, sRate, expo)
	local sign, absV = math.sign(value), math.abs(value)
	local superFactor = 1.0 / (1.0 - (absV * sRate))
	local rc = (absV^4 * expo) + absV * (1 - expo)
	return 200 * rc * rcRate * superFactor * (math.pi / 180) * sign
end

function savePosition()
	config.position = camera.position
end

function respawnDrone()
	camera.position = config.position or Vec3.new(209, 2450, -28225)
	velocity = Vec3.zeroVector
end