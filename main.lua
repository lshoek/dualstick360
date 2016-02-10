include("dualstick360/globals.lua")
include("dualstick360/utils.lua")
include("utils/stateMachine.lua")
include("dualstick360/player.lua")
include("dualstick360/bullet.lua")
include("dualstick360/enemy.lua")
include("dualstick360/healthpack.lua")
include("dualstick360/level1.lua")

function init()
	-- init player
	player = Player.new()
	player:init()
	
	-- cam
	cam = GameObjectManager:createGameObject("Camera")
	cam.cc = cam:createCameraComponent()
	cam.cc:setPosition(Vec3(0, 0, -100))
	cam.lookDir = Vec3(0, 1, 0)
	cam.cc:lookAt(cam.lookDir:mulScalar(2.5))
	cam.cc:setState(ComponentState.Active)

	--[[local terrain = GameObjectManager:createGameObject("terrain")
	terrain.rc = terrain:createRenderComponent()
	terrain.rc:setPath("data/models/verylasttest.fbx")
	terrain.rc:setScale(Vec3(1000,1000,0))
    terrain:setPosition(Vec3(0,0,19))
	terrain:setRotation(Quaternion(Vec3(0,1,0),180))]]--
end

function update(deltaTime)
    -- move camera
    cam.cc:setPosition(Vec3(player.rb:getPosition().x, player.rb:getPosition().y, CAMERA_Z))
    hb:setPosition(Vec3((2/3)*CAMERA_Z + cam.cc:getPosition().x + 50, (4/15)*CAMERA_Z + cam.cc:getPosition().y -20, (2/15)*CAMERA_Z))
    
    -- check condition
	if player.hp <= 0 then
		GAME_OVER = true
	end

	if BOSS_CONDITION_BEATEN then
		GAME_BEATEN = true
	end

	-- update gameobjects
	if not GAME_OVER and not GAME_BEATEN then
		player:update(deltaTime)

		for _, b in ipairs(player.bullets) do
			if (b.isActive) then
				b:update(deltaTime)
			end
		end

		for _, e in ipairs(enemyArray) do
			for _, b in ipairs(e.bullets) do
				if (b.isActive) then
					b:update(deltaTime)
				end
			end
		end
	else
		if GAME_OVER then
			DebugRenderer:printText(Vec2(-0.1, 0.5), "GAME OVER")
			DebugRenderer:printText(Vec2(-0.15, 0.45), "Press Return to Restart")
		elseif GAME_BEATEN then
			DebugRenderer:printText(Vec2(-0.1, 0.5), "YOU WON!")
			DebugRenderer:printText(Vec2(-0.15, 0.45), "Hooray, that's the game!")
		end
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
	createGrid()

	-- utils.lua
	printTextCalls = 0
	printGameplayTextCalls = 0
end
Events.Update:registerListener(update)

-- main
local cinfo = WorldCInfo()
cinfo.worldSize = 2000
world = PhysicsFactory:createWorld(cinfo)
world:setCollisionFilter(PhysicsFactory:createCollisionFilter_Simple())
PhysicsSystem:setWorld(world)

init()
build_level_1()
PhysicsSystem:setDebugDrawingEnabled(true)