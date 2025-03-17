
local TEXTURE_CHECKMARK = get_texture_info("checkmark")
local TEXTURE_NO_CHECKMARK = get_texture_info("no_checkmark")

local INPUT_A = 0
local INPUT_JOYSTICK = 1

local PERMISSION_ALL = 0
local PERMISSION_SERVER = 1
local PERMISSION_MODERATORS = 3

local joystickCooldown = 0
local joystickCombo = 0

local entries = {}
local mainEntries = {}
local setGamemodeEntries = {}
local setLevelEntries = {}
local gamemodeSettingEntries = {}

local selection = 1

local function has_permission(perm)
    return perm == PERMISSION_ALL
        or perm == PERMISSION_SERVER and network_is_server()
        or perm == PERMISSION_MODERATORS and (network_is_server() or network_is_moderator())
end

local function set_setting_entries(newEntries)
    entries = newEntries == mainEntries and newEntries or table.copy(newEntries)
    if entries ~= mainEntries then
        entries[#entries + 1] = {
            name = 'Back',
            input = INPUT_A,
            permission = PERMISSION_ALL,
            action = function ()
                set_setting_entries(mainEntries)
            end
        }
    end
    selection = 1
end

function toggle_arena_settings()
    if #entries == 0 then
        set_setting_entries(mainEntries)
    else
        entries = {}
    end
end

local function update()
    -- always update the level entries, as this can be controlled by other mods, and levels can be added at any time
    -- also avoids a race condition
    setLevelEntries = {}
    for _, level in ipairs(gGameLevels) do
        setLevelEntries[#setLevelEntries + 1] = {
            name = level.name,
            input = INPUT_A,
            permission = PERMISSION_MODERATORS,
            action = function ()
                gGlobalSyncTable.currentLevel = level.level
                round_end(false)
                sWaitTimer = 1
                sRoundCount = 0
            end
        }
    end
end

local function on_mods_loaded()
    mainEntries = {
        {
            name = 'Set Gamemode',
            input = INPUT_A,
            permission = PERMISSION_MODERATORS,
            action = function ()
                set_setting_entries(setGamemodeEntries)
            end
        },
        {
            name = 'Set Level',
            input = INPUT_A,
            permission = PERMISSION_MODERATORS,
            action = function ()
                set_setting_entries(setLevelEntries)
            end
        },
        {
            name = 'Gamemode Settings',
            input = INPUT_A,
            permission = PERMISSION_SERVER,
            action = function ()
                set_setting_entries(gamemodeSettingEntries)
            end
        },
        {
            name = 'Max I-Frames',
            input = INPUT_JOYSTICK,
            permission = PERMISSION_MODERATORS,
            action = function (direction, strength)
                gGlobalSyncTable.maxInvincTimer = clamp(gGlobalSyncTable.maxInvincTimer + (strength * direction), 0, 30)
            end,
            update = function (entry)
                entry.value = gGlobalSyncTable.maxInvincTimer == 30 and "Default" or gGlobalSyncTable.maxInvincTimer == 0 and "None" or tostring(gGlobalSyncTable.maxInvincTimer)
            end,
            value = gGlobalSyncTable.maxInvincTimer
        },
        {
            name = 'Spectating',
            input = INPUT_A,
            permission = PERMISSION_ALL,
            toggleValue = gPlayerSyncTable[0].team == TEAM_SPECTATOR,
            action = function ()
                if gPlayerSyncTable[0].team == TEAM_SPECTATOR then
                    player_reset_sync_table(gMarioStates[0])
                else
                    gPlayerSyncTable[0].team = TEAM_SPECTATOR
                    gPlayerSyncTable[0].item = ITEM_NONE
                end
            end,
            update = function (entry)
                entry.toggleValue = gPlayerSyncTable[0].team == TEAM_SPECTATOR
            end,
        }
    }

    setGamemodeEntries[#setGamemodeEntries + 1] = {
        name = "Random",
        input = INPUT_A,
        permission = PERMISSION_MODERATORS,
        toggleValue = sRandomizeMode,
        action = function ()
            sRandomizeMode = true
            round_end(false)
            sWaitTimer = 1
            sRoundCount = 0
        end,
        update = function (entry)
            entry.toggleValue = sRandomizeMode
        end
    }

    for key, gamemode in ipairs(gGameModes) do
        setGamemodeEntries[#setGamemodeEntries + 1] = {
            name = gamemode.name,
            input = INPUT_A,
            permission = PERMISSION_MODERATORS,
            toggleValue = gGlobalSyncTable.gameMode == key and not sRandomizeMode,
            action = function ()
                if table.contains(gGameLevels[get_current_level_key()].compatibleGamemodes, key) then
                    gGlobalSyncTable.gameMode = key
                    sRandomizeMode = false
                    round_end(false)
                    sWaitTimer = 1
                    sRoundCount = 0
                end
            end,
            update = function (entry)
                entry.toggleValue = gGlobalSyncTable.gameMode == key and not sRandomizeMode
            end
        }
    end

    for _, level in ipairs(gGameLevels) do
        setLevelEntries[#setLevelEntries + 1] = {
            name = level.name,
            input = INPUT_A,
            permission = PERMISSION_MODERATORS,
            action = function ()
                gGlobalSyncTable.currentLevel = level.level
                round_end(false)
                sWaitTimer = 1
                sRoundCount = 0
            end
        }
    end

    for _, gamemode in ipairs(gGameModes) do
        gamemodeSettingEntries[#gamemodeSettingEntries + 1] = {
            name = gamemode.name .. " Time Limit",
            input = INPUT_JOYSTICK,
            permission = PERMISSION_SERVER,
            action = function (direction, strength)
                gamemode.time = gamemode.time + (strength * direction)
                if gamemode.time < 0 then gamemode.time = 0 end
            end,
            update = function (entry)
                entry.value = tostring(gamemode.time > 0 and seconds_to_minutes(gamemode.time) or "None")
            end,
            value = tostring(gamemode.time > 0 and seconds_to_minutes(gamemode.time) or "None")
        }
    end
