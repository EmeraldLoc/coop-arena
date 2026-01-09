#include "src/game/envfx_snow.h"

const GeoLayout boomerang_geo[] = {
	GEO_NODE_START(),
	GEO_OPEN_NODE(),
		GEO_ASM(LAYER_OPAQUE + 3, geo_mario_set_player_colors),
		GEO_DISPLAY_LIST(LAYER_OPAQUE, boomerang_Inst3D27_RefRep_003_mesh_layer_1),
	GEO_CLOSE_NODE(),
	GEO_END(),
};
