-- DamageInformer.lua v6.0
-- MoonLoader 0.26+ / SAMPFUNCS / SAMP 0.3.7
-- Data-only bridge for C++ .asi renderer

script_name("DamageInformer")
script_author("port")
script_version("6.0")

require "lib.moonloader"
require "lib.sampfuncs"

local sampevents = require "lib.samp.events"
local imgui      = require "mimgui"
local inicfg     = require "inicfg"
local ec         = require "encoding"
local ffi        = require "ffi"
local GetBonePosition = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)

ec.default = "CP1251"
u8 = ec.UTF8

------------------------------------------------------------
-- SHARED MEMORY / FFI
------------------------------------------------------------
ffi.cdef[[
typedef void* HANDLE;
typedef void* LPVOID;
typedef const char* LPCSTR;
typedef unsigned long DWORD;
typedef int BOOL;
typedef size_t SIZE_T;

HANDLE CreateFileMappingA(HANDLE hFile, LPVOID lpFileMappingAttributes, DWORD flProtect,
                          DWORD dwMaximumSizeHigh, DWORD dwMaximumSizeLow, LPCSTR lpName);
LPVOID MapViewOfFile(HANDLE hFileMappingObject, DWORD dwDesiredAccess,
                     DWORD dwFileOffsetHigh, DWORD dwFileOffsetLow, SIZE_T dwNumberOfBytesToMap);
BOOL UnmapViewOfFile(LPVOID lpBaseAddress);
BOOL CloseHandle(HANDLE hObject);

#pragma pack(push, 1)
typedef struct {
    float screenX;
    float screenY;
    float alpha;
    float rise;
    float r;
    float g;
    float b;
    char  text[32];
} DIEntry;

typedef struct {
    float x;
    float y;
    float angle;
    float r;
    float g;
    float b;
    float alpha;
    char label[64];
} DIArrow;

typedef struct {
    float x1, y1;
    float x2, y2;
    float r, g, b, a;
} DISkeletonLine;

typedef struct {
    float screenX;
    float screenY;
    float health;
    float armour;
    float alpha;
    float r;
    float g;
    float b;
    char stateLabel[32];
    char label[64];
} DINameTag;

typedef struct {
    int fontSize;

    int count;
    DIEntry entries[12];

    int arrowCount;
    DIArrow arrows[6];

    int tagCount;
    DINameTag tags[64];

    int tagFontSize;
    float tagBarWidth;
    float tagBarHeight;
    float tagYOffset;
    float tagBarYOffset;

    float hpHighR, hpHighG, hpHighB;
    float hpMidR,  hpMidG,  hpMidB;
    float hpLowR,  hpLowG,  hpLowB;
    float armourR, armourG, armourB;

    float hpBgR, hpBgG, hpBgB;
    float armourBgR, armourBgG, armourBgB;

    int skeletonLineCount;
    DISkeletonLine skeletonLines[1024];
} DISharedData;

#pragma pack(pop)
]]

local PAGE_READWRITE       = 0x04
local FILE_MAP_ALL_ACCESS  = 0xF001F
local INVALID_HANDLE_VALUE = ffi.cast("HANDLE", -1)
local DI_SHMEM_NAME        = "Local\\DamageInformerData"

local g_diMap  = nil
local g_diView = nil
local g_diData = nil

local TAG_MAX_COUNT = 64
local playerArmour = {}
local playerSeat = {}
local playerVehicle = {}
local playerHealth = {}
local lastDlOnVehicleHit = 0
local VEH_DL_COOLDOWN_MS = 1500

local function initSharedDamage()
    if g_diData ~= nil then
        return true
    end

    local size = ffi.sizeof("DISharedData")

    g_diMap = ffi.C.CreateFileMappingA(
        INVALID_HANDLE_VALUE,
        nil,
        PAGE_READWRITE,
        0,
        size,
        DI_SHMEM_NAME
    )

    if g_diMap == nil then
        return false
    end

    g_diView = ffi.C.MapViewOfFile(
        g_diMap,
        FILE_MAP_ALL_ACCESS,
        0,
        0,
        size
    )

    if g_diView == nil then
        ffi.C.CloseHandle(g_diMap)
        g_diMap = nil
        return false
    end

    g_diData = ffi.cast("DISharedData*", g_diView)
    ffi.fill(g_diView, size, 0)
    return true
end

local function shutdownSharedDamage()
    if g_diView ~= nil then
        ffi.C.UnmapViewOfFile(g_diView)
        g_diView = nil
    end
    if g_diMap ~= nil then
        ffi.C.CloseHandle(g_diMap)
        g_diMap = nil
    end
    g_diData = nil
end

local function writeCString(dst, maxLen, text)
    ffi.fill(dst, maxLen, 0)
    if not text then return end
    local safe = tostring(text)
    if #safe >= maxLen then
        safe = safe:sub(1, maxLen - 1)
    end
    ffi.copy(dst, safe)
end
local function getBodyPartCoordinates(boneId, ped)
    if not ped or not doesCharExist(ped) then
        return nil
    end

    local ptr = getCharPointer(ped)
    if ptr == 0 then
        return nil
    end

    local out = ffi.new("float[3]")
    local ok = GetBonePosition(ffi.cast("void*", ptr), out, boneId, true)
    if ok == 0 then
        return nil
    end

    return out[0], out[1], out[2]
end
------------------------------------------------------------
-- CONFIG
------------------------------------------------------------
local ini = inicfg.load({
    main = {
        enabled       = true,
        life_ms       = 2000,
        max_entries   = 6,
        anchor_x      = -1,
        anchor_y      = -1,
        entry_spacing = 22,
        font_size     = 22,
        arrow_radius  = 180,
        show_arrow    = true,
        show_name     = true,
        show_id       = true,
        show_tags = true,
        tag_font_size = 10,
        tag_bar_width = 30,
        tag_bar_height = 5,
        tag_y_offset = 0,
        tag_bar_y_offset = -1,
        player_overlay_distance = 2000,
        show_skeleton = true,
        skeleton_use_nametag_colors = true,
    },

    colors = {
        given_r = 0.2, given_g = 1.0, given_b = 0.2,
        taken_r = 1.0, taken_g = 0.3, taken_b = 0.3,
        arrow_r = 1.0, arrow_g = 0.3, arrow_b = 0.3,
    },

    ui = {
        window_r = 0.10, window_g = 0.10, window_b = 0.10, window_a = 0.94,
        top_r = 0.16, top_g = 0.29, top_b = 0.48, top_a = 1.00,

        frame_r = 0.16, frame_g = 0.29, frame_b = 0.48, frame_a = 0.54,
        frame_hover_r = 0.26, frame_hover_g = 0.59, frame_hover_b = 0.98, frame_hover_a = 0.40,
        frame_active_r = 0.26, frame_active_g = 0.59, frame_active_b = 0.98, frame_active_a = 0.67,

        check_r = 0.26, check_g = 0.59, check_b = 0.98, check_a = 1.00,

        slider_r = 0.24, slider_g = 0.52, slider_b = 0.88, slider_a = 1.00,
        slider_active_r = 0.26, slider_active_g = 0.59, slider_active_b = 0.98, slider_active_a = 1.00,

        button_r = 0.26, button_g = 0.59, button_b = 0.98, button_a = 0.40,
        button_hover_r = 0.26, button_hover_g = 0.59, button_hover_b = 0.98, button_hover_a = 1.00,
        button_active_r = 0.06, button_active_g = 0.53, button_active_b = 0.98, button_active_a = 1.00,

        tab_r = 0.18, tab_g = 0.35, tab_b = 0.58, tab_a = 0.86,
        tab_hover_r = 0.26, tab_hover_g = 0.59, tab_hover_b = 0.98, tab_hover_a = 0.80,
        tab_active_r = 0.20, tab_active_g = 0.41, tab_active_b = 0.68, tab_active_a = 1.00,

        text_r = 1.00, text_g = 1.00, text_b = 1.00, text_a = 1.00,
    },
    nametag_colors = {
        hp_high_r = 0.0, hp_high_g = 0.78, hp_high_b = 0.33,
        hp_mid_r = 1.0, hp_mid_g = 0.76, hp_mid_b = 0.07,
        hp_low_r = 1.0, hp_low_g = 0.32, hp_low_b = 0.32,
        armour_r = 0.90, armour_g = 0.90, armour_b = 0.90,
        hp_bg_r = 0.16, hp_bg_g = 0.16, hp_bg_b = 0.16,
        armour_bg_r = 0.16, armour_bg_g = 0.16, armour_bg_b = 0.16,
    },
    skeleton_colors = {
        skeleton_r = 1.0, skeleton_g = 1.0, skeleton_b = 1.0,
    }
}, "DamageInformer.ini")

