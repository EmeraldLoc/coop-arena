function active_player(m)
    local np = gNetworkPlayers[m.playerIndex]
    if m.playerIndex == 0 then return true end
    if not np.connected then return false end
    return is_player_active(m) ~= 0
end

function set_dist_and_angle(from, dist, pitch, yaw)
    return {
        x = from.x + dist * coss(pitch) * sins(yaw),
        y = from.y + dist * sins(pitch),
        z = from.z + dist * coss(pitch) * coss(yaw),
    }
end

function clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

function convert_s16(num)
    local min = -32768
    local max = 32767
    while (num < min) do
        num = max + (num - min)
    end
    while (num > max) do
        num = min + (num - max)
    end
    return num
end

function mario_health_float(m)
    return clamp((m.health - 255) / (2176 - 255), 0, 1)
end

function global_index_hurts_mario_state(globalIndex, m)
    if globalIndex == gNetworkPlayers[m.playerIndex].globalIndex then
        return false
    end

    local npAttacker = network_player_from_global_index(globalIndex)
    if npAttacker == nil then
        return false
    end
    local sAttacker = gPlayerSyncTable[npAttacker.localIndex]
    local sVictim = gPlayerSyncTable[m.playerIndex]

    if sAttacker.team == 0 or sVictim.team == 0 then
        return true
    end

    return sAttacker.team ~= sVictim.team
end

function is_invuln_or_intang(m)
    local invuln = ((m.action & ACT_FLAG_INVULNERABLE) ~= 0) or (m.invincTimer ~= 0)
    local intang = ((m.action & ACT_FLAG_INTANGIBLE) ~= 0)
    return invuln or intang
end

get_uncolored_string = get_uncolored_string and get_uncolored_string or
function (str)
    local s = ''
    local inSlash = false
    for i = 1, #str do
        local c = str:sub(i,i)
        if c == '\\' then
            inSlash = not inSlash
        elseif not inSlash then
            s = s .. c
        end
    end
    return s
end

-- TODO: Support 4 teams
function get_other_team(teamNum)
    if teamNum == 1 then
        return 2
    elseif teamNum == 2 then
        return 1
    else
        return 0
    end
end

function team_color_str(teamNum)
    if teamNum == 1 then
        return '\\#ff9999\\'
    elseif teamNum == 2 then
        return '\\#9999ff\\'
    else
        return '\\#ffffff\\'
    end
end

function team_name_str(teamNum)
    if teamNum == 1 then
        return 'red'
    elseif teamNum == 2 then
        return 'blue'
    else
        return 'white'
    end
end

function seconds_to_minutes(seconds)
    if seconds < 60 then return seconds end
    return string.format('%d:%02d', math.floor(seconds / 60), seconds % 60)
end

---@param table table
---@param element any
function table.contains(table, element)
	-- check each value in the table
    for _, value in pairs(table) do
		-- check if that value is equal to the element
      	if value == element then
			-- if so, we are good to go, and the table contains the element, return true!
        	return true
      	end
    end

	-- if we finish the loop, we didn't find the entry in the table, so return false
	return false
end

