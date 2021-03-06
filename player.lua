include("dualstick360/globals.lua")
include("dualstick360/bullet.lua")
include("dualstick360/utils.lua")

Player = {}
Player.__index = Player

--[[ Create a new Player object ]]
function Player.new()
	local self = setmetatable({}, Player)
	self.go = GameObjectManager:createGameObject("PlayerOne")
	return self
end

--[[ Update the healthbar (global) ]]
function Player:healthbarupdate()
	local hpLenght = (player.hp/PLAYER_HP)*HEALTH_BAR_LENGTH
	player.hb.rc:setScale(Vec3(5, -hpLenght, 0.1))
end

--[[ Initialize the current Player object, constructs a rigid body, all objects that are part of the Player and sets its members. ]]
function Player:init() -- : inserts metatable at args called 'self'

	-- variables for movement
	self.movementDirection = Vec3(0, 0, 0)
	self.moveKeyPressed = false

	-- variables for shooting
	self.bullets = {}
	self.cursorDirection = Vec3(0, 0, 0)
	self.timeSinceLastShot = 0
	
	--variables for shield
	self.shieldActive = false

	-- variables for gamepad data
	self.leftStickAngle = 0
	self.rightStickAngle = 0
	self.leftStickPush = 0
	self.rightStickPush = 0
	
	-- variables for gameplay
	self.score = 0
	self.hp = PLAYER_HP

	-- physicscomponent
	self.physComp = self.go:createPhysicsComponent()

	local cinfo = RigidBodyCInfo()
	cinfo.shape = PhysicsFactory:createSphere(PLAYER_SIZE)
	cinfo.position = PLAYER_STARTPOSITION
	cinfo.mass = PLAYER_MASS
	cinfo.linearDamping = PLAYER_LINDAMP
	cinfo.motionType = MotionType.Dynamic
	cinfo.collisionFilterInfo = PLAYER_INFO
	self.rb = self.physComp:createRigidBody(cinfo)
	self.rb:setUserData(self)

	--player shield 3 parts
	--middle
	self.shield = {}
	self.shield.go = GameObjectManager:createGameObject("player_shield_mid")
	self.shield.physComp = self.shield.go:createPhysicsComponent()

	local cinfo = RigidBodyCInfo()
	--												width				length				height		
	cinfo.shape = PhysicsFactory:createBox(Vec3(0.19* PLAYER_SIZE,0.93*PLAYER_SIZE,1.4* PLAYER_SIZE))
	cinfo.position = Vec3(10, 0, 0)
	cinfo.mass = 0.5
	cinfo.restitution = PLAYER_SHIELDRESTITUTION
	cinfo.motionType = MotionType.Keyframed
	cinfo.collisionFilterInfo = PLAYERSHIELD_INFO
	
	self.shield.rb = self.shield.physComp:createRigidBody(cinfo)
	--right
	self.shield_r = {}
	self.shield_r.go = GameObjectManager:createGameObject("player_shield_r")
	self.shield_r.physComp = self.shield_r.go:createPhysicsComponent()

	local cinfo = RigidBodyCInfo()
	--												width				length				height	
	cinfo.shape = PhysicsFactory:createBox(Vec3(0.19* PLAYER_SIZE,0.76 * PLAYER_SIZE,1.4* PLAYER_SIZE))
	cinfo.position = Vec3(0, 0, 0)
	cinfo.mass = 0.5
	cinfo.restitution = PLAYER_SHIELDRESTITUTION
	cinfo.motionType = MotionType.Keyframed
	cinfo.collisionFilterInfo = PLAYERSHIELD_INFO
	
	self.shield_r.rb = self.shield_r.physComp:createRigidBody(cinfo)
	self.shield_r.go:setComponentStates(ComponentState.Inactive)
	
	self.shield_r.rb:setRotation(Quaternion(Vec3(0,0,1),45))
	
	--left
	self.shield_l = {}
	self.shield_l.go = GameObjectManager:createGameObject("player_shield_l")
	self.shield_l.physComp = self.shield_l.go:createPhysicsComponent()

	local cinfo = RigidBodyCInfo()
	--												width				length				height	
	cinfo.shape = PhysicsFactory:createBox(Vec3(0.19* PLAYER_SIZE,0.76 * PLAYER_SIZE,1.4* PLAYER_SIZE))
	cinfo.position = Vec3(0, 0, 0)
	cinfo.mass = 0.5
	cinfo.restitution = PLAYER_SHIELDRESTITUTION
	cinfo.motionType = MotionType.Keyframed
	cinfo.collisionFilterInfo = PLAYERSHIELD_INFO
	
	self.shield_l.rb = self.shield_l.physComp:createRigidBody(cinfo)
	self.shield_l.go:setComponentStates(ComponentState.Inactive)
	self.shield_l.rb:setRotation(Quaternion(Vec3(0,0,1),-45))	

	-- init bullets
	for i=1, PLAYER_BULLETLIMIT do
		local b = Bullet.new(i)
		b:init(i, true, false)
		self.bullets[i] = b
	end
    
    -- health bar
    hb = GameObjectManager:createGameObject("myHealthBar")
    hb.rc = hb:createRenderComponent()
    hb.rc:setPath("data/models/box.thModel")
    hb.rc:setScale(Vec3(5, -(self.hp/PLAYER_HP)*HEALTH_BAR_LENGTH, 0.1))
    hb:setPosition(Vec3((2/3)*CAMERA_Z-150,(4/15)*CAMERA_Z, (2/15)*CAMERA_Z))
    hb:setRotation(Quaternion(Vec3(0,0,1),90))
    self.hb = hb
    
