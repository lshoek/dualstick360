--healthpack.lue
include("dualstick360/globals.lua")
include("dualstick360/player.lua")
include("dualstick360/utils.lua")

Healthpack = {}
Healthpack.__index = Healthpack

--[[creating new healthpack object]]--
function Healthpack.new()
	local self = setmetatable({}, Healthpack)
	return self
end

--[[checks for player collision and adds healthpoints]]--
function healthPackCollision(eventData)

	local ridigBody_Healthpack = eventData:getBody(CollisionArgsCallbackSource.B)
	local rigidBody_Other = eventData:getBody(CollisionArgsCallbackSource.A)
	
	if rigidBody_Other:equals(player.rb) then

		if(player.hp + ridigBody_Healthpack:getUserData().hpPlus > PLAYER_HP) then
			player.hp = PLAYER_HP
		else
			player.hp = player.hp + ridigBody_Healthpack:getUserData().hpPlus
		end
		player:healthbarupdate()
		
		ridigBody_Healthpack:getUserData().go:setComponentStates(ComponentState.Inactive)
	end
	
	return EventResult.Handled

end

--[[ Create Function with parameters position and hpPlus]]
function createHealthpack(position, hpPlus)
	local h = Healthpack.new()
	HEALTHPACK_ARRAYSIZE = HEALTHPACK_ARRAYSIZE + 1
	h:init("healthpack" .. HEALTHPACK_ARRAYSIZE, position, hpPlus)
	healthpackArray[HEALTHPACK_ARRAYSIZE] = h
end

--[[ Initialize the current healthpack object, constructs a rigid body and all objects that are part of the healthpack and sets its members. ]]
function Healthpack:init(guid, position, hpPlus)
	
	self.go = GameObjectManager:createGameObject(guid)
	self.currentLifeTime = 0
	self.physComp = self.go:createPhysicsComponent()
	self.physComp:getContactPointEvent():registerListener(healthPackCollision)

	local cinfo = RigidBodyCInfo()
	
	if(hpPlus < 26) then
		cinfo.shape = PhysicsFactory:createCapsule(Vec3(0.0, 0.0, 0.0), Vec3(4.0, 0.0, 0.0), 2.0)
	elseif(hpPlus < 51) then
		cinfo.shape = PhysicsFactory:createCapsule(Vec3(0.0, 0.0, 0.0), Vec3(5.0, 0.0, 0.0), 2.5)
	elseif(hpPlus < 76) then
		cinfo.shape = PhysicsFactory:createCapsule(Vec3(0.0, 0.0, 0.0), Vec3(6.0, 0.0, 0.0), 3.0)
	end
	
	cinfo.position = position
	cinfo.mass = 0.05
	cinfo.friction = 0
	cinfo.linearDamping = 0
	cinfo.motionType = MotionType.Fixed	
	cinfo.collisionFilterInfo = OBJECT_INFO
	
	self.hpPlus = hpPlus


	self.rb = self.physComp:createRigidBody(cinfo)
	self.rb:setUserData(self)

end