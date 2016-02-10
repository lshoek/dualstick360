--healthpack.lue
include("dualstick360/globals.lua")
include("dualstick360/player.lua")
include("dualstick360/utils.lua")

HEALTHPACK = {}
HEALTHPACK.__index = HEALTHPACK

function HEALTHPACK.new()
	local self = setmetatable({}, HEALTHPACK)
	return self
end

function healthPackCollision(eventData)

	local ridigBody_Healthpack = eventData:getBody(CollisionArgsCallbackSource.B)
	local rigidBody_Other = eventData:getBody(CollisionArgsCallbackSource.A)
	
	if rigidBody_Other:equals(player.rb) then

		if(player.hp + HEALTHPACK_HPPLUS > PLAYER_HP) then
			player.hp = PLAYER_HP
		else
			player.hp = player.hp + HEALTHPACK_HPPLUS
		end
		healthbarupdate()
		
		ridigBody_Healthpack:getUserData().go:setComponentStates(ComponentState.Inactive)
	end
	
	return EventResult.Handled

end

function HEALTHPACK:init(guid, position)
	
	self.go = GameObjectManager:createGameObject(guid)
	self.currentLifeTime = 0
	self.isActive = false
	self.isConstrained = false
	self.fromPlayer = fromPlayer
	self.physComp = self.go:createPhysicsComponent()
	self.physComp:getContactPointEvent():registerListener(healthPackCollision)

	local cinfo = RigidBodyCInfo()
	cinfo.shape = PhysicsFactory:createCapsule(Vec3(0.0, 0.0, 0.0), Vec3(4.0, 0.0, 0.0), 2.0)
	cinfo.position = position
	cinfo.mass = 0.05
	cinfo.friction = 0
	cinfo.linearDamping = 0
	cinfo.motionType = MotionType.Fixed	
	cinfo.collisionFilterInfo = OBJECT_INFO


	self.rb = self.physComp:createRigidBody(cinfo)
	self.rb:setUserData(self)

end