-- enemy_1.lua
include("dualstick360/player.lua")
include("dualstick360/bullet.lua")
include("dualstick360/utils.lua")

Enemy_1 = {}
Enemy_1.__index = Enemy_1

ENEMY_1_SIZE = 2

ENEMY_1_BULLETLIMIT = 10 
ENEMY_1_BULLETDELAY = 1.5
ENEMY_1_BULLETSPEED = 8
ENEMY_1_BULLETSIZE = 1

ENEMY_1_TOWER_SIZE = 2
ENEMY_1_BOUNCING_SIZE = 3
ENEMY_1_MOVING_SIZE = 3

ENEMY_1_HP = 3
ENEMY_1_SCORE_VALUE = 10

ENEMY_1_ATTACKDISTANCE = 80

function Enemy_1.new()
	local self = setmetatable({}, Enemy_1)
	return self
end


function createEnemy_1_Moving(position, distance, clockwise,shootingDir)
	ENEMY_1_ARRAYSIZE = ENEMY_1_ARRAYSIZE + 1
	local e1 = Enemy_1.new()
	e1:init("enemy_1_" .. ENEMY_1_ARRAYSIZE, position, distance, clockwise, true,false,shootingDir, ENEMY_1_MOVING_SIZE)
	ENEMY_1_ARRAY[ENEMY_1_ARRAYSIZE] = e1
end

function createEnemy_1_Tower(position,shootingDir)
	ENEMY_1_ARRAYSIZE = ENEMY_1_ARRAYSIZE + 1
	local e1 = Enemy_1.new()
	e1:init("enemy_1_" .. ENEMY_1_ARRAYSIZE, position, 0, false, false,true,shootingDir, ENEMY_1_TOWER_SIZE)
	ENEMY_1_ARRAY[ENEMY_1_ARRAYSIZE] = e1
end

function createEnemy_1_Bouncing(position,shootingDir)
	ENEMY_1_ARRAYSIZE = ENEMY_1_ARRAYSIZE + 1
	local e1 = Enemy_1.new()
	e1:init("enemy_1_" .. ENEMY_1_ARRAYSIZE, position, 0, false, false, false,shootingDir, ENEMY_1_BOUNCING_SIZE)
	ENEMY_1_ARRAY[ENEMY_1_ARRAYSIZE] = e1
end



--shootingDir
--1 - Up
--2 - Down
--3 - Left
--4 - Right
--5 - Player

function Enemy_1:init(guid, startPosition, walkingDistance, clockwise, moving, tower, shootingDir, size)
	
	
	--gameobject
	self.go = GameObjectManager:createGameObject("e1_" .. guid)
	
	--physics component
	self.physComp = self.go:createPhysicsComponent()

	local cinfo = RigidBodyCInfo()
	cinfo.shape = PhysicsFactory:createBox(Vec3(size,size,size))
	cinfo.position = startPosition
	cinfo.mass = 0.4
	if(tower == true) then
		cinfo.motionType = MotionType.Fixed
	else
		cinfo.motionType = MotionType.Dynamic
	end
	cinfo.collisionFilterInfo = ENEMY_INFO

	self.rb = self.physComp:createRigidBody(cinfo)
	self.stateTimer = 0
	self.startPos = startPosition;
	self.walkDist = walkingDistance
	self.moveLeft = false
	self.moveUp = false
	self.clockwise = clockwise
	self.moving = moving
	self.shootingDir = shootingDir
	self.go:setComponentStates(ComponentState.Inactive)
	self.rb:setUserData(self)
	
	--healthpoints
	self.hp = 0
	
	
	--shooting variables
	if (self.shootingDir == 1) then
		self.cursorDirection = Vec3(0,-1,0)
	elseif(self.shootingDir == 2) then
		self.cursorDirection = Vec3(0,1,0)
	elseif(self.shootingDir == 3) then
		self.cursorDirection = Vec3(-1,0,0)
	elseif(self.shootingDir == 4) then
		self.cursorDirection = Vec3(1,0,0)
	else
		self.cursorDirection = Vec3(0, 0, 0)
	end
	
	
	self.numBullets = 0
	self.timeSinceLastShot = 0
	self.bullets = {}
	
	-- init bullets
	for i = 1, ENEMY_1_BULLETLIMIT do
		local b = Bullet.new(i)
		b:init(guid .. i, false,ENEMY_1_BULLETSIZE)
		self.bullets[i] = b
	end
	
	-- Update Statemachine -- Update Functions

	-- spawning - State
	self.spawningEnter = function(eventData)

		--random_xoffset = math.random(-40, 40) + 20
		--random_yoffset = math.random(-40, 40) + 20
		
		--self.rb:setPosition(Vec3((player.rb:getPosition().x + random_xoffset), (player.rb:getPosition().y + random_yoffset), 0.0))
		
		self.hp = ENEMY_1_HP
		
		self.go:setComponentStates(ComponentState.Active)
		
		
		return EventResult.Handled
	end
	
	
	
	-- walking - State
	self.walkingUpdate =  function(eventData)
	
		
		
		if(self.moving == true) then
		
			printText(self.go:getGuid() .. " hp: " .. self.hp)
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
			self.stateTimer = self.stateTimer - eventData:getElapsedTime()
		
		end
