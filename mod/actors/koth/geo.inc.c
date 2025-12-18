#include "src/game/envfx_snow.h"

const GeoLayout koth_Bone_opt1[] = {
	GEO_NODE_START(),
	GEO_OPEN_NODE(),
		GEO_DISPLAY_LIST(LAYER_ALPHA, koth_Cylinder_mesh_layer_4),
		GEO_DISPLAY_LIST(LAYER_ALPHA, koth_material_revert_render_settings),
	GEO_CLOSE_NODE(),
	GEO_RETURN(),
};
const GeoLayout koth_Bone_opt2[] = {
	GEO_NODE_START(),
    GEO_OPEN_NODE(),
        GEO_ASM(LAYER_ALPHA + 3, geo_mario_set_player_colors),
        GEO_DISPLAY_LIST(LAYER_ALPHA, koth_active_Cylinder_mesh_layer_4),
        GEO_DISPLAY_LIST(LAYER_ALPHA, koth_active_material_revert_render_settings),
    GEO_CLOSE_NODE(),
	GEO_RETURN(),
};
const GeoLayout koth_geo[] = {
	GEO_NODE_START(),
	GEO_OPEN_NODE(),
		GEO_SWITCH_CASE(3, geo_switch_anim_state),
		GEO_OPEN_NODE(),
			GEO_NODE_START(),
			/*GEO_OPEN_NODE(),
				GEO_DISPLAY_LIST(LAYER_ALPHA, koth_Cylinder_mesh_layer_4),
				GEO_DISPLAY_LIST(LAYER_ALPHA, koth_material_revert_render_settings),
			GEO_CLOSE_NODE(),*/
			GEO_BRANCH(1, koth_Bone_opt1),
			GEO_BRANCH(1, koth_Bone_opt2),
		GEO_CLOSE_NODE(),
	GEO_CLOSE_NODE(),
	GEO_END(),
};
