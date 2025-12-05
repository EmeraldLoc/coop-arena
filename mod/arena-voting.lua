local selection = 1
local joystickCooldown = 0

function get_amount_of_votes_for_level(level)

    local amountOfVotes = 0

    for i = 0, MAX_PLAYERS - 1 do
        local np = gNetworkPlayers[i]
        local s = gPlayerSyncTable[i]
        if np.connected and s.vote == level then
            amountOfVotes = amountOfVotes + 1
        end
    end

    return amountOfVotes
end

function voting_hud()

    if gGlobalSyncTable.gameState ~= GAME_STATE_VOTING then return end

    local s = gPlayerSyncTable[0]

    djui_hud_set_resolution(RESOLUTION_DJUI)
    djui_hud_set_font(djui_menu_get_font())

    local screenWidth = djui_hud_get_screen_width()
    local screenHeight = djui_hud_get_screen_height()

    local width = 1300
    local height = 675

    local x = (screenWidth - width) / 2
    local y = (screenHeight - height) / 2

    djui_hud_set_color(20, 20, 20, 200)
    djui_hud_render_rect(x, y, width, height)

    if #sVoteEntries == 0 then
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text_shaded("Please Wait...", x + width / 2 - djui_hud_measure_text("Please Wait...") / 2, y + height / 2, 1)
        return
    end

    -- render preview
    local previewWidth = 768
    local previewHeight = 432
    local previewImage

    if selection == 1 then
        previewImage = TEX_REDO_LEVEL
    elseif selection == 5 then
        previewImage = TEX_RANDOM_LEVEL
    else
        previewImage = gGameLevels[sVoteEntries[selection - 1].level].previewImage
        if not previewImage then
            previewImage = TEX_NO_IMAGE
        end
    end

    x = (screenWidth - previewWidth) / 2
    y = (screenHeight - previewHeight) / 2 - 100

    djui_hud_set_color(255, 220, 0, s.vote == selection and 255 or 0)
    djui_hud_render_rect(x - 6, y - 6, previewWidth + 12, previewHeight + 13)
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_render_texture(previewImage, x, y, previewWidth / previewImage.width, previewWidth / previewImage.width)

    if selection > 1 and selection < 5 then

        local level = gGameLevels[sVoteEntries[selection - 1].level]
        local gamemode = gGameModes[sVoteEntries[selection - 1].gamemode]

        local levelName = level.name
        local levelAuthor = level.author
        local gamemodeName = gamemode.name

        djui_hud_set_font(FONT_MENU)
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text(levelName, x + 6, y + 4, 0.5)

        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text(levelAuthor, x + previewWidth - djui_hud_measure_text(levelAuthor) * 0.5 - 12, y + previewHeight - 30 - 6, 0.5)

        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text(gamemodeName, x + previewWidth - djui_hud_measure_text(gamemodeName) * 0.5 - 12, y + 4, 0.5)

        djui_hud_set_font(FONT_NORMAL)
    end

    previewWidth = 192
    previewHeight = 108

    local totalWidth = 5 * previewWidth + 4 * 75

    x = (screenWidth - totalWidth) / 2
    y = (screenHeight - previewWidth) / 2 + 250

    previewImage = TEX_REDO_LEVEL

    djui_hud_set_color(255, 220, 0, selection == VOTE_ID_REDO and 255 or 0)
    djui_hud_render_rect(x - 4, y - 4, previewWidth + 8, previewHeight + 9)
    djui_hud_set_color(255, s.vote == VOTE_ID_REDO and 200 or 255, s.vote == VOTE_ID_REDO and 0 or 255, 255)
    djui_hud_render_texture(previewImage, x, y, previewWidth / previewImage.width, previewWidth / previewImage.width)

    local redoLevelText = "Redo Level (" .. get_amount_of_votes_for_level(VOTE_ID_REDO) .. ")"

    djui_hud_set_color(255, s.vote == VOTE_ID_REDO and 220 or 255, s.vote == VOTE_ID_REDO and 0 or 255, 255)
    djui_hud_print_text_shaded(redoLevelText, x + previewWidth / 2 - djui_hud_measure_text(redoLevelText) / 2, y + previewHeight + 10, 1)

    for i = 1, 3 do
        local v = sVoteEntries[i]

        x = x + previewWidth + 75

        previewImage = gGameLevels[v.level].previewImage
        if not previewImage then previewImage = TEX_NO_IMAGE end

        djui_hud_set_color(255, 220, 0, selection == i + 1 and 255 or 0)
        djui_hud_render_rect(x - 4, y - 4, previewWidth + 8, previewHeight + 9)
        djui_hud_set_color(255, s.vote == i + 1 and 200 or 255, s.vote == i + 1 and 0 or 255, 255)
        djui_hud_render_texture(previewImage, x, y, previewWidth / previewImage.width, previewHeight / (previewImage.width / 16 * 9))

        local voteLevelText = gGameLevels[v.level].name .. " (" .. get_amount_of_votes_for_level(i + 1) .. ")"

        djui_hud_set_color(255, s.vote == i + 1 and 220 or 255, s.vote == i + 1 and 0 or 255, 255)
        djui_hud_print_text_shaded(voteLevelText, x + previewWidth / 2 - djui_hud_measure_text(voteLevelText) / 2, y + previewHeight + 10, 1)
    end

    x = x + previewWidth + 75

    previewImage = TEX_RANDOM_LEVEL

    djui_hud_set_color(255, 220, 0, selection == VOTE_ID_RANDOM and 255 or 0)
    djui_hud_render_rect(x - 4, y - 4, previewWidth + 8, previewHeight + 9)
    djui_hud_set_color(255, s.vote == VOTE_ID_RANDOM and 200 or 255, s.vote == VOTE_ID_RANDOM and 0 or 255, 255)
    djui_hud_render_texture(previewImage, x, y, previewWidth / previewImage.width, previewHeight / (previewImage.width / 16 * 9))

    local randomLevelText = "Random (" .. get_amount_of_votes_for_level(VOTE_ID_RANDOM) .. ")"

    djui_hud_set_color(255, s.vote == VOTE_ID_RANDOM and 220 or 255, s.vote == VOTE_ID_RANDOM and 0 or 255, 255)
    djui_hud_print_text_shaded(randomLevelText, x + previewWidth / 2 - djui_hud_measure_text(randomLevelText) / 2, y + previewHeight + 10, 1)
end

---@param m MarioState
local function mario_update(m)
    if gGlobalSyncTable.gameState ~= GAME_STATE_VOTING then
        selection = 2
        return
    end

    if m.playerIndex ~= 0 then return end

    local s = gPlayerSyncTable[0]

    m.freeze = 1

    if joystickCooldown > 0 then
        joystickCooldown = joystickCooldown - 1
        if m.controller.stickX == 0 and m.controller.stickY == 0 then
            joystickCooldown = 0
        end
        return
    end

    if m.controller.stickX > 0.5 then
        selection = selection + 1
        if selection > 5 then selection = 1 end
        joystickCooldown = 0.2 * 30
    elseif m.controller.stickX < -0.5 then
        selection = selection - 1
        if selection < 1 then selection = 5 end
        joystickCooldown = 0.2 * 30
    end

    if m.controller.buttonPressed & A_BUTTON ~= 0 then
        s.vote = s.vote == selection and 0 or selection
    end
end

hook_event(HOOK_ON_HUD_RENDER, voting_hud)
hook_event(HOOK_MARIO_UPDATE, mario_update)
