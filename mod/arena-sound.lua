local m = gMarioStates[0]
local np = gNetworkPlayers[0]

local pauseDisplayMusic = false
local pauseDisplayLevelID = false

--- @type ArenaBGM?
local curBGM
local BGMPaused = false

local function handle_music()
    local bgm = gGameLevels[get_current_level_key()].bgm

    --Handle main course music
    if np.currAreaSyncValid and bgm ~= curBGM then
        if curBGM and curBGM.stream then
            audio_stream_stop(curBGM.stream)
        end
        curBGM = bgm

        if bgm and bgm.audio then
            bgm.volume = bgm.volume or 1
            bgm.stream = audio_stream_load(bgm.audio)
            if bgm.stream then
                audio_stream_set_looping(bgm.stream, true)
                if bgm.loopStart and bgm.loopEnd then
                    audio_stream_set_loop_points(bgm.stream, bgm.loopStart, bgm.loopEnd)
                end
                audio_stream_play(bgm.stream, true, bgm.volume)
                print("Playing new audio " .. bgm.name)
            else
                djui_popup_create('Missing audio!: ' .. bgm.audio, 10)
                print("Attempted to load audio file, but couldn't find it on the system: " .. bgm.audio)
            end
        end
    end

    if bgm and bgm.stream then
        if m.capTimer > 0 ~= BGMPaused then
            BGMPaused = m.capTimer > 0
            if BGMPaused then
                audio_stream_stop(bgm.stream)
            else
                audio_stream_play(bgm.stream, true, bgm.volume)
            end
        end

        audio_stream_set_volume(bgm.stream, bgm.volume * (is_game_paused() and .31 or 1))
    end
end

local function hud_render()
    if pauseDisplayMusic and is_game_paused() then
        local bgm = gGameLevels[get_current_level_key()].bgm
        djui_hud_set_resolution(RESOLUTION_DJUI)
        djui_hud_set_font(FONT_NORMAL)
        local screenWidth = djui_hud_get_screen_width()
        local screenHeight = djui_hud_get_screen_height()
        local height = 64
        local y = screenHeight - height
        djui_hud_set_color(200,200,200,255)
        local text
        if pauseDisplayLevelID then
            text = "Level ID: " .. np.currLevelNum
        elseif bgm then
            text = "Music: " .. bgm.name
        end
        djui_hud_print_text(text, 5, y, 1)
    end
end

local function override_music(player, seqID)
    if gGameLevels[get_current_level_key()].bgm and player == 0
    and ((seqID & 0xFF) < 0x0E or 0x20 < (seqID & 0xFF))
    then return 0 end
end

hook_event(HOOK_UPDATE, handle_music)
hook_event(HOOK_ON_HUD_RENDER, hud_render)
hook_event(HOOK_ON_SEQ_LOAD, override_music)