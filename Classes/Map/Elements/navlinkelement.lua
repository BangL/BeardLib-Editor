EditorNavLink = EditorNavLink or class(MissionScriptEditor)
-- might finish this later if im bothered unless somebody else wants to
--[[
EditorNavLinkUnit.INSTANCE_VAR_NAMES = {
	{
		value = "so_action",
		type = "special_objective_action"
	}
}
EditorNavLinkUnit._AI_SO_types = {
	"AI_defend",
	"AI_security",
	"AI_hunt",
	"AI_search",
	"AI_idle",
	"AI_escort",
	"AI_sniper"
}
EditorNavLinkUnit.PRESETS = {
	civilians = {
		"civ_male",
		"civ_female"
	},
	team_ai = {
		"teamAI1",
		"teamAI2",
		"teamAI3",
		"teamAI4"
	},
	security = {
		"security",
		"security_patrol"
	},
	acrobats = {
		"cop",
		"fbi",
		"swat",
		"sniper",
		"gangster",
		"murky",
		"teamAI1",
		"teamAI2",
		"teamAI3",
		"teamAI4"
	},
	heavies = {
		"shield",
		"tank"
	}
}
]]--
function EditorNavLink:create_element()
    EditorNavLink.super.create_element(self)
    self._element.class = "ElementNavLinkUnit"
--    self._element.values.obstacle_list = {}
--    self._element.values.operation = "add"
--    self._guis = {}
--    self._obstacle_units = {}
--    self._all_object_names = {}
    self._nav_link_filter = {}
    self._nav_link_filter_check_boxes = {}
    self._element.values.ai_group = "none"
    self._element.values.align_rotation = true
    self._element.values.align_position = true
    self._element.values.needs_pos_rsrv = true
    self._element.values.is_navigation_link = true
    self._element.values.so_action = "none"
    self._element.values.search_position = self._unit:position()
    self._element.values.interval = ElementNavLink._DEFAULT_VALUES.interval
    self._element.values.attitude = "none"
    self._element.values.SO_access = "0"
    self._element.values.test_unit = "default"
    self._element.values._patrol_group = false
end

function EditorNavLink:_build_panel()
	self:_create_panel()
	self:Text("Havent finished remaking this to work in raid BLE")
end