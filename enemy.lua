include("dualstick360/player.lua")
include("dualstick360/bullet.lua")
include("dualstick360/utils.lua")

Enemy = {}
Enemy.__index = Enemy

-- standard parameters (may be overwritten)
ENEMY_SIZE = 8
ENEMY_SPEED = 7.5
ENEMY_ROTATIONSPEED = 10
ENEMY_BULLETLIMIT = 10 
ENEMY_BULLETDELAY = 1.0
ENEMY_BULLETSPEED = 15
ENEMY_BULLETSIZE = 3
ENEMY_ATTACKDISTANCE = 100
ENEMY_SCORE_VALUE = 10
ENEMY_HP = 10

-- behaviour types
ENEMY_BEHAVIOURTYPE_MOVE = 0
ENEMY_BEHAVIOURTYPE_TOWER = 1
ENEMY_BEHAVIOURTYPE_BOUNCE = 2
ENEMY_BEHAVIOURTYPE_STALKER = 3
ENEMY_BEHAVIOURTYPE_BOSS = 9

-- shooting directions
ENEMY_SHOOTINGDIR_UP = 0
ENEMY_SHOOTINGDIR_DOWN = 1
ENEMY_SHOOTINGDIR_LEFT = 2
ENEMY_SHOOTINGDIR_RIGHT = 3
ENEMY_SHOOTINGDIR_PLAYER = 4

function Enemy.new()
	local self = setmetatable({}, Enemy)
	return self
end

function createEnemy(position, behaviourType, size, distance, clockwise, shootingDir)
	local e = Enemy.new()
	ENEMY_ARRAYSIZE = ENEMY_ARRAYSIZE + 1
	e:init("e" .. ENEMY_ARRAYSIZE, position, behaviourType, size, distance, clockwise, shootingDir)
	ENEMY_ARRAY[ENEMY_ARRAYSIZE] = e
end

