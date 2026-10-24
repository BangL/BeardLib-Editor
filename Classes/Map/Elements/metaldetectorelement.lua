EditorMetalDetector = EditorMetalDetector or class(MissionScriptEditor)
EditorMetalDetector.CLASS = "ElementMetalDetector"
function EditorMetalDetector:_build_panel()
	self:_create_panel()
	self:Text("Executes the elements it links to. Used by the metal detector unit.")
end
