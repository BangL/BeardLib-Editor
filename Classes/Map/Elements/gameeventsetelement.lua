EditorGameEventSet = EditorGameEventSet or class(MissionScriptEditor)
EditorGameEventSet.CLASS = "ElementGameEventSet"
function EditorGameEventSet:_build_panel()
	self:_create_panel()
	self:Text("Executes the elements it links to.")
end
