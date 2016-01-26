include("dualstick360/utils.lua")
include("utils/stateMachine.lua")
include("dualstick360/player.lua")
include("dualstick360/bullet.lua")
include("dualstick360/enemy.lua")
include("dualstick360/healthpack.lua")
include("dualstick360/level1.lua")

-- variables
player = {}
cam = GameObjectManager:createGameObject("Camera")

ENEMY_ARRAY = {}
ENEMY_ARRAYSIZE = 0

GAME_OVER = false

local cinfo = WorldCInfo()
cinfo.worldSize = 2000
world = PhysicsFactory:createWorld(cinfo)
world:setCollisionFilter(PhysicsFactory:createCollisionFilter_Simple())
PhysicsSystem:setWorld(world)

build_level_1()

-- functions
function init()
	-- init player
	player = Player.new()
	player:init()
	
	local terrain = GameObjectManager:createGameObject("terrain")
	terrain.rc = terrain:createRenderComponent()
	terrain.rc:setPath("data/models/verylasttest.fbx")
	terrain.rc:setScale(Vec3(1000,1000,0))
    terrain:setPosition(Vec3(0,0,19))
	terrain:setRotation(Quaternion(Vec3(0,1,0),180))

	
	-- testHealthpack
	testhealthpack = HEALTHPACK.new()
	testhealthpack:init("testpack", Vec3(-50,0,0))
	
	-- cam
	cam.cc = cam:createCameraComponent()
	cam.cc:setPosition(Vec3(0, 0, -100))
	cam.lookDir = Vec3(0, 1, 0)
	cam.cc:lookAt(cam.lookDir:mulScalar(2.5))
	cam.cc:setState(ComponentState.Active)
end

function update(deltaTime)
    -- move camera
    cam.cc:setPosition(Vec3(player.rb:getPosition().x, player.rb:getPosition().y, CAMERA_Z))
    hb:setPosition(Vec3((2/3)*CAMERA_Z + cam.cc:getPosition().x + 50, (4/15)*CAMERA_Z + cam.cc:getPosition().y -20, (2/15)*CAMERA_Z))
    
    -- check hp
	if player.hp <= 0 then
		GAME_OVER = true
	end

	-- update gameobjects
	if not GAME_OVER then
		player:update(deltaTime)

		for _, b in ipairs(player.bullets) do
			if (b.isActive) then
				b:update(deltaTime)
			end
		end

		for _, e in ipairs(ENEMY_ARRAY) do
			for _, b in ipairs(e.bullets) do
				if (b.isActive) then
					b:update(deltaTime)
				end
			end
		end
	else
		DebugRenderer:printText(Vec2(-0.1, 0.5), "GAME OVER")
		DebugRenderer:printText(Vec2(-0.15, 0.45), "Press Return to Restart")
		player.go:setComponentStates(ComponentState.Inactive)
		shield.go:setComponentStates(ComponentState.Inactive)
		shield_l.go:setComponentStates(ComponentState.Inactive)
		shield_r.go:setComponentStates(ComponentState.Inactive)		
		if (InputHandler:isPressed(Key.Return)) then
			player.go:setComponentStates(ComponentState.Active)
			player.hp = PLAYER_HP
			player.score = 0
			GAME_OVER = false
		end
	end

	-- utils.lua
	printTextCalls = 0
	printGameplayTextCalls = 0
end

Events.Update:registerListener(update)

-- main
init()
PhysicsSystem:setDebugDrawingEnabled(true)