end

local function on_hud_render()
    if #entries == 0 then return end

    djui_hud_set_resolution(RESOLUTION_DJUI)
    djui_hud_set_font(djui_menu_get_font())

    local screenWidth = djui_hud_get_screen_width()
    local screenHeight = djui_hud_get_screen_height()

    local width = 850
    local height = 800

    local x = (screenWidth - width) / 2
    local y = (screenHeight - height) / 2

    djui_hud_set_color(20, 20, 20, 200)
    djui_hud_render_rect(x, y, width, height)

    width = width - 50
    x = x + 25
    y = y + 25

    for i, entry in ipairs(entries) do
        if entry.update then
            entry.update(entry)
        end
        local rectColor        = i == selection and { 50,   50,   0, 255 } or {   0,   0,   0, 128 }
        local outlineRectColor = i == selection and { 255, 220,   0, 255 } or {   0,   0,   0, 128 }
        local textColor        = i == selection and { 255, 255, 255, 255 } or { 220, 220, 220, 255 }
        height = 40
        djui_hud_set_color(rectColor[1], rectColor[2], rectColor[3], rectColor[4])
        djui_hud_render_rect_outlined(x, y, width, height, outlineRectColor[1], outlineRectColor[2], outlineRectColor[3], outlineRectColor[4], 2)
        djui_hud_set_color(textColor[1], textColor[2], textColor[3], textColor[4])
        djui_hud_print_text(entry.name, x + 5, y + 3, 1)
        if entry.toggleValue ~= nil then
            local texture = entry.toggleValue and TEXTURE_CHECKMARK or TEXTURE_NO_CHECKMARK
            djui_hud_set_filter(FILTER_LINEAR)
            djui_hud_set_color(255, 255, 255, 200)
            djui_hud_render_texture(texture, x + width - 35, y + 5, (height - 10) / 32, (height - 10) / 32)
            djui_hud_set_filter(FILTER_NEAREST)
        elseif entry.value then
            djui_hud_set_color(255, 220, 0, 255)
            djui_hud_print_text(entry.value, x + width - djui_hud_measure_text(entry.value) - 5, y + 3, 1)
        end
        y = y + height + 25
    end
end

---@param m MarioState
local function mario_update(m)
    if m.playerIndex ~= 0 then return end
    if #entries == 0 then return end

    local curEntry = entries[selection]
    m.freeze = 1

    if m.controller.buttonPressed & START_BUTTON ~= 0 or gGlobalSyncTable.gameState == GAME_STATE_VOTING then
        if entries ~= mainEntries then set_setting_entries(mainEntries) else entries = {} end
        m.controller.buttonPressed = m.controller.buttonPressed & ~START_BUTTON
        return
    end

    if m.controller.buttonPressed & A_BUTTON ~= 0 and curEntry.input == INPUT_A
    and has_permission(curEntry.permission) then
        curEntry.action()
    end

    if joystickCooldown > 0 then
        if joystickCooldown == 0.2 * 30 then
            joystickCombo = joystickCombo * 2
            if joystickCombo > 200 then joystickCombo = 200 end
        end
        joystickCooldown = joystickCooldown - 1
        if m.controller.stickX == 0 and m.controller.stickY == 0 then
            joystickCooldown = 0
            joystickCombo = 1
        end
        return
    end

    if m.controller.stickY > 0.5 then
        joystickCooldown = 0.2 * 30
        selection = selection - 1
        if selection < 1 then
            selection = #entries
        end
    elseif m.controller.stickY < -0.5 then
        joystickCooldown = 0.2 * 30
        selection = selection + 1
        if selection > #entries then
            selection = 1
        end
    end

    if curEntry.input == INPUT_JOYSTICK and has_permission(curEntry.permission) then
        if m.controller.stickX > 0.5 then
            curEntry.action(1, math.max(1, math.floor(joystickCombo * 0.2)))
            joystickCooldown = 0.2 * 30
        elseif m.controller.stickX < -0.5 then
            curEntry.action(-1, math.max(1, math.floor(joystickCombo * 0.2)))
            joystickCooldown = 0.2 * 30
        end
    end
end

hook_event(HOOK_UPDATE, update)
hook_event(HOOK_ON_MODS_LOADED, on_mods_loaded)
hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_event(HOOK_MARIO_UPDATE, mario_update)