------------
-- tables --
------------

gMarioStateExtras = {}
for i = 0, (MAX_PLAYERS - 1) do
    local np = gNetworkPlayers[i]

    gMarioStateExtras[i] = {}
    local e = gMarioStateExtras[i]
    e.rotAngle            = 0
    e.rotFrames           = 0
    e.lastDamagedByGlobal = np.globalIndex
    e.attackCooldown      = 0
    e.prevHurtCounter     = 0
    e.levelTimer          = 0
    e.levelTimerLevel     = 0
    e.springing           = 0

    local s = gPlayerSyncTable[i]
    s.item     = ITEM_NONE
    s.ammo     = 0
    s.kills    = 0
    s.deaths   = 0
    s.score    = 0
    s.team     = 0
    s.charging = 0
    s.metal    = false
    s.rank     = 0
end

local sKnockbackActions = {
    ACT_SOFT_FORWARD_GROUND_KB, ACT_FORWARD_GROUND_KB, ACT_HARD_FORWARD_GROUND_KB,
    ACT_FORWARD_AIR_KB, ACT_FORWARD_AIR_KB, ACT_HARD_FORWARD_AIR_KB,
    ACT_FORWARD_WATER_KB, ACT_FORWARD_WATER_KB, ACT_FORWARD_WATER_KB,
    ACT_SOFT_BACKWARD_GROUND_KB, ACT_BACKWARD_GROUND_KB, ACT_HARD_BACKWARD_GROUND_KB,
    ACT_BACKWARD_AIR_KB, ACT_BACKWARD_AIR_KB, ACT_HARD_BACKWARD_AIR_KB,
    ACT_BACKWARD_WATER_KB, ACT_BACKWARD_WATER_KB, ACT_BACKWARD_WATER_KB,

    ACT_LEDGE_GRAB, ACT_LEDGE_CLIMB_SLOW_1, ACT_LEDGE_CLIMB_SLOW_2, ACT_LEDGE_CLIMB_DOWN, ACT_LEDGE_CLIMB_FAST,
    ACT_GROUND_BONK, ACT_SOFT_BONK,

    ACT_STOP_CROUCHING, ACT_STOMACH_SLIDE_STOP,
}

-----------
-- hooks --
-----------

function allow_pvp_attack(attacker, victim)
    local npAttacker = gNetworkPlayers[attacker.playerIndex]
    local sAttacker = gPlayerSyncTable[attacker.playerIndex]
    local sVictim = gPlayerSyncTable[victim.playerIndex]

    -- check spectator status
    if sAttacker.team == TEAM_SPECTATOR or sVictim.team == TEAM_SPECTATOR then return false end

    -- hammer attacks are custom
    if sAttacker.item == ITEM_HAMMER and mario_hammer_is_attack(attacker) then
        return false
    end

    -- check teams
    return global_index_hurts_mario_state(npAttacker.globalIndex, victim)
end

function on_pvp_attack(attacker, victim)
    if victim.playerIndex == 0 then
        local e = gMarioStateExtras[victim.playerIndex]
        local npAttacker = gNetworkPlayers[attacker.playerIndex]
        e.lastDamagedByGlobal = npAttacker.globalIndex
    end
end

function allow_interact(interactor, interactee, interactType, interactValue)
    -- find the interactee's mario state if this is mario
    for i = 0, MAX_PLAYERS - 1 do
        local m = gMarioStates[i]
        local s = gPlayerSyncTable[i]
        if m.marioObj == interactee and s.team == TEAM_SPECTATOR then
            return false
        end
    end

    if gPlayerSyncTable[interactor.playerIndex].team == TEAM_SPECTATOR then return false end
end

function on_interact(interactor, interactee, interactType, interactValue)
    if interactor.playerIndex ~= 0 then return end
    local bhvId = get_id_from_behavior(interactee.behavior)
    if bhvId ~= id_bhvArenaFlame and bhvId ~= id_bhvArenaChildFlame then return end

    local e = gMarioStateExtras[interactor.playerIndex]
    e.lastDamagedByGlobal = interactee.oArenaFlameGlobalOwner
end

function on_set_mario_action(m)
    local e = gMarioStateExtras[m.playerIndex]
    local s = gPlayerSyncTable[m.playerIndex]
    if m.action == ACT_DIVE then
        e.rotAngle = 0
        e.rotFrames = 0
    end

    if m.playerIndex == 0 and is_player_active(m) ~= 0 then
        if (m.action & ACT_FLAG_AIR) == 0 then
            if e.springing == 1 then
                e.springing = 0
            end
        end
    end
end