------------------------------------------------------------
-- RUNTIME
------------------------------------------------------------
local g_enabled  = ini.main.enabled
local w_enabled  = ini.main.show_tags
local s_enabled  = ini.main.show_skeleton
local entries    = {}
local attackers  = {}
local ATK_LIFE   = 3000
local MAX_ARROWS = 6
local recentVehicleShooters = {}
local VEH_SHOT_MEMORY_MS = 1200
local lastVehicleHealth = nil
local pendingTags = {}


local function msNow()
    return math.floor(os.clock() * 1000)
end

local function addEntry(txt, r, g, b)
    if #entries >= ini.main.max_entries then
        table.remove(entries, 1)
    end
    table.insert(entries, {
        text = txt,
        r = r,
        g = g,
        b = b,
        spawnMs = msNow()
    })
end

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------
local function touchVehicleShooter(pid)
    if not pid or pid < 0 then return end
    recentVehicleShooters[pid] = msNow()
end

local function cleanupVehicleShooters()
    local now = msNow()
    for pid, ts in pairs(recentVehicleShooters) do
        if (now - ts) > VEH_SHOT_MEMORY_MS then
            recentVehicleShooters[pid] = nil
        end
    end
end

local function addVehicleAttackersFromRecentShots()
    local now = msNow()
    for pid, ts in pairs(recentVehicleShooters) do
        if (now - ts) <= VEH_SHOT_MEMORY_MS and sampIsPlayerConnected(pid) then
            local ok, ped = sampGetCharHandleBySampPlayerId(pid)
            if ok then
                local wx, wy, wz = getCharCoordinates(ped)
                attackers[pid] = {
                    pid = pid,
                    name = sampGetPlayerNickname(pid) or "?",
                    wx = wx,
                    wy = wy,
                    wz = wz,
                    spawnMs = now,
                }
            end
        end
    end
end
------------------------------------------------------------
-- EVENTS
------------------------------------------------------------
function sampevents.onSendGiveDamage(targetID, damage, weapon, bodypart)
    if not g_enabled then return end
    addEntry(string.format("+%.1f", damage),
        ini.colors.given_r, ini.colors.given_g, ini.colors.given_b)
end

function sampevents.onSendTakeDamage(senderID, damage, weapon, bodypart)
    if not g_enabled then return end
    addEntry(string.format("-%.1f", damage),
        ini.colors.taken_r, ini.colors.taken_g, ini.colors.taken_b)

    if senderID >= 0 and sampIsPlayerConnected(senderID) then
        local ok, ped = sampGetCharHandleBySampPlayerId(senderID)
        if ok then
            local wx, wy, wz = getCharCoordinates(ped)
            local name = sampGetPlayerNickname(senderID) or "?"

            attackers[senderID] = {
                pid = senderID,
                name = name,
                wx = wx,
                wy = wy,
                wz = wz,
                spawnMs = msNow(),
            }
        end
    end
end
function sampevents.onPlayerSync(playerId, data)
    if playerId ~= nil and data ~= nil then
        playerHealth[playerId] = tonumber(data.health) or 0
        playerArmour[playerId] = tonumber(data.armor) or 0
    end
end
function sampevents.onPlayerQuit(playerId, reason)
    playerHealth[playerId] = nil
    playerArmour[playerId] = nil
    playerSeat[playerId] = nil
    playerVehicle[playerId] = nil
end
function sampevents.onVehicleSync(playerId, vehicleId, data)
    if playerId ~= nil then
        playerSeat[playerId] = 0
        playerVehicle[playerId] = vehicleId
    end
end

function sampevents.onPassengerSync(playerId, data)
    if playerId ~= nil and data ~= nil then
        playerSeat[playerId] = tonumber(data.seatId) or 1
        playerVehicle[playerId] = data.vehicleId
    end
end

function sampevents.onPlayerEnterVehicle(playerId, vehicleId, passenger)
    if playerId ~= nil then
        playerSeat[playerId] = passenger and 1 or 0
        playerVehicle[playerId] = vehicleId
    end
end

function sampevents.onPlayerExitVehicle(playerId, vehicleId)
    if playerId ~= nil then
        playerSeat[playerId] = nil
        playerVehicle[playerId] = nil
    end
end

------------------------------------------------------------
-- ARROW MATH
------------------------------------------------------------
local function getCameraYaw()
    local cx, cy, cz = getActiveCameraCoordinates()
    local tx, ty, tz = getActiveCameraPointAt()

    local dx = tx - cx
    local dy = ty - cy

    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.0001 then
        return 0.0
    end

    dx = dx / len
    dy = dy / len

    return math.atan2(dx, dy)
end

local function getArrowData(wx, wy)
    local sw, sh = getScreenResolution()
    local cx, cy = sw * 0.5, sh * 0.5
    local radius = ini.main.arrow_radius

    local lx, ly = getCharCoordinates(PLAYER_PED)
    local camYaw = getCameraYaw()

    local dx = wx - lx
    local dy = wy - ly

    local sinH = math.sin(camYaw)
    local cosH = math.cos(camYaw)

    local fwdDot   = dx * sinH + dy * cosH
    local rightDot = dx * cosH - dy * sinH

    local scrX = rightDot
    local scrY = -fwdDot

    local len = math.sqrt(scrX * scrX + scrY * scrY)
    if len < 0.001 then
        return nil
    end

    local nx = scrX / len
    local ny = scrY / len

    local ix = cx + nx * radius
    local iy = cy + ny * radius
    local angle = math.atan2(ny, nx) + math.pi * 0.5

    return ix, iy, angle
end

