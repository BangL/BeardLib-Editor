EditorNavigationStitcher = EditorNavigationStitcher or class(MissionScriptEditor)
EditorNavigationStitcher.ACTIONS = {
	"stitch",
	"tear"
}

function EditorNavigationStitcher:create_element()
	EditorNavigationStitcher.super.create_element(self)
	self._element.class = "ElementavigationStitcher"
    self._element.values.operation = "spawn"
	self._element.values.world = ""
	self._element.values.elements = {}

end

function EditorNavigationStitcher:_build_panel()
	self:_create_panel()
  --  self:ComboCtrl("operation", EditorNavigationStitcher.ACTIONS, {help = "Select an operation for the selected elements"})
    self:Text("Not finished recreating to work in raid BLE")
--	self:Text("Choose an operation to perform on the selected elements. An element might not have the selected operation implemented and will then generate error when executed.")
end

-- i am once again stupid