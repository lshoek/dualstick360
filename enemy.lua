include("dualstick360/globals.lua")
include("dualstick360/player.lua")
include("dualstick360/bullet.lua")
include("dualstick360/utils.lua")

Enemy = {}
Enemy.__index = Enemy

function Enemy.new()
	local self = setmetatable({}, Enemy)
	return self
end

function createEnemy(position, behaviourType, size, distance, clockwise, shootingDir,strong)
	local e = Enemy.new()
	ENEMY_ARRAYSIZE = ENEMY_ARRAYSIZE + 1
	e:init("e" .. ENEMY_ARRAYSIZE, position, behaviourType, size, distance, clockwise, shootingDir, strong)
	enemyArray[ENEMY_ARRAYSIZE] = e
end

function Enemy:init(guid, startPosition, behaviourType, size, walkingDistance, clockwise, shootingDir,strong)
	-- just defaults
	self.go = GameObjectManager:createGameObject(guid)
	self.go:setBaseViewDirection(Vec3(0, -1, 0):normalized())
	self.physComp = self.go:createPhysicsComponent()

	local cinfo = RigidBodyCInfo()
	if not (behaviourType == ENEMY_BEHAVIOURTYPE_BOSS) then
        --create Rendercomponent
        self.rc = self.go:createRenderComponent()
		self.rc:setPath("data/models/box.thModel")
		self.rc:setScale(Vec3(size, size/2, size))
        cinfo.shape = PhysicsFactory:createBox(Vec3(size, size, size))
    else
   		cinfo.shape = PhysicsFactory:createSphere(size)
    end


    cinfo.mass = 1
	cinfo.linearDamping = 2.5
	cinfo.restitution = 0
    cinfo.position = startPosition
	cinfo.angularDamping = 1
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
	self.bulletTypeStrong = strong
	self.attackDistance = ENEMY_ATTACKDISTANCE
	self.scoreValue = ENEMY_SCORE_VALUE

	self.attackTimer = 1
	self.moveLeft = false
	self.moveUp = false
	self.timeSinceLastShot = 0
	self.bullets = {}
	
	-- init bullets
	for i = 1, self.bulletLimit do
		local b = Bullet.new(i)
		b:init(guid .. i, false, self.bulletTypeStrong)
		self.bullets[i] = b
	end

	-- specific behaviour types (overwrite defaults)
	if(behaviourType == ENEMY_BEHAVIOURTYPE_MOVE) then
		self.speed = ENEMY_TYPE_MOVE_SPEED
		cinfo.linearDamping = 0
	end
	if(behaviourType == ENEMY_BEHAVIOURTYPE_BOUNCE) then
        cinfo.mass = 0.1
		cinfo.linearDamping = 0.6
		cinfo.restitution = 1
    end
	if(behaviourType == ENEMY_BEHAVIOURTYPE_TOWER) then
		cinfo.motionType = MotionType.Fixed
	end
	if(behaviourType == ENEMY_BEHAVIOURTYPE_BOSS) then
		cinfo.mass = 1000
		self.hp = 150
		self.speed = 300
		self.bulletLimit = 100 + 60
		self.bulletDelay = 0.2
		self.bulletSpeed = ENEMY_BULLETSPEED
		self.bulletSize = 3
		self.attackDistance = 200
		self.scoreValue = 1000
		
		for i = 1, self.bulletLimit do
		local b = Bullet.new(i)
			if(i < 100) then
				b:init(guid .. i, false, true)
			else
				b:init(guid .. i, false, false)
			end
			self.bullets[i] = b
		end
		
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
			local speed = self.speed
			printText("movespeed: " .. self.speed)
		
			if(self.clockwise == true) then		
				if(self.moveLeft == false and self.moveUp == false) then
					self.rb:setLinearVelocity(Vec3(speed, 0, 0))
					if(pos.x > startPos.x + walkingDist) then
						self.moveUp = true
					end
				elseif(self.moveLeft == false and self.moveUp == true) then
					self.rb:setLinearVelocity(Vec3(0, speed, 0))
					if(pos.y > startPos.y + walkingDist) then
						self.moveLeft = true
					end
				elseif(self.moveLeft == true and self.moveUp == true) then
					self.rb:setLinearVelocity(Vec3(-speed, 0, 0))
					if(pos.x < startPos.x) then
						self.moveUp = false
					end
				elseif(self.moveLeft == true and self.moveUp == false) then
					self.rb:setLinearVelocity(Vec3(0, -speed, 0))
					if(pos.y < startPos.y) then
						self.moveLeft = false
					end
				end
			else
				if(self.moveLeft == false and self.moveUp == false) then
					self.rb:setLinearVelocity(Vec3(0, -speed, 0))
					if(pos.y < startPos.y) then
						self.moveLeft = true
					end
				elseif(self.moveLeft == false and self.moveUp == true) then
					self.rb:setLinearVelocity(Vec3(speed, 0, 0))
					if(pos.x > startPos.x + walkingDist) then
						self.moveUp = false
					end
				elseif(self.moveLeft == true and self.moveUp == true) then
					self.rb:setLinearVelocity(Vec3(0, speed, 0))
					if(pos.y > startPos.y + walkingDist) then
						self.moveLeft = false
					end
				elseif(self.moveLeft == true and self.moveUp == false) then
					self.rb:setLinearVelocity(Vec3(-speed, 0, 0))
					if(pos.x < startPos.x) then
						self.moveUp = true
					end
				end
			end
			self.rb:setAngularVelocity(Vec3(0, 0, 0))
		end

		-- reposition enemy on z axis
		self.rb:setPosition(Vec3(self.rb:getPosition().x, self.rb:getPosition().y,0))
		return EventResult.Handled
	end

	-- attack_player - State
	self.attack_playerUpdate = function(eventData)
		if (self.shootingDir == ENEMY_SHOOTINGDIR_PLAYER) then
			self.targetDirection = player.rb:getPosition() - self.rb:getPosition()
		end

		if (self.behaviourType == ENEMY_BEHAVIOURTYPE_MOVE) then
			local pos = self.go:getPosition()
			local startPos = self.startPos
			local walkingDist = self.walkDist
			local speed = self.speed
			
			if (self.clockwise == true) then
				if (self.moveLeft == false and self.moveUp == false) then
					self.rb:setLinearVelocity(Vec3(speed, 0, 0))
					if (pos.x > startPos.x + walkingDist) then
						self.moveUp = true
					end
				elseif (self.moveLeft == false and self.moveUp == true) then
					self.rb:setLinearVelocity(Vec3(0, speed, 0))
					if (pos.y > startPos.y + walkingDist) then
						self.moveLeft = true
					end
				elseif (self.moveLeft == true and self.moveUp == true) then
					self.rb:setLinearVelocity(Vec3(-speed, 0, 0))
					if (pos.x < startPos.x) then
						self.moveUp = false
					end
				elseif (self.moveLeft == true and self.moveUp == false) then
					self.rb:setLinearVelocity(Vec3(0, -speed, 0))
					if (pos.y < startPos.y) then
						self.moveLeft = false
					end
				end
			else
				if (self.moveLeft == false and self.moveUp == false) then
					self.rb:setLinearVelocity(Vec3(0, -speed, 0))
					if (pos.y < startPos.y) then
						self.moveLeft = true
					end
				elseif (self.moveLeft == false and self.moveUp == true) then
					self.rb:setLinearVelocity(Vec3(speed, 0, 0))
					if (pos.x > startPos.x + walkingDist) then
						self.moveUp = false
					end
				elseif (self.moveLeft == true and self.moveUp == true) then
					self.rb:setLinearVelocity(Vec3(0, speed, 0))
					if (pos.y > startPos.y + walkingDist) then
						self.moveLeft = false
					end
				elseif (self.moveLeft == true and self.moveUp == false) then
					self.rb:setLinearVelocity(Vec3(-speed, 0, 0))
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
			printText("attackTimer: " .. self.attackTimer)
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
				--boss attack code
				self.attackTimer = ((self.attackTimer + 1)%ENEMY_TYPE_BOSS_SPECIALATTACKRATE)
				if (self.attackTimer == 0) then
					for i=1, 60 do
						for i=100, self.bulletLimit do
							local b = self.bullets[i]
							if not (b.isActive) then
								local normalTargetDir = self.targetDirection:normalized()
								normalTargetDir = rotateVector(normalTargetDir, Vec3(0, 0, 1), i*(360/60))
								b:activateBullet(self.rb:getPosition() + normalTargetDir:mulScalar(self.size*1.05), normalTargetDir, self.bulletSpeed)
								break
							end
						end
					end
				end

				for i=1, 100 do
					local b = self.bullets[i]
					if not (b.isActive) then
						local normalTargetDir = self.targetDirection:normalized()
						normalTargetDir = rotateVector(normalTargetDir, Vec3(0, 0, 1), math.random(-ENEMY_TYPE_BOSS_NORMALATTACKSCATTER, ENEMY_TYPE_BOSS_NORMALATTACKSCATTER))
						b:activateBullet(self.rb:getPosition() + normalTargetDir:mulScalar(self.size*1.05), normalTargetDir, self.bulletSpeed)
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
		if (self.behaviourType == ENEMY_BEHAVIOURTYPE_BOSS) then
			BOSS_CONDITION_BEATEN = true

		end
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