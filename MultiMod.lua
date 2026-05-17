script_name    = "MultiMod"
script_author  = "pla"
script_version = "0.1.2"

require "lib.moonloader"
local sampev   = require "lib.samp.events"
local imgui    = require "imgui"
local encoding = require "encoding"
encoding.default = "CP1251"
local u8 = encoding.UTF8

require 'sflua.gangzone'
local ffi = require 'ffi'

local VK_F6 = 0x75

-- ============================================================
-- DEBUG
-- ============================================================
local DEBUG = true
local function dbg(msg)
    if DEBUG then
        sampAddChatMessage("{FFAA00}[FishJob DBG] {FFFFFF}" .. tostring(msg), -1)
    end
end

-- ============================================================
-- ZONE DE PESCUIT
-- ============================================================
local ZONES = {
    { name = "Fish San Fierro",   minx = -1277.75390625,    miny =  427.5234375,        maxx = -1214.75390625,    maxy =  487.5234375,        city = "SF" },
    { name = "Fish Los Santos",   minx =  345.227294921875, miny = -2092.479675292969,  maxx =  416.227294921875, maxy = -2071.479675292969,  city = "LS" },
    { name = "Fish Las Venturas", minx = 1989.333496093750, miny = 1553.333312988281,   maxx = 2011.333496093750, maxy = 1573.333312988281,   city = "LV" },
}

-- ============================================================
-- CONFIG
-- ============================================================
local config_dir  = getWorkingDirectory() .. "/config"
local config_path = config_dir .. "/MultiMod.dat"

local cfg = {
    enabled     = false,
    cities      = { LS = true, LV = false, SF = false },
    auto_helmet = true,
    dl_enabled  = false,
    dl_vehicle  = 0,
    dl_role     = 0,
    counter_x   = -1,
    counter_y   = -1,
    raport_x    = -1,
    raport_y    = -1,
    -- tema
    theme_r     = 0.48,
    theme_g     = 0.06,
    theme_b     = 0.06,
    check_r     = 0.77,
    check_g     = 0.07,
    check_b     = 0.19,
    -- salut auto
    greet_enabled = false,
    greet_msg     = "Salut!",
    greet_y       = true,
    greet_c       = false,
    greet_r       = false,
    greet_delay   = 5,
    greet_trigger = "you are a legend",  -- mesaj custom de trigger
    nitro_enabled = false,
}

local function saveCfg()
    if not doesDirectoryExist(config_dir) then createDirectory(config_dir) end
    local f = io.open(config_path, "w")
    if not f then return end
    f:write("enabled="     .. (cfg.enabled     and "1" or "0") .. "\n")
    f:write("city_LS="     .. (cfg.cities.LS   and "1" or "0") .. "\n")
    f:write("city_LV="     .. (cfg.cities.LV   and "1" or "0") .. "\n")
    f:write("city_SF="     .. (cfg.cities.SF   and "1" or "0") .. "\n")
    f:write("auto_helmet=" .. (cfg.auto_helmet  and "1" or "0") .. "\n")
    f:write("dl_enabled="  .. (cfg.dl_enabled   and "1" or "0") .. "\n")
    f:write("dl_vehicle="  .. tostring(cfg.dl_vehicle)           .. "\n")
    f:write("dl_role="     .. tostring(cfg.dl_role)              .. "\n")
    f:write("counter_x="   .. tostring(cfg.counter_x)            .. "\n")
    f:write("counter_y="   .. tostring(cfg.counter_y)            .. "\n")
    f:write("raport_x="    .. tostring(cfg.raport_x)             .. "\n")
    f:write("raport_y="    .. tostring(cfg.raport_y)             .. "\n")
    f:write("theme_r="     .. tostring(cfg.theme_r)              .. "\n")
    f:write("theme_g="     .. tostring(cfg.theme_g)              .. "\n")
    f:write("theme_b="     .. tostring(cfg.theme_b)              .. "\n")
    f:write("check_r="     .. tostring(cfg.check_r)              .. "\n")
    f:write("check_g="     .. tostring(cfg.check_g)              .. "\n")
    f:write("check_b="     .. tostring(cfg.check_b)              .. "\n")
    f:write("greet_enabled=" .. (cfg.greet_enabled and "1" or "0") .. "\n")
    f:write("greet_msg="   .. cfg.greet_msg                      .. "\n")
    f:write("greet_y="     .. (cfg.greet_y  and "1" or "0")      .. "\n")
    f:write("greet_c="     .. (cfg.greet_c  and "1" or "0")      .. "\n")
    f:write("greet_r="     .. (cfg.greet_r  and "1" or "0")      .. "\n")
    f:write("greet_delay=" .. tostring(cfg.greet_delay)          .. "\n")
    f:write("greet_trigger=" .. cfg.greet_trigger                .. "\n")
    f:write("nitro_enabled=" .. (cfg.nitro_enabled and "1" or "0") .. "\n")
    f:close()
end

local function loadCfg()
    local f = io.open(config_path, "r")
    if not f then return end
    for line in f:lines() do
        local k, v = line:match("^([^=]+)=(.-)%s*$")
        if k and v then
            if     k == "enabled"     then cfg.enabled     = v == "1"
            elseif k == "city_LS"     then cfg.cities.LS   = v == "1"
            elseif k == "city_LV"     then cfg.cities.LV   = v == "1"
            elseif k == "city_SF"     then cfg.cities.SF   = v == "1"
            elseif k == "auto_helmet" then cfg.auto_helmet = v == "1"
            elseif k == "dl_enabled"  then cfg.dl_enabled  = v == "1"
            elseif k == "dl_vehicle"  then cfg.dl_vehicle  = tonumber(v) or 0
            elseif k == "dl_role"     then cfg.dl_role     = tonumber(v) or 0
            elseif k == "counter_x"   then cfg.counter_x   = tonumber(v) or -1
            elseif k == "counter_y"   then cfg.counter_y   = tonumber(v) or -1
            elseif k == "raport_x"    then cfg.raport_x    = tonumber(v) or -1
            elseif k == "raport_y"    then cfg.raport_y    = tonumber(v) or -1
            elseif k == "theme_r"     then cfg.theme_r     = tonumber(v) or 0.48
            elseif k == "theme_g"     then cfg.theme_g     = tonumber(v) or 0.06
            elseif k == "theme_b"     then cfg.theme_b     = tonumber(v) or 0.06
            elseif k == "check_r"     then cfg.check_r     = tonumber(v) or 0.77
            elseif k == "check_g"     then cfg.check_g     = tonumber(v) or 0.07
            elseif k == "check_b"     then cfg.check_b     = tonumber(v) or 0.19
            elseif k == "greet_enabled" then cfg.greet_enabled = v == "1"
            elseif k == "greet_msg"   then cfg.greet_msg   = v
            elseif k == "greet_y"     then cfg.greet_y     = v == "1"
            elseif k == "greet_c"     then cfg.greet_c     = v == "1"
            elseif k == "greet_r"     then cfg.greet_r     = v == "1"
            elseif k == "greet_delay" then cfg.greet_delay = tonumber(v) or 5
            elseif k == "greet_trigger" then cfg.greet_trigger = v
            elseif k == "nitro_enabled" then cfg.nitro_enabled = v == "1"
            end
        end
    end
    f:close()
end

-- ============================================================
-- SERVER COOLDOWN
-- ============================================================
local SERVER_COOLDOWN = 87

-- ============================================================
-- STATE
-- ============================================================
local ST = { IDLE = 0, FISHING = 1, CONFIRMED = 2, WAITING = 3, SPAMMING = 4 }
local state          = ST.IDLE
local fishTimeout    = 0
local waitTimeout    = 0
local catchTime      = 0
local cooldownEndsAt = 0
local lastSpamAt     = 0
local wasOnBike      = false
local showMenu       = false
local showRaport     = true

-- throttle pentru counters: redesenate maxim de 10x/secunda
local lastCounterDraw = 0
local lastRaportDraw  = 0
local COUNTER_FPS     = 0.1   -- 100ms = 10fps

local VK_F = 0x46
local VK_G = 0x47

local dlVehicleInputBuf = imgui.ImBuffer("", 16)
local greetMsgBuf       = imgui.ImBuffer("", 128)
local greetTriggerBuf   = imgui.ImBuffer("", 128)
local greetPending      = false
local greetSentThisSession = false  -- reset doar la restart proces, nu la reconnect

local session = {
    active      = false,
    caught      = 0,
    bonus       = 0,
    sold        = false,
    startTime   = 0,
    money       = 0,
    -- tracking ciclu de pescuit pentru rata corecta
    firstCatch  = 0,   -- os.time() la primul peste prins
    lastCatch   = 0,   -- os.time() la ultimul peste prins
}

