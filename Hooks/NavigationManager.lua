if not Global.editor_mode then
	return
end

local mvec3_cpy = mvector3.copy
--[[function NavigationManager:init()
	self._debug = SystemInfo:platform() == Idstring("WIN32")
	self._builder = NavFieldBuilder:new()
	self._get_room_height_at_pos = self._builder._get_room_height_at_pos
	self._check_room_overlap_bool = self._builder._check_room_overlap_bool
	self._door_access_types = self._builder._door_access_types
	self._opposite_side_str = self._builder._opposite_side_str
	self._perp_pos_dir_str_map = self._builder._perp_pos_dir_str_map
	self._perp_neg_dir_str_map = self._builder._perp_neg_dir_str_map
	self._dim_str_map = self._builder._dim_str_map
	self._perp_dim_str_map = self._builder._perp_dim_str_map
	self._neg_dir_str_map = self._builder._neg_dir_str_map
	self._x_dir_str_map = self._builder._x_dir_str_map
	self._dir_str_to_vec = self._builder._dir_str_to_vec
	self._geog_segment_size = self._builder._geog_segment_size
	self._grid_size = self._builder._grid_size
	self._worlds = {}
	self._rooms = {}
	self._room_doors = {}
	self._geog_segments = {}
	self._nr_geog_segments = nil
	self._visibility_groups = {}
	self._nav_segments = {}
	self._coarse_searches = {}
	self:set_debug_draw_state(true)
	self._covers = {}
	self._next_pos_rsrv_expiry = false
	if self._debug then
		self._nav_links = {}
	end
	self._quad_field = World:quad_field()
	self._quad_field:set_nav_link_filter(NavigationManager.ACCESS_FLAGS)
	self._pos_rsrv_filters = {}
	self._obstacles = {}
	if self._debug then
		self._pos_reservations = {}
	end
end]]--

function NavigationManager:init()
	Application:trace("[NavigationManager][init]")

	self._debug = SystemInfo:platform() == Idstring("WIN32")
	self._builder = NavFieldBuilder:new()
	self._get_room_height_at_pos = self._builder._get_room_height_at_pos
	self._check_room_overlap_bool = self._builder._check_room_overlap_bool
	self._door_access_types = self._builder._door_access_types
	self._opposite_side_str = self._builder._opposite_side_str
	self._perp_pos_dir_str_map = self._builder._perp_pos_dir_str_map
	self._perp_neg_dir_str_map = self._builder._perp_neg_dir_str_map
	self._dim_str_map = self._builder._dim_str_map
	self._perp_dim_str_map = self._builder._perp_dim_str_map
	self._neg_dir_str_map = self._builder._neg_dir_str_map
	self._x_dir_str_map = self._builder._x_dir_str_map
	self._dir_str_to_vec = self._builder._dir_str_to_vec
	self._geog_segment_size = self._builder._geog_segment_size
	self._grid_size = self._builder._grid_size
	self._worlds = {}
	self._rooms = {}
	self._room_doors = {}
	self._geog_segments = {}
	self._nr_geog_segments = nil
	self._nav_segments = {}
	self._nav_stitcher_counter = 0
	self._coarse_searches = {}
	self:set_debug_draw_state(true)
	self._covers = {}
	self._next_pos_rsrv_expiry = false

	if self._debug then
		self._nav_links = {}
	end

	self._quad_field = World:quad_field()

	self._quad_field:set_nav_link_filter(NavigationManager.ACCESS_FLAGS)

	self._pos_rsrv_filters = {}
	self._obstacles = {}
	self._pos_reservations = {}

	self:_init_draw_data()

	self._data_ready = false
	self._listener_holder = QueuedEventListenerHolder:new()
end

function NavigationManager:update(t, dt)
	if self._debug then
		self._builder:update(t, dt)
		if self._draw_enabled then
			local options = self._draw_enabled
			local data = self._draw_data
			if data and type(options) == "table" then
				local progress = self._use_fast_drawing and 1 or math.clamp((t - data.start_t) / (data.duration * 0.5), 0, 1)
                if options.quads then
                    self:_draw_rooms(progress)
                end
                if options.doors then
                    self:_draw_doors(progress)
                end
                if options.blockers then
                    self:_draw_nav_blockers()
                end
				if options.obstacles then
                    self:_draw_nav_obstacles()
                end
                if options.vis_graph then
                    self:_draw_visibility_groups(progress)
                end
                if options.coarse_graph then
                    self:_draw_coarse_graph()
                end
                if options.nav_links then
                    self:_draw_anim_nav_links()
                end
                if options.covers then
                    self:_draw_covers()
                end
				if options.pos_rsrv then
					self:_draw_pos_reservations(t)
				end
				if not self._use_fast_drawing and progress == 1 then
					self._draw_data.start_t = t
				end
			end
		end
	end
	self:_commence_coarce_searches(t)