--[[		
		if (pos.x < -50) then
			self.moveLeft = false
		elseif (pos.x > 50) then
			self.moveLeft = true
		end
		if (self.moveLeft) then
			self.rb:setLinearVelocity(Vec3(-10, 0, 0))
		else
			self.rb:setLinearVelocity(Vec3(10, 0, 0))
		end
		
	]]--	
		--keep on z axe
		self.rb:setPosition(Vec3(self.rb:getPosition().x,self.rb:getPosition().y,0))
		return EventResult.Handled
	end
	
	
	-- attack_player - State
	self.attack_playerUpdate =  function(eventData)
	
		printText(self.go:getGuid() .. " hp: " .. self.hp)
		
		printText(self.go:getGuid() .. " hp: " .. self.hp)
		
		if(self.moving == true) then
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
			self.stateTimer = self.stateTimer - eventData:getElapsedTime()
		
		end
		
		
		if(self.shootingDir == 5) then
			self.cursorDirection = Vec3(player.rb:getPosition().x - self.rb:getPosition().x,player.rb:getPosition().y - self.rb:getPosition().y,0):normalized()
		end

		
		DebugRenderer:drawArrow(self.rb:getPosition(), self.rb:getPosition() + self.cursorDirection:mulScalar(ENEMY_1_SIZE*2))
		
		
		
		--keep on z axe
		self.rb:setPosition(Vec3(self.rb:getPosition().x,self.rb:getPosition().y,0))
		
		
		-- shoot bullets
		if(self.timeSinceLastShot>ENEMY_1_BULLETDELAY) then
			for _, b in ipairs(self.bullets) do
				if not (b.isActive) then
					b:activateBullet(self.rb:getPosition() + self.cursorDirection:mulScalar(ENEMY_1_SIZE*2), self.cursorDirection, ENEMY_1_BULLETSPEED)
					break
				end
			end
			self.timeSinceLastShot = 0
		
		end
		
		-- enable delay between shots
		if (self.timeSinceLastShot < ENEMY_1_BULLETDELAY) then
			self.timeSinceLastShot = self.timeSinceLastShot + eventData:getElapsedTime()
		end

		-- update active bullets
		local activeBullets = 0
		for _, b in ipairs(self.bullets) do
			if (b.isActive) then
				b:update(eventData:getElapsedTime())
				activeBullets = activeBullets + 1
			end
		end
		
		
		
		return EventResult.Handled
	end
	
	--attack condition
	
	self.attack_playerCondition = function(eventData)
	
		local x_distanceToPlayer = math.abs(player.rb:getPosition().x - self.rb:getPosition().x) 
		local y_distanceToPlayer = math.abs(player.rb:getPosition().y - self.rb:getPosition().y) 
		
		if((x_distanceToPlayer < ENEMY_1_ATTACKDISTANCE and y_distanceToPlayer < ENEMY_1_ATTACKDISTANCE) or self.hp < ENEMY_1_HP )then
			return true
		else
			return false
		end
		
	end
	
	
	-- dead -State
	
	self.deadEnter = function(eventData)
		
		player.score = player.score + ENEMY_1_SCORE_VALUE
		
		for _, b in ipairs(self.bullets) do
			if (b.isActive) then
				b:reset()
			end
		end
		
		self.go:setComponentStates(ComponentState.Inactive)
		
		return EventResult.Handled
	
	end
	
	-- dead condition
	
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
	
	
	self.fsm = StateMachine{ 
	
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
				
					enter = {self.deadEnter}
				
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











