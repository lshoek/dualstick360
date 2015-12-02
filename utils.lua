PI = 3.14159265359
printTextCalls = 0

function printText(text)
	DebugRenderer:printText(Vec2(-0.95, 0.8-(printTextCalls*0.05)), text)
	printTextCalls = printTextCalls + 1
end