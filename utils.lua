PI = 3.14159265359
printTextCalls = 0
printGameplayTextCalls = 0

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