---Editor for BeardLib operation module (a chain of events, every event is a job of the project).
---Photos, icons and the localization work like the ones of a job.
---@class ProjectOperationEditor : ProjectJobEditor
ProjectOperationEditor = ProjectOperationEditor or class(ProjectJobEditor)
ProjectEditor.EDITORS.operation = ProjectOperationEditor

local XML = BeardLib.Utils.XML

ProjectEditor.ACTIONS["CloneOperation"] = function(parent)
    local ops = {}
    for id, op in pairs(tweak_data.operations.missions) do
        if not op.custom and not op.hidden and op.job_type == OperationsTweakData.JOB_TYPE_OPERATION and op.events_index_template then
            local count = 0
            for _, row in ipairs(op.events_index_template) do
                count = count + #row
            end
            table.insert(ops, {name = id .. " / " .. managers.localization:text(op.name_id or ("job_" .. id)) .. " (" .. count .. " events)", id = id})
        end
    end
    table.sort(ops, function(a, b) return a.id < b.id end)
    BLE.ListDialog:Show({
        list = ops,
        callback = function(selection)
            BLE.ListDialog:hide()
            ProjectOperationEditor:new(parent, nil, {clone_id = selection.id})
        end
    })
end

--- Ids of the jobs of the project, the events of an operation.
function ProjectOperationEditor:job_ids()
    local ids = {}
    for _, job in ipairs(self._parent:get_modules("job")) do
        table.insert(ids, job.id)
    end
    table.sort(ids)
    return ids
end

--- The event nodes of the data (children of the operation).
function ProjectOperationEditor:events()
    local events = {}
    for _, child in ipairs(self._data) do
        if type(child) == "table" and child._meta == "event" then
            table.insert(events, child)
        end
    end
    return events
end

function ProjectOperationEditor:build_menu(menu, data)
    local up = ClassClbk(self, "set_data_callback")

    data.orig_id = data.orig_id or data.id
    menu:textbox("OperationID", up, data.id, {forbidden_chars = {':','*','?','"','<','>','|'}})

    local regions = tweak_data.operations.regions
    menu:combobox("Region", up, regions, table.get_key(regions, data.region or "germany") or 1)
    menu:numberbox("Xp", up, tonumber(data.xp) or 5000, {max = 1000000, min = 0, floats = 0, help = "Xp for completing the operation"})
    menu:textbox("AudioBriefingId", up, data.audio_briefing_id, {help = "Sound event of the audio briefing (Audio tab). Needs an event that exists in the game."})
    menu:textbox("ShortAudioBriefingId", up, data.short_audio_briefing_id, {help = "Sound event that plays when the operation is selected. Needs an event that exists in the game."})
    menu:tickbox("AllowFreePlay", up, data.allow_free_play ~= false and data.allow_free_play ~= "false", {help = "Allow to play the events one by one (free play)"})
    menu:tickbox("Hidden", up, data.hidden, {help = "Hide from the operation selection"})

    local events = menu:divgroup("Events", {border_position_below_title = true, private = {size = 22}})
    events:button("AddEvent", ClassClbk(self, "AddEvent"))
    local jobs = self:job_ids()
    for i, event in ipairs(self:events()) do
        local job = event.job or event.id
        if job and not table.contains(jobs, job) then
            table.insert(jobs, job)
        end
        events:combobox("EventJob" .. i, up, jobs, table.get_key(jobs, job) or 1, {text = "Event " .. i .. " (job)"})
        events:numberbox("EventRow" .. i, up, tonumber(event.row) or i, {min = 1, floats = 0, text = "Event " .. i .. " row", help = "Events with the same row are alternatives, one of them is picked every time the operation is started"})
        events:button("RemoveEvent" .. i, ClassClbk(self, "RemoveEvent", i), {text = "Remove event " .. i})
    end
    events:divider("EventsHelp", {
        text = "The events are played one after another in the camp and the levels of their jobs. Every event is a job of this project "
        .."(create it as a job, hide it in the raid list if it should only be played as part of the operation)."
    })

    local divgroup_opt = {border_position_below_title = true, private = {size = 22}}
    local icon_group = menu:divgroup("Icon", divgroup_opt)
    icon_group:button("SelectMenuIconFromDisk", ClassClbk(self, "SelectIconFromDisk", "_menu"))
    icon_group:button("SelectHudIconFromDisk", ClassClbk(self, "SelectIconFromDisk", "_hud"))
    icon_group:divider("IconHelp", {
        text = "The icons are loaded from assets/guis/textures/mods/icons: job_[ID]_menu.png is the one in the list (56x56) and job_[ID]_hud.png the "
        .."big one on the paper and the loading screen (224x224), or .texture. A missing one is the default icon."
    })
    self:build_photos(menu, divgroup_opt, up)
end

