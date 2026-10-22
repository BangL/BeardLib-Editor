BrushLayerEditor = BrushLayerEditor or class(LayerEditor)

function BrushLayerEditor:init(parent)
    BrushLayerEditor.super.init(self, parent, "BrushLayerEditorEditor", {private = {h = parent._holder:ItemsHeight(1, 6)}})

	self._brush_names = {}
	self._brush_types = {}
	self._brush_size = 15
	self._brush_density = 3
	self._brush_pressure = 1
	self._random_roll = 0
	self._spraying = false
	self._erasing = false
	self._brush_height = 40
	self._angle_override = 0
	self._offset = 0
	self._visible = true
	self._erase_with_pressure = false
	self._erase_with_units = false
	self._overide_surface_normal = false
	self._brush_on_editor_bodies = false
	self._amount_dirty = true
	self._short_names = true

	-- self:load_unit_map_from_vector(CoreEditorUtils.layer_type("brush"))

	self._place_slot_mask = managers.slot:get_mask("brush_placeable")
	self._brush_slot_mask = managers.slot:get_mask("brushes")
	self._unit_brushes = {}
	self._brush_units = clone(BLE.Brushes)

	if self._brush_units and #self._brush_units > 0 then
		table.sort(self._brush_units)
	end

	self._selected_unit_names = {}
	self._brushed_path = "core/temp/editor_temp/brushes"

	self:load_brushes()
end

---Brushes are data of this layer: the engine only shows the massunit that is loaded (see BrushLayerEditor:update_massunit),
---and the file is written by the editor itself (MassunitWriter). A brush has to come from a package the level loads.
function BrushLayerEditor:save()
	if not self._needs_saving then
		return
	else
		self._needs_saving = false
	end

	local data = self:brush_data()
	data.preload_units = {}
	local added = {}
	for _, entry in pairs(self:instances()) do
		if #entry.positions > 0 then
			local name = type(entry.name) == "string" and entry.name or entry.name:key()
			if not added[name] then
				added[name] = true
				table.insert(data.preload_units, entry.name)
			end
		end
	end

	self:write_massunit_file()
end

---The brush entry of the world data (a world without brushes has it without a file).
function BrushLayerEditor:brush_data()
	local data = self._parent:data()
	data.brush = data.brush or {}
	data.brush.file = data.brush.file or "massunit"
	return data.brush
end

function BrushLayerEditor:massunit_file_path()
	return Path:Combine(BLE.MapProject:current_level_path(), self:brush_data().file .. ".massunit")
end

---Loads the instances the engine has (massunit of the level) as data of the layer.
function BrushLayerEditor:init_instances()
	self._instances = {}
	for _, unit_name in ipairs(MassUnitManager:list()) do
		local entry = self:instance_entry(unit_name)
		for _, pos in ipairs(MassUnitManager:unit_positions(unit_name)) do
			table.insert(entry.positions, pos)
		end
		for _, rot in ipairs(MassUnitManager:unit_rotations(unit_name)) do
			table.insert(entry.rotations, rot)
		end
	end
end

function BrushLayerEditor:instances()
	if not self._instances then
		self:init_instances()
	end
	return self._instances
end

---@param name string|userdata Name of the unit or its Idstring.
function BrushLayerEditor:instance_entry(name)
	if not self._instances then
		self._instances = {}
	end
	local ids = type(name) == "string" and Idstring(name) or name
	local key = ids:key()
	local entry = self._instances[key]
	if not entry then
		local unhashed = type(name) == "string" and name or BLE.Utils:Unhash(ids, "unit")
		entry = {key = key, name = unhashed or ids, positions = {}, rotations = {}}
		self._instances[key] = entry
	end
	return entry
end

function BrushLayerEditor:mark_changed()
	self._amount_dirty = true
	self._massunit_dirty = true
	self._last_change = os.clock()
end

function BrushLayerEditor:add_instance(name, position, rotation)
	local entry = self:instance_entry(name)
	table.insert(entry.positions, position)
	table.insert(entry.rotations, rotation)
	-- shown as a marker until the engine has them (see update_massunit)
	self._pending = self._pending or {}
	table.insert(self._pending, position)
	self:mark_changed()
end

