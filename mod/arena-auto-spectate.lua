
local autoSpectateTimer = 1 * 60 * 30 -- 1 minute

function is_auto_spectating_approaching()
    if autoSpectateTimer <= 5 * 30 and gPlayerSyncTable[0].team ~= TEAM_SPECTATOR then return autoSpectateTimer else return nil end
end

---@param m MarioState
local function mario_update(m)
    if m.playerIndex ~= 0 then return end
    if active_player_count(false) == 1 then return end

    autoSpectateTimer = clamp(autoSpectateTimer - 1, 0, autoSpectateTimer)

    if m.controller.buttonPressed ~= 0
    or m.controller.buttonDown ~= 0
    or m.controller.stickX > 10
    or m.controller.stickX < -10
    or m.controller.stickY > 10
    or m.controller.stickY < -10 then
        autoSpectateTimer = 1 * 60 * 30
    end

    if  autoSpectateTimer <= 0 then
        gPlayerSyncTable[0].team = TEAM_SPECTATOR
        gPlayerSyncTable[0].item = ITEM_NONE
    end
end

hook_event(HOOK_MARIO_UPDATE, mario_update)