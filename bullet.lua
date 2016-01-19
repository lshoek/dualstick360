include("dualstick360/utils.lua")

BULLET_LIFETIME = 2

Bullet = {}
Bullet.__index = Bullet

function Bullet.new()
	local self = setmetatable({}, Bullet)
	return self
end

function bulletCollision(eventData)
		
		local ridigBody_Bullet = eventData:getBody(CollisionArgsCallbackSource.A)
		local rigidBody_Other = eventData:getBody(CollisionArgsCallbackSource.B)
		
		--Player gets hit
		if rigidBody_Other:equals(player.rb) then
			--by own bullet
			if ridigBody_Bullet:getUserData().fromPlayer then
				return EventResult.Handled
			--by other bullet
			else
				player.hp = player.hp - 10
				ridigBody_Bullet:getUserData().currentLifeTime = BULLET_LIFETIME
				local hpLenght = (player.hp/PLAYER_HP)*HEALTH_BAR_LENGTH
				player.hb.rc:setScale(Vec3(5, -hpLenght, 0.1))
				
				--activate controller rumble motors
				if(RUMBLE_ON == true) then
					InputHandler:gamepad(0):rumbleLeftFor(0.8,0.00012)
					InputHandler:gamepad(0):rumbleRightFor(0.8,0.00012)
				end
			
			end
			return EventResult.Handled
		end
		
		--enemy_1 gets hit
		for i = 1, ENEMY_1_QUANTITY do
			
			if rigidBody_Other:equals(enemy_1_array[i].rb) then
			
				enemy_1_array[i].hp = enemy_1_array[i].hp - 1 
				ridigBody_Bullet:getUserData().currentLifeTime = BULLET_LIFETIME
				return EventResult.Handled
				
			end
			
		end

	return EventResult.Handled
end

function Bullet:init(guid, fromPlayer,bullet_size)
	
	self.go = GameObjectManager:createGameObject("b" .. guid)
	self.currentLifeTime = 0
	self.isActive = false
	self.isConstrained = false
	self.fromPlayer = fromPlayer
	self.physComp = self.go:createPhysicsComponent()
	self.physComp:getContactPointEvent():registerListener(bulletCollision)

	local cinfo = RigidBodyCInfo()
	cinfo.shape = PhysicsFactory:createSphere(bullet_size)
	cinfo.position = Vec3(0, 0, 0)
	cinfo.mass = 0.05
	cinfo.friction = 0
	cinfo.linearDamping = 0
	cinfo.motionType = MotionType.Dynamic
	cinfo.qualityType = QualityType.Bullet
	
	
	if (string.find(guid, 'e')) then
		cinfo.collisionFilterInfo = 0x7 -- ENEMYBULLET_INFO
	else
		cinfo.collisionFilterInfo = 0x3 -- PLAYERBULLET_INFO
	end

	self.rb = self.physComp:createRigidBody(cinfo)
	self.rb:setUserData(self)

	self.go:setComponentStates(ComponentState.Inactive)
end

function Bullet:activateBullet(position, direction, speed)
	self.isActive = true
	self.physComp:setState(ComponentState.Active)
	self.go:setComponentStates(ComponentState.Active)
	self.rb:setPosition(position)
	self.rb:applyLinearImpulse(direction:mulScalar(speed))
--[[
	if not (self.isConstrained) then
		local cinfo = {
			type = ConstraintType.PointToPlane,
			A = self.rb,
			--B = top.rb, -- Comment out this line to use the world as reference point
			constraintSpace = "world",
			pivot = Vec3(0,0,0),--bottom:getPosition(),
			up = Vec3(0, 0, 1),
			solvingMethod = "stable",
		}
		local constraint = PhysicsFactory:createConstraint(cinfo)
		world:addConstraint(constraint)
		self.isConstrained = true
	end]]--
	
end

function Bullet:update(f)
	if (self.currentLifeTime >= BULLET_LIFETIME) then -- or self.rb:getLinearVelocity():length() < 70
		self:reset()
	end
	self.currentLifeTime = self.currentLifeTime + f
	printText(self.go:getGuid() .. ": " .. self.rb:getPosition().x .. ", " .. self.rb:getPosition().y .. ", " .. self.rb:getPosition().z)
end

function Bullet:reset(f)
	self.currentLifeTime = 0
	self.isActive = false
	self.rb:setPosition(Vec3(0, 0, 0))
	self.rb:setLinearVelocity(Vec3(0, 0, 0))
	self.rb:setAngularVelocity(Vec3(0, 0, 0))
	self.go:setComponentStates(ComponentState.Inactive)
end