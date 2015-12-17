include("dualstick360/bullet.lua")
include("dualstick360/utils.lua")

PLAYER_SIZE = 5
PLAYER_MAXSPEED = 50
PLAYER_BULLETLIMIT = 25
PLAYER_BULLETDELAY = 0.08
PLAYER_BULLETSPEED = 6000
PLAYER_BULLETSIZE = 2
PLAYER_MINIMUMPUSH = 0.05

PLAYER_HP = 100

Player = {}
Player.__index = Player

function Player.new()
	local self = setmetatable({}, Player)
	self.go = GameObjectManager:createGameObject("PlayerOne")
	return self
end

	-- collision event
function player_bullet_collision(eventData)
		
		local rigidBody = eventData:getBody(CollisionArgsCallbackSource.A)
		
		for i = 1, ENEMY_1_QUANTITY do
			
			for k = 1, ENEMY_1_BULLETLIMIT do
				if rigidBody:equals(enemy_1_array[i].bullets[k].rb) then
					player.hp = player.hp - 10			
				end
			end
		end
	
		return EventResult.Handled

end

function Player:init(world) -- : inserts metatable at args called 'self'
	-- variables for movement
	self.movementDirection = Vec3(0, 0, 0)
	self.moveKeyPressed = false

	-- variables for shooting
	self.bullets = {}
	self.cursorDirection = Vec3(0, 0, 0)
	self.numBullets = 0
	self.timeSinceLastShot = 0
	self.shootKeyPressed = false

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
	cinfo.position = Vec3(0, 0, 0)
	cinfo.mass = 1.5
	cinfo.linearDamping = 7.0
	cinfo.motionType = MotionType.Dynamic
	cinfo.collisionFilterInfo = 0x1

	self.rb = self.physComp:createRigidBody(cinfo)
	self.rb:setUserData(self)
	self.physComp:getContactPointEvent():registerListener(player_bullet_collision)


	-- init bullets
	for i=1, PLAYER_BULLETLIMIT do
		local b = Bullet.new(i)
		b:init(i, world, PLAYER_BULLETSIZE)
		self.bullets[i] = b
	end
end

function Player:update(f)


	-- gamepad movement controls (analog stick angle and push)
		local leftStick = InputHandler:gamepad(0):leftStick()
		local rightStick = InputHandler:gamepad(0):rightStick()

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

		-- draw cursor
		if (self.rightStickPush > PLAYER_MINIMUMPUSH or self.keyboardKeyPressed) then
			self.cursorDirection = Vec3(math.sin((self.rightStickAngle/360)*2*PI), math.cos(self.rightStickAngle/360*2*PI), 0)
			DebugRenderer:drawArrow(self.rb:getPosition(), self.rb:getPosition() + self.cursorDirection:mulScalar(PLAYER_SIZE*2))
		end

		-- shoot bullets
		if ((self.rightStickPush > 0.5 or self.keyboardKeyPressed) and self.timeSinceLastShot>PLAYER_BULLETDELAY) then
			for _, b in ipairs(self.bullets) do
				if not (b.isActive) then
					b:activateBullet(self.rb:getPosition(), self.cursorDirection)
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
		
		--gameplay printer
		printGameplayText("HP: " .. self.hp)
		printGameplayText("Score: " .. self.score)

		-- debug printer
		printText("self.leftstickAngle:" .. self.leftStickAngle)
		printText("self.rightstickAngle:" .. self.rightStickAngle)
		printText("self.leftStickPush:" .. self.leftStickPush)
		printText("self.rightStickPush:" .. self.rightStickPush)
		printText("active bullets:" .. activeBullets)	
		

end