include("dualstick360/globals.lua")

math.randomseed(os.time())
--[[ Fancy print function that automatically draws the text on a convenient position on the screen. ]]

function printText(text)
	if printTextCalls < 31 then
		DebugRenderer:printText(Vec2(-0.95, 0.8-(printTextCalls*0.05)), text)
		printTextCalls = printTextCalls + 1
	end
end

--[[ Another fancy print function for gameplay text that automatically draws the text on a convenient position on the screen. ]]
function printGameplayText(text)
	if printGameplayTextCalls < 31 then
		DebugRenderer:printText(Vec2(0.83, 0.8-(printGameplayTextCalls*0.05)), text)
		printGameplayTextCalls = printGameplayTextCalls + 1
	end
end

--[[ Calculates the angle in dregrees between two given vectors in 2 dimensions (x/y) ]]
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

--[[ Rotates any vector a given number of degrees around a given axis ]]
function rotateVector(vector, axis, angle)
	local rotQuat = Quaternion(axis, angle)
	local rotMat = rotQuat:toMat3()
	local rotVector = rotMat:mulVec3(vector)
	return rotVector
end

--[[ 	Calculates what direction (positive/negative) the vector self should steer to,
		in order to point to the same direction as the targetDir vector. 
	]]
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