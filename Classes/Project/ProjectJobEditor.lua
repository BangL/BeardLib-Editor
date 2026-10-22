---Editor for BeardLib job module (a raid: one job = one level).
---@class ProjectJobEditor : ProjectModuleEditor
ProjectJobEditor = ProjectJobEditor or class(ProjectModuleEditor)
ProjectEditor.EDITORS.job = ProjectJobEditor
ProjectEditor.ACTIONS["CloneJob"] = function(parent, create_data)
    local jobs = {}
    for id, job in pairs(tweak_data.operations.missions) do
        if not job.custom and not job.hidden and job.job_type == OperationsTweakData.JOB_TYPE_RAID and job.level_id then
            table.insert(jobs, {name = id.." / " .. managers.localization:text(job.name_id or ("job_"..id)), id = id})
        end
    end
    BLE.ListDialog:Show({
        list = jobs,
        callback = function(selection)
            BLE.ListDialog:hide()
            ProjectJobEditor:new(parent, nil, table.merge({clone_id = selection.id}, create_data))
        end
    })
end

--- A list for a textbox (lists are written as comma separated attributes), strings stay as they are.
local function join(list)
    return type(list) == "table" and table.concat(list, ",") or list
end

--- Name and briefing of a job are localized as job_[ID]_name/_brief (see JobModule), this keeps the strings of the project in sync.
--- @param func function Gets the string table of the default language file, return true when changed.
function ProjectJobEditor:edit_localization(func)
    local path = Path:Combine(self._parent:get_dir(), "loc", "english.txt")
    if not FileIO:Exists(path) then
        return
    end
    local ok, strings = pcall(json.decode, FileIO:ReadFrom(path))
    if not ok or type(strings) ~= "table" or not func(strings) then
        return
    end
    local keys = table.map_keys(strings)
    table.sort(keys)
    local lines = {}
    for _, key in ipairs(keys) do
        table.insert(lines, string.format("\t%s : %s", json.encode(key), json.encode(strings[key])))
    end
    FileIO:WriteTo(path, "{\n" .. table.concat(lines, ",\n") .. "\n}")
end

