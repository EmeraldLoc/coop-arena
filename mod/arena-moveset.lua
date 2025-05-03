local gStateExtras = {}
for i = 0, MAX_PLAYERS - 1 do
    gStateExtras[i] = {}
    local e = gStateExtras[i]
    e.tech = 0

    e.jumpLeniency = 0 -- Jump Leniency timer
    e.lncyWallkick = 0 -- Controls Wall Kicking being as lenient as Jump Leniency
end

----------------
-- Teching v2 --
----------------

local TECH_KB = {
    [ACT_GROUND_BONK]             = ACT_BACKWARD_ROLLOUT,
    [ACT_BACKWARD_GROUND_KB]      = ACT_BACKWARD_ROLLOUT,
    [ACT_HARD_BACKWARD_GROUND_KB] = ACT_BACKWARD_ROLLOUT,
    [ACT_HARD_FORWARD_GROUND_KB]  = ACT_FORWARD_ROLLOUT,
    [ACT_FORWARD_GROUND_KB]       = ACT_FORWARD_ROLLOUT
}

local function mario_on_set_action(m)
    if TECH_KB[m.action] then
        gStateExtras[m.playerIndex].tech = 0
    end
end
hook_event(HOOK_ON_SET_MARIO_ACTION, mario_on_set_action)

local function mario_update(m)
    if not active_player(m) then return end

    if TECH_KB[m.action] then
        local e = gStateExtras[m.playerIndex]
        e.tech = e.tech + 1
        if e.tech < 10 and (m.input & INPUT_Z_PRESSED) ~= 0 then
            m.vel.y = 21.0
            m.particleFlags = m.particleFlags | ACTIVE_PARTICLE_SPARKLES
            e.tech = 0
            return set_mario_action(m, TECH_KB[m.action], 1)
        end
    end
end
hook_event(HOOK_MARIO_UPDATE, mario_update)

---------------------------------------------
-- Jump and Crouch Leniency by SMS Alfredo --
---------------------------------------------

gGlobalSyncTable.jumpLeniency = 5

