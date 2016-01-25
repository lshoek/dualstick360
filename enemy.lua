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
ENEMY_HP = 3

-- behaviour types
ENEMY_BEHAVIOURTYPE_MOVE = 0
ENEMY_BEHAVIOURTYPE_TOWER = 1
ENEMY_BEHAVIOURTYPE_BOUNCE = 2
ENEMY_BEHAVIOURTYPE_STALKER = 3

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

function createEnemy(position, behaviourType, distance, clockwise, shootingDir)
	local e = Enemy.new()
	ENEMY_ARRAYSIZE = ENEMY_ARRAYSIZE + 1
	e:init("e" .. ENEMY_ARRAYSIZE, position, behaviourType, distance, clockwise, shootingDir)
	ENEMY_ARRAY[ENEMY_ARRAYSIZE] = e
end

function Enemy:init(guid, startPosition, behaviourType, walkingDistance, clockwise, shootingDir)
	self.go = GameObjectManager:createGameObject(guid)
	self.go:setBaseViewDirection(Vec3(0, -1, 0):normalized())
	self.physComp = self.go:createPhysicsComponent()

	local cinfo = RigidBodyCInfo()
	cinfo.shape = PhysicsFactory:createBox(Vec3(ENEMY_SIZE, ENEMY_SIZE, ENEMY_SIZE))
	cinfo.position = startPosition
	cinfo.mass = 1
	cinfo.linearDamping = 2.5
	cinfo.angularDamping = 1
	cinfo.restitution = 0
	cinfo.friction = 0
	cinfo.collisionFilterInfo = ENEMY_INFO
	cinfo.motionType = MotionType.Dynamic
	if(behaviourType == ENEMY_BEHAVIOURTYPE_TOWER) then
		cinfo.motionType = MotionType.Fixed
	end

	-- store parameters
	self.startPos = startPosition
	self.behaviourType = behaviourType
	self.walkDist = walkingDistance
	self.clockwise = clockwise
	self.shootingDir = shootingDir

	-- other variables
	self.hp = 0
	self.stateTimer = 0
	self.moveLeft = false
	self.moveUp = false
	self.moving = moving
	self.numBullets = 0
	self.timeSinceLastShot = 0
	self.bullets = {}

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
	for i = 1, ENEMY_BULLETLIMIT do
		local b = Bullet.new(i)
		b:init(guid .. i, false, ENEMY_BULLETSIZE)
		self.bullets[i] = b
	end
	
	-- spawning - State
	self.spawningEnter = function(eventData)
		self.hp = ENEMY_HP
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
				self.rb:applyLinearImpulse(viewDirection:mulScalar(ENEMY_SPEED))
				self.rb:setAngularVelocity(Vec3(0, 0, rotationSpeed))
			end
			DebugRenderer:drawArrow(self.rb:getPosition(), self.rb:getPosition() + viewDirection:mulScalar(10))
		end
		
		-- shoot bullets
		if (self.timeSinceLastShot > ENEMY_BULLETDELAY) then
			for _, b in ipairs(self.bullets) do
				if not (b.isActive) then
					local normalTargetdir = self.targetDirection:normalized()
					b:activateBullet(self.rb:getPosition() + normalTargetdir:mulScalar(ENEMY_SIZE*2), normalTargetdir, ENEMY_BULLETSPEED)
					break
				end
			end
			self.timeSinceLastShot = 0
		end
		
		-- enable delay between shots
		if (self.timeSinceLastShot < ENEMY_BULLETDELAY) then
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
		if (distanceToPlayer < ENEMY_ATTACKDISTANCE or self.hp < ENEMY_HP ) then
			return true
		else
			return false
		end	
	end

	-- walk condition
	self.walkCondition = function(eventData)
		local distanceToPlayer = (player.rb:getPosition() - self.rb:getPosition()):length()
		if (distanceToPlayer > ENEMY_ATTACKDISTANCE) then
			return true
		else
			return false
		end		
	end
	
	-- death - State
	self.deadEnter = function(eventData)
		player.score = player.score + ENEMY_SCORE_VALUE
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