--- @param menu ProjectEditor
--- @param data table
function ProjectJobEditor:build_menu(menu, data)
    local up = ClassClbk(self, "set_data_callback")

    data.orig_id = data.orig_id or data.id
    menu:textbox("JobID", up, data.id, {forbidden_chars = {':','*','?','"','<','>','|'}})

    local levels = {}
    for _, mod in pairs(self._parent:get_modules("level")) do
        table.insert(levels, mod.id)
    end
    if data.level_id and not table.contains(levels, data.level_id) then
        table.insert(levels, data.level_id)
    end
    table.sort(levels)
    menu:combobox("Level", up, levels, table.get_key(levels, data.level_id) or 1, {free_typing = true})

    local regions = tweak_data.operations.regions
    menu:combobox("Region", up, regions, table.get_key(regions, data.region or "germany") or 1)
    menu:numberbox("Xp", up, data.xp or 2000, {max = 1000000, min = 0, floats = 0})
    menu:textbox("MusicId", up, data.music_id)
    menu:textbox("MissionFlag", up, data.mission_flag)
    menu:tickbox("StartInStealth", up, data.start_in_stealth, {help = "The mission starts in stealth"})
    local stealth = {"whisper_info_starts_loud", "whisper_info_starts_stealth", "whisper_info_mostly_stealthable", "whisper_info_completely_stealthable"}
    menu:combobox("StealthDescription", up, stealth, table.get_key(stealth, data.stealth_description or (data.start_in_stealth and "whisper_info_starts_stealth" or "whisper_info_starts_loud")) or 1, {
        help = "Text on the mission selection"
    })
    local presets = {"small", "medium", "large"}
    local preset = tweak_data.operations.dogtag_types[type(data.dogtags) == "string" and data.dogtags or "medium"] or tweak_data.operations.dogtag_types.medium
    menu:combobox("Dogtags", up, presets, table.get_key(presets, type(data.dogtags) == "string" and data.dogtags or "medium") or 2, {
        help = "Preset of how many dogtags are placed on the level. The values below override it."
    })
    local loot_help = "Leave at the value of the preset to use the preset"
    menu:numberbox("DogtagsMin", up, tonumber(data.dogtags_min) or preset.min, {min = 0, floats = 0, help = "Minimum dogtag value placed on the level. " .. loot_help})
    menu:numberbox("DogtagsMax", up, tonumber(data.dogtags_max) or preset.max, {min = 0, floats = 0, help = "Maximum dogtag value placed on the level. " .. loot_help})
    menu:numberbox("DogtagsDiffBonus", up, tonumber(data.dogtags_diff_bonus) or preset.diff_bonus, {min = 0, floats = 0, help = "Extra dogtag value per difficulty above the first. " .. loot_help})
    menu:numberbox("DogtagsMinDist", up, tonumber(data.dogtags_min_dist) or 200, {min = 0, floats = 0, help = "Minimum distance between two planted dogtags (cm)"})
    local greed = JobModule.DEFAULT_GREED_ITEMS
    menu:numberbox("GreedItemsMin", up, tonumber(data.greed_items_min) or greed.min, {min = 0, floats = 0, help = "Minimum value of greed items (gold) placed on the level"})
    menu:numberbox("GreedItemsMax", up, tonumber(data.greed_items_max) or greed.max, {min = 0, floats = 0, help = "Maximum value of greed items (gold) placed on the level"})
    menu:textbox("AudioBriefingId", up, data.audio_briefing_id, {help = "Sound event of the audio briefing (Audio tab). Needs an event that exists in the game."})
    menu:textbox("ShortAudioBriefingId", up, data.short_audio_briefing_id, {help = "Sound event that plays when the raid is selected. Needs an event that exists in the game."})
    menu:textbox("ExcludedContinents", up, join(data.excluded_continents), {help = "Continents of the level that are not loaded when it is played as a raid, separated by commas (vanilla raids exclude \"operation\")"})
    menu:textbox("BountyForbidBuffs", up, data.bounty_forbid_buffs or join(data.bounty_filters and data.bounty_filters.forbid_buffs), {help = "Buffs a bounty card must not have for this raid, separated by commas, e.g. bags_dont_slow_players_down,effect_player_carry_invert_speed"})
    menu:tickbox("Hidden", up, data.hidden, {help = "Hide from the raid selection"})

    local divgroup_opt = {border_position_below_title = true, private = {size = 22}}
    local icon_group = menu:divgroup("Icon", divgroup_opt)
    icon_group:button("SelectIconFromDisk", ClassClbk(self, "SelectIconFromDisk"))
    icon_group:pathbox("Icon", up, data.icon, "texture", {text = "Icon Path"})
    icon_group:divider("IconHelp", {
        text = "The icons are loaded from assets/guis/textures/mods/icons: job_[ID].png is the folder icon (about 392x392), job_[ID]_menu.png the one in the list and job_[ID]_hud.png the HUD one (both 56x56), or .texture. "
        .."A missing one is the default icon. The button on top selects the folder icon from disk."
    })
    self:build_photos(menu, divgroup_opt, up)
end

function ProjectJobEditor:photos_dir()
    local af = self._parent:get_module_by_meta("AddFiles")
    return Path:Combine(self._parent:get_dir(), af and af.directory or "assets", "guis/textures/mods/icons")
end

---Number of the photos of the job (job_[ID]_photo_[N] counting up from 1).
function ProjectJobEditor:photo_count(id)
    local count = 0
    local dir = self:photos_dir()
    while count < JobModule.MAX_PHOTOS do
        local base = Path:Combine(dir, "job_" .. (id or self._data.id) .. "_photo_" .. (count + 1))
        if not (FileIO:Exists(base .. ".png") or FileIO:Exists(base .. ".texture")) then
            break
        end
        count = count + 1
    end
    return count
end

