include("dualstick360/player.lua")
include("dualstick360/bullet.lua")
include("dualstick360/utils.lua")

Enemy_2 = {}
Enemy_2.__index = Enemy_2

ENEMY_2_SIZE = 5
ENEMY_2_SPEED = 20
ENEMY_2_ROTATIONSPEED = 5
ENEMY_2_BULLETLIMIT = 10
ENEMY_2_BULLETDELAY = 0.8
ENEMY_2_BULLETSPEED = 4
ENEMY_2_BULLETSIZE = 3
ENEMY_2_HP = 10
ENEMY_2_SCORE_VALUE = 10
ENEMY_2_ATTACKDISTANCE = 100

function Enemy_2.new()
	local self = setmetatable({}, Enemy_2)
	return self
end

function Enemy_2:init(guid)
	self.go = GameObjectManager:createGameObject("e2_" .. guid)
	self.go:setBaseViewDirection(Vec3(0, -1, 0):normalized())
	
	-- physics component
	self.physComp = self.go:createPhysicsComponent()

	local cinfo = RigidBodyCInfo()
	cinfo.shape = PhysicsFactory:createBox(Vec3(ENEMY_2_SIZE, ENEMY_2_SIZE, ENEMY_2_SIZE))
	cinfo.position = Vec3(0, 0, 0)
	cinfo.mass = 5
	cinfo.motionType = MotionType.Dynamic
	cinfo.collisionFilterInfo = ENEMY_INFO
	cinfo.restitution = 0
	cinfo.friction = 0
	cinfo.linearDamping = 2.5
	cinfo.angularDamping = 1

	self.rb = self.physComp:createRigidBody(cinfo)
	self.stateTimer = 0
	self.moveLeft = false
	self.go:setComponentStates(ComponentState.Inactive)
	self.rb:setUserData(self)
	
	--healthpoints
	self.hp = 0
	
	--shooting variables
	self.numBullets = 0
	self.timeSinceLastShot = 0
	self.bullets = {}
	
	-- init bullets
	for i = 1, ENEMY_2_BULLETLIMIT do
		local b = Bullet.new(i)
		b:init(guid .. i, false, ENEMY_2_BULLETSIZE)
		self.bullets[i] = b
	end
	
	-- STATEMACHINE UPDATE

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
		random_xoffset = math.random(-160, 160) + 20
		random_yoffset = math.random(-160, 160) + 20
		self.rb:setPosition(Vec3((player.rb:getPosition().x + random_xoffset), (player.rb:getPosition().y + random_yoffset), 0.0))
		self.hp = ENEMY_2_HP
		self.go:setComponentStates(ComponentState.Active)
		return EventResult.Handled
	end
	
	-- walking
	self.walkingUpdate = function(eventData)
		-- do nothing
		self.rb:setPosition(Vec3(self.rb:getPosition().x, self.rb:getPosition().y, 0))
		self.stateTimer = self.stateTimer - eventData:getElapsedTime()
		return EventResult.Handled
	end
	
	-- attack_player
	self.attack_playerUpdate =  function(eventData)
		local targetDirection = Vec3(player.rb:getPosition() - self.rb:getPosition())
		local viewDirection = self.go:getViewDirection()
		local distance = targetDirection:length()
		if (distance > 10) then
			local steer = calcSteering(self, targetDirection:normalized())
			local rotationSpeed = ENEMY_2_ROTATIONSPEED * -steer
			self.rb:applyLinearImpulse(viewDirection:mulScalar(ENEMY_2_SPEED))
			self.rb:setAngularVelocity(Vec3(0, 0, rotationSpeed))
		end
		DebugRenderer:drawArrow(self.rb:getPosition(), self.rb:getPosition() + viewDirection:mulScalar(10))

		self.rb:setPosition(Vec3(self.rb:getPosition().x, self.rb:getPosition().y, 0))
		self.stateTimer = self.stateTimer - eventData:getElapsedTime()
		
		-- shoot bullets
		if (self.timeSinceLastShot >= ENEMY_2_BULLETDELAY) then
			for _, b in ipairs(self.bullets) do
				printText("b")
				if not (b.isActive) then
					b:activateBullet(self.rb:getPosition(), targetDirection, ENEMY_2_BULLETSPEED)
					break
				end
			end
			self.timeSinceLastShot = 0
		end
		
		-- enable delay between shots
		if (self.timeSinceLastShot < ENEMY_2_BULLETDELAY) then
			self.timeSinceLastShot = self.timeSinceLastShot + eventData:getElapsedTime()
		end
		return EventResult.Handled
	end
	
	-- attack condition
	self.attack_playerCondition = function(eventData)
		local distanceToPlayer = player.rb:getPosition() - self.rb:getPosition()
		if (distanceToPlayer:length() < ENEMY_2_ATTACKDISTANCE or self.hp < ENEMY_2_HP) then
			return true
		else
			return false
		end		
	end

	-- walk condition
	self.walkCondition = function(eventData)
		local distanceToPlayer = player.rb:getPosition() - self.rb:getPosition()
		if (distanceToPlayer:length() > ENEMY_2_ATTACKDISTANCE) then
			return true
		else
			return false
		end		
	end
	
	-- dead
	self.deadEnter = function(eventData)
		player.score = player.score + ENEMY_2_SCORE_VALUE
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
	self.fsm = StateMachine
	{ 
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
					enter = { self.deadEnter }
				}
			}
		},
		transitions = {
			{ from = "__enter", to = "spawning"},
			{ from = "spawning", to = "walking"},
			{ from = "walking", to = "attack_player", condition = self.attack_playerCondition},
			{ from = "attack_player", to = "walking", condition = self.walkCondition},
			{ from = "walking", to ="dead", condition = self.deadCondition},
			{ from = "attack_player", to = "dead", condition = self.deadCondition},
			{ from = "dead", to = "spawning", condition = function() return InputHandler:wasTriggered(Key.R) end}	
		}	
	}
	self.fsm:run()
end