end

--[[ 	Updates all members of the player. 
		Reads input from gamepad/keyboard and updates the Player position and cursor direction.
	 	Also fires bullets and activates shield 
	]]
function Player:update(f)
	-- gamepad movement controls (analog stick angle and push)
		local leftStick = InputHandler:gamepad(0):leftStick()
		local rightStick = InputHandler:gamepad(0):rightStick()
		local rightTrigger = InputHandler:gamepad(0):rightTrigger()

		self.leftStickAngle = (math.atan(leftStick.y, leftStick.x)/PI)*180 + 90
		self.rightStickAngle = (math.atan(rightStick.y, rightStick.x)/PI)*180 + 90
		self.leftStickPush = leftStick:length()
		self.rightStickPush = rightStick:length()

		if (self.leftStickAngle < 0) then
			self.leftStickAngle = self.leftStickAngle + 360
		end
		if (self.rightStickAngle < 0) then
			self.rightStickAngle = self.rightStickAngle + 360
		end

		-- DEBUG keyboard movement controls
		if (InputHandler:isPressed(Key.W)) then
			self.leftStickAngle = 180
			self.leftStickPush = 1
		elseif (InputHandler:isPressed(Key.S)) then
			self.leftStickAngle = 0
			self.leftStickPush = 1
		elseif (InputHandler:isPressed(Key.A)) then
			self.leftStickAngle = 270
			self.leftStickPush = 1
		elseif (InputHandler:isPressed(Key.D)) then
			self.leftStickAngle = 90
			self.leftStickPush = 1
		end

		-- move player
		if (self.leftStickPush > PLAYER_MINIMUMPUSH) then
			self.movementDirection = Vec3(math.sin((self.leftStickAngle/360)*2*PI), math.cos(self.leftStickAngle/360*2*PI), 0)
			self.rb:applyLinearImpulse(self.movementDirection:mulScalar(PLAYER_MAXSPEED * self.leftStickPush))
		end

		-- DEBUG keyboard player cursor
		self.keyboardKeyPressed = false
		if (InputHandler:isPressed(Key.Up)) then 
			self.rightStickAngle = 180
			self.keyboardKeyPressed = true
		elseif (InputHandler:isPressed(Key.Down)) then 
			self.rightStickAngle = 0
			self.keyboardKeyPressed = true
		elseif (InputHandler:isPressed(Key.Left)) then 
			self.rightStickAngle = 270
			self.keyboardKeyPressed = true
		elseif (InputHandler:isPressed(Key.Right)) then 
			self.rightStickAngle = 90
			self.keyboardKeyPressed = true
		end

		-- update shieldActive
		if(rightTrigger > 0.9 or InputHandler:isPressed(Key.Space)) then
			self.shieldActive = true
		else
			self.shieldActive = false
		end
		-- calc curserDirection
		if (self.rightStickPush > PLAYER_MINIMUMPUSH or self.keyboardKeyPressed) then
			self.cursorDirection = Vec3(math.sin((self.rightStickAngle/360)*2*PI), math.cos(self.rightStickAngle/360*2*PI), 0):normalized()
		end
		
		-- draw cursor
		if ((self.rightStickPush > PLAYER_MINIMUMPUSH or self.keyboardKeyPressed) and self.shieldActive == false) then
			DebugRenderer:drawArrow(self.rb:getPosition(), self.rb:getPosition() + self.cursorDirection:mulScalar(PLAYER_SIZE*2))
		end
		
		--update shield		
		if ((self.rightStickPush > PLAYER_MINIMUMPUSH or self.keyboardKeyPressed) and self.shieldActive) then
			self.shield.go:setComponentStates(ComponentState.Active)
			self.shield.rb:setPosition(self.rb:getPosition().x + self.cursorDirection.x*PLAYER_SHIELDDISTANCE,self.rb:getPosition().y + self.cursorDirection.y*PLAYER_SHIELDDISTANCE, 0)
			local shieldrotation_deg = calcAngleBetween(Vec3(0,1,0),self.cursorDirection)
			self.shield.rb:setRotation(Quaternion(Vec3(0,0,1),shieldrotation_deg))
			
			self.shield_r.go:setComponentStates(ComponentState.Active)
			q = Quaternion(Vec3(0.0, 0.0, 1.0), 45)
			v = q:toMat3():mulVec3(self.cursorDirection)
			self.shield_r.rb:setPosition(self.rb:getPosition().x + v.x*PLAYER_SHIELDDISTANCE_SIDE,self.rb:getPosition().y + v.y*PLAYER_SHIELDDISTANCE_SIDE, 0)
			local shieldrotation_deg = calcAngleBetween(Vec3(0,1,0),self.cursorDirection)
			self.shield_r.rb:setRotation(Quaternion(Vec3(0,0,1),shieldrotation_deg+45))
			
			self.shield_l.go:setComponentStates(ComponentState.Active)
			q = Quaternion(Vec3(0.0, 0.0, 1.0), -45)
			v = q:toMat3():mulVec3(self.cursorDirection)
			self.shield_l.rb:setPosition(self.rb:getPosition().x + v.x*PLAYER_SHIELDDISTANCE_SIDE,self.rb:getPosition().y + v.y*PLAYER_SHIELDDISTANCE_SIDE, 0)
			local shieldrotation_deg = calcAngleBetween(Vec3(0,1,0),self.cursorDirection)
			self.shield_l.rb:setRotation(Quaternion(Vec3(0,0,1),shieldrotation_deg-45))
		else
			self.shield.go:setComponentStates(ComponentState.Inactive)
			self.shield_l.go:setComponentStates(ComponentState.Inactive)
			self.shield_r.go:setComponentStates(ComponentState.Inactive)
		end
		
		-- shoot bullets
		if ((self.rightStickPush > 0.5 or self.keyboardKeyPressed) and self.timeSinceLastShot > PLAYER_BULLETDELAY and self.shieldActive == false) then
			for _, b in ipairs(self.bullets) do
				if not (b.isActive) then
					b:activateBullet(self.rb:getPosition() + self.cursorDirection:mulScalar(PLAYER_SIZE), self.cursorDirection, PLAYER_BULLETSPEED)
					break
				end
			end
			self.timeSinceLastShot = 0
		end

		-- enable delay between shots
		if (self.timeSinceLastShot < PLAYER_BULLETDELAY) then
			self.timeSinceLastShot = self.timeSinceLastShot + f
		end
		
		--keep on z axe
		self.rb:setPosition(Vec3(self.rb:getPosition().x,self.rb:getPosition().y,0))
		self.rb:setAngularVelocity(Vec3(0, 0, 0))
		
		--gameplay printer
		printGameplayText("HP: " .. self.hp)
		printGameplayText("Score: " .. self.score)

		-- debug printer
		printText("self.leftstickAngle:" .. self.leftStickAngle)
		printText("self.rightstickAngle:" .. self.rightStickAngle)
		printText("self.leftStickPush:" .. self.leftStickPush)
		printText("self.rightStickPush:" .. self.rightStickPush)	
		printText("rightTriggerValue: " .. rightTrigger) 
end