end

function NavigationManager:_init_draw_data()
	local data = {}
	local duration = not self._use_fast_drawing and 10 or nil
	data.duration = duration
	local brush = {
		door = Draw:brush(Color(0.1, 0, 1, 1), duration),
		room_diag = Draw:brush(Color(1, 0.5, 0.5, 0), duration),
		room_diag_disabled = Draw:brush(Color(0.5, 0.7, 0, 0), duration),
		room_diag_obstructed = Draw:brush(Color(0.5, 0.5, 0, 0.5), duration),
		room_border = Draw:brush(Color(0, 0.3, 0.3, 0.8), duration),
		room_fill = Draw:brush(Color(0.3, 0.3, 0.3, 0.8), duration),
		room_fill_disabled = Draw:brush(Color(0.3, 0.8, 0.3, 0.3), duration),
		room_fill_obstructed = Draw:brush(Color(0.3, 0.8, 0, 0.8), duration),
		coarse_graph = Draw:brush(Color(0.2, 0.9, 0.9, 0.2)),
		vis_graph_rooms = Draw:brush(Color(0.6, 0.5, 0.2, 0.9), duration),
		vis_graph_node = Draw:brush(Color(1, 0.6, 0, 0.9), duration),
		vis_graph_links = Draw:brush(Color(0.2, 0.8, 0.1, 0.6), duration),
		obstacles = Draw:brush(Color(0.3, 1, 0, 1)),
		blocked = Draw:brush(Color(1, 1, 1, 1))
	}

	brush.blocked:set_font(Idstring("fonts/font_medium_buttons"), 30)

	data.brush = brush
	local offsets = {
		Vector3(-1, -1),
		Vector3(-1, 1),
		Vector3(1, -1),
		Vector3(1, 1)
	}
	data.offsets = offsets
	data.next_draw_i_room = 1
	data.next_draw_i_door = 1
	data.next_draw_i_coarse = 1
	data.next_draw_i_vis = 1
	self._draw_data = data
end

function NavigationManager:set_debug_draw_state(options)
    local temp = {}
	local fast_drawing = true
    if type(options) == "table" then
        for k, option in pairs(options) do
            if type(option) == "table" then
				if k == "fast_drawing" then
					fast_drawing = option.value
				else
                	temp[k] = option.value
				end
            end
        end

		if table.size(temp) > 0 then
        	options = temp
		else
			options = nil
		end
    end
    if options and (not self._draw_enabled or fast_drawing ~= self._use_fast_drawing) then
		self._use_fast_drawing = fast_drawing
        self:_init_draw_data()
        self._draw_data.start_t = TimerManager:game():time()
    end
    self._draw_enabled = options
end

function NavigationManager:build_complete_clbk(draw_options)
	self:_refresh_data_from_builder()
	if self._builder:is_data_complete() then
		self:_create_load_data_from_builder(self:_get_default_world_id())
		self:_load_nav_data(self._load_data, self:_get_default_world_id(), nil, nil)
		self._quad_field:clear_all()

		local setup_data = {
			quad_grid_size = self._grid_size,
			sector_grid_size = self._sector_grid_size
		}

		self._quad_field:setup(setup_data, callback(self, self, "clbk_navfield"))
		self._quad_field:set_nav_link_filter(NavigationManager.ACCESS_FLAGS)
		self:_send_nav_field_to_engine(self._load_data, self:_get_default_world_id(), nil, nil)

		self._data = self._data or {}
		self._data[0] = self._load_data

		self:_resolve_segment_neighbours(self:_get_default_world_id())
	end
	self:set_debug_draw_state(draw_options)
	if self:is_data_ready() then
		self._load_data = self:get_save_data()
        local c = BLE.Utils:GetPart("opt")
        BLE:log("Navigation data Progress: Done!")
    end
	if self._build_complete_clbk then
		self._build_complete_clbk()
	end
	BLE.Utils:GetLayer("ai"):reenable_disabled_units()
end

