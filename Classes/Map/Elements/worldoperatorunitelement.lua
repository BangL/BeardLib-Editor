EditorWorldOperator = EditorWorldOperator or class(MissionScriptEditor)
EditorWorldOperator.ACTIONS = {
	"spawn",
	"spawn_alarmed",
	"despawn",
	"enable_plant_loot",
	"enable_alarm_state",
	"disable_alarm_state"
}

function EditorWorldOperator:create_element()
	EditorWorldOperator.super.create_element(self)
	self._element.class = "ElementWorldOperator"
	self._element.values.operation = "spawn"
	self._element.values.world = ""
	self._element.values.elements = {}
end

function EditorWorldOperator:_build_panel()
	self:_create_panel()
	self:ComboCtrl("operation", EditorWorldOperator.ACTIONS, {help = "Select an operation for the selected elements"})
	self:BuildElementsManage("elements")
	self:Text("Dont attempt to use as the elements it wants arent functional yet")
	self:Text("Choose an operation to perform on the selected elements. An element might not have the selected operation implemented and will then generate error when executed.")
end