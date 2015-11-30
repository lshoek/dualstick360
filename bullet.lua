-- bullet.lua

BULLET_SIZE = 2
BULLET_SPEED = 5000

Bullet = {}
Bullet.__index = Bullet

function Bullet.new()
	local self = setmetatable({}, Bullet)
	return self
end

function Bullet:init(guid)
	self.go = GameObjectManager:createGameObject("b" .. guid)
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
	self.physComp:setState(ComponentState.Active)
	self.rb:setPosition(position)
	self.rb:applyLinearImpulse(direction:mulScalar(BULLET_SPEED))
end

function Bullet:test()
	DebugRenderer:printText(Vec2(-0.8, 0.7), 
		"bullet.position: " .. self.position.x .. " ," .. self.position.y)
end