include("dualstick360/enemy.lua")

levelobj = GameObjectManager:createGameObject("level_parent")

wall_counter = 0
box_counter = 0
rot_box_counter = 0

function createGrid()
   for j = -300, 1700, 50 do
       DebugRenderer:drawLine3D(Vec3(j, 300, 10), Vec3(j, -2500, 10), Color(0, 0, 70/255, 1))
   end
   for i = -2500, 300, 50 do
       DebugRenderer:drawLine3D(Vec3(-300, i, 10), Vec3(1700,  i, 10), Color(0, 0, 70/255, 1))
   end
end

function createWall(parent, dimension, position)
    wall_counter = wall_counter + 1
    
    local box = GameObjectManager:createGameObject("wall" .. wall_counter)
    box.pc = box:createPhysicsComponent()
    
    local cinfo = RigidBodyCInfo()
    cinfo.motionType = MotionType.Fixed
    cinfo.shape = PhysicsFactory:createBox(dimension)
	cinfo.restitution = 1.0
    cinfo.collisionFilterInfo = OBJECT_INFO
    
    local rb = box.pc:createRigidBody(cinfo)
    
    box:setParent(parent)
    box:setPosition(position)
end

function createBox(parent, dimension, position)
    box_counter = box_counter + 1
    
    local box = GameObjectManager:createGameObject("obstacle" .. box_counter)
    box.pc = box:createPhysicsComponent()
    
    local cinfo = RigidBodyCInfo()
    cinfo.motionType = MotionType.Fixed
    cinfo.shape = PhysicsFactory:createBox(dimension)
	cinfo.restitution = 1.0
    cinfo.collisionFilterInfo = OBJECT_INFO
    
    local rb = box.pc:createRigidBody(cinfo)
    
    box:setParent(parent)
    box:setPosition(position)
end

function createRotatedBox(parent, dimension, position,rotation)
    rot_box_counter = rot_box_counter + 1
    
    local box = GameObjectManager:createGameObject("box" .. rot_box_counter)
    box.pc = box:createPhysicsComponent()
    
    local cinfo = RigidBodyCInfo()
    cinfo.motionType = MotionType.Fixed
    cinfo.shape = PhysicsFactory:createBox(dimension)
	cinfo.restitution = 1.0
    cinfo.collisionFilterInfo = OBJECT_INFO
    
    local rb = box.pc:createRigidBody(cinfo)
    
    box:setParent(parent)
    box:setPosition(position)
    box:setRotation(rotation)
end