-- ============================================================
-- RAPORT FACTIUNE
-- ============================================================
local raport = {
    arrested        = 0,
    killed          = 0,
    tickets         = 0,
    ticketsMax      = 0,
    licConfiscated  = 0,
    licConfiscatedMax = 0,
    hoursH          = 0,
    hoursM          = 0,
    hoursReqH       = 0,
    hoursReqM       = 0,
    hasData         = false,
}

-- ============================================================
-- [DL AUTO] APASARE TASTA F / G DUPA CATCH
-- Foloseste PostMessage Win32 ca sa functioneze si in alt-tab
-- ============================================================
local ffi_win = ffi
ffi_win.cdef[[
    void* __stdcall FindWindowA(const char* lpClassName, const char* lpWindowName);
    int   __stdcall PostMessageA(void* hWnd, unsigned int Msg, unsigned int wParam, long lParam);
    void* __stdcall GetCurrentProcess();
    unsigned long __stdcall GetProcessId(void* hProcess);
    void* __stdcall GetTopWindow(void* hWnd);
    void* __stdcall GetWindow(void* hWnd, unsigned int uCmd);
    unsigned long __stdcall GetWindowThreadProcessId(void* hWnd, unsigned long* lpdwProcessId);
]]
local WM_KEYDOWN  = 0x0100
local WM_KEYUP    = 0x0101
local GW_HWNDNEXT = 2
local NULL        = ffi_win.cast("void*", 0)

local cachedHwnd  = nil

local function getGTAWindow()
    if cachedHwnd ~= nil then return cachedHwnd end
    local classes = { "GTASA", "GTA:SA", "GTASAEXE", "Grand Theft Auto San Andreas" }
    for _, cls in ipairs(classes) do
        local ok, hwnd = pcall(ffi_win.C.FindWindowA, cls, nil)
        if ok and hwnd ~= nil and hwnd ~= NULL then
            dbg("DL: hwnd gasit cls='" .. cls .. "'")
            cachedHwnd = hwnd
            return hwnd
        end
    end
    local titles = { "GTA: San Andreas", "Grand Theft Auto: San Andreas" }
    for _, title in ipairs(titles) do
        local ok, hwnd = pcall(ffi_win.C.FindWindowA, nil, title)
        if ok and hwnd ~= nil and hwnd ~= NULL then
            dbg("DL: hwnd gasit titlu='" .. title .. "'")
            cachedHwnd = hwnd
            return hwnd
        end
    end
    local myPid = ffi_win.C.GetProcessId(ffi_win.C.GetCurrentProcess())
    local hwnd  = ffi_win.C.GetTopWindow(NULL)
    local pid   = ffi_win.new("unsigned long[1]")
    while hwnd ~= nil and hwnd ~= NULL do
        ffi_win.C.GetWindowThreadProcessId(hwnd, pid)
        if pid[0] == myPid then
            dbg("DL: hwnd gasit prin PID=" .. tostring(myPid))
            cachedHwnd = hwnd
            return hwnd
        end
        hwnd = ffi_win.C.GetWindow(hwnd, GW_HWNDNEXT)
    end
    dbg("DL: hwnd GTA negasit!")
    return nil
end

local dlPendingAt = 0

local function scheduleDL()
    if not cfg.dl_enabled then return end
    dlPendingAt = os.clock() + 0.8
end

local function processDLPress()
    if dlPendingAt == 0 then return end
    if os.clock() < dlPendingAt then return end
    dlPendingAt = 0
    if not cfg.dl_enabled then return end
    local vk  = (cfg.dl_role == 0) and VK_F or VK_G
    local key = (cfg.dl_role == 0) and "F"   or "G"
    lua_thread.create(function()
        local hwnd = getGTAWindow()
        if hwnd then
            ffi_win.C.PostMessageA(hwnd, WM_KEYDOWN, vk, 0)
            wait(80)
            ffi_win.C.PostMessageA(hwnd, WM_KEYUP,   vk, 0)
            dbg("DL: PostMessage tasta " .. key .. " (alt-tab safe)")
        else
            setVirtualKeyDown(vk, true)
            wait(80)
            setVirtualKeyDown(vk, false)
            dbg("DL: fallback setVirtualKeyDown tasta " .. key)
        end
    end)
end

-- ============================================================
-- HELPERS
-- ============================================================
local BICYCLE_MODELS = { [481] = true, [509] = true, [510] = true }
local MOTO_MODELS    = { [448]=true,[461]=true,[462]=true,[463]=true,[468]=true,
                         [471]=true,[521]=true,[522]=true,[523]=true,[581]=true,[586]=true }

local function onMotorcycle()
    if not isCharInAnyCar(PLAYER_PED) then return false end
    if not isCharOnAnyBike(PLAYER_PED) then return false end
    return not BICYCLE_MODELS[getCarModel(storeCarCharIsInNoSave(PLAYER_PED))]
end

local function safeGetPos()
    local ok, x, y, z = pcall(getCharCoordinates, PLAYER_PED)
    if ok then return x, y end
    return nil, nil
end

local function inZone(z)
    if not cfg.cities[z.city] then return false end
    local px, py = safeGetPos()
    if not px then return false end
    return px >= z.minx and px <= z.maxx and py >= z.miny and py <= z.maxy
end

local function inAnyZone()
    for _, z in ipairs(ZONES) do
        if inZone(z) then return true end
    end
    return false
end

local function fmtTime(s)
    local h  = math.floor(s / 3600)
    local m  = math.floor((s % 3600) / 60)
    local ss = s % 60
    if h > 0 then return string.format("%02d:%02d:%02d", h, m, ss) end
    return string.format("%02d:%02d", m, ss)
end

local function fmtMoney(n)
    -- formateaza cu virgule: 1234567 -> $1,234,567
    local s = tostring(math.floor(n))
    local result = ""
    local len = #s
    for i = 1, len do
        if i > 1 and (len - i + 1) % 3 == 0 then
            result = result .. ","
        end
        result = result .. s:sub(i, i)
    end
    return "$" .. result
end

local function startSession()
    session.active     = true
    session.caught     = 0
    session.bonus      = 0
    session.sold       = false
    session.startTime  = os.time()
    session.money      = 0
    session.firstCatch = 0
    session.lastCatch  = 0
end

-- ============================================================
-- GANGZONE
-- ============================================================
local FISHZONE_IDS   = {1000, 1001, 1002}
local FISHZONE_COLOR = 0xCC0099FF

local function getZonePool()
    local ok, ptr = pcall(sampGetGangzonePoolPtr)
    if not ok or not ptr then return nil end
    local ok2, pool = pcall(ffi.cast, 'SCGangZonePool*', ptr)
    if not ok2 or not pool then return nil end
    return pool
end

local function createFishZones()
    local pool = getZonePool()
    if not pool then dbg("Pool gangzone indisponibil"); return end
    for i, z in ipairs(ZONES) do
        local id = FISHZONE_IDS[i]
        pcall(function()
            if pool.m_bNotEmpty[id] ~= 0 then pool:Delete(id) end
            if cfg.cities[z.city] then
                pool:Create(id, z.minx, z.miny, z.maxx, z.maxy, FISHZONE_COLOR)
            end
        end)
    end
end

-- ============================================================
-- CULORI & STILURI — identic cristi95
-- ============================================================
local C_GREEN  = imgui.ImVec4(0.13, 0.77, 0.37, 1.0)
local C_YELLOW = imgui.ImVec4(1.00, 0.82, 0.10, 1.0)
local C_ORANGE = imgui.ImVec4(0.95, 0.45, 0.10, 1.0)
local C_BLUE   = imgui.ImVec4(0.25, 0.78, 1.00, 1.0)
local C_GRAY   = imgui.ImVec4(0.60, 0.60, 0.60, 1.0)
local C_WHITE  = imgui.ImVec4(1.00, 1.00, 1.00, 1.0)
local C_RED    = imgui.ImVec4(0.48, 0.06, 0.06, 1.0)
local C_REDHOV = imgui.ImVec4(0.60, 0.08, 0.08, 1.0)
local C_REDACT = imgui.ImVec4(0.35, 0.04, 0.04, 1.0)

local BG      = imgui.ImVec4(0.10, 0.10, 0.10, 1.0)
local CAT_BG  = imgui.ImVec4(0.48, 0.06, 0.06, 1.0)
local CAT_HOV = imgui.ImVec4(0.56, 0.07, 0.07, 1.0)
local CAT_ACT = imgui.ImVec4(0.35, 0.04, 0.04, 1.0)
local ROW_BG  = imgui.ImVec4(0.10, 0.10, 0.10, 1.0)
local ROW_ALT = imgui.ImVec4(0.13, 0.13, 0.13, 1.0)

