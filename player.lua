include("dualstick360/bullet.lua")
include("dualstick360/utils.lua")

PLAYER_SIZE = 3
PLAYER_MAXSPEED = 50
PLAYER_BULLETLIMIT = 25
PLAYER_BULLETDELAY = 0.1
PLAYER_BULLETSPEED = 6000
PLAYER_BULLETSIZE = 2
PLAYER_MINIMUMPUSH = 0.05

CAMERA_Z = -150
PLAYER_SHIELDDISTANCE = 2 * PLAYER_SIZE
PLAYER_SHIELDDISTANCE_SIDE = 2 * PLAYER_SIZE * 1.05
PLAYER_SHIELDRESTITUTION = 1.0

RUMBLE_ON = true

PLAYER_HP = 100
HEALTH_BAR_LENGTH = 50   -- -(1/3) * CAMERA_Z 
HEALTH_BAR_WIDTH = 5     -- -(1/30) * CAMERA_Z 

Player = {}
Player.__index = Player

function Player.new()
	local self = setmetatable({}, Player)
	self.go = GameObjectManager:createGameObject("PlayerOne")
	return self
end

function healthbarupdate()

	local hpLenght = (player.hp/PLAYER_HP)*HEALTH_BAR_LENGTH
	player.hb.rc:setScale(Vec3(5, -hpLenght, 0.1))
	
end

