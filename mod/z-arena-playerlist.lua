
local sPlayerListScale = 0.86
local playerListWidth = 750 * sPlayerListScale
local playerListHeight = 800 * sPlayerListScale
local modListWidth = 300 * sPlayerListScale
local modListHeight = 600 * sPlayerListScale
local lipHeight = 50 * sPlayerListScale

local TOP_LEFT = 0
local TOP_RIGHT = 1
local BOTTOM_LEFT = 2
local BOTTOM_RIGHT = 3

---@param team integer
---@param width number
---@param height number
---@param alignment integer
---@param playerSlots integer
local function render_team_playerlist(players, team, width, height, alignment, listPadding, playerSlots)
    local screenWidth = djui_hud_get_screen_width()
    local screenHeight = djui_hud_get_screen_height()
    local xOffset = playerListWidth / 4
    local x = (screenWidth - width) / 2 - xOffset
    local y = (screenHeight - height + lipHeight) / 2
    if alignment == TOP_LEFT then
        x = (screenWidth - playerListWidth) / 2 - xOffset + listPadding
        y = (screenHeight - playerListHeight + lipHeight) / 2 + listPadding
    elseif alignment == TOP_RIGHT then
        x = (screenWidth + playerListWidth) / 2 - width - xOffset - listPadding
        y = (screenHeight - playerListHeight + lipHeight) / 2 + listPadding
    elseif alignment == BOTTOM_LEFT then
        x = (screenWidth - playerListWidth) / 2 - xOffset + listPadding
        y = (screenHeight + playerListHeight + lipHeight) / 2 - height - listPadding
    elseif alignment == BOTTOM_RIGHT then
        x = (screenWidth + playerListWidth) / 2 - width - xOffset - listPadding
        y = (screenHeight + playerListHeight + lipHeight) / 2 - height - listPadding
    end
    local paddingX = 20
    local paddingY = 12
    local listWidth = (width - 10)
    local listHeight = math.min((playerListHeight / network_player_connected_count()), 47) - paddingY
    local dividerXPadding = 30
    if team ~= TEAM_NONE then
        djui_hud_set_color(TEAM_COLORS[team].r, TEAM_COLORS[team].g, TEAM_COLORS[team].b, 200)
    else
        djui_hud_set_color(5, 5, 5, 200)
    end
    djui_hud_render_rect_outlined(x, y, width, height, 255, 255, 255, 255, 2)
    for i = 1, playerSlots - 1 do
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_render_rect(x + dividerXPadding / 2, y + ((listHeight + paddingY + 35) * i) - 3, listWidth - dividerXPadding, 2)
    end
    for _, v in ipairs(players) do
        local np = gNetworkPlayers[v]
        local s = gPlayerSyncTable[v]
        local rank = rank_str(s.rank)
        local originalX = x
        local originalY = y
        local cells = 4
        local curCell = 1
        local cellWidth = listWidth / cells + 1
        local killText = tostring(s.kills) .. " kills"
        local pointsText = gGameModes[gGlobalSyncTable.gameMode].useScore and tostring(s.score) .. " points" or tostring(s.deaths) .. " deaths"
        local textScale = listHeight / 35
        --[[if (djui_hud_measure_text(get_uncolored_string(np.name) .. killText .. pointsText) + 40 + paddingX) > listWidth then
            -- first order of matter is to shrink the name to at least 16 characters
            local cappedName = string.sub(get_uncolored_string(np.name), 1, 16)

            textScale = listWidth / (djui_hud_measure_text(cappedName .. killText .. pointsText) + 40 + paddingX)
            log_to_console(tostring(textScale))
        end--]]

        s.rank = v + 1

        x = originalX + cellWidth * (curCell - 1)
        y = y + 5
        y = y + 2 * textScale

        djui_hud_set_color(255, 255, 255, 255)
        if charSelect then
            charSelect.character_render_life_icon(v, x, y, 2)
        else
            local headTex = gCharacters[np.overrideModelIndex].hudHeadTexture or get_texture_info("texture_hud_char_question")
            djui_hud_render_texture(headTex, x, y, 32 / (headTex.width) * textScale, 32 / (headTex.height) * textScale)
        end

        x = x + 40

        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text_shaded(cap_text(get_uncolored_string(np.name), (listWidth - 40) / textScale), x, y, textScale)

        y = y + 35
        x = originalX + cellWidth * (curCell - 1)

        local text = s.team ~= TEAM_SPECTATOR and rank .. "  " .. killText .. "  " .. pointsText or "Spectator"

        if s.team == TEAM_SPECTATOR then
            djui_hud_set_color(128, 128, 128, 255)
        else
            djui_hud_set_color(255, rank_color_g(s.rank), 0, 255)
        end
        djui_hud_print_text_shaded(text, x + 10 * textScale, y, textScale)

        x = originalX
        y = originalY + listHeight + paddingY + 35
    end
