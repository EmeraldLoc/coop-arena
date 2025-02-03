#include "src/game/envfx_snow.h"

const GeoLayout arena_flag_yellow_geo[] = {
	GEO_NODE_START(),
	GEO_OPEN_NODE(),
		GEO_DISPLAY_LIST(LAYER_OPAQUE, arena_flag_yellow_yellow_flag_mesh_layer_1),
	GEO_CLOSE_NODE(),
	GEO_END(),
};