function ProjectJobEditor:read_localization()
    local path = Path:Combine(self._parent:get_dir(), "loc", "english.txt")
    local ok, strings = pcall(json.decode, FileIO:Exists(path) and FileIO:ReadFrom(path) or "{}")
    return ok and type(strings) == "table" and strings or {}
end

function ProjectJobEditor:build_photos(menu, opt, up)
    local id = self._data.id
    local strings = self:read_localization()
    local group = menu:divgroup("Photos", opt)
    group:button("AddPhotoFromDisk", ClassClbk(self, "AddPhotoFromDisk"))
    group:button("RemoveLastPhoto", ClassClbk(self, "RemoveLastPhoto"))
    for i = 1, self:photo_count() do
        local key = "job_" .. id .. "_photo_" .. i
        group:textbox("PhotoTitle" .. i, up, strings[key .. "_title"] or "", {text = "Photo " .. i .. " title"})
        group:textbox("PhotoDescription" .. i, up, strings[key .. "_description"] or "", {text = "Photo " .. i .. " description"})
    end
    group:divider("PhotoHelp", {
        text = "The intel photos (about 416x288) are loaded from assets/guis/textures/mods/icons as job_[ID]_photo_1.png, job_[ID]_photo_2.png and so on (or .texture). "
        .."Reopen the job after adding or removing a photo to edit its texts."
    })
end

function ProjectJobEditor:AddPhotoFromDisk()
    if self:photo_count() >= JobModule.MAX_PHOTOS then
        BLE.Utils:Notify("Error", string.format("A job can have %d photos at most", JobModule.MAX_PHOTOS))
        return
    end
    BLE.FBD:Show({
        where = Path:Normalize(Application:base_path()),
        extensions = {"texture", "png"},
        file_click = function(path)
            local id = self._data.id
            local number = self:photo_count() + 1
            FileIO:CopyFile(path, Path:Combine(self:photos_dir(), "job_" .. id .. "_photo_" .. number) .. "." .. Path:GetFileExtension(path))
            self:edit_localization(function(strings)
                local key = "job_" .. id .. "_photo_" .. number
                strings[key .. "_title"] = strings[key .. "_title"] or ("Photo " .. number)
                strings[key .. "_description"] = strings[key .. "_description"] or ""
                return true
            end)
            self._parent:save_data_callback()
            BLE.FBD:Hide()
        end
    })
end

function ProjectJobEditor:RemoveLastPhoto()
    local id = self._data.id
    local number = self:photo_count()
    if number == 0 then
        return
    end
    local base = Path:Combine(self:photos_dir(), "job_" .. id .. "_photo_" .. number)
    FileIO:Delete(base .. ".png")
    FileIO:Delete(base .. ".texture")
    self:edit_localization(function(strings)
        strings["job_" .. id .. "_photo_" .. number .. "_title"] = nil
        strings["job_" .. id .. "_photo_" .. number .. "_description"] = nil
        return true
    end)
    self._parent:save_data_callback()
end

function ProjectJobEditor:SelectIconFromDisk()
    local base_path = Path:Normalize(Application:base_path())

    BLE.FBD:Show({
        where = base_path,
        extensions = {"texture", "png"},
        file_click = function(path)
            local af = self._parent:get_module_by_meta("AddFiles")
            local icon = Path:Combine(self._parent:get_dir(), af and af.directory or "assets", "guis/textures/mods/icons", "job_"..self._data.id)
            FileIO:Delete(icon..".png")
            FileIO:Delete(icon..".texture")
            FileIO:CopyFile(path, icon..'.'..Path:GetFileExtension(path))
            self._data.icon = nil
            self._parent:save_data_callback()
            BLE.FBD:Hide()
        end
    })
end

