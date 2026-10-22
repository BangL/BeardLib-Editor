-- Keeps the editor from touching the player's profile (progress, stats, xp, gold, weapon challenges).
-- The wrappers check Global.editor_mode on every call, so nothing stays disabled outside the editor.
local function guard(class, names)
    for _, name in ipairs(names) do
        local orig = class[name]
        if orig then
            class[name] = function(self, ...)
                if Global.editor_mode then
                    return
                end
                return orig(self, ...)
            end
        end
    end
end

local F = table.remove(RequiredScript:split("/"))

if F == "savefilemanager" then
    guard(SavefileManager, {"save_game", "save_progress"})
elseif F == "statisticsmanager" then
    guard(StatisticsManager, {
        "start_session", "stop_session", "killed", "killed_by_anyone", "downed", "_increment_misc", "_increment_camp_stat",
        "publish_to_steam", "publish_camp_stats_to_steam", "publish_top_stats_to_steam", "publish_level_to_steam",
        "publish_gold_to_steam", "publish_custom_stat_to_steam"
    })
elseif F == "raidexperiencemanager" then
    guard(RaidExperienceManager, {"add_points", "mission_xp_award", "add_loot_redeemed_xp", "on_loot_drop_xp"})
elseif F == "greedmanager" then
    guard(GreedManager, {"award_gold_picked_up_in_mission", "on_level_exited", "secure_bounty", "sync_secured_bounty"})
elseif F == "challengetasks" then
    -- the progress of the weapon challenges (kills, ammo, candy) is kept in memory and saved with the next save after the editor
    guard(ChallengeTaskKillEnemies, {"on_enemy_killed"})
    guard(ChallengeTaskCollectAmmo, {"on_ammo_collected"})
    guard(ChallengeTaskCollectCandy, {"_on_candy_consumed"})
end
