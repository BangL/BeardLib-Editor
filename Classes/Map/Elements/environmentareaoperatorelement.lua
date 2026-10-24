EditorEnvironmentAreaOperator = EditorEnvironmentAreaOperator or class(MissionScriptEditor)
EditorEnvironmentAreaOperator.CLASS = "ElementEnvironmentAreaOperator"
function EditorEnvironmentAreaOperator:create_element()
	EditorEnvironmentAreaOperator.super.create_element(self)
	self._element.values.environment = "none"
	self._element.values.environment_area = ""
end

function EditorEnvironmentAreaOperator:_build_panel()
	self:_create_panel()
	local areas = {}
	for _, area in ipairs(managers.environment_area and managers.environment_area:areas() or {}) do
		table.insert(areas, area:name())
	end
	self:ComboCtrl("environment_area", areas, {help = "The environment area to change", free_typing = true})
	self:PathCtrl("environment", "environment", nil, nil, {help = "The environment the area is set to"})
end