function BrushLayerEditor:remove_instances(found)
	local by_entry = {}
	for _, item in ipairs(found) do
		by_entry[item.entry] = by_entry[item.entry] or {}
		table.insert(by_entry[item.entry], item.index)
	end
	for entry, indexes in pairs(by_entry) do
		table.sort(indexes, function(a, b) return a > b end)
		for _, index in ipairs(indexes) do
			table.remove(entry.positions, index)
			table.remove(entry.rotations, index)
		end
	end
	if #found > 0 then
		self:mark_changed()
	end
end

---The instances in the cylinder of the brush.
---@param only_selected boolean Only the units of the selected brushes.
---@return table List of {entry =, index =}
function BrushLayerEditor:find_instances(base, tip, radius, only_selected)
	local selected
	if only_selected then
		selected = {}
		for _, unit_name in ipairs(self._brush_names) do
			selected[Idstring(unit_name):key()] = true
		end
	end
	local axis = tip - base
	local length_sq = mvector3.length_sq(axis)
	local found = {}
	for key, entry in pairs(self:instances()) do
		if not selected or selected[key] then
			for index, pos in ipairs(entry.positions) do
				local t = length_sq > 0 and (pos - base):dot(axis) / length_sq or 0
				if t >= 0 and t <= 1 and mvector3.distance(pos, base + axis * t) <= radius then
					table.insert(found, {entry = entry, index = index})
				end
			end
		end
	end
	return found
end

---The list of the massunit writer.
function BrushLayerEditor:massunit_units()
	self._quat_cache = self._quat_cache or setmetatable({}, {__mode = "k"})
	local units = {}
	for key, entry in pairs(self:instances()) do
		if #entry.positions > 0 then
			local positions, rotations = {}, {}
			for i, pos in ipairs(entry.positions) do
				positions[i] = {pos.x, pos.y, pos.z}
				local rot = entry.rotations[i]
				local quat = self._quat_cache[rot]
				if not quat then
					quat = math.rot_to_quat(rot)
					self._quat_cache[rot] = quat
				end
				rotations[i] = quat
			end
			table.insert(units, {key = key, positions = positions, rotations = rotations})
		end
	end
	return units
end

function BrushLayerEditor:write_massunit_file()
	if not BLE.MapProject:current_level_path() then
		-- no project level (e.g. a vanilla level): nowhere to write the file to
		return
	end
	local path = self:massunit_file_path()
	local units = self:massunit_units()
	if #units == 0 then
		-- no instance at all: the empty file of the template, the engine does not get a file without a type
		local stub = FileIO:ReadFrom(Path:Combine(BLE.MapProject._templates_directory, "Level/massunit.massunit"), "rb")
		FileIO:WriteTo(path, stub, "wb")
	else
		MassunitWriter:Write(path, units)
	end
end

---Shows the instances: the massunit of the level is loaded again, like the game does when it loads the level. The engine
---is touched as little as possible (it crashed whenever a massunit was replaced while its instances were alive, or a
---resource was asked for right after its reload, which is asynchronous):
---    1. the manager is emptied,  2. a moment later the file is written and reloaded,  3. a moment later it is loaded.
---This only starts when the brush is not in use (a stroke is shown as markers meanwhile) and the last change is a
---moment ago, so a stroke costs one cycle.
function BrushLayerEditor:update_massunit()
	local now = os.clock()
	local state = self._massunit_state
	if state == "emptied" then
		if now >= self._massunit_next then
			self._massunit_dirty = false
			self:write_massunit_file()
			self._massunit_ids = Idstring(managers.worlddefinition:world_dir() .. self:brush_data().file)
			PackageManager:reload(Idstring("massunit"), self._massunit_ids)
			self._massunit_state = "reloaded"
			self._massunit_next = now + 1
		end
	elseif state == "reloaded" then
		if now >= self._massunit_next then
			MassUnitManager:load(self._massunit_ids, Vector3(), Rotation(), {})
			MassUnitManager:set_visibility(self._visible)
			self._massunit_state = nil
			self._pending = nil
		end
	elseif self._massunit_dirty and not (self._spraying or self._erasing) and now - (self._last_change or 0) >= 0.5 then
		MassUnitManager:delete_all_units()
		self._massunit_state = "emptied"
		self._massunit_next = now + 0.4
	end
end

function BrushLayerEditor:unit_positions(name)
	return clone(self:instance_entry(name).positions)
end

