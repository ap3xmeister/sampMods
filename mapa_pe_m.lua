--[[
    Mapa pe M v1.3
    Author: Tibi - moduri.ro
    
    Fast map overlay with optional GPS line.
    Hold M (or configured key) to enlarge map.
    
    Commands:
      /gpsm - Toggle GPS
      /gpsmap - Settings
    Keys:
      M - Hold to enlarge map
]]

script_name("Mapa pe M")
script_author("Tibi - moduri.ro")
script_version("1.3")

require "lib.moonloader"

local imgui = require "imgui"
imgui.ShowCursor = false  -- MUST be set immediately after loading imgui to prevent cursor on first display
local RakLua = require 'RakLua'
print("RakLua loaded:", RakLua ~= nil)
print("RakLuaEvents:", RakLuaEvents)
print("registerHandler:", RakLua and RakLua.registerHandler)
RakLua.defineSampLuaCompatibility()
local memory = require "memory"
local sampev = require 'samp.events'
local inicfg = require 'inicfg'
local raknet = require 'samp.raknet'

local bit = require 'bit'  -- For gang zone color conversion

-- GPS pathfinding library
local json = require "gps_lib.json"
local Grid = require("gps_lib.grid")
local Pathfinder = require("gps_lib.pathfinder")

-- Resource folder
local RESOURCE_PATH = getWorkingDirectory() .. "\\resource\\mapa_pe_m\\"

-- Config
local CONFIG_FILE = "gps_map_settings"
local DEFAULT_CONFIG = {
    settings = {
        enabled = true,
        useRoadRoute = false,
        autoShowMinimap = true,
        lineColorIndex = 2,  -- 0=Red, 1=Blue, 2=Green (default)
        arrowColorIndex = 4,  -- 0=Red, 1=Blue, 2=Green, 3=Yellow, 4=Purple-Pink (default), 5=Orange, 6=Cyan, 7=White
        mapKeyIndex = 0,
        hideMessages = false,
        centerEnlargedMap = false,
        enlargedMapSize = 0,  -- 0=60%, 1=70%, 2=80%, 3=90%
        mapOpacity = 100,  -- 0-100%
        mapStyle = 0,  -- 0=Default, 1=SA Style, 2=3D Style
        showGangZones = true  -- Show gang zones/turfs on map
    }
}

local config = inicfg.load(DEFAULT_CONFIG, CONFIG_FILE)
if not config then
    config = DEFAULT_CONFIG
end

local function saveConfig()
    inicfg.save(config, CONFIG_FILE)
end

-- GTA V Style Theme Colors (matching AutoReconnect)
local GTAV_YELLOW = imgui.ImVec4(0.96, 0.76, 0.07, 1.0)
local GTAV_YELLOW_DARK = imgui.ImVec4(0.85, 0.65, 0.05, 1.0)
local GTAV_BG_DARK = imgui.ImVec4(0.08, 0.08, 0.10, 0.97)
local GTAV_BG_PANEL = imgui.ImVec4(0.12, 0.12, 0.14, 0.95)
local GTAV_BG_ITEM = imgui.ImVec4(0.16, 0.16, 0.18, 1.0)
local GTAV_BG_HOVER = imgui.ImVec4(0.22, 0.22, 0.24, 1.0)
local GTAV_TEXT = imgui.ImVec4(0.95, 0.95, 0.95, 1.0)
local GTAV_TEXT_DIM = imgui.ImVec4(0.60, 0.60, 0.62, 1.0)
local GTAV_BORDER = imgui.ImVec4(0.25, 0.25, 0.28, 0.60)
local GTAV_ORANGE = imgui.ImVec4(1.0, 0.5, 0.0, 1.0)
local GTAV_GREEN = imgui.ImVec4(0.30, 0.85, 0.40, 1.0)

local function applyGTAVTheme()
    imgui.PushStyleVar(imgui.StyleVar.WindowRounding, 0.0)
    imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 4.0)
    imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(20, 15))
    imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(10, 8))
    imgui.PushStyleVar(imgui.StyleVar.FramePadding, imgui.ImVec2(8, 8))
    
    imgui.PushStyleColor(imgui.Col.WindowBg, GTAV_BG_DARK)
    imgui.PushStyleColor(imgui.Col.TitleBg, GTAV_BG_PANEL)
    imgui.PushStyleColor(imgui.Col.TitleBgActive, GTAV_BG_PANEL)
    imgui.PushStyleColor(imgui.Col.TitleBgCollapsed, GTAV_BG_PANEL)
    imgui.PushStyleColor(imgui.Col.Border, GTAV_BORDER)
    imgui.PushStyleColor(imgui.Col.FrameBg, GTAV_BG_ITEM)
    imgui.PushStyleColor(imgui.Col.FrameBgHovered, GTAV_BG_HOVER)
    imgui.PushStyleColor(imgui.Col.FrameBgActive, GTAV_BG_HOVER)
    imgui.PushStyleColor(imgui.Col.Button, GTAV_BG_ITEM)
    imgui.PushStyleColor(imgui.Col.ButtonHovered, GTAV_YELLOW_DARK)
    imgui.PushStyleColor(imgui.Col.ButtonActive, GTAV_YELLOW)
    imgui.PushStyleColor(imgui.Col.SliderGrab, GTAV_YELLOW)
    imgui.PushStyleColor(imgui.Col.SliderGrabActive, GTAV_YELLOW_DARK)
    imgui.PushStyleColor(imgui.Col.CheckMark, GTAV_YELLOW)
    imgui.PushStyleColor(imgui.Col.Header, GTAV_BG_ITEM)
    imgui.PushStyleColor(imgui.Col.HeaderHovered, GTAV_YELLOW_DARK)
    imgui.PushStyleColor(imgui.Col.HeaderActive, GTAV_YELLOW)
    imgui.PushStyleColor(imgui.Col.Text, GTAV_TEXT)
    imgui.PushStyleColor(imgui.Col.TextDisabled, GTAV_TEXT_DIM)
    imgui.PushStyleColor(imgui.Col.ScrollbarBg, GTAV_BG_PANEL)
    imgui.PushStyleColor(imgui.Col.ScrollbarGrab, GTAV_BG_HOVER)
    imgui.PushStyleColor(imgui.Col.ScrollbarGrabHovered, GTAV_YELLOW_DARK)
    imgui.PushStyleColor(imgui.Col.ScrollbarGrabActive, GTAV_YELLOW)
    imgui.PushStyleColor(imgui.Col.PopupBg, GTAV_BG_PANEL)
end

local function popGTAVTheme()
    imgui.PopStyleColor(24)
    imgui.PopStyleVar(5)
end

-- Map Keys
local MAP_KEYS = {
    { name = "M", code = 0x4D },
    { name = "E", code = 0x45 },
    { name = "Z", code = 0x5A },
    { name = "X", code = 0x58 },
    { name = "C", code = 0x43 },
    { name = "V", code = 0x56 },
    { name = "B", code = 0x42 },
    { name = "N", code = 0x4E },
    { name = "Tab", code = 0x09 },
    { name = "CapsLock", code = 0x14 }
}

