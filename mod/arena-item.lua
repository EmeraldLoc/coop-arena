local arenaItemTimeout = 30 * 15 -- 15 seconds

-----------------

define_custom_obj_fields({
    oArenaItemType = 'u32',
    oArenaItemTouched = 'u32',
})

function bhv_arena_item_init(obj)
    obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    obj.oOpacity = 255
    obj.oArenaItemType = (obj.oBehParams >> 24) % ITEM_MAX

    -- update pallet
    obj.globalPlayerIndex = gNetworkPlayers[0].globalIndex

    local data = gItemData[obj.oArenaItemType]
    obj_scale(obj, data.scale)

    network_init_object(obj, false, {
        'oArenaItemType',
        'oArenaItemTouched',
        'oTimer'
    })
end

function bhv_arena_item_collect(obj)
    spawn_sparkles(obj.oPosX, obj.oPosY, obj.oPosZ)
    spawn_mist(obj, 2)
    obj.oArenaItemTouched = 1
    obj.oTimer = 0
    network_send_object(obj, true)

    cur_obj_play_sound_2(SOUND_GENERAL_COLLECT_1UP)

    local s = gPlayerSyncTable[0]
    s.charging = 0
    s.ammo = 5
    s.item = obj.oArenaItemType
end

function bhv_arena_item_collect_metal_cap(obj)
    spawn_sparkles(obj.oPosX, obj.oPosY, obj.oPosZ)
    spawn_mist(obj, 2)
    obj.oArenaItemTouched = 1
    obj.oTimer = 0
    network_send_object(obj, true)

    local m = gMarioStates[0]
    m.flags = m.flags & (~MARIO_CAP_ON_HEAD & ~MARIO_CAP_IN_HAND)

    local capTime = 600 * 2.5
    local capMusic = SEQUENCE_ARGS(4, SEQ_EVENT_METAL_CAP)

    if capTime > m.capTimer then
        m.capTimer = capTime
    end

    m.flags = m.flags | MARIO_CAP_ON_HEAD

    play_sound(SOUND_MENU_STAR_SOUND, gGlobalSoundSource)
    play_character_sound(m, CHAR_SOUND_HERE_WE_GO)

    play_cap_music(capMusic)
end

function bhv_arena_item_collect_coin(obj)
    spawn_sparkles(obj.oPosX, obj.oPosY, obj.oPosZ)
    spawn_mist(obj, 2)
    obj.oArenaItemTouched = 1
    obj.oTimer = 0
    network_send_object(obj, true)

    cur_obj_play_sound_2(SOUND_GENERAL_COIN)

    local m = gMarioStates[0]
    m.numCoins = m.numCoins + 1
    m.healCounter = m.healCounter + 8
end

function bhv_arena_item_update_touch(obj)
    local data = gItemData[obj.oArenaItemType]
    if obj.oArenaItemTouched == 1 then
        if obj.oTimer >= data.timeout then
            obj.oArenaItemTouched = 0
            if network_is_server() then
                network_send_object(obj, true)
            end
        elseif obj.oTimer < 5 then
            obj_scale(obj, data.scale - (obj.oTimer / 5))
        elseif obj.oTimer >= data.timeout - 10 then
            obj_scale(obj, (obj.oTimer - (data.timeout - 10)) / 10)
            cur_obj_unhide()
        else
            cur_obj_hide()
        end
        return true
    else
        obj_scale(obj, data.scale)
        cur_obj_unhide()
        return false
    end
end

function bhv_arena_item_update_model(obj)
    local data = gItemData[obj.oArenaItemType]
    if data == nil then return end

    obj_set_model_extended(obj, data.model)
    obj.oFaceAnglePitch = data.pitchOffset

    if data.billboard then
        obj.header.gfx.node.flags = obj.header.gfx.node.flags | GRAPH_RENDER_BILLBOARD
    else
        obj.header.gfx.node.flags = obj.header.gfx.node.flags & ~GRAPH_RENDER_BILLBOARD
    end

    if data.animations ~= nil then
        obj.oAnimations = data.animations
        cur_obj_init_animation(data.animationIndex)
    else
        obj.oAnimations = nil
    end

    if data.updateAnimState then
        obj.oAnimState = obj.oAnimState + 1
    end
end

function bhv_arena_item_update_rotation(obj)
    obj.oFaceAngleYaw   = obj.oFaceAngleYaw + 600
    obj.oFaceAngleRoll  = 0
    obj.oFaceAnglePitch = 0
end