-- tab activ in menu bar: "main", "settings", "info"
local activeTab = "main"

-- imgui buffer pentru color picker
local themeColorBuf = imgui.ImVec4(0.48, 0.06, 0.06, 1.0)

-- recalculeaza culorile derivate din tema
local function applyTheme()
    local r, g, b = cfg.theme_r, cfg.theme_g, cfg.theme_b
    CAT_BG   = imgui.ImVec4(r,        g,        b,        1.0)
    CAT_HOV  = imgui.ImVec4(math.min(r + 0.08, 1), math.min(g + 0.01, 1), math.min(b + 0.01, 1), 1.0)
    CAT_ACT  = imgui.ImVec4(math.max(r - 0.13, 0), math.max(g - 0.02, 0), math.max(b - 0.02, 0), 1.0)
    C_RED    = imgui.ImVec4(r,        g,        b,        1.0)
    C_REDHOV = imgui.ImVec4(math.min(r + 0.12, 1), math.min(g + 0.02, 1), math.min(b + 0.02, 1), 1.0)
    C_REDACT = imgui.ImVec4(math.max(r - 0.13, 0), math.max(g - 0.02, 0), math.max(b - 0.02, 0), 1.0)
    themeColorBuf = imgui.ImVec4(r, g, b, 1.0)
end

local catOpen = {
    general = true,
    fish    = true,
    autoveh = true,
    zone    = false,
    counter = true,
    misc    = true,
    raport  = true,
}

local MENU_W = 360

local function redBtn(label, w, h)
    imgui.PushStyleColor(imgui.Col.Button,        C_RED)
    imgui.PushStyleColor(imgui.Col.ButtonHovered, C_REDHOV)
    imgui.PushStyleColor(imgui.Col.ButtonActive,  C_REDACT)
    local clicked = imgui.Button(label, imgui.ImVec2(w or 70, h or 18))
    imgui.PopStyleColor(3)
    return clicked
end

local function catHeader(id, label)
    imgui.PushStyleColor(imgui.Col.Button,        CAT_BG)
    imgui.PushStyleColor(imgui.Col.ButtonHovered, CAT_HOV)
    imgui.PushStyleColor(imgui.Col.ButtonActive,  CAT_ACT)
    imgui.PushID(id)
    local arrow = catOpen[id] and "v  " or ">  "
    local clicked = imgui.Button(arrow .. u8(label), imgui.ImVec2(MENU_W - 16, 22))
    imgui.PopID()
    imgui.PopStyleColor(3)
    if clicked then catOpen[id] = not catOpen[id] end
    return catOpen[id]
end

-- ============================================================
-- COUNTER — acelasi stil ca meniul principal
-- ============================================================
local CW = 220

