local panelAnimationTimer = 0
local animationDuration = 0.25 * 30
local previousX = 0

function reset_rtv_votes()
    for i = 0, MAX_PLAYERS - 1 do
        gPlayerSyncTable[i].rtv = false
    end
end

function get_required_rtv_count()
    return math.ceil(active_player_count(true) / 2)
end

function get_total_rtv_count()
    local rtvCount = 0
    for i = 0, MAX_PLAYERS - 1 do
        if gNetworkPlayers[i].connected and gPlayerSyncTable[i].rtv then
            rtvCount = rtvCount + 1
        end
    end
    return rtvCount
end

local function on_hud_render()

    djui_hud_set_resolution(RESOLUTION_DJUI)
    djui_hud_set_font(FONT_SCIENCE_GOTHIC)

    local voteCount = get_total_rtv_count()
    panelAnimationTimer = clamp(panelAnimationTimer + (voteCount > 0 and 1 or -1), 0, animationDuration)

    local screenWidth = djui_hud_get_screen_width()
    local screenHeight = djui_hud_get_screen_height()

    local width = 300
    local height = 400

    local x = screenWidth - width * (panelAnimationTimer / animationDuration)
    local y = (screenHeight - height) / 2

    local text = "Skip round?"
    local textScale = 1.5
    local textOffset = (width - djui_hud_measure_text(text) * textScale) / 2
    local textX = x + textOffset
    local previousTextX = previousX + textOffset
    y = (screenHeight - 36 * textScale) / 2
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text_shaded_interpolated(text, previousTextX, y, textScale, textX, y, textScale)

    y = y + 30 * textScale

    text = "Vote yes by typing /rtv"
    textScale = 1
    textOffset = (width - djui_hud_measure_text(text) * textScale) / 2
    textX = x + textOffset
    previousTextX = previousX + textOffset
    djui_hud_set_color(220, 220, 220, 255)
    djui_hud_print_text_shaded_interpolated(text, previousTextX, y, textScale, textX, y, textScale)

    y = y + 36 * textScale

    text = voteCount .. "/" .. get_required_rtv_count()
    textScale = 1
    textOffset = (width - djui_hud_measure_text(text) * textScale) / 2
    textX = x + textOffset
    previousTextX = previousX + textOffset
    if voteCount == get_required_rtv_count() then
        djui_hud_set_color(255, 220, 0, 255)
    else
        djui_hud_set_color(200, 200, 200, 255)
    end
    djui_hud_print_text_shaded_interpolated(text, previousTextX, y, textScale, textX, y, textScale)
    previousX = x
end

local function on_rock_the_vote_command(msg)
    gPlayerSyncTable[0].rtv = true
    return true
end

hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_chat_command("rtv", "Rock the Vote, allowing you to skip the current map and gamemode", on_rock_the_vote_command)