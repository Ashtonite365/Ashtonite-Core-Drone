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