end

local function render_playerlist()
    djui_hud_set_filter(FILTER_NEAREST)
    local screenWidth = djui_hud_get_screen_width()
    local screenHeight = djui_hud_get_screen_height()
    local title = gGameModes[gGlobalSyncTable.gameMode].name
    local width = playerListWidth
    local height = playerListHeight
    local lipWidth = math.max(width / 2 + 100, djui_hud_measure_text(title) * 2 + 50) * sPlayerListScale
    local xOffset = width / 4

    local x = (screenWidth - lipWidth) / 2 - xOffset
    local y = (screenHeight - height) / 2 - lipHeight / 2

    djui_hud_set_color(60, 60, 60, 200)
    djui_hud_render_rect(x, y - 5, lipWidth, lipHeight + 5)

    -- render outline manually to remove bottom of lip
    local thickness = 5
    djui_hud_set_color(0, 0, 0, 200)
    djui_hud_render_rect(x - thickness, y - thickness * 2, lipWidth + thickness * 2, thickness)
    djui_hud_render_rect(x - thickness, y - thickness, thickness, lipHeight)
    djui_hud_render_rect(x + lipWidth, y - thickness, thickness, lipHeight)

    x = (screenWidth - width) / 2 - xOffset
    y = (screenHeight - height + lipHeight) / 2

    djui_hud_set_color(60, 60, 60, 200)
    djui_hud_render_rect(x, y, width, height)
    djui_hud_set_color(0, 0, 0, 200)
    djui_hud_render_rect(x - thickness, y - thickness, thickness, height + thickness * 2)
    djui_hud_render_rect(x + (width - thickness) + thickness, y, thickness, height / 2 - modListHeight / 2)
    djui_hud_render_rect(x + (width - thickness) + thickness, y + height / 2 + modListHeight / 2, thickness, height / 2 - modListHeight / 2 + thickness)
    djui_hud_render_rect(x, y - thickness, width / 2 - lipWidth / 2, thickness)
    djui_hud_render_rect(x + width / 2 + lipWidth / 2, y - thickness, width / 2 - lipWidth / 2 + thickness, thickness)
    djui_hud_render_rect(x, y + (height - thickness) + thickness, width, thickness)

    x = screenWidth / 2 - xOffset - djui_hud_measure_text(title) * (2 * sPlayerListScale) / 2
    local textY = screenHeight / 2 - height / 2 - lipHeight + (20 * sPlayerListScale) / 2

    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text(title, x, textY, 2 * sPlayerListScale)

    x = (screenWidth - width) / 2 - xOffset + 5

    local listPadding = 20

    if get_amount_of_teams_in_match() == 4 then
        render_team_playerlist(get_players_in_team(TEAM_RED), TEAM_RED, width / 2 - listPadding, height / 2 - listPadding, TOP_LEFT, listPadding / 2, 4)
        render_team_playerlist(get_players_in_team(TEAM_BLUE), TEAM_BLUE, width / 2 - listPadding, height / 2 - listPadding, TOP_RIGHT, listPadding / 2, 4)
        render_team_playerlist(get_players_in_team(TEAM_GREEN), TEAM_GREEN, width / 2 - listPadding, height / 2 - listPadding, BOTTOM_LEFT, listPadding / 2, 4)
        render_team_playerlist(get_players_in_team(TEAM_YELLOW), TEAM_YELLOW, width / 2 - listPadding, height / 2 - listPadding, BOTTOM_RIGHT, listPadding / 2, 4)
    elseif get_amount_of_teams_in_match() == 2 then
        render_team_playerlist(get_players_in_team(TEAM_RED), TEAM_RED, width / 2 - listPadding, height - listPadding, TOP_LEFT, listPadding / 2, 8)
        render_team_playerlist(get_players_in_team(TEAM_BLUE), TEAM_BLUE, width / 2 - listPadding, height - listPadding, TOP_RIGHT, listPadding / 2, 8)
    else
        -- this technically can work with any amount of teams, so it's also what we use for 3 player teams!
        local players = {}
        for i = 0, MAX_PLAYERS / 2 - 1 do
            if gNetworkPlayers[i].connected then
                table.insert(players, i)
            end
        end
        render_team_playerlist(players, TEAM_NONE, width / 2 - listPadding, height - listPadding, TOP_LEFT, listPadding / 2, 8)
        players = {}
        for i = MAX_PLAYERS / 2, MAX_PLAYERS - 1 do
            if gNetworkPlayers[i].connected then
                table.insert(players, i)
            end
        end
        render_team_playerlist(players, TEAM_NONE, width / 2 - listPadding, height - listPadding, TOP_RIGHT, listPadding / 2, 8)
    end
    djui_hud_set_filter(FILTER_LINEAR)
