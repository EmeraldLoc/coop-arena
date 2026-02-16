ACT_ARENA_KB_LANDING = allocate_mario_action(ACT_GROUP_AUTOMATIC)
ACT_ARENA_ROLL = allocate_mario_action(ACT_GROUP_MOVING)
ACT_ARENA_AIR_TECH = allocate_mario_action(ACT_GROUP_AIRBORNE)
local ROLL_FRAMES = 20

---@param m MarioState
local function act_arena_kb_landing(m)
    if not m then return end
    local anim = CHAR_ANIM_SOFT_BACK_KB
    if m.forwardVel > 0 then
        anim = CHAR_ANIM_SOFT_FRONT_KB
    end

    if landing_step(m, anim, ACT_IDLE) < 3 then
        if m.input & INPUT_Z_DOWN ~= 0 then
            return set_mario_action(m, ACT_ARENA_ROLL, 0)
        end
    end
end

---@param m MarioState
local function act_arena_roll(m)
    if not m then return end
    if m.actionState == 0 then
        m.faceAngle.y = m.intendedYaw
        m.actionState = m.actionState + 1
        m.forwardVel = 80
    end

    m.forwardVel = math.lerp(m.forwardVel, 0, 0.1)
    m.vel.x = m.forwardVel*sins(m.faceAngle.y)
    m.vel.z = m.forwardVel*coss(m.faceAngle.y)
    perform_ground_step(m)
    set_character_animation(m, CHAR_ANIM_SLIDEFLIP)

    if m.actionTimer > ROLL_FRAMES then
        return set_mario_action(m, ACT_IDLE, 0)
    end

    m.actionTimer = m.actionTimer + 1
end

hook_mario_action(ACT_ARENA_KB_LANDING, act_arena_kb_landing)
hook_mario_action(ACT_ARENA_ROLL, act_arena_roll)

local function before_mario_action(m, nextAct)
    if nextAct & ACT_FLAG_INVULNERABLE ~= 0 and nextAct & ACT_FLAG_AIR == 0 then
        return set_mario_action(m, ACT_ARENA_KB_LANDING, 0)
    end
end

hook_event(HOOK_BEFORE_SET_MARIO_ACTION, before_mario_action)