local search = NavigationManager.search_coarse
function NavigationManager:search_coarse( ... )
    if self._builder._building then
        return
    end
    return search(self, ...)
end

function NavigationManager:_safe_remove_unit(unit) end
function NavigationManager:remove_AI_blocker_units() end

function NavigationManager:_draw_nav_blockers()
	if self._builder._helper_blockers then
		local nav_segments = self._builder._nav_segments
		local registered_blockers = self._builder._helper_blockers
		local all_blockers = World:find_units_quick("all", 15)

		for _, blocker_unit in ipairs(all_blockers) do
			local id = blocker_unit:unit_data().unit_id

			if registered_blockers[id] then
				local draw_pos = blocker_unit:oobb() and blocker_unit:oobb():center() or blocker_unit:position()
				local nav_segment = registered_blockers[id]

				if nav_segments and nav_segments[nav_segment] and self._selected_segment == nav_segment then
					Application:draw(blocker_unit, 1, 0, 0)
					Application:draw_cylinder(draw_pos, nav_segments[nav_segment].pos, 2, 0.8, 0.1, 0)
				end
			end
		end
	end
end

function NavigationManager:_draw_nav_obstacles()
	if self._obstacles then
		local draw = self._draw_data
		local brushes = draw and draw.brush
		for id, obstacle_data in ipairs(self._obstacles) do
			local unit = obstacle_data.unit
			if alive(unit) then
				Application:draw(unit, 1, 0, 1)
				brushes.obstacles:unit(unit)
			end
		end
	end
end

function NavigationManager:_refresh_data_from_builder()
	self._rooms = self._builder._rooms
	self._room_doors = self._builder._room_doors
	self._geog_segments = self._builder._geog_segments
	self._geog_segment_offset = self._builder._geog_segment_offset
	self._nr_geog_segments = self._builder._nr_geog_segments
	self._visibility_groups = self._builder._visibility_groups
	self._nav_segments = self._builder._nav_segments
end

function NavigationManager:_draw_rooms(progress)
	local selected_seg = self._selected_segment
	local room_mask = nil

	if selected_seg and self._nav_segments[selected_seg] and next(self._nav_segments[selected_seg].vis_groups) then
		room_mask = {}

		for _, i_vis_group in ipairs(self._nav_segments[selected_seg].vis_groups) do
			local vis_group_rooms = self._visibility_groups[i_vis_group].rooms

			for i_room, _ in pairs(vis_group_rooms) do
				room_mask[i_room] = true
			end
		end
	end

	local data = self._draw_data
	local rooms = self._rooms
	local nr_rooms = #rooms
	local i_room = data.next_draw_i_room
	local wanted_index = math.clamp(math.ceil(nr_rooms * progress), 1, nr_rooms)

	while i_room <= wanted_index and i_room <= nr_rooms do
		local room = rooms[i_room]

		if not room_mask or room_mask[i_room] then
			self:_draw_room(room)
		end

		i_room = i_room + 1
	end

	if progress == 1 then
		data.next_draw_i_room = 1
	else
		data.next_draw_i_room = i_room
	end
end

function NavigationManager:_draw_coarse_graph()
	local all_nav_segments = self._nav_segments
	local all_doors = self._room_doors
	local all_vis_groups = self._visibility_groups
	local cone_height = Vector3(0, 0, 50)

	for seg_id, seg_data in pairs(all_nav_segments) do
		local neighbours = seg_data.neighbours

		for neigh_i_seg, door_list in pairs(neighbours) do
			local pos = all_nav_segments[neigh_i_seg].pos
			local color = {
				1,
				1,
				0
			}

			if all_nav_segments[neigh_i_seg].disabled then
				color = {
					1,
					0,
					0
				}
			elseif seg_data.blocked_group or all_nav_segments[neigh_i_seg].blocked_group then
				color = {
					1,
					0.5,
					0
				}

				self._draw_data.brush.blocked:center_text(pos + cone_height * 2, all_nav_segments[neigh_i_seg].blocked_group)
			end

			Application:draw_cone(pos, seg_data.pos, 12, unpack(color))
			Application:draw_cone(pos, pos + cone_height, 40, unpack(color))
		end
	end
end

function NavigationManager:get_save_data()
	log("load Data:")
	log(tostring(self._load_data))
	return ScriptSerializer:to_generic_xml(self._load_data or {
		version = NavFieldBuilder._VERSION
	})
end