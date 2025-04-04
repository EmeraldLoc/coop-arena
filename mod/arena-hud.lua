gHudIcons = {
    flags = {
        [0] = { tex = TEX_FLAG, prevX = 0, prevY = 0, r = 255, g = 255, b = 255 },
        [TEAM_RED] = { tex = TEX_FLAG, prevX = 0, prevY = 0, r = 255, g = 120, b = 120 },
        [TEAM_BLUE] = { tex = TEX_FLAG, prevX = 0, prevY = 0, r = 120, g = 120, b = 255 },
        -- TODO: Maybe update team colors here
        [TEAM_GREEN] = { tex = TEX_FLAG, prevX = 0, prevY = 0, r = 120, g = 255, b = 120 },
        [TEAM_YELLOW] = { tex = TEX_FLAG, prevX = 0, prevY = 0, r = 255, g = 255, b = 0 },
    },
    koth = { tex = TEX_KOTH, prevX = 0, prevY = 0, r = 255, g = 255, b = 255 },
}

local arenaHudTextures = {
    [ITEM_CANNON_BOX] = {
        get_texture_info("Arena64NewHUD_0000_Cannon-Box-(PC)"),
        get_texture_info("Arena64NewHUD_0001_Cannon-Box")
    },
    health = {
        get_texture_info("Arena64NewHUD_0002_Health")
    },
    [ITEM_HAMMER] = {
        get_texture_info("Arena64NewHUD_0003_Hammer-(PC)"),
        get_texture_info("Arena64NewHUD_0004_Hammer")
    },
    [ITEM_FIRE_FLOWER] = {
        get_texture_info("Arena64NewHUD_0005_Flower-(PC)"),
        get_texture_info("Arena64NewHUD_0006_Flower")
    },
    [ITEM_BOBOMB] = {
        get_texture_info("Arena64NewHUD_0007_Bobomb-(PC)"),
        get_texture_info("Arena64NewHUD_0008_Bobomb")
    },
    [ITEM_NONE] = {
        get_texture_info("Arena64NewHUD_0009_Main-Hands-(PC)"),
    },
    solo_timer = {
        get_texture_info("Arena64NewHUD_0010_Solo-Timer-HUD"),
    },
    three_team_hud = {
        get_texture_info("Arena64NewHUD_0011_3-TEAM-HUD")
    },
    four_team_hud = {
        get_texture_info("Arena64NewHUD_0012_4-TEAM-HUD")
    },
    team_hud = {
        get_texture_info("Arena64NewHUD_0013_Team-HUD")
    },
    two_team_colors = {
        get_texture_info("Arena64NewHUD_0014_2_Team-Colors")
    },
    three_team_colors = {
        get_texture_info("Arena64NewHUD_0015_3_Team-Colors")
    },
    four_team_colors = {
        get_texture_info("Arena64NewHUD_0016_4_Team-Colors")
    },
}

local function render_arena_hud_texture(hudTex, x, y, scale)
    for i = 1, #hudTex do
        local tex = hudTex[i]
        djui_hud_render_texture(tex, x, y, scale, scale)
    end
end