------------------------------------------------------------
-- SHARED MEMORY WRITE
------------------------------------------------------------
local function writeSharedDamage(anchorX, anchorY)
    if not g_enabled then
        if g_diData then
            g_diData.fontSize = ini.main.font_size
            g_diData.count = 0
            g_diData.arrowCount = 0
        end
        return
    end

    if not initSharedDamage() then
        return
    end

    local now = msNow()
    local lifeMs = ini.main.life_ms
    local lineH = ini.main.entry_spacing * 1.4

    g_diData.fontSize = ini.main.font_size
    g_diData.count = 0
    g_diData.arrowCount = 0

    local writeIndex = 0
    for i = 1, #entries do
        local e = entries[i]
        local elapsed = now - e.spawnMs
        if elapsed < lifeMs and writeIndex < 12 then
            local t = elapsed / lifeMs
            local alpha = 1.0 - t
            local rise = t * 35.0

            local slot = g_diData.entries[writeIndex]
            slot.screenX = anchorX
            slot.screenY = anchorY + (writeIndex * lineH)
            slot.alpha = alpha
            slot.rise = rise
            slot.r = e.r
            slot.g = e.g
            slot.b = e.b
            writeCString(slot.text, 32, e.text)

            writeIndex = writeIndex + 1
        end
    end

    g_diData.count = writeIndex

    local arrowIndex = 0
    for pid, a in pairs(attackers) do
        local age = now - a.spawnMs
        if age >= ATK_LIFE then
            attackers[pid] = nil
        elseif arrowIndex < MAX_ARROWS and ini.main.show_arrow then
            local alpha = 1.0 - (age / ATK_LIFE)

            if a.pid >= 0 and sampIsPlayerConnected(a.pid) then
                local ok, ped = sampGetCharHandleBySampPlayerId(a.pid)
                if ok then
                    a.wx, a.wy, a.wz = getCharCoordinates(ped)
                end
            end

            local ix, iy, angle = getArrowData(a.wx, a.wy)
            if ix and iy and angle then
                local slot = g_diData.arrows[arrowIndex]
                slot.x = ix
                slot.y = iy
                slot.angle = angle
                slot.r = ini.colors.arrow_r
                slot.g = ini.colors.arrow_g
                slot.b = ini.colors.arrow_b
                slot.alpha = alpha

                local label = ""
                if ini.main.show_name then
                    label = a.name or ""
                end
                if ini.main.show_id then
                    local idStr = "[" .. tostring(a.pid) .. "]"
                    label = label ~= "" and (label .. " " .. idStr) or idStr
                end

                writeCString(slot.label, 64, label)
                arrowIndex = arrowIndex + 1
            end
        end
    end

    g_diData.arrowCount = arrowIndex
end

