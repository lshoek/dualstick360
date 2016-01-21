-- enemy_1.lua
include("dualstick360/player.lua")
include("dualstick360/bullet.lua")
include("dualstick360/utils.lua")

Enemy_1 = {}
Enemy_1.__index = Enemy_1

ENEMY_1_SIZE = 8

ENEMY_1_BULLETLIMIT = 10 
ENEMY_1_BULLETDELAY = 0.8
ENEMY_1_BULLETSPEED = 6
ENEMY_1_BULLETSIZE = 1

ENEMY_1_HP = 10
ENEMY_1_SCORE_VALUE = 10

ENEMY_1_ATTACKDISTANCE = 30

function Enemy_1.new()
	local self = setmetatable({}, Enemy_1)
	return self
end



function Enemy_1:init(guid)
	
	
	--gameobject
	self.go = GameObjectManager:createGameObject("e1_" .. guid)
	
	--random spawning
	random_xoffset = math.random(-40,40) + 20
	random_yoffset = math.random(-40,40) + 20
	
	--physics component
	self.physComp = self.go:createPhysicsComponent()

	local cinfo = RigidBodyCInfo()
	cinfo.shape = PhysicsFactory:createBox(Vec3(ENEMY_1_SIZE,ENEMY_1_SIZE,ENEMY_1_SIZE))
	cinfo.position = Vec3(random_xoffset, random_yoffset, 0)
	cinfo.mass = 0.5
	cinfo.motionType = MotionType.Dynamic
	cinfo.collisionFilterInfo = ENEMY_INFO

	self.rb = self.physComp:createRigidBody(cinfo)
	self.stateTimer = 0
	self.moveLeft = false
	self.go:setComponentStates(ComponentState.Inactive)
	self.rb:setUserData(self)
	
	--healthpoints
	self.hp = 0
	
	
	--shooting variables
	self.cursorDirection = Vec3(0, 0, 0)
	self.numBullets = 0
	self.timeSinceLastShot = 0
	self.bullets = {}
	
	-- init bullets
	for i = 1, ENEMY_1_BULLETLIMIT do
		local b = Bullet.new(i)
		b:init(guid .. i, ENEMY_1_BULLETSIZE)
		self.bullets[i] = b
	end
	
	-- Update Statemachine -- Update Functions
	
	-- collision event
	self.Bullet_collision = function(eventData)
		local rigidBody = eventData:getBody(CollisionArgsCallbackSource.A)
	
		for i=1, PLAYER_BULLETLIMIT do
			if rigidBody:equals(player.bullets[i].rb) then
				self.hp = self.hp - 1			
			end
		end
	
		return EventResult.Handled

	end

	self.physComp:getContactPointEvent():registerListener(self.Bullet_collision)
	
	
	
	-- spawning - State
	self.spawningEnter = function(eventData)

		random_xoffset = math.random(-40, 40) + 20
		random_yoffset = math.random(-40, 40) + 20
		
		self.rb:setPosition(Vec3((player.rb:getPosition().x + random_xoffset), (player.rb:getPosition().y + random_yoffset), 0.0))
		
		self.hp = ENEMY_1_HP
		
		self.go:setComponentStates(ComponentState.Active)
		
		
		return EventResult.Handled
	end
	
	
	
	-- walking - State
	self.walkingUpdate =  function(eventData)
	
		--printText(self.go:getGuid() .. " hp: " .. self.hp)
		local pos = self.go:getPosition()
		
		
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
		self.rb:setAngularVelocity(Vec3(0, 0, 0))
		self.stateTimer = self.stateTimer - eventData:getElapsedTime()
		
		--keep on z axe
		self.rb:setPosition(Vec3(self.rb:getPosition().x,self.rb:getPosition().y,0))
		return EventResult.Handled
	end
	
	
	-- attack_player - State
	self.attack_playerUpdate =  function(eventData)
	
		--printText(self.go:getGuid() .. " hp: " .. self.hp)
		
		local pos = self.go:getPosition()
		if (pos.y < -50) then
			self.moveLeft = false
		elseif (pos.y > 50) then
			self.moveLeft = true
		end
		if (self.moveLeft) then
			self.rb:setLinearVelocity(Vec3(0, -10, 0))
		else
			self.rb:setLinearVelocity(Vec3(0, 10, 0))
		end
		self.rb:setAngularVelocity(Vec3(0, 0, 0))
		self.stateTimer = self.stateTimer - eventData:getElapsedTime()
		
		self.cursorDirection = Vec3(player.rb:getPosition().x - self.rb:getPosition().x,player.rb:getPosition().y - self.rb:getPosition().y,0):normalized()
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











