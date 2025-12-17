local lightDir = {
    ["Rainbow"] = -10,
    ["City"] = -1,
    ["Citadel"] = -10,
    ["Forts"] = -10,
    ["Origin"] = -10,
    ["Pillars"] = -10
}

local function on_level_init()
    set_lighting_dir(1, lightDir[gGameLevels[get_current_level_key()].name] or 0)
end
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)

local lightColor = {
    ["City"] = {
        lightR = 255, shadeR = 19,
        lightG = 225, shadeG = 58,
        lightB = 115, shadeB = 212
    },
    ["Rainbow"] = {
        lightR = 255, shadeR = 19,
        lightG = 255, shadeG = 58,
        lightB = 255, shadeB = 212
    }
}
local defLight = {
    lightR = 255, shadeR = 127,
    lightG = 255, shadeG = 127,
    lightB = 255, shadeB = 127
}

local curLight
--- @param m MarioState
local function mario_update(m)
    local l = lightColor[gGameLevels[get_current_level_key()].name] or defLight
    if curLight ~= l then
        curLight = l
        for field, val in pairs(l) do
            m.marioBodyState[field] = val
        end
    end
end
hook_event(HOOK_MARIO_UPDATE, mario_update)