local function writeSharedNameTags()
    if not g_diData then return end

    g_diData.tagCount = 0
    g_diData.tagFontSize = ini.main.tag_font_size or 10
    g_diData.tagBarWidth = ini.main.tag_bar_width or 30
    g_diData.tagBarHeight = ini.main.tag_bar_height or 5
    g_diData.tagYOffset = ini.main.tag_y_offset or 0
    g_diData.tagBarYOffset = ini.main.tag_bar_y_offset or 0

    g_diData.hpHighR = ini.nametag_colors.hp_high_r or 0.0
    g_diData.hpHighG = ini.nametag_colors.hp_high_g or 0.78
    g_diData.hpHighB = ini.nametag_colors.hp_high_b or 0.33

    g_diData.hpMidR = ini.nametag_colors.hp_mid_r or 1.0
    g_diData.hpMidG = ini.nametag_colors.hp_mid_g or 0.76
    g_diData.hpMidB = ini.nametag_colors.hp_mid_b or 0.07

    g_diData.hpLowR = ini.nametag_colors.hp_low_r or 1.0
    g_diData.hpLowG = ini.nametag_colors.hp_low_g or 0.32
    g_diData.hpLowB = ini.nametag_colors.hp_low_b or 0.32

    g_diData.armourR = ini.nametag_colors.armour_r or 0.90
    g_diData.armourG = ini.nametag_colors.armour_g or 0.90
    g_diData.armourB = ini.nametag_colors.armour_b or 0.90

    g_diData.hpBgR = ini.nametag_colors.hp_bg_r or 0.16
    g_diData.hpBgG = ini.nametag_colors.hp_bg_g or 0.16
    g_diData.hpBgB = ini.nametag_colors.hp_bg_b or 0.16

    g_diData.armourBgR = ini.nametag_colors.armour_bg_r or 0.16
    g_diData.armourBgG = ini.nametag_colors.armour_bg_g or 0.16
    g_diData.armourBgB = ini.nametag_colors.armour_bg_b or 0.16

    local maxDist = ini.main.player_overlay_distance or 2000

    if not w_enabled or not ini.main.show_tags then
        return
    end

    local mx, my, mz = getCharCoordinates(PLAYER_PED)
    local pendingTags = {}

    for _, ped in ipairs(getAllChars()) do
        if #pendingTags >= TAG_MAX_COUNT then break end

        if doesCharExist(ped) and ped ~= PLAYER_PED and not isCharDead(ped) then
            local ok, pid = sampGetPlayerIdByCharHandle(ped)
            if ok and sampIsPlayerConnected(pid) then
                local x, y, z = getCharCoordinates(ped)
                local dist = getDistanceBetweenCoords3d(mx, my, mz, x, y, z)
                local tx, ty, tz = x, y, z + 0.8
                local hx, hy, hz = getBodyPartCoordinates(8, ped)
                if hx and hy and hz then
                    tx, ty, tz = hx, hy, hz + 0.05
                end

                local cx, cy, cz = getActiveCameraCoordinates()
                local visibleDirectly = isLineOfSightClear(
                    cx, cy, cz,
                    tx, ty, tz,
                    true,
                    false,
                    false,
                    true,
                    false
                )
                local serverTagLikelyVisible = visibleDirectly and dist <= 47
                if dist <= maxDist and isCharOnScreen(ped) and not serverTagLikelyVisible then
                    local tx, ty, tz = x, y, z + 1.1
                    local hx, hy, hz = getBodyPartCoordinates(8, ped)
                    if hx and hy and hz then
                        tx, ty, tz = hx, hy, hz + 0.08
                    end

                    local sx, sy = convert3DCoordsToScreen(tx, ty, tz)
                    local sw, sh = getScreenResolution()

                    local screenMarginX = 8
                    local screenMarginTop = 25
                    local screenMarginBottom = 8

                    if sx and sy
                    and sx >= screenMarginX
                    and sx <= (sw - screenMarginX)
                    and sy >= screenMarginTop
                    and sy <= (sh - screenMarginBottom) then
                        local hp = playerHealth[pid]
                        if hp == nil then
                            hp = getCharHealth(ped)
                        end
                        if hp < 0 then hp = 0 end
                        if hp > 100 then hp = 100 end

                        local armor = playerArmour[pid] or 0
                        if armor < 0 then armor = 0 end
                        if armor > 100 then armor = 100 end

                        local name = sampGetPlayerNickname(pid) or "?"
                        local seat = nil
                        local stateLine = nil
                        local veh = -1

                        if isCharInAnyCar(ped) then
                            veh = storeCarCharIsInNoSave(ped)
                            seat = playerSeat[pid]

                            if seat == 0 then
                                stateLine = "[Driving]"
                            elseif seat ~= nil and seat >= 1 then
                                stateLine = "[Passenger]"
                            end
                        else
                            playerSeat[pid] = nil
                            playerVehicle[pid] = nil
                            seat = nil
                        end

                        local label = string.format("%s [%d]", name, pid)

                        local r, g, b = 1.0, 1.0, 1.0
                        local color = sampGetPlayerColor(pid)
                        if color ~= 0 then
                            local a8 = bit.band(bit.rshift(color, 24), 0xFF)
                            local r8 = bit.band(bit.rshift(color, 16), 0xFF)
                            local g8 = bit.band(bit.rshift(color, 8), 0xFF)
                            local b8 = bit.band(color, 0xFF)

                            r = r8 / 255.0
                            g = g8 / 255.0
                            b = b8 / 255.0
                        end
                        local veh = -1
                        if isCharInAnyCar(ped) then
                            veh = storeCarCharIsInNoSave(ped)
                        end
                        table.insert(pendingTags, {
                            screenX = sx,
                            screenY = sy,
                            health = hp,
                            armour = armor,
                            alpha = 1.0 - math.min(dist / maxDist, 1.0),
                            stateLabel = stateLine,
                            label = label,
                            r = r,
                            g = g,
                            b = b,
                            inVehicle = veh ~= -1,
                            vehicle = veh
                        })
                    end
                end
            end
        end
    end

    table.sort(pendingTags, function(a, b)
        if a.screenY == b.screenY then
            return a.screenX < b.screenX
        end
        return a.screenY < b.screenY
    end)

    local placed = {}
    local textHalfW = 90.0
    local textTopOffset = -12.0 + (ini.main.tag_y_offset or 0)
    local textHeight = 13.0
    local barYOffset = 1.0 + (ini.main.tag_y_offset or 0) + (ini.main.tag_bar_y_offset or 0)
    local barHeight = (ini.main.tag_bar_height or 5)
    local totalTop = math.min(textTopOffset, barYOffset)
    local hasAnyArmour = true
    local secondBarGap = 2.0
    local totalBottom = math.max(
        textTopOffset + textHeight,
        barYOffset + barHeight + secondBarGap + barHeight
    )
    local tagBoxH = totalBottom - totalTop
    local stackGap = 3.0

    local function overlaps(a, b)
        local ax1 = a.screenX - textHalfW
        local ay1 = a.screenY + totalTop
        local ax2 = a.screenX + textHalfW
        local ay2 = ay1 + tagBoxH

        local bx1 = b.screenX - textHalfW
        local by1 = b.screenY + totalTop
        local bx2 = b.screenX + textHalfW
        local by2 = by1 + tagBoxH

        return ax1 < bx2 and ax2 > bx1 and ay1 < by2 and ay2 > by1
    end

    local sw, sh = getScreenResolution()

    for i = 1, #pendingTags do
        local t = pendingTags[i]
        local tries = 0

        if t.inVehicle then
            while tries < 20 do
                local collided = false

                for j = 1, #placed do
                    if placed[j].inVehicle and t.vehicle == placed[j].vehicle and overlaps(t, placed[j]) then
                        t.screenY = placed[j].screenY - tagBoxH - stackGap
                        collided = true
                        break
                    end
                end

                if not collided then
                    break
                end

                tries = tries + 1
            end
        end

        local minY = -totalTop + 2.0
        local maxY = sh - totalBottom - 2.0

        if t.screenY < minY then t.screenY = minY end
        if t.screenY > maxY then t.screenY = maxY end

        table.insert(placed, t)
    end

    local writeCount = math.min(#placed, TAG_MAX_COUNT)
    for i = 1, writeCount do
        local src = placed[i]
        local slot = g_diData.tags[i - 1]

        slot.screenX = src.screenX
        slot.screenY = src.screenY
        slot.health = src.health
        slot.armour = src.armour
        slot.alpha = src.alpha
        slot.r = src.r
        slot.g = src.g
        slot.b = src.b
        writeCString(slot.stateLabel, 32, src.stateLabel)
        writeCString(slot.label, 64, src.label)
    end

    g_diData.tagCount = writeCount
end

local skeletonPairs = {
    {2, 3}, {3, 4}, {4, 5},
    {4, 21}, {21, 22}, {22, 23},
    {4, 31}, {31, 32}, {32, 33},
    {2, 41}, {41, 42}, {42, 43},
    {2, 51}, {51, 52}, {52, 53},
}

local function getBodyPartCoordinates(id, handle)
    if not doesCharExist(handle) then return nil end

    local pedptr = getCharPointer(handle)
    if not pedptr or pedptr == 0 then
        return nil
    end

    local vec = ffi.new("float[3]")
    GetBonePosition(ffi.cast("void*", pedptr), vec, id, true)
    return vec[0], vec[1], vec[2]
end

local function writeSharedSkeleton()
    if not g_diData then return end

    g_diData.skeletonLineCount = 0
    if not s_enabled or not ini.main.show_skeleton then
        return
    end

    local maxLines = 1024
    local lineIndex = 0
    local mx, my, mz = getCharCoordinates(PLAYER_PED)
    local maxDist = ini.main.player_overlay_distance or 2000

    for _, ped in ipairs(getAllChars()) do
        if lineIndex >= maxLines then break end

        if doesCharExist(ped) and ped ~= PLAYER_PED and not isCharDead(ped) then
            local ok, pid = sampGetPlayerIdByCharHandle(ped)
            if ok and sampIsPlayerConnected(pid) and isCharOnScreen(ped) then
                local x, y, z = getCharCoordinates(ped)
                local dist = getDistanceBetweenCoords3d(mx, my, mz, x, y, z)

                if dist <= maxDist then
                    local r, g, b, a

                    if ini.main.skeleton_use_nametag_colors ~= false then
                        local color = sampGetPlayerColor(pid)
                        a = bit.band(bit.rshift(color, 24), 0xFF) / 255.0
                        r = bit.band(bit.rshift(color, 16), 0xFF) / 255.0
                        g = bit.band(bit.rshift(color, 8), 0xFF) / 255.0
                        b = bit.band(color, 0xFF) / 255.0
                    else
                        r = ini.skeleton_colors.skeleton_r or 1.0
                        g = ini.skeleton_colors.skeleton_g or 1.0
                        b = ini.skeleton_colors.skeleton_b or 1.0
                        a = 1.0
                    end

                    for i = 1, #skeletonPairs do
                        if lineIndex >= maxLines then break end

                        local boneA = skeletonPairs[i][1]
                        local boneB = skeletonPairs[i][2]

                        local wx1, wy1, wz1 = getBodyPartCoordinates(boneA, ped)
                        local wx2, wy2, wz2 = getBodyPartCoordinates(boneB, ped)

                        if wx1 and wx2 then
                            local ok1, sx1, sy1 = convert3DCoordsToScreenEx(wx1, wy1, wz1, false, false)
                            local ok2, sx2, sy2 = convert3DCoordsToScreenEx(wx2, wy2, wz2, false, false)

                            if ok1 and ok2 then
                                local slot = g_diData.skeletonLines[lineIndex]
                                slot.x1, slot.y1 = sx1, sy1
                                slot.x2, slot.y2 = sx2, sy2
                                slot.r, slot.g, slot.b, slot.a = r, g, b, a
                                lineIndex = lineIndex + 1
                            end
                        end
                    end
                end
            end
        end
    end

    g_diData.skeletonLineCount = lineIndex
end

------------------------------------------------------------
-- IMGUI CONTROLS
------------------------------------------------------------
local wnd_open          = imgui.new.bool(false)
local current_tab       = imgui.new.int(0)
local cb_enabled        = imgui.new.bool(ini.main.enabled)
local cb_arrow          = imgui.new.bool(ini.main.show_arrow)
local cb_name           = imgui.new.bool(ini.main.show_name)
local cb_id             = imgui.new.bool(ini.main.show_id)
local cb_tags           = imgui.new.bool(ini.main.show_tags)
local sl_tagFont        = imgui.new.int(ini.main.tag_font_size or 10)
local sl_tagBarW        = imgui.new.int(ini.main.tag_bar_width or 30)
local sl_tagBarH        = imgui.new.int(ini.main.tag_bar_height or 5)
local sl_tagY           = imgui.new.int(ini.main.tag_y_offset or 0)
local sl_tagBarY        = imgui.new.int(ini.main.tag_bar_y_offset or -1)
local cb_skeleton       = imgui.new.bool(ini.main.show_skeleton)
local sl_overlayDist    = imgui.new.int(ini.main.player_overlay_distance or 2000)

local ui_col_window        = imgui.new.float[4](ini.ui.window_r, ini.ui.window_g, ini.ui.window_b, ini.ui.window_a)
local ui_col_title         = imgui.new.float[4](ini.ui.top_r, ini.ui.top_g, ini.ui.top_b, ini.ui.top_a)

local ui_col_frame         = imgui.new.float[4](ini.ui.frame_r, ini.ui.frame_g, ini.ui.frame_b, ini.ui.frame_a)
local ui_col_frame_hover   = imgui.new.float[4](ini.ui.frame_hover_r, ini.ui.frame_hover_g, ini.ui.frame_hover_b, ini.ui.frame_hover_a)
local ui_col_frame_active  = imgui.new.float[4](ini.ui.frame_active_r, ini.ui.frame_active_g, ini.ui.frame_active_b, ini.ui.frame_active_a)

local ui_col_checkmark     = imgui.new.float[4](ini.ui.check_r, ini.ui.check_g, ini.ui.check_b, ini.ui.check_a)

local ui_col_slider        = imgui.new.float[4](ini.ui.slider_r, ini.ui.slider_g, ini.ui.slider_b, ini.ui.slider_a)
local ui_col_slider_active = imgui.new.float[4](ini.ui.slider_active_r, ini.ui.slider_active_g, ini.ui.slider_active_b, ini.ui.slider_active_a)

local ui_col_button        = imgui.new.float[4](ini.ui.button_r, ini.ui.button_g, ini.ui.button_b, ini.ui.button_a)
local ui_col_button_hov    = imgui.new.float[4](ini.ui.button_hover_r, ini.ui.button_hover_g, ini.ui.button_hover_b, ini.ui.button_hover_a)
local ui_col_button_active = imgui.new.float[4](ini.ui.button_active_r, ini.ui.button_active_g, ini.ui.button_active_b, ini.ui.button_active_a)

local ui_col_tab           = imgui.new.float[4](ini.ui.tab_r, ini.ui.tab_g, ini.ui.tab_b, ini.ui.tab_a)
local ui_col_tab_hover     = imgui.new.float[4](ini.ui.tab_hover_r, ini.ui.tab_hover_g, ini.ui.tab_hover_b, ini.ui.tab_hover_a)
local ui_col_tab_active    = imgui.new.float[4](ini.ui.tab_active_r, ini.ui.tab_active_g, ini.ui.tab_active_b, ini.ui.tab_active_a)

local ui_col_text          = imgui.new.float[4](ini.ui.text_r, ini.ui.text_g, ini.ui.text_b, ini.ui.text_a)

local col_hp_high           = imgui.new.float[3](ini.nametag_colors.hp_high_r, ini.nametag_colors.hp_high_g, ini.nametag_colors.hp_high_b)
local col_hp_mid            = imgui.new.float[3](ini.nametag_colors.hp_mid_r,  ini.nametag_colors.hp_mid_g,  ini.nametag_colors.hp_mid_b)
local col_hp_low            = imgui.new.float[3](ini.nametag_colors.hp_low_r,  ini.nametag_colors.hp_low_g,  ini.nametag_colors.hp_low_b)
local col_armour            = imgui.new.float[3](ini.nametag_colors.armour_r,  ini.nametag_colors.armour_g,  ini.nametag_colors.armour_b)

local col_hp_bg             = imgui.new.float[3](ini.nametag_colors.hp_bg_r, ini.nametag_colors.hp_bg_g, ini.nametag_colors.hp_bg_b)
local col_armour_bg         = imgui.new.float[3](ini.nametag_colors.armour_bg_r, ini.nametag_colors.armour_bg_g, ini.nametag_colors.armour_bg_b)

local cb_skeleton_nametag   = imgui.new.bool(ini.main.skeleton_use_nametag_colors ~= false)
local col_skeleton          = imgui.new.float[3](ini.skeleton_colors.skeleton_r or 1.0, ini.skeleton_colors.skeleton_g or 1.0, ini.skeleton_colors.skeleton_b or 1.0)

local sl_life     = imgui.new.int(ini.main.life_ms)
local sl_max      = imgui.new.int(ini.main.max_entries)
local sl_fsize    = imgui.new.int(ini.main.font_size)
local sl_spacing  = imgui.new.int(ini.main.entry_spacing or 31)
local sl_radius   = imgui.new.int(ini.main.arrow_radius)
local sl_ancX     = imgui.new.int(ini.main.anchor_x > 0 and ini.main.anchor_x or 0)
local sl_ancY     = imgui.new.int(ini.main.anchor_y > 0 and ini.main.anchor_y or 0)

local col_give    = imgui.new.float[3](ini.colors.given_r, ini.colors.given_g, ini.colors.given_b)
local col_take    = imgui.new.float[3](ini.colors.taken_r, ini.colors.taken_g, ini.colors.taken_b)
local col_arrow   = imgui.new.float[3](ini.colors.arrow_r, ini.colors.arrow_g, ini.colors.arrow_b)

local function saveUiColors()
    ini.ui.window_r, ini.ui.window_g, ini.ui.window_b, ini.ui.window_a = ui_col_window[0], ui_col_window[1], ui_col_window[2], ui_col_window[3]
    ini.ui.top_r, ini.ui.top_g, ini.ui.top_b, ini.ui.top_a = ui_col_title[0], ui_col_title[1], ui_col_title[2], ui_col_title[3]

    ini.ui.frame_r, ini.ui.frame_g, ini.ui.frame_b, ini.ui.frame_a = ui_col_frame[0], ui_col_frame[1], ui_col_frame[2], ui_col_frame[3]
    ini.ui.frame_hover_r, ini.ui.frame_hover_g, ini.ui.frame_hover_b, ini.ui.frame_hover_a = ui_col_frame_hover[0], ui_col_frame_hover[1], ui_col_frame_hover[2], ui_col_frame_hover[3]
    ini.ui.frame_active_r, ini.ui.frame_active_g, ini.ui.frame_active_b, ini.ui.frame_active_a = ui_col_frame_active[0], ui_col_frame_active[1], ui_col_frame_active[2], ui_col_frame_active[3]

    ini.ui.check_r, ini.ui.check_g, ini.ui.check_b, ini.ui.check_a = ui_col_checkmark[0], ui_col_checkmark[1], ui_col_checkmark[2], ui_col_checkmark[3]

    ini.ui.slider_r, ini.ui.slider_g, ini.ui.slider_b, ini.ui.slider_a = ui_col_slider[0], ui_col_slider[1], ui_col_slider[2], ui_col_slider[3]
    ini.ui.slider_active_r, ini.ui.slider_active_g, ini.ui.slider_active_b, ini.ui.slider_active_a = ui_col_slider_active[0], ui_col_slider_active[1], ui_col_slider_active[2], ui_col_slider_active[3]

    ini.ui.button_r, ini.ui.button_g, ini.ui.button_b, ini.ui.button_a = ui_col_button[0], ui_col_button[1], ui_col_button[2], ui_col_button[3]
    ini.ui.button_hover_r, ini.ui.button_hover_g, ini.ui.button_hover_b, ini.ui.button_hover_a = ui_col_button_hov[0], ui_col_button_hov[1], ui_col_button_hov[2], ui_col_button_hov[3]
    ini.ui.button_active_r, ini.ui.button_active_g, ini.ui.button_active_b, ini.ui.button_active_a = ui_col_button_active[0], ui_col_button_active[1], ui_col_button_active[2], ui_col_button_active[3]

    ini.ui.tab_r, ini.ui.tab_g, ini.ui.tab_b, ini.ui.tab_a = ui_col_tab[0], ui_col_tab[1], ui_col_tab[2], ui_col_tab[3]
    ini.ui.tab_hover_r, ini.ui.tab_hover_g, ini.ui.tab_hover_b, ini.ui.tab_hover_a = ui_col_tab_hover[0], ui_col_tab_hover[1], ui_col_tab_hover[2], ui_col_tab_hover[3]
    ini.ui.tab_active_r, ini.ui.tab_active_g, ini.ui.tab_active_b, ini.ui.tab_active_a = ui_col_tab_active[0], ui_col_tab_active[1], ui_col_tab_active[2], ui_col_tab_active[3]

    ini.ui.text_r, ini.ui.text_g, ini.ui.text_b, ini.ui.text_a = ui_col_text[0], ui_col_text[1], ui_col_text[2], ui_col_text[3]

    inicfg.save(ini, "DamageInformer.ini")
end

local settings = imgui.OnFrame(
    function() return wnd_open[0] end,
    function(self)
        local sw, sh = getScreenResolution()
        imgui.SetNextWindowSize(imgui.ImVec2(420, 0), imgui.Cond.Always)
        imgui.SetNextWindowPos(
            imgui.ImVec2(sw * 0.5, sh * 0.5),
            imgui.Cond.FirstUseEver,
            imgui.ImVec2(0.5, 0.5)
        )

        -- UI style colors
        local style = imgui.GetStyle()
        local colors = style.Colors

        colors[imgui.Col.WindowBg]         = imgui.ImVec4(ui_col_window[0], ui_col_window[1], ui_col_window[2], ui_col_window[3])
        colors[imgui.Col.TitleBg]          = imgui.ImVec4(ui_col_title[0], ui_col_title[1], ui_col_title[2], ui_col_title[3])
        colors[imgui.Col.TitleBgActive]    = imgui.ImVec4(ui_col_title[0], ui_col_title[1], ui_col_title[2], ui_col_title[3])
        colors[imgui.Col.FrameBg]          = imgui.ImVec4(ui_col_frame[0], ui_col_frame[1], ui_col_frame[2], ui_col_frame[3])
        colors[imgui.Col.Button]           = imgui.ImVec4(ui_col_button[0], ui_col_button[1], ui_col_button[2], ui_col_button[3])
        colors[imgui.Col.ButtonHovered]    = imgui.ImVec4(ui_col_button_hov[0], ui_col_button_hov[1], ui_col_button_hov[2], ui_col_button_hov[3])
        colors[imgui.Col.Tab]              = imgui.ImVec4(ui_col_tab[0], ui_col_tab[1], ui_col_tab[2], ui_col_tab[3])
        colors[imgui.Col.Text]             = imgui.ImVec4(ui_col_text[0], ui_col_text[1], ui_col_text[2], ui_col_text[3])
        colors[imgui.Col.FrameBgHovered]   = imgui.ImVec4(ui_col_frame_hover[0], ui_col_frame_hover[1], ui_col_frame_hover[2], ui_col_frame_hover[3])
        colors[imgui.Col.FrameBgActive]    = imgui.ImVec4(ui_col_frame_active[0], ui_col_frame_active[1], ui_col_frame_active[2], ui_col_frame_active[3])
        colors[imgui.Col.CheckMark]        = imgui.ImVec4(ui_col_checkmark[0], ui_col_checkmark[1], ui_col_checkmark[2], ui_col_checkmark[3])
        colors[imgui.Col.SliderGrab]       = imgui.ImVec4(ui_col_slider[0], ui_col_slider[1], ui_col_slider[2], ui_col_slider[3])
        colors[imgui.Col.SliderGrabActive] = imgui.ImVec4(ui_col_slider_active[0], ui_col_slider_active[1], ui_col_slider_active[2], ui_col_slider_active[3])
        colors[imgui.Col.ButtonActive]     = imgui.ImVec4(ui_col_button_active[0], ui_col_button_active[1], ui_col_button_active[2], ui_col_button_active[3])
        colors[imgui.Col.TabHovered]       = imgui.ImVec4(ui_col_tab_hover[0], ui_col_tab_hover[1], ui_col_tab_hover[2], ui_col_tab_hover[3])
        colors[imgui.Col.TabActive]         = imgui.ImVec4(ui_col_tab_active[0], ui_col_tab_active[1], ui_col_tab_active[2], ui_col_tab_active[3])
        imgui.Begin(
            u8("DamageInformer v6.0"),
            wnd_open,
            imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize
        )

        if imgui.BeginTabBar("##ditabs") then
            if imgui.BeginTabItem(u8("Settings")) then
                current_tab[0] = 0

                if imgui.Checkbox(u8("Enabled"), cb_enabled) then
                    g_enabled = cb_enabled[0]
                    ini.main.enabled = g_enabled
                    inicfg.save(ini, "DamageInformer.ini")
                end

                imgui.Separator()
                imgui.TextDisabled(u8("Colors"))
                if imgui.ColorEdit3(u8("Given damage##cg"), col_give) then
                    ini.colors.given_r, ini.colors.given_g, ini.colors.given_b =
                        col_give[0], col_give[1], col_give[2]
                    inicfg.save(ini, "DamageInformer.ini")
                end
                if imgui.ColorEdit3(u8("Taken damage##ct"), col_take) then
                    ini.colors.taken_r, ini.colors.taken_g, ini.colors.taken_b =
                        col_take[0], col_take[1], col_take[2]
                    inicfg.save(ini, "DamageInformer.ini")
                end
                if imgui.ColorEdit3(u8("Arrow / attacker##ca"), col_arrow) then
                    ini.colors.arrow_r, ini.colors.arrow_g, ini.colors.arrow_b =
                        col_arrow[0], col_arrow[1], col_arrow[2]
                    inicfg.save(ini, "DamageInformer.ini")
                end

                imgui.Separator()
                imgui.TextDisabled(u8("Arrow"))
                if imgui.Checkbox(u8("Show arrow indicator"), cb_arrow) then
                    ini.main.show_arrow = cb_arrow[0]
                    inicfg.save(ini, "DamageInformer.ini")
                end
                if imgui.Checkbox(u8("Show attacker name"), cb_name) then
                    ini.main.show_name = cb_name[0]
                    inicfg.save(ini, "DamageInformer.ini")
                end
                if imgui.Checkbox(u8("Show attacker ID"), cb_id) then
                    ini.main.show_id = cb_id[0]
                    inicfg.save(ini, "DamageInformer.ini")
                end

                imgui.PushItemWidth(180)
                if imgui.SliderInt(u8("Arrow radius (px)##ar"), sl_radius, 60, 500, "%d px") then
                    ini.main.arrow_radius = sl_radius[0]
                    inicfg.save(ini, "DamageInformer.ini")
                end
                imgui.PopItemWidth()

                imgui.Separator()
                imgui.TextDisabled(u8("Damage numbers"))
                imgui.PushItemWidth(180)

                if imgui.SliderInt(u8("Font size##fs"), sl_fsize, 8, 48, "%d px") then
                    ini.main.font_size = sl_fsize[0]
                    inicfg.save(ini, "DamageInformer.ini")
                end

                if imgui.SliderInt(u8("Entry spacing##sp"), sl_spacing, 12, 80, "%d px") then
                    ini.main.entry_spacing = sl_spacing[0]
                    inicfg.save(ini, "DamageInformer.ini")
                end

                if imgui.SliderInt(u8("Lifetime (ms)##lf"), sl_life, 500, 5000, "%d ms") then
                    ini.main.life_ms = sl_life[0]
                    inicfg.save(ini, "DamageInformer.ini")
                end

                if imgui.SliderInt(u8("Max visible##mx"), sl_max, 1, 12, "%d") then
                    ini.main.max_entries = sl_max[0]
                    inicfg.save(ini, "DamageInformer.ini")
                end

                imgui.PopItemWidth()

                imgui.Separator()
                imgui.TextDisabled(u8("Position"))
                imgui.PushItemWidth(180)
                local sw2, sh2 = getScreenResolution()
                if imgui.SliderInt(u8("Anchor X##ax"), sl_ancX, 0, sw2, "%d") then
                    ini.main.anchor_x = sl_ancX[0]
                    inicfg.save(ini, "DamageInformer.ini")
                end
                if imgui.SliderInt(u8("Anchor Y##ay"), sl_ancY, 0, sh2, "%d") then
                    ini.main.anchor_y = sl_ancY[0]
                    inicfg.save(ini, "DamageInformer.ini")
                end

                imgui.PopItemWidth()

                imgui.Separator()
                if imgui.Button(u8("Test entries"), imgui.ImVec2(130, 0)) then
                    addEntry("+24.3", ini.colors.given_r, ini.colors.given_g, ini.colors.given_b)
                    addEntry("-18.0", ini.colors.taken_r, ini.colors.taken_g, ini.colors.taken_b)
                    local x, y, z = getCharCoordinates(PLAYER_PED)
                    attackers[0] = { pid = 0, name = "TestPlayer", wx = x + 20, wy = y + 20, wz = z, spawnMs = msNow() }
                    attackers[1] = { pid = 1, name = "TestPlayer2", wx = x - 20, wy = y + 25, wz = z, spawnMs = msNow() }
                end

                imgui.TextDisabled(u8("/di to toggle"))
                imgui.EndTabItem()
            end

            if imgui.BeginTabItem(u8("UI")) then
                current_tab[0] = 2

                imgui.Text(u8("Interface colors"))
                imgui.Separator()

                if imgui.ColorEdit4(u8("Window background##uiw"), ui_col_window) then saveUiColors() end
                if imgui.ColorEdit4(u8("Top bar##uit"), ui_col_title) then saveUiColors() end
                if imgui.ColorEdit4(u8("Frame background##uif"), ui_col_frame) then saveUiColors() end
                if imgui.ColorEdit4(u8("Frame hovered##uifh"), ui_col_frame_hover) then saveUiColors() end
                if imgui.ColorEdit4(u8("Frame active##uifa"), ui_col_frame_active) then saveUiColors() end
                if imgui.ColorEdit4(u8("Checkmark##uick"), ui_col_checkmark) then saveUiColors() end
                if imgui.ColorEdit4(u8("Slider grab##uisg"), ui_col_slider) then saveUiColors() end
                if imgui.ColorEdit4(u8("Slider grab active##uisga"), ui_col_slider_active) then saveUiColors() end
                if imgui.ColorEdit4(u8("Button##uib"), ui_col_button) then saveUiColors() end
                if imgui.ColorEdit4(u8("Button hovered##uibh"), ui_col_button_hov) then saveUiColors() end
                if imgui.ColorEdit4(u8("Button active##uiba"), ui_col_button_active) then saveUiColors() end
                if imgui.ColorEdit4(u8("Tab##uitab"), ui_col_tab) then saveUiColors() end
                if imgui.ColorEdit4(u8("Tab hovered##uitabh"), ui_col_tab_hover) then saveUiColors() end
                if imgui.ColorEdit4(u8("Tab active##uitaba"), ui_col_tab_active) then saveUiColors() end
                if imgui.ColorEdit4(u8("Text##uitxt"), ui_col_text) then saveUiColors() end

                imgui.Separator()
                if imgui.Button(u8("Reset UI colors"), imgui.ImVec2(140, 0)) then
                    ui_col_window[0], ui_col_window[1], ui_col_window[2], ui_col_window[3] = 0.10, 0.10, 0.10, 0.94
                    ui_col_title[0], ui_col_title[1], ui_col_title[2], ui_col_title[3] = 0.16, 0.29, 0.48, 1.00
                    ui_col_frame[0], ui_col_frame[1], ui_col_frame[2], ui_col_frame[3] = 0.16, 0.29, 0.48, 0.54
                    ui_col_frame_hover[0], ui_col_frame_hover[1], ui_col_frame_hover[2], ui_col_frame_hover[3] = 0.26, 0.59, 0.98, 0.40
                    ui_col_frame_active[0], ui_col_frame_active[1], ui_col_frame_active[2], ui_col_frame_active[3] = 0.26, 0.59, 0.98, 0.67
                    ui_col_checkmark[0], ui_col_checkmark[1], ui_col_checkmark[2], ui_col_checkmark[3] = 0.26, 0.59, 0.98, 1.00
                    ui_col_slider[0], ui_col_slider[1], ui_col_slider[2], ui_col_slider[3] = 0.24, 0.52, 0.88, 1.00
                    ui_col_slider_active[0], ui_col_slider_active[1], ui_col_slider_active[2], ui_col_slider_active[3] = 0.26, 0.59, 0.98, 1.00
                    ui_col_button[0], ui_col_button[1], ui_col_button[2], ui_col_button[3] = 0.26, 0.59, 0.98, 0.40
                    ui_col_button_hov[0], ui_col_button_hov[1], ui_col_button_hov[2], ui_col_button_hov[3] = 0.26, 0.59, 0.98, 1.00
                    ui_col_button_active[0], ui_col_button_active[1], ui_col_button_active[2], ui_col_button_active[3] = 0.06, 0.53, 0.98, 1.00
                    ui_col_tab[0], ui_col_tab[1], ui_col_tab[2], ui_col_tab[3] = 0.18, 0.35, 0.58, 0.86
                    ui_col_tab_hover[0], ui_col_tab_hover[1], ui_col_tab_hover[2], ui_col_tab_hover[3] = 0.26, 0.59, 0.98, 0.80
                    ui_col_tab_active[0], ui_col_tab_active[1], ui_col_tab_active[2], ui_col_tab_active[3] = 0.20, 0.41, 0.68, 1.00
                    ui_col_text[0], ui_col_text[1], ui_col_text[2], ui_col_text[3] = 1.00, 1.00, 1.00, 1.00
                    saveUiColors()
                end

                imgui.EndTabItem()
            end

            if imgui.BeginTabItem(u8("Nametags")) then
                current_tab[0] = 3

                
                if imgui.Checkbox(u8("Show nearby player tags"), cb_tags) then
                    w_enabled = cb_tags[0]
                    ini.main.show_tags = w_enabled
                    inicfg.save(ini, "DamageInformer.ini")
                end
                imgui.Separator()

                imgui.TextDisabled(u8("Nearby tags"))
                imgui.PushItemWidth(180)

                if imgui.SliderInt(u8("Tag font size##tfs"), sl_tagFont, 6, 24, "%d px") then
                    ini.main.tag_font_size = sl_tagFont[0]
                    inicfg.save(ini, "DamageInformer.ini")
                end

                if imgui.SliderInt(u8("Tag bar width##tbw"), sl_tagBarW, 10, 80, "%d px") then
                    ini.main.tag_bar_width = sl_tagBarW[0]
                    inicfg.save(ini, "DamageInformer.ini")
                end

                if imgui.SliderInt(u8("Tag bar height##tbh"), sl_tagBarH, 2, 12, "%d px") then
                    ini.main.tag_bar_height = sl_tagBarH[0]
                    inicfg.save(ini, "DamageInformer.ini")
                end

                if imgui.SliderInt(u8("Tag Y offset##tyo"), sl_tagY, -20, 20, "%d") then
                    ini.main.tag_y_offset = sl_tagY[0]
                    inicfg.save(ini, "DamageInformer.ini")
                end

                if imgui.SliderInt(u8("Tag bar Y offset##tbyo"), sl_tagBarY, -20, 20, "%d") then
                    ini.main.tag_bar_y_offset = sl_tagBarY[0]
                    inicfg.save(ini, "DamageInformer.ini")
                end

                if imgui.SliderInt(u8("Player overlay distance##pod"), sl_overlayDist, 5, 20000, "%d m") then
                    ini.main.player_overlay_distance = sl_overlayDist[0]
                    inicfg.save(ini, "DamageInformer.ini")
                end
                imgui.Separator()
                imgui.TextDisabled(u8("Health/Armour bar colors"))
                imgui.PushItemWidth(180)

                if imgui.ColorEdit3(u8("Health high##chh"), col_hp_high) then
                    ini.nametag_colors.hp_high_r, ini.nametag_colors.hp_high_g, ini.nametag_colors.hp_high_b =
                        col_hp_high[0], col_hp_high[1], col_hp_high[2]
                    inicfg.save(ini, "DamageInformer.ini")
                end

                if imgui.ColorEdit3(u8("Health medium##chm"), col_hp_mid) then
                    ini.nametag_colors.hp_mid_r, ini.nametag_colors.hp_mid_g, ini.nametag_colors.hp_mid_b =
                        col_hp_mid[0], col_hp_mid[1], col_hp_mid[2]
                    inicfg.save(ini, "DamageInformer.ini")
                end

                if imgui.ColorEdit3(u8("Health low##chl"), col_hp_low) then
                    ini.nametag_colors.hp_low_r, ini.nametag_colors.hp_low_g, ini.nametag_colors.hp_low_b =
                        col_hp_low[0], col_hp_low[1], col_hp_low[2]
                    inicfg.save(ini, "DamageInformer.ini")
                end

                if imgui.ColorEdit3(u8("Armour bar##car"), col_armour) then
                    ini.nametag_colors.armour_r, ini.nametag_colors.armour_g, ini.nametag_colors.armour_b =
                        col_armour[0], col_armour[1], col_armour[2]
                    inicfg.save(ini, "DamageInformer.ini")
                end

                if imgui.ColorEdit3(u8("Health background##chbg"), col_hp_bg) then
                    ini.nametag_colors.hp_bg_r, ini.nametag_colors.hp_bg_g, ini.nametag_colors.hp_bg_b =
                        col_hp_bg[0], col_hp_bg[1], col_hp_bg[2]
                    inicfg.save(ini, "DamageInformer.ini")
                end

                if imgui.ColorEdit3(u8("Armour background##cabg"), col_armour_bg) then
                    ini.nametag_colors.armour_bg_r, ini.nametag_colors.armour_bg_g, ini.nametag_colors.armour_bg_b =
                        col_armour_bg[0], col_armour_bg[1], col_armour_bg[2]
                    inicfg.save(ini, "DamageInformer.ini")
                end

                imgui.PopItemWidth()
                imgui.Spacing()
                imgui.EndTabItem()
            end

            if imgui.BeginTabItem(u8("Skeleton")) then
                current_tab[0] = 4

                imgui.Text(u8("Skeleton"))

                if imgui.Checkbox(u8("Show skeleton"), cb_skeleton) then
                    s_enabled = cb_skeleton[0]
                    ini.main.show_skeleton = s_enabled
                    inicfg.save(ini, "DamageInformer.ini")
                end

                if imgui.Checkbox(u8("Use nametag colors"), cb_skeleton_nametag) then
                    ini.main.skeleton_use_nametag_colors = cb_skeleton_nametag[0]
                    inicfg.save(ini, "DamageInformer.ini")
                end

                imgui.Separator()
                imgui.TextDisabled(u8("Skeleton color"))
                imgui.PushItemWidth(180)

                if not cb_skeleton_nametag[0] then
                    if imgui.ColorEdit3(u8("Custom skeleton##csk"), col_skeleton) then
                        ini.skeleton_colors.skeleton_r, ini.skeleton_colors.skeleton_g, ini.skeleton_colors.skeleton_b =
                            col_skeleton[0], col_skeleton[1], col_skeleton[2]
                        inicfg.save(ini, "DamageInformer.ini")
                    end
                end

                imgui.PopItemWidth()
                imgui.Spacing()
                imgui.EndTabItem()
            end

            if imgui.BeginTabItem(u8("Credits")) then
                current_tab[0] = 1

                imgui.Text(u8("Damage Informer"))
                imgui.Separator()
                imgui.TextWrapped(u8("Special thanks to everyone who helped build, test, and improve this script."))

                imgui.Spacing()
                imgui.BulletText(u8("Owner / concept: Apex"))
                imgui.BulletText(u8("Lua logic / integration: Apex"))
                imgui.BulletText(u8("ASI renderer / C++ bridge: Apex"))
                imgui.BulletText(u8("Beta Tester: BONi, lik3me"))
                imgui.BulletText(u8("Dinamovist Muist: nonamexdd"))

                imgui.Spacing()
                imgui.EndTabItem()
            end

            imgui.EndTabBar()
        end

        imgui.End()
    end
)

------------------------------------------------------------
-- MAIN UPDATE
------------------------------------------------------------
function onD3DPresent()
    if not isSampAvailable() then return end
    if not isPlayerPlaying(PLAYER_HANDLE) then return end
    if isPauseMenuActive() then return end
    if sampIsScoreboardOpen() then return end

    cleanupVehicleShooters()

    if isCharInAnyCar(PLAYER_PED) then
        local veh = storeCarCharIsInNoSave(PLAYER_PED)
        if veh ~= 0 then
            local hp = getCarHealth(veh)

            if lastVehicleHealth ~= nil and hp < lastVehicleHealth then
                local myX, myY, myZ = getCharCoordinates(PLAYER_PED)
                local nowMs = msNow()
                if nowMs - lastDlOnVehicleHit >= VEH_DL_COOLDOWN_MS then
                    local cmd = "/dl"
                    sampSendChat(cmd)
                    lastDlOnVehicleHit = nowMs
                end

                for i = 0, sampGetMaxPlayerId() do
                    local myOk, myPid = sampGetPlayerIdByCharHandle(PLAYER_PED)

                    if sampIsPlayerConnected(i) and (not myOk or i ~= myPid) then
                        local ok, ped = sampGetCharHandleBySampPlayerId(i)
                        if ok then
                            local px, py, pz = getCharCoordinates(ped)
                            local dist = getDistanceBetweenCoords3d(px, py, pz, myX, myY, myZ)

                            if dist < 100.0 then
                                local wpn = getCurrentCharWeapon(ped)
                                if wpn > 0 then
                                    attackers[i] = {
                                        pid = i,
                                        name = sampGetPlayerNickname(i) or "?",
                                        wx = px,
                                        wy = py,
                                        wz = pz,
                                        spawnMs = msNow()
                                    }
                                end
                            end
                        end
                    end
                end
            end

            lastVehicleHealth = hp
        else
            lastVehicleHealth = nil
        end
    else
        lastVehicleHealth = nil
    end

    local now = msNow()
    for i = #entries, 1, -1 do
        if (now - entries[i].spawnMs) >= ini.main.life_ms then
            table.remove(entries, i)
        end
    end

    local sw, sh = getScreenResolution()
    local ancX = ini.main.anchor_x > 0 and ini.main.anchor_x or (sw * 0.5)
    local ancY = ini.main.anchor_y > 0 and ini.main.anchor_y or (sh * 0.25)

    writeSharedDamage(ancX, ancY)
    writeSharedNameTags()
    writeSharedSkeleton()
end


------------------------------------------------------------
-- MAIN
------------------------------------------------------------
function main()
    while not isSampAvailable() do
        wait(100)
    end

    initSharedDamage()

    sampRegisterChatCommand("di", function()
        wnd_open[0] = not wnd_open[0]
    end)

    sampRegisterChatCommand("dmgreload", function()
        shutdownSharedDamage()
        thisScript():reload()
    end)

    sampAddChatMessage(
        "{FF6B6B}[DamageInformer]{FFFFFF} v6.0 loaded! /di = settings",
        0xFFFFFF
    )

    while true do
        wait(0)
    end
end