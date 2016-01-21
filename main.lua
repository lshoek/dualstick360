include("dualstick360/utils.lua")
include("utils/stateMachine.lua")
include("dualstick360/player.lua")
include("dualstick360/bullet.lua")
include("dualstick360/enemy_1.lua")
include("dualstick360/healthpack.lua")

-- variables
player = {}
cam = GameObjectManager:createGameObject("Camera")
ENEMY_1_QUANTITY = 3
enemy_1_array = {}

GAME_OVER = false

-- physics world

local cinfo = WorldCInfo()
cinfo.worldSize = 2000
world = PhysicsFactory:createWorld(cinfo)
world:setCollisionFilter(PhysicsFactory:createCollisionFilter_Simple())
PhysicsSystem:setWorld(world)

-- functions
function init()
	-- player
	player = Player.new()
	player:init()
	
	--enemy_1
	for i = 1, ENEMY_1_QUANTITY do
		local e1 = Enemy_1.new()
		e1:init("enemy_1_" .. i)
		enemy_1_array[i] = e1
	end
	
	--testHealthpack
	
	testhealthpack = HEALTHPACK.new()
	testhealthpack:init("testpack", Vec3(-50,0,0))
	--world	

	--Events.PostInitialization:registerListener(addBulletConstraints)

	-- world (block)
	--[[
	local block = {}
	block.go = GameObjectManager:createGameObject("test_Block")
	block.physComp = block.go:createPhysicsComponent()

	local cinfo = RigidBodyCInfo()
	cinfo.shape = PhysicsFactory:createBox(20, 20, 10)
	cinfo.position = Vec3(-15, -20, -5)
	cinfo.mass = 1000
	cinfo.motionType = MotionType.Dynamic
	cinfo.collisionFilterInfo = OBJECT_INFO

	block.rb = block.physComp:createRigidBody(cinfo)
	block.rb:setUserData(block)]]--
--[[
	-- constraints
	local cinfo = {
		type = ConstraintType.PointToPlane,
		A = player.rb,
		--B = top.rb, -- Comment out this line to use the world as reference point
		constraintSpace = "world",
		pivot = Vec3(0, 0, 0),
		up = Vec3(0, 0, 1),
		solvingMethod = "stable",
	}
	local playerConstraint = PhysicsFactory:createConstraint(cinfo)

	local cinfo = {
		type = ConstraintType.PointToPlane,
		A = block.rb,
		--B = top.rb, -- Comment out this line to use the world as reference point
		constraintSpace = "world",
		pivot = Vec3(0, 0, 0),
		up = Vec3(0, 0, 1),
		solvingMethod = "stable",
	}
	local blockConstraint = PhysicsFactory:createConstraint(cinfo)

	-- The constraint must be added in the post-initialization phase
	Events.PostInitialization:registerListener(function() world:addConstraint(playerConstraint) end)
	Events.PostInitialization:registerListener(function() world:addConstraint(blockConstraint) end)
]]--
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
    
    
	if player.hp <= 0 then
		GAME_OVER = true
	end

	-- update gameobjects
	if not GAME_OVER then
		player:update(deltaTime)
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