function Player:init() -- : inserts metatable at args called 'self'

	-- variables for movement
	self.movementDirection = Vec3(0, 0, 0)
	self.moveKeyPressed = false

	-- variables for shooting
	self.bullets = {}
	self.cursorDirection = Vec3(0, 0, 0)
	self.numBullets = 0
	self.timeSinceLastShot = 0
	self.shootKeyPressed = false
	
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
	cinfo.position = Vec3(1, 0, 0)
	cinfo.mass = 1.5
	cinfo.linearDamping = 7.0
	cinfo.motionType = MotionType.Dynamic
	cinfo.collisionFilterInfo = PLAYER_INFO

	self.rb = self.physComp:createRigidBody(cinfo)
	self.rb:setUserData(self)

	--player shield 3parts
	--middle
	shield = {}
	shield.go = GameObjectManager:createGameObject("Shield")
	shield.physComp = shield.go:createPhysicsComponent()

	local cinfo = RigidBodyCInfo()
	--cinfo.shape = PhysicsFactory:createBox(Vec3(0.9,4.5,7))
	--												width				length				height		
	cinfo.shape = PhysicsFactory:createBox(Vec3(0.19* PLAYER_SIZE,0.93*PLAYER_SIZE,1.4* PLAYER_SIZE))
	cinfo.position = Vec3(10, 0, 0)
	cinfo.mass = 0.5
	cinfo.restitution = PLAYER_SHIELDRESTITUTION
	cinfo.motionType = MotionType.Keyframed
	cinfo.collisionFilterInfo = 0x7
	
	shield.rb = shield.physComp:createRigidBody(cinfo)
	--shield.go:setComponentStates(ComponentState.Inactive)
	--right
	shield_r = {}
	shield_r.go = GameObjectManager:createGameObject("Shield_r")
	shield_r.physComp = shield_r.go:createPhysicsComponent()

	local cinfo = RigidBodyCInfo()
	--												width				length				height	
	cinfo.shape = PhysicsFactory:createBox(Vec3(0.19* PLAYER_SIZE,0.76 * PLAYER_SIZE,1.4* PLAYER_SIZE))
	cinfo.position = Vec3(0, 0, 0)
	cinfo.mass = 0.5
	cinfo.restitution = PLAYER_SHIELDRESTITUTION
	cinfo.motionType = MotionType.Keyframed
	cinfo.collisionFilterInfo = 0x7
	
	shield_r.rb = shield_r.physComp:createRigidBody(cinfo)
	shield_r.go:setComponentStates(ComponentState.Inactive)
	
	shield_r.rb:setRotation(Quaternion(Vec3(0,0,1),45))
	
	--left
	shield_l = {}
	shield_l.go = GameObjectManager:createGameObject("Shield_l")
	shield_l.physComp = shield_l.go:createPhysicsComponent()

	local cinfo = RigidBodyCInfo()
	--												width				length				height	
	cinfo.shape = PhysicsFactory:createBox(Vec3(0.19* PLAYER_SIZE,0.76 * PLAYER_SIZE,1.4* PLAYER_SIZE))
	cinfo.position = Vec3(0, 0, 0)
	cinfo.mass = 0.5
	cinfo.restitution = PLAYER_SHIELDRESTITUTION
	cinfo.motionType = MotionType.Keyframed
	cinfo.collisionFilterInfo = 0x7
	
	shield_l.rb = shield_l.physComp:createRigidBody(cinfo)
	shield_l.go:setComponentStates(ComponentState.Inactive)
	shield_l.rb:setRotation(Quaternion(Vec3(0,0,1),-45))	

	-- init bullets
	for i=1, PLAYER_BULLETLIMIT do
		local b = Bullet.new(i)
		b:init(i, true, PLAYER_BULLETSIZE)
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
			self.cursorDirection = Vec3(math.sin((self.rightStickAngle/360)*2*PI), math.cos(self.rightStickAngle/360*2*PI), 0)
		end
		
		-- draw cursor
		if ((self.rightStickPush > PLAYER_MINIMUMPUSH or self.keyboardKeyPressed) and self.shieldActive == false) then
			DebugRenderer:drawArrow(self.rb:getPosition(), self.rb:getPosition() + self.cursorDirection:mulScalar(PLAYER_SIZE*2))
		end
		
		--update shield		
		if ((self.rightStickPush > PLAYER_MINIMUMPUSH or self.keyboardKeyPressed) and self.shieldActive) then
			shield.go:setComponentStates(ComponentState.Active)
			shield.rb:setPosition(self.rb:getPosition().x + self.cursorDirection.x*PLAYER_SHIELDDISTANCE,self.rb:getPosition().y + self.cursorDirection.y*PLAYER_SHIELDDISTANCE, 0)
			shieldrotation_deg = calcAngleBetween(Vec3(0,1,0),self.cursorDirection)
			shield.rb:setRotation(Quaternion(Vec3(0,0,1),shieldrotation_deg))
			
			shield_r.go:setComponentStates(ComponentState.Active)
			q = Quaternion(Vec3(0.0, 0.0, 1.0), 45)
			v = q:toMat3():mulVec3(self.cursorDirection)
			shield_r.rb:setPosition(self.rb:getPosition().x + v.x*PLAYER_SHIELDDISTANCE_SIDE,self.rb:getPosition().y + v.y*PLAYER_SHIELDDISTANCE_SIDE, 0)
			shieldrotation_deg = calcAngleBetween(Vec3(0,1,0),self.cursorDirection)
			shield_r.rb:setRotation(Quaternion(Vec3(0,0,1),shieldrotation_deg+45))
			
			shield_l.go:setComponentStates(ComponentState.Active)
			q = Quaternion(Vec3(0.0, 0.0, 1.0), -45)
			v = q:toMat3():mulVec3(self.cursorDirection)
			shield_l.rb:setPosition(self.rb:getPosition().x + v.x*PLAYER_SHIELDDISTANCE_SIDE,self.rb:getPosition().y + v.y*PLAYER_SHIELDDISTANCE_SIDE, 0)
			shieldrotation_deg = calcAngleBetween(Vec3(0,1,0),self.cursorDirection)
			shield_l.rb:setRotation(Quaternion(Vec3(0,0,1),shieldrotation_deg-45))
			
			
		else
			shield.go:setComponentStates(ComponentState.Inactive)
			shield_l.go:setComponentStates(ComponentState.Inactive)
			shield_r.go:setComponentStates(ComponentState.Inactive)
		end
		
		-- shoot bullets
		if ((self.rightStickPush > 0.5 or self.keyboardKeyPressed) and self.timeSinceLastShot>PLAYER_BULLETDELAY and self.shieldActive == false) then
			for _, b in ipairs(self.bullets) do
				if not (b.isActive) then
					b:activateBullet(self.rb:getPosition(), self.cursorDirection, PLAYER_BULLETSPEED)
					break
				end
			end
			self.timeSinceLastShot = 0
		end

		-- enable delay between shots
		if (self.timeSinceLastShot < PLAYER_BULLETDELAY) then
			self.timeSinceLastShot = self.timeSinceLastShot + f
		end
		
		-- update active bullets
		local activeBullets = 0
		for _, b in ipairs(self.bullets) do
			if (b.isActive) then
				b:update(f)
				activeBullets = activeBullets + 1
			end
		end
		
		--keep on z axe
		self.rb:setPosition(Vec3(self.rb:getPosition().x,self.rb:getPosition().y,0))
		
		--gameplay printer
		printGameplayText("HP: " .. self.hp)
		printGameplayText("Score: " .. self.score)

		-- debug printer
		printText("self.leftstickAngle:" .. self.leftStickAngle)
		printText("self.rightstickAngle:" .. self.rightStickAngle)
		printText("self.leftStickPush:" .. self.leftStickPush)
		printText("self.rightStickPush:" .. self.rightStickPush)
		printText("active bullets:" .. activeBullets)	
		printText("rightTriggerValue: " .. rightTrigger) 
end