--Actions you're allowed leniency out of
LNCY_AIR_ACTIONS = {
    [ACT_BACKFLIP_LAND] = 1,
    [ACT_BACKFLIP_LAND_STOP] = 1,
    [ACT_BEGIN_SLIDING] = 1,
    [ACT_BRAKING] = 1,
    [ACT_BRAKING_STOP] = 1,
    [ACT_BURNING_FALL] = 1,
    [ACT_BURNING_GROUND] = 1,
    [ACT_BUTT_SLIDE] = 1,
    [ACT_BUTT_SLIDE_AIR] = 1,
    [ACT_BUTT_SLIDE_STOP] = 1,
    [ACT_COUGHING] = 1,
    [ACT_CRAWLING] = 1,
    [ACT_CROUCHING] = 1,
    [ACT_CROUCH_SLIDE] = 1,
    [ACT_DECELERATING] = 1,
    [ACT_DIVE_SLIDE] = 1,
    [ACT_DOUBLE_JUMP_LAND] = 1,
    [ACT_DOUBLE_JUMP_LAND_STOP] = 1,
    [ACT_FINISH_TURNING_AROUND] = 1,
    [ACT_FREEFALL] = 1,
    [ACT_FREEFALL_LAND] = 1,
    [ACT_FREEFALL_LAND_STOP] = 1,
    [ACT_HOLD_BUTT_SLIDE] = 1,
    [ACT_HOLD_BUTT_SLIDE_AIR] = 1,
    [ACT_HOLD_BUTT_SLIDE_STOP] = 1,
    [ACT_HOLD_DECELERATING] = 1,
    [ACT_HOLD_FREEFALL] = 1,
    [ACT_HOLD_FREEFALL_LAND] = 1,
    [ACT_HOLD_FREEFALL_LAND_STOP] = 1,
    [ACT_HOLD_HEAVY_IDLE] = 1,
    [ACT_HOLD_HEAVY_WALKING] = 1,
    [ACT_HOLD_JUMP_LAND] = 1,
    [ACT_HOLD_JUMP_LAND_STOP] = 1,
    [ACT_HOLD_METAL_WATER_FALLING] = 1,
    [ACT_HOLD_METAL_WATER_FALL_LAND] = 1,
    [ACT_HOLD_METAL_WATER_JUMP_LAND] = 1,
    [ACT_HOLD_METAL_WATER_STANDING] = 1,
    [ACT_HOLD_METAL_WATER_WALKING] = 1,
    [ACT_HOLD_QUICKSAND_JUMP_LAND] = 1,
    [ACT_HOLD_STOMACH_SLIDE] = 1,
    [ACT_HOLD_WALKING] = 1,
    [ACT_IDLE] = 1,
    [ACT_IN_QUICKSAND] = 1,
    [ACT_JUMP_LAND] = 1,
    [ACT_JUMP_LAND_STOP] = 1,
    [ACT_LAVA_BOOST_LAND] = 1,
    [ACT_LONG_JUMP_LAND] = 1,
    [ACT_LONG_JUMP_LAND_STOP] = 1,
    [ACT_METAL_WATER_FALLING] = 1,
    [ACT_METAL_WATER_FALL_LAND] = 1,
    [ACT_METAL_WATER_JUMP_LAND] = 1,
    [ACT_METAL_WATER_STANDING] = 1,
    [ACT_METAL_WATER_WALKING] = 1,
    [ACT_MOVE_PUNCHING] = 1,
    [ACT_PUNCHING] = 1,
    [ACT_SIDE_FLIP_LAND] = 1,
    [ACT_SIDE_FLIP_LAND_STOP] = 1,
    [ACT_SLIDE_KICK_SLIDE] = 1,
    [ACT_SLIDE_KICK_SLIDE_STOP] = 1,
    [ACT_STANDING_AGAINST_WALL] = 1,
    [ACT_START_CRAWLING] = 1,
    [ACT_START_CROUCHING] = 1,
    [ACT_STOMACH_SLIDE] = 1,
    [ACT_STOMACH_SLIDE_STOP] = 1,
    [ACT_STOP_CRAWLING] = 1,
    [ACT_STOP_CROUCHING] = 1,
    [ACT_TRIPLE_JUMP_LAND] = 1,
    [ACT_TRIPLE_JUMP_LAND_STOP] = 1,
    [ACT_TURNING_AROUND] = 1,
    [ACT_WALKING] = 1
}

