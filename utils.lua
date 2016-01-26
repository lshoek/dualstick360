-- ETC
PI = 3.14159265359
printTextCalls = 0
printGameplayTextCalls = 0

-- COLLISION FILTER INFO
PLAYER_INFO = 0x1
PLAYERBULLET_INFO = 0x3
ENEMYBULET_INFO = 0x7
ENEMY_INFO = 0xf
OBJECT_INFO = 0x1f

math.randomseed(os.time())

function printText(text)
	if printTextCalls < 31 then
		DebugRenderer:printText(Vec2(-0.95, 0.8-(printTextCalls*0.05)), text)
		printTextCalls = printTextCalls + 1
	end
end

function printGameplayText(text)
	if printGameplayTextCalls < 31 then
		DebugRenderer:printText(Vec2(0.83, 0.8-(printGameplayTextCalls*0.05)), text)
		printGameplayTextCalls = printGameplayTextCalls + 1
	end
end

function calcAngleBetween(vector1, vector2)
	local angleRad = math.atan(vector2.y, vector2.x) - math.atan(vector1.x, vector1.y)
	local angleDeg = (angleRad / math.pi) * 180
	if (angleDeg > 180) then
		angleDeg = angleDeg - 360
	end
	if (angleDeg < -180) then
		angleDeg = angleDeg + 360
	end
	return angleDeg
end

function rotateVector(vector, axis, angle)
	local rotQuat = Quaternion(axis, angle)
	local rotMat = rotQuat:toMat3()
	local rotVector = rotMat:mulVec3(vector)
	return rotVector
end

function calcSteering(self, targetDir)
	local rightVec = self.go:getRightDirection()
	local steer = rightVec:dot(targetDir)
	local crossRightMove = rightVec:cross(targetDir)
	if (crossRightMove.z < 0) then
		if (steer < 0) then
			steer = -1
		else
			steer = 1
		end
	end
	return steer
end	