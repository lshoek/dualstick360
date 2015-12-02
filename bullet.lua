include("dualstick360/utils.lua")

BULLET_SIZE = 2
BULLET_SPEED = 5000
BULLET_LIFETIME = 2

Bullet = {}
Bullet.__index = Bullet

function Bullet.new()
	local self = setmetatable({}, Bullet)
	return self
end

function Bullet:init(guid)
	self.go = GameObjectManager:createGameObject("b" .. guid)
	self.currentLifeTime = 0
	self.isActive = false
	self.physComp = self.go:createPhysicsComponent()

	local cinfo = RigidBodyCInfo()
	cinfo.shape = PhysicsFactory:createSphere(BULLET_SIZE)
	cinfo.position = Vec3(0, 0, 0)
	cinfo.mass = 0.1
	cinfo.friction = 100
	cinfo.motionType = MotionType.Dynamic

	self.rb = self.physComp:createRigidBody(cinfo)
	self.rb:setUserData(self)

	self.go:setComponentStates(ComponentState.Inactive)
end

function Bullet:activateBullet(position, direction)
	self.isActive = true
	self.physComp:setState(ComponentState.Active)
	self.rb:setPosition(position)
	self.rb:applyLinearImpulse(direction:mulScalar(BULLET_SPEED))
end

function Bullet:update(f)
	if (self.currentLifeTime > BULLET_LIFETIME) then
		self:reset()
	end
	self.currentLifeTime = self.currentLifeTime + f
end

function Bullet:reset(f)
	self.currentLifeTime = 0
	self.isActive = false
	self.rb:setPosition(Vec3(0, 0, 0))
	self.rb:setLinearVelocity(Vec3(0, 0, 0))
	self.rb:setAngularVelocity(Vec3(0, 0, 0))
	self.go:setComponentStates(ComponentState.Inactive)
end