--- Copies an icon image to the icons folder of the project.
--- @param suffix string "_menu" or "_hud"
function ProjectOperationEditor:SelectIconFromDisk(suffix)
    BLE.FBD:Show({
        where = Path:Normalize(Application:base_path()),
        extensions = {"texture", "png"},
        file_click = function(path)
            local icon = Path:Combine(self:photos_dir(), "job_" .. self._data.id .. suffix)
            FileIO:Delete(icon .. ".png")
            FileIO:Delete(icon .. ".texture")
            FileIO:CopyFile(path, icon .. "." .. Path:GetFileExtension(path))
            self._parent:save_data_callback()
            BLE.FBD:Hide()
        end
    })
end

--- Reads the events of the menu into the data, in the order of the menu.
function ProjectOperationEditor:read_events()
    for i, event in ipairs(self:events()) do
        local job_item, row_item = self:GetItem("EventJob" .. i), self:GetItem("EventRow" .. i)
        if job_item then
            event.job = job_item:SelectedItem()
            event.row = row_item and row_item:Value() or event.row
            event.id = nil
        end
    end
end

function ProjectOperationEditor:AddEvent()
    self:read_events()
    local jobs = self:job_ids()
    local events = self:events()
    -- the job of the last event, or the first of the project
    local job = events[#events] and (events[#events].job or events[#events].id) or jobs[1]
    if not job then
        BLE.Utils:Notify("Error", "Create a job first, the events of an operation are jobs")
        return
    end
    XML:InsertNode(self._data, {_meta = "event", job = job, row = #events + 1})
    self._parent:open_module(self)
end

function ProjectOperationEditor:RemoveEvent(index)
    self:read_events()
    local event = self:events()[index]
    if event then
        table.delete_value(self._data, event)
    end
    self._parent:open_module(self)
end

--- Clones a vanilla operation: every event becomes a (hidden) job with a clone of its level, the operation points at them
--- in the rows of the original.
function ProjectOperationEditor:clone_operation(name, create_data)
    local missions = tweak_data.operations.missions
    local src = missions[create_data.clone_id]
    local loc = managers.localization

    -- the events in the order of the rows, the same event only once
    local jobs, rows, list = {}, {}, {}
    for _, row in ipairs(src.events_index_template) do
        local event_row = {}
        for _, key in ipairs(row) do
            local event = src.events[key]
            if event and event.level_id then
                if not jobs[key] then
                    jobs[key] = name .. "_" .. key
                    table.insert(list, {key = key, clone_id = missions[event.mission_id] and event.mission_id or key})
                end
                table.insert(event_row, key)
            end
        end
        if #event_row > 0 then
            table.insert(rows, event_row)
        end
    end
    for _, job in pairs(jobs) do
        if missions[job] then
            BLE.Utils:Notify("Error", string.format("A job or operation with the id %s already exists! Please use another name", job))
            return
        end
    end

    local function create_jobs()
        local function step(i)
            local entry = list[i]
            if not entry then
                return self:finish_clone(name, src, rows, jobs, create_data)
            end
            ProjectJobEditor:new(self._parent, nil, {
                clone_id = entry.clone_id,
                fixed_name = jobs[entry.key],
                no_reload = true,
                final_callback = function(success, data)
                    if not success then
                        BLE.Utils:Notify("Error", "Cloning the operation failed at the event " .. entry.key .. ", the jobs created until then stay in the project")
                        return
                    end
                    data.hidden = true -- only played as part of the operation
                    step(i + 1)
                end
            })
        end
        step(1)
    end

    if #list > 6 then
        BLE.Utils:YesNoQuestion(string.format("This clones %d levels and takes a while, the game may look frozen. Continue?", #list), create_jobs)
    else
        create_jobs()
    end
end

function ProjectOperationEditor:finish_clone(name, src, rows, jobs, create_data)
    local loc = managers.localization
    local template = deep_clone(BLE.MapProject._operation_module_template)
    template.id = name
    for _, key in ipairs({"region", "xp", "icon_menu", "icon_hud", "audio_briefing_id", "short_audio_briefing_id"}) do
        template[key] = src[key] or template[key]
    end
    template.allow_free_play = not src.allow_free_play and "false" or nil
    for i, row in ipairs(rows) do
        for _, key in ipairs(row) do
            XML:InsertNode(template, {_meta = "event", job = jobs[key], row = i})
        end
    end
    local name_text = src.name_id and loc:text(src.name_id) or name
    local brief_text = src.briefing_id and loc:text(src.briefing_id) or ""
    self:edit_localization(function(strings)
        strings["job_" .. name .. "_name"] = strings["job_" .. name .. "_name"] or name_text
        strings["job_" .. name .. "_brief"] = strings["job_" .. name .. "_brief"] or brief_text
        return true
    end)
    self:finalize_creation(template, create_data)
end

function ProjectOperationEditor:create(create_data)
    ProjectEditor.AskName(create_data, {
        title = "Enter a name for the operation",
        yes = "Create",
        text = create_data.name or "",
        check_value = function(name)
            local warn
            for k in pairs(tweak_data.operations.missions) do
                if string.lower(k) == name:lower() then
                    warn = string.format("A job or operation with the id %s already exists! Please use a unique id", k)
                end
            end
            if name == "" then
                warn = "Id cannot be empty!"
            elseif string.begins(name, " ") then
                warn = "Invalid ID!"
            end
            if warn then
                BLE.Utils:Notify("Error", warn)
            end
            return warn == nil
        end,
        no_callback = function()
            if create_data.final_callback then
                create_data.final_callback(false)
            end
        end,
        callback = function(name)
            if create_data.clone_id then
                return self:clone_operation(name, create_data)
            end
            local template = deep_clone(BLE.MapProject._operation_module_template)
            template.id = name
            -- an operation needs events: all jobs of the project, one row each
            for i, job in ipairs(self:job_ids()) do
                XML:InsertNode(template, {_meta = "event", job = job, row = i})
            end
            self:edit_localization(function(strings)
                strings["job_" .. name .. "_name"] = strings["job_" .. name .. "_name"] or name
                strings["job_" .. name .. "_brief"] = strings["job_" .. name .. "_brief"] or ""
                return true
            end)
            self:finalize_creation(template, create_data)
        end
    })
end

--- The callback function for all items for this menu.
function ProjectOperationEditor:set_data_callback()
    local data = self._data

    local name_item = self:GetItem("OperationID")
    local new_name = name_item:Value()
    local title = "Operation ID"
    if data.id ~= new_name then
        local exists = tweak_data.operations.missions[new_name] and new_name ~= data.orig_id
        if new_name == "" or exists then
            title = title .. "[!]"
        else
            data.id = new_name
        end
    end
    name_item:SetText(title)

    data.region = self:GetItem("Region"):SelectedItem()
    data.xp = self:GetItemValue("Xp")
    data.allow_free_play = not self:GetItemValue("AllowFreePlay") and "false" or nil
    data.hidden = self:GetItemValue("Hidden") or nil
    data.audio_briefing_id = self:GetItemValue("AudioBriefingId")
    data.short_audio_briefing_id = self:GetItemValue("ShortAudioBriefingId")
    for _, key in ipairs({"audio_briefing_id", "short_audio_briefing_id"}) do
        if data[key] == "" then
            data[key] = nil
        end
    end
    self:read_events()

    -- the texts of the photos live in the localization
    local photo_count = self:photo_count()
    if photo_count > 0 and self:GetItem("PhotoTitle1") then
        self:edit_localization(function(strings)
            for i = 1, photo_count do
                local key = "job_" .. data.id .. "_photo_" .. i
                strings[key .. "_title"] = self:GetItemValue("PhotoTitle" .. i)
                strings[key .. "_description"] = self:GetItemValue("PhotoDescription" .. i)
            end
            return true
        end)
    end
end

function ProjectOperationEditor:save_data()
    local op = self._data
    local orig_id = op.orig_id or op.id -- the ID has been changed, delete the old one.
    if orig_id ~= op.id then
        tweak_data.operations.missions[orig_id] = nil
        table.delete(tweak_data.operations._operations_index, orig_id)

        self:edit_localization(function(strings)
            local changed
            local prefix = "job_" .. orig_id .. "_"
            for key, text in pairs(clone(strings)) do
                if string.begins(key, prefix) then
                    strings["job_" .. op.id .. "_" .. key:sub(#prefix + 1)] = text
                    strings[key] = nil
                    changed = true
                end
            end
            return changed
        end)

        local icons = Path:Combine(self:photos_dir(), "job_")
        for _, suffix in ipairs({"_menu", "_hud"}) do
            FileIO:MoveTo(icons .. orig_id .. suffix .. ".png", icons .. op.id .. suffix .. ".png")
            FileIO:MoveTo(icons .. orig_id .. suffix .. ".texture", icons .. op.id .. suffix .. ".texture")
        end
        for i = 1, JobModule.MAX_PHOTOS do
            FileIO:MoveTo(icons .. orig_id .. "_photo_" .. i .. ".png", icons .. op.id .. "_photo_" .. i .. ".png")
            FileIO:MoveTo(icons .. orig_id .. "_photo_" .. i .. ".texture", icons .. op.id .. "_photo_" .. i .. ".texture")
        end
    end
    op.orig_id = nil
    return ProjectModuleEditor.save_data(self)
end

--- Removes the operation from the game data (the lists of the editor read it).
function ProjectOperationEditor:delete()
    local id = self._data.orig_id or self._data.id
    local op = tweak_data.operations.missions[id]
    if op and op.custom then
        tweak_data.operations.missions[id] = nil
        table.delete(tweak_data.operations._operations_index, id)
    end
end
