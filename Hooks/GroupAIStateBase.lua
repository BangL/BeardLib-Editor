if not Global.editor_mode then
	return
end

local F = table.remove(RequiredScript:split("/"))

if F == "groupaistatebase" then
    Hooks:PostHook(GroupAIStateBase, "_init_misc_data", "EditorGroupAIInit", function(self)
        self._enemies_spawned_assault = 0
        self._enemies_spawned_lifetime = 0
        self._enemies_in_level = 0
        self._enemies_killed_assault = 0
        self._enemies_killed_lifetime = 0
    end)

    -- A play test player may not have a criminal record (e.g. after the preview respawned it),
    -- which makes the vanilla code crash on the final death. Treat that as the end of the play test.
    local on_player_criminal_death = GroupAIStateBase.on_player_criminal_death
    function GroupAIStateBase:on_player_criminal_death(peer_id, ...)
        local peer = managers.network:session():peer(peer_id)
        local unit = peer and peer:unit()
        if not unit or not self._criminals[unit:key()] then
            Global.editor_player_died = true
            managers.raid_job:external_end_mission(false, true)
            return
        end
        return on_player_criminal_death(self, peer_id, ...)
    end

    Hooks:PostHook(GroupAIStateBase, "update", "EditorGroupAISpawns", function(self, use_last)
        if not self._task_data then
            return
        end
        
        local force_spawned = math.max((self._task_data.assault.force_spawned or 0) - self._enemies_spawned_assault, 0)
        local enemies = self:_count_police_force("assault")
        local killed = math.max(self._enemies_in_level -  enemies, 0)

        self._enemies_spawned_lifetime = self._enemies_spawned_lifetime + force_spawned
        self._enemies_spawned_assault = self._task_data.assault.force_spawned or 0

        self._enemies_killed_assault = self._enemies_killed_assault + killed
        self._enemies_killed_lifetime = self._enemies_killed_lifetime + killed
        self._enemies_in_level = enemies
    end)

    function GroupAIStateBase:enemies_spawned_lifetime()
        return self._enemies_spawned_lifetime
    end

    function GroupAIStateBase:enemies_spawned_in_current_assault()
        return self._enemies_spawned_assault
    end

    function GroupAIStateBase:enemies_killed_lifetime()
        return self._enemies_killed_lifetime
    end

    function GroupAIStateBase:enemies_killed_in_current_assault()
        return self._enemies_killed_assault
    end

    function GroupAIStateBase:enemies_in_level()
        return self._enemies_in_level
    end

elseif F == "groupaistatebesiege" then
    Hooks:PostHook(GroupAIStateBesiege, "_begin_assault_task", "EditorBesiegeReset", function(self, assault_areas)
        self._enemies_spawned_assault = 0
        self._enemies_killed_assault = 0
    end)
end
