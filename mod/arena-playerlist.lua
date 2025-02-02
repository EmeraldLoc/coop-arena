
local function render_playerlist()
    local screenWidth = djui_hud_get_screen_width()
    local screenHeight = djui_hud_get_screen_height()
    local width = 750
    local height = 725
    local x = (screenWidth - width) / 2
    local y = (screenHeight - height) / 2

    djui_hud_set_color(0, 0, 0, 200)
    djui_hud_render_rect(x, y, width, height)

    local title = gGameModes[gGlobalSyncTable.gameMode].name

    x = screenWidth / 2 - djui_hud_measure_text(title)

    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text(title, x, y, 2)

    x = (screenWidth - width) / 2 + 5
    y = y + 75

    for i = 0, MAX_PLAYERS - 1 do
        if gNetworkPlayers[i].connected then
            local np = gNetworkPlayers[i]
            local s = gPlayerSyncTable[i]
            local rank = rank_str(s.rank)
            local playerTextColor = hex_to_rgb(network_get_player_text_color_string(i))
            local playerListWidth = width - 10
            local playerListHeight = 32
            local originalX = x
            local cells = 4
            local curCell = 1
            local cellWidth = playerListWidth / (cells + 1)
            djui_hud_set_color(20, 20, 20, 255)
            djui_hud_render_rect(x, y, playerListWidth, playerListHeight)

            djui_hud_set_color(255, 255, 255, 255)
            if charSelect then
                charSelect.character_render_life_icon(i, x, y, 2)
            else
                local headTex = gCharacters[np.overrideModelIndex].hudHeadTexture or get_texture_info("texture_hud_char_question")

                djui_hud_render_texture(headTex, x, y, 32 / (headTex.width), 32 / (headTex.height))
            end

            x = x + 40

            djui_hud_set_color(playerTextColor.r, playerTextColor.g, playerTextColor.b, 255)
            djui_hud_print_text(cap_text(np.name, cellWidth * 2 - 45), x, y, 1)

            curCell = curCell + 1; x = (screenWidth - width) / 2 + cellWidth * curCell

            djui_hud_set_color(40, 40, 40, 100)
            djui_hud_render_rect(x, y + 2, 2, playerListHeight - 4)

            if s.team == TEAM_SPECTATOR then
                djui_hud_set_color(70, 70, 70, 255)
                djui_hud_print_text("Spectator", x + 10, y, 1)
                goto continue
            else
                djui_hud_set_color(255, rank_color_g(s.rank), 0, 255)
                djui_hud_print_text(rank, x + 10, y, 1)
            end

            curCell = curCell + 1; x = (screenWidth - width) / 2 + cellWidth * curCell

            djui_hud_set_color(40, 40, 40, 100)
            djui_hud_render_rect(x, y + 2, 2, playerListHeight - 4)

            djui_hud_set_color(255, rank_color_g(s.rank), 0, 255)
            djui_hud_print_text(tostring(s.kills) .. " kills", x + 10, y, 1)

            curCell = curCell + 1; x = (screenWidth - width) / 2 + cellWidth * curCell

            djui_hud_set_color(40, 40, 40, 100)
            djui_hud_render_rect(x, y + 2, 2, playerListHeight - 4)

            djui_hud_set_color(255, rank_color_g(s.rank), 0, 255)
            djui_hud_print_text(gGameModes[gGlobalSyncTable.gameMode].useScore and tostring(s.score) .. " points" or tostring(s.deaths) .. " deaths", x + 10, y, 1)

            ::continue::

            x = originalX
            y = y + playerListHeight + 7
        end
    end
end

local function render_modlist()

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