function ProjectJobEditor:create(create_data)
    ProjectEditor.AskName(create_data, {
        title = "Enter a name for the job",
        yes = "Create",
        text = create_data.name or "",
        check_value = function(name)
            local warn
            for k in pairs(tweak_data.operations.missions) do
                if string.lower(k) == name:lower() then
                    warn = string.format("A job with the id %s already exists! Please use a unique id", k)
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
            local template = deep_clone(BLE.MapProject._job_module_template)
            template.id = name
            template.level_id = name

            local loc = managers.localization
            local src = create_data.clone_id and tweak_data.operations.missions[create_data.clone_id]
            local name_text = src and src.name_id and loc:text(src.name_id) or name
            local brief_text = src and src.briefing_id and loc:text(src.briefing_id) or ""
            self:edit_localization(function(strings)
                strings["job_" .. name .. "_name"] = strings["job_" .. name .. "_name"] or name_text
                strings["job_" .. name .. "_brief"] = strings["job_" .. name .. "_brief"] or brief_text
                return true
            end)

            local clone_id = create_data.clone_id
            if clone_id then
                for _, key in ipairs({"region", "xp", "music_id", "mission_flag", "stealth_description", "start_in_stealth", "dogtags", "dogtags_min", "dogtags_max", "dogtags_diff_bonus", "dogtags_min_dist", "greed_items_min", "greed_items_max", "audio_briefing_id", "short_audio_briefing_id", "bounty_forbid_buffs", "mission_state"}) do
                    template[key] = src[key] or template[key]
                end
                -- vanilla keeps the loot values in tables, the project in attributes
                if type(src.dogtags) == "table" then
                    template.dogtags = nil
                    for _, key in ipairs({"min", "max", "diff_bonus", "min_dist"}) do
                        template["dogtags_" .. key] = src.dogtags[key]
                    end
                end
                if type(src.greed_items) == "table" then
                    template.greed_items_min = src.greed_items.min
                    template.greed_items_max = src.greed_items.max
                end
                template.excluded_continents = join(src.excluded_continents)
                template.bounty_forbid_buffs = join(src.bounty_filters and src.bounty_filters.forbid_buffs)
                -- the three icons of the vanilla raid, each slot has its own size (the list one is 56x56, the folder 392x392)
                template.icon_menu = src.icon_menu
                template.icon_menu_big = src.icon_menu_big
                template.icon_hud = src.icon_hud

                --Clone the level of the raid, it gets the same id as the job.
                ProjectLevelEditor:new(self._parent, nil, {
                    clone_id = src.level_id,
                    name = name,
                    fixed_name = create_data.fixed_name and name or nil,
                    job = template,
                    no_reload = true,
                    final_callback = function()
                        self:finalize_creation(template, create_data)
                    end
                })
            else
                self:finalize_creation(template, create_data)
            end
        end
    })
end

--- The callback function for all items for this menu.
function ProjectJobEditor:set_data_callback()
    local data = self._data

    local name_item = self:GetItem("JobID")
    local new_name = name_item:Value()
    local title = "Job ID"
    if data.id ~= new_name then
        local exists = false
        for _, mod in pairs(self._parent:get_modules("job")) do
            if mod.id == new_name then
                exists = true
            end
        end
        if exists or new_name == "" or (data.orig_id ~= new_name and tweak_data.operations.missions[new_name]) then
            title = title .. "[Invalid]"
        else
            data.id = new_name
        end
    end
    name_item:SetText(title)

    data.level_id = self:GetItem("Level"):SelectedItem()
    data.region = self:GetItem("Region"):SelectedItem()
    data.xp = self:GetItemValue("Xp")
    data.music_id = self:GetItemValue("MusicId")
    data.mission_flag = self:GetItemValue("MissionFlag")
    data.hidden = self:GetItemValue("Hidden") or nil
    local greed = JobModule.DEFAULT_GREED_ITEMS
    local greed_min, greed_max = self:GetItemValue("GreedItemsMin"), self:GetItemValue("GreedItemsMax")
    data.greed_items_min = greed_min ~= greed.min and greed_min or nil
    data.greed_items_max = greed_max ~= greed.max and greed_max or nil
    local presets = tweak_data.operations.dogtag_types
    data.dogtags = self:GetItem("Dogtags"):SelectedItem()
    local preset = presets[data.dogtags] or presets.medium
    -- only what differs from the preset is written
    for key, default in pairs({min = preset.min, max = preset.max, diff_bonus = preset.diff_bonus, min_dist = 200}) do
        local item = ({min = "DogtagsMin", max = "DogtagsMax", diff_bonus = "DogtagsDiffBonus", min_dist = "DogtagsMinDist"})[key]
        local value = self:GetItemValue(item)
        data["dogtags_" .. key] = value ~= default and value or nil
    end
    data.start_in_stealth = self:GetItemValue("StartInStealth") or nil
    data.stealth_description = self:GetItem("StealthDescription"):SelectedItem()
    data.icon = self:GetItem("Icon"):Value()
    data.audio_briefing_id = self:GetItemValue("AudioBriefingId")
    data.short_audio_briefing_id = self:GetItemValue("ShortAudioBriefingId")
    data.excluded_continents = self:GetItemValue("ExcludedContinents")
    data.bounty_forbid_buffs = self:GetItemValue("BountyForbidBuffs")
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
    for _, key in ipairs({"music_id", "mission_flag", "icon", "audio_briefing_id", "short_audio_briefing_id", "excluded_continents", "bounty_forbid_buffs"}) do
        if data[key] == "" then
            data[key] = nil
        end
    end