--Special jump actions for certain actions
LNCY_TRANS = {
    [ACT_JUMP_LAND] = ACT_DOUBLE_JUMP,
    [ACT_JUMP_LAND_STOP] = ACT_DOUBLE_JUMP,

    [ACT_DOUBLE_JUMP_LAND] = ACT_TRIPLE_JUMP,
    [ACT_DOUBLE_JUMP_LAND_STOP] = ACT_TRIPLE_JUMP,

    [ACT_FINISH_TURNING_AROUND] = ACT_SIDE_FLIP,
    [ACT_TURNING_AROUND] = ACT_SIDE_FLIP,

    [ACT_DIVE] = ACT_FORWARD_ROLLOUT,
    [ACT_DIVE_SLIDE] = ACT_FORWARD_ROLLOUT,

    [ACT_SLIDE_KICK] = ACT_FORWARD_ROLLOUT,
    [ACT_SLIDE_KICK_SLIDE] = ACT_FORWARD_ROLLOUT,
    [ACT_SLIDE_KICK_SLIDE_STOP] = ACT_FORWARD_ROLLOUT,

    [ACT_STOMACH_SLIDE] = ACT_FORWARD_ROLLOUT,
    [ACT_STOMACH_SLIDE_STOP] = ACT_FORWARD_ROLLOUT,

    [ACT_DIVE_PICKING_UP] = ACT_HOLD_JUMP,
    [ACT_HOLD_BUTT_SLIDE] = ACT_HOLD_JUMP,
    [ACT_HOLD_BUTT_SLIDE_AIR] = ACT_HOLD_JUMP,
    [ACT_HOLD_BUTT_SLIDE_STOP] = ACT_HOLD_JUMP,
    [ACT_HOLD_DECELERATING] = ACT_HOLD_JUMP,
    [ACT_HOLD_FREEFALL] = ACT_HOLD_JUMP,
    [ACT_HOLD_FREEFALL_LAND] = ACT_HOLD_JUMP,
    [ACT_HOLD_FREEFALL_LAND_STOP] = ACT_HOLD_JUMP,
    [ACT_HOLD_HEAVY_IDLE] = ACT_HOLD_JUMP,
    [ACT_HOLD_HEAVY_WALKING] = ACT_HOLD_JUMP,
    [ACT_HOLD_JUMP_LAND] = ACT_HOLD_JUMP,
    [ACT_HOLD_JUMP_LAND_STOP] = ACT_HOLD_JUMP,

    [ACT_HOLD_METAL_WATER_FALLING] = ACT_HOLD_METAL_WATER_JUMP,
    [ACT_HOLD_METAL_WATER_FALL_LAND] = ACT_HOLD_METAL_WATER_JUMP,
    [ACT_HOLD_METAL_WATER_JUMP_LAND] = ACT_HOLD_METAL_WATER_JUMP,
    [ACT_HOLD_METAL_WATER_STANDING] = ACT_HOLD_METAL_WATER_JUMP,
    [ACT_HOLD_METAL_WATER_WALKING] = ACT_HOLD_METAL_WATER_JUMP,

    [ACT_METAL_WATER_FALLING] = ACT_METAL_WATER_JUMP,
    [ACT_METAL_WATER_FALL_LAND] = ACT_METAL_WATER_JUMP,
    [ACT_METAL_WATER_JUMP_LAND] = ACT_METAL_WATER_JUMP,
    [ACT_METAL_WATER_STANDING] = ACT_METAL_WATER_JUMP,
    [ACT_METAL_WATER_WALKING] = ACT_METAL_WATER_JUMP
}

--Main function
--- @param m MarioState
function jump_leniency(m)
    if not active_player(m) then return end
    local e = gStateExtras[m.playerIndex]

    --Air Jump Leniency (pressing A late after having fallen off a ledge)
    if gGlobalSyncTable.jumpLeniency > 0
    and (m.action & ACT_FLAG_AIR) ~= 0
    and LNCY_AIR_ACTIONS[m.prevAction]
    and LNCY_AIR_ACTIONS[m.action] then
        e.jumpLeniency = e.jumpLeniency + 1

        if e.jumpLeniency <= gGlobalSyncTable.jumpLeniency
        and (m.controller.buttonPressed & A_BUTTON) ~= 0 then
            m.flags = m.flags | MARIO_ACTION_SOUND_PLAYED

            local trans = LNCY_TRANS[m.prevAction]
            if trans == ACT_TRIPLE_JUMP then
                set_triple_jump_action(m, trans, 0)
            elseif trans then
                set_mario_action(m, trans, 0)
            elseif (m.input & INPUT_Z_DOWN) ~= 0
            and (m.forwardVel > 10.0) then
                set_mario_action(m, ACT_LONG_JUMP, 0)
            else
                set_mario_action(m, ACT_JUMP, 0)
            end
        end
    else
        e.jumpLeniency = 0
    end

    --Make wall kick timing also match the Jump Leniency
    if e.lncyWallkick ~= m.wallKickTimer then
        if e.lncyWallkick == 0 then
            m.wallKickTimer = math.max(m.wallKickTimer, gGlobalSyncTable.jumpLeniency)
        end
        e.lncyWallkick = m.wallKickTimer
    end
end
hook_event(HOOK_BEFORE_MARIO_UPDATE, jump_leniency)

--Crouching

