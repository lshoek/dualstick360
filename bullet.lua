include("dualstick360/utils.lua")

BULLET_LIFETIME = 2

Bullet = {}
Bullet.__index = Bullet

function Bullet.new()
	local self = setmetatable({}, Bullet)
	return self
end

function Bullet:init(guid, world, bullet_size)
	self.go = GameObjectManager:createGameObject("b" .. guid)
	self.currentLifeTime = 0
	self.isActive = false
	self.isConstrained = false
	self.physComp = self.go:createPhysicsComponent()

	local cinfo = RigidBodyCInfo()
	cinfo.shape = PhysicsFactory:createSphere(bullet_size)
	cinfo.position = Vec3(0, 0, 0)
	cinfo.mass = 0.05
	cinfo.motionType = MotionType.Dynamic
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
	end
end

function Bullet:update(f)
	if (self.currentLifeTime >= BULLET_LIFETIME) then
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