function mario_local_update(m)
    local np = gNetworkPlayers[m.playerIndex]
    local s = gPlayerSyncTable[m.playerIndex]
    local e = gMarioStateExtras[m.playerIndex]

    -- decrease cooldown
    if e.attackCooldown > 0 then
        e.attackCooldown = e.attackCooldown - 1
    end

    -- break out of shot from cannon
    if (m.action == ACT_SHOT_FROM_CANNON) then
        if (m.input & INPUT_B_PRESSED) ~= 0 then
            return set_mario_action(m, ACT_DIVE, 0)
        elseif (m.input & INPUT_Z_PRESSED) ~= 0 then
            return set_mario_action(m, ACT_GROUND_POUND, 0)
        end
    end

    -- set metal
    s.metal = (m.capTimer > 0)

    -- increase damage when holding flag
    if is_holding_flag(m) then
        if m.hurtCounter > e.prevHurtCounter then
            m.hurtCounter = m.hurtCounter * 2
        end
    end

    -- reduce damage when metal
    if s.metal then
        if m.hurtCounter > e.prevHurtCounter then
            m.hurtCounter = m.hurtCounter / 2
        end
    end

    -- discard current item
    if s.item ~= ITEM_NONE and (s.ammo <= 0 or (m.controller.buttonPressed & L_TRIG) ~= 0) then
        s.item = ITEM_NONE
        if gItemHeld[m.playerIndex] ~= nil then
            spawn_triangles(gItemHeld[m.playerIndex])
        end
        play_sound(SOUND_GENERAL_BREAK_BOX, m.marioObj.header.gfx.cameraToObject)
    end

    -- prevent water heal
    if m.health >= 0x100 then
        if m.healCounter == 0 and m.hurtCounter == 0 then
            if ((m.action & ACT_FLAG_SWIMMING ~= 0) and (m.action & ACT_FLAG_INTANGIBLE == 0)) then
                if ((m.pos.y >= (m.waterLevel - 140)) and not (m.area.terrainType & TERRAIN_SNOW ~= 0)) then
                    m.health = m.health - 0x1A
                end
            end
        end
    end

    e.prevHurtCounter = m.hurtCounter
end

local function mario_update(m)
    local e  = gMarioStateExtras[m.playerIndex]
    local s  = gPlayerSyncTable[m.playerIndex]
    local np = gNetworkPlayers[m.playerIndex]
    if not np.connected then return end

    -- increase knockback animations
    local animInfo = nil
    if m.marioObj ~= nil then
        animInfo = m.marioObj.header.gfx.animInfo
    end
    for i, value in ipairs(sKnockbackActions) do
        if m.action == value then
            local frame = animInfo.animFrame
            local loopEnd = frame
            if animInfo.curAnim ~= nil then
                loopEnd = animInfo.curAnim.loopEnd
            end

            if frame < loopEnd - 2 then
                frame = frame + 1
            end

            animInfo.animFrame = frame
        end
    end

    -- set invincibilites
    if m.invincTimer > gGlobalSyncTable.maxInvincTimer then m.invincTimer = gGlobalSyncTable.maxInvincTimer end
    if m.knockbackTimer > 5 then
        m.knockbackTimer = 5
    end

    -- update the local player
    if m.playerIndex == 0 then
        mario_local_update(m)
    end

    -- update palette
    if s.team == TEAM_RED then
        network_player_set_override_palette_color(np, PANTS, { r = 36, g = 25, b = 25 })
        network_player_set_override_palette_color(np, SHIRT, { r = 129, g = 0, b = 0 })
        network_player_set_override_palette_color(np, GLOVES, { r = 36, g = 25, b = 25 })
        network_player_set_override_palette_color(np, SHOES, { r = 129, g = 0, b = 0 })
        network_player_set_override_palette_color(np, HAIR, network_player_get_palette_color(np, HAIR))
        network_player_set_override_palette_color(np, SKIN, network_player_get_palette_color(np, SKIN))
        network_player_set_override_palette_color(np, CAP, { r = 129, g = 0, b = 0 })
        network_player_set_override_palette_color(np, EMBLEM, { r = 129, g = 0, b = 0 })
    elseif s.team == TEAM_BLUE then
        network_player_set_override_palette_color(np, PANTS, { r = 191, g = 222, b = 255 })
        network_player_set_override_palette_color(np, SHIRT, { r = 0, g = 96, b = 255 })
        network_player_set_override_palette_color(np, GLOVES, { r = 191, g = 222, b = 255 })
        network_player_set_override_palette_color(np, SHOES, { r = 0, g = 96, b = 255 })
        network_player_set_override_palette_color(np, HAIR, network_player_get_palette_color(np, HAIR))
        network_player_set_override_palette_color(np, SKIN, network_player_get_palette_color(np, SKIN))
        network_player_set_override_palette_color(np, CAP, { r = 0, g = 96, b = 255 })
        network_player_set_override_palette_color(np, EMBLEM, { r = 0, g = 96, b = 255 })
    elseif s.team == TEAM_GREEN then
        network_player_set_override_palette_color(np, PANTS, { r = 37, g = 176, b = 104 })
        network_player_set_override_palette_color(np, SHIRT, { r = 60, g = 77, b = 66 })
        network_player_set_override_palette_color(np, GLOVES, { r = 37, g = 176, b = 104 })
        network_player_set_override_palette_color(np, SHOES, { r = 60, g = 77, b = 66 })
        network_player_set_override_palette_color(np, HAIR, network_player_get_palette_color(np, HAIR))
        network_player_set_override_palette_color(np, SKIN, network_player_get_palette_color(np, SKIN))
        network_player_set_override_palette_color(np, CAP, { r = 60, g = 77, b = 66 })
        network_player_set_override_palette_color(np, EMBLEM, { r = 60, g = 77, b = 66 })
    elseif s.team == TEAM_YELLOW then
        network_player_set_override_palette_color(np, PANTS, { r = 247, g = 173, b = 5 })
        network_player_set_override_palette_color(np, SHIRT, { r = 252, g = 211, b = 119 })
        network_player_set_override_palette_color(np, GLOVES, { r = 247, g = 173, b = 5 })
        network_player_set_override_palette_color(np, SHOES, { r = 252, g = 211, b = 119 })
        network_player_set_override_palette_color(np, HAIR, network_player_get_palette_color(np, HAIR))
        network_player_set_override_palette_color(np, SKIN, network_player_get_palette_color(np, SKIN))
        network_player_set_override_palette_color(np, CAP, { r = 252, g = 211, b = 119 })
        network_player_set_override_palette_color(np, EMBLEM, { r = 252, g = 211, b = 119 })
    else
        network_player_reset_override_palette(np)
    end

    -- set metal
    if s.metal then
        m.marioBodyState.modelState = MODEL_STATE_METAL
    end

    -- set spectator transparency
    if s.team == TEAM_SPECTATOR then
        m.marioBodyState.modelState = MODEL_STATE_NOISE_ALPHA
    end

    -- allow yaw change on springing
    if e.springing == 1 then
        m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x400, 0x400)
    end

    -- update level timer
    if e.levelTimerLevel ~= np.currLevelNum then
        e.levelTimer = 0
        e.levelTimerLevel = np.currLevelNum
    else
        e.levelTimer = e.levelTimer + 1
    end
