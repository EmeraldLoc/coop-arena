MAX_PLAYERS = gServerSettings.maxPlayers

ITEM_NONE        = 0
ITEM_METAL_CAP   = 1
ITEM_HAMMER      = 2
ITEM_FIRE_FLOWER = 3
ITEM_CANNON_BOX  = 4
ITEM_BOBOMB      = 5
ITEM_COIN        = 6
ITEM_MAX         = 7

E_MODEL_HAMMER        = smlua_model_util_get_id("hammer_geo")
E_MODEL_FIRE_FLOWER   = smlua_model_util_get_id("fire_flower_geo")
E_MODEL_CANNON_BOX    = smlua_model_util_get_id("cannon_box_geo")
E_MODEL_CANNON_BALL   = smlua_model_util_get_id("arena_ball_geo")
E_MODEL_FLAG_RED      = smlua_model_util_get_id("arena_flag_red_geo")
E_MODEL_FLAG_BLUE     = smlua_model_util_get_id("arena_flag_blue_geo")
E_MODEL_FLAG_GREEN    = smlua_model_util_get_id("arena_flag_green_geo")
E_MODEL_FLAG_YELLOW   = smlua_model_util_get_id("arena_flag_yellow_geo")
E_MODEL_FLAG_WHITE    = smlua_model_util_get_id("arena_flag_white_geo")
E_MODEL_KOTH          = smlua_model_util_get_id("koth_geo")
E_MODEL_SPRING_TOP    = smlua_model_util_get_id("spring_top_geo")
E_MODEL_SPRING_BOTTOM = smlua_model_util_get_id("spring_bottom_geo")

TEX_FLAG = get_texture_info('arena-flag')
TEX_KOTH = get_texture_info('arena-koth')
TEX_RANDOM_LEVEL = get_texture_info("random_level")
TEX_REDO_LEVEL = get_texture_info("redo_level")
TEX_NO_IMAGE = get_texture_info("no_image")

TEAM_SPECTATOR   = -1
TEAM_NONE        =  0
TEAM_RED         =  1
TEAM_BLUE        =  2
TEAM_GREEN       =  3
TEAM_YELLOW      =  4
TEAM_COUNT       = 4
TEAM_COLORS      = {
    [TEAM_NONE] = { r = 255, g = 255, b = 255 },
    [TEAM_RED] = { r = 255, g = 63, b = 39 },
    [TEAM_BLUE] = { r = 39, g = 149, b = 255 },
    [TEAM_GREEN] = { r = 14, g = 152, b = 18 },
    [TEAM_YELLOW] = { r = 255, g = 200, b = 0 },
}
TEAM_TEXT_COLORS = {
    [TEAM_NONE] = { r = 220, g = 220, b = 220 },
    [TEAM_RED] = { r = 255, g = 120, b = 120 },
    [TEAM_BLUE] = { r = 120, g = 120, b = 255 },
    [TEAM_GREEN] = { r = 120, g = 255, b = 120 },
    [TEAM_YELLOW] = { r = 255, g = 255, b = 0 },
}
VOTE_ID_REDO = 1
VOTE_ID_RANDOM = 5