end

local function render_modlist()
    djui_hud_set_filter(FILTER_NEAREST)
    local screenWidth = djui_hud_get_screen_width()
    local screenHeight = djui_hud_get_screen_height()
    local title = "Mods"
    local width = modListWidth
    local height = modListHeight
    local lipWidth = math.max(width / 2 + 100, djui_hud_measure_text(title) * 2 + 50) * sPlayerListScale
    local xOffset = -(playerListWidth / 4 + width / 2 + 5)

    local x = (screenWidth - lipWidth) / 2 - xOffset
    local y = (screenHeight - height) / 2 - lipHeight / 2

    djui_hud_set_color(60, 60, 60, 200)
    djui_hud_render_rect(x, y - 5, lipWidth, lipHeight + 5)

    -- render outline manually to remove bottom of lip
    local thickness = 5
    djui_hud_set_color(0, 0, 0, 200)
    djui_hud_render_rect(x - thickness, y - thickness * 2, lipWidth + thickness * 2, thickness)
    djui_hud_render_rect(x - thickness, y - thickness, thickness, lipHeight)
    djui_hud_render_rect(x + lipWidth, y - thickness, thickness, lipHeight)

    x = (screenWidth - width) / 2 - xOffset
    y = (screenHeight - height + lipHeight) / 2

    djui_hud_set_color(60, 60, 60, 200)
    djui_hud_render_rect(x - 5, y, width + 5, height)
    djui_hud_set_color(0, 0, 0, 200)
    djui_hud_render_rect(x + (width - thickness) + thickness, y, thickness, height + thickness)
    djui_hud_render_rect(x, y - thickness, width / 2 - lipWidth / 2, thickness)
    djui_hud_render_rect(x + width / 2 + lipWidth / 2, y - thickness, width / 2 - lipWidth / 2 + thickness, thickness)
    djui_hud_render_rect(x, y + (height - thickness) + thickness, width, thickness)

    x = screenWidth / 2 - xOffset - djui_hud_measure_text(title) * (2 * sPlayerListScale) / 2
    local textY = screenHeight / 2 - height / 2 - lipHeight + (20 * sPlayerListScale) / 2

    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text(title, x, textY, 2 * sPlayerListScale)

    x = (screenWidth - width) / 2 - xOffset + 5

    local listPadding = 20

    djui_hud_set_color(5, 5, 5, 200)
    djui_hud_render_rect_outlined(x + listPadding / 2 - 5, y + listPadding / 2, width - listPadding, height - listPadding, 255, 255, 255, 255, 2)

    local activeModsSize = 0
    for mod in pairs(gActiveMods) do
        if not mod then goto continue end
        activeModsSize = activeModsSize + 1
        ::continue::
    end

    for i = 0, activeModsSize do
        local mod = gActiveMods[i]
        local paddingY = 12
        local listWidth = (width - 10)
        local listHeight = math.min((height / activeModsSize), 47) - paddingY
        local originalX = x
        local originalY = y
        local textScale = listHeight / 35
        local dividerXPadding = 30

        if not mod then goto continue end

        y = y + listPadding
        x = x + dividerXPadding / 2

        djui_hud_set_color(220, 220, 220, 255)
        djui_hud_print_text_shaded(cap_text(mod.name, (listWidth - listPadding) / textScale), x, y, textScale)

        if i ~= activeModsSize then
            djui_hud_set_color(255, 255, 255, 255)
            djui_hud_render_rect(originalX + dividerXPadding / 2, y + listHeight + paddingY / 2, listWidth - dividerXPadding, 2)
        end

        ::continue::

        x = originalX
        y = originalY + listHeight + paddingY
    end

    djui_hud_set_filter(FILTER_LINEAR)
end

local function on_hud_render()
    djui_hud_set_font(FONT_SCIENCE_GOTHIC)
    djui_hud_set_resolution(RESOLUTION_DJUI)

    if djui_attempting_to_open_playerlist() then
        render_playerlist()
        render_modlist()
    end
end

local function on_mods_loaded()
    if _G.gServerSettingsCS then _G.gServerSettingsCS.enablePlayerList = false end
end

hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_event(HOOK_ON_MODS_LOADED, on_mods_loaded)