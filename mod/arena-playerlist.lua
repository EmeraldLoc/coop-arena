
local sPlayerListScale = 0.86
local playerListWidth = 750 * sPlayerListScale
local playerListHeight = 800 * sPlayerListScale
local modListWidth = 300 * sPlayerListScale
local modListHeight = 400 * sPlayerListScale

local function render_playerlist()
    djui_hud_set_filter(FILTER_NEAREST)
    local screenWidth = djui_hud_get_screen_width()
    local screenHeight = djui_hud_get_screen_height()
    local title = gGameModes[gGlobalSyncTable.gameMode].name
    local width = playerListWidth
    local height = playerListHeight
    local lipWidth = math.max(width / 2 + 100, djui_hud_measure_text(title) * 2 + 50) * sPlayerListScale
    local lipHeight = 50 * sPlayerListScale
    local xOffset = width / 4

    local x = (screenWidth - lipWidth) / 2 - xOffset
    local y = (screenHeight - height) / 2 - lipHeight / 2

    djui_hud_set_color(27, 27, 27, 200)
    djui_hud_render_rect(x, y - 5, lipWidth, lipHeight)

    -- render outline manually to remove bottom of lip
    local thickness = 5
    djui_hud_set_color(20, 20, 20, 200)
    djui_hud_render_rect(x - thickness, y - thickness * 2, lipWidth + thickness * 2, thickness)
    djui_hud_render_rect(x - thickness, y - thickness, thickness, lipHeight)
    djui_hud_render_rect(x + lipWidth, y - thickness, thickness, lipHeight)

    x = (screenWidth - width) / 2 - xOffset
    y = (screenHeight - height + lipHeight) / 2

    djui_hud_set_color(27, 27, 27, 200)
    djui_hud_render_rect_outlined(x, y, width, height, 20, 20, 20, 200, 5)

    x = screenWidth / 2 - xOffset - djui_hud_measure_text(title) * (2 * sPlayerListScale) / 2
    local textY = screenHeight / 2 - height / 2 - lipHeight + (20 * sPlayerListScale) / 2

    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text(title, x, textY, 2 * sPlayerListScale)

    x = (screenWidth - width) / 2 - xOffset + 5

    for i = 0, MAX_PLAYERS - 1 do
        if gNetworkPlayers[i].connected then
            local np = gNetworkPlayers[i]
            local s = gPlayerSyncTable[i]
            local rank = rank_str(s.rank)
            local paddingY = 12
            local playerTextColor = hex_to_rgb(network_get_player_text_color_string(i))
            local listWidth = (width - 10)
            local listHeight = math.min((height / network_player_connected_count()), 47) - paddingY
            local originalX = x
            local originalY = y
            local cells = 4
            local curCell = 1
            local cellWidth = listWidth / (cells + 1)
            local textScale = listHeight / 35

            s.rank = i + 1

            y = y + 5

            djui_hud_set_color(20, 20, 20, 255)
            local outlineColor = { r = 30, g = 30, b = 30, a = 255 }
            if s.rank == 1 then
                outlineColor = { r = 255, g = rank_color_g(s.rank), b = 0, a = 255 }
            end
            djui_hud_render_rect_outlined(x, y, listWidth, listHeight, outlineColor.r, outlineColor.g, outlineColor.b, outlineColor.a, 2)

            y = y + 2 * textScale

            djui_hud_set_color(255, 255, 255, 255)
            if charSelect then
                charSelect.character_render_life_icon(i, x, y, 2)
            else
                local headTex = gCharacters[np.overrideModelIndex].hudHeadTexture or get_texture_info("texture_hud_char_question")

                djui_hud_render_texture(headTex, x, y, 32 / (headTex.width) * textScale, 32 / (headTex.height) * textScale)
            end

            x = x + 40

            djui_hud_set_color(playerTextColor.r, playerTextColor.g, playerTextColor.b, 255)
            djui_hud_print_text_shaded(cap_text(np.name, (cellWidth * 2 - 45) / textScale), x, y, textScale)

            curCell = curCell + 1
            x = (screenWidth - width) / 2 - xOffset + cellWidth * curCell

            djui_hud_set_color(40, 40, 40, 100)
            djui_hud_render_rect(x, y + 2, 2, listHeight - 4)

            if s.team == TEAM_SPECTATOR then
                djui_hud_set_color(70, 70, 70, 255)
                djui_hud_print_text_shaded("Spectator", x + 10 * textScale, y, textScale)
                goto continue
            else
                djui_hud_set_color(255, rank_color_g(s.rank), 0, 255)
                djui_hud_print_text_shaded(rank, x + 10 * textScale, y, textScale)
            end

            curCell = curCell + 1
            x = (screenWidth - width) / 2 - xOffset + cellWidth * curCell

            djui_hud_set_color(40, 40, 40, 100)
            djui_hud_render_rect(x, y + 2, 2, listHeight - 4)

            djui_hud_set_color(255, rank_color_g(s.rank), 0, 255)
            djui_hud_print_text_shaded(tostring(s.kills) .. " kills", x + 10 * textScale, y, textScale)

            curCell = curCell + 1
            x = (screenWidth - width) / 2 - xOffset + cellWidth * curCell

            djui_hud_set_color(40, 40, 40, 100)
            djui_hud_render_rect(x, y + 2, 2, listHeight - 4)

            djui_hud_set_color(255, rank_color_g(s.rank), 0, 255)
            djui_hud_print_text_shaded(gGameModes[gGlobalSyncTable.gameMode].useScore and tostring(s.score) .. " points" or tostring(s.deaths) .. " deaths", x + 10 * textScale, y, textScale)

            ::continue::

            x = originalX
            y = originalY + listHeight + paddingY
        end
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
    local lipHeight = 50 * sPlayerListScale
    local xOffset = -(playerListWidth / 4 + width / 2 + 5)

    local x = (screenWidth - lipWidth) / 2 - xOffset
    local y = (screenHeight - height) / 2 - lipHeight / 2

    djui_hud_set_color(27, 27, 27, 200)
    djui_hud_render_rect(x, y - 5, lipWidth, lipHeight)

    -- render outline manually to remove bottom of lip
    local thickness = 5
    djui_hud_set_color(20, 20, 20, 200)
    djui_hud_render_rect(x - thickness, y - thickness * 2, lipWidth + thickness * 2, thickness)
    djui_hud_render_rect(x - thickness, y - thickness, thickness, lipHeight)
    djui_hud_render_rect(x + lipWidth, y - thickness, thickness, lipHeight)

    x = (screenWidth - width) / 2 - xOffset
    y = (screenHeight - height + lipHeight) / 2

    djui_hud_set_color(27, 27, 27, 200)
    djui_hud_render_rect(x, y, width, height)
    djui_hud_set_color(20, 20, 20, 200)
    djui_hud_render_rect(x + (width - thickness) + thickness, y, thickness, height + thickness)
    djui_hud_render_rect(x, y - thickness, width + thickness, thickness)
    djui_hud_render_rect(x, y + (height - thickness) + thickness, width, thickness)

    x = screenWidth / 2 - xOffset - djui_hud_measure_text(title) * (2 * sPlayerListScale) / 2
    local textY = screenHeight / 2 - height / 2 - lipHeight + (20 * sPlayerListScale) / 2

    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text(title, x, textY, 2 * sPlayerListScale)

    x = (screenWidth - width) / 2 - xOffset + 5

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

        if not mod then goto continue end

        y = y + 5

        djui_hud_set_color(20, 20, 20, 255)
        djui_hud_render_rect_outlined(x, y, listWidth, listHeight, 30, 30, 30, 255, 2)

        x = x + 10

        djui_hud_set_color(220, 220, 220, 255)
        djui_hud_print_text_shaded(cap_text(mod.name, listWidth / textScale), x, y, textScale)

        ::continue::

        x = originalX
        y = originalY + listHeight + paddingY
    end

    djui_hud_set_filter(FILTER_LINEAR)
end

local function on_hud_render()
    djui_hud_set_font(djui_menu_get_font())
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