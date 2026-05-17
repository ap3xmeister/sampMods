script_name("GiftBox Locations")
script_author("Apex")
script_version("0.1")

require "lib.moonloader"
require "lib.sampfuncs"

local sampev = require "lib.samp.events"
local imgui = require "mimgui"
local inicfg = require "inicfg"
local ec = require "encoding"
ec.default = "CP1251"
u8 = ec.UTF8

local ini = inicfg.load({
    main = {
        enabled     = true,
        anchor_x    = -1,
        anchor_y    = -1,
        hours       = 0,   
    },
}, "GiftboxLocations.ini")


local g_enabled = ini.main.enabled;
local font_flag = require("moonloader").font_flag
local hudFont = nil
local header = ""
local heade2 = ""
local payday = false
local outlineColor = 0xFF000000
local location = ""

local main_window = imgui.new.bool()

local cb_enabled  = imgui.new.bool(ini.main.enabled)

local sl_ancX     = imgui.new.int(ini.main.anchor_x > 0 and ini.main.anchor_x or 0)
local sl_ancY     = imgui.new.int(ini.main.anchor_y > 0 and ini.main.anchor_y or 0)

local function getTextSize(font, text)
    if not font or not text then return 0, 14 end

    if renderGetFontDrawTextLength and type(renderGetFontDrawTextLength) == 'function' then
        local w, h = renderGetFontDrawTextLength(font, text)
        if type(w) == 'number' and type(h) == 'number' then
            return w, h
        end
    end

    local approxW = string.len(tostring(text)) * 7
    return approxW, 14
end

local function drawShadowed(font, text, x, y, color)
    if not font or not text then return end
    if renderFontDrawText then
        renderFontDrawText(font, text, x+1, y+1, outlineColor)
        renderFontDrawText(font, text, x, y, color)
    end
end

function sampev.onServerMessage(color, text)
    text = text or ""

    local hours = text:match("^Vei putea folosi /getgift din nou peste (%d+) ore%.")
    if hours then
        hours = tonumber(hours)
        sampAddChatMessage("MATCHED GIFT MESSAGE: " .. text, 0x00FF00)
        ini.main.hours = hours;
        inicfg.save(ini, "GiftboxLocations.ini")
    end

    if text:find("Your paycheck has arrived; please visit the bank to withdraw your money.") then
        payday = true
    end
    if text:find("^Ai castigat") then
        if text:find("%$") then
            ini.main.hours = 2
            inicfg.save(ini, "GiftboxLocations.ini")
        else
            ini.main.hours = 4
            inicfg.save(ini, "GiftboxLocations.ini")
        end
    end
end

function calculateGetgiftHours() 
    if(ini.main.hours > 0) then
        if(payday) then
            ini.main.hours = ini.main.hours - 1
            payday = false
            inicfg.save(ini, "GiftboxLocations.ini")
        end
    end
end

function getGiftLocationByNumber(numar)
    local index = math.floor(numar / 100) + 1

    local giftLocations = {
        "Parcare LV",      -- 1-99
        "East Beach",      -- 100-199
        "Fort Carson",     -- 200-299
        "Docks",           -- 300-399
        "Bayside",         -- 400-499
        "Corturi LV",      -- 500-599
        "Beach SF",        -- 600-699
        "Race arena LV",   -- 700-799
        "Montgomery",      -- 800-899
        "Aero. Parasit"    -- 900-999
    }

    return giftLocations[index] or "Unknown"
end

function main()
    repeat wait(0) until isSampAvailable()

    hudFont = renderCreateFont("Segoe UI", 18, font_flag.BOLD + font_flag.SHADOW)

    sampRegisterChatCommand("giftbox", function()
        main_window[0] = not main_window[0]
    end)
    sampAddChatMessage("{00FF00}[GIFTBOX LOCATIONS] Running.", -1)

    while not isSampAvailable() or not sampIsLocalPlayerSpawned() do
        wait(100)
    end

    local result, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if result then
        location = getGiftLocationByNumber(myId)
    end

    local sw, sh = getScreenResolution()
    while true do
        wait(0)
        calculateGetgiftHours()
        if g_enabled and hudFont then
            local x = math.max(10, math.min(sl_ancX[0], sw - 250))
            local y = math.max(10, math.min(sl_ancY[0], sh - 50))
            if(ini.main.hours > 1 or ini.main.hours == 0) then
                header = string.format("Next /getgift: %d hours", ini.main.hours)
            elseif(ini.main.hours <= 1) then
                header = string.format("Next /getgift: %d hour", ini.main.hours)
            end
            drawShadowed(hudFont, header, x, y, 0xFFFFFFFF)
            header2 = string.format("GiftBox location: %s", location)
            drawShadowed(hudFont, header2, x, y + 30, 0xFFFFFFFF)
        end
    end
end

local settings = imgui.OnFrame(
    function()
        return main_window[0] end,
    function(self)
        local sw, sh = getScreenResolution()

        if main_window[0] then
            imgui.SetNextWindowSize(imgui.ImVec2(260, 110), imgui.Cond.FirstUseEver)
            imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))

            imgui.Begin(u8("Giftbox locations v1.0"), main_window)

            if imgui.Checkbox(u8("Enabled"), cb_enabled) then
                g_enabled = cb_enabled[0]
                ini.main.enabled = cb_enabled[0]
                inicfg.save(ini, "GiftboxLocations.ini")
            end

            imgui.PushItemWidth(180)

            local sw2, sh2 = getScreenResolution()

            if imgui.SliderInt(u8("Anchor X##ax"), sl_ancX, 0, sw2, "%d") then
                ini.main.anchor_x = sl_ancX[0]
                inicfg.save(ini, "GiftboxLocations.ini")
            end

            if imgui.SliderInt(u8("Anchor Y##ay"), sl_ancY, 0, sh2, "%d") then
                ini.main.anchor_y = sl_ancY[0]
                inicfg.save(ini, "GiftboxLocations.ini")
            end

            imgui.PopItemWidth()
            imgui.End()
        end
    end
)