function BrushLayerEditor:unit_rotations(name)
	return clone(self:instance_entry(name).rotations)
end

function BrushLayerEditor:delete_units(name)
	local entry = self:instance_entry(name)
	if #entry.positions > 0 then
		entry.positions, entry.rotations = {}, {}
		self:mark_changed()
	end
end

function BrushLayerEditor:reposition_all()
	managers.editor:output("Reposition all brushes:")

	for _, entry in pairs(self:instances()) do
		local positions, rotations = entry.positions, entry.rotations
		local name = type(entry.name) == "string" and entry.name or entry.name:key()
		local nudged_units = 0

		if #positions > 0 then
			entry.positions, entry.rotations = {}, {}

			for counter = 1, #positions do
				local rot = rotations[counter]
				local pos = positions[counter]
				local from = pos + rot:z() * 50
				local to = pos - rot:z() * 110
				local ray_type = self._brush_on_editor_bodies and "body editor" or "body"
				local ray = managers.editor:select_unit_by_raycast(self._place_slot_mask, ray_type, from, to)

				if ray then
					table.insert(entry.positions, ray.position)
					table.insert(entry.rotations, rot)
					if (ray.position - pos):length() > 0.05 then
						nudged_units = nudged_units + 1
					end
				else
					managers.editor:output(" * Lost one of type " .. name .. " - it was too alone at: " .. tostring(pos))
				end
			end
			self:mark_changed()
		end

		if nudged_units > 0 then
			managers.editor:output(" * Nudged " .. nudged_units .. " units of type " .. name)
		end
	end
end

function BrushLayerEditor:clear_all()
    BLE.Utils:YesNoQuestion("This will delete all brushes in this level, are you sure?", function()
		self._instances = {}
		self:mark_changed()
    end)
end

function BrushLayerEditor:clear_unit()
    BLE.Utils:YesNoQuestion("This will delete all selected brushes in this level, are you sure?", function()
        for _, name in ipairs(self._brush_names) do
            self:delete_units(name)
        end
    end)
end

function BrushLayerEditor:_on_amount_updated()
	if not self._debug_units_total then
		return -- the menu is not built yet
	end

	local _, total = self:get_brush_stats()

	self._debug_units_total:SetText("Total Units: " .. total.amount)
	self._debug_units_unique:SetText("Unique Units: " .. total.unique)

	if self._debug_list and self._debug_list:visible() then
		self._debug_list:fill_unit_list()
	end
end

function BrushLayerEditor:set_visibility(cb)
	self._visible = cb:get_value()

	MassUnitManager:set_visibility(self._visible)
end

function BrushLayerEditor:_set_show_placed(cb)
	self._show_placed = cb:get_value()

	self:search_units()
end

function BrushLayerEditor:_set_short_names(cb)
	self._short_names = cb:get_value()

	self:search_units()
end

function BrushLayerEditor:select()
end

function BrushLayerEditor:spray_units()
	if not self._visible then
		return
	end

	self:erase_units_release()

	self._spraying = true
end

function BrushLayerEditor:spray_units_release()
	if self._spraying then
		self._spraying = false
	end
end

function BrushLayerEditor:erase_units()
	if not self._visible then
		return
	end

	self:spray_units_release()

	self._erasing = true
end

function BrushLayerEditor:erase_units_release()
	if self._erasing then
		self._erasing = false
	end
end

function BrushLayerEditor:is_my_unit()
	return false
end

