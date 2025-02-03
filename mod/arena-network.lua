PACKET_ARENA_DEATH = 1
PACKET_ARENA_HAMMER_HIT = 2
PACKET_ARENA_RESPAWN = 3
PACKET_ARENA_FLAG = 4
PACKET_ARENA_VOTE_ENTRIES = 5

-------------

function send_arena_death(victimGlobalId, attackerGlobalId)
    network_send(true, {
        id = PACKET_ARENA_DEATH,
        victimGlobalId = victimGlobalId,
        attackerGlobalId = attackerGlobalId,
    })
    on_arena_player_death(victimGlobalId, attackerGlobalId)
end

function on_packet_arena_death_receive(dataTable)
    on_arena_player_death(dataTable.victimGlobalId, dataTable.attackerGlobalId)
end

-------------

function on_packet_arena_respawn_receive(dataTable)
    player_respawn(gMarioStates[0])
end

function send_arena_respawn()
    network_send(true, {
        id = PACKET_ARENA_RESPAWN,
    })
    on_packet_arena_respawn_receive(nil)
end

-------------

function send_arena_hammer_hit(victimGlobalId, attackerGlobalId)
    network_send(true, {
        id = PACKET_ARENA_HAMMER_HIT,
        victimGlobalId = victimGlobalId,
        attackerGlobalId = attackerGlobalId,
    })

    -- spawn particles
    local npVictim   = network_player_from_global_index(victimGlobalId)
    if npVictim ~= nil then
        local mVictim = gMarioStates[npVictim.localIndex]
        spawn_vertical_stars(mVictim.pos.x, mVictim.pos.y, mVictim.pos.z)
    end
end

function on_packet_arena_hammer_hit_receive(dataTable)
    local npVictim   = network_player_from_global_index(dataTable.victimGlobalId)
    local npAttacker = network_player_from_global_index(dataTable.attackerGlobalId)
    local sAttacker = gPlayerSyncTable[npAttacker.localIndex]

    -- decrease ammo
    if sAttacker ~= nil and sAttacker.localIndex == 0 then
        if sAttacker.item == ITEM_HAMMER then
            sAttacker.ammo = sAttacker.ammo - 1
        end
    end

    -- spawn particles
    if npVictim ~= nil then
        local mVictim = gMarioStates[npVictim.localIndex]
        spawn_vertical_stars(mVictim.pos.x, mVictim.pos.y, mVictim.pos.z)
    end
end

-------------

function on_packet_arena_flag_receive(dataTable)
    local np = gNetworkPlayers[0]
    local data = gArenaFlagInfo[dataTable.team]
    if data ~= nil and data.obj ~= nil then
        spawn_sparkles(data.obj.oPosX, data.obj.oPosY, data.obj.oPosZ)
        spawn_mist(data.obj, 2)
    end
    if dataTable.globalIndex == np.globalIndex then
        cur_obj_play_sound_2(SOUND_GENERAL_COLLECT_1UP)
    end
    djui_popup_create(dataTable.msg, 3)
end

function send_arena_flag(team, globalIndex, msg)
    local dataTable = {
        id = PACKET_ARENA_FLAG,
        team = team,
        globalIndex = globalIndex,
        msg = msg
    }
    network_send(true, dataTable)
    on_packet_arena_flag_receive(dataTable)
end

-------------

function on_packet_arena_vote_entries_receive(dataTable)
    sVoteEntries = {}
    for i = 1, 3 do
        sVoteEntries[i] = { level = dataTable["level" .. i], gamemode = dataTable["gamemode" .. i] }
    end
end

function send_arena_vote_entries(voteEntries)
    local dataTable = {
        id = PACKET_ARENA_VOTE_ENTRIES,
        level1 = voteEntries[1].level, gamemode1 = voteEntries[1].gamemode,
        level2 = voteEntries[2].level, gamemode2 = voteEntries[2].gamemode,
        level3 = voteEntries[3].level, gamemode3 = voteEntries[3].gamemode,
    }
    network_send(true, dataTable)
end

-------------

sPacketTable = {
    [PACKET_ARENA_DEATH]        = on_packet_arena_death_receive,
    [PACKET_ARENA_HAMMER_HIT]   = on_packet_arena_hammer_hit_receive,
    [PACKET_ARENA_RESPAWN]      = on_packet_arena_respawn_receive,
    [PACKET_ARENA_FLAG]         = on_packet_arena_flag_receive,
    [PACKET_ARENA_VOTE_ENTRIES] = on_packet_arena_vote_entries_receive,
}

function on_packet_receive(dataTable)
    if sPacketTable[dataTable.id] ~= nil then
        sPacketTable[dataTable.id](dataTable)
    end
end

hook_event(HOOK_ON_PACKET_RECEIVE, on_packet_receive)
