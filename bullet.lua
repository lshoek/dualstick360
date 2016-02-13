include("dualstick360/globals.lua")
include("dualstick360/utils.lua")

Bullet = {}
Bullet.__index = Bullet

--[[ Create a new Bullet object ]]
function Bullet.new()
	local self = setmetatable({}, Bullet)
	return self
end

--[[ Fires a collision event for any Bullet. Handles Bullet-Player and Bullet-Enemy collision. ]]
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
				if(ridigBody_Bullet:getUserData().isHurting == true) then
					player.hp = player.hp - 10
					if(player.hp < 0) then
						player.hp = 0
					end
					io.write("damageplayer\n")
					healthbarupdate()
					ridigBody_Bullet:getUserData().isHurting = false
					ridigBody_Bullet:getUserData().currentLifeTime = BULLET_LIFETIME

					--activate controller rumble motors
					if(RUMBLE_ON == true) then
						InputHandler:gamepad(0):rumbleLeftFor(0.8,0.00012)
						InputHandler:gamepad(0):rumbleRightFor(0.8,0.00012)
					end
				end
			end
			return EventResult.Handled
		end
		
		-- enemy gets hit
		for i = 1, ENEMY_ARRAYSIZE do
			if rigidBody_Other:equals(enemyArray[i].rb) then
				if(ridigBody_Bullet:getUserData().isHurting == true) then
					enemyArray[i].hp = enemyArray[i].hp - 1 
					ridigBody_Bullet:getUserData().isHurting = false
					ridigBody_Bullet:getUserData().currentLifeTime = BULLET_LIFETIME
					return EventResult.Handled
				end
			end		
		end
	return EventResult.Handled
end

--[[ Initialize the current Bullet object, constructs a rigid boddy for the Bullet and sets its members. ]]
function Bullet:init(guid, fromPlayer, strong)
	self.go = GameObjectManager:createGameObject("b" .. guid)
	self.currentLifeTime = 0
	self.isActive = false
	self.isConstrained = false
	self.isHurting = true
	self.fromPlayer = fromPlayer
	self.strong = strong
	self.physComp = self.go:createPhysicsComponent()
	self.physComp:getContactPointEvent():registerListener(bulletCollision)

	local cinfo = RigidBodyCInfo()
	
	if(strong == true) then
		cinfo.shape = PhysicsFactory:createSphere(BULLET_SIZE_STRONG)
	else
		cinfo.shape = PhysicsFactory:createSphere(BULLET_SIZE_WEAK)
	end
	
	if(fromPlayer == true) then
		cinfo.shape = PhysicsFactory:createSphere(PLAYER_BULLETSIZE)
	end
	
	cinfo.position = Vec3(0, 0, 0)
	cinfo.mass = 0.09
	cinfo.friction = 0
	cinfo.maxLinearVelocity = 500
	cinfo.linearDamping = 0
	cinfo.motionType = MotionType.Dynamic
	cinfo.qualityType = QualityType.Bullet
	
	if (string.find(guid, 'e')) then
		if(strong == true) then
			cinfo.collisionFilterInfo = ENEMYBULLET_INFO_STRONG
		else
			cinfo.collisionFilterInfo = ENEMYBULLET_INFO_WEAK
		end
	else
		cinfo.collisionFilterInfo = PLAYERBULLET_INFO
	end

	self.rb = self.physComp:createRigidBody(cinfo)
	self.rb:setUserData(self)
	self.go:setComponentStates(ComponentState.Inactive)
end

--[[ Activates a Bullet. This will make the Bullet available to be fired for either an Enemy or a Player object. ]]
function Bullet:activateBullet(position, direction, speed)
	self.isActive = true
	self.isHurting = true
	self.go:setComponentStates(ComponentState.Active)
	self.rb:setPosition(position)
	self.rb:applyLinearImpulse(direction:mulScalar(speed))
end

--[[ Updates the lifetime of this Bullet. When its lifetime has reached its limit, the Bullet will reset/deactivate itself. ]]
function Bullet:update(f)
	if (self.currentLifeTime >= BULLET_LIFETIME) then
		self:reset()
	end
	self.currentLifeTime = self.currentLifeTime + f
end

--[[ Deactivates a Bullet and sets its members back to its defaults. This Bullet now cannot be fired until it is activated again. ]]
function Bullet:reset(f)
	self.currentLifeTime = 0
	self.isActive = false
	self.isHurting = true
	self.rb:setPosition(Vec3(0, 0, 0))
	self.rb:setLinearVelocity(Vec3(0, 0, 0))
	self.rb:setAngularVelocity(Vec3(0, 0, 0))
	self.go:setComponentStates(ComponentState.Inactive)
end