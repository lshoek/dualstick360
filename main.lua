include("utils/stateMachine.lua")
include("dualstick360/player.lua")
include("dualstick360/bullet.lua")

-- constants
PI = 3.14159265359

-- variables
player = {}
bullets = {}
cam = GameObjectManager:createGameObject("Camera")

-- physics world
do
    local cinfo = WorldCInfo()
    cinfo.worldSize = 2000
    PhysicsSystem:setWorld(PhysicsFactory:createWorld(cinfo))
end

-- functions
function init()
	-- player
	player = Player.new()
	player:init()

	-- cam
	cam.cc = cam:createCameraComponent()
	cam.cc:setPosition(Vec3(0, 0, -100))
	cam.lookDir = Vec3(0, 1, 0)
	cam.cc:lookAt(cam.lookDir:mulScalar(2.5))
	cam.cc:setState(ComponentState.Active)

end

function update(deltaTime)
	-- update gameobjects
	player:update(deltaTime)

end
Events.Update:registerListener(update)

-- main
init()
PhysicsSystem:setDebugDrawingEnabled(true)