function BrushLayerEditor:update(time, rel_time)
	-- the picture of the brushes is updated even if another tab is open
	self:update_massunit()

	if not self:active() then
		return
	end

	if self._amount_dirty then
		self._amount_dirty = nil
		self._needs_saving = true

		self:_on_amount_updated()
	end

	if self._amount_more_dirty then
		self._amount_more_dirty = nil
		self._amount_dirty = true
	end

	local from = managers.editor:get_cursor_look_point(0)
	local to = managers.editor:get_cursor_look_point(5000)
	local ray_type = self._brush_on_editor_bodies and "body editor" or "body"
	local ray = managers.editor:select_unit_by_raycast(self._place_slot_mask, ray_type)
	local base, tip = nil

	if ray then
		Application:draw_circle(ray.position + ray.normal * 0.1, self._brush_size, 0, 0.7, 0, ray.normal)
		Application:draw_circle(ray.position + ray.normal * 0.1 + ray.normal * self._offset, self._brush_size, 0, 1, 0, ray.normal)

		base = ray.position - ray.normal * 40 - ray.normal * self._offset
		tip = ray.position + ray.normal * self._brush_height + ray.normal * self._offset

		Application:draw_circle(tip, self._brush_size, 0, 0.7, 0, ray.normal)
	else
		local ray_normal = (to - from):normalized()
		base = from + ray_normal * 1000
		tip = from + ray_normal * 10000
		local tunnel = 9000

		while tunnel > 0 do
			Application:draw_circle(base + ray_normal * tunnel, self._brush_size, 0.3 + 0.7 * tunnel / 9000, 0, 0, ray_normal)

			tunnel = tunnel * 0.9 - 100
		end

		Application:draw_circle(base, self._brush_size, 0.3, 0.2, 0.2, ray_normal)
	end

	if self._spraying and ray or self._erasing then
		local found = self:find_instances(base, tip, self._brush_size)
		local area = math.pi * math.pow(self._brush_size / 100, 2)
		local density = #found / area

		if self._spraying then
			local created = 0

			while created < self._brush_pressure and density <= self._brush_density do
				local nudge_amount = 1 - math.rand(self._brush_size * self._brush_size) / (self._brush_size * self._brush_size)
				local rand_nudge = ray.normal:random_orthogonal() * self._brush_size * nudge_amount
				local place_ray = managers.editor:select_unit_by_raycast(self._place_slot_mask, ray_type, tip + rand_nudge, base + rand_nudge)

				self:create_brush(place_ray)

				created = created + 1
				density = (#found + created) / area
			end

			if self._brush_density == 0 then
				self:spray_units_release()
			end
		elseif self._erasing then
			if self._erase_with_units then
				found = self:find_instances(base, tip, self._brush_size, true)
			end
			if self._erase_with_pressure and ray then
				local removed = {}
				for i = 1, math.min(self._brush_pressure, #found) do
					removed[i] = found[i]
				end
				found = removed
			end
			self:remove_instances(found)

			if self._erase_with_pressure and self._brush_density == 0 then
				self:erase_units_release()
			end
		end
	end

	if self._pending then
		for _, position in ipairs(self._pending) do
			Application:draw_sphere(position, 4, 0, 1, 0)
		end
	end

	if self._debug_draw_unit_orientation then
		self:_draw_unit_orientations()
	end
end

function BrushLayerEditor:brush_names_contain(name)
	for _, unit_name in pairs(self._brush_names) do
		if unit_name:id() == name then
			return true
		end
	end
	return false
end

function BrushLayerEditor:_draw_unit_orientations()
	local brush_stats = self:get_brush_stats()

	for _, stats in ipairs(brush_stats) do
		for i = 1, stats.amount do
			Application:draw_rotation(stats.positions[i], stats.rotations[i])
		end
	end
end

function BrushLayerEditor:add_brush_header(name)
	if not self._brush_types[name] then
		local header = BrushHeader:new()

		header:set_name(name)

		self._brush_types[name] = header

		return header
	else
		return self._brush_types[name]
	end
end

function BrushLayerEditor:create_brush(ray)
	if #self._brush_names > 0 and ray then
		local name = self._brush_names[math.floor(1 + math.rand(#self._brush_names))]
		-- a brush that no package of the level has cannot be shown (see ensure_package), loading it can crash the engine
		if not MassUnitManager:can_spawn_unit(Idstring(name)) then
			return
		end

		self:add_brush_header(name)

		local brush_type = self._brush_types[name]
		local at = Vector3(0, 0, 1)
		local up = self._overide_surface_normal and Vector3(0, 0, 1) or ray.normal
		local rand_rotator = Rotation(up, math.rand(self._random_roll) - self._random_roll / 2)

		if self._angle_override ~= 0 then
			rand_rotator = Rotation(up, self._angle_override)
		end

		local right = nil

		if math.abs(up.z) > 0.7 then
			local camera_rot = managers.editor._vp:camera():rotation()

			if camera_rot:z():dot(up) < 0.7 then
				right = camera_rot:z():cross(up):rotate_with(rand_rotator)
				at = up:cross(right)
			else
				at = up:cross(camera_rot:x()):rotate_with(rand_rotator)
				right = at:cross(up)
			end
		else
			right = at:cross(up):rotate_with(rand_rotator)
			at = up:cross(right)
		end

		local rotation = Rotation(right, at, up)
		local position = ray.position + up * self._offset
		self:add_instance(name, position + rotation:z() * brush_type:get_spawn_dist(), rotation)
	end
end

function BrushLayerEditor:build_menu()
	self:GetPart("opt"):add_save_callback("save_massunit", ClassClbk(self, "save"))

	local h = self._holder:ItemsHeight(2)
	local icons = BLE.Utils.EditorIcons
    local controls = self._holder:group("Main", {align_method = "grid", auto_height = false, h = h*1/2})
	local tb = controls:GetToolbar()

	tb:tb_imgbtn("RepositionAll", ClassClbk(self, "reposition_all"), nil, icons.repos_brush, {help = "Tries to reposition all brushes down or to the sides"})
	tb:tb_imgbtn("ClearSelected", ClassClbk(self, "clear_unit"), nil, icons.cross_box, {help = "Clear all selected brushes"})
	tb:tb_imgbtn("ClearAll", ClassClbk(self, "clear_all"), nil, icons.trash, {help = "Clear all brushes"})

    local up = ClassClbk(self, "update_item")
    controls:numberbox("random_roll", up, self._random_roll, {min = 0, max = 360, text = "Random Roll [deg]"})
    self._radius_ctrl = controls:numberbox("brush_size", up, self._brush_size, {min = 1, max = 1000, text = "Radius [cm]"})
    controls:numberbox("brush_height", up, self._brush_height, {min = 0, max = 1000, text = "Height [cm]"})
    controls:numberbox("angle_override", up, self._angle_override, {min = 0, max = 360, text = "Angle [deg]"})
    controls:numberbox("offset", up, self._offset, {min = -30, max = 1000, text = "Offset [cm]]"})
    controls:slider("brush_density", up, self._brush_density, {min = 0, max = 30, text = "Density [/m^2]"})
    controls:slider("brush_pressure", up, self._brush_pressure, {min = 1, max = 20, text = "Pressure"})

    controls:tickbox("erase_with_pressure", up, self._erase_with_pressure, {text = "Pressure Erase", size_by_text = true})
    controls:tickbox("erase_with_units", up, self._erase_with_units, {text = "Erase with Selected Units", size_by_text = true})
    controls:tickbox("overide_surface_normal", up, self._overide_surface_normal, {text = "Override Surface Normal Rotation", size_by_text = true})
    controls:tickbox("brush_on_editor_bodies", up, self._brush_on_editor_bodies, {text = "Brush on Editor Bodies", size_by_text = true})
    controls:tickbox("Visible", ClassClbk(self, "set_visibility"), self._visible, {size_by_text = true})

	controls:tickbox("ShowPlacedBrushesOnly", ClassClbk(self, "_set_show_placed"), self._show_placed, {size_by_text = true})
	controls:tickbox("ShortUnitPaths", ClassClbk(self, "_set_short_names"), self._short_names, {size_by_text = true})

	local debug = controls:group("Debug", {align_method = "grid", closed = true})

    debug:tickbox("debug_draw_unit_orientation", up, self._debug_draw_unit_orientation, {text = "Draw unit orientations"})
    --debug:s_btn("OpenDebugList", ClassClbk(self, "_on_gui_open_debug_list"), {enabled = false})


	self._debug_units_total = debug:lbl("Total Units:", {size_by_text = true})
	self._debug_units_unique = debug:lbl("Unique Units:", {size_by_text = true})

    self._unit_list = self._holder:divgroup("Units", {h = h*1/2, auto_height = false, auto_align = false, text = "Brushes"})
	self._unit_list:GetToolbar():textbox("Search", ClassClbk(self, "search_units"), "", {text = " ", control_slice = 1, w = self._unit_list:ItemsWidth() * 0.75, position = "RightCenteryOffset-x"})
	self:search_units()

    local brushes = self._holder:group("Brushes", {h = h, auto_height = false, align_method = "grid", visible = false})
	local brushes_tb = brushes:GetToolbar()

	brushes_tb:tb_imgbtn("Remove", ClassClbk(self, "remove_brush"), nil, icons.cross, {highlight_color = Color.red, help = "Remove brush"})
	brushes_tb:tb_imgbtn("AddScript", ClassClbk(self, "show_create_brush"), nil, icons.plus, {help = "Add Brush"})

    self._brush_list = brushes:pan("BrushList")
	for name, _ in pairs(self._unit_brushes) do
        self._brush_list:button(name, ClassClbk(self, "select_brush"), {text = name})
	end
end

function BrushLayerEditor:search_units(item)
	item = item or self._unit_list:GetItem("Search")
	local search = item:Value():lower():escape_special()
	self._unit_list:ClearItems("units")
	for _, name in pairs(self._brush_units) do
		local match = name:lower():match(search)
		if self._show_placed and match then
			local positions = self:unit_positions(name)
			match = #positions > 0
		end

		if match then
			local display_name = name:gsub("units/", "")
			if self._short_names then
				display_name = BLE.Utils:ShortPath(name, 1)
			end

			local selected = table.contains(self._selected_unit_names, name)
			self._unit_list:button(name, ClassClbk(self, "select_unit"), {label = "units", text = display_name, help = name, border_left = selected})
		end
	end
	self._unit_list:AlignItems()
end

function BrushLayerEditor:show_create_brush(data)
	if #self._brush_names > 0 then
        BLE.InputDialog:Show({
            title = "Enter name for the new brush configuration:",
            text = "",
            callback = function(name)
                if name and name ~= "" then
                    if self._unit_brushes[name] then
                        self:show_create_brush(data)
                    else
                        self._unit_brushes[name] = clone(self._brush_names)

                        local brush = self._brush_list:button(name, ClassClbk(self, "select_brush"), {text = name})

                        self:save_brushes()
                        self:select_brush(brush)
                    end
                end
            end
        })
	end
end

function BrushLayerEditor:hide_create_brush(data)
	data.dialog:end_modal()

	self._cancel_dialog = data.cancel
end

function BrushLayerEditor:remove_brush(brushes)
	local i = brushes:selected_index()

	if i >= 0 then
		self._unit_brushes[brushes:get_string(i)] = nil

		brushes:remove(i)
		self:save_brushes()

		self._brush_names = {}
	end
end

function BrushLayerEditor:save_brushes()
	if true then
		return
	end
	local f = SystemFS:open(managers.database:base_path() .. self._brushed_path .. ".xml", "w")

	f:puts("<brushes>")

	for name, unit_names in pairs(self._unit_brushes) do
		f:puts("\t<brush name=\"" .. name .. "\">")

		for _, unit_name in ipairs(unit_names) do
			f:puts("\t\t<unit name=\"" .. unit_name .. "\"/>")
		end

		f:puts("\t</brush>")
	end

	f:puts("</brushes>")
	f:close()
	managers.database:recompile(self._brushed_path)
end

function BrushLayerEditor:load_brushes()
	if DB:has("xml", self._brushed_path) then
		local node = DB:load_node("xml", self._brushed_path)

		for brush in node:children() do
			local name = brush:parameter("name")
			local unit_names = {}

			for unit in brush:children() do
				table.insert(unit_names, unit:parameter("name"))
			end

			self._unit_brushes[name] = unit_names
		end
	end
end

--- Brushes only work from the packages the level loads (the massunit manager only knows their units). Offers to add a package that has the
--- brush if it is not available yet.
function BrushLayerEditor:ensure_package(name)
	if MassUnitManager:can_spawn_unit(Idstring(name)) then
		return true
	end
	BLE.Utils:YesNoQuestion(string.format("The brush %s is not in any package this level loads, so it cannot be used. Choose a package that has it to add it to the level?", name), function()
		managers.editor.parts.assets:find_package(name, "unit", true, function()
			-- the package is loaded now, the brush is selected again to make sure it is ready
			self:search_units()
		end)
	end)
	return false
end

function BrushLayerEditor:select_unit(item)
	local name = item.name
	self._unit_name = name
	if not ctrl() then
		self._selected_unit_names = {}
	end
	if table.contains(self._selected_unit_names, name) then
		table.delete(self._selected_unit_names, name)
	else
		table.insert(self._selected_unit_names, name)
		self:ensure_package(name)
	end
	for _, unit_item in pairs(self._unit_list:Items()) do
		unit_item:SetBorder({left = table.contains(self._selected_unit_names, unit_item.name)})
	end

	self._brush_names = {}

	for _, unit_name in ipairs(self._selected_unit_names) do
		table.insert(self._brush_names, unit_name)
	end
end

function BrushLayerEditor:select_hovered_units()
	local from = managers.editor:get_cursor_look_point(0)
	local to = managers.editor:get_cursor_look_point(5000)
	local ray_type = self._brush_on_editor_bodies and "body editor" or "body"

	local ray = managers.editor:select_unit_by_raycast(self._place_slot_mask, ray_type)
	if not ray then
		return
	end

	self._selected_unit_names = {}

	local base = ray.position - ray.normal * 40 - ray.normal * self._offset
	local tip = ray.position + ray.normal * self._brush_height + ray.normal * self._offset

	local found = self:find_instances(base, tip, self._brush_size)
	if #found == 0 then
		return
	end

	for _, item in ipairs(found) do
		local name = type(item.entry.name) == "string" and item.entry.name

		if not name then
			-- the name is not known
		elseif table.contains(self._selected_unit_names, name) then
			table.delete(self._selected_unit_names, name)
		else
			table.insert(self._selected_unit_names, name)
		end
	end		
	
	for _, unit_item in pairs(self._unit_list:Items()) do
		unit_item:SetBorder({left = table.contains(self._selected_unit_names, unit_item.name)})
	end
	
	self._brush_names = {}
	for _, unit_name in ipairs(self._selected_unit_names) do
		table.insert(self._brush_names, unit_name)
	end
end

function BrushLayerEditor:select_brush(item)
	for _, brush_item in pairs(self._brush_list:Items()) do
		brush_item:SetBorder({left = brush_item.name == item.name})
	end

	self._brush_names = {}
    self._selected_brush = item.name

	for _, name in ipairs(self._unit_brushes[item.name]) do
		table.insert(self._brush_names, name)
	end
end

function BrushLayerEditor:update_item(item)
	self["_"..item.name] = item:Value()
end

function BrushLayerEditor:get_brush_stats()
	local brush_stats = {}
	local total = {
		unique = 0,
		amount = 0
	}

	for _, entry in pairs(self:instances()) do
		local amount = #entry.positions
		if amount > 0 then
			table.insert(brush_stats, {
				unit_name = entry.name,
				amount = amount,
				positions = entry.positions,
				rotations = entry.rotations
			})
			total.amount = total.amount + amount
			total.unique = total.unique + 1
		end
	end

	return brush_stats, total
end

function BrushLayerEditor:active()
	return self._visible and self._holder:Visible()
end

function BrushLayerEditor:mouse_busy()
	return self:active()
end

function BrushLayerEditor:mouse_pressed(b, x, y)
	if not self:active() then
		return
	end
    if b == Idstring("0") then
        self:spray_units()
    elseif b == Idstring("1") then
        self:erase_units()
	elseif b == Idstring("2") then
        self:select_hovered_units()
	elseif b == Idstring("mouse wheel up") then
		self._brush_size = math.clamp(self._brush_size+10, 1, 1000)
		self._radius_ctrl:SetValue(self._brush_size)
	elseif b == Idstring("mouse wheel down") then
		self._brush_size = math.clamp(self._brush_size-10, 1, 1000)
		self._radius_ctrl:SetValue(self._brush_size)
    end
	return true
end

function BrushLayerEditor:mouse_released(b, x, y)
	if not self._visible then
		return
	end
    if b == Idstring("0") then
        self:spray_units_release()
    elseif b == Idstring("1") then
        self:erase_units_release()
    end
	return true
end

------------------------------------- Brush Header -------------------------------------------

BrushHeader = BrushHeader or class()

function BrushHeader:init()
	self._name = ""
	self._distance = 0
end

function BrushHeader:set_name(name)
	self._name = name

	if self._name then
		CoreUnit.editor_load_unit(self._name)
	end

	self:setup_brush_distance()
end

function BrushHeader:setup_brush_distance()
	if self._name then
		local ud = PackageManager:unit_data(self._name:id())
		local node = ud and ud.script_data and ud:script_data() or nil
		if node then
			for data in node:children() do
				if data:name() == "brush" then
					self._distance = tonumber(data:parameter("distance")) or 0
				end
			end
		end
	end
end

function BrushHeader:get_spawn_dist()
	return self._distance
end