--Actions you're allowed leniency out of
--LNCY_CROUCH allows for crouch leniency
LNCY_GROUND = 1
LNCY_CROUCH = 2

LNCY_GROUND_ACTIONS = {
    [ACT_BACKFLIP_LAND] = LNCY_GROUND,
    [ACT_BACKFLIP_LAND_STOP] = LNCY_GROUND,
    [ACT_BRAKING] = LNCY_CROUCH,
    [ACT_COUGHING] = LNCY_CROUCH,
    [ACT_CROUCHING] = LNCY_GROUND,
    [ACT_DECELERATING] = LNCY_CROUCH,
    [ACT_DOUBLE_JUMP_LAND] = LNCY_GROUND,
    [ACT_DOUBLE_JUMP_LAND_STOP] = LNCY_GROUND,
    [ACT_FINISH_TURNING_AROUND] = LNCY_GROUND,
    [ACT_FREEFALL_LAND] = LNCY_GROUND,
    [ACT_FREEFALL_LAND_STOP] = LNCY_GROUND,
    [ACT_HOLD_DECELERATING] = LNCY_CROUCH,
    [ACT_HOLD_FREEFALL_LAND] = LNCY_GROUND,
    [ACT_HOLD_FREEFALL_LAND_STOP] = LNCY_GROUND,
    [ACT_JUMP_LAND] = LNCY_GROUND,
    [ACT_JUMP_LAND_STOP] = LNCY_GROUND,
    [ACT_LONG_JUMP_LAND] = LNCY_GROUND,
    [ACT_LONG_JUMP_LAND_STOP] = LNCY_GROUND,
    [ACT_PUNCHING] = LNCY_GROUND,
    [ACT_SIDE_FLIP_LAND] = LNCY_GROUND,
    [ACT_SIDE_FLIP_LAND_STOP] = LNCY_GROUND,
    [ACT_STANDING_AGAINST_WALL] = LNCY_CROUCH,
    [ACT_START_CROUCHING] = LNCY_GROUND,
    [ACT_STOP_CROUCHING] = LNCY_GROUND,
    [ACT_TRIPLE_JUMP_LAND] = LNCY_GROUND,
    [ACT_TRIPLE_JUMP_LAND_STOP] = LNCY_GROUND,
    [ACT_TURNING_AROUND] = LNCY_CROUCH,
    [ACT_WALKING] = LNCY_CROUCH
}

--Main function
--- @param m MarioState
function crouch_leniency(m)
    --Ground Jump Leniency (pressing Z and A/B together)
    if (m.action & ACT_FLAG_AIR) == 0
    and (LNCY_GROUND_ACTIONS[m.action] or 0) >= LNCY_GROUND
    and (m.controller.buttonDown & Z_TRIG) ~= 0 then
        if (m.controller.buttonPressed & (A_BUTTON | B_BUTTON)) ~= 0 then
            --Standing actions
            if (m.action & ACT_FLAG_STATIONARY) ~= 0 then
                if (m.controller.buttonPressed & A_BUTTON) ~= 0 then
                    set_jumping_action(m, ACT_BACKFLIP, 0)
                elseif m.action == ACT_CROUCHING then
                    set_mario_action(m, ACT_PUNCHING, 9)
                end
            --Moving actions
            elseif m.forwardVel > 10.0 then
                if (m.controller.buttonPressed & A_BUTTON) ~= 0 then
                    set_jumping_action(m, ACT_LONG_JUMP, 0)
                else
                    set_mario_action(m, ACT_SLIDE_KICK, 0)
                end
            end

        --Crouch Leniency (hold Z to crouch instead of needing to press it)
        elseif LNCY_GROUND_ACTIONS[m.action] >= LNCY_CROUCH then
            set_mario_action(m, (m.action & ACT_FLAG_STATIONARY) == 0 and ACT_CROUCH_SLIDE or ACT_START_CROUCHING, 0)
        end
    end
end
hook_event(HOOK_BEFORE_MARIO_UPDATE, crouch_leniency)