function Enemy:init(guid, startPosition, behaviourType, size, walkingDistance, clockwise, shootingDir)
	-- just defaults
	self.go = GameObjectManager:createGameObject(guid)
	self.go:setBaseViewDirection(Vec3(0, -1, 0):normalized())
	self.physComp = self.go:createPhysicsComponent()

	local cinfo = RigidBodyCInfo()
	cinfo.shape = PhysicsFactory:createBox(Vec3(size, size, size))
	cinfo.position = startPosition
	cinfo.mass = 1
	cinfo.linearDamping = 2.5
	cinfo.angularDamping = 1
	cinfo.restitution = 0
	cinfo.friction = 0
	cinfo.collisionFilterInfo = ENEMY_INFO
	cinfo.motionType = MotionType.Dynamic

	-- store parameters
	self.startPos = startPosition
	self.behaviourType = behaviourType
	self.walkDist = walkingDistance
	self.clockwise = clockwise
	self.shootingDir = shootingDir

	-- other variables
	self.size = size
	self.hp = ENEMY_HP
	self.speed = ENEMY_SPEED
	self.bulletLimit = ENEMY_BULLETLIMIT
	self.bulletDelay = ENEMY_BULLETDELAY
	self.bulletSpeed = ENEMY_BULLETSPEED
	self.bulletSize = ENEMY_BULLETSIZE
	self.attackDistance = ENEMY_ATTACKDISTANCE
	self.scoreValue = ENEMY_SCORE_VALUE

	self.stateTimer = 0
	self.moveLeft = false
	self.moveUp = false
	self.moving = moving
	self.numBullets = 0
	self.timeSinceLastShot = 0
	self.bullets = {}

	-- specific behaviour types (overwrite defaults)
	if(behaviourType == ENEMY_BEHAVIOURTYPE_TOWER) then
		cinfo.motionType = MotionType.Fixed
	end
	if(behaviourType == ENEMY_BEHAVIOURTYPE_BOSS) then
		cinfo.mass = 1000
		self.hp = 150
		self.speed = 300
		self.bulletLimit = 100
		self.bulletDelay = 0.1
		self.bulletSpeed = ENEMY_BULLETSPEED
		self.bulletSize = 3
		self.attackDistance = 200
		self.scoreValue = 1000
	end

	self.rb = self.physComp:createRigidBody(cinfo)
	self.go:setComponentStates(ComponentState.Inactive)
	self.rb:setUserData(self)
	
	-- shooting direction
	self.targetDirection = Vec3(0, 0, 0)
	if (self.shootingDir == ENEMY_SHOOTINGDIR_UP) then
		self.targetDirection = Vec3(0, -1, 0)
	elseif(self.shootingDir == ENEMY_SHOOTINGDIR_DOWN) then
		self.targetDirection = Vec3(0, 1, 0)
	elseif(self.shootingDir == ENEMY_SHOOTINGDIR_LEFT) then
		self.targetDirection = Vec3(-1, 0, 0)
	elseif(self.shootingDir == ENEMY_SHOOTINGDIR_RIGHT) then
		self.targetDirection = Vec3(1, 0, 0)
	end
	
	-- init bullets
	for i = 1, self.bulletLimit do
		local b = Bullet.new(i)
		b:init(guid .. i, false, self.bulletSize)
		self.bullets[i] = b
	end
	
	-- spawning - State
	self.spawningEnter = function(eventData)
		self.go:setComponentStates(ComponentState.Active)
		return EventResult.Handled
	end
	
	-- walking - State
	self.walkingUpdate =  function(eventData)
		if (self.behaviourType == ENEMY_BEHAVIOURTYPE_MOVE) then
			local pos = self.go:getPosition()
			local startPos = self.startPos
			local walkingDist = self.walkDist
		
			if(self.clockwise == true) then		
				if(self.moveLeft == false and self.moveUp == false) then
					self.rb:setLinearVelocity(Vec3(10, 0, 0))
					if(pos.x > startPos.x + walkingDist) then
						self.moveUp = true
					end
				elseif(self.moveLeft == false and self.moveUp == true) then
					self.rb:setLinearVelocity(Vec3(0, 10, 0))
					if(pos.y > startPos.y + walkingDist) then
						self.moveLeft = true
					end
				elseif(self.moveLeft == true and self.moveUp == true) then
					self.rb:setLinearVelocity(Vec3(-10, 0, 0))
					if(pos.x < startPos.x) then
						self.moveUp = false
					end
				elseif(self.moveLeft == true and self.moveUp == false) then
					self.rb:setLinearVelocity(Vec3(0, -10, 0))
					if(pos.y < startPos.y) then
						self.moveLeft = false
					end
				end
			else
				if(self.moveLeft == false and self.moveUp == false) then
					self.rb:setLinearVelocity(Vec3(0, -10, 0))
					if(pos.y < startPos.y) then
						self.moveLeft = true
					end
				elseif(self.moveLeft == false and self.moveUp == true) then
					self.rb:setLinearVelocity(Vec3(10, 0, 0))
					if(pos.x > startPos.x + walkingDist) then
						self.moveUp = false
					end
				elseif(self.moveLeft == true and self.moveUp == true) then
					self.rb:setLinearVelocity(Vec3(0, 10, 0))
					if(pos.y > startPos.y + walkingDist) then
						self.moveLeft = false
					end
				elseif(self.moveLeft == true and self.moveUp == false) then
					self.rb:setLinearVelocity(Vec3(-10, 0, 0))
					if(pos.x < startPos.x) then
						self.moveUp = true
					end
				end
			end
			self.rb:setAngularVelocity(Vec3(0, 0, 0))
		end
		self.stateTimer = self.stateTimer - eventData:getElapsedTime()

		-- reposition enemy on z axis
		self.rb:setPosition(Vec3(self.rb:getPosition().x, self.rb:getPosition().y,0))
		return EventResult.Handled
	end

	-- attack_player - State
	self.attack_playerUpdate = function(eventData)
		if (self.shootingDir == ENEMY_SHOOTINGDIR_PLAYER) then
			self.targetDirection = player.rb:getPosition() - self.rb:getPosition()
			printText("UPDATE")
		end

		if (self.behaviourType == ENEMY_BEHAVIOURTYPE_MOVE) then
			local pos = self.go:getPosition()
			local startPos = self.startPos
			local walkingDist = self.walkDist
			
			if (self.clockwise == true) then
				if (self.moveLeft == false and self.moveUp == false) then
					self.rb:setLinearVelocity(Vec3(10, 0, 0))
					if (pos.x > startPos.x + walkingDist) then
						self.moveUp = true
					end
				elseif (self.moveLeft == false and self.moveUp == true) then
					self.rb:setLinearVelocity(Vec3(0, 10, 0))
					if (pos.y > startPos.y + walkingDist) then
						self.moveLeft = true
					end
				elseif (self.moveLeft == true and self.moveUp == true) then
					self.rb:setLinearVelocity(Vec3(-10, 0, 0))
					if (pos.x < startPos.x) then
						self.moveUp = false
					end
				elseif (self.moveLeft == true and self.moveUp == false) then
					self.rb:setLinearVelocity(Vec3(0, -10, 0))
					if (pos.y < startPos.y) then
						self.moveLeft = false
					end
				end
			else
				if (self.moveLeft == false and self.moveUp == false) then
					self.rb:setLinearVelocity(Vec3(0, -10, 0))
					if (pos.y < startPos.y) then
						self.moveLeft = true
					end
				elseif (self.moveLeft == false and self.moveUp == true) then
					self.rb:setLinearVelocity(Vec3(10, 0, 0))
					if (pos.x > startPos.x + walkingDist) then
						self.moveUp = false
					end
				elseif (self.moveLeft == true and self.moveUp == true) then
					self.rb:setLinearVelocity(Vec3(0, 10, 0))
					if (pos.y > startPos.y + walkingDist) then
						self.moveLeft = false
					end
				elseif (self.moveLeft == true and self.moveUp == false) then
					self.rb:setLinearVelocity(Vec3(-10, 0, 0))
					if (pos.x < startPos.x) then
						self.moveUp = true
					end
				end
			end
			self.rb:setAngularVelocity(Vec3(0, 0, 0))

		elseif (self.behaviourType == ENEMY_BEHAVIOURTYPE_STALKER) then
			local viewDirection = self.go:getViewDirection()
			local distance = self.targetDirection:length()
			if (distance > 10) then
				local steer = calcSteering(self, self.targetDirection:normalized())
				local rotationSpeed = ENEMY_ROTATIONSPEED * -steer
				self.rb:applyLinearImpulse(viewDirection:mulScalar(self.speed))
				self.rb:setAngularVelocity(Vec3(0, 0, rotationSpeed))
			end
			DebugRenderer:drawArrow(self.rb:getPosition(), self.rb:getPosition() + viewDirection:mulScalar(10))

		elseif (self.behaviourType == ENEMY_BEHAVIOURTYPE_BOSS) then
			local viewDirection = self.go:getViewDirection()
			local steer = calcSteering(self, self.targetDirection:normalized())
			local rotationSpeed = ENEMY_ROTATIONSPEED * -steer
			self.rb:applyLinearImpulse(viewDirection:mulScalar(self.speed))
			self.rb:setAngularVelocity(Vec3(0, 0, rotationSpeed))
			DebugRenderer:drawArrow(self.rb:getPosition(), self.rb:getPosition() + viewDirection:mulScalar(10))
			printText("BOSS HP: " .. self.hp)
		end
		
		-- shoot bullets
		if (self.timeSinceLastShot > self.bulletDelay) then
			if not (self.behaviourType == ENEMY_BEHAVIOURTYPE_BOSS) then
				for _, b in ipairs(self.bullets) do
					if not (b.isActive) then
						local normalTargetDir = self.targetDirection:normalized()
						b:activateBullet(self.rb:getPosition() + normalTargetDir:mulScalar(self.size*2), normalTargetDir, self.bulletSpeed)
						break
					end
				end
				self.timeSinceLastShot = 0
			else
				for _, b in ipairs(self.bullets) do
					if not (b.isActive) then
						local normalTargetDir = self.targetDirection:normalized()
						normalTargetDir = rotateVector(normalTargetDir, Vec3(0, 0, 1), math.random(-30, 30))
						b:activateBullet(self.rb:getPosition() + normalTargetDir:mulScalar(self.size*1.3), normalTargetDir, self.bulletSpeed)
						break
					end
				end
				self.timeSinceLastShot = 0
			end
		end
		
		-- enable delay between shots
		if (self.timeSinceLastShot < self.bulletDelay) then
			self.timeSinceLastShot = self.timeSinceLastShot + eventData:getElapsedTime()
		end		

		-- reposition enemy on z axis
		self.rb:setPosition(Vec3(self.rb:getPosition().x, self.rb:getPosition().y, 0))
		self.stateTimer = self.stateTimer - eventData:getElapsedTime()

		return EventResult.Handled
	end
	
	-- attack condition
	self.attack_playerCondition = function(eventData)
		local distanceToPlayer = (player.rb:getPosition() - self.rb:getPosition()):length()
		if (distanceToPlayer < self.attackDistance) then
			return true
		else
			return false
		end	
	end

	-- walk condition
	self.walkCondition = function(eventData)
		local distanceToPlayer = (player.rb:getPosition() - self.rb:getPosition()):length()
		if (distanceToPlayer > self.attackDistance) then
			return true
		else
			return false
		end		
	end
	
	-- death - State
	self.deadEnter = function(eventData)
		player.score = player.score + self.scoreValue
		for _, b in ipairs(self.bullets) do
			if (b.isActive) then
				b:reset()
			end
		end
		self.go:setComponentStates(ComponentState.Inactive)
		return EventResult.Handled
	end
	
	-- death condition
	self.deadCondition = function(eventData)
		if(self.hp <= 0) or (InputHandler:wasTriggered(Key.K)) then
			return true
		else
			return false
		end
	end
	
	--StateMachine
	io.write("/".. guid .. "FSM")
	self.fsm_name = guid .. "FSM"
	
	self.fsm = StateMachine { 
		name = guid .. "FSM",
		parent = "/game" ,
		states = {
			{
				name = "spawning",
				eventListeners = {	
					enter = { self.spawningEnter },			
				}	
			},
			{
				name = "walking",
				eventListeners = {
					update = { 
						self.walkingUpdate 
					}	
				}
			},
			{
				name = "attack_player",
				eventListeners = {
					update = {
						self.attack_playerUpdate
					}
				}
			},
			{
				name = "dead",
				eventListeners = {		
					enter = {
						self.deadEnter
					}			
				}
			}
		},
		transitions = {
			{ from = "__enter", to = "spawning"},
			{ from = "spawning", to = "walking"},
			{ from = "walking", to = "attack_player", condition = self.attack_playerCondition},
			{ from = "attack_player", to = "walking",	condition = function() return InputHandler:wasTriggered(Key.O) end},
			{ from = "walking", to ="dead", condition = self.deadCondition},
			{ from = "attack_player", to = "dead", condition = self.deadCondition},
			{ from = "dead", to = "spawning", condition = function() return InputHandler:wasTriggered(Key.R) end}
		}	
	}
	self.fsm:run() 
end