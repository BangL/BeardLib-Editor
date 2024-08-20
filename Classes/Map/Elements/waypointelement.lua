EditorWaypoint = EditorWaypoint or class(MissionScriptEditor)
EditorWaypoint._icon_options = {
	"map_waypoint_pov_in",
	"map_waypoint_pov_out",
	"waypoint_special_camp_mission_raid",
	"waypoint_special_aim",
	"waypoint_special_air_strike",
	"waypoint_special_ammo",
	"waypoint_special_boat",
	"waypoint_special_code_book",
	"waypoint_special_code_device",
	"waypoint_special_crowbar",
	"waypoint_special_cvy_foxhole",
	"waypoint_special_cvy_landimine",
	"waypoint_special_defend",
	"waypoint_special_dog_tags",
	"waypoint_special_door",
	"waypoint_special_downed",
	"waypoint_special_dynamite_stick",
	"waypoint_special_escape",
	"waypoint_special_explosive",
	"waypoint_special_fire",
	"waypoint_special_fix",
	"waypoint_special_general_vip_sit",
	"waypoint_special_gereneral_vip_move",
	"waypoint_special_gold",
	"waypoint_special_health",
	"waypoint_special_key",
	"waypoint_special_kill",
	"waypoint_special_lockpick",
	"waypoint_special_loot",
	"waypoint_special_loot_drop",
	"waypoint_special_parachute",
	"waypoint_special_phone",
	"waypoint_special_portable_radio",
	"waypoint_special_power",
	"waypoint_special_prisoner",
	"waypoint_special_recording_device",
	"waypoint_special_refuel",
	"waypoint_special_refuel_empty",
	"waypoint_special_stash_box",
	"waypoint_special_thermite",
	"waypoint_special_tools",
	"waypoint_special_valve",
	"waypoint_special_vehicle_kugelwagen",
	"waypoint_special_vehicle_truck",
	"waypoint_special_wait",
	"waypoint_special_where",
	"raid_wp_wait",
	"raid_prisoner"
}

function EditorWaypoint:create_element()
	self.super.create_element(self)
	self._element.class = "ElementWaypoint"	
	self._element.values.icon = "pd2_goto"
	self._element.values.text_id = "debug_none"
	self._element.values.only_in_civilian = false	
end

function EditorWaypoint:_set_text()
	self._text:SetText("Text: " .. (self._hed.text_id and managers.localization:text(self._hed.text_id) or "No Text id set."))
end

function EditorWaypoint:set_element_data(params, ...)
	EditorWaypoint.super.set_element_data(self, params, ...)
	if params.name == "text_id" then
		self:_set_text()
	end
end

function EditorWaypoint:_build_panel()
	self:_create_panel()
	self:BooleanCtrl("only_in_civilian", {help = "This waypoint will only be visible for players that are in civilian mode"})
	self:BooleanCtrl("only_on_instigator", {help = "This waypoint will only be visible for the player that triggers it"})
	self:ComboCtrl("icon", self._icon_options, {help = "Select an icon", free_typing = true})
	self:StringCtrl("text_id")
	self._text = self._class_group:divider("")
	self:_set_text()
	self:Info("You can use any id from HudIconsTweakData as a waypoint icon if you type them in.")
end
