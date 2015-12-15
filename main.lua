include("utils/stateMachine.lua")
include("dualstick360/player.lua")
include("dualstick360/bullet.lua")
include("dualstick360/utils.lua")

-- variables
player = {}
cam = GameObjectManager:createGameObject("Camera")

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
	player:init(world)


	--Events.PostInitialization:registerListener(addBulletConstraints)

	-- world (block)
	local block = {}
	block.go = GameObjectManager:createGameObject("test_Block")
	block.physComp = block.go:createPhysicsComponent()

	local cinfo = RigidBodyCInfo()
	cinfo.shape = PhysicsFactory:createBox(20, 20, 10)
	cinfo.position = Vec3(-15, -20, -5)
	cinfo.mass = 1000
	cinfo.motionType = MotionType.Dynamic
	cinfo.collisionFilterInfo = 0x1

	block.rb = block.physComp:createRigidBody(cinfo)
	block.rb:setUserData(block)

	-- constraint 
	local cinfo = {
		type = ConstraintType.PointToPlane,
		A = block.rb,
		--B = top.rb, -- Comment out this line to use the world as reference point
		constraintSpace = "world",
		pivot = Vec3(0, 0, 0),
		up = Vec3(0, 0, 1),
		solvingMethod = "stable",
	}

	local constraint = PhysicsFactory:createConstraint(cinfo)

	-- The constraint must be added in the post-initialization phase
	Events.PostInitialization:registerListener(function() world:addConstraint(constraint) end)

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

	-- utils.lua
	printTextCalls = 0
end

Events.Update:registerListener(update)

-- main
init()
PhysicsSystem:setDebugDrawingEnabled(true)