end

function player_reset_sync_table(m)
    local s  = gPlayerSyncTable[m.playerIndex]
    s.item     = ITEM_NONE
    s.ammo     = 0
    s.kills    = 0
    s.deaths   = 0
    s.score    = 0
    s.charging = 0
    s.metal    = false
    s.rank     = 0
    s.team     = pick_team_on_join(m)
    s.vote     = 0
    s.rtv      = false
end

function player_respawn(m)
    local np = gNetworkPlayers[m.playerIndex]
    local e  = gMarioStateExtras[m.playerIndex]
    local s  = gPlayerSyncTable[m.playerIndex]

    -- reset most variables
    init_single_mario(m)

    -- spawn location/angle
    spawn = find_spawn_point()
    if spawn ~= nil then
        m.pos.x = spawn.pos.x
        m.pos.y = spawn.pos.y
        m.pos.z = spawn.pos.z
        m.faceAngle.y = spawn.yaw
    else
        m.pos.x = 0
        m.pos.y = 0
        m.pos.z = 0
    end

    -- reset the rest of the variables
    m.capTimer = 0
    m.health = 0x880
    if m.area then soft_reset_camera(m.area.camera) end
    s.ammo = 0
    s.item = ITEM_NONE
    e.lastDamagedByGlobal = np.globalIndex
    stop_cap_music()
end

function on_death(m)
    if m.playerIndex ~= 0 then return end
    local np = gNetworkPlayers[m.playerIndex]
    local e = gMarioStateExtras[m.playerIndex]
    local s = gPlayerSyncTable[m.playerIndex]

    -- inform of death
    send_arena_death(np.globalIndex, e.lastDamagedByGlobal)

    -- respawn
    player_respawn(m)
    return false
end

function on_player_connected(m)
    local np = gNetworkPlayers[m.playerIndex]
    local e = gMarioStateExtras[m.playerIndex]
    local s = gPlayerSyncTable[m.playerIndex]
    if network_is_server() then
        player_reset_sync_table(m)
    end
    if m.playerIndex == 0 then
        e.lastDamagedByGlobal = np.globalIndex
    end
end

function on_player_disconnected(m)
    local s = gPlayerSyncTable[m.playerIndex]
    if network_is_server() then
        player_reset_sync_table(m)
    end
end

function before_phys_step(m)
    local hScale = 1.0

    if is_holding_flag(m) and m.action ~= ACT_SHOT_FROM_CANNON then
        hScale = 0.9
    end

    m.vel.x = m.vel.x * hScale
    m.vel.z = m.vel.z * hScale
end

hook_event(HOOK_ALLOW_PVP_ATTACK, allow_pvp_attack)
hook_event(HOOK_ON_PVP_ATTACK, on_pvp_attack)
hook_event(HOOK_ALLOW_INTERACT, allow_interact)
hook_event(HOOK_ON_INTERACT, on_interact)
hook_event(HOOK_ON_SET_MARIO_ACTION, on_set_mario_action)
hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_DEATH, on_death)
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected)
hook_event(HOOK_ON_PLAYER_DISCONNECTED, on_player_disconnected)
hook_event(HOOK_BEFORE_PHYS_STEP, before_phys_step)