local function drawCounter()
    if not session.active then return end

    local sw, sh    = getScreenResolution()
    local elapsed   = os.time() - session.startTime
    local total     = session.caught + session.bonus

    -- rata pesti: doar pesti reali (caught), nu bonus skill points
    -- bazata pe timpul dintre primul si ultimul catch (ciclu real)
    local fishRate  = 0
    local moneyRate = 0
    if session.caught >= 2 and session.lastCatch > session.firstCatch then
        -- timp mediu per peste = (lastCatch - firstCatch) / (caught - 1)
        local cycleTime = session.lastCatch - session.firstCatch
        local avgPerFish = cycleTime / (session.caught - 1)
        fishRate  = avgPerFish > 0 and math.floor(3600 / avgPerFish) or 0
        moneyRate = avgPerFish > 0 and math.floor((session.money / session.caught) * (3600 / avgPerFish)) or 0
    elseif session.caught == 1 and elapsed > 30 then
        -- un singur peste: estimeaza din timpul scurs
        fishRate  = math.floor(3600 / elapsed)
        moneyRate = math.floor(session.money * 3600 / elapsed)
    end

    local showExtra = (state == ST.WAITING or state == ST.SPAMMING) and cooldownEndsAt > 0

    -- inaltime dinamica: linii fixe + linie extra daca e cooldown
    local H = 245 + (showExtra and 20 or 0)

    local defX = sw - CW - 10
    local defY = 10
    local posX = cfg.counter_x >= 0 and cfg.counter_x or defX
    local posY = cfg.counter_y >= 0 and cfg.counter_y or defY

    -- FirstUseEver = seteaza pozitia doar prima data, drag liber dupa
    imgui.SetNextWindowPos(imgui.ImVec2(posX, posY), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowSize(imgui.ImVec2(CW, H), imgui.Cond.Always)

    imgui.PushStyleColor(imgui.Col.WindowBg,      imgui.ImVec4(0.10, 0.10, 0.10, 1.00))
    imgui.PushStyleColor(imgui.Col.TitleBg,       CAT_BG)
    imgui.PushStyleColor(imgui.Col.TitleBgActive, CAT_HOV)
    imgui.PushStyleColor(imgui.Col.Separator,     imgui.ImVec4(cfg.theme_r * 0.5, cfg.theme_g * 0.5, cfg.theme_b * 0.5, 1.00))
    imgui.PushStyleVar(imgui.StyleVar.WindowRounding, 0)
    imgui.PushStyleVar(imgui.StyleVar.FrameRounding,  0)

    imgui.Begin("FISH JOB##cnt", nil, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse)

    -- salveaza pozitia dupa fiecare drag
    local wpos = imgui.GetWindowPos()
    local fx, fy = math.floor(wpos.x), math.floor(wpos.y)
    if fx ~= cfg.counter_x or fy ~= cfg.counter_y then
        cfg.counter_x = fx
        cfg.counter_y = fy
        saveCfg()
    end

    -- status bar
    local stTxt, stClr
    if not cfg.enabled then
        stTxt, stClr = "OPRIT", C_GRAY
    elseif state == ST.FISHING or state == ST.CONFIRMED then
        stTxt, stClr = "PESCUIESTE", C_GREEN
    elseif state == ST.WAITING then
        stTxt, stClr = "ASTEAPTA", C_ORANGE
    elseif state == ST.SPAMMING then
        stTxt, stClr = "SPAM /fish", C_ORANGE
    elseif inAnyZone() then
        stTxt, stClr = "IN ZONA", C_BLUE
    else
        stTxt, stClr = "IN AFARA ZONEI", C_GRAY
    end

    imgui.PushStyleColor(imgui.Col.Button,        CAT_BG)
    imgui.PushStyleColor(imgui.Col.ButtonHovered, CAT_BG)
    imgui.PushStyleColor(imgui.Col.ButtonActive,  CAT_BG)
    imgui.Button("STATUS", imgui.ImVec2(CW - 16, 20))
    imgui.PopStyleColor(3)
    imgui.TextColored(stClr, u8(stTxt))

    -- ── PESCUIT ──
    imgui.Separator()
    imgui.PushStyleColor(imgui.Col.Button,        CAT_BG)
    imgui.PushStyleColor(imgui.Col.ButtonHovered, CAT_BG)
    imgui.PushStyleColor(imgui.Col.ButtonActive,  CAT_BG)
    imgui.Button("PESCUIT", imgui.ImVec2(CW - 16, 18))
    imgui.PopStyleColor(3)

    imgui.TextColored(C_GRAY,  "Pesti")
    imgui.SameLine(100) imgui.TextColored(C_GREEN,  tostring(session.caught))

    imgui.TextColored(C_GRAY,  "Bonus")
    imgui.SameLine(100) imgui.TextColored(C_YELLOW, tostring(session.bonus))

    imgui.TextColored(C_GRAY,  "Total")
    imgui.SameLine(100) imgui.Text(tostring(total))

    imgui.TextColored(C_GRAY,  "Timp")
    imgui.SameLine(100) imgui.Text(fmtTime(elapsed))

    imgui.TextColored(C_GRAY,  "Rata")
    imgui.SameLine(100) imgui.Text("~" .. fishRate .. "/h")

    if showExtra then
        if state == ST.SPAMMING then
            imgui.TextColored(C_ORANGE, u8("spam /fish..."))
        else
            local rem = math.max(0, math.ceil(cooldownEndsAt - os.clock()))
            imgui.TextColored(C_GRAY, "Cooldown")
            imgui.SameLine(100) imgui.TextColored(C_ORANGE, rem .. "s")
        end
    end

    -- ── BANI ──
    imgui.Separator()
    imgui.PushStyleColor(imgui.Col.Button,        CAT_BG)
    imgui.PushStyleColor(imgui.Col.ButtonHovered, CAT_BG)
    imgui.PushStyleColor(imgui.Col.ButtonActive,  CAT_BG)
    imgui.Button("BANI", imgui.ImVec2(CW - 16, 18))
    imgui.PopStyleColor(3)

    imgui.TextColored(C_GRAY,  "Sesiune")
    imgui.SameLine(100) imgui.TextColored(C_GREEN,  fmtMoney(session.money))

    imgui.TextColored(C_GRAY,  "Rata")
    imgui.SameLine(100) imgui.TextColored(C_YELLOW, fmtMoney(moneyRate) .. "/h")

    imgui.End()
    imgui.PopStyleVar(2)
    imgui.PopStyleColor(4)
end

-- ============================================================
-- RAPORT COUNTER — fereastra draggabila separata
-- ============================================================
local RW = 230   -- latime raport counter

local function drawRaportCounter()
    if not showRaport then return end

    local sw, sh = getScreenResolution()
    local defX   = sw - RW - 10
    local defY   = 220
    local posX   = cfg.raport_x >= 0 and cfg.raport_x or defX
    local posY   = cfg.raport_y >= 0 and cfg.raport_y or defY

    imgui.SetNextWindowPos(imgui.ImVec2(posX, posY), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowSize(imgui.ImVec2(RW, raport.hasData and 155 or 75), imgui.Cond.Always)

    imgui.PushStyleColor(imgui.Col.WindowBg,      imgui.ImVec4(0.10, 0.10, 0.10, 1.00))
    imgui.PushStyleColor(imgui.Col.TitleBg,       CAT_BG)
    imgui.PushStyleColor(imgui.Col.TitleBgActive, CAT_HOV)
    imgui.PushStyleColor(imgui.Col.Separator,     imgui.ImVec4(cfg.theme_r * 0.5, cfg.theme_g * 0.5, cfg.theme_b * 0.5, 1.00))
    imgui.PushStyleVar(imgui.StyleVar.WindowRounding, 0)
    imgui.PushStyleVar(imgui.StyleVar.FrameRounding,  0)

    imgui.Begin("RAPORT##rct", nil, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse)

    local wpos = imgui.GetWindowPos()
    local fx, fy = math.floor(wpos.x), math.floor(wpos.y)
    if fx ~= cfg.raport_x or fy ~= cfg.raport_y then
        cfg.raport_x = fx
        cfg.raport_y = fy
        saveCfg()
    end

    if not raport.hasData then
        imgui.TextColored(C_GRAY, u8("Scrie /raport pentru date"))
        imgui.Spacing()
        imgui.PushStyleColor(imgui.Col.Button,        CAT_BG)
        imgui.PushStyleColor(imgui.Col.ButtonHovered, CAT_HOV)
        imgui.PushStyleColor(imgui.Col.ButtonActive,  CAT_ACT)
        if imgui.Button(u8("/raport"), imgui.ImVec2(RW - 16, 20)) then
            sampSendChat("/raport")
        end
        imgui.PopStyleColor(3)
    else
        -- header
        imgui.PushStyleColor(imgui.Col.Button,        CAT_BG)
        imgui.PushStyleColor(imgui.Col.ButtonHovered, CAT_BG)
        imgui.PushStyleColor(imgui.Col.ButtonActive,  CAT_BG)
        imgui.Button("ACTIVITATE FACTIUNE", imgui.ImVec2(RW - 16, 20))
        imgui.PopStyleColor(3)

        -- Arestati / Ucisi
        imgui.TextColored(C_GRAY,   "Wanted")
        imgui.SameLine(140)
        imgui.TextColored(C_GREEN,  tostring(raport.arrested))
        imgui.SameLine(0, 0) imgui.TextColored(C_GRAY, " / ")
        imgui.SameLine(0, 0) imgui.TextColored(C_YELLOW, tostring(raport.killed))

        -- Bilete
        imgui.TextColored(C_GRAY,   "Amenzi")
        imgui.SameLine(140)
        local tkClr = (raport.tickets >= raport.ticketsMax and raport.ticketsMax > 0) and C_GREEN or C_ORANGE
        imgui.TextColored(tkClr, tostring(raport.tickets))
        imgui.SameLine(0, 0) imgui.TextColored(C_GRAY, " / " .. tostring(raport.ticketsMax))

        imgui.TextColored(C_GRAY,   "Permise")
        imgui.SameLine(140)
        local lcClr = (raport.licConfiscated >= raport.licConfiscatedMax and raport.licConfiscatedMax > 0) and C_GREEN or C_ORANGE
        imgui.TextColored(lcClr, tostring(raport.licConfiscated))
        imgui.SameLine(0, 0) imgui.TextColored(C_GRAY, " / " .. tostring(raport.licConfiscatedMax))

        imgui.Separator()

        -- Ore jucate
        local playedMins = raport.hoursH * 60 + raport.hoursM
        local reqMins    = raport.hoursReqH * 60 + raport.hoursReqM
        local oreClr     = (playedMins >= reqMins) and C_GREEN or C_ORANGE
        imgui.TextColored(C_GRAY, "Ore jucate")
        imgui.SameLine(140)
        imgui.TextColored(oreClr, string.format("%02d:%02d", raport.hoursH, raport.hoursM))
        imgui.SameLine(0, 0) imgui.TextColored(C_GRAY, " / ")
        imgui.SameLine(0, 0) imgui.TextColored(C_WHITE, string.format("%02d:%02d", raport.hoursReqH, raport.hoursReqM))

        -- Progres general: scor ponderat din toate categoriile
        local scoreMax = 0
        local scoreCrt = 0

        if reqMins > 0 then
            scoreMax = scoreMax + 40
            scoreCrt = scoreCrt + math.min(40, math.floor(playedMins * 40 / reqMins))
        end
        if raport.ticketsMax > 0 then
            scoreMax = scoreMax + 40
            scoreCrt = scoreCrt + math.min(40, math.floor(raport.tickets * 40 / raport.ticketsMax))
        end
        if raport.licConfiscatedMax > 0 then
            scoreMax = scoreMax + 20
            scoreCrt = scoreCrt + math.min(20, math.floor(raport.licConfiscated * 20 / raport.licConfiscatedMax))
        end

        local pct    = scoreMax > 0 and math.floor(scoreCrt * 100 / scoreMax) or 0
        local pctClr = pct >= 100 and C_GREEN or C_ORANGE
        imgui.TextColored(C_GRAY, "Progres")
        imgui.SameLine(140)
        imgui.TextColored(pctClr, scoreCrt .. "/" .. scoreMax .. "  (" .. pct .. "%)")
    end

    imgui.End()
    imgui.PopStyleVar(2)
    imgui.PopStyleColor(4)
end
local function applyMenuStyle()
    local r, g, b = cfg.theme_r, cfg.theme_g, cfg.theme_b
    imgui.PushStyleColor(imgui.Col.WindowBg,           imgui.ImVec4(0.10, 0.10, 0.10, 1.00))
    imgui.PushStyleColor(imgui.Col.TitleBg,            imgui.ImVec4(r,        g,        b,        1.00))
    imgui.PushStyleColor(imgui.Col.TitleBgActive,      imgui.ImVec4(r + 0.08, g + 0.01, b + 0.01, 1.00))
    imgui.PushStyleColor(imgui.Col.ScrollbarBg,        imgui.ImVec4(0.07, 0.07, 0.07, 1.00))
    imgui.PushStyleColor(imgui.Col.ScrollbarGrab,      imgui.ImVec4(r,        g,        b,        1.00))
    -- checkbox / radio: bifa si cercul interior
    imgui.PushStyleColor(imgui.Col.CheckMark,          imgui.ImVec4(cfg.check_r, cfg.check_g, cfg.check_b, 1.00))
    -- frame checkbox / radio (chenarul)
    imgui.PushStyleColor(imgui.Col.FrameBg,            imgui.ImVec4(0.16, 0.16, 0.16, 1.00))
    imgui.PushStyleColor(imgui.Col.FrameBgHovered,     imgui.ImVec4(r,        g,        b,        0.50))
    imgui.PushStyleColor(imgui.Col.FrameBgActive,      imgui.ImVec4(r,        g,        b,        0.80))
    imgui.PushStyleColor(imgui.Col.Separator,          imgui.ImVec4(r * 0.5,  g * 0.5,  b * 0.5,  1.00))
    imgui.PushStyleColor(imgui.Col.Header,             imgui.ImVec4(r,        g,        b,        0.60))
    imgui.PushStyleColor(imgui.Col.HeaderHovered,      imgui.ImVec4(r + 0.08, g + 0.01, b + 0.01, 0.80))
    imgui.PushStyleColor(imgui.Col.MenuBarBg,          imgui.ImVec4(0.07, 0.07, 0.07, 1.00))
    -- slider
    imgui.PushStyleColor(imgui.Col.SliderGrab,         imgui.ImVec4(r,        g,        b,        1.00))
    imgui.PushStyleColor(imgui.Col.SliderGrabActive,   imgui.ImVec4(r + 0.1,  g + 0.02, b + 0.02, 1.00))
    imgui.PushStyleVar(imgui.StyleVar.WindowRounding, 0)
    imgui.PushStyleVar(imgui.StyleVar.FrameRounding,  0)
end

local function popMenuStyle()
    imgui.PopStyleVar(2)
    imgui.PopStyleColor(15)
end

local function drawMain()
    local sw, sh = getScreenResolution()
    applyMenuStyle()

    imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(MENU_W, 560), imgui.Cond.FirstUseEver)

    imgui.Begin(u8("MultiMod v1.0.0  |  /multimod"), nil, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.MenuBar)

    -- ── MENU BAR ─────────────────────────────────────────────
    if imgui.BeginMenuBar() then
        -- stilizare butoane menu bar ca tab-uri
        local function menuTab(id, label)
            local isActive = activeTab == id
            if isActive then
                imgui.PushStyleColor(imgui.Col.Button,        CAT_BG)
                imgui.PushStyleColor(imgui.Col.ButtonHovered, CAT_HOV)
                imgui.PushStyleColor(imgui.Col.ButtonActive,  CAT_ACT)
            else
                imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.0, 0.0, 0.0, 0.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.22, 0.22, 0.22, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonActive,  CAT_ACT)
            end
            if imgui.Button(u8(label)) then activeTab = id end
            imgui.PopStyleColor(3)
            imgui.SameLine(0, 2)
        end

        menuTab("main",     "Main")
        menuTab("settings", "Settings")
        menuTab("info",     "Info")

        imgui.EndMenuBar()
    end

    -- ── TAB: MAIN ─────────────────────────────────────────────
    if activeTab == "main" then

        if catHeader("general", "GENERAL") then
            imgui.Spacing()
            local b1 = imgui.ImBool(cfg.enabled)
            if imgui.Checkbox(u8("Bot activat  [F6]##en"), b1) then
                cfg.enabled = b1.v
                if b1.v then state = ST.IDLE; if not session.active then startSession() end end
                saveCfg()
            end
            local b2 = imgui.ImBool(cfg.auto_helmet)
            if imgui.Checkbox(u8("Auto casca  (/ph)##ah"), b2) then
                cfg.auto_helmet = b2.v; saveCfg()
            end
            imgui.Spacing()
            local stTxt, stClr
            if not cfg.enabled then
                stTxt, stClr = "OPRIT", C_GRAY
            elseif state == ST.FISHING then
                stTxt, stClr = "pescuieste (astept)", C_YELLOW
            elseif state == ST.CONFIRMED then
                stTxt, stClr = "pescuieste (confirmat)", C_GREEN
            elseif state == ST.WAITING then
                local rem = math.max(0, math.ceil(cooldownEndsAt - os.clock()))
                if session.sold then stTxt, stClr = "sold | cd " .. rem .. "s", C_ORANGE
                else stTxt, stClr = "vinde pestele...", C_ORANGE end
            elseif state == ST.SPAMMING then
                stTxt, stClr = "spam /fish...", C_ORANGE
            elseif inAnyZone() then
                stTxt, stClr = "in zona", C_BLUE
            else
                stTxt, stClr = "in afara zonei", C_GRAY
            end
            imgui.TextColored(C_GRAY, u8("Status: ")) imgui.SameLine(0, 0)
            imgui.TextColored(stClr, u8(stTxt))
            if cooldownEndsAt > 0 then
                local rem = math.max(0, math.ceil(cooldownEndsAt - os.clock()))
                imgui.TextColored(C_GRAY, u8("Cooldown: ")) imgui.SameLine(0, 0)
                if rem > 0 then imgui.TextColored(C_ORANGE, rem .. "s")
                else imgui.TextColored(C_GREEN, u8("gata")) end
            end
            imgui.Spacing()
        end

        if catHeader("fish", "PESCUIT") then
            imgui.Spacing()
            imgui.TextColored(C_GRAY, u8("Orase active:"))
            imgui.Spacing()
            local bLS = imgui.ImBool(cfg.cities.LS)
            if imgui.Checkbox("Los Santos##LS", bLS)   then cfg.cities.LS = bLS.v; saveCfg(); createFishZones() end
            local bLV = imgui.ImBool(cfg.cities.LV)
            if imgui.Checkbox("Las Venturas##LV", bLV) then cfg.cities.LV = bLV.v; saveCfg(); createFishZones() end
            local bSF = imgui.ImBool(cfg.cities.SF)
            if imgui.Checkbox("San Fierro##SF", bSF)   then cfg.cities.SF = bSF.v; saveCfg(); createFishZones() end

            imgui.Spacing() imgui.Separator() imgui.Spacing()
            imgui.TextColored(C_GRAY, u8("Auto intrare masina:"))
            imgui.Spacing()
            local bDL = imgui.ImBool(cfg.dl_enabled)
            if imgui.Checkbox(u8("Activat (apasa F/G dupa catch)##dl"), bDL) then
                cfg.dl_enabled = bDL.v; saveCfg()
            end
            imgui.Spacing()
            imgui.TextColored(C_GRAY, u8("ID Vehicul:")) imgui.SameLine(0, 8)
            imgui.PushItemWidth(70)
            if imgui.InputText("##dlvid", dlVehicleInputBuf) then
                local num = tonumber(dlVehicleInputBuf.v)
                cfg.dl_vehicle = (num and num > 0) and math.floor(num) or 0
                saveCfg()
            end
            imgui.PopItemWidth()
            imgui.SameLine(0, 6)
            if cfg.dl_vehicle > 0 then imgui.TextColored(C_GREEN, "ID: " .. cfg.dl_vehicle)
            else imgui.TextColored(C_ORANGE, u8("(nesetat)")) end
            imgui.Spacing()
            imgui.TextColored(C_GRAY, u8("Rol: ")) imgui.SameLine(0, 4)
            if imgui.RadioButton(u8("Sofer [F]##r0"), cfg.dl_role == 0) then cfg.dl_role = 0; saveCfg() end
            imgui.SameLine(0, 14)
            if imgui.RadioButton(u8("Pasager [G]##r1"), cfg.dl_role == 1) then cfg.dl_role = 1; saveCfg() end
            imgui.Spacing()
            local kl = (cfg.dl_role == 0) and "F" or "G"
            if cfg.dl_enabled then imgui.TextColored(C_GREEN, u8("Apasa " .. kl .. " dupa fiecare catch"))
            else imgui.TextColored(C_GRAY, u8("Dezactivat")) end

            imgui.Spacing() imgui.Separator() imgui.Spacing()
            imgui.TextColored(C_GRAY, u8("Zone de pescuit:"))
            imgui.Spacing()
            for _, z in ipairs(ZONES) do
                local here   = inZone(z)
                local active = cfg.cities[z.city]
                local cx = (z.minx + z.maxx) / 2
                local cy = (z.miny + z.maxy) / 2
                local tag = here and " << ESTI AICI" or (not active and " (dezactivat)" or "")
                local txt = string.format("[%s] %s  %.0f,%.0f%s", z.city, u8(z.name), cx, cy, tag)
                if here then imgui.TextColored(C_GREEN, txt)
                elseif not active then imgui.TextColored(C_GRAY, txt)
                else imgui.Text(txt) end
            end

            imgui.Spacing() imgui.Separator() imgui.Spacing()
            imgui.TextColored(C_GRAY, u8("Counter sesiune:"))
            imgui.Spacing()
            if session.active then
                local elapsed   = os.time() - session.startTime
                local total     = session.caught + session.bonus
                local fishRate2  = 0
                local moneyRate2 = 0
                if session.caught >= 2 and session.lastCatch > session.firstCatch then
                    local cycleTime  = session.lastCatch - session.firstCatch
                    local avgPerFish = cycleTime / (session.caught - 1)
                    fishRate2  = avgPerFish > 0 and math.floor(3600 / avgPerFish) or 0
                    moneyRate2 = avgPerFish > 0 and math.floor((session.money / session.caught) * (3600 / avgPerFish)) or 0
                elseif session.caught == 1 and elapsed > 30 then
                    fishRate2  = math.floor(3600 / elapsed)
                    moneyRate2 = math.floor(session.money * 3600 / elapsed)
                end
                imgui.TextColored(C_GRAY, "Pesti  ")  imgui.SameLine(80) imgui.TextColored(C_GREEN,  tostring(session.caught))
                imgui.TextColored(C_GRAY, "Bonus  ")  imgui.SameLine(80) imgui.TextColored(C_YELLOW, tostring(session.bonus))
                imgui.TextColored(C_GRAY, "Total  ")  imgui.SameLine(80) imgui.Text(tostring(total))
                imgui.TextColored(C_GRAY, "Timp   ")  imgui.SameLine(80) imgui.Text(fmtTime(elapsed) .. "   ~" .. fishRate2 .. "/h")
                imgui.TextColored(C_GRAY, "Bani   ")  imgui.SameLine(80) imgui.TextColored(C_GREEN,  fmtMoney(session.money))
                imgui.TextColored(C_GRAY, "Rata $ ")  imgui.SameLine(80) imgui.TextColored(C_YELLOW, fmtMoney(moneyRate2) .. "/h")
                imgui.Spacing()
                if redBtn(u8("Reset"), 60, 20) then startSession() end
                imgui.SameLine(0, 6)
                if redBtn(u8("Stop"),  60, 20) then session.active = false end
            else
                if redBtn(u8("Start Counter"), 110, 22) then startSession() end
            end
            imgui.Spacing()
        end

        if catHeader("misc", "MISC") then
            imgui.Spacing()

            local bR = imgui.ImBool(showRaport)
            if imgui.Checkbox(u8("Afiseaza counter raport##sr"), bR) then
                showRaport = bR.v
            end
            imgui.TextColored(C_GRAY, u8("(trage cu mouse-ul sa-l muti)"))

            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            -- salut auto
            imgui.PushStyleColor(imgui.Col.Button,        CAT_BG)
            imgui.PushStyleColor(imgui.Col.ButtonHovered, CAT_BG)
            imgui.PushStyleColor(imgui.Col.ButtonActive,  CAT_BG)
            imgui.Button(u8("SALUT AUTO DUPA LOGIN"), imgui.ImVec2(MENU_W - 16, 20))
            imgui.PopStyleColor(3)

            imgui.Spacing()
            local bGr = imgui.ImBool(cfg.greet_enabled)
            if imgui.Checkbox(u8("Activat##gr"), bGr) then
                cfg.greet_enabled = bGr.v; saveCfg()
            end

            imgui.Spacing()
            imgui.TextColored(C_GRAY, u8("Mesaj salut:")) imgui.SameLine(0, 8)
            imgui.PushItemWidth(MENU_W - 110)
            if imgui.InputText("##greetmsg", greetMsgBuf) then
                cfg.greet_msg = greetMsgBuf.v
                saveCfg()
            end
            imgui.PopItemWidth()

            imgui.Spacing()
            imgui.TextColored(C_GRAY, u8("Trigger login:")) imgui.SameLine(0, 8)
            imgui.PushItemWidth(MENU_W - 115)
            if imgui.InputText("##greettrig", greetTriggerBuf) then
                cfg.greet_trigger = greetTriggerBuf.v
                saveCfg()
            end
            imgui.PopItemWidth()
            imgui.TextColored(C_GRAY, u8("(mesajul din chat care indica ca te-ai logat)"))

            imgui.Spacing()
            imgui.TextColored(C_GRAY, u8("Trimite pe:"))
            imgui.Spacing()

            local bGY = imgui.ImBool(cfg.greet_y)
            if imgui.Checkbox("/y  ##gy", bGY) then cfg.greet_y = bGY.v; saveCfg() end
            local bGC = imgui.ImBool(cfg.greet_c)
            if imgui.Checkbox("/c  ##gc", bGC) then cfg.greet_c = bGC.v; saveCfg() end
            local bGR = imgui.ImBool(cfg.greet_r)
            if imgui.Checkbox("/r  ##grr", bGR) then cfg.greet_r = bGR.v; saveCfg() end

            imgui.Spacing()
            imgui.TextColored(C_GRAY, u8("Delay (sec):")) imgui.SameLine(0, 8)
            local delayBuf = imgui.ImFloat(cfg.greet_delay)
            imgui.PushItemWidth(60)
            if imgui.SliderFloat("##gdelay", delayBuf, 1.0, 30.0) then
                cfg.greet_delay = math.floor(delayBuf.v)
                saveCfg()
            end
            imgui.PopItemWidth()

            imgui.Spacing()
            if cfg.greet_enabled and cfg.greet_msg ~= "" then
                local chats = {}
                if cfg.greet_y then table.insert(chats, "/y") end
                if cfg.greet_c then table.insert(chats, "/c") end
                if cfg.greet_r then table.insert(chats, "/r") end
                if #chats > 0 then
                    imgui.TextColored(C_GREEN, u8('Va trimite "' .. cfg.greet_msg .. '" pe ' .. table.concat(chats, ", ")))
                else
                    imgui.TextColored(C_ORANGE, u8("Selecteaza cel putin un chat!"))
                end
            else
                imgui.TextColored(C_GRAY, u8("Dezactivat"))
            end

            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            -- wheelie spam
            imgui.PushStyleColor(imgui.Col.Button,        CAT_BG)
            imgui.PushStyleColor(imgui.Col.ButtonHovered, CAT_BG)
            imgui.PushStyleColor(imgui.Col.ButtonActive,  CAT_BG)
            imgui.Button("WHEELIE SPAM", imgui.ImVec2(MENU_W - 16, 20))
            imgui.PopStyleColor(3)

            imgui.Spacing()
            local bNitro = imgui.ImBool(cfg.nitro_enabled)
            if imgui.Checkbox(u8("Activ (spam wheelie cand tii W pe moto)##nitro"), bNitro) then
                cfg.nitro_enabled = bNitro.v
                saveCfg()
            end
            imgui.TextColored(C_GRAY, u8("(doar pe motocicleta, nu pe bicicleta)"))
            imgui.Spacing()

        end

    -- ── TAB: SETTINGS ─────────────────────────────────────────
    elseif activeTab == "settings" then
        imgui.Spacing()

        -- culoare tema
        imgui.PushStyleColor(imgui.Col.Button,        CAT_BG)
        imgui.PushStyleColor(imgui.Col.ButtonHovered, CAT_BG)
        imgui.PushStyleColor(imgui.Col.ButtonActive,  CAT_BG)
        imgui.Button("CULOARE TEMA", imgui.ImVec2(MENU_W - 16, 20))
        imgui.PopStyleColor(3)

        imgui.Spacing()
        imgui.TextColored(C_GRAY, u8("Alege culoarea principala (header, butoane):"))
        imgui.Spacing()

        -- 3 slidere RGB in loc de ColorEdit3 (nu e suportat in moon-imgui)
        local rBuf = imgui.ImFloat(cfg.theme_r)
        local gBuf = imgui.ImFloat(cfg.theme_g)
        local bBuf = imgui.ImFloat(cfg.theme_b)

        imgui.TextColored(C_GRAY, "R") imgui.SameLine(0, 8)
        imgui.PushItemWidth(MENU_W - 50)
        if imgui.SliderFloat("##tr", rBuf, 0.0, 1.0) then
            cfg.theme_r = rBuf.v; applyTheme(); saveCfg()
        end
        imgui.PopItemWidth()

        imgui.TextColored(C_GRAY, "G") imgui.SameLine(0, 8)
        imgui.PushItemWidth(MENU_W - 50)
        if imgui.SliderFloat("##tg", gBuf, 0.0, 1.0) then
            cfg.theme_g = gBuf.v; applyTheme(); saveCfg()
        end
        imgui.PopItemWidth()

        imgui.TextColored(C_GRAY, "B") imgui.SameLine(0, 8)
        imgui.PushItemWidth(MENU_W - 50)
        if imgui.SliderFloat("##tb", bBuf, 0.0, 1.0) then
            cfg.theme_b = bBuf.v; applyTheme(); saveCfg()
        end
        imgui.PopItemWidth()

        -- preview culoare curenta
        imgui.Spacing()
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(cfg.theme_r, cfg.theme_g, cfg.theme_b, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(cfg.theme_r, cfg.theme_g, cfg.theme_b, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(cfg.theme_r, cfg.theme_g, cfg.theme_b, 1.0))
        imgui.Button(u8("Preview culoare"), imgui.ImVec2(MENU_W - 16, 22))
        imgui.PopStyleColor(3)

        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()

        -- culoare checkmark si radiobutton
        imgui.PushStyleColor(imgui.Col.Button,        CAT_BG)
        imgui.PushStyleColor(imgui.Col.ButtonHovered, CAT_BG)
        imgui.PushStyleColor(imgui.Col.ButtonActive,  CAT_BG)
        imgui.Button("CULOARE CHECKMARK / RADIO", imgui.ImVec2(MENU_W - 16, 20))
        imgui.PopStyleColor(3)

        imgui.Spacing()
        imgui.TextColored(C_GRAY, u8("Culoarea bifei la checkbox si radiobutton:"))
        imgui.Spacing()

        local crBuf = imgui.ImFloat(cfg.check_r or 0.77)
        local cgBuf = imgui.ImFloat(cfg.check_g or 0.07)
        local cbBuf = imgui.ImFloat(cfg.check_b or 0.19)

        imgui.TextColored(C_GRAY, "R") imgui.SameLine(0, 8)
        imgui.PushItemWidth(MENU_W - 50)
        if imgui.SliderFloat("##cr", crBuf, 0.0, 1.0) then
            cfg.check_r = crBuf.v; saveCfg()
        end
        imgui.PopItemWidth()

        imgui.TextColored(C_GRAY, "G") imgui.SameLine(0, 8)
        imgui.PushItemWidth(MENU_W - 50)
        if imgui.SliderFloat("##cg", cgBuf, 0.0, 1.0) then
            cfg.check_g = cgBuf.v; saveCfg()
        end
        imgui.PopItemWidth()

        imgui.TextColored(C_GRAY, "B") imgui.SameLine(0, 8)
        imgui.PushItemWidth(MENU_W - 50)
        if imgui.SliderFloat("##cb", cbBuf, 0.0, 1.0) then
            cfg.check_b = cbBuf.v; saveCfg()
        end
        imgui.PopItemWidth()

        imgui.Spacing()
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(cfg.check_r or 0.77, cfg.check_g or 0.07, cfg.check_b or 0.19, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(cfg.check_r or 0.77, cfg.check_g or 0.07, cfg.check_b or 0.19, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(cfg.check_r or 0.77, cfg.check_g or 0.07, cfg.check_b or 0.19, 1.0))
        imgui.Button(u8("Preview checkmark"), imgui.ImVec2(MENU_W - 16, 22))
        imgui.PopStyleColor(3)

        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()

        -- debug toggle
        imgui.PushStyleColor(imgui.Col.Button,        CAT_BG)
        imgui.PushStyleColor(imgui.Col.ButtonHovered, CAT_BG)
        imgui.PushStyleColor(imgui.Col.ButtonActive,  CAT_BG)
        imgui.Button("DEBUG", imgui.ImVec2(MENU_W - 16, 20))
        imgui.PopStyleColor(3)

        imgui.Spacing()
        local bDbg = imgui.ImBool(DEBUG)
        if imgui.Checkbox(u8("Afiseaza mesaje debug in chat##dbg"), bDbg) then
            DEBUG = bDbg.v
        end

        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()

        -- culori preset rapide
        imgui.TextColored(C_GRAY, u8("Preseturi:"))
        imgui.Spacing()

        local presets = {
            { name = "Rosu (default)", r = 0.48, g = 0.06, b = 0.06 },
            { name = "Albastru",       r = 0.06, g = 0.15, b = 0.48 },
            { name = "Verde",          r = 0.06, g = 0.38, b = 0.10 },
            { name = "Mov",            r = 0.30, g = 0.06, b = 0.48 },
            { name = "Portocaliu",     r = 0.55, g = 0.25, b = 0.04 },
            { name = "Gri inchis",     r = 0.20, g = 0.20, b = 0.20 },
        }

        for i, p in ipairs(presets) do
            local col = imgui.ImVec4(p.r, p.g, p.b, 1.0)
            imgui.PushStyleColor(imgui.Col.Button,        col)
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(p.r+0.1, p.g+0.02, p.b+0.02, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(p.r-0.1, p.g-0.02, p.b-0.02, 1.0))
            if imgui.Button(u8(p.name) .. "##pre" .. i, imgui.ImVec2(MENU_W - 16, 22)) then
                cfg.theme_r = p.r
                cfg.theme_g = p.g
                cfg.theme_b = p.b
                applyTheme()
                saveCfg()
            end
            imgui.PopStyleColor(3)
            imgui.Spacing()
        end

    -- ── TAB: INFO ─────────────────────────────────────────────
    elseif activeTab == "info" then
        imgui.Spacing()

        imgui.PushStyleColor(imgui.Col.Button,        CAT_BG)
        imgui.PushStyleColor(imgui.Col.ButtonHovered, CAT_BG)
        imgui.PushStyleColor(imgui.Col.ButtonActive,  CAT_BG)
        imgui.Button("FISHJOB", imgui.ImVec2(MENU_W - 16, 20))
        imgui.PopStyleColor(3)

        imgui.Spacing()
        imgui.TextColored(C_GRAY,   "Versiune")   imgui.SameLine(120) imgui.Text("4.5.0")
        imgui.TextColored(C_GRAY,   "Autor")      imgui.SameLine(120) imgui.TextColored(C_GREEN, "Claude")
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()

        imgui.PushStyleColor(imgui.Col.Button,        CAT_BG)
        imgui.PushStyleColor(imgui.Col.ButtonHovered, CAT_BG)
        imgui.PushStyleColor(imgui.Col.ButtonActive,  CAT_BG)
        imgui.Button("COMENZI", imgui.ImVec2(MENU_W - 16, 20))
        imgui.PopStyleColor(3)

        imgui.Spacing()
        imgui.TextColored(CAT_BG,  "/multimod")   imgui.SameLine(110) imgui.TextColored(C_GRAY, u8("deschide meniul"))
        imgui.TextColored(CAT_BG,  "F6")          imgui.SameLine(110) imgui.TextColored(C_GRAY, u8("toggle bot on/off"))
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()

        imgui.PushStyleColor(imgui.Col.Button,        CAT_BG)
        imgui.PushStyleColor(imgui.Col.ButtonHovered, CAT_BG)
        imgui.PushStyleColor(imgui.Col.ButtonActive,  CAT_BG)
        imgui.Button("FEATURES", imgui.ImVec2(MENU_W - 16, 20))
        imgui.PopStyleColor(3)

        imgui.Spacing()
        local features = {
            u8("Bot pescuit automat cu spam /fish"),
            u8("Auto casca pe motocicleta (/ph)"),
            u8("Auto intrare masina (F/G) dupa catch"),
            u8("Counter sesiune cu bani + rata/h"),
            u8("Counter raport factiune in timp real"),
            u8("Zone pescuit pe minimap (gangzone)"),
            u8("Cooldown dinamic din mesaje server"),
            u8("Retry automat la scared fish"),
            u8("Tema personalizabila cu color picker"),
        }
        for _, f in ipairs(features) do
            imgui.TextColored(C_GRAY, "- ") imgui.SameLine(0, 0) imgui.Text(f)
        end
        imgui.Spacing()
    end

    -- ── BUTON INCHIDE ─────────────────────────────────────────
    imgui.Spacing()
    imgui.Separator()
    imgui.Spacing()
    local bw = 100
    imgui.SetCursorPosX((MENU_W - bw) * 0.5)
    if redBtn(u8("INCHIDE"), bw, 24) then showMenu = false end

    imgui.End()
    popMenuStyle()
end

-- ============================================================
-- IMGUI OnDrawFrame
-- ============================================================
function imgui.OnDrawFrame()
    imgui.ShowCursor = showMenu
    drawCounter()
    drawRaportCounter()
    if showMenu then
        pcall(drawMain)
    end
end

-- ============================================================
-- SAMP EVENTS
-- ============================================================
function sampev.onServerMessage(color, text)
    local t = text:gsub("{[%x]+}", ""):lower()
    local tOrig = text:gsub("{[%x]+}", "")  -- fara lowercase pentru parsare numere

    -- Detectare autologin — triggereza salut
    if cfg.greet_enabled and (
        t:find("you are now logged in") or
        t:find("you are a legend") or
        t:find("autentificat cu succes") or
        t:find("logat cu succes") or
        t:find("welcome back") or
        t:find("ai fost logat automat") or
        t:find("logged in automatically") or
        (cfg.greet_trigger ~= "" and t:find(cfg.greet_trigger:lower(), 1, true))
    ) then
        greetPending = true
        return
    end

    -- Confirmare inceput pescuit
    if t:find("you're now fishing") or t:find("you are now fishing") then
        if cfg.enabled and (state == ST.FISHING or state == ST.SPAMMING) then
            state       = ST.CONFIRMED
            fishTimeout = os.clock() + 60
        end
        return
    end

    -- Captura peste
    if t:match("you caught a .+ fish!") then
        catchTime      = os.clock()
        cooldownEndsAt = catchTime + SERVER_COOLDOWN
        if session.active then session.sold = false end
        if cfg.enabled and (state == ST.FISHING or state == ST.CONFIRMED or state == ST.SPAMMING) then
            state       = ST.WAITING
            waitTimeout = os.clock() + 180
        end
        scheduleDL()
        return
    end

    -- Vanzare peste: "You sold the fish for $13,172."
    local fishMoney = tOrig:match("[Yy]ou sold the fish for %$([%d,]+)")
    if fishMoney then
        local amount = tonumber((fishMoney:gsub(",", ""))) or 0
        if session.active then
            session.caught = session.caught + 1
            session.money  = session.money + amount
            local now = os.time()
            if session.firstCatch == 0 then session.firstCatch = now end
            session.lastCatch = now
        end
        if cfg.enabled and state == ST.WAITING then
            session.sold = true
        end
        return
    end

    -- Pet bonus: "PET BONUS: You received an extra $66 for the fisherman job."
    local petMoney = tOrig:match("[Pp][Ee][Tt] [Bb][Oo][Nn][Uu][Ss].*%$([%d,]+)")
    if petMoney then
        local amount = tonumber((petMoney:gsub(",", ""))) or 0
        if session.active then
            session.money = session.money + amount
            -- NU incrementam session.bonus — aia e doar pentru skill points (skin bonus)
        end
        return
    end

    -- Ajustare cooldown
    local mins, secs = t:match("you must wait (%d+) minutes? %((%d+) seconds?%)")
    if mins and secs then
        local remaining = tonumber(mins) * 60 + tonumber(secs)
        cooldownEndsAt = os.clock() + remaining
        return
    end

    -- Skin bonus
    if t:find("skin bonus") and t:find("skill point") then
        if session.active then session.bonus = session.bonus + 1 end
        return
    end

    if t:find("you are already fishing") then
        if cfg.enabled and (state == ST.FISHING or state == ST.SPAMMING) then
            state       = ST.CONFIRMED
            fishTimeout = os.clock() + 60
        end
        return
    end

    -- Scared fish
    if t:find("you scared the fish") then
        if cfg.enabled then
            state = ST.IDLE
            lua_thread.create(function()
                wait(2000)
                if cfg.enabled and inAnyZone() and not isCharInAnyCar(PLAYER_PED) then
                    sampSendChat("/fish")
                    state       = ST.FISHING
                    fishTimeout = os.clock() + 15
                    dbg("Scared fish — retrimis /fish")
                end
            end)
        end
        return
    end

    -- ── RAPORT FACTIUNE ──────────────────────────────────────
    -- Parsare din /raport (toate liniile)
    local arr, kil = tOrig:match("[Pp]layers arrested/killed:%s*(%d+)/(%d+)")
    if arr and kil then
        raport.arrested = tonumber(arr) or 0
        raport.killed   = tonumber(kil) or 0
        raport.hasData  = true
        return
    end

    local tk, tkMax = tOrig:match("[Tt]ickets:%s*(%d+)/(%d+)")
    if tk and tkMax then
        raport.tickets    = tonumber(tk)    or 0
        raport.ticketsMax = tonumber(tkMax) or 0
        raport.hasData    = true
        return
    end
    
    local lcc, lccMax = tOrig:match("[Ll]icences confiscated:%s*(%d+)/(%d+)")
    if lcc and lccMax then
        raport.licConfiscated    = tonumber(lcc)    or 0
        raport.licConfiscatedMax = tonumber(lccMax) or 0
        raport.hasData           = true
        return
    end

    local hh, hm, rh, rm = tOrig:match("[Hh]ours played:%s*(%d+):(%d+)/(%d+):(%d+)")
    if hh and hm and rh and rm then
        raport.hoursH    = tonumber(hh) or 0
        raport.hoursM    = tonumber(hm) or 0
        raport.hoursReqH = tonumber(rh) or 0
        raport.hoursReqM = tonumber(rm) or 0
        raport.hasData   = true
        return
    end

    -- Parsare in timp real — mesaje individuale de activitate
    -- Arest: "You have arrested PlayerName." sau "PlayerName has been arrested."
    if t:find("has been arrested") or t:find("you have arrested") then
        raport.arrested = raport.arrested + 1
        raport.hasData  = true
        return
    end

    -- Kill: "You killed PlayerName." / mesaje de frag
    if t:find("you killed") or t:find("you have killed") then
        raport.killed  = raport.killed + 1
        raport.hasData = true
        return
    end

    -- Ticket: "You have issued a ticket" / "Ticket issued"
    if t:find("ticket issued") or t:find("you have issued a ticket") or t:find("ticket has been issued") then
        raport.tickets = raport.tickets + 1
        raport.hasData = true
        return
    end

    if t:find("licence confiscated") then
        raport.licConfiscated = raport.licConfiscated + 1
        raport.hasData       = true
        return
    end
end

-- ============================================================
-- SALUT AUTO DUPA LOGIN
-- ============================================================
local function sendGreet()
    if not cfg.greet_enabled then return end
    if cfg.greet_msg == "" then return end
    if greetSentThisSession then
        dbg("Salut: deja trimis in aceasta sesiune, skip")
        return
    end
    greetSentThisSession = true
    lua_thread.create(function()
        wait(cfg.greet_delay * 1000)
        if cfg.greet_y then sampSendChat("/y " .. cfg.greet_msg) end
        if cfg.greet_c then wait(400); sampSendChat("/c " .. cfg.greet_msg) end
        if cfg.greet_r then wait(400); sampSendChat("/r " .. cfg.greet_msg) end
        dbg("Salut trimis: " .. cfg.greet_msg)
    end)
end

-- greetPending e setat la conectare si resetat dupa primul spawn

-- ============================================================
-- MAIN
-- ============================================================
function main()
    while not isSampAvailable() do wait(100) end
    math.randomseed(os.time())
    loadCfg()

    imgui.Process = true
    applyTheme()
    dlVehicleInputBuf = imgui.ImBuffer(cfg.dl_vehicle > 0 and tostring(cfg.dl_vehicle) or "", 16)
    greetMsgBuf       = imgui.ImBuffer(cfg.greet_msg or "", 128)
    greetTriggerBuf   = imgui.ImBuffer(cfg.greet_trigger or "", 128)

    wait(2000)
    createFishZones()

    sampRegisterChatCommand("multimod", function()
        showMenu = not showMenu
    end)

    sampAddChatMessage("{00FF66}[MultiMod v1.0.0] {FFFFFF}Incarcat. /multimod = meniu | F6 = toggle", -1)

    local lastZoneRefresh = os.clock()
    while true do
        wait(0)

        if wasKeyPressed(VK_F6) then
            cfg.enabled = not cfg.enabled
            if cfg.enabled then
                state = ST.IDLE
                if not session.active then startSession() end
                sampAddChatMessage("{00FF66}[MultiMod] {FFFFFF}Activat.", -1)
            else
                state = ST.IDLE
                sampAddChatMessage("{FF4444}[MultiMod] {FFFFFF}Dezactivat.", -1)
            end
            saveCfg()
            wait(200)
        end

        if os.clock() - lastZoneRefresh > 300 then
            createFishZones()
            lastZoneRefresh = os.clock()
        end

        if cfg.auto_helmet then
            local onBike = onMotorcycle()
            if onBike and not wasOnBike then
                wait(700)
                sampSendChat("/ph")
            end
            wasOnBike = onBike
        end

        processDLPress()

        -- wheelie spam: setGameKeyState(1, -128) doar cand tii W apasat
        if cfg.nitro_enabled and isCharOnAnyBike(PLAYER_PED) then
            local model = getCarModel(storeCarCharIsInNoSave(PLAYER_PED))
            if MOTO_MODELS[model] then
                local chatOk = not sampIsChatInputActive() and not sampIsDialogActive()
                local wDown  = isKeyDown(0x57)  -- W
                if chatOk and wDown then
                    setGameKeyState(1, -128)
                    wait(0)
                    setGameKeyState(1, 0)
                end
            end
        end

        -- salut auto dupa login
        if greetPending and isCharOnScreen(PLAYER_PED) then
            greetPending = false
            sendGreet()
        end

        if cfg.enabled then
            local onFoot = not isCharInAnyCar(PLAYER_PED)
            local inZ    = inAnyZone()

            if state == ST.CONFIRMED and os.clock() >= fishTimeout then
                state = ST.IDLE
            end

            if state == ST.WAITING then
                if session.sold and inZ and os.clock() >= cooldownEndsAt then
                    state      = ST.SPAMMING
                    lastSpamAt = 0
                elseif os.clock() >= waitTimeout then
                    state        = ST.IDLE
                    session.sold = false
                    dbg("waitTimeout — resetat la IDLE")
                end
            end

            if state == ST.SPAMMING then
                if not inZ then
                    state = ST.WAITING
                elseif onFoot and os.clock() - lastSpamAt >= 0.5 then
                    sampSendChat("/fish")
                    lastSpamAt = os.clock()
                end
            end

            if onFoot and inZ then
                if state == ST.IDLE then
                    sampSendChat("/fish")
                    state       = ST.FISHING
                    fishTimeout = os.clock() + 15
                elseif state == ST.FISHING and os.clock() >= fishTimeout then
                    sampSendChat("/fish")
                    fishTimeout = os.clock() + 15
                end
            end
        end
    end
end