-- State
local window_state = imgui.ImBool(false)
local settingsWindow = imgui.ImBool(false)
local enlargedMode = false
local checkpoint = { active = false, x = 0, y = 0, z = 0 }
local raceCheckpoint = { active = false, x = 0, y = 0, z = 0 }
local displayPath = {}  -- Path currently being displayed
local map = nil
local RadarX, RadarY, RadarSize
local lastCalcTime = 0
local calculating = false
local gangZones = {}  -- Store gang zones: gangZones[id] = {minX, minY, maxX, maxY, color, flashing, flashColor}
local debugRadarDump
local readBlips
local questMarkersEnabled = false
local allBlips = {}
function main()
    -- IMMEDIATELY set cursor to hidden before ANYTHING else
    -- This must happen before imgui.Process becomes true for the first time
    imgui.ShowCursor = false
    
    repeat wait(0) until isSampAvailable()
    
    -- Load textures
    map_img = imgui.CreateTextureFromFile(RESOURCE_PATH .. "map.png")
    mapsa_img = imgui.CreateTextureFromFile(RESOURCE_PATH .. "mapsa.png")
    map3d_img = imgui.CreateTextureFromFile(RESOURCE_PATH .. "map3d.png")
    cursor_img = imgui.CreateTextureFromFile(RESOURCE_PATH .. "cursor.png")
    marker_img = imgui.CreateTextureFromFile(RESOURCE_PATH .. "marker.png")

    local iconDir = RESOURCE_PATH .. "radar\\"
    radar_icons = {}
    local testFile = io.open(iconDir .. "radar_police.png", "rb")
    if testFile then
        testFile:close()
        -- Icons already extracted, just load them
        local RADAR_ICON_NAMES = {
            [2]  = "radar_centre",         -- Player Position
            [3]  = "radar_north",          -- Map player on big map is usually not needed as texture
            [4]  = "radar_north",

            [5]  = "radar_airYard",
            [6]  = "radar_ammugun",
            [7]  = "radar_barbers",
            [8]  = "radar_BIGSMOKE",
            [9]  = "radar_boatyard",
            [10] = "radar_burgerShot",
            [11] = "radar_bulldozer",      -- Quarry
            [12] = "radar_CATALINA",
            [13] = "radar_CESARVIAPANDO",
            [14] = "radar_chicken",
            [15] = "radar_CJ",
            [16] = "radar_crash1",
            [17] = "radar_diner",
            [18] = "radar_emmetGun",
            [19] = "radar_enemyAttack",
            [20] = "radar_fire",
            [21] = "radar_girlfriend",
            [22] = "radar_hostpital",
            [23] = "radar_LocoSyndicate",
            [24] = "radar_MADDOG",
            [25] = "radar_mafiaCasino",
            [26] = "radar_MCSTRAP",
            [27] = "radar_modGarage",
            [28] = "radar_OGLOC",
            [29] = "radar_pizza",
            [30] = "radar_police",
            [31] = "radar_propertyG",
            [32] = "radar_propertyR",
            [33] = "radar_race",
            [34] = "radar_RYDER",
            [35] = "radar_saveGame",
            [36] = "radar_school",
            [37] = "radar_qmark",
            [38] = "radar_SWEET",
            [39] = "radar_tattoo",
            [40] = "radar_THETRUTH",
            [41] = "radar_waypoint",
            [42] = "radar_TORENO",
            [43] = "radar_triads",
            [44] = "radar_triadsCasino",
            [45] = "radar_tshirt",
            [46] = "radar_WOOZIE",
            [47] = "radar_ZERO",
            [48] = "radar_club",
            [49] = "radar_dateDrink",
            [50] = "radar_Resturant",
            [51] = "radar_truck",
            [52] = "radar_cash",
            [53] = "radar_flag",
            [54] = "radar_gym",
            [55] = "radar_impound",
            [56] = "radar_light",
            [57] = "radar_runway",
            [58] = "radar_gangB",
            [59] = "radar_gangP",
            [60] = "radar_gangY",
            [61] = "radar_gangN",
            [62] = "radar_gangG",
            [63] = "radar_spray"
        }
        for iconId, texName in pairs(RADAR_ICON_NAMES) do
            local path = iconDir .. texName .. ".png"
            local f = io.open(path, "rb")
            if f then
                f:close()
                radar_icons[iconId] = imgui.CreateTextureFromFile(path)
            end
        end
    else
        sampAddChatMessage("{FFFF00}[MMAP] Radar icons not found. Run /txdextract to extract them from hud.txd.", -1)
    end
    
    -- Load map data
    local mapFile = io.open(RESOURCE_PATH .. "map.txt", "r")
    if mapFile then
        map = json.parse(mapFile:read("*a"))
        mapFile:close()
        print("[GPS] Road map loaded")
    else
        sampAddChatMessage("{FF0000}[GPS] {FFFFFF}Error: map.txt not found!", -1)
        return
    end
    
    -- Get radar position
    RadarX = memory.getfloat(0x858A10)
    RadarY = memory.getfloat(0x866B70)
    local RadarWidth = memory.getfloat(0x866B78)
    local RadarHeight = memory.getfloat(0x866B74)
    RadarSize = RadarHeight > RadarWidth and RadarHeight or RadarWidth



    sampRegisterChatCommand("gpsm", function()
        config.settings.enabled = not config.settings.enabled
        saveConfig()
        if not config.settings.hideMessages then
            sampAddChatMessage(config.settings.enabled and "{00FF00}[GPS] {FFFFFF}Enabled." or "{FF6600}[GPS] {FFFFFF}Disabled.", -1)
        end
        if not config.settings.enabled then 
            window_state.v = false
            displayPath = {}
        end
    end)
    sampRegisterChatCommand("gpsmap", function()
        settingsWindow.v = not settingsWindow.v
    end)

    sampRegisterChatCommand("mapreload", function()
        thisScript():reload()
    end)

    sampRegisterChatCommand("txdextract", function()

        -- Also scan modloader subfolders
        local hudPath = nil
        for _, p in ipairs(searchPaths) do
            local f = io.open(p, "rb")
            if f then f:close(); hudPath = p; break end
        end

        if not hudPath then
            sampAddChatMessage("{FF0000}[TXD] hud.txd not found! Check paths.", -1)
            return
        end

        sampAddChatMessage("{FFFF00}[TXD] Found: " .. hudPath, -1)
        sampAddChatMessage("{FFFF00}[TXD] Extracting radar icons...", -1)

        local RADAR_ICON_NAMES = {
            [8]  = "radar_airYard",
            [9]  = "radar_ammugun",
            [10] = "radar_barbers",
            [11] = "radar_BIGSMOKE",
            [13] = "radar_burgerShot",
            [14] = "radar_bulldozer",
            [16] = "radar_CJ",
            [17] = "radar_chicken",
            [2]  = "radar_centre",
            [20] = "radar_diner",
            [21] = "radar_emmetGun",
            [22] = "radar_enemyAttack",
            [23] = "radar_fire",
            [24] = "radar_girlfriend",
            [25] = "radar_hostpital",
            [55] = "radar_gangB",
            [58] = "radar_gangN",
            [56] = "radar_gangP",
            [57] = "radar_gangY",
            [26] = "radar_LocoSyndicate",
            [27] = "radar_MADDOG",
            [47] = "radar_mafiaCasino",
            [29] = "radar_MCSTRAP",
            [30] = "radar_modGarage",
            [32] = "radar_north",
            [33] = "radar_police",
            [34] = "radar_propertyG",
            [35] = "radar_propertyR",
            [40] = "radar_qmark",
            [36] = "radar_race",
            [37] = "radar_RYDER",
            [38] = "radar_saveGame",
            [39] = "radar_school",
            [62] = "radar_spray",
            [42] = "radar_SWEET",
            [43] = "radar_tattoo",
            [44] = "radar_THETRUTH",
            [45] = "radar_TORENO",
            [46] = "radar_triads",
            [53] = "radar_triadsCasino",
            [48] = "radar_tshirt",
            [41] = "radar_waypoint",
            [49] = "radar_WOOZIE",
            [50] = "radar_ZERO",
        }

        local txd = loadTextureDictionary("hud.txd")
        if not txd then
            sampAddChatMessage("{FF0000}[TXD] Failed to load TXD!", -1)
            return
        end

        freeTextureDictionary(txd)
    end)

    sampRegisterChatCommand("nearbyblips", function()
        local px, py, pz = getCharCoordinates(PLAYER_PED)
        local blips = readBlips()
        local nearby = {}
        for _, b in ipairs(blips) do
            local dist = math.sqrt((b.x-px)^2+(b.y-py)^2)
            if dist < 100 then
                table.insert(nearby, {blip=b, dist=dist})
            end
        end
        table.sort(nearby, function(a,b) return a.dist < b.dist end)
        sampAddChatMessage(string.format("{00FF00}[BLIPS] %d blips within 100 units:", #nearby), -1)
        for i, entry in ipairs(nearby) do
            local b = entry.blip
            local flags = {}
            if b.icon == 0 then table.insert(flags, "type0") end
            if b.icon == 0 and b.colorId == 4294902015 then table.insert(flags, "pizza?") end
            if b.icon == 0 and b.colorId == 4277707519 then table.insert(flags, "tow?") end
            if b.icon == 41 then table.insert(flags, "waypoint") end
            if b.icon == 1 then table.insert(flags, "square") end

            local flagText = (#flags > 0) and table.concat(flags, ",") or "-"
            sampAddChatMessage(string.format(
            "[%03d] icon=%d color=%u b1C=%s x=%.1f y=%.1f z=%.1f dist=%.0f flags=%s",
                b.index or -1,
                b.icon or -1,
                b.colorId or 0,
                tostring(b.b1C),
                b.x or 0,
                b.y or 0,
                b.z or 0,
                entry.dist,
                flagText
            ), -1)
            if i >= 15 then
                sampAddChatMessage("{FFFF00}limited to 15.", -1)
                break
            end
        end
    end)

    sampRegisterChatCommand("icondbg", function()
        -- SA-MP map icons: base 0xBA86F0 + 0x1400 offset, 32 slots, each 0x28 bytes
        -- Also try the player map icon array at known GTA SA addresses
        local bases = {
            {addr = 0xBA86F0 + 0x1400, name = "SAMP_ICONS"},  -- after radar traces
            {addr = 0x58A4E8, name = "GTA_MAPICONS"},          -- GTA SA map icon pool
        }
        for _, base in ipairs(bases) do
            sampAddChatMessage("{00FF00}[ICONDBG] scanning " .. base.name, -1)
            local found = 0
            for i = 0, 31 do
                local addr = base.addr + i * 0x28
                local x = memory.getfloat(addr + 0x08, true)
                local y = memory.getfloat(addr + 0x0C, true)
                local z = memory.getfloat(addr + 0x10, true)
                local b0 = memory.getuint8(addr + 0x00, true)
                local b24 = memory.getuint8(addr + 0x24, true)
                if math.abs(x) <= 3000 and math.abs(y) <= 3000 and not (x == 0 and y == 0) then
                    sampAddChatMessage(string.format("[ICONDBG] [%d] xyz(%.1f %.1f %.1f) b0=%d b24=%d", i, x, y, z, b0, b24), -1)
                    found = found + 1
                end
            end
            sampAddChatMessage(string.format("[ICONDBG] found %d in %s", found, base.name), -1)
        end
        -- Also try sampGetPlayerMapIcon if available
        sampAddChatMessage("{FFFF00}[ICONDBG] trying sampGetMapIcons...", -1)
        for i = 0, 99 do
            local ok, x, y, z, icon, color = pcall(sampGetMapIcon, i)
            if ok and x and math.abs(x) <= 3000 then
                sampAddChatMessage(string.format("[ICONDBG] icon[%d] xyz(%.1f %.1f %.1f) type=%d color=%d", i, x, y, z, icon or 0, color or 0), -1)
            end
        end
    end)

    sampRegisterChatCommand("pickupdbg", function()
        local PICKUP_BASE = 0xC3CE10
        local PICKUP_SIZE = 0x14
        local MAX_PICKUPS = 4096
        local count = 0
        local px, py, pz = getCharCoordinates(PLAYER_PED)
        sampAddChatMessage("{00FF00}[PICKUPDBG] scanning near player...", -1)
        for i = 0, MAX_PICKUPS - 1 do
            local addr = PICKUP_BASE + i * PICKUP_SIZE
            local modelId = memory.getuint32(addr + 0x00, true)
            local ptype   = memory.getuint32(addr + 0x04, true)
            local x = memory.getfloat(addr + 0x08, true)
            local y = memory.getfloat(addr + 0x0C, true)
            local z = memory.getfloat(addr + 0x10, true)
            if modelId > 0 and modelId < 20000 and math.abs(x) <= 3000 and math.abs(y) <= 3000 then
                local dist = math.sqrt((x-px)^2 + (y-py)^2)
                if dist < 300 then
                    sampAddChatMessage(string.format("[PICKUP] [%d] model=%d type=%d xyz(%.1f %.1f %.1f) dist=%.0f",
                        i, modelId, ptype, x, y, z, dist), -1)
                    count = count + 1
                    if count >= 20 then
                        sampAddChatMessage("{FFFF00}[PICKUPDBG] limited to 20.", -1)
                        return
                    end
                end
            end
        end
        sampAddChatMessage(string.format("{00FF00}[PICKUPDBG] found %d within 300 units.", count), -1)
    end)

    sampRegisterChatCommand("objectdbg", function()
        local px, py, pz = getCharCoordinates(PLAYER_PED)
        local count = 0
        sampAddChatMessage("{00FF00}[OBJECTDBG] scanning SAMP objects...", -1)
        for i = 0, 999 do
            local exists, x, y, z = false, 0, 0, 0
            local ok = pcall(function()
                local ex, ox, oy, oz = sampGetObjectPos(i)
                exists, x, y, z = ex, ox, oy, oz
            end)
            if ok and exists and math.abs(x) <= 3000 and math.abs(y) <= 3000 then
                local dist = math.sqrt((x-px)^2 + (y-py)^2)
                if dist < 300 then
                    local model = 0
                    pcall(function() model = sampGetObjectModel(i) end)
                    sampAddChatMessage(string.format("[OBJ] id=%d model=%d xyz(%.1f %.1f %.1f) dist=%.0f",
                        i, model, x, y, z, dist), -1)
                    count = count + 1
                    if count >= 20 then
                        sampAddChatMessage("{FFFF00}[OBJECTDBG] limited to 20.", -1)
                        return
                    end
                end
            end
        end
        sampAddChatMessage(string.format("{00FF00}[OBJECTDBG] found %d within 300 units.", count), -1)
    end)

    sampRegisterChatCommand("blipdbg", function()
        local RADAR_BASE = 0xBA86F0
        local RADAR_SIZE = 0x28
        local MAX_RADAR_TRACES = 175
        local px, py, pz = getCharCoordinates(PLAYER_PED)
        sampAddChatMessage("{00FF00}[BLIPDBG] showing nearby icon=0 blips, all bytes...", -1)
        local count = 0
        for i = 0, MAX_RADAR_TRACES - 1 do
            local addr = RADAR_BASE + i * RADAR_SIZE
            local x = memory.getfloat(addr + 0x08, true)
            local y = memory.getfloat(addr + 0x0C, true)
            local z = memory.getfloat(addr + 0x10, true)
            local icon = memory.getuint8(addr + 0x24, true)
            local colorId = memory.getuint32(addr + 0x00, true)
            if icon == 0 and colorId == 4294967295 and math.abs(x) <= 3000 and math.abs(y) <= 3000 and not (x==0 and y==0) then
                local dist = math.sqrt((x-px)^2+(y-py)^2)
                if dist < 200 then
                    local b14 = memory.getuint8(addr+0x14,true)
                    local b15 = memory.getuint8(addr+0x15,true)
                    local b16 = memory.getuint8(addr+0x16,true)
                    local b17 = memory.getuint8(addr+0x17,true)
                    local b18 = memory.getuint8(addr+0x18,true)
                    local b19 = memory.getuint8(addr+0x19,true)
                    local b1A = memory.getuint8(addr+0x1A,true)
                    local b1B = memory.getuint8(addr+0x1B,true)
                    local b1C = memory.getuint8(addr+0x1C,true)
                    local b1D = memory.getuint8(addr+0x1D,true)
                    local b1E = memory.getuint8(addr+0x1E,true)
                    local b1F = memory.getuint8(addr+0x1F,true)
                    local b20 = memory.getuint8(addr+0x20,true)
                    local b21 = memory.getuint8(addr+0x21,true)
                    local b22 = memory.getuint8(addr+0x22,true)
                    local b23 = memory.getuint8(addr+0x23,true)
                    local b24 = memory.getuint8(addr+0x24,true)
                    local b25 = memory.getuint8(addr+0x25,true)
                    local b26 = memory.getuint8(addr+0x26,true)
                    local b27 = memory.getuint8(addr+0x27,true)
                    sampAddChatMessage(string.format("[%03d] xyz(%.1f %.1f) dist=%.0f", i, x, y, dist), -1)
                    sampAddChatMessage(string.format("  14-1B: %d,%d,%d,%d,%d,%d,%d,%d", b14,b15,b16,b17,b18,b19,b1A,b1B), -1)
                    sampAddChatMessage(string.format("  1C-27: %d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d", b1C,b1D,b1E,b1F,b20,b21,b22,b23,b24,b25,b26,b27), -1)
                    count = count + 1
                    if count >= 5 then
                        sampAddChatMessage("{FFFF00}[BLIPDBG] limited to 5 nearby.", -1)
                        return
                    end
                end
            end
        end
        sampAddChatMessage(string.format("{00FF00}[BLIPDBG] found %d nearby quest blips.", count), -1)
    end)
    
    if not config.settings.hideMessages then
        sampAddChatMessage("{00FF00}[GPS] {FFFFFF}v1.3 loaded! Hold {00FF00}M{FFFFFF} for map. Use /gpsm to toggle, /gpsmap for settings.", -1)
    end
    
    while true do
        wait(0)
        
        -- Map key handling
        if not sampIsChatInputActive() and not sampIsDialogActive() and not isGamePaused() then
            local keyCode = MAP_KEYS[config.settings.mapKeyIndex + 1] and MAP_KEYS[config.settings.mapKeyIndex + 1].code or 0x4D
            enlargedMode = isKeyDown(keyCode)
        else
            enlargedMode = false
        end
        
        -- Window visibility
        local hasCheckpoint = checkpoint.active or raceCheckpoint.active
        local shouldShow = (config.settings.autoShowMinimap and hasCheckpoint) or enlargedMode
        window_state.v = shouldShow and config.settings.enabled
        
        -- Set cursor visibility BEFORE setting Process
        -- Only show cursor when settings window is open
        imgui.ShowCursor = settingsWindow.v
        
        -- Force hide cursor when map is shown but settings is not
        if window_state.v and not settingsWindow.v then
            showCursor(false)
        end
        
        imgui.Process = window_state.v or settingsWindow.v
        
        -- Get current target
        local targetX, targetY = nil, nil
        
        if checkpoint.active then
            targetX, targetY = checkpoint.x, checkpoint.y
        elseif raceCheckpoint.active then
            targetX, targetY = raceCheckpoint.x, raceCheckpoint.y
        else
            local blipRes, blipX, blipY = getTargetBlipCoordinates()
            if blipRes then targetX, targetY = blipX, blipY end
        end
        
        -- If no target, clear path
        if not targetX then
            if #displayPath > 0 then displayPath = {} end
        else
            local Px, Py = getCharCoordinates(PLAYER_PED)
            local playerMapX = Px < 0 and (3000 - math.abs(Px)) or (3000 + Px)
            local playerMapY = Py < 0 and (3000 + math.abs(Py)) or (3000 - Py)
            local targetMapX = targetX < 0 and (3000 - math.abs(targetX)) or (3000 + targetX)
            local targetMapY = targetY < 0 and (3000 + math.abs(targetY)) or (3000 - targetY)
            
            local playerGridX = math.ceil(playerMapX/12)
            local playerGridY = math.ceil(playerMapY/12)
            local targetGridX = math.ceil(targetMapX/12)
            local targetGridY = math.ceil(targetMapY/12)
            
            if config.settings.useRoadRoute then
                -- ROAD ROUTE MODE (A* pathfinding, may lag)
                if not calculating and (os.clock() - lastCalcTime) > 5 then
                    calculating = true
                    lastCalcTime = os.clock()
                    
                    lua_thread.create(function()
                        local ok, result = pcall(function()
                            return get_path(
                                {playerGridX, playerGridY},
                                {targetGridX, targetGridY},
                                map
                            )
                        end)
                        if ok and result and #result > 0 then
                            displayPath = result
                        end
                        calculating = false
                    end)
                end
            else
                -- STRAIGHT LINE MODE (no lag) - default
                local simplePath = {}
                local steps = 20
                for i = 0, steps do
                    local t = i / steps
                    local x = playerGridX + (targetGridX - playerGridX) * t
                    local y = playerGridY + (targetGridY - playerGridY) * t
                    table.insert(simplePath, {x, y})
                end
                displayPath = simplePath
            end
            
            -- Remove passed waypoints from displayPath
            if #displayPath > 0 then
                local Px, Py = getCharCoordinates(PLAYER_PED)
                local playerMapX = Px < 0 and (3000 - math.abs(Px)) or (3000 + Px)
                local playerMapY = Py < 0 and (3000 + math.abs(Py)) or (3000 - Py)
                local playerGridX = playerMapX / 12
                local playerGridY = playerMapY / 12
                
                local distX = math.abs(playerGridX - displayPath[1][1])
                local distY = math.abs(playerGridY - displayPath[1][2])
                if distX < 3 and distY < 3 then
                    table.remove(displayPath, 1)
                end
            end
        end
    end
end








function get_path(start_point, end_point, mapData)
    local function is_trapped(m, x)
        m[x[1]][x[2]] = 1
        local ops = {{0,-1},{0,1},{-1,0},{1,0},{-1,-1},{-1,1},{1,1},{1,-1}}
        local isTrapped = true
        for _, v in ipairs(ops) do
            if (x[1]+v[1]) <= #m and (x[1]+v[1]) >= 1 and (x[2]+v[2]) <= #m[1] and (x[2]+v[2]) >= 1 then
                if m[x[1]+v[1]][x[2]+v[2]] == 1 then isTrapped = false end
            end
        end
        local ops_ratio = 0
        while isTrapped do
            local expandOps = {{0,-1-ops_ratio},{0,1+ops_ratio},{-1-ops_ratio,0},{1+ops_ratio,0},
                              {-1-ops_ratio,-1-ops_ratio},{-1-ops_ratio,1+ops_ratio},{1+ops_ratio,1+ops_ratio},{1+ops_ratio,-1-ops_ratio}}
            local skips = 0
            for _, v in ipairs(expandOps) do
                if (x[1]+v[1]) <= #m and (x[1]+v[1]) >= 1 and (x[2]+v[2]) <= #m[1] and (x[2]+v[2]) >= 1 then
                    if m[x[1]+v[1]][x[2]+v[2]] == 1 then isTrapped = false; break
                    else m[x[1]+v[1]][x[2]+v[2]] = 1 end
                else skips = skips + 1 end
            end
            if skips == 8 then break end
            ops_ratio = ops_ratio + 1
        end
    end
    
    is_trapped(mapData, {start_point[2], start_point[1]})
    is_trapped(mapData, {end_point[2], end_point[1]})
    
    local grid = Grid(mapData)
    local myFinder = Pathfinder(grid, 'ASTAR', 1)
    local path = myFinder:getPath(start_point[1], start_point[2], end_point[1], end_point[2])
    
    local result = {}
    if path then for node in path:nodes() do table.insert(result, {node:getX(), node:getY()}) end end
    return result
end

function rotateVector(vec, ang)
    return {vec[1]*math.cos(ang) - vec[2]*math.sin(ang), vec[1]*math.sin(ang) + vec[2]*math.cos(ang)}
end

function returnAngle()
    local cx, cy = getActiveCameraCoordinates()
    local tx, ty = getActiveCameraPointAt()
    return getHeadingFromVector2d(tx - cx, ty - cy)
end

function ImRotate(v, cos_a, sin_a) return imgui.ImVec2(v.x*cos_a - v.y*sin_a, v.x*sin_a + v.y*cos_a) end
function calcAddImVec2(l, r) return imgui.ImVec2(l.x + r.x, l.y + r.y) end
local function drawFilledTriangle(draw_list, p1, p2, p3, fillColor, outlineColor)
    draw_list:AddTriangleFilled(p1, p2, p3, outlineColor)
    local cx = (p1.x + p2.x + p3.x) / 3
    local cy = (p1.y + p2.y + p3.y) / 3

    local function inset(p, s)
        return imgui.ImVec2(
            p.x + (cx - p.x) * s,
            p.y + (cy - p.y) * s
        )
    end

    draw_list:AddTriangleFilled(
        inset(p1, 0.12),
        inset(p2, 0.12),
        inset(p3, 0.12),
        fillColor
    )
end

local function drawMarkerType0(draw_list, pos, size, dz, fillColor, outlineColor)
    local sameLevelThreshold = 3.0

    if dz > sameLevelThreshold then
        local p1 = imgui.ImVec2(pos.x, pos.y - size)
        local p2 = imgui.ImVec2(pos.x - size * 0.85, pos.y + size * 0.75)
        local p3 = imgui.ImVec2(pos.x + size * 0.85, pos.y + size * 0.75)
        drawFilledTriangle(draw_list, p1, p2, p3, fillColor, outlineColor)
    elseif dz < -sameLevelThreshold then
        local p1 = imgui.ImVec2(pos.x, pos.y + size)
        local p2 = imgui.ImVec2(pos.x - size * 0.85, pos.y - size * 0.75)
        local p3 = imgui.ImVec2(pos.x + size * 0.85, pos.y - size * 0.75)
        drawFilledTriangle(draw_list, p1, p2, p3, fillColor, outlineColor)
    else
        draw_list:AddRectFilled(
            imgui.ImVec2(pos.x - size, pos.y - size),
            imgui.ImVec2(pos.x + size, pos.y + size),
            outlineColor,
            0
        )
        draw_list:AddRectFilled(
            imgui.ImVec2(pos.x - size + 2, pos.y - size + 2),
            imgui.ImVec2(pos.x + size - 2, pos.y + size - 2),
            fillColor,
            0
        )
    end
end
function ImageRotated(tex_id, center, size, angle, alpha)
    alpha = alpha or 1.0
    local cos_a, sin_a = math.cos(angle), math.sin(angle)
    local pos = {
        calcAddImVec2(center, ImRotate(imgui.ImVec2(-size.x*0.5, -size.y*0.5), cos_a, sin_a)),
        calcAddImVec2(center, ImRotate(imgui.ImVec2(size.x*0.5, -size.y*0.5), cos_a, sin_a)),
        calcAddImVec2(center, ImRotate(imgui.ImVec2(size.x*0.5, size.y*0.5), cos_a, sin_a)),
        calcAddImVec2(center, ImRotate(imgui.ImVec2(-size.x*0.5, size.y*0.5), cos_a, sin_a))
    }
    local uvs = {imgui.ImVec2(0,0), imgui.ImVec2(1,0), imgui.ImVec2(1,1), imgui.ImVec2(0,1)}
    local color = imgui.GetColorU32(imgui.ImVec4(1, 1, 1, alpha))
    imgui.GetWindowDrawList():AddImageQuad(tex_id, pos[1], pos[2], pos[3], pos[4], uvs[1], uvs[2], uvs[3], uvs[4], color)
end

function sampev.onSetCheckpoint(position)
    checkpoint = {active = true, x = position.x, y = position.y, z = position.z}
    -- Don't print spam
end

function sampev.onDisableCheckpoint()
    checkpoint.active = false
    -- DON'T clear path here - /find disables and re-enables rapidly
end

function sampev.onSetRaceCheckpoint(cpType, position)
    raceCheckpoint = {active = true, x = position.x, y = position.y, z = position.z}
end

function sampev.onDisableRaceCheckpoint()
    raceCheckpoint.active = false
    -- DON'T clear path here either
end
function sampev.onServerMessage(color, text)
    text = text or ""

    if text:find("Quest activat%. Obiectele au fost marcate pe minimap!", 1, false) then
        questMarkersEnabled = true
        sampAddChatMessage("[MMAP] quest markers ON", -1)
    elseif text:find("Quest dezactivat. Obiectele au fost ascunse de pe minimap!", 1, true) then
        questMarkersEnabled = false
        sampAddChatMessage("[MMAP] quest markers OFF", -1)
    end
end

-- Helper function to convert ABGR color to RGBA values (SA-MP uses ABGR)
local function abgrToRgba(abgrColor)
    local a = bit.band(bit.rshift(abgrColor, 24), 0xFF) / 255
    local b = bit.band(bit.rshift(abgrColor, 16), 0xFF) / 255  -- Blue is in the "R" position
    local g = bit.band(bit.rshift(abgrColor, 8), 0xFF) / 255
    local r = bit.band(abgrColor, 0xFF) / 255  -- Red is in the "B" position
    -- Boost for visibility
    r = math.min(1, r * 1.3)
    g = math.min(1, g * 1.3)
    b = math.min(1, b * 1.3)
    return r, g, b, a
end

-- Gang Zone Events
function sampev.onCreateGangZone(zoneId, squareStart, squareEnd, color)
    local r, g, b, a = abgrToRgba(color)
    -- Pre-calculate map coordinates (only depends on zone position, not player position)
    local zMinX = squareStart.x < 0 and (3000 - math.abs(squareStart.x)) or (3000 + squareStart.x)
    local zMinY = squareStart.y < 0 and (3000 + math.abs(squareStart.y)) or (3000 - squareStart.y)
    local zMaxX = squareEnd.x < 0 and (3000 - math.abs(squareEnd.x)) or (3000 + squareEnd.x)
    local zMaxY = squareEnd.y < 0 and (3000 + math.abs(squareEnd.y)) or (3000 - squareEnd.y)
    
    gangZones[zoneId] = {
        -- Pre-calculated map coords
        mapMinX = zMinX,
        mapMinY = zMinY,
        mapMaxX = zMaxX,
        mapMaxY = zMaxY,
        -- Pre-calculated colors
        r = r, g = g, b = b, a = a,
        fillAlpha = math.max(a * 0.9, 0.6),  -- More visible fill
        -- Other
        flashing = false,
        flashR = 0, flashG = 0, flashB = 0, flashA = 0
    }
end

function sampev.onGangZoneDestroy(zoneId)
    gangZones[zoneId] = nil
end

function sampev.onGangZoneFlash(zoneId, color)
    if gangZones[zoneId] then
        gangZones[zoneId].flashing = true
        local r, g, b, a = abgrToRgba(color)
        gangZones[zoneId].flashR = r
        gangZones[zoneId].flashG = g
        gangZones[zoneId].flashB = b
        gangZones[zoneId].flashA = a
    end
end

function sampev.onGangZoneStopFlash(zoneId)
    if gangZones[zoneId] then
        gangZones[zoneId].flashing = false
    end
end

local function applyTheme()
    imgui.SwitchContext()
    local s = imgui.GetStyle()
    s.WindowPadding, s.WindowRounding, s.FramePadding, s.ItemSpacing = imgui.ImVec2(0,0), 0, imgui.ImVec2(0,0), imgui.ImVec2(0,0)
    -- Initialize cursor to hidden (imgui defaults to true, we only want it for settings)
    imgui.ShowCursor = false
end
applyTheme()

local MAX_RADAR_TRACES = 175
local RADAR_BASE = 0xBA86F0
local RADAR_SIZE = 0x28

debugRadarDump = function()
    local count = 0
    sampAddChatMessage("{00FF00}[RADARDBG] scanning entries...", -1)

    for i = 0, MAX_RADAR_TRACES - 1 do
        local addr = RADAR_BASE + i * RADAR_SIZE

        -- Correct offsets (confirmed: x=+0x08, y=+0x0C, z=+0x10)
        local x = memory.getfloat(addr + 0x08, true)
        local y = memory.getfloat(addr + 0x0C, true)
        local z = memory.getfloat(addr + 0x10, true)

        if math.abs(x) <= 3000 and math.abs(y) <= 3000 and not (x == 0 and y == 0 and z == 0) then
            -- Read all bytes of the struct
            local b00 = memory.getuint8(addr + 0x00, true)
            local b01 = memory.getuint8(addr + 0x01, true)
            local b02 = memory.getuint8(addr + 0x02, true)
            local b03 = memory.getuint8(addr + 0x03, true)
            local b04 = memory.getuint8(addr + 0x04, true)
            local b05 = memory.getuint8(addr + 0x05, true)
            local b06 = memory.getuint8(addr + 0x06, true)
            local b07 = memory.getuint8(addr + 0x07, true)
            -- +0x08 to +0x17 = x,y,z floats (12 bytes) + 4 bytes
            local b14 = memory.getuint8(addr + 0x14, true)
            local b15 = memory.getuint8(addr + 0x15, true)
            local b16 = memory.getuint8(addr + 0x16, true)
            local b17 = memory.getuint8(addr + 0x17, true)
            local b18 = memory.getuint8(addr + 0x18, true)
            local b19 = memory.getuint8(addr + 0x19, true)
            local b1A = memory.getuint8(addr + 0x1A, true)
            local b1B = memory.getuint8(addr + 0x1B, true)
            local b1C = memory.getuint8(addr + 0x1C, true)
            local b1D = memory.getuint8(addr + 0x1D, true)
            local b1E = memory.getuint8(addr + 0x1E, true)
            local b1F = memory.getuint8(addr + 0x1F, true)
            local b20 = memory.getuint8(addr + 0x20, true)
            local b21 = memory.getuint8(addr + 0x21, true)
            local b22 = memory.getuint8(addr + 0x22, true)
            local b23 = memory.getuint8(addr + 0x23, true)
            local b24 = memory.getuint8(addr + 0x24, true)
            local b25 = memory.getuint8(addr + 0x25, true)
            local b26 = memory.getuint8(addr + 0x26, true)
            local b27 = memory.getuint8(addr + 0x27, true)

            sampAddChatMessage(string.format(
                "[%03d] xyz(%.1f %.1f %.1f)",
                i, x, y, z), -1)
            sampAddChatMessage(string.format(
                "  00-07: %d,%d,%d,%d | %d,%d,%d,%d",
                b00,b01,b02,b03,b04,b05,b06,b07), -1)
            sampAddChatMessage(string.format(
                "  14-1F: %d,%d,%d,%d | %d,%d,%d,%d | %d,%d,%d,%d",
                b14,b15,b16,b17,b18,b19,b1A,b1B,b1C,b1D,b1E,b1F), -1)
            sampAddChatMessage(string.format(
                "  20-27: %d,%d,%d,%d | %d,%d,%d,%d",
                b20,b21,b22,b23,b24,b25,b26,b27), -1)

            count = count + 1
            if count >= 6 then
                sampAddChatMessage("{FFFF00}[RADARDBG] limited to 6. Run again near other markers.", -1)
                return
            end
        end
    end

    sampAddChatMessage(string.format("{00FF00}[RADARDBG] done, %d entries.", count), -1)
end

local MAX_RADAR_TRACES = 175
local RADAR_BASE = 0xBA86F0
local RADAR_SIZE = 0x28

readBlips = function()
    local blips = {}

    for i = 0, MAX_RADAR_TRACES - 1 do
        local addr = RADAR_BASE + i * RADAR_SIZE

        local colorId = memory.getuint32(addr + 0x00, true)
        local x = memory.getfloat(addr + 0x08, true)
        local y = memory.getfloat(addr + 0x0C, true)
        local z = memory.getfloat(addr + 0x10, true)
        local icon = memory.getuint8(addr + 0x24, true)
        local b1C = memory.getuint8(addr + 0x1C, true)

        if math.abs(x) <= 3000 and math.abs(y) <= 3000 then
            if not (x == 0.0 and y == 0.0 and z == 0.0) then
                table.insert(blips, {
                    x = x,
                    y = y,
                    z = z,
                    icon = icon,
                    colorId = colorId,
                    b1C = b1C,
                    index = i
                })
            end
        end
    end

    return blips
end

local function worldToMapScreen(wx, wy, winPosX, winPosY, sizeMap, offsetX, offsetY, centerX, centerY, angle)
    local tmx = wx < 0 and (3000 - math.abs(wx)) or (3000 + wx)
    local tmy = wy < 0 and (3000 + math.abs(wy)) or (3000 - wy)

    local bv = rotateVector({
        winPosX + tmx / (6000 / sizeMap) - offsetX - centerX,
        winPosY + tmy / (6000 / sizeMap) - offsetY - centerY
    }, angle)

    return imgui.ImVec2(bv[1] + centerX, bv[2] + centerY)
end

function imgui.OnDrawFrame()
    -- Only show cursor when settings window is open (for clicking UI elements)
    -- When just viewing the map (E key), cursor should be hidden
    imgui.ShowCursor = settingsWindow.v
    
    -- Settings Window with GTA V Theme
    if settingsWindow.v then
        local screenX, screenY = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(screenX / 2, screenY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(420, 700), imgui.Cond.FirstUseEver)
        
        applyGTAVTheme()
        
        imgui.Begin('GPS MAP SETTINGS', settingsWindow, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
        
        -- Header
        local titleText = "GPS DISPLAY SETTINGS"
        local titleSize = imgui.CalcTextSize(titleText)
        imgui.SetCursorPosX((imgui.GetWindowWidth() - titleSize.x) / 2)
        imgui.TextColored(GTAV_YELLOW, titleText)
        
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        
        -- Route Mode Toggle
        local useRoadBool = imgui.ImBool(config.settings.useRoadRoute)
        if imgui.Checkbox("Use Road Route (follows roads)", useRoadBool) then
            config.settings.useRoadRoute = useRoadBool.v
            saveConfig()
            displayPath = {}  -- Clear path when switching modes
        end
        if config.settings.useRoadRoute then
            imgui.TextColored(GTAV_ORANGE, "  Warning: May cause lag spikes")
        else
            imgui.TextColored(GTAV_TEXT_DIM, "  Straight line mode (no lag)")
        end
        imgui.SameLine()
        imgui.TextColored(GTAV_TEXT_DIM, "[?]")
        if imgui.IsItemHovered() then
            imgui.SetTooltip("Road Route uses A* pathfinding to follow roads.\nStraight Line draws a direct line (default, no lag).")
        end
        
        imgui.Spacing()
        
        -- Auto-show minimap option
        local autoShowBool = imgui.ImBool(config.settings.autoShowMinimap)
        if imgui.Checkbox("Auto-show minimap when checkpoint active", autoShowBool) then
            config.settings.autoShowMinimap = autoShowBool.v
            saveConfig()
        end
        if imgui.IsItemHovered() then
            imgui.SetTooltip("When enabled, minimap appears automatically when\na checkpoint is active. When disabled, hold the\nMap Key to show the minimap.")
        end
        
        imgui.Spacing()
        
        -- Show Gang Zones option
        local showZonesBool = imgui.ImBool(config.settings.showGangZones ~= false)
        if imgui.Checkbox("Show gang zones (turfs)", showZonesBool) then
            config.settings.showGangZones = showZonesBool.v
            saveConfig()
        end
        if imgui.IsItemHovered() then
            imgui.SetTooltip("Show gang zone territories on the map.\nDisable if you experience FPS drops.")
        end
        
        imgui.Spacing()
        
        -- Line Color
        imgui.AlignTextToFramePadding()
        imgui.Text("Line Color:")
        imgui.SameLine(imgui.GetWindowWidth() - 180)
        imgui.PushItemWidth(160)
        local lineColorCombo = imgui.ImInt(config.settings.lineColorIndex)
        if imgui.Combo("##linecolor", lineColorCombo, {"Red", "Blue", "Green", "Yellow", "Purple", "Orange", "Cyan", "White"}, 8) then
            config.settings.lineColorIndex = lineColorCombo.v
            saveConfig()
        end
        if imgui.IsItemHovered() then
            imgui.SetTooltip("Color of the GPS line on the map.")
        end
        imgui.PopItemWidth()
        
        imgui.Spacing()
        
        -- Arrow Color
        imgui.AlignTextToFramePadding()
        imgui.Text("Arrow Color:")
        imgui.SameLine(imgui.GetWindowWidth() - 180)
        imgui.PushItemWidth(160)
        local arrowColorCombo = imgui.ImInt(config.settings.arrowColorIndex or 4)
        if imgui.Combo("##arrowcolor", arrowColorCombo, {"Red", "Blue", "Green", "Yellow", "Purple-Pink", "Orange", "Cyan", "White"}, 8) then
            config.settings.arrowColorIndex = arrowColorCombo.v
            saveConfig()
        end
        if imgui.IsItemHovered() then
            imgui.SetTooltip("Color of the player arrow on the map.")
        end
        imgui.PopItemWidth()
        
        imgui.Spacing()
        
        -- Map Key
        imgui.AlignTextToFramePadding()
        imgui.Text("Map Key:")
        imgui.SameLine(imgui.GetWindowWidth() - 180)
        imgui.PushItemWidth(160)
        local mapKeyCombo = imgui.ImInt(config.settings.mapKeyIndex)
        if imgui.Combo("##mapkey", mapKeyCombo, {"M", "E", "Z", "X", "C", "V", "B", "N", "Tab", "CapsLock"}, 10) then
            config.settings.mapKeyIndex = mapKeyCombo.v
            saveConfig()
        end
        if imgui.IsItemHovered() then
            imgui.SetTooltip("Hold this key to enlarge the map.")
        end
        imgui.PopItemWidth()
        
        imgui.Spacing()
        
        -- Enlarged Map Size
        imgui.AlignTextToFramePadding()
        imgui.Text("Enlarged Size:")
        imgui.SameLine(imgui.GetWindowWidth() - 180)
        imgui.PushItemWidth(160)
        local enlargedSizeCombo = imgui.ImInt(config.settings.enlargedMapSize or 0)
        if imgui.Combo("##enlargedsize", enlargedSizeCombo, {"60%", "70%", "80%", "90%"}, 4) then
            config.settings.enlargedMapSize = enlargedSizeCombo.v
            saveConfig()
        end
        if imgui.IsItemHovered() then
            imgui.SetTooltip("Size of the enlarged map when holding the Map Key.")
        end
        imgui.PopItemWidth()
        
        imgui.Spacing()
        
        -- Center Enlarged Map option
        local centerMapBool = imgui.ImBool(config.settings.centerEnlargedMap or false)
        if imgui.Checkbox("Center enlarged map on screen", centerMapBool) then
            config.settings.centerEnlargedMap = centerMapBool.v
            saveConfig()
        end
        if imgui.IsItemHovered() then
            imgui.SetTooltip("When enabled, enlarged map appears in the center.\nWhen disabled, it appears in the bottom-left corner.")
        end
        
        imgui.Spacing()
        
        -- Hide Messages option
        local hideMessagesBool = imgui.ImBool(config.settings.hideMessages)
        if imgui.Checkbox("Hide chat messages", hideMessagesBool) then
            config.settings.hideMessages = hideMessagesBool.v
            saveConfig()
        end
        if imgui.IsItemHovered() then
            imgui.SetTooltip("Hide all GPS mod messages from chat.")
        end
        
        imgui.Spacing()
        
        -- Map Opacity
        imgui.AlignTextToFramePadding()
        imgui.Text("Map Opacity:")
        imgui.SameLine(imgui.GetWindowWidth() - 180)
        imgui.PushItemWidth(130)
        local opacityFloat = imgui.ImFloat(config.settings.mapOpacity or 100)
        if imgui.SliderFloat("##opacity", opacityFloat, 20, 100, "%.0f%%") then
            config.settings.mapOpacity = math.floor(opacityFloat.v)
            saveConfig()
        end
        if imgui.IsItemHovered() then
            imgui.SetTooltip("Transparency of the map image (20-100%).")
        end
        imgui.PopItemWidth()
        
        imgui.Spacing()
        
        -- Map Style
        imgui.AlignTextToFramePadding()
        imgui.Text("Map Style:")
        imgui.SameLine(imgui.GetWindowWidth() - 180)
        imgui.PushItemWidth(160)
        local mapStyleCombo = imgui.ImInt(config.settings.mapStyle or 0)
        if imgui.Combo("##mapstyle", mapStyleCombo, {"Default (mapkv)", "SA Style (mapsa)", "3D Style (map3d)"}, 3) then
            config.settings.mapStyle = mapStyleCombo.v
            saveConfig()
        end
        if imgui.IsItemHovered() then
            imgui.SetTooltip("Select which map image to display.")
        end
        imgui.PopItemWidth()
        
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        
        -- Close button centered
        local buttonWidth = 150
        imgui.SetCursorPosX((imgui.GetWindowWidth() - buttonWidth) / 2)
        if imgui.Button('CLOSE', imgui.ImVec2(buttonWidth, 30)) then
            settingsWindow.v = false
        end
        
        -- Footer
        imgui.Spacing()
        imgui.TextColored(GTAV_TEXT_DIM, "moduri.ro")
        
        imgui.End()
        popGTAVTheme()
    end
    
    -- Map Window
    if not window_state.v or not config.settings.enabled then return end
    
    local X, Y = getScreenResolution()
    
    -- Larger size when M held, smaller when just checkpoint
    local winSize
    local posX, posY
    
    if enlargedMode then
        -- Enlarged: size based on setting
        local sizeMultipliers = { 0.6, 0.7, 0.8, 0.9 }
        local sizeIndex = (config.settings.enlargedMapSize or 0) + 1
        if sizeIndex < 1 or sizeIndex > 4 then sizeIndex = 1 end
        winSize = math.min(X, Y) * sizeMultipliers[sizeIndex]
        
        if config.settings.centerEnlargedMap then
            -- Center of screen
            posX = X / 2
            posY = Y / 2
        else
            -- Bottom-left corner (default)
            posX = winSize/2 + 20
            posY = Y - winSize/2 - 20
        end
    else
        -- Normal: larger map on left side
        winSize = RadarSize * 4  -- Bigger default size
        posX = winSize/2 + 100
        posY = Y - winSize/2 - 20
    end
    
    imgui.SetNextWindowSize(imgui.ImVec2(winSize, winSize), imgui.Cond.Always)
    imgui.SetNextWindowPos(imgui.ImVec2(posX, posY), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
    
    imgui.Begin("GPS", window_state, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar +
        imgui.WindowFlags.NoMove + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoFocusOnAppearing + 
        imgui.WindowFlags.NoInputs + imgui.WindowFlags.NoBringToFrontOnFocus)
    
    local draw_list = imgui.GetWindowDrawList()
    
    -- Zoom level: smaller value = more zoomed out (shows more area)
    local sizeMap
    if enlargedMode then
        sizeMap = winSize  -- Map exactly fits window
    else
        sizeMap = X * 0.6   -- Normal zoom
    end
    local x, y = getCharCoordinates(PLAYER_PED)
    local mapX = x < 0 and (3000 - math.abs(x)) or (3000 + x)
    local mapY = y < 0 and (3000 + math.abs(y)) or (3000 - y)
    local offsetX = (mapX / (6000/sizeMap)) - (imgui.GetWindowSize().x/2)
    local offsetY = (mapY / (6000/sizeMap)) - (imgui.GetWindowSize().y/2)
    
    -- In enlarged mode, clamp offset so map never shows empty areas
    if enlargedMode then
        local maxOffset = sizeMap - winSize
        offsetX = math.max(0, math.min(offsetX, maxOffset))
        offsetY = math.max(0, math.min(offsetY, maxOffset))
    end
    local winPosX, winPosY = imgui.GetWindowPos().x, imgui.GetWindowPos().y
    local winW, winH = imgui.GetWindowSize().x, imgui.GetWindowSize().y
    local centerX, centerY = winPosX + winW/2, winPosY + winH/2
    
    -- Rotation angle: rotate in normal mode, no rotation in enlarged mode
    local angle
    if enlargedMode then
        angle = 0  -- No rotation when M pressed
    else
        angle = math.rad(returnAngle())  -- Rotate with camera
    end
    
    -- Draw map (with transparency)
    local mapAlpha = (config.settings.mapOpacity or 100) / 100
    local rv = rotateVector({winPosX + sizeMap/2 - offsetX - centerX, winPosY + sizeMap/2 - offsetY - centerY}, angle)
    
    -- Select map based on style setting
    local selectedMap = map_img
    local mapStyle = config.settings.mapStyle or 0
    if mapStyle == 1 and mapsa_img then
        selectedMap = mapsa_img
    elseif mapStyle == 2 and map3d_img then
        selectedMap = map3d_img
    end
    
    ImageRotated(selectedMap, imgui.ImVec2(rv[1] + centerX, rv[2] + centerY), imgui.ImVec2(sizeMap, sizeMap), angle, mapAlpha)
    
    -- Draw gang zones (only in enlarged mode to avoid FPS drops)
    if config.settings.showGangZones ~= false and enlargedMode then
    -- Only draw zones that are at least partially visible
    local mapScale = sizeMap / 6000
    local viewMinX, viewMaxX = winPosX, winPosX + winSize
    local viewMinY, viewMaxY = winPosY, winPosY + winSize
    
    for _, zone in pairs(gangZones) do
        -- Calculate screen bounds
        local screenMinX = winPosX + zone.mapMinX * mapScale - offsetX
        local screenMinY = winPosY + zone.mapMaxY * mapScale - offsetY
        local screenMaxX = winPosX + zone.mapMaxX * mapScale - offsetX
        local screenMaxY = winPosY + zone.mapMinY * mapScale - offsetY
        
        -- Skip zones completely outside viewport (frustum culling)
        if screenMaxX > viewMinX and screenMinX < viewMaxX and 
           screenMaxY > viewMinY and screenMinY < viewMaxY then
            
            -- Create corner ImVec2s
            local c1, c2, c3, c4
            if enlargedMode then
                c1 = imgui.ImVec2(screenMinX, screenMinY)
                c2 = imgui.ImVec2(screenMaxX, screenMinY)
                c3 = imgui.ImVec2(screenMaxX, screenMaxY)
                c4 = imgui.ImVec2(screenMinX, screenMaxY)
            else
                local r1 = rotateVector({screenMinX - centerX, screenMinY - centerY}, angle)
                local r2 = rotateVector({screenMaxX - centerX, screenMinY - centerY}, angle)
                local r3 = rotateVector({screenMaxX - centerX, screenMaxY - centerY}, angle)
                local r4 = rotateVector({screenMinX - centerX, screenMaxY - centerY}, angle)
                c1 = imgui.ImVec2(r1[1] + centerX, r1[2] + centerY)
                c2 = imgui.ImVec2(r2[1] + centerX, r2[2] + centerY)
                c3 = imgui.ImVec2(r3[1] + centerX, r3[2] + centerY)
                c4 = imgui.ImVec2(r4[1] + centerX, r4[2] + centerY)
            end
            
            -- Use pre-calculated colors
            local r, g, b = zone.r, zone.g, zone.b
            local fillA = zone.fillAlpha
            if zone.flashing and (math.floor(os.clock() * 4) % 2 == 0) then
                r, g, b = zone.flashR, zone.flashG, zone.flashB
            end
            
            -- Draw filled quad + border for visibility
            local fillColor = imgui.GetColorU32(imgui.ImVec4(r, g, b, fillA))
            local borderColor = imgui.GetColorU32(imgui.ImVec4(r, g, b, 1))  -- Full opacity border
            draw_list:AddQuadFilled(c1, c2, c3, c4, fillColor)
            draw_list:AddQuad(c1, c2, c3, c4, borderColor, 1)  -- Thin border
        end
    end
    end  -- if showGangZones
    
    -- Draw path - connected line with small dots
    local LINE_COLORS = {
        imgui.ImVec4(1, 0, 0, 1),       -- Red
        imgui.ImVec4(0.2, 0.5, 1, 1),   -- Blue
        imgui.ImVec4(0.2, 0.9, 0.3, 1), -- Green
        imgui.ImVec4(1, 0.9, 0.1, 1),   -- Yellow
        imgui.ImVec4(0.7, 0.3, 1, 1),   -- Purple
        imgui.ImVec4(1, 0.5, 0, 1),     -- Orange
        imgui.ImVec4(0, 0.9, 1, 1),     -- Cyan
        imgui.ImVec4(1, 1, 1, 1)        -- White
    }
    local gpsColor = imgui.GetColorU32(LINE_COLORS[config.settings.lineColorIndex + 1] or LINE_COLORS[1])
    local gpsOutline = imgui.GetColorU32(imgui.ImVec4(0, 0, 0, 0.7))  -- Dark outline for visibility
    local lineThickness = 3  -- Medium line
    local outlineThickness = 4.5  -- Thin outline behind the line
    
    local prevPoint = nil
    for i = 1, #displayPath do
        local pv = rotateVector({winPosX + displayPath[i][1]*(sizeMap/500) - offsetX - centerX, winPosY + displayPath[i][2]*(sizeMap/500) - offsetY - centerY}, angle)
        local currentPoint = imgui.ImVec2(pv[1] + centerX, pv[2] + centerY)
        
        -- Draw outline first (behind the main line)
        if prevPoint then
            draw_list:AddLine(prevPoint, currentPoint, gpsOutline, outlineThickness)
        end
        
        prevPoint = currentPoint
    end
    
    -- Draw the colored line on top
    prevPoint = nil
    for i = 1, #displayPath do
        local pv = rotateVector({winPosX + displayPath[i][1]*(sizeMap/500) - offsetX - centerX, winPosY + displayPath[i][2]*(sizeMap/500) - offsetY - centerY}, angle)
        local currentPoint = imgui.ImVec2(pv[1] + centerX, pv[2] + centerY)
        
        if prevPoint then
            draw_list:AddLine(prevPoint, currentPoint, gpsColor, lineThickness)
        end
        
        prevPoint = currentPoint
    end
    
    -- Draw line from player position to first waypoint
    if #displayPath > 0 then
        -- Calculate player screen position
        local playerScreenX, playerScreenY
        if enlargedMode then
            playerScreenX = winPosX + (mapX / (6000/sizeMap)) - offsetX
            playerScreenY = winPosY + (mapY / (6000/sizeMap)) - offsetY
        else
            playerScreenX = centerX
            playerScreenY = centerY
        end
        
        -- Get first waypoint position
        local firstWP = displayPath[1]
        local fpv = rotateVector({winPosX + firstWP[1]*(sizeMap/500) - offsetX - centerX, winPosY + firstWP[2]*(sizeMap/500) - offsetY - centerY}, angle)
        local firstPoint = imgui.ImVec2(fpv[1] + centerX, fpv[2] + centerY)
        local playerPoint = imgui.ImVec2(playerScreenX, playerScreenY)
        
        -- Draw outline and line from player to first waypoint
        draw_list:AddLine(playerPoint, firstPoint, gpsOutline, outlineThickness)
        draw_list:AddLine(playerPoint, firstPoint, gpsColor, lineThickness)
    end
    
    -- Draw cursor (player position)
    local cursorX, cursorY
    local cursorSize
    if enlargedMode then
        -- In enlarged mode, calculate actual player position on map
        local playerPosX = winPosX + (mapX / (6000/sizeMap)) - offsetX
        local playerPosY = winPosY + (mapY / (6000/sizeMap)) - offsetY
        cursorX, cursorY = playerPosX, playerPosY
        -- Scale cursor size based on map size (bigger map = bigger cursor)
        local sizeMultipliers = { 14, 16, 18, 20 }  -- For 60%, 70%, 80%, 90%
        local sizeIndex = (config.settings.enlargedMapSize or 0) + 1
        if sizeIndex < 1 or sizeIndex > 4 then sizeIndex = 1 end
        cursorSize = sizeMultipliers[sizeIndex]
    else
        -- In normal mode, player is always at center
        cursorX, cursorY = centerX, centerY
        cursorSize = 18  -- Size for normal view
    end
    local cursorAngle = -math.rad(getCharHeading(PLAYER_PED)) + angle
    
    -- Draw arrow with code (more visible than image)
    local cos_a, sin_a = math.cos(cursorAngle), math.sin(cursorAngle)
    local function rotatePoint(px, py)
        return cursorX + px * cos_a - py * sin_a, cursorY + px * sin_a + py * cos_a
    end
    
    -- Arrow triangle points (pointing up by default)
    local tipX, tipY = rotatePoint(0, -cursorSize)  -- Top point
    local leftX, leftY = rotatePoint(-cursorSize * 0.6, cursorSize * 0.6)  -- Bottom left
    local rightX, rightY = rotatePoint(cursorSize * 0.6, cursorSize * 0.6)  -- Bottom right
    local backX, backY = rotatePoint(0, cursorSize * 0.2)  -- Back indent for arrow shape
    
    -- Arrow colors (same order as LINE_COLORS but with purple-pink)
    local ARROW_COLORS = {
        imgui.ImVec4(1, 0.2, 0.2, 1),     -- Red
        imgui.ImVec4(0.3, 0.6, 1, 1),     -- Blue
        imgui.ImVec4(0.2, 1, 0.3, 1),     -- Green
        imgui.ImVec4(1, 0.95, 0.2, 1),    -- Yellow
        imgui.ImVec4(1, 0.3, 0.8, 1),     -- Purple-Pink (default)
        imgui.ImVec4(1, 0.6, 0.1, 1),     -- Orange
        imgui.ImVec4(0.2, 1, 1, 1),       -- Cyan
        imgui.ImVec4(1, 1, 1, 1)          -- White
    }
    local arrowColorIdx = (config.settings.arrowColorIndex or 4) + 1
    local arrowColor = imgui.GetColorU32(ARROW_COLORS[arrowColorIdx] or ARROW_COLORS[5])
    local outlineColor = imgui.GetColorU32(imgui.ImVec4(0, 0, 0, 1))  -- Black outline
    
    -- Draw outline first (thicker)
    draw_list:AddTriangleFilled(
        imgui.ImVec2(tipX, tipY),
        imgui.ImVec2(leftX, leftY),
        imgui.ImVec2(backX, backY),
        outlineColor
    )
    draw_list:AddTriangleFilled(
        imgui.ImVec2(tipX, tipY),
        imgui.ImVec2(backX, backY),
        imgui.ImVec2(rightX, rightY),
        outlineColor
    )
    
    -- Draw arrow slightly smaller on top
    local scale = 0.85
    local tipX2, tipY2 = rotatePoint(0, -cursorSize * scale)
    local leftX2, leftY2 = rotatePoint(-cursorSize * 0.6 * scale, cursorSize * 0.6 * scale)
    local rightX2, rightY2 = rotatePoint(cursorSize * 0.6 * scale, cursorSize * 0.6 * scale)
    local backX2, backY2 = rotatePoint(0, cursorSize * 0.2 * scale)
    
    draw_list:AddTriangleFilled(
        imgui.ImVec2(tipX2, tipY2),
        imgui.ImVec2(leftX2, leftY2),
        imgui.ImVec2(backX2, backY2),
        arrowColor
    )
    draw_list:AddTriangleFilled(
        imgui.ImVec2(tipX2, tipY2),
        imgui.ImVec2(backX2, backY2),
        imgui.ImVec2(rightX2, rightY2),
        arrowColor
    )
    local px, py, pz = getCharCoordinates(PLAYER_PED)

    allBlips = readBlips()

    -- Draw non-quest blips from memory (waypoints, squares, icon blips)
    for _, blip in ipairs(allBlips) do
        local isWaypoint = (blip.icon == 41)
        local isSquare = (blip.icon == 1)
        local isQuest = (blip.icon == 0) and (blip.colorId == 4294967295) and (blip.b1C == 3)
        local isNonQuest = blip.icon ~= 0
        local isTowTruck = (blip.icon == 0) and (blip.colorId == 4277707519) and (blip.b1C == 3)
        local isPizzaBoy = (blip.icon == 0) and (blip.colorId == 4294902015) and (blip.b1C == 3)
        local isDeliveryDriver = (blip.icon == 0) and (blip.colorId == 3985711615) and (blip.b1C == 3)
        local isDeliveryDriver2 = (blip.icon == 0) and (blip.colorId == 2473647103) and (blip.b1C == 3)

        if isWaypoint or isDeliveryDriver or isDeliveryDriver2 or isTowTruck or isPizzaBoy or isSquare or isNonQuest or (isQuest and questMarkersEnabled) then
            local pos = worldToMapScreen(blip.x, blip.y, winPosX, winPosY, sizeMap, offsetX, offsetY, centerX, centerY, angle)
            local color = imgui.GetColorU32(imgui.ImVec4(1, 1, 1, 1))

            if isWaypoint and marker_img then
                local markerSize = enlargedMode and 30 or 22
                draw_list:AddImage(
                    marker_img,
                    imgui.ImVec2(pos.x - markerSize / 2, pos.y - markerSize),
                    imgui.ImVec2(pos.x + markerSize / 2, pos.y)
                )
            elseif isSquare then
                local r = enlargedMode and 8 or 7
                draw_list:AddRectFilled(
                    imgui.ImVec2(pos.x - r, pos.y - r),
                    imgui.ImVec2(pos.x + r, pos.y + r),
                    color
                )
                draw_list:AddRect(
                    imgui.ImVec2(pos.x - r, pos.y - r),
                    imgui.ImVec2(pos.x + r, pos.y + r),
                    imgui.GetColorU32(imgui.ImVec4(0, 0, 0, 1))
                )
            elseif isTowTruck then
                local r = enlargedMode and 8 or 7
                local dz = blip.z - pz
                local yellow = imgui.GetColorU32(imgui.ImVec4(1, 1, 0.761, 1))
                drawMarkerType0(draw_list, pos, r, dz, yellow, imgui.GetColorU32(imgui.ImVec4(0, 0, 0, 1)))
            elseif isPizzaBoy then
                local r = enlargedMode and 8 or 7
                local dz = blip.z - pz
                local yellowPizza = imgui.GetColorU32(imgui.ImVec4(0.988, 1, 0, 1))
                drawMarkerType0(draw_list, pos, r, dz, yellowPizza, imgui.GetColorU32(imgui.ImVec4(0, 0, 0, 1)))
            elseif isDeliveryDriver then
                local r = enlargedMode and 8 or 7
                local dz = blip.z - pz
                local orange = imgui.GetColorU32(imgui.ImVec4(0.961, 0.545, 0.153, 1))
                drawMarkerType0(draw_list, pos, r, dz, orange, imgui.GetColorU32(imgui.ImVec4(0, 0, 0, 1)))
            elseif isDeliveryDriver2 then
                local r = enlargedMode and 8 or 7
                local dz = blip.z - pz
                local purple = imgui.GetColorU32(imgui.ImVec4(0.714, 0.412, 1, 1))
                drawMarkerType0(draw_list, pos, r, dz, purple, imgui.GetColorU32(imgui.ImVec4(0, 0, 0, 1)))
            elseif isNonQuest and radar_icons[blip.icon] then
                local iconSize = enlargedMode and 20 or 14
                draw_list:AddImage(
                    radar_icons[blip.icon],
                    imgui.ImVec2(pos.x - iconSize / 2, pos.y - iconSize / 2),
                    imgui.ImVec2(pos.x + iconSize / 2, pos.y + iconSize / 2)
                )
            else
                local r = isQuest and (enlargedMode and 8 or 7) or (enlargedMode and 8 or 7)
                local dz = blip.z - pz
                drawMarkerType0(draw_list, pos, r, dz, color, imgui.GetColorU32(imgui.ImVec4(0, 0, 0, 1)))
            end
        end
    end

    -- Highlight active checkpoint separately
    -- Draw target marker (bigger, different color)
    if checkpoint.active or raceCheckpoint.active then
        local tx = checkpoint.active and checkpoint.x or raceCheckpoint.x
        local ty = checkpoint.active and checkpoint.y or raceCheckpoint.y
        local tz = checkpoint.active and checkpoint.z or raceCheckpoint.z

        local px, py, pz = getCharCoordinates(PLAYER_PED)
        local markerPos = worldToMapScreen(
            tx, ty,
            winPosX, winPosY, sizeMap, offsetX, offsetY, centerX, centerY, angle
        )

        local fillColor = imgui.GetColorU32(imgui.ImVec4(1.0, 0.0, 0.0, 1.0))
        local outlineColor = imgui.GetColorU32(imgui.ImVec4(0.0, 0.0, 0.0, 1.0))
        local markerSize = enlargedMode and 8 or 6
        local dz = (tz or pz) - pz

        drawMarkerType0(draw_list, markerPos, markerSize, dz, fillColor, outlineColor)
    end
    
    -- Draw border
    draw_list:AddRect(imgui.ImVec2(winPosX, winPosY), imgui.ImVec2(winPosX + winSize, winPosY + winSize), imgui.GetColorU32(imgui.ImVec4(1,1,1,1)), 10, nil, 10)
    
    imgui.End()
end