function table.copy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[table.copy(orig_key)] = table.copy(orig_value)
        end
        setmetatable(copy, table.copy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function linear_interpolation(input, minRange, maxRange, minInput, maxInput)
    local m = (maxRange - minRange) / (maxInput - minInput)
    local b = minRange - m * minInput

    return m * input + b
end

---@param x number|integer
---@param y number|integer
---@param width number|integer
---@param height number|integer
---@param oR number|integer
---@param oG number|integer
---@param oB number|integer
---@param oA number|integer
---@param thickness number|integer
function djui_hud_render_rect_outlined(x, y, width, height, oR, oG, oB, oA, thickness)
    -- render main rect
    djui_hud_render_rect(x, y, width, height)
    -- render rect outside of each side
    djui_hud_set_color(oR, oG, oB, oA)
    djui_hud_render_rect(x - thickness, y - thickness, thickness, height + thickness * 2)
    djui_hud_render_rect(x + (width - thickness) + thickness, y, thickness, height + thickness)
    djui_hud_render_rect(x, y - thickness, width + thickness, thickness)
    djui_hud_render_rect(x, y + (height - thickness) + thickness, width, thickness)
end

---@param text string
---@param x number
---@param y number
---@param scale number
function djui_hud_print_text_shaded(text, x, y, scale)
    local color = djui_hud_get_color()
    djui_hud_set_color(0, 0, 0, color.a)
    djui_hud_print_text(text, x + 2 * scale, y + 2 * scale, scale)
    djui_hud_set_color(color.r, color.g, color.b, color.a)
    djui_hud_print_text(text, x, y, scale)
end

function hex_to_rgb(hex)
	-- remove the # and the \\ from the hex so that we can convert it properly
	hex = hex:gsub('#','')
	hex = hex:gsub('\\','')

    return { r = tonumber('0x'..hex:sub(1,2)), g = tonumber('0x'..hex:sub(3,4)), b = tonumber('0x'..hex:sub(5,6)) }
end

function rgb_to_hex(r, g, b)
	return string.format("#%02X%02X%02X", r, g, b)
end

function cap_text(text, maxLength)
	local newText = ""
	local lastValidText = ""
	for i = 1, #text do
		local c = text:sub(i, i)
		newText = newText .. c
		if djui_hud_measure_text(get_uncolored_string(newText)) <= maxLength then lastValidText = newText end
	end

	return lastValidText
end

------------

function spawn_mist(obj, scale)
    local spi = obj_get_temp_spawn_particles_info(E_MODEL_MIST)
    if spi == nil then
        return nil
    end

    spi.behParam = 3
    spi.count = 5
    spi.offsetY = 25
    spi.forwardVelBase = 6 * scale
    spi.forwardVelRange = -12 * scale
    spi.velYBase = 6 * scale
    spi.velYRange = -12 * scale
    spi.gravity = 0
    spi.dragStrength = 5
    spi.sizeBase = 10 * scale
    spi.sizeRange = 16 * scale

    cur_obj_spawn_particles(spi)
end

function spawn_mist_advanced(obj, scale, type, count, offsetY)
    local spi = obj_get_temp_spawn_particles_info(E_MODEL_MIST)
    if spi == nil then
        return nil
    end

    spi.behParam = type
    spi.count = count
    spi.offsetY = offsetY
    spi.forwardVelBase = 3 * scale
    spi.forwardVelRange = -6 * scale
    spi.velYBase = 3 * scale
    spi.velYRange = -6 * scale
    spi.gravity = 0
    spi.dragStrength = 5
    spi.sizeBase = 5 * scale
    spi.sizeRange = 7 * scale

    cur_obj_spawn_particles(spi)
end

function spawn_balls(obj, scale)
    local spi = obj_get_temp_spawn_particles_info(E_MODEL_BOWLING_BALL)
    if spi == nil then
        return nil
    end

    spi.behParam = 2
    spi.count = 3
    spi.offsetY = 25
    spi.forwardVelBase = 30 * scale
    spi.forwardVelRange = -60 * scale
    spi.velYBase = 30 * scale
    spi.velYRange = -60 * scale
    spi.gravity = 0
    spi.dragStrength = 5
    spi.sizeBase = 0.5 * scale
    spi.sizeRange = 0.5 * scale

    cur_obj_spawn_particles(spi)
end

function spawn_triangles(obj)
    spawn_non_sync_object(id_bhvTriangleParticleSpawner, E_MODEL_NONE,
        obj.oPosX,
        obj.oPosY,
        obj.oPosZ,
        nil)
end

function spawn_horizontal_stars(x, y, z)
    spawn_non_sync_object(id_bhvHorStarParticleSpawner, E_MODEL_NONE,
        x,
        y,
        z,
        nil)
end

function spawn_vertical_stars(x, y, z)
    spawn_non_sync_object(id_bhvVertStarParticleSpawner, E_MODEL_NONE,
        x,
        y,
        z,
        nil)
end

function spawn_sparkles(x, y, z)
    for i = 0, 5 do
        spawn_non_sync_object(id_bhvSparkleSpawn, E_MODEL_NONE,
            x + math.random(-100, 100),
            y + math.random(-100, 100),
            z + math.random(-100, 100),
            nil)
    end
end

--------

function bhv_debug_pos_init(obj)
    obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    obj.oOpacity = 255
    obj.oTimer = 0
    obj_set_billboard(obj)
    obj_scale(obj, 0.5)
end

function bhv_debug_pos_loop(obj)
    obj.oTimer = obj.oTimer + 1
    if obj.oTimer > 1 then
        obj.activeFlags = ACTIVE_FLAG_DEACTIVATED
    end
end

id_bhvDebugPos = hook_behavior(nil, OBJ_LIST_DEFAULT, true, bhv_debug_pos_init, bhv_debug_pos_loop)

function debug_pos(x, y, z)
    spawn_non_sync_object(id_bhvDebugPos, E_MODEL_AMP, x, y, z, nil)
end

-------

function SEQUENCE_ARGS(priority, seqId)
    return ((priority << 8) | seqId)
end