function bhv_arena_item_check_collect(obj)
    local m = nearest_mario_state_to_object(obj)
    local data = gItemData[obj.oArenaItemType]
    if m == gMarioStates[0] then
        local s = gPlayerSyncTable[0]
        local player = m.marioObj
        local yDist = math.abs(obj.oPosY - player.oPosY)
        local xzDist = math.sqrt((obj.oPosX - player.oPosX) ^ 2 + (obj.oPosZ - player.oPosZ) ^ 2)
        if xzDist < 160 and yDist < 250 and s.team ~= TEAM_SPECTATOR then
            if data and data.customCollectFunc then
                data.customCollectFunc(obj)
            elseif s.item == ITEM_NONE then
                bhv_arena_item_collect(obj)
            end
        end
    end
end

function bhv_arena_item_loop(obj)
    -- update touch
    if bhv_arena_item_update_touch(obj) then
        return
    end

    -- update model
    bhv_arena_item_update_model(obj)

    -- update rotation
    bhv_arena_item_update_rotation(obj)

    -- see if player touched
    bhv_arena_item_check_collect(obj)
end

id_bhvArenaItem = hook_behavior(nil, OBJ_LIST_DEFAULT, true, bhv_arena_item_init, bhv_arena_item_loop)

-----------------

---@type table<integer, ArenaItem>
gItemData = {
    [ITEM_NONE] = {
        model = E_MODEL_NONE,
        pitchOffset = 0,
        scale = 1,
        billboard = false,
        updateAnimState = false,
        timeout = arenaItemTimeout,
        customCollectFunc = nil,
        constantHooks = nil,
        activeHooks = nil,
    },
    [ITEM_METAL_CAP] = {
        model = E_MODEL_MARIOS_METAL_CAP,
        pitchOffset = 0,
        scale = 2,
        billboard = false,
        updateAnimState = false,
        timeout = arenaItemTimeout * 5,
        customCollectFunc = bhv_arena_item_collect_metal_cap,
        constantHooks = nil,
        activeHooks = nil,
    },
    [ITEM_HAMMER] = {
        model = E_MODEL_HAMMER,
        pitchOffset = 0x2000,
        scale = 1,
        billboard = false,
        updateAnimState = false,
        timeout = arenaItemTimeout,
        customCollectFunc = nil,
        constantHooks = {
            {
                hookEvent = HOOK_MARIO_UPDATE,
                func = mario_local_hammer_check,
            },
            {
                hookEvent = HOOK_MARIO_UPDATE,
                func = mario_hammer_update
            }
        },
        activeHooks = {
            {
                hookEvent = HOOK_ON_SET_MARIO_ACTION,
                func = mario_hammer_on_set_action
            }
        }
    },
    [ITEM_FIRE_FLOWER] = {
        model = E_MODEL_FIRE_FLOWER,
        pitchOffset = 0,
        scale = 1,
        billboard = false,
        updateAnimState = false,
        timeout = arenaItemTimeout,
        customCollectFunc = nil,
        constantHooks = nil,
        activeHooks = {
            {
                hookEvent = HOOK_MARIO_UPDATE,
                func = fire_flower_update
            }
        },
    },
    [ITEM_CANNON_BOX] = {
        model = E_MODEL_CANNON_BOX,
        pitchOffset = 0,
        scale = 1,
        billboard = false,
        updateAnimState = false,
        timeout = arenaItemTimeout,
        customCollectFunc = nil,
        constantHooks = {
            {
                hookEvent = HOOK_MARIO_UPDATE,
                func = mario_cannon_box_update
            }
        },
        activeHooks = nil,
    },
    [ITEM_BOBOMB] = {
        model = E_MODEL_BLACK_BOBOMB,
        pitchOffset = 0,
        animations = gObjectAnimations.bobomb_seg8_anims_0802396C,
        animationIndex = 0,
        scale = 1,
        billboard = false,
        updateAnimState = false,
        timeout = arenaItemTimeout,
        customCollectFunc = nil,
        constantHooks = nil,
        activeHooks = {
            {
                hookEvent = HOOK_MARIO_UPDATE,
                func = bobomb_update
            }
        },
    },
    [ITEM_COIN] = {
        model = E_MODEL_YELLOW_COIN,
        pitchOffset = 0,
        scale = 1,
        billboard = true,
        updateAnimState = true,
        timeout = arenaItemTimeout,
        customCollectFunc = bhv_arena_item_collect_coin,
        constantHooks = nil,
        activeHooks = nil,
    },
}

-- hook up the events
function on_mods_loaded()
    for key, item in pairs(gItemData) do
        if item.constantHooks then
            for _, hook in pairs(item.constantHooks) do
                hook_event(hook.hookEvent, hook.func)
            end
        end

        if item.activeHooks then
            for _, hook in pairs(item.activeHooks) do
                hook_event(hook.hookEvent, function (...)
                    if gPlayerSyncTable[0].item == key then
                        hook.func(...)
                    end
                end)
            end
        end
    end
end

hook_event(HOOK_ON_MODS_LOADED, on_mods_loaded)
