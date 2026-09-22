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
