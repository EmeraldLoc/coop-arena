function mario_hammer_is_attack(m)
    if m.action == ACT_PUNCHING      then return true end
    if m.action == ACT_MOVE_PUNCHING then return true end
    if m.action == ACT_JUMP_KICK     then return true end
    if m.action == ACT_DIVE          then return true end
    if m.action == ACT_GROUND_POUND  then return true end
    return false
end

local function mario_hammer_position(m)
    local held = gItemHeld[m.playerIndex]
    if held == nil then
        return { x = m.pos.x, y = m.pos.y, z = m.pos.z }
    end

    local origin = { x = held.oPosX, y = held.oPosY, z = held.oPosZ }
    return set_dist_and_angle(origin, 100, 0x4000 + -held.oFaceAnglePitch, held.oFaceAngleYaw)
end

local function mario_hammer_pound(m)
    local v = {
        x = m.pos.x + sins(m.faceAngle.y) * 200,
        y = m.pos.y,
        z = m.pos.z + coss(m.faceAngle.y) * 200,
    }
    spawn_horizontal_stars(v.x, v.y, v.z)
    play_mario_heavy_landing_sound(m, SOUND_ACTION_TERRAIN_HEAVY_LANDING)
    cur_obj_shake_screen(SHAKE_POS_MEDIUM)
end

function mario_hammer_on_set_action(m)
    if m.action == ACT_PUNCHING or m.action == ACT_MOVE_PUNCHING or m.action == ACT_JUMP_KICK then
        play_sound(SOUND_ACTION_TWIRL, m.marioObj.header.gfx.cameraToObject)
    elseif m.action == ACT_DIVE_SLIDE or m.action == ACT_GROUND_POUND_LAND then
        mario_hammer_pound(m)
    end
end

---@param m MarioState
function mario_hammer_update(m)
    local e = gMarioStateExtras[m.playerIndex]
    local s = gPlayerSyncTable[m.playerIndex]
    if s.item ~= ITEM_HAMMER then return end

    -- override dive animation
    if m.action == ACT_DIVE then
        set_character_animation(m, CHAR_ANIM_FORWARD_SPINNING)

        e.rotFrames = e.rotFrames + 1
        if (e.rotFrames) % 7 == 0 then
            play_sound(SOUND_ACTION_TWIRL, m.marioObj.header.gfx.cameraToObject)
        end

        e.rotAngle = e.rotAngle + (0x80 * 60)
        if e.rotAngle > 0x10000 then
            e.rotAngle = e.rotAngle - 0x10000
        end
        set_anim_to_frame(m, 10 * e.rotAngle / 0x10000)
    elseif m.action == ACT_PUNCHING or m.action == ACT_MOVE_PUNCHING then
        local animFrame = m.marioObj.header.gfx.animInfo.animFrame
        if animFrame == -1 and m.actionArg > 1 then
            mario_hammer_pound(m)
        end
        if m.actionArg > 2 then m.actionArg = 0 end
    end
end

function mario_local_hammer_check(m)
    if m.playerIndex ~= 0 then return end
    local np = gNetworkPlayers[m.playerIndex]
    local e = gMarioStateExtras[m.playerIndex]
    local savedKb = m.knockbackTimer
    m.knockbackTimer = 0

    -- check for hammer attacks
    for i = 1, (MAX_PLAYERS - 1) do
        local mattacker  = gMarioStates[i]
        local npattacker = gNetworkPlayers[i]
        local sattacker  = gPlayerSyncTable[i]
        local cmvictim = lag_compensation_get_local_state(npattacker)

        if sattacker.item == ITEM_HAMMER and mario_hammer_is_attack(mattacker) and passes_pvp_interaction_checks(mattacker, cmvictim) ~= 0 and passes_pvp_interaction_checks(mattacker, m) ~= 0 and global_index_hurts_mario_state(npattacker.globalIndex, m) then
            local pos = mario_hammer_position(mattacker)
            local dist = vec3f_dist(pos, cmvictim.pos)
            if dist <= 200 then
                local yOffset = 0.6
                if mattacker.action == ACT_JUMP_KICK then
                    yOffset = 1.0
                end

                local vel = {
                    x = sins(mattacker.faceAngle.y),
                    y = yOffset,
                    z = coss(mattacker.faceAngle.y),
                }
                vec3f_normalize(vel)
                vec3f_mul(vel, 80 + 10 * (1 - mario_health_float(cmvictim)))

                set_mario_action(m, ACT_BACKWARD_AIR_KB, 0)
                m.invincTimer = 20
                m.knockbackTimer = 10
                m.vel.x = vel.x
                m.vel.y = vel.y
                m.vel.z = vel.z
                m.faceAngle.y = atan2s(vel.z, vel.x) + 0x8000
                m.forwardVel = 0
                sattacker.ammo = sattacker.ammo - 1

                send_arena_hammer_hit(np.globalIndex, npattacker.globalIndex)
                e.lastDamagedByGlobal = npattacker.globalIndex

                if mattacker.action == ACT_JUMP_KICK or mattacker.action == ACT_DIVE then
                    m.hurtCounter = 10
                else
                    m.hurtCounter = 15
                end
            end
        end
    end

    if savedKb > m.knockbackTimer then
        m.knockbackTimer = savedKb
    end
end
