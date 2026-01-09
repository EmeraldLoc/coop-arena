
--- @class ArenaBGM
--- @field audio               string
--- @field name                string
--- @field volume              number?
--- @field loopStart           integer?
--- @field loopEnd             integer?
--- @field stream              ModAudio

--- @class ArenaLevel
--- @field level               LevelNum|integer
--- @field name                string
--- @field author              string
--- @field previewImage        TextureInfo?
--- @field minTeams            integer?
--- @field maxTeams            integer?
--- @field compatibleGamemodes table
--- @field bgm                 ArenaBGM?
--- @field overrideKothRing    integer?
--- @field overrideTeamFlags   table?

--- @class ArenaHook
--- @field hookEvent LuaHookedEventType
--- @field func function

--- @class ArenaItem
--- @field model ModelExtendedId
--- @field pitchOffset number
--- @field scale number
--- @field billboard boolean
--- @field updateAnimState boolean
--- @field timeout number
--- @field customCollectFunc function?
--- @field constantHooks ArenaHook[]?
--- @field activeHooks ArenaHook[]?

--- @class ArenaItemHeld
--- @field heldModel ModelExtendedId
--- @field updateAnimState boolean
--- @field billboard boolean
--- @field scale number
--- @field attachment integer
--- @field yawOffset number
--- @field pitchOffset number
--- @field yOffset number
--- @field forwardOffset number
--- @field renderAdjust function?