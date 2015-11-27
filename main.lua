include("utils/stateMachine.lua")

-- constants
PLAYER_SIZE = 5
PLAYER_SPEEDDECR = 0.90
PLAYER_SPEEDINCR = 20
PLAYER_MAXSPEED = 120
PLAYER_ANGLEINCR = 3.6
PI = 3.14159265359

-- variables
player = GameObjectManager:createGameObject("Player")
cam = GameObjectManager:createGameObject("Camera")
bullets = {}

-- physics world
do
    local cinfo = WorldCInfo()
    cinfo.worldSize = 2000
    PhysicsSystem:setWorld(PhysicsFactory:createWorld(cinfo))
end

-- functions
function init()
	-- player
	player.position = Vec3(0, 0, 0)
	player.yspeed = 0
	player.xspeed = 0
	player.physComp = player:createPhysicsComponent()
	player.cursorDirection = Vec3(0, 0, 0)
	player.cursorAngle = 0;

	local cinfo = CharacterRigidBodyCInfo {
		shape = PhysicsFactory:createSphere(PLAYER_SIZE),
		position = Vec3(0, 0, 0),
		enableDeactivation = false
	}

	player.rb = player.physComp:createRigidBody(cinfo)
	player.rb:setUserData(player)

	-- cam
	cam.cc = cam:createCameraComponent()
	cam.cc:setPosition(Vec3(0, 0, -100))
	cam.lookDir = Vec3(0, 1, 0)
	cam.cc:lookAt(cam.lookDir:mulScalar(2.5))
	cam.cc:setState(ComponentState.Active)

end

function updatePlayerMovement(f)
	-- controls (smooth movement w/ arrow keys)
	if (InputHandler:isPressed(Key.W) and (player.yspeed < PLAYER_MAXSPEED)) then 
		player.yspeed = player.yspeed - PLAYER_SPEEDINCR
	end
	if (InputHandler:isPressed(Key.S) and (player.yspeed > -PLAYER_MAXSPEED)) then 
		player.yspeed = player.yspeed + PLAYER_SPEEDINCR 
	end
	if (InputHandler:isPressed(Key.A) and (player.xspeed > -PLAYER_MAXSPEED)) then 
		player.xspeed = player.xspeed - PLAYER_SPEEDINCR
	end
	if (InputHandler:isPressed(Key.D) and (player.xspeed < PLAYER_MAXSPEED)) then 
		player.xspeed = player.xspeed + PLAYER_SPEEDINCR 
	end

	if (player.yspeed > 0) then
		player.yspeed = player.yspeed * PLAYER_SPEEDDECR
	elseif (player.yspeed < 0) then
		player.yspeed = player.yspeed * PLAYER_SPEEDDECR
	else
		player.yspeed = 0;
	end

	if (player.xspeed > 0) then
		player.xspeed = player.xspeed * PLAYER_SPEEDDECR
	elseif (player.xspeed < 0) then
		player.xspeed = player.xspeed * PLAYER_SPEEDDECR
	else
		player.xspeed = 0;
	end

	player.position.y = player.position.y + player.yspeed*f;
	player.position.x = player.position.x + player.xspeed*f;

	player.rb:setPosition(player.position)
end

function updatePlayerCursor(f)
	-- update player cursor
	if (InputHandler:isPressed(Key.Left)) then 
		player.cursorAngle = player.cursorAngle - PLAYER_ANGLEINCR*f
		if (player.cursorAngle < 0) then
			player.cursorAngle = 360 + player.cursorAngle
		end
	elseif (InputHandler:isPressed(Key.Right)) then 
		player.cursorAngle = player.cursorAngle + PLAYER_ANGLEINCR*f
		if (player.cursorAngle > 360) then
			player.cursorAngle = player.cursorAngle - 360
		end
	end

	player.cursorDirection = Vec3(math.sin(player.cursorAngle*PI)/180, math.cos(player.cursorAngle*PI)/180, 0)
	DebugRenderer:drawArrow(player.position, player.position + player.cursorDirection:mulScalar(2000))
	DebugRenderer:printText(Vec2(-0.8, 0.8), "cursor.angle:" .. player.cursorAngle .. " f:" .. f)
end

function update(deltaTime)
	-- update gameobjects

	updatePlayerMovement(deltaTime)
	updatePlayerCursor(deltaTime)
end

Events.Update:registerListener(update)

-- main
init()
PhysicsSystem:setDebugDrawingEnabled(true)