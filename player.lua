include("dualstick360/bullet.lua")

PLAYER_SIZE = 5
PLAYER_SPEEDDECR = 0.90
PLAYER_SPEEDINCR = 20
PLAYER_MAXSPEED = 120
PLAYER_ANGLEINCR = 3.6
PLAYER_BULLETLIMIT = 20

Player = {}
Player.__index = Player

function Player.new(obj)
	local self = setmetatable({}, Player)
	self.value = obj
	return self
end

-- : inserts metatable at args called 'self'
function Player:init()
	-- init player
	self.go = GameObjectManager:createGameObject("PlayerOne")
	self.position = Vec3(0, 0, 0)
	self.yspeed = 0
	self.xspeed = 0
	self.physComp = self.go:createPhysicsComponent()
	self.cursorDirection = Vec3(0, 0, 0)
	self.cursorAngle = 0
	self.bullets = {}
	self.numBullets = 0

	local cinfo = CharacterRigidBodyCInfo {
		shape = PhysicsFactory:createSphere(PLAYER_SIZE),
		position = Vec3(0, 0, 0),
		enableDeactivation = false
	}

	self.rb = self.physComp:createRigidBody(cinfo)
	self.rb:setUserData(self)

	-- init bullets
	for i=1, PLAYER_BULLETLIMIT do
		local b = Bullet.new()
		b:init(i)
		self.bullets[i] = b
	end
end

function Player:update(f)
	-- controls (smooth movement w/ arrow keys)
	if (InputHandler:isPressed(Key.W) and (self.yspeed < PLAYER_MAXSPEED)) then 
		self.yspeed = self.yspeed - PLAYER_SPEEDINCR
	end
	if (InputHandler:isPressed(Key.S) and (self.yspeed > -PLAYER_MAXSPEED)) then 
		self.yspeed = self.yspeed + PLAYER_SPEEDINCR 
	end
	if (InputHandler:isPressed(Key.A) and (self.xspeed > -PLAYER_MAXSPEED)) then 
		self.xspeed = self.xspeed - PLAYER_SPEEDINCR
	end
	if (InputHandler:isPressed(Key.D) and (self.xspeed < PLAYER_MAXSPEED)) then 
		self.xspeed = self.xspeed + PLAYER_SPEEDINCR 
	end

	if (self.yspeed > 0) then
		self.yspeed = self.yspeed * PLAYER_SPEEDDECR
	elseif (self.yspeed < 0) then
		self.yspeed = self.yspeed * PLAYER_SPEEDDECR
	else
		self.yspeed = 0;
	end

	if (self.xspeed > 0) then
		self.xspeed = self.xspeed * PLAYER_SPEEDDECR
	elseif (self.xspeed < 0) then
		self.xspeed = self.xspeed * PLAYER_SPEEDDECR
	else
		self.xspeed = 0;
	end

	self.position.y = self.position.y + self.yspeed*f;
	self.position.x = self.position.x + self.xspeed*f;

	self.rb:setPosition(self.position)

	-- update player cursor
	if (InputHandler:isPressed(Key.Left)) then 
		self.cursorAngle = self.cursorAngle - PLAYER_ANGLEINCR*f
		if (self.cursorAngle < 0) then
			self.cursorAngle = 360 + self.cursorAngle
		end
	elseif (InputHandler:isPressed(Key.Right)) then 
		self.cursorAngle = self.cursorAngle + PLAYER_ANGLEINCR*f
		if (self.cursorAngle > 360) then
			self.cursorAngle = self.cursorAngle - 360
		end
	end

	self.cursorDirection = Vec3(math.sin(self.cursorAngle*PI)/180, math.cos(self.cursorAngle*PI)/180, 0)
	DebugRenderer:drawArrow(self.position, self.position + self.cursorDirection:mulScalar(2000))
	DebugRenderer:printText(Vec2(-0.8, 0.8), "cursor.angle:" .. self.cursorAngle .. " f:" .. f)

	-- update player bullets
	if (InputHandler:isPressed(Key.Space) and self.numBullets<1) then
		local b = self.bullets[self.numBullets+1]
		b:setActive(true)
		b.position = self.position
		b.angle = self.cursorAngle
		self.bullets[self.numBullets+1] = b
		self.numBullets = self.numBullets + 1
	end

	for _, b in ipairs(self.bullets) do
		if(b.active) then
			b:update(f)
		end
	end
end