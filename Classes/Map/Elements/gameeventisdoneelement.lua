EditorGameEventIsDone = EditorGameEventIsDone or class(MissionScriptEditor)
EditorGameEventIsDone.CLASS = "ElementGameEventIsDone"
function EditorGameEventIsDone:_build_panel()
	self:_create_panel()
	self:Text("Unused by the game, it never executes anything.")
end
