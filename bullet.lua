-- bullet.lua

BULLET_SIZE = 2
BULLET_SPEED = 100

Bullet = {}
Bullet.__index = Bullet

function Bullet.new(obj)
	local self = setmetatable({}, Bullet)
	self.value = obj
	return self
end

function Bullet:init(guid)
	self.go = GameObjectManager:createGameObject("b" .. guid)
	self.active = false
	self.position = Vec3(0, 0, 0)
	self.angle = 0
	self.physComp = self.go:createPhysicsComponent()

	local cinfo = RigidBodyCInfo()
	cinfo.shape = PhysicsFactory:createSphere(BULLET_SIZE)
	cinfo.position = Vec3(0, 0, 0)
	cinfo.motionType = MotionType.Keyframed

	self.rb = self.physComp:createRigidBody(cinfo)
	self.rb:setUserData(self)
end

function Bullet:update(f)
	self.position.x = self.position.x + (math.sin(self.angle*PI)/180)*BULLET_SPEED*f
	self.position.y = self.position.y + (math.cos(self.angle*PI)/180)*BULLET_SPEED*f

	self.rb:setPosition(self.position)
end

function Bullet:setActive(bool)
	self.active = bool
end