end

function ProjectJobEditor:save_data()
    local job = self._data
    local orig_id = job.orig_id or job.id -- Job ID has been changed, let's delete the old ID.
    if orig_id ~= job.id then
        -- the events of the operations of the project point to the job
        for _, op in ipairs(self._parent:get_modules("operation")) do
            for _, event in ipairs(op) do
                if type(event) == "table" and event._meta == "event" and (event.job or event.id) == orig_id then
                    event.job = job.id
                    event.id = nil
                end
            end
        end
        tweak_data.operations.missions[orig_id] = nil
        table.delete(tweak_data.operations._raids_index, orig_id)

        self:edit_localization(function(strings)
            local changed
            for _, suffix in ipairs({"_name", "_brief"}) do
                local old_key, new_key = "job_" .. orig_id .. suffix, "job_" .. job.id .. suffix
                if strings[old_key] and not strings[new_key] then
                    strings[new_key] = strings[old_key]
                    strings[old_key] = nil
                    changed = true
                end
            end
            local prefix = "job_" .. orig_id .. "_photo_"
            for key, text in pairs(clone(strings)) do
                if string.begins(key, prefix) then
                    strings["job_" .. job.id .. "_photo_" .. key:sub(#prefix + 1)] = text
                    strings[key] = nil
                    changed = true
                end
            end
            return changed
        end)

        -- Move old photos
        for i = 1, JobModule.MAX_PHOTOS do
            local photo = Path:Combine(self:photos_dir(), "job_")
            FileIO:MoveTo(photo .. orig_id .. "_photo_" .. i .. ".png", photo .. job.id .. "_photo_" .. i .. ".png")
            FileIO:MoveTo(photo .. orig_id .. "_photo_" .. i .. ".texture", photo .. job.id .. "_photo_" .. i .. ".texture")
        end

        local af = self._parent:get_module_by_meta("AddFiles")
        local icon = Path:Combine(self._parent:get_dir(), af and af.directory or "assets", "guis/textures/mods/icons", "job_")

        -- Move old icon
        FileIO:MoveTo(icon .. orig_id..".png", icon .. job.id..".png")
        FileIO:MoveTo(icon .. orig_id..".texture", icon .. job.id..".texture")
    end
    job.orig_id = nil
    return ProjectJobEditor.super.save_data(self)
end

--- Removes the job from the game data (the lists of the editor read it) and the events that point at it.
function ProjectJobEditor:delete()
    local id = self._data.orig_id or self._data.id
    for _, op in ipairs(self._parent:get_modules("operation")) do
        for _, event in ipairs(clone(op)) do
            if type(event) == "table" and event._meta == "event" and (event.job or event.id) == id then
                table.delete_value(op, event)
            end
        end
    end
    local job = tweak_data.operations.missions[id]
    if job and job.custom then
        tweak_data.operations.missions[id] = nil
        table.delete(tweak_data.operations._raids_index, id)
    end
end