function build_level_1()
    createWall(levelobj, Vec3(345, 5, 15), Vec3(225, 60, 0))
    createWall(levelobj, Vec3(5, 225, 15), Vec3(-125, -160, 0))
    createWall(levelobj, Vec3(75, 5, 15), Vec3(-45, -380, 0))
    createWall(levelobj, Vec3(5, 112.5, 15), Vec3(35, -272.5, 0))
    createWall(levelobj, Vec3(37.5, 5, 15), Vec3(76.5, -165, 0))
    createWall(levelobj, Vec3(5, 300, 15), Vec3(119, -460, 0))
    createWall(levelobj, Vec3(150, 5, 15), Vec3(274, -755, 0))
    createWall(levelobj, Vec3(5, 150, 15), Vec3(429, -900, 0))
    createWall(levelobj, Vec3(37.5, 5, 15), Vec3(396.5, -1055, 0))
    createWall(levelobj, Vec3(5, 112.5, 15), Vec3(354, -947, 0))
    createWall(levelobj, Vec3(150, 5, 15), Vec3(209.5, -829.5, 0))
    createWall(levelobj, Vec3(5, 150, 15), Vec3(65, -675, 0))
    createWall(levelobj, Vec3(150, 5, 15), Vec3(-90, -530, 0))
    createWall(levelobj, Vec3(5, 525, 15), Vec3(-245, -1050, 0))
    createWall(levelobj, Vec3(262.5, 5, 15), Vec3(22, -1570, 0))
    createWall(levelobj, Vec3(5, 112.5, 15), Vec3(289.5, -1462.5, 0))
    createWall(levelobj, Vec3(150, 5, 15), Vec3(444.5, -1355, 0))
    createWall(levelobj, Vec3(5, 300, 15), Vec3(599.5, -1060, 0))
    createWall(levelobj, Vec3(150, 5, 15), Vec3(744.5, -755, 0))
    createWall(levelobj, Vec3(5, 525, 15), Vec3(899.5, -1275, 0))
    createWall(levelobj, Vec3(112.5, 5, 15), Vec3(792.5, -1805, 0))
    createWall(levelobj, Vec3(5, 225, 15), Vec3(685, -2035, 0))
    createWall(levelobj, Vec3(412.5, 5, 15), Vec3(1102.5, -2255, 0))
    createWall(levelobj, Vec3(5, 225, 15), Vec3(1520, -2035, 0))
    createWall(levelobj, Vec3(112.5, 5, 15), Vec3(1413.5, -1805, 0))
    createWall(levelobj, Vec3(5, 187.5, 15), Vec3(1306, -1612.5, 0))
    createWall(levelobj, Vec3(112.5, 5, 15), Vec3(1423.5, -1430, 0))
    createWall(levelobj, Vec3(5, 112.5, 15), Vec3(1540.5, -1323, 0))
    createWall(levelobj, Vec3(112.5, 5, 15), Vec3(1422.5, -1215.5, 0))
    createWall(levelobj, Vec3(5, 112.5, 15), Vec3(1315, -1098, 0))
    createWall(levelobj, Vec3(112.5, 5, 15), Vec3(1432.5, -990.5, 0))
    createWall(levelobj, Vec3(5, 300, 15), Vec3(1550, -695.5, 0))
    createWall(levelobj, Vec3(487.5, 5, 15), Vec3(1057.5, -400.5, 0))
    createWall(levelobj, Vec3(5, 230, 15), Vec3(565, -175.5, 0))
    
    createBox(levelobj, Vec3(90, 37.5, 15), Vec3(214, -675, 0))
    createBox(levelobj, Vec3(75, 75, 15), Vec3(390, -1200, 0))
    createBox(levelobj, Vec3(37.5, 37.5, 15), Vec3(680, -490, 0))
    createBox(levelobj, Vec3(75, 75, 15), Vec3(975, -580, 0))
    createBox(levelobj, Vec3(37.5, 150, 15), Vec3(1347.5, -835.5, 0))
    createBox(levelobj, Vec3(37.5, 37.5, 15), Vec3(1380, -1300.5, 0))
    createBox(levelobj, Vec3(100, 37.5, 15), Vec3(1075, -1710.5, 0))
    createBox(levelobj, Vec3(100, 80, 15), Vec3(320, -370, 0))
    createBox(levelobj, Vec3(37.5, 190, 15), Vec3(50, -1300, 0))
    createBox(levelobj, Vec3(20, 20, 15), Vec3(-165, -1400, 0))
    
    createRotatedBox(levelobj, Vec3(80, 37.5, 15), Vec3(1070, -960, 0),Quaternion(Vec3(0,0,1),45))
    createRotatedBox(levelobj, Vec3(80, 37.5, 15), Vec3(400, -50, 0),Quaternion(Vec3(0,0,1),70))
    createRotatedBox(levelobj, Vec3(20, 150, 15), Vec3(190, -950, 0),Quaternion(Vec3(0,0,1),120))
    createRotatedBox(levelobj, Vec3(35, 35, 15), Vec3(-90, -690, 0),Quaternion(Vec3(0,0,1),40))

    
	--createHealthpack(position, hpPlus)
	
	createHealthpack(Vec3(1480,-1380,0), 50)
	createHealthpack(Vec3(1460,-930,0), 50)
	createHealthpack(Vec3(150,-730,0), 50)
        
    --createEnemy(position, behaviourType, size, distance, clockwise, shootingDir, strongBullets)
		createEnemy(Vec3(-80, -330, 0),    ENEMY_BEHAVIOURTYPE_MOVE,    ENEMY_SIZE,  30,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
	
    createEnemy(Vec3(-80, -330, 0),    ENEMY_BEHAVIOURTYPE_STALKER,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(-10, -330, 0),    ENEMY_BEHAVIOURTYPE_STALKER,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(-50, -290, 0),    ENEMY_BEHAVIOURTYPE_STALKER,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(100, -150, 0),    ENEMY_BEHAVIOURTYPE_TOWER,      ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_DOWN, false)
    createEnemy(Vec3(50, -150, 0),    ENEMY_BEHAVIOURTYPE_TOWER,      ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_DOWN, false)
    createEnemy(Vec3(200, -80, 0),    ENEMY_BEHAVIOURTYPE_STALKER,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(200, -20, 0),    ENEMY_BEHAVIOURTYPE_STALKER,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
        
    createEnemy(Vec3(170, -550, 0),    ENEMY_BEHAVIOURTYPE_BOUNCE,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(380, -550, 0),    ENEMY_BEHAVIOURTYPE_BOUNCE,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(890, -700, 0),    ENEMY_BEHAVIOURTYPE_BOUNCE,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(990, -800, 0),    ENEMY_BEHAVIOURTYPE_BOUNCE,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(990, -900, 0),    ENEMY_BEHAVIOURTYPE_BOUNCE,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(1100, -800, 0),    ENEMY_BEHAVIOURTYPE_BOUNCE,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(180, -1400, 0),    ENEMY_BEHAVIOURTYPE_BOUNCE,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(-50, -1150, 0),    ENEMY_BEHAVIOURTYPE_BOUNCE,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(-110, -1200, 0),    ENEMY_BEHAVIOURTYPE_BOUNCE,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(-200, -1330, 0),    ENEMY_BEHAVIOURTYPE_BOUNCE,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(-10, -550, 0),    ENEMY_BEHAVIOURTYPE_BOUNCE,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(-60, -550, 0),    ENEMY_BEHAVIOURTYPE_BOUNCE,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(-110, -550, 0),    ENEMY_BEHAVIOURTYPE_BOUNCE,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(-160, -550, 0),    ENEMY_BEHAVIOURTYPE_BOUNCE,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(1430, -1380, 0),    ENEMY_BEHAVIOURTYPE_BOUNCE,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(1430, -1280, 0),    ENEMY_BEHAVIOURTYPE_BOUNCE,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(1230, -1100, 0),    ENEMY_BEHAVIOURTYPE_BOUNCE,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(1180, -1100, 0),    ENEMY_BEHAVIOURTYPE_BOUNCE,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(1130, -1100, 0),    ENEMY_BEHAVIOURTYPE_BOUNCE,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
        
    createEnemy(Vec3(950, -1500, 0),    ENEMY_BEHAVIOURTYPE_STALKER,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(1000, -1500, 0),    ENEMY_BEHAVIOURTYPE_STALKER,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(1050, -1500, 0),    ENEMY_BEHAVIOURTYPE_STALKER,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(1100, -1500, 0),    ENEMY_BEHAVIOURTYPE_STALKER,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(1020, -1600, 0),    ENEMY_BEHAVIOURTYPE_STALKER,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(1200, -1650, 0),    ENEMY_BEHAVIOURTYPE_STALKER,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(530, -1200, 0),    ENEMY_BEHAVIOURTYPE_STALKER,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(235, -1320, 0),    ENEMY_BEHAVIOURTYPE_STALKER,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(150, -1320, 0),    ENEMY_BEHAVIOURTYPE_STALKER,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(130, -890, 0),    ENEMY_BEHAVIOURTYPE_STALKER,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(-10, -740, 0),    ENEMY_BEHAVIOURTYPE_STALKER,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(-190, -740, 0),    ENEMY_BEHAVIOURTYPE_STALKER,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(-190, -630, 0),    ENEMY_BEHAVIOURTYPE_STALKER,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(-10, -630, 0),    ENEMY_BEHAVIOURTYPE_STALKER,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, false)
    createEnemy(Vec3(1380, -1240, 0),    ENEMY_BEHAVIOURTYPE_STALKER,    ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_PLAYER, true)
    
    createEnemy(Vec3(1460, -980, 0),    ENEMY_BEHAVIOURTYPE_TOWER,      ENEMY_SIZE,  0,     true, ENEMY_SHOOTINGDIR_DOWN, true)

    local pos_y = -1030
    for i = 1, 5 do
        createEnemy(Vec3(442, pos_y, 0), ENEMY_BEHAVIOURTYPE_TOWER, ENEMY_SIZE, 100, true, ENEMY_SHOOTINGDIR_RIGHT, true)
        pos_y = pos_y + 60
    end
    pos_y = -1450
    for i = 1, 6 do
        createEnemy(Vec3(45, pos_y, 0), ENEMY_BEHAVIOURTYPE_TOWER, ENEMY_SIZE, 100, true, ENEMY_SHOOTINGDIR_LEFT, true)
        pos_y = pos_y + 60
    end
    pos_y = -930
    for i = 1, 5 do
        createEnemy(Vec3(1370, pos_y, 0), ENEMY_BEHAVIOURTYPE_TOWER, ENEMY_SIZE, 100, true, ENEMY_SHOOTINGDIR_RIGHT, true)
        pos_y = pos_y + 50
    end
    pos_y = -905
    for i = 1, 6 do
        createEnemy(Vec3(1555, pos_y, 0), ENEMY_BEHAVIOURTYPE_TOWER, ENEMY_SIZE, 100, true, ENEMY_SHOOTINGDIR_LEFT, true)
        pos_y = pos_y + 50
    end

    createEnemy(Vec3(1110, -2050, 0), ENEMY_BEHAVIOURTYPE_BOSS, ENEMY_SIZE*6, 0, true, ENEMY_SHOOTINGDIR_PLAYER)
end