# Adding a level

`add_level(levelNum, levelName, levelAuthor, previewImage?)`

The level number is the number that `level_register` gives you. A `previewImage` is the texture info for that image. You get that with `get_texture_info`. It may be `nil`.

### Adding level data

`add_level_data(level, data)`

The `level` paramater is your level index the `add_level` function returns. The `data` paramater is a table that contains other data you want to change about your level.

Valid data to be changed:

```lua
--- @class ArenaLevel
--- @field level               LevelNum|integer
--- @field name                string
--- @field author              string
--- @field previewImage        TextureInfo?
--- @field minTeams            integer?
--- @field maxTeams            integer?
--- @field compatibleGamemodes table
--- @field bgm                 ArenaBGM?
```

You can change any of these fields by having the key as the field name, and value as the value.

#### Arena Background Music, and Gamemodes

The arena background music class for `bgm` looks like this

```lua
--- @class ArenaBGM
--- @field audio               string
--- @field name                string
--- @field volume              number?
--- @field loopStart           integer?
--- @field loopEnd             integer?
```

The gamemodes for `compatibleGamemodes` looks like this. Note, for your mod, you can either copy and paste these in to your mod, or use the numbers directly in the table.

```
GAME_MODE_DM    = 1
GAME_MODE_TDM   = 2
GAME_MODE_CTF   = 3
GAME_MODE_FT    = 4
GAME_MODE_TFT   = 5
GAME_MODE_KOTH  = 6
GAME_MODE_TKOTH = 7
GAME_MODE_COUNT = 7
```

### Examples

Here's is an example usecase of adding a level to arena:

```lua
ARENA_EXAMPLE_LEVEL = level_register('level_example_entry', COURSE_NONE, 'Example', 'example', 28000, 0x08, 0x08, 0x08)

local levelAdded
function on_level_init()
    if levelAdded then return end
    local L_EXAMPLE = Arena.add_level(ARENA_EXAMPLE_LEVEL, "Example", "EmeraldLockdown", get_texture_info("example_preview_image"))
    Arena.add_level_data(L_EXAMPLE, {
        minTeams = 3,
        maxTeams = 4,
        compatibleGamemodes = {
            Arena.GAME_MODE_CTF,
            Arena.GAME_MODE_FT,
            Arena.GAME_MODE_TFT
        },
        bgm = {
            audio = "rock.ogg",
            loopStart = 445434,
            loopEnd = 2762459,
            name = "Bowser's Castle - Mario Kart World"
        }
    })
    levelAdded = true
end

hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
```
