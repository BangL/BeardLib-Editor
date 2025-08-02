if not Global.editor_mode then
	return
end

local Instance = CoreWorldInstanceManager
function Instance:prepare_unit_data(instance, continent_data, worlddefinition)
	local start_index = instance.start_index
	local folder = instance.folder
	local path = folder .. "/" .. CoreWorldInstanceManager.DEFAULT_CONTINENT_NAME
	local instance_data = self:_get_instance_continent_data(path)
	local function _prepare_entries(entries)
		if not entries then
			return
		end
		for _, entry in ipairs(entries) do
			entry.unit_data.local_rot = mrotation.copy(entry.unit_data.rotation)
			entry.unit_data.local_pos = mvector3.copy(entry.unit_data.position)
			entry.unit_data.rotation = instance.rotation * entry.unit_data.rotation
			entry.unit_data.position = instance.position + entry.unit_data.position:rotate_with(instance.rotation)
			if worlddefinition and worlddefinition:world_id() ~= 0 then
				local old_id = entry.unit_data.unit_id
				local offset = self:_get_mod_id(entry.unit_data.unit_id) + self._start_offset_index + start_index
				local temp_id = continent_data.base_id + offset

				entry.unit_data.unit_id = worlddefinition:_get_new_instance_id(temp_id, offset)
			else
				entry.unit_data.unit_id = continent_data.base_id + self:_get_mod_id(entry.unit_data.unit_id) + self._start_offset_index + start_index
			end
			entry.unit_data.instance = instance.name
			entry.unit_data.continent = instance.continent
			if entry.unit_data.zipline then
				entry.unit_data.zipline.end_pos = instance.position + entry.unit_data.zipline.end_pos:rotate_with(instance.rotation)
			end
		end
	end
	_prepare_entries(instance_data.statics)
	_prepare_entries(instance_data.dynamics)
	return instance_data
end

function Instance:get_mission_outputs(instance)
	local start_index = instance.start_index
	local folder = instance.folder
	local path = folder .. "/" .. CoreWorldInstanceManager.DEFAULT_CONTINENT_NAME
	local instance_data = self:_serialize_to_script("mission", path)
	local mission_inputs = {}
	for script, script_data in pairs(instance_data) do
		for _, element in ipairs(script_data.elements) do
			if element.class == "ElementInstanceOutput" then
				local id = element.id + self._start_offset_index + start_index
				table.insert(mission_inputs, tostring(element.values.event))
			end
		end
	end
	table.sort(mission_inputs)
	return mission_inputs
end

function Instance:custom_create_instance(instance_name, worlddefinition_id, custom_data)
	local worlddefinition = worlddefinition_id ~= 0 and managers.worldcollection:worlddefinition_by_id(worlddefinition_id)
	worlddefinition = worlddefinition or managers.worlddefinition
	local instance = self:get_instance_data_by_name(instance_name, worlddefinition_id)
	local continent_data = worlddefinition._continents[instance.continent]
	local orig_pos = instance.position
	local orig_rot = instance.rotation
	instance.position = custom_data.position or Vector3()
	instance.rotation = custom_data.rotation or Rotation()
	local prepared_unit_data = managers.world_instance:prepare_unit_data(instance, continent_data, worlddefinition)
	if prepared_unit_data.statics then
		for _, static in ipairs(prepared_unit_data.statics) do
			local unit = worlddefinition:_create_statics_unit(static, Vector3())
			if Application:editor() then
				managers.editor:layer("Statics"):add_unit_to_created_units(unit)
			end
		end
	end
	if prepared_unit_data.dynamics then
		for _, entry in ipairs(prepared_unit_data.dynamics) do
			local unit = worlddefinition:_create_dynamics_unit(entry, Vector3())
			if Application:editor() then
				managers.editor:layer("Dynamics"):add_unit_to_created_units(unit)
			end
		end
	end
	local prepare_mission_data = self:prepare_mission_data_by_name(instance_name, worlddefinition_id)
	local mission = worlddefinition_id ~= 0 and managers.worldcollection:mission_by_id(worlddefinition_id) or managers.mission
	mission:script(instance.script):external_create_instance_elements(prepare_mission_data, instance_name)

	instance.position = orig_pos
	instance.rotation = orig_rot
end

function Instance:prepare_mission_data_by_name(name, worlddefinition_id)
	local instance_data = self:get_instance_data_by_name(name, worlddefinition_id)
	local mdata = self:prepare_mission_data(instance_data)
	mdata.instance_name = name
	return mdata
end