function rank_str(rank)
    return rank .. (((rank // 10) % 10 ~= 1) and ({"st", "nd", "rd"})[rank % 10] or "th")
end

function rank_color_g(rank)
    return clamp(255 - 255 * (rank / 8), 0, 255)
end

function update_ranking_descriptions()
    for i = 0, (MAX_PLAYERS - 1) do
        local s  = gPlayerSyncTable[i]
        local np = gNetworkPlayers[i]
        local m  = gMarioStates[i]
        if active_player(m) then
            if s.rank > 0 then
                local score = s.kills
                if gGameModes[gGlobalSyncTable.gameMode].useScore then
                    score = s.score
                end
                local description = string.format('%s %d', rank_str(s.rank), score)
                local r = 255
                local g = rank_color_g(i)
                local b = 0
                network_player_set_description(np, description, r, g, b, 255)
            else
                network_player_set_description(np, ' ', 255, 255, 255, 255)
            end
        end
    end
end

function render_game_mode()
    local m  = gMarioStates[0]
    local np = gNetworkPlayers[0]
    local s  = gPlayerSyncTable[0]

    if s.rank <= 0 then return end

    local screenWidth = djui_hud_get_screen_width()

    local scoreCap = gGameModes[gGlobalSyncTable.gameMode].scoreCap

    local txt = string.format(gGameModes[gGlobalSyncTable.gameMode].rules, scoreCap)
    local scale = 0.35
    local width = djui_hud_measure_text(txt) * scale
    local x = (screenWidth - width) / 2
    local y = 4 * scale

    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text_shaded(txt, x, y, scale)
end

function render_single_team_score(team)
    -- TODO: Finish this
    local txt = tostring(calculate_team_score(team))

    local screenWidth = djui_hud_get_screen_width()
    local screenHeight = djui_hud_get_screen_height()
    local scale = 0.18
    local textWidth = djui_hud_measure_text(txt) * scale
    local x = screenWidth / 2
    local y = screenHeight - 37

    if team == 1 then
        x = x - 20
    elseif team == 2 then
        x = x + 20 - textWidth
    elseif team == 3 then
        x = x - 20
        y = y + 13
    elseif team == 4 then
        x = x + 20 - textWidth
        y = y + 13
    end

    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text_shaded(txt, x, y, scale)
end

function render_team_score()
    if not gGameModes[gGlobalSyncTable.gameMode].teams then
        return
    end

    for i = 1, gGameLevels[get_current_level_key()].maxTeams do
        render_single_team_score(i)
    end
end

function render_local_rank()
    local s  = gPlayerSyncTable[0]

    if s.rank <= 0 then
        return
    end

    local rankTxt = ""
    if gGameModes[gGlobalSyncTable.gameMode].useScore then
        rankTxt = string.format("%s | %d points | %d kills", rank_str(s.rank), s.score, s.kills)
    else
        rankTxt = string.format("%s | %d kills | %d deaths", rank_str(s.rank), s.kills, s.deaths)
    end
    local screenWidth = djui_hud_get_screen_width()
    local scale = 0.35
    local paddingX = 64 * scale
    local width = (djui_hud_measure_text(rankTxt) + paddingX) * scale
    local x = (screenWidth - width) / 2
    local y = 40 * scale

    djui_hud_set_color(255, rank_color_g(s.rank), 0, 255)
    djui_hud_print_text_shaded(rankTxt, x + paddingX / 8, y, scale)
end

function render_server_message()
    local txt = gGlobalSyncTable.message
    if not txt or #txt <= 1 then return end

    -- get screen dimensions
    local screenWidth  = djui_hud_get_screen_width()
    local screenHeight = djui_hud_get_screen_height()

    local scale = 1
    local width = (djui_hud_measure_text(txt) + 8) * scale
    local height = 4 * scale + 28 * scale
    local x = (screenWidth - width) / 2
    local y = (screenHeight / 4)

    djui_hud_set_color(0, 0, 0, 128)
    djui_hud_render_rect(x, y, width, height)

    x = x + 4 * scale
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text_shaded(txt, x + 0 * scale, y + 0 * scale, scale)
end

function render_main_hud()
    djui_hud_set_resolution(RESOLUTION_DJUI)
    local m = gMarioStates[0]
    local s = gPlayerSyncTable[0]

    -- get screen dimensions
    local screenWidth  = djui_hud_get_screen_width()
    local screenHeight = djui_hud_get_screen_height()

    local scale = 4
    local x = screenWidth / 2 - 64 * scale
    local y = screenHeight - 96 * scale

    local health = arenaHudTextures.health
    local powerHud = arenaHudTextures[s.item]

    djui_hud_set_color(255, 255, 255, 255)
    render_arena_hud_texture(health, x, y, scale)

    if gGameModes[gGlobalSyncTable.gameMode].time > 0 then
        local timer = arenaHudTextures.solo_timer
        render_arena_hud_texture(timer, x, y, scale)
    end

    if gGameModes[gGlobalSyncTable.gameMode].teams then
        local teamHud = arenaHudTextures.team_hud
        render_arena_hud_texture(teamHud, x, y, scale)

        if gGameLevels[get_current_level_key()].maxTeams == 3 then
            teamHud = arenaHudTextures.three_team_hud
            render_arena_hud_texture(teamHud, x, y, scale)
        elseif gGameLevels[get_current_level_key()].maxTeams == 4 then
            teamHud = arenaHudTextures.four_team_hud
            render_arena_hud_texture(teamHud, x, y, scale)
        end

        local teamColors = arenaHudTextures.two_team_colors
        if gGameLevels[get_current_level_key()].maxTeams == 3 then
            teamColors = arenaHudTextures.three_team_colors
        elseif gGameLevels[get_current_level_key()].maxTeams == 4 then
            teamColors = arenaHudTextures.four_team_colors
        end

        -- .....uh ignore this, definitely didn't mess up the colors, and I 100% wasn't lazy at all, nope, def not
        djui_hud_set_color(200, 200, 200, 255)
        render_arena_hud_texture(teamColors, x, y, scale)
        djui_hud_set_color(255, 255, 255, 255)
    end

    if m.health <= 0x880 then
        local width = clampf(52 * scale - linear_interpolation(m.health, 0, 52 * scale, 0xFF, 0x880), 0, 52 * scale)
        local height = 5 * scale

        local x = screenWidth / 2 + 26 * scale - width
        local y = screenHeight - 30 * 4

        djui_hud_set_color(96, 96, 96, 255)
        djui_hud_render_rect(x, y, width, height)
        djui_hud_set_color(255, 255, 255, 255)
    end

    render_arena_hud_texture(powerHud, x, y, scale)

    djui_hud_set_resolution(RESOLUTION_N64)
end

function render_timer()
    if gGlobalSyncTable.timer <= 0 then return end

    local txt = string.format("%d:%02d", math.floor(gGlobalSyncTable.timer / 60), math.floor(gGlobalSyncTable.timer) % 60)

    if gGlobalSyncTable.timer < 60 then
        txt = string.format("%d", math.floor(gGlobalSyncTable.timer))
    end

    local screenWidth = djui_hud_get_screen_width()
    local screenHeight = djui_hud_get_screen_height()
    local scale = 0.23
    local paddingX = 64 * scale
    local width = (djui_hud_measure_text(txt) + paddingX) * scale
    local height = 32 * scale
    local x = (screenWidth - width) / 2
    local y = screenHeight - height - 31

    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text_shaded(txt, x + paddingX / 8, y, scale)
end

function render_auto_spectate_warning()
    if not is_auto_spectating_approaching() then return end

    local txt = "AFK player detected. Spectating in " .. math.ceil(is_auto_spectating_approaching() / 30)

    -- get screen dimensions
    local screenWidth  = djui_hud_get_screen_width()
    local screenHeight = djui_hud_get_screen_height()

    local scale = 0.75
    local width = screenWidth
    local height = screenHeight
    local x = 0
    local y = 0

    local pulseSpeed = 0.4
    local opacity = (math.sin(get_global_timer() * pulseSpeed) * 0.5 + 0.5) * 128

    djui_hud_set_color(255, 0, 0, opacity)
    djui_hud_render_rect(x, y, width, height)

    x = screenWidth / 2 - (djui_hud_measure_text(txt) * scale) / 2
    y = screenHeight / 2 - (32 * scale) / 2
    djui_hud_set_color(255, opacity * 2, opacity * 2, 255)
    djui_hud_print_text_shaded(txt, x + 0 * scale, y + 0 * scale, scale)
end

function render_hud_icon(obj, hudIcon)
    local pos = { x = obj.oPosX, y = obj.oPosY, z = obj.oPosZ }
    local out = { x = 0, y = 0, z = 0 }
    djui_hud_world_pos_to_screen_pos(pos, out)

    if out.z > -260 then
        return
    end

    local alpha = clamp(vec3f_dist(pos, gMarioStates[0].pos) / 5000, 0, 1) - 0.2
    if alpha <= 0 then
        return
    end
    alpha = 1 - ((1 - alpha) ^ 3)

    local dX = out.x - 4
    local dY = out.y - 4

    djui_hud_set_color(hudIcon.r, hudIcon.g, hudIcon.b, alpha * 200)
    djui_hud_render_texture_interpolated(hudIcon.tex, hudIcon.prevX, hudIcon.prevY, 0.3, 0.3, dX, dY, 0.3, 0.3)

    hudIcon.prevX = dX
    hudIcon.prevY = dY
end

local function on_hud_render()
    -- hide default hud elements
    hud_hide()

    -- set resolution and font
    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(djui_menu_get_font())

    -- update and render information
    update_ranking_descriptions()
    render_game_mode()
    render_local_rank()
    render_server_message()
    render_main_hud()
    render_timer()
    render_team_score()
    render_auto_spectate_warning()

    -- render hud icons
    if gGlobalSyncTable.gameMode == GAME_MODE_FT or gGlobalSyncTable.gameMode == GAME_MODE_TFT then
        if gArenaFlagInfo[0] and gArenaFlagInfo[0].obj then
            render_hud_icon(gArenaFlagInfo[0].obj, gHudIcons.flags[0])
        end
    elseif gGlobalSyncTable.gameMode == GAME_MODE_CTF then
        if gArenaFlagInfo[1] and gArenaFlagInfo[1].obj then
            render_hud_icon(gArenaFlagInfo[1].obj, gHudIcons.flags[1])
        end
        if gArenaFlagInfo[2] and gArenaFlagInfo[2].obj then
            render_hud_icon(gArenaFlagInfo[2].obj, gHudIcons.flags[2])
        end
    elseif gGlobalSyncTable.gameMode == GAME_MODE_KOTH or gGlobalSyncTable.gameMode == GAME_MODE_TKOTH then
        if gArenaKothActiveObj then
            render_hud_icon(gArenaKothActiveObj, gHudIcons.koth)
        end
    end
end

hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
