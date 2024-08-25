EditorWorldOutputEvent = EditorWorldOutputEvent or class(MissionScriptEditor)
-- i got lazy for this aswell
function EditorWorldOutputEvent:create_element()
	EditorWorldOutputEvent.super.create_element(self)
	self._element.class = "ElementWorldOutputEvent"
	self._element.module = "CoreElementWorld"
end

function EditorWorldOutputEvent:_build_panel()
	self:_create_panel()
	self:Text("Havent finished remaking this to work in raid BLE")
end

EditorWorldOutput = EditorWorldOutput or class(MissionScriptEditor)
function EditorWorldOutput:create_element()
	EditorWorldOutput.super.create_element(self)
	self._element.class = "ElementWorldOutput"
	self._element.module = "CoreElementWorld"
end

function EditorWorldOutput:_build_panel()
	self:_create_panel()
	self:Text("Havent finished remaking this to work in raid BLE")
end

EditorWorldInputEvent = EditorWorldInputEvent or class(MissionScriptEditor)
function EditorWorldInputEvent:create_element()
	EditorWorldInputEvent.super.create_element(self)
	self._element.class = "ElementWorldInputEvent"
	self._element.module = "CoreElementWorld"
end

function EditorWorldInputEvent:_build_panel()
	self:_create_panel()
	self:Text("Havent finished remaking this to work in raid BLE")
end

EditorWorldPoint = EditorWorldPoint or class(MissionScriptEditor)
function EditorWorldPoint:create_element()
	EditorWorldPoint.super.create_element(self)
	self._element.class = "ElementWorldPoint"
	self._element.module = "CoreElementWorld"
    self._spawn_counter = 0
end

function EditorWorldPoint:_build_panel()
	self:_create_panel()
	self:Text("Havent finished remaking this to work in raid BLE")
end