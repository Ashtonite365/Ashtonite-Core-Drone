-- @name Ashtonite.Core Drone
-- @credits Scha's Drone Camera + Grok
-- @author Ashtonite365
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
