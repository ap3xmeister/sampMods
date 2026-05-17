-- JobStats.lua
-- MoonLoader 0.26+ / SAMPFUNCS 5.3+

script_name("JobStats")
script_author("Apex")
script_version("1.0")

require "lib.moonloader"
require "lib.sampfuncs"

local sampev = require "lib.samp.events"
local imgui = require "mimgui"
local inicfg = require "inicfg"
local ec = require "encoding"
ec.default = "CP1251"
u8 = ec.UTF8

-- Config structure ()
local ini = inicfg.load({
    arms_dealer = {
        skill = 0,
        points_for_rank_up = 0,
        info = "",
        shifts = 0,
        materials_earned = 0,
        materials_from_skins = 0,
        extra_materials_from_skill = 0,
        total_materials_earned = 0,
        extra_skill_points_earned = 0,
        bad_luck = 0,
        average_skill_point_per_shift = 0,
        total_time_spent_working = 0,
        average_materials_per_hour = 0,
        money_earned_during_sessions = 0
    };
    fisherman = {
        skill = 0,
        points_for_rank_up = 0,
        info = "",
        fish_caught = 0,
        money_earned = 0,
        money_from_pet = 0,
        money_from_skins = 0,
        total_money_earned = 0,
        extra_skill_points_earned = 0,
        bad_luck = 0,
        average_skill_point_per_fish_caught = 0,
        total_time_spent_working = 0,
        average_money_per_hour = 0,
        money_earned_during_sessions = 0
    };
    pizza_boy = {
        skill = 0,
        points_for_rank_up = 0,
        info = "",
        pizzas_delivered = 0,
        money_earned = 0,
        money_from_pet = 0,
        money_from_skins = 0,
        extra_money_from_skill = 0,
        total_money_earned = 0,
        extra_skill_points_earned = 0,
        bad_luck = 0,
        average_skill_point_per_pizza_delivered = 0,
        total_time_spent_working = 0,
        average_money_per_hour = 0,
        money_earned_during_sessions = 0
    };
    trucker = {
        skill = 0,
        points_for_rank_up = 0,
        info = "",
        trailers_delivered = 0,
        money_earned = 0,
        money_from_pet = 0,
        money_from_skins = 0,
        extra_money_from_skill = 0,
        total_money_earned = 0,
        extra_skill_points_earned = 0,
        bad_luck = 0,
        average_skill_point_per_trailer_delivered = 0,
        total_time_spent_working = 0,
        average_money_per_hour = 0,
        money_earned_during_sessions = 0
    };
    bus_driver = {
        skill = 0,
        points_for_rank_up = 0,
        info = "",
        bus_stops = 0,
        money_earned = 0,
        money_from_skins = 0,
        extra_money_from_skill = 0,
        total_money_earned = 0,
        extra_skill_points_earned = 0,
        bad_luck = 0,
        average_skill_point_per_bus_stop = 0,
        total_time_spent_working = 0,
        average_money_per_hour = 0,
        money_earned_during_sessions = 0
    };
    garbage_man = {
        skill = 0,
        points_for_rank_up = 0,
        info = "",
        shifts = 0,
        money_earned = 0,
        money_from_pet = 0,
        money_from_skins = 0,
        extra_money_from_skill = 0,
        total_money_earned = 0,
        extra_skill_points_earned = 0,
        bad_luck = 0,
        average_skill_point_per_shift = 0,
        total_time_spent_working = 0,
        average_money_per_hour = 0,
        money_earned_during_sessions = 0
    };
    farmer = {
        skill = 0,
        points_for_rank_up = 0,
        info = "",
        flour_sold = 0,
        money_earned = 0,
        money_from_pet = 0,
        money_from_skins = 0,
        extra_money_from_skill = 0,
        total_money_earned = 0,
        extra_skill_points_earned = 0,
        bad_luck = 0,
        average_skill_point_per_flour_sold = 0,
        total_time_spent_working = 0,
        average_money_per_hour = 0,
        money_earned_during_sessions = 0
    };
    boat_transporter = {
        skill = 0,
        points_for_rank_up = 0,
        info = "",
        shifts = 0,
        money_earned = 0,
        money_from_pet = 0,
        money_from_skins = 0,
        extra_money_from_skill = 0,
        total_money_earned = 0,
        extra_skill_points_earned = 0,
        bad_luck = 0,
        average_skill_point_per_shift = 0,
        total_time_spent_working = 0,
        average_money_per_hour = 0,
        money_earned_during_sessions = 0
    };
    delivery_driver = {
        skill = 0,
        points_for_rank_up = 0,
        info = "",
        deliveries_made = 0,
        money_earned = 0,
        money_from_skins = 0,
        total_money_earned = 0,
        extra_skill_points_earned = 0,
        bad_luck = 0,
        average_skill_point_per_delivery_made = 0,
        total_time_spent_working = 0,
        average_money_per_hour = 0,
        money_earned_during_sessions = 0
    };
    tow_trucker = {
        skill = 0,
        points_for_rank_up = 0,
        info = "",
        cars_trucked = 0,
        money_earned = 0,
        money_from_pet = 0,
        money_from_skins = 0,
        extra_money_from_skill = 0,
        total_money_earned = 0,
        extra_skill_points_earned = 0,
        bad_luck = 0,
        average_skill_point_per_cars_trucked = 0,
        total_time_spent_working = 0,
        average_money_per_hour = 0,
        money_earned_during_sessions = 0
    };
    total_job_stats = {
        money_earned = 0,
        money_from_pet = 0,
        money_from_skins = 0,
        extra_money_from_skill = 0,
        total_money_earned = 0,
        extra_skill_points_earned = 0,
        bad_luck = 0,
        average_skill_point_per_shifts = 0,
        total_time_spent_working = 0,
        average_money_per_hour = 0,
        money_earned_during_sessions = 0,
        total_shifts = 0
    };
    read_skills = {
        enable = false
    };
}, "JobStats.ini")

-- Runtime state
local main_window = imgui.new.bool()

local arms_dealer_window = imgui.new.bool()
local fisherman_window = imgui.new.bool()
local pizza_boy_window = imgui.new.bool()
local trucker_window = imgui.new.bool()
local bus_driver_window = imgui.new.bool()
local garbage_man_window = imgui.new.bool()
local farmer_window = imgui.new.bool()
local boat_transporter_window = imgui.new.bool()
local delivery_driver_window = imgui.new.bool()
local tow_trucker_window = imgui.new.bool()

local arms_dealer_session_window = imgui.new.bool()
local fisherman_session_window = imgui.new.bool()
local pizza_boy_session_window = imgui.new.bool()
local trucker_session_window = imgui.new.bool()
local bus_driver_session_window = imgui.new.bool()
local garbage_man_session_window = imgui.new.bool()
local farmer_session_window = imgui.new.bool()
local boat_transporter_session_window = imgui.new.bool()
local delivery_driver_session_window = imgui.new.bool()
local tow_trucker_session_window = imgui.new.bool()

local total_job_stats_window = imgui.new.bool()

local debug = 0
-- Job stats variables
local arms_dealer_session_stats = {
    session_time = 0,
    shifts = 0,
    materials_earned = 0,
    materials_from_skins = 0,
    extra_materials_from_skill = 0,
    total_materials_earned = 0,
    extra_skill_points_earned = 0,
    bad_luck = 0,
    average_skill_point_per_shift = 0
}

local fisherman_session_stats = {
    session_time = 0,
    fish_caught = 0,
    money_earned = 0,
    money_from_pet = 0,
    money_from_skins = 0,
    total_money_earned = 0,
    extra_skill_points_earned = 0,
    bad_luck = 0,
    average_skill_point_per_fish_caught = 0
}

local pizza_boy_session_stats = {
    session_time = 0,
    pizzas_delivered = 0,
    money_earned = 0,
    money_from_pet = 0,
    money_from_skins = 0,
    extra_money_from_skill = 0,
    total_money_earned = 0,
    extra_skill_points_earned = 0,
    bad_luck = 0,
    average_skill_point_per_pizza_delivered = 0
}

local trucker_session_stats = {
    session_time = 0,
    trailers_delivered = 0,
    money_earned = 0,
    money_from_pet = 0,
    money_from_skins = 0,
    extra_money_from_skill = 0,
    total_money_earned = 0,
    extra_skill_points_earned = 0,
    bad_luck = 0,
    average_skill_point_per_trailer_delivered = 0
}

local bus_driver_session_stats = {
    session_time = 0,
    bus_stops = 0,
    money_earned = 0,
    money_from_skins = 0,
    extra_money_from_skill = 0,
    total_money_earned = 0,
    extra_skill_points_earned = 0,
    bad_luck = 0,
    average_skill_point_per_bus_stop = 0,
    current_shift = 0
}

local garbage_man_session_stats = {
    session_time = 0,
    shifts = 0,
    money_earned = 0,
    money_from_pet = 0,
    money_from_skins = 0,
    extra_money_from_skill = 0,
    total_money_earned = 0,
    extra_skill_points_earned = 0,
    bad_luck = 0,
    average_skill_point_per_shift = 0
}

local farmer_session_stats = {
    session_time = 0,
    flour_sold = 0,
    money_earned = 0,
    money_from_pet = 0,
    money_from_skins = 0,
    extra_money_from_skill = 0,
    total_money_earned = 0,
    extra_skill_points_earned = 0,
    bad_luck = 0,
    average_skill_point_per_flour_sold = 0
}

local boat_transporter_session_stats = {
    session_time = 0,
    shifts = 0,
    money_earned = 0,
    money_from_pet = 0,
    money_from_skins = 0,
    extra_money_from_skill = 0,
    total_money_earned = 0,
    extra_skill_points_earned = 0,
    bad_luck = 0,
    average_skill_point_per_shift = 0
}

local delivery_driver_session_stats = {
    session_time = 0,
    deliveries_made = 0,
    money_earned = 0,
    money_from_skins = 0,
    total_money_earned = 0,
    extra_skill_points_earned = 0,
    bad_luck = 0,
    average_skill_point_per_delivery_made = 0
}

local tow_trucker_session_stats = {
    session_time = 0,
    cars_trucked = 0,
    money_earned = 0,
    money_from_pet = 0,
    money_from_skins = 0,
    extra_money_from_skill = 0,
    total_money_earned = 0,
    extra_skill_points_earned = 0,
    bad_luck = 0,
    average_skill_point_per_cars_trucked = 0
}

local isArmsDealer = false
local isFisherman = false
local isPizzaBoy = false
local isTrucker = false
local isBusDriver = false
local isGarbageMan = false
local isFarmer = false
local isBoatTransporter = false
local isDeliveryDriver = false
local isTowTrucker = false


local arms_dealer_session = false
local arms_dealer_session_start = nil
local fisherman_session = false
local fisherman_session_start = nil
local pizza_boy_session = false
local pizza_boy_session_start = nil
local trucker_session = false
local trucker_session_start = nil
local bus_driver_session = false
local bus_driver_session_start = nil
local garbage_man_session = false
local garbage_man_session_start = nil
local farmer_session = false
local farmer_session_start = nil
local boat_transporter_session = false
local boat_transporter_session_start = nil
local delivery_driver_session = false
local delivery_driver_session_start = nil
local tow_trucker_session = false
local tow_trucker_session_start = nil

local bus_stops_for_current_shift = 0
local bus_stops_for_current_shift_session = 0

local MONEY_GREEN       = imgui.ImVec4(0.075, 0.471, 0.11, 1.0)
local MONEY_YELLOW      = imgui.ImVec4(0.965, 1, 0, 1.0)
local COLOR_BRONZE      = imgui.ImVec4(0.80, 0.49, 0.20, 1.0)
local COLOR_SILVER      = imgui.ImVec4(0.78, 0.78, 0.82, 1.0)
local COLOR_GOLD        = imgui.ImVec4(0.95, 0.78, 0.18, 1.0)
local COLOR_DIAMOND     = imgui.ImVec4(0.25, 0.78, 1.00, 1.0)
local INFOJOB_COLOR     = imgui.ImVec4(0.52, 0.91, 0.57, 1.0)

local last_total_kg = 0
local last_bonus_kg = 0

function clearJobActive() 
    isArmsDealer = false
    isFisherman = false
    isPizzaBoy = false
    isTrucker = false
    isBusDriver = false
    isGarbageMan = false
    isFarmer = false
    isBoatTransporter = false
    isDeliveryDriver = false
    isTowTrucker = false
end

function showActiveJobs()
    if isArmsDealer then
        sampAddChatMessage(u8("[JobStats] Active job: Arms Dealer."), -1)
    end
    if isFisherman then
        sampAddChatMessage(u8("[JobStats] Active job: Fisherman."), -1)
    end
    if isPizzaBoy then
        sampAddChatMessage(u8("[JobStats] Active job: Pizza Boy."), -1)
    end
    if isTrucker then
        sampAddChatMessage(u8("[JobStats] Active job: Trucker."), -1)
    end
    if isBusDriver then
        sampAddChatMessage(u8("[JobStats] Active job: Bus Driver."), -1)
    end
    if isGarbageMan then
        sampAddChatMessage(u8("[JobStats] Active job: Garbageman."), -1)
    end
    if isFarmer then
        sampAddChatMessage(u8("[JobStats] Active job: Farmer."), -1)
    end
    if isBoatTransporter then
        sampAddChatMessage(u8("[JobStats] Active job: Boat Transporter."), -1)
    end
    if isDeliveryDriver then
        sampAddChatMessage(u8("[JobStats] Active job: Delivery Driver."), -1)
    end
    if isTowTrucker then
        sampAddChatMessage(u8("[JobStats] Active job: Tow Trucker."), -1)
    end
end

local function getActiveJobKey()
    if isArmsDealer then return "arms_dealer" end
    if isFisherman then return "fisherman" end
    if isPizzaBoy then return "pizza_boy" end
    if isTrucker then return "trucker" end
    if isBusDriver then return "bus_driver" end
    if isGarbageMan then return "garbage_man" end
    if isFarmer then return "farmer" end
    if isBoatTransporter then return "boat_transporter" end
    if isDeliveryDriver then return "delivery_driver" end
    if isTowTrucker then return "tow_trucker" end
end

local function getSessionStatsByJob(jobKey)
    if jobKey == "arms_dealer" then return arms_dealer_session, arms_dealer_session_stats end
    if jobKey == "fisherman" then return fisherman_session, fisherman_session_stats end
    if jobKey == "pizza_boy" then return pizza_boy_session, pizza_boy_session_stats end
    if jobKey == "trucker" then return trucker_session, trucker_session_stats end
    if jobKey == "bus_driver" then return bus_driver_session, bus_driver_session_stats end
    if jobKey == "garbage_man" then return garbage_man_session, garbage_man_session_stats end
    if jobKey == "farmer" then return farmer_session, farmer_session_stats end
    if jobKey == "boat_transporter" then return boat_transporter_session, boat_transporter_session_stats end
    if jobKey == "delivery_driver" then return delivery_driver_session, delivery_driver_session_stats end
    if jobKey == "tow_trucker" then return tow_trucker_session, tow_trucker_session_stats end
end

function sampev.onShowDialog(dialogId, dialogStyle, dialogTitle, button1, button2, text)
    text = text or ""

    local jobMap = {
        ["Fisherman"] = "fisherman",
        ["Arms Dealer"] = "arms_dealer",
        ["Pizza Boy"] = "pizza_boy",
        ["Trucker"] = "trucker",
        ["Garbageman"] = "garbage_man",
        ["Farmer"] = "farmer",
        ["Boat Transporter"] = "boat_transporter",
        ["Bus Driver"] = "bus_driver",
        ["Tow Trucker"] = "tow_trucker",
        ["Delivery Driver"] = "delivery_driver"
    }

    for line in text:gmatch("[^\r\n]+") do
        local job, rank, points, info = line:match("^(.-)\t(.-)\t(%d+)\t(.*)$")

        if job and rank and points then
            if info then
                info = info:gsub("%(%+(%d+)", "(+%1%% ")
            end
            local section = jobMap[job]
            if section and ini[section] then
                ini[section].skill = rank or ""
                ini[section].points_for_rank_up = tonumber(points) or 0
                ini[section].info = info or ""
            end
        end
    end

    inicfg.save(ini, "JobStats.ini")
end

local function handleJobSkillText(text)
    
end

function sampev.onServerMessage(color, text)
    text = text or ""

    local rank = text:match("Felicitari! Ai acum skill%s+(.+)%s+pentru acest job!")
    if rank then
        lua_thread.create(function()
            sampSendChat("/skills")
            wait(50)
            setVirtualKeyDown(VK_ESCAPE, true)
            wait(80)
            setVirtualKeyDown(VK_ESCAPE, false)
        end)

    end

    if text:find("^You're now fishing. It will take a few seconds to reel your fish in.") then
        if not fisherman_session_window[0] then 
            fisherman_session_window[0] = true
            fisherman_session = true
            fisherman_session_stats.session_time = 0
            fisherman_session_start = os.time()
        end
        if not isFisherman then
            clearJobActive()
            isFisherman = true
            showActiveJobs()
        end
    end

    if text:match("^Scrie /pizza pentru a incepe sa muncesti%.$") or text:match("^Mergi la punctele galbene pentru a livra pizza%.$") then
        if not pizza_boy_session_window[0] then
            pizza_boy_session_window[0] = true
            pizza_boy_session = true
            pizza_boy_session_stats.session_time = 0
            pizza_boy_session_start = os.time()
        end

        if not isPizzaBoy then
            clearJobActive()
            isPizzaBoy = true
            showActiveJobs()
        end
    end

    if text:find("^Mergi la checkpointul de pe minimap pentru a livra marfa%.$") then
        if not trucker_session_window[0] then
            trucker_session_window[0] = true
            trucker_session = true
            trucker_session_stats.session_time = 0
            trucker_session_start = os.time() 
        end
        if not isTrucker then
            clearJobActive()
            isTrucker = true
            showActiveJobs()
        end
    end

    if text:find("^Mergi la checkpoint%.$") then
        if not bus_driver_session_window[0] then
            bus_driver_session_window[0] = true
            bus_driver_session = true
            bus_driver_session_stats.session_time = 0
            bus_driver_session_start = os.time() 
        end
        bus_stops_for_current_shift = 0

        if not isBusDriver then 
            clearJobActive()
            isBusDriver = true
            showActiveJobs()
        end
    end

    if text:match("^Foloseste /collecttrash pentru a incepe sa colectezi gunoiul%.$") or text:match("^Mergi la checkpoint pentru a incepe colectarea gunoiului%. Distanta:") then
        if not garbage_man_session_window[0] then
            garbage_man_session_window[0] = true
            garbage_man_session = true
            garbage_man_session_stats.session_time = 0
            garbage_man_session_start = os.time()
        end

        if not isGarbageMan then
            clearJobActive()
            isGarbageMan = true
            showActiveJobs()
        end
    end

    local actorName = text:match("^%* (.-)%[%d+%] starts the engine of his Tractor%.")

    local ok, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    local myName = ok and sampGetPlayerNickname(myId) or nil
    if actorName and myName and actorName:lower() == myName:lower() then
        if not farmer_session_window[0] then 
            farmer_session_window[0] = true
            farmer_session = true
            farmer_session_stats.session_time = 0
            farmer_session_start = os.time()
        end
        if not isFarmer then
            clearJobActive()
            isFarmer = true
            showActiveJobs()
        end
    end
    
    if text:match("^Mergi la checkpoint pentru a incarca marfa in barca!$") or text:match("^Mergi la checkpoint pentru a livra marfa!$") then
        if not boat_transporter_session_window[0] then
            boat_transporter_session_window[0] = true
            boat_transporter_session = true
            boat_transporter_session_stats.session_time = 0
            boat_transporter_session_start = os.time()
        end

        if not isDeliveryDriver then
            clearJobActive()
            isDeliveryDriver = true
            showActiveJobs()
        end
    end

    if text:find("^Mergi la iconul portocaliu de pe harta pentru a incarca pachetele%.$") then
        if not delivery_driver_session_window[0] then
            delivery_driver_session_window[0] = true
            delivery_driver_session = true
            delivery_driver_session_stats.session_time = 0
            delivery_driver_session_start = os.time()
        end
        if not isDeliveryDriver then
            clearJobActive()
            isDeliveryDriver = true
            showActiveJobs()
        end
    end

    if text:match("^Pentru a munci ca tow trucker, scrie /towstart%.$") then
        if not tow_trucker_session_window[0] then
            tow_trucker_session_window[0] = true
            tow_trucker_session = true
            tow_trucker_session_stats.session_time = 0
            tow_trucker_session_start = os.time()
        end
        if not isTowTrucker then
            clearJobActive()
            isTowTrucker = true
            showActiveJobs()
        end
    end

    if text:match("^Mergi la checkpoint pentru a colecta materialele%.$") then
        if not arms_dealer_session_window[0] then
            arms_dealer_session_window[0] = true
            arms_dealer_session = true
            arms_dealer_session_stats.session_time = 0
            arms_dealer_session_start = os.time()
        end
        if not isArmsDealer then
            clearJobActive()
            isArmsDealer = true
            showActiveJobs()
        end
    end

    if text:match("^Nu ai fost norocos de data asta %(nu ai obtinut un skill point extra%)%.$") then
        local jobKey = getActiveJobKey()
        if jobKey and ini[jobKey] then
            ini[jobKey].bad_luck = (ini[jobKey].bad_luck or 0) + 1

            local sessionActive, sessionStats = getSessionStatsByJob(jobKey)
            if sessionActive and sessionStats then
                sessionStats.bad_luck = (sessionStats.bad_luck or 0) + 1
            end

            inicfg.save(ini, "JobStats.ini")
        end
    end

    if text:find("SKIN BONUS: Ai obtinut un skill point extra pentru jobul", 1, true) then
        if isArmsDealer then
            ini.arms_dealer.extra_skill_points_earned = ini.arms_dealer.extra_skill_points_earned + 1
            ini.arms_dealer.points_for_rank_up = math.max(0, ini.arms_dealer.points_for_rank_up - 1)
            inicfg.save(ini, "JobStats.ini")
            if arms_dealer_session then
                arms_dealer_session_stats.extra_skill_points_earned = arms_dealer_session_stats.extra_skill_points_earned + 1
            end
        end
        if isFisherman then
            ini.fisherman.extra_skill_points_earned = ini.fisherman.extra_skill_points_earned + 1
            ini.fisherman.points_for_rank_up = math.max(0, ini.fisherman.points_for_rank_up - 1)
            inicfg.save(ini, "JobStats.ini")
            if fisherman_session then
                fisherman_session_stats.extra_skill_points_earned = fisherman_session_stats.extra_skill_points_earned + 1
            end
        end
        if isPizzaBoy then
            ini.pizza_boy.extra_skill_points_earned = ini.pizza_boy.extra_skill_points_earned + 1
            ini.pizza_boy.points_for_rank_up = math.max(0, ini.pizza_boy.points_for_rank_up - 1)
            inicfg.save(ini, "JobStats.ini")
            if pizza_boy_session then
                pizza_boy_session_stats.extra_skill_points_earned = pizza_boy_session_stats.extra_skill_points_earned + 1
            end
        end
        if isTrucker then
            ini.trucker.extra_skill_points_earned = ini.trucker.extra_skill_points_earned + 1
            ini.trucker.points_for_rank_up = math.max(0, ini.trucker.points_for_rank_up - 1)
            inicfg.save(ini, "JobStats.ini")
            if trucker_session then
                trucker_session_stats.extra_skill_points_earned = trucker_session_stats.extra_skill_points_earned + 1
            end
        end
        if isBusDriver then
            ini.bus_driver.extra_skill_points_earned = ini.bus_driver.extra_skill_points_earned + 1
            ini.bus_driver.points_for_rank_up = math.max(0, ini.bus_driver.points_for_rank_up - 1)
            inicfg.save(ini, "JobStats.ini")
            if bus_driver_session then
                bus_driver_session_stats.extra_skill_points_earned = bus_driver_session_stats.extra_skill_points_earned + 1
            end
        end
        if isGarbageMan then
            ini.garbage_man.extra_skill_points_earned = ini.garbage_man.extra_skill_points_earned + 1
            ini.garbage_man.points_for_rank_up = math.max(0, ini.garbage_man.points_for_rank_up - 1)
            inicfg.save(ini, "JobStats.ini")
            if garbage_man_session then
                garbage_man_session_stats.extra_skill_points_earned = garbage_man_session_stats.extra_skill_points_earned + 1
            end
        end
        if isFarmer then
            ini.farmer.extra_skill_points_earned = ini.farmer.extra_skill_points_earned + 1
            ini.farmer.points_for_rank_up = math.max(0, ini.farmer.points_for_rank_up - 1)
            inicfg.save(ini, "JobStats.ini")
            if farmer_session then
                farmer_session_stats.extra_skill_points_earned = farmer_session_stats.extra_skill_points_earned + 1
            end
        end
        if isBoatTransporter then
            ini.boat_transporter.extra_skill_points_earned = ini.boat_transporter.extra_skill_points_earned + 1
            ini.boat_transporter.points_for_rank_up = math.max(0, ini.boat_transporter.points_for_rank_up - 1)
            inicfg.save(ini, "JobStats.ini")
            if boat_transporter_session then
                boat_transporter_session_stats.extra_skill_points_earned = boat_transporter_session_stats.extra_skill_points_earned + 1
            end
        end
        if isDeliveryDriver then
            ini.delivery_driver.extra_skill_points_earned = ini.delivery_driver.extra_skill_points_earned + 1
            ini.delivery_driver.points_for_rank_up = math.max(0, ini.delivery_driver.points_for_rank_up - 1)
            inicfg.save(ini, "JobStats.ini")
            if delivery_driver_session then
                delivery_driver_session_stats.extra_skill_points_earned = delivery_driver_session_stats.extra_skill_points_earned + 1
            end
        end
        if isTowTrucker then
            ini.tow_trucker.extra_skill_points_earned = ini.tow_trucker.extra_skill_points_earned + 1
            ini.tow_trucker.points_for_rank_up = math.max(0, ini.tow_trucker.points_for_rank_up - 1)
            inicfg.save(ini, "JobStats.ini")
            if tow_trucker_session then
                tow_trucker_session_stats.extra_skill_points_earned = tow_trucker_session_stats.extra_skill_points_earned + 1
            end
        end
    end

    local materials, skill_bonus = text:match("^Ai colectat ([%d,]+) materiale%s+%(([%d,]+) skill bonus%)%.$")
    if materials and skill_bonus then
        materials = materials:gsub(",", "")
        skill_bonus = skill_bonus:gsub(",", "")
        materials = tonumber(materials)
        skill_bonus = tonumber(skill_bonus)

        if materials and skill_bonus then
            local base_money = materials - skill_bonus

            if isArmsDealer then
                ini.arms_dealer.materials_earned = (ini.arms_dealer.materials_earned or 0) + materials
                ini.arms_dealer.shifts = (ini.arms_dealer.shifts or 0) + 1
                ini.arms_dealer.points_for_rank_up = ini.arms_dealer.points_for_rank_up - 1
                ini.arms_dealer.extra_materials_from_skill = (ini.arms_dealer.extra_materials_from_skill or 0) + skill_bonus
                ini.arms_dealer.total_materials_earned = (ini.arms_dealer.total_materials_earned or 0) + materials
                inicfg.save(ini, "JobStats.ini")

                if arms_dealer_session then
                    arms_dealer_session_stats.materials_earned = (arms_dealer_session_stats.materials_earned or 0) + materials
                    arms_dealer_session_stats.shifts = (arms_dealer_session_stats.shifts or 0) + 1
                    arms_dealer_session_stats.extra_materials_from_skill = (arms_dealer_session_stats.extra_materials_from_skill or 0) + skill_bonus
                    arms_dealer_session_stats.total_materials_earned = (arms_dealer_session_stats.total_materials_earned or 0) + materials
                end
            end
        end
    end

    local fish_sold = text:match("^Ai vandut pestele pentru %$([%d,]+)%.$")
    if fish_sold then
        fish_sold = fish_sold:gsub(",", "")
        fish_sold = tonumber(fish_sold)

        if fish_sold then
            ini.fisherman.money_earned = (ini.fisherman.money_earned or 0) + fish_sold
            ini.fisherman.fish_caught = (ini.fisherman.fish_caught or 0) + 1
            ini.fisherman.points_for_rank_up = ini.fisherman.points_for_rank_up - 1
            ini.fisherman.total_money_earned = (ini.fisherman.total_money_earned or 0) + fish_sold
            inicfg.save(ini, "JobStats.ini")

            if fisherman_session then
                fisherman_session_stats.money_earned = (fisherman_session_stats.money_earned or 0) + fish_sold
                fisherman_session_stats.fish_caught = (fisherman_session_stats.fish_caught or 0) + 1
                fisherman_session_stats.total_money_earned = (fisherman_session_stats.total_money_earned or 0) + fish_sold
            end
        end
    end

    local total_earned, skill_bonus = text:match("^Pizza livrata! Ai castigat ([%d,]+)%$ %(([%d,]+)%$ skill bonus%)%.$")
    if total_earned and skill_bonus then
        total_earned = total_earned:gsub(",", "")
        skill_bonus = skill_bonus:gsub(",", "")
        total_earned = tonumber(total_earned)
        skill_bonus = tonumber(skill_bonus)

        if total_earned and skill_bonus then
            local base_money = total_earned - skill_bonus

            if isPizzaBoy then
                ini.pizza_boy.money_earned = (ini.pizza_boy.money_earned or 0) + base_money
                ini.pizza_boy.pizzas_delivered = (ini.pizza_boy.pizzas_delivered or 0) + 1
                ini.pizza_boy.points_for_rank_up = ini.pizza_boy.points_for_rank_up - 1
                ini.pizza_boy.extra_money_from_skill = (ini.pizza_boy.extra_money_from_skill or 0) + skill_bonus
                ini.pizza_boy.total_money_earned = (ini.pizza_boy.total_money_earned or 0) + total_earned
                inicfg.save(ini, "JobStats.ini")

                if pizza_boy_session then
                    pizza_boy_session_stats.money_earned = (pizza_boy_session_stats.money_earned or 0) + base_money
                    pizza_boy_session_stats.pizzas_delivered = (pizza_boy_session_stats.pizzas_delivered or 0) + 1
                    pizza_boy_session_stats.extra_money_from_skill = (pizza_boy_session_stats.extra_money_from_skill or 0) + skill_bonus
                    pizza_boy_session_stats.total_money_earned = (pizza_boy_session_stats.total_money_earned or 0) + total_earned
                end
            end
        end
    end

    local total_earned, skill_bonus = text:match("^.*Ai primit %$([%d,]+) %(([%d,]+)%$ bonus pt skill%) pentru livrarea marfii%.$")
    if total_earned and skill_bonus then
        total_earned = total_earned:gsub(",", "")
        skill_bonus = skill_bonus:gsub(",", "")
        total_earned = tonumber(total_earned)
        skill_bonus = tonumber(skill_bonus)

        if total_earned and skill_bonus then
            local base_money = total_earned - skill_bonus

            if isTrucker then
                ini.trucker.money_earned = (ini.trucker.money_earned or 0) + base_money
                ini.trucker.trailers_delivered = (ini.trucker.trailers_delivered or 0) + 1
                ini.trucker.points_for_rank_up = ini.trucker.points_for_rank_up - 1
                ini.trucker.extra_money_from_skill = (ini.trucker.extra_money_from_skill or 0) + skill_bonus
                ini.trucker.total_money_earned = (ini.trucker.total_money_earned or 0) + total_earned
                inicfg.save(ini, "JobStats.ini")

                if trucker_session then
                    trucker_session_stats.money_earned = (trucker_session_stats.money_earned or 0) + base_money
                    trucker_session_stats.trailers_delivered = (trucker_session_stats.trailers_delivered or 0) + 1
                    trucker_session_stats.extra_money_from_skill = (trucker_session_stats.extra_money_from_skill or 0) + skill_bonus
                    trucker_session_stats.total_money_earned = (trucker_session_stats.total_money_earned or 0) + total_earned
                end
            end
        end
    end

    local total_earned, skill_bonus = text:match("^.*Ai primit ([%d,]+)%$ %(([%d,]+)%$ bonus pt skill%) pentru %d+ kg de gunoi%.$")
    if total_earned and skill_bonus then
        total_earned = total_earned:gsub(",", "")
        skill_bonus = skill_bonus:gsub(",", "")
        total_earned = tonumber(total_earned)
        skill_bonus = tonumber(skill_bonus)

        if total_earned and skill_bonus then
            local base_money = total_earned - skill_bonus

            if isGarbageMan then
                ini.garbage_man.money_earned = (ini.garbage_man.money_earned or 0) + base_money
                ini.garbage_man.shifts = (ini.garbage_man.shifts or 0) + 1
                ini.garbage_man.points_for_rank_up = ini.garbage_man.points_for_rank_up - 1
                ini.garbage_man.extra_money_from_skill = (ini.garbage_man.extra_money_from_skill or 0) + skill_bonus
                ini.garbage_man.total_money_earned = (ini.garbage_man.total_money_earned or 0) + total_earned
                inicfg.save(ini, "JobStats.ini")

                if garbage_man_session then
                    garbage_man_session_stats.money_earned = (garbage_man_session_stats.money_earned or 0) + base_money
                    garbage_man_session_stats.shifts = (garbage_man_session_stats.shifts or 0) + 1
                    garbage_man_session_stats.extra_money_from_skill = (garbage_man_session_stats.extra_money_from_skill or 0) + skill_bonus
                    garbage_man_session_stats.total_money_earned = (garbage_man_session_stats.total_money_earned or 0) + total_earned
                end
            end
        end
    end
    local total_kg, bonus_kg = text:match("^Ai primit un sac ce contine (%d+) kg de faina %((%d+)kg bonus pentru skill%)%s*%.")

    if total_kg and bonus_kg then
        last_total_kg = tonumber(total_kg) or 0
        last_bonus_kg = tonumber(bonus_kg) or 0
    end

    local flour_sold = text:match("^.*Ai vandut un sac de faina pentru %$([%d,]+)%.$")
    if flour_sold then
        flour_sold = flour_sold:gsub(",", "")
        flour_sold = tonumber(flour_sold)
        if flour_sold then
            local bonus_money = last_bonus_kg * 1003
            local base_money = flour_sold - bonus_money
            ini.farmer.money_earned = (ini.farmer.money_earned or 0) + base_money
            ini.farmer.flour_sold = (ini.farmer.flour_sold or 0) + 1
            ini.farmer.points_for_rank_up = ini.farmer.points_for_rank_up - 1
            ini.farmer.extra_money_from_skill = (ini.farmer.extra_money_from_skill or 0) + bonus_money
            ini.farmer.total_money_earned = (ini.farmer.total_money_earned or 0) + flour_sold
            inicfg.save(ini, "JobStats.ini")

            if farmer_session then
                farmer_session_stats.money_earned = (farmer_session_stats.money_earned or 0) + base_money
                farmer_session_stats.flour_sold = (farmer_session_stats.flour_sold or 0) + 1
                farmer_session_stats.extra_money_from_skill = (farmer_session_stats.extra_money_from_skill or 0) + bonus_money
                farmer_session_stats.total_money_earned = (farmer_session_stats.total_money_earned or 0) + flour_sold
            end
        end
    end

    local flour_sold = text:match("^Detinatorii fermei au fost foarte multumiti de calitatea muncii prestate. Ai primit %$([%d,]+)%.$")
    if flour_sold then
        flour_sold = flour_sold:gsub(",", "")
        flour_sold = tonumber(flour_sold)
        if flour_sold then
            ini.farmer.money_earned = (ini.farmer.money_earned or 0) + flour_sold
            ini.farmer.flour_sold = (ini.farmer.flour_sold or 0) + 1
            ini.farmer.points_for_rank_up = ini.farmer.points_for_rank_up - 1
            ini.farmer.total_money_earned = (ini.farmer.total_money_earned or 0) + flour_sold
            inicfg.save(ini, "JobStats.ini")

            if farmer_session then
                farmer_session_stats.money_earned = (farmer_session_stats.money_earned or 0) + flour_sold
                farmer_session_stats.flour_sold = (farmer_session_stats.flour_sold or 0) + 1
                farmer_session_stats.total_money_earned = (farmer_session_stats.total_money_earned or 0) + flour_sold
            end
        end
    end

    local total_earned, skill_bonus = text:match("^Ai primit ([%d,]+)%$ %(([%d,]+)%$ bonus pt skill%)%. Mergi la urmatorul checkpoint%.$")
    if total_earned and skill_bonus then
        total_earned = total_earned:gsub(",", "")
        skill_bonus = skill_bonus:gsub(",", "")
        total_earned = tonumber(total_earned)
        skill_bonus = tonumber(skill_bonus)
        if total_earned and skill_bonus then
            local base_money = total_earned - skill_bonus

            if isBusDriver then
                ini.bus_driver.money_earned = (ini.bus_driver.money_earned or 0) + base_money
                bus_stops_for_current_shift = bus_stops_for_current_shift + 1
                bus_stops_for_current_shift_session = bus_stops_for_current_shift
                if bus_stops_for_current_shift == 10 then
                    bus_stops_for_current_shift = 0
                    ini.bus_driver.bus_stops = (ini.bus_driver.bus_stops or 0) + 1
                    ini.bus_driver.points_for_rank_up = ini.bus_driver.points_for_rank_up - 1
                end
                ini.bus_driver.extra_money_from_skill = (ini.bus_driver.extra_money_from_skill or 0) + skill_bonus
                ini.bus_driver.total_money_earned = (ini.bus_driver.total_money_earned or 0) + total_earned
                inicfg.save(ini, "JobStats.ini")

                if bus_driver_session then
                    bus_driver_session_stats.money_earned = (bus_driver_session_stats.money_earned or 0) + base_money
                    if bus_stops_for_current_shift_session == 10 then
                        bus_driver_session_stats.bus_stops = (bus_driver_session_stats.bus_stops or 0) + 1
                        bus_stops_for_current_shift_session = 0
                    end
                    bus_driver_session_stats.extra_money_from_skill = (bus_driver_session_stats.extra_money_from_skill or 0) + skill_bonus
                    bus_driver_session_stats.total_money_earned = (bus_driver_session_stats.total_money_earned or 0) + total_earned
                end
                sampAddChatMessage(string.format(
                    "Bus stops: %d | Bus stops session: %d",
                    bus_stops_for_current_shift,
                    bus_stops_for_current_shift_session
                ), 0xFFFFFFFF)
            end
        end
    end

    local total_earned, skill_bonus = text:match("^Marfa livrata! Ai castigat ([%d,]+)%$ %(([%d,]+)%$ bonus pentru skill%)%.$")
    if total_earned and skill_bonus then
        total_earned = total_earned:gsub(",", "")
        skill_bonus = skill_bonus:gsub(",", "")
        total_earned = tonumber(total_earned)
        skill_bonus = tonumber(skill_bonus)

        if total_earned and skill_bonus then
            local base_money = total_earned - skill_bonus

            if isBoatTransporter then
                ini.boat_transporter.money_earned = (ini.boat_transporter.money_earned or 0) + base_money
                ini.boat_transporter.shifts = (ini.boat_transporter.shifts or 0) + 1
                ini.boat_transporter.points_for_rank_up = ini.boat_transporter.points_for_rank_up - 1
                ini.boat_transporter.extra_money_from_skill = (ini.boat_transporter.extra_money_from_skill or 0) + skill_bonus
                ini.boat_transporter.total_money_earned = (ini.boat_transporter.total_money_earned or 0) + total_earned
                inicfg.save(ini, "JobStats.ini")

                if boat_transporter_session then
                    boat_transporter_session_stats.money_earned = (boat_transporter_session_stats.money_earned or 0) + base_money
                    boat_transporter_session_stats.shifts = (boat_transporter_session_stats.shifts or 0) + 1
                    boat_transporter_session_stats.extra_money_from_skill = (boat_transporter_session_stats.extra_money_from_skill or 0) + skill_bonus
                    boat_transporter_session_stats.total_money_earned = (boat_transporter_session_stats.total_money_earned or 0) + total_earned
                end
            end
        end
    end
    
    local total_earned = text:match("^.*Pachet livrat%. Ai primit ([%d,]+)%$%.$") or text:match("^.*You have received a bonus of %$([%d,]+) for delivering all the packages%.")
    if total_earned then
        total_earned = total_earned:gsub(",", "")
        total_earned = tonumber(total_earned)

        if total_earned then

            if isDeliveryDriver then
                ini.delivery_driver.money_earned = (ini.delivery_driver.money_earned or 0) + total_earned
                ini.delivery_driver.deliveries_made = (ini.delivery_driver.deliveries_made or 0) + 1
                ini.delivery_driver.points_for_rank_up = ini.delivery_driver.points_for_rank_up - 1
                ini.delivery_driver.total_money_earned = (ini.delivery_driver.total_money_earned or 0) + total_earned
                inicfg.save(ini, "JobStats.ini")

                if delivery_driver_session then
                    delivery_driver_session_stats.money_earned = (delivery_driver_session_stats.money_earned or 0) + total_earned
                    delivery_driver_session_stats.deliveries_made = (delivery_driver_session_stats.deliveries_made or 0) + 1
                    delivery_driver_session_stats.total_money_earned = (delivery_driver_session_stats.total_money_earned or 0) + total_earned
                end
            end
        end
    end

    local bonus = text:match("^.*You have received a bonus of %$([%d,]+) for delivering all the packages%.")
    if bonus then
        bonus = bonus:gsub(",", "")
        bonus = tonumber(bonus)

        if bonus then

            if isDeliveryDriver then
                ini.delivery_driver.money_earned = (ini.delivery_driver.money_earned or 0) + bonus
                ini.delivery_driver.total_money_earned = (ini.delivery_driver.total_money_earned or 0) + bonus
                inicfg.save(ini, "JobStats.ini")

                if delivery_driver_session then
                    delivery_driver_session_stats.money_earned = (delivery_driver_session_stats.money_earned or 0) + bonus
                    delivery_driver_session_stats.total_money_earned = (delivery_driver_session_stats.total_money_earned or 0) + bonus
                end
            end
        end
    end

    local total_earned, skill_bonus = text:match("^Vehicul ridicat! Ai castigat ([%d,]+)%$ %(([%d,]+)%$ skill bonus%)%.$")
    if total_earned and skill_bonus then
        total_earned = total_earned:gsub(",", "")
        skill_bonus = skill_bonus:gsub(",", "")
        total_earned = tonumber(total_earned)
        skill_bonus = tonumber(skill_bonus)

        if total_earned and skill_bonus then
            local base_money = total_earned - skill_bonus

            if isTowTrucker then
                ini.tow_trucker.money_earned = (ini.tow_trucker.money_earned or 0) + base_money
                ini.tow_trucker.cars_trucked = (ini.tow_trucker.cars_trucked or 0) + 1
                ini.tow_trucker.points_for_rank_up = ini.tow_trucker.points_for_rank_up - 1
                ini.tow_trucker.extra_money_from_skill = (ini.tow_trucker.extra_money_from_skill or 0) + skill_bonus
                ini.tow_trucker.total_money_earned = (ini.tow_trucker.total_money_earned or 0) + total_earned
                inicfg.save(ini, "JobStats.ini")

                if tow_trucker_session then
                    tow_trucker_session_stats.money_earned = (tow_trucker_session_stats.money_earned or 0) + base_money
                    tow_trucker_session_stats.cars_trucked = (tow_trucker_session_stats.cars_trucked or 0) + 1
                    tow_trucker_session_stats.extra_money_from_skill = (tow_trucker_session_stats.extra_money_from_skill or 0) + skill_bonus
                    tow_trucker_session_stats.total_money_earned = (tow_trucker_session_stats.total_money_earned or 0) + total_earned
                end
            end
        end
    end


    local pet_bonus = text:match("^PET BONUS: Ai castigat (%d+)%$ extra pentru acest job.")
    if pet_bonus then
        if isFisherman then
            pet_bonus = tonumber(pet_bonus)
            ini.fisherman.money_from_pet = ini.fisherman.money_from_pet + pet_bonus
            ini.fisherman.total_money_earned = ini.fisherman.total_money_earned + pet_bonus
            inicfg.save(ini, "JobStats.ini")
            if fisherman_session then
                fisherman_session_stats.money_from_pet = fisherman_session_stats.money_from_pet + pet_bonus
                fisherman_session_stats.total_money_earned = fisherman_session_stats.total_money_earned + pet_bonus     
            end
        end
        if isPizzaBoy then
            pet_bonus = tonumber(pet_bonus)
            ini.pizza_boy.money_from_pet = ini.pizza_boy.money_from_pet + pet_bonus
            ini.pizza_boy.total_money_earned = ini.pizza_boy.total_money_earned + pet_bonus
            inicfg.save(ini, "JobStats.ini")
            if pizza_boy_session then
                pizza_boy_session_stats.money_from_pet = pizza_boy_session_stats.money_from_pet + pet_bonus
                pizza_boy_session_stats.total_money_earned = pizza_boy_session_stats.total_money_earned + pet_bonus     
            end
        end
        if isTrucker then
            pet_bonus = tonumber(pet_bonus)
            ini.trucker.money_from_pet = ini.trucker.money_from_pet + pet_bonus
            ini.trucker.total_money_earned = ini.trucker.total_money_earned + pet_bonus
            inicfg.save(ini, "JobStats.ini")
            if trucker_session then
                trucker_session_stats.money_from_pet = trucker_session_stats.money_from_pet + pet_bonus
                trucker_session_stats.total_money_earned = trucker_session_stats.total_money_earned + pet_bonus     
            end
        end
        if isGarbageMan then
            pet_bonus = tonumber(pet_bonus)
            ini.garbage_man.money_from_pet = ini.garbage_man.money_from_pet + pet_bonus
            ini.garbage_man.total_money_earned = ini.garbage_man.total_money_earned + pet_bonus
            inicfg.save(ini, "JobStats.ini")
            if garbage_man_session then
                garbage_man_session_stats.money_from_pet = garbage_man_session_stats.money_from_pet + pet_bonus
                garbage_man_session_stats.total_money_earned = garbage_man_session_stats.total_money_earned + pet_bonus     
            end
        end
        if isFarmer then
            pet_bonus = tonumber(pet_bonus)
            ini.farmer.money_from_pet = ini.farmer.money_from_pet + pet_bonus
            ini.farmer.total_money_earned = ini.farmer.total_money_earned + pet_bonus
            inicfg.save(ini, "JobStats.ini")
            if farmer_session then
                farmer_session_stats.money_from_pet = farmer_session_stats.money_from_pet + pet_bonus
                farmer_session_stats.total_money_earned = farmer_session_stats.total_money_earned + pet_bonus     
            end
        end
        if isBoatTransporter then
            pet_bonus = tonumber(pet_bonus)
            ini.boat_transporter.money_from_pet = ini.boat_transporter.money_from_pet + pet_bonus
            ini.boat_transporter.total_money_earned = ini.boat_transporter.total_money_earned + pet_bonus
            inicfg.save(ini, "JobStats.ini")
            if boat_transporter_session then
                boat_transporter_session_stats.money_from_pet = boat_transporter_session_stats.money_from_pet + pet_bonus
                boat_transporter_session_stats.total_money_earned = boat_transporter_session_stats.total_money_earned + pet_bonus     
            end
        end
        if isTowTrucker then
            pet_bonus = tonumber(pet_bonus)
            ini.tow_trucker.money_from_pet = ini.tow_trucker.money_from_pet + pet_bonus
            ini.tow_trucker.total_money_earned = ini.tow_trucker.total_money_earned + pet_bonus
            inicfg.save(ini, "JobStats.ini")
            if tow_trucker_session then
                tow_trucker_session_stats.money_from_pet = tow_trucker_session_stats.money_from_pet + pet_bonus
                tow_trucker_session_stats.total_money_earned = tow_trucker_session_stats.total_money_earned + pet_bonus     
            end
        end
    end


    if text:find("Poti livra pizza aici. Uita-te in stanga/dreapta (Q/E) si apasa CLICK pentru a arunca pizza.", 1, true) then
        lua_thread.create(function()
            setVirtualKeyDown(VK_Q, true)
            setVirtualKeyDown(VK_LBUTTON, true)
            wait(80)
            setVirtualKeyDown(VK_LBUTTON, false)
            setVirtualKeyDown(VK_Q, false)

        end)
    end

end

function clearSessionsJobs()
    if arms_dealer_session and arms_dealer_session_start then
        local elapsed = os.time() - arms_dealer_session_start
        ini.arms_dealer.total_time_spent_working = (ini.arms_dealer.total_time_spent_working or 0) + elapsed
        ini.arms_dealer.average_materials_per_hour =
            (ini.arms_dealer.total_materials_earned or 0) / math.max(1, (ini.arms_dealer.total_time_spent_working or 0) / 3600)
        inicfg.save(ini, "JobStats.ini")

        arms_dealer_session = false
        arms_dealer_session_start = nil
        arms_dealer_session_stats = {
            session_time = 0,
            shifts = 0,
            materials_earned = 0,
            materials_from_skins = 0,
            extra_materials_from_skill = 0,
            total_materials_earned = 0,
            extra_skill_points_earned = 0,
            bad_luck = 0,
            average_skill_point_per_shift = 0
        }
    end
    if fisherman_session and fisherman_session_start then
        local elapsed = os.time() - fisherman_session_start
        ini.fisherman.total_time_spent_working = (ini.fisherman.total_time_spent_working or 0) + elapsed
        ini.fisherman.money_earned_during_sessions = (ini.fisherman.money_earned_during_sessions or 0) + fisherman_session_stats.total_money_earned
        ini.fisherman.average_money_per_hour =
            (ini.fisherman.money_earned_during_sessions or 0) / math.max(1, (ini.fisherman.total_time_spent_working or 0) / 3600)
        inicfg.save(ini, "JobStats.ini")

        fisherman_session = false
        fisherman_session_start = nil
        fisherman_session_stats = {
            session_time = 0,
            fish_caught = 0,
            money_earned = 0,
            money_from_pet = 0,
            money_from_skins = 0,
            total_money_earned = 0,
            extra_skill_points_earned = 0,
            bad_luck = 0,
            average_skill_point_per_fish_caught = 0
        }
    end
    if pizza_boy_session and pizza_boy_session_start then
        local elapsed = os.time() - pizza_boy_session_start
        ini.pizza_boy.total_time_spent_working = (ini.pizza_boy.total_time_spent_working or 0) + elapsed
        ini.pizza_boy.money_earned_during_sessions = (ini.pizza_boy.money_earned_during_sessions or 0) + pizza_boy_session_stats.total_money_earned
        ini.pizza_boy.average_money_per_hour =
            (ini.pizza_boy.money_earned_during_sessions or 0) / math.max(1, (ini.pizza_boy.total_time_spent_working or 0) / 3600)
        inicfg.save(ini, "JobStats.ini")

        pizza_boy_session = false
        pizza_boy_session_start = nil
        pizza_boy_session_stats = {
            session_time = 0,
            pizzas_delivered = 0,
            money_earned = 0,
            money_from_pet = 0,
            money_from_skins = 0,
            extra_money_from_skill = 0,
            total_money_earned = 0,
            extra_skill_points_earned = 0,
            bad_luck = 0,
            average_skill_point_per_pizza_delivered = 0
        }
    end
    if trucker_session and trucker_session_start then
        local elapsed = os.time() - trucker_session_start
        ini.trucker.total_time_spent_working = (ini.trucker.total_time_spent_working or 0) + elapsed
        ini.trucker.money_earned_during_sessions = (ini.trucker.money_earned_during_sessions or 0) + trucker_session_stats.total_money_earned
        ini.trucker.average_money_per_hour =
            (ini.trucker.money_earned_during_sessions or 0) / math.max(1, (ini.trucker.total_time_spent_working or 0) / 3600)
        inicfg.save(ini, "JobStats.ini")

        trucker_session = false
        trucker_session_start = nil
        trucker_session_stats = {
            session_time = 0,
            trailers_delivered = 0,
            money_earned = 0,
            money_from_pet = 0,
            money_from_skins = 0,
            extra_money_from_skill = 0,
            total_money_earned = 0,
            extra_skill_points_earned = 0,
            bad_luck = 0,
            average_skill_point_per_trailer_delivered = 0
        }
    end
    if bus_driver_session and bus_driver_session_start then
        local elapsed = os.time() - bus_driver_session_start
        ini.bus_driver.total_time_spent_working = (ini.bus_driver.total_time_spent_working or 0) + elapsed
        ini.bus_driver.money_earned_during_sessions = (ini.bus_driver.money_earned_during_sessions or 0) + bus_driver_session_stats.total_money_earned
        ini.bus_driver.average_money_per_hour =
            (ini.bus_driver.money_earned_during_sessions or 0) / math.max(1, (ini.bus_driver.total_time_spent_working or 0) / 3600)
        inicfg.save(ini, "JobStats.ini")

        bus_stops_for_current_shift_session = 0
        bus_driver_session = false
        bus_driver_session_start = nil
        bus_driver_session_stats = {
            session_time = 0,
            bus_stops = 0,
            money_earned = 0,
            money_from_skins = 0,
            extra_money_from_skill = 0,
            total_money_earned = 0,
            extra_skill_points_earned = 0,
            bad_luck = 0,
            average_skill_point_per_bus_stop = 0
        }
    end
    if garbage_man_session and garbage_man_session_start then
        local elapsed = os.time() - garbage_man_session_start
        ini.garbage_man.total_time_spent_working = (ini.garbage_man.total_time_spent_working or 0) + elapsed
        ini.garbage_man.money_earned_during_sessions = (ini.garbage_man.money_earned_during_sessions or 0) + garbage_man_session_stats.total_money_earned
        ini.garbage_man.average_money_per_hour =
            (ini.garbage_man.money_earned_during_sessions or 0) / math.max(1, (ini.garbage_man.total_time_spent_working or 0) / 3600)
        inicfg.save(ini, "JobStats.ini")

        garbage_man_session = false
        garbage_man_session_start = nil
        garbage_man_session_stats = {
            session_time = 0,
            shifts = 0,
            money_earned = 0,
            money_from_pet = 0,
            money_from_skins = 0,
            extra_money_from_skill = 0,
            total_money_earned = 0,
            extra_skill_points_earned = 0,
            bad_luck = 0,
            average_skill_point_per_shift = 0
        }
    end
    if farmer_session and farmer_session_start then
        local elapsed = os.time() - farmer_session_start
        ini.farmer.total_time_spent_working = (ini.farmer.total_time_spent_working or 0) + elapsed
        ini.farmer.money_earned_during_sessions = (ini.farmer.money_earned_during_sessions or 0) + farmer_session_stats.total_money_earned
        ini.farmer.average_money_per_hour =
            (ini.farmer.money_earned_during_sessions or 0) / math.max(1, (ini.farmer.total_time_spent_working or 0) / 3600)
        inicfg.save(ini, "JobStats.ini")

        farmer_session = false
        farmer_session_start = nil
        farmer_session_stats = {
            session_time = 0,
            flour_sold = 0,
            money_earned = 0,
            money_from_pet = 0,
            money_from_skins = 0,
            extra_money_from_skill = 0,
            total_money_earned = 0,
            extra_skill_points_earned = 0,
            bad_luck = 0,
            average_skill_point_per_flour_sold = 0
        }
    end
    if boat_transporter_session and boat_transporter_session_start then
        local elapsed = os.time() - boat_transporter_session_start
        ini.boat_transporter.total_time_spent_working = (ini.boat_transporter.total_time_spent_working or 0) + elapsed
        ini.boat_transporter.money_earned_during_sessions = (ini.boat_transporter.money_earned_during_sessions or 0) + boat_transporter_session_stats.total_money_earned
        ini.boat_transporter.average_money_per_hour =
            (ini.boat_transporter.money_earned_during_sessions or 0) / math.max(1, (ini.boat_transporter.total_time_spent_working or 0) / 3600)
        inicfg.save(ini, "JobStats.ini")

        boat_transporter_session = false
        boat_transporter_session_start = nil
        boat_transporter_session_stats = {
            session_time = 0,
            trips = 0,
            money_earned = 0,
            money_from_pet = 0,
            money_from_skins = 0,
            extra_money_from_skill = 0,
            total_money_earned = 0,
            extra_skill_points_earned = 0,
            bad_luck = 0,
            average_skill_point_per_trip = 0
        }
    end
    if delivery_driver_session and delivery_driver_session_start then
        local elapsed = os.time() - delivery_driver_session_start
        ini.delivery_driver.total_time_spent_working = (ini.delivery_driver.total_time_spent_working or 0) + elapsed
        ini.delivery_driver.money_earned_during_sessions = (ini.delivery_driver.money_earned_during_sessions or 0) + delivery_driver_session_stats.total_money_earned
        ini.delivery_driver.average_money_per_hour =
            (ini.delivery_driver.money_earned_during_sessions or 0) / math.max(1, (ini.delivery_driver.total_time_spent_working or 0) / 3600)
        inicfg.save(ini, "JobStats.ini")

        delivery_driver_session = false
        delivery_driver_session_start = nil
        delivery_driver_session_stats = {
            session_time = 0,
            deliveries_made = 0,
            money_earned = 0,
            money_from_skins = 0,
            total_money_earned = 0,
            extra_skill_points_earned = 0,
            bad_luck = 0,
            average_skill_point_per_delivery_made = 0
        }
    end
    if tow_trucker_session and tow_trucker_session_start then
        local elapsed = os.time() - tow_trucker_session_start
        ini.tow_trucker.total_time_spent_working = (ini.tow_trucker.total_time_spent_working or 0) + elapsed
        ini.tow_trucker.money_earned_during_sessions = (ini.tow_trucker.money_earned_during_sessions or 0) + tow_trucker_session_stats.total_money_earned
        ini.tow_trucker.average_money_per_hour =
            (ini.tow_trucker.money_earned_during_sessions or 0) / math.max(1, (ini.tow_trucker.total_time_spent_working or 0) / 3600)
        inicfg.save(ini, "JobStats.ini")

        tow_trucker_session = false
        tow_trucker_session_start = nil
        tow_trucker_session_stats = {
            session_time = 0,
            cars_trucked = 0,
            money_earned = 0,
            money_from_pet = 0,
            money_from_skins = 0,
            extra_money_from_skill = 0,
            total_money_earned = 0,
            extra_skill_points_earned = 0,
            bad_luck = 0,
            average_skill_point_per_cars_trucked = 0
        }
    end
end

local function totalJobStats()
    local money_earned = 0
    local money_from_pet = 0
    local money_from_skins = 0
    local extra_money_from_skill = 0
    local total_money_earned = 0
    local extra_skill_points_earned = 0
    local bad_luck = 0
    local total_time_spent_working = 0
    local average_money_per_hour = 0
    local total_shifts = 0


    local jobs = {
        "arms_dealer", "fisherman", "pizza_boy", "trucker", "bus_driver",
        "garbage_man", "farmer", "boat_transporter", "delivery_driver", "tow_trucker"
    }

    for _, key in ipairs(jobs) do
        local job = ini[key]
        if job then
            money_earned = money_earned + (job.money_earned or 0)
            money_from_pet = money_from_pet + (job.money_from_pet or 0)
            money_from_skins = money_from_skins + (job.money_from_skins or 0)
            extra_money_from_skill = extra_money_from_skill + (job.extra_money_from_skill or 0)
            total_money_earned = total_money_earned + (job.total_money_earned or 0)
            extra_skill_points_earned = extra_skill_points_earned + (job.extra_skill_points_earned or 0)
            bad_luck = bad_luck + (job.bad_luck or 0)
            total_time_spent_working = total_time_spent_working + (job.total_time_spent_working or 0)
            total_shifts = total_shifts + (job.fish_caught or 0) + (job.pizzas_delivered or 0) + (job.trailers_delivered or 0) + (job.bus_stops or 0) + (job.shifts or 0) + (job.flour_sold or 0) + (job.deliveries_made or 0) + (job.cars_trucked or 0)
        end
    end

    ini.total_job_stats.money_earned = money_earned
    ini.total_job_stats.money_from_pet = money_from_pet
    ini.total_job_stats.money_from_skins = money_from_skins
    ini.total_job_stats.extra_money_from_skill = extra_money_from_skill
    ini.total_job_stats.total_money_earned = total_money_earned
    ini.total_job_stats.extra_skill_points_earned = extra_skill_points_earned
    ini.total_job_stats.bad_luck = bad_luck
    ini.total_job_stats.total_time_spent_working = total_time_spent_working
    ini.total_job_stats.average_money_per_hour =
        (ini.total_job_stats.total_money_earned or 0) / math.max(1, (ini.total_job_stats.total_time_spent_working or 0) / 3600)
    ini.total_job_stats.total_shifts = total_shifts

    inicfg.save(ini, "JobStats.ini")
end

local function formatComma(n)
    n = tonumber(n) or 0
    local s = tostring(math.floor(n))
    local sign, int = s:match("^([%-]?)(%d+)$")
    int = int:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return sign .. int
end

local function getSkillColor(skillText)
    skillText = (skillText or ""):lower()

    if skillText:find("bronze", 1, true) then
        return COLOR_BRONZE
    elseif skillText:find("silver", 1, true) then
        return COLOR_SILVER
    elseif skillText:find("gold", 1, true) then
        return COLOR_GOLD
    elseif skillText:find("diamond", 1, true) then
        return COLOR_DIAMOND
    end

    return COLOR_SILVER
end

local settings = imgui.OnFrame(
    function()
        return main_window[0]
            or arms_dealer_window[0]
            or arms_dealer_session_window[0]
            or fisherman_window[0]
            or fisherman_session_window[0]
            or pizza_boy_window[0]
            or pizza_boy_session_window[0]
            or trucker_window[0]
            or trucker_session_window[0]
            or bus_driver_window[0]
            or bus_driver_session_window[0]
            or garbage_man_window[0]
            or garbage_man_session_window[0]
            or farmer_window[0]
            or farmer_session_window[0]
            or boat_transporter_window[0]
            or boat_transporter_session_window[0]
            or delivery_driver_window[0]
            or delivery_driver_session_window[0]
            or tow_trucker_window[0]
            or tow_trucker_session_window[0]
            or total_job_stats_window[0]
    end,
    function(self)
        self.HideCursor = not main_window[0]
        local sw, sh = getScreenResolution()
        imgui.SetNextWindowSize(imgui.ImVec2(150, 315), imgui.Cond.Always)
        imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))

        if main_window[0] then
            imgui.Begin(u8("Job Stats v1.0"), main_window)

            if imgui.Button(u8("Arms Dealer"), imgui.ImVec2(120, 0)) then
                arms_dealer_window[0] = true
            end

            if  imgui.Button(u8("Fisherman"), imgui.ImVec2(120, 0)) then
                fisherman_window[0] = true
            end

            if  imgui.Button(u8("Pizza Boy"), imgui.ImVec2(120, 0)) then 
                pizza_boy_window[0] = true
            end

            if  imgui.Button(u8("Trucker"), imgui.ImVec2(120, 0)) then 
                trucker_window[0] = true
            end

            if  imgui.Button(u8("Bus Driver"), imgui.ImVec2(120, 0)) then 
                bus_driver_window[0] = true
            end

            if  imgui.Button(u8("Garbage Man"), imgui.ImVec2(120, 0)) then
                garbage_man_window[0] = true
            end

            if  imgui.Button(u8("Farmer"), imgui.ImVec2(120, 0)) then
                farmer_window[0] = true
            end

            if  imgui.Button(u8("Boat Transporter"), imgui.ImVec2(120, 0)) then
                boat_transporter_window[0] = true
            end

            if  imgui.Button(u8("Delivery Driver"), imgui.ImVec2(120, 0)) then
                delivery_driver_window[0] = true
            end

            if  imgui.Button(u8("Tow Trucker"), imgui.ImVec2(120, 0)) then
                tow_trucker_window[0] = true
            end

            if  imgui.Button(u8("Total Job Stats"), imgui.ImVec2(120, 0)) then
                totalJobStats()
                total_job_stats_window[0] = true
            end

            imgui.Text(u8("/jobstats to toggle menu"))
            imgui.End()
        end
        
        -- Arms Dealer Window
        if arms_dealer_window[0] then
            imgui.SetNextWindowSize(imgui.ImVec2(400, 350), imgui.Cond.Always)
            imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.Begin(u8("Arms Dealer"), arms_dealer_window)
            local t = ini.arms_dealer.total_time_spent_working or 0
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            local s = math.floor(t % 60)

            local cleanSkill = (ini.arms_dealer.skill or ""):gsub("{%x%x%x%x%x%x}", "")
            local cleanInfo = (ini.arms_dealer.info or ""):gsub("{%x%x%x%x%x%x}", "")
            local skillColor = getSkillColor(cleanSkill)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 220)

            imgui.Text((string.format(u8("Skill:")))); imgui.NextColumn()
            imgui.TextColored(skillColor, u8(cleanSkill)); imgui.NextColumn()
            imgui.Text((string.format(u8("Points for rank up:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.arms_dealer.points_for_rank_up))); imgui.NextColumn()
            imgui.Text((string.format(u8("Info:")))); imgui.NextColumn()
            imgui.TextColored(INFOJOB_COLOR, u8(cleanInfo)); imgui.NextColumn()
            imgui.Text((string.format(u8("Shifts:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.arms_dealer.shifts))); imgui.NextColumn()
            imgui.Text((string.format(u8("Materials earned:")))); imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(0.847, 1, 0.8, 1.0), u8(formatComma(ini.arms_dealer.materials_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Materials earned from skins:")))); imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(0.847, 1, 0.8, 1.0), u8(formatComma(ini.arms_dealer.materials_from_skins))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra materials earned from skill:")))); imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(0.847, 1, 0.8, 1.0), u8(formatComma(ini.arms_dealer.extra_materials_from_skill))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total materials earned:")))); imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(0.847, 1, 0.8, 1.0), u8(formatComma(ini.arms_dealer.total_materials_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra skill point earned:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.arms_dealer.extra_skill_points_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Bad luck:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.arms_dealer.bad_luck))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average skill point per shift:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%.2f"), ini.arms_dealer.extra_skill_points_earned / ini.arms_dealer.shifts))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total time spent working:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%02d:%02d:%02d"), h, m, s))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average materials per hour:")))); imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(0.847, 1, 0.8, 1.0), u8(formatComma(ini.arms_dealer.average_materials_per_hour))); imgui.NextColumn()
            if imgui.Button(u8("Close"), imgui.ImVec2(120, 0)) then
                arms_dealer_window[0] = false
            end
            if imgui.Button(u8("Start session"), imgui.ImVec2(120, 0)) then                
                if arms_dealer_session_window[0] then return end
                arms_dealer_session_window[0] = true
                arms_dealer_session = true
                arms_dealer_session_stats.session_time = 0
                arms_dealer_session_start = os.time()
            end

            imgui.End()
        end

        if arms_dealer_session and arms_dealer_session_start then
            arms_dealer_session_stats.session_time = os.time() - arms_dealer_session_start
        end

        if arms_dealer_session_window[0] then
            local wasOpen = arms_dealer_session_window[0]
            imgui.SetNextWindowSize(imgui.ImVec2(400, 300), imgui.Cond.Always)
            imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            
            imgui.Begin(u8("Arms Dealer Session"), arms_dealer_session_window)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 220)
            local t = arms_dealer_session_stats.session_time or 0
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            local s = math.floor(t % 60)

            imgui.Text((string.format(u8("Session time:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%02d:%02d:%02d"), h, m, s))); imgui.NextColumn()
            imgui.Text((string.format(u8("Shifts:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), arms_dealer_session_stats.shifts))); imgui.NextColumn()
            imgui.Text((string.format(u8("Materials earned:")))); imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(0.847, 1, 0.8, 1.0), u8(formatComma(arms_dealer_session_stats.materials_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Materials earned from skins:")))); imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(0.847, 1, 0.8, 1.0), u8(formatComma(arms_dealer_session_stats.materials_from_skins))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra materials earned from skill:")))); imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(0.847, 1, 0.8, 1.0), u8(formatComma(arms_dealer_session_stats.extra_materials_from_skill))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total materials earned:")))); imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(0.847, 1, 0.8, 1.0), u8(formatComma(arms_dealer_session_stats.total_materials_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra skill point earned:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), arms_dealer_session_stats.extra_skill_points_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Bad luck:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), arms_dealer_session_stats.bad_luck))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average skill point per shift:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%.2f"), arms_dealer_session_stats.extra_skill_points_earned / arms_dealer_session_stats.shifts))); imgui.NextColumn()
            if imgui.Button(u8("End session"), imgui.ImVec2(120, 0)) then
                arms_dealer_session_window[0] = false
            end

            imgui.End()

            if wasOpen and not arms_dealer_session_window[0] then
                clearSessionsJobs()
            end
        end

        -- Fisherman Window
        if fisherman_window[0] then
            imgui.SetNextWindowSize(imgui.ImVec2(400, 350), imgui.Cond.Always)
            imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.Begin(u8("Fisherman"), fisherman_window)
            local t = ini.fisherman.total_time_spent_working or 0
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            local s = math.floor(t % 60)

            local cleanSkill = (ini.fisherman.skill or ""):gsub("{%x%x%x%x%x%x}", "")
            local cleanInfo = (ini.fisherman.info or ""):gsub("{%x%x%x%x%x%x}", "")
            local skillColor = getSkillColor(cleanSkill)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 220)

            imgui.Text((string.format(u8("Skill:")))); imgui.NextColumn()
            imgui.TextColored(skillColor, u8(cleanSkill)); imgui.NextColumn()
            imgui.Text((string.format(u8("Points for rank up:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.fisherman.points_for_rank_up))); imgui.NextColumn()
            imgui.Text((string.format(u8("Info:")))); imgui.NextColumn()
            imgui.TextColored(INFOJOB_COLOR, u8(cleanInfo)); imgui.NextColumn()
            imgui.Text((string.format(u8("Fish caught:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.fisherman.fish_caught))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.fisherman.money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from pet:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_YELLOW, u8("$" .. formatComma(ini.fisherman.money_from_pet))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.fisherman.total_money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra skill point earned:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.fisherman.extra_skill_points_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Bad luck:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.fisherman.bad_luck))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average skill point per fish caught:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%.2f"), ini.fisherman.extra_skill_points_earned / ini.fisherman.fish_caught))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total time spent working:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%02d:%02d:%02d"), h, m, s))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average money per hour:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.fisherman.average_money_per_hour))); imgui.NextColumn()
            if imgui.Button(u8("Close"), imgui.ImVec2(120, 0)) then
                fisherman_window[0] = false
            end
            if imgui.Button(u8("Start session"), imgui.ImVec2(120, 0)) then
                if fisherman_session_window[0] then return end
                fisherman_session_window[0] = true
                fisherman_session = true
                fisherman_session_stats.session_time = 0
                fisherman_session_start = os.time()
            end

            imgui.End()
        end

        if fisherman_session and fisherman_session_start then
            fisherman_session_stats.session_time = os.time() - fisherman_session_start
        end

        if fisherman_session_window[0] then
            local wasOpen = fisherman_session_window[0]
            imgui.SetNextWindowSize(imgui.ImVec2(400, 300), imgui.Cond.Always)
            imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            
            imgui.Begin(u8("Fisherman Session"), fisherman_session_window)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 220)
            local t = fisherman_session_stats.session_time or 0
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            local s = math.floor(t % 60)

            imgui.Text((string.format(u8("Session time:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%02d:%02d:%02d"), h, m, s))); imgui.NextColumn()
            imgui.Text((string.format(u8("Fish caught:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), fisherman_session_stats.fish_caught))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(fisherman_session_stats.money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from pet:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_YELLOW, u8("$" .. formatComma(fisherman_session_stats.money_from_pet))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(fisherman_session_stats.total_money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra skill point earned:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), fisherman_session_stats.extra_skill_points_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Bad luck:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), fisherman_session_stats.bad_luck))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average skill point per fish caught:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%.2f"), fisherman_session_stats.extra_skill_points_earned / fisherman_session_stats.fish_caught))); imgui.NextColumn()
            if imgui.Button(u8("End session"), imgui.ImVec2(120, 0)) then
                fisherman_session_window[0] = false
            end

            imgui.End()

            if wasOpen and not fisherman_session_window[0] then
                clearSessionsJobs()
            end
        end

        -- Pizza Window
        if pizza_boy_window[0] then
            imgui.SetNextWindowSize(imgui.ImVec2(400, 350), imgui.Cond.Always)
            imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.Begin(u8("Pizza Boy"), pizza_boy_window)
            local t = ini.pizza_boy.total_time_spent_working or 0
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            local s = math.floor(t % 60)

            local cleanSkill = (ini.pizza_boy.skill or ""):gsub("{%x%x%x%x%x%x}", "")
            local cleanInfo = (ini.pizza_boy.info or ""):gsub("{%x%x%x%x%x%x}", "")
            local skillColor = getSkillColor(cleanSkill)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 220)

            imgui.Text((string.format(u8("Skill:")))); imgui.NextColumn()
            imgui.TextColored(skillColor, u8(cleanSkill)); imgui.NextColumn()
            imgui.Text((string.format(u8("Points for rank up:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.pizza_boy.points_for_rank_up))); imgui.NextColumn()
            imgui.Text((string.format(u8("Info:")))); imgui.NextColumn()
            imgui.TextColored(INFOJOB_COLOR, u8(cleanInfo)); imgui.NextColumn()
            imgui.Text((string.format(u8("Pizzas delivered:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.pizza_boy.pizzas_delivered))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.pizza_boy.money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from pet:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_YELLOW, u8("$" .. formatComma(ini.pizza_boy.money_from_pet))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from skins:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.pizza_boy.money_earned_from_skins))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra money earned from skill:")))); imgui.NextColumn()          
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.pizza_boy.extra_money_from_skill))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.pizza_boy.total_money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra skill point earned:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.pizza_boy.extra_skill_points_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Bad luck:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.pizza_boy.bad_luck))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average skill point per pizza delivered:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%.2f"), ini.pizza_boy.extra_skill_points_earned / ini.pizza_boy.pizzas_delivered))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total time spent working:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%02d:%02d:%02d"), h, m, s))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average money per hour:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.pizza_boy.average_money_per_hour))); imgui.NextColumn()
            if imgui.Button(u8("Close"), imgui.ImVec2(120, 0)) then
                pizza_boy_window[0] = false
            end
            if imgui.Button(u8("Start session"), imgui.ImVec2(120, 0)) then
                if pizza_boy_window[0] then return end
                pizza_boy_window[0] = true
                pizza_boy_session = true
                pizza_boy_session_stats.session_time = 0
                pizza_boy_session_start = os.time()
            end

            imgui.End()
        end

        if pizza_boy_session and pizza_boy_session_start then
            pizza_boy_session_stats.session_time = os.time() - pizza_boy_session_start
        end

        if pizza_boy_session_window[0] then
            local wasOpen = pizza_boy_session_window[0]
            imgui.SetNextWindowSize(imgui.ImVec2(400, 300), imgui.Cond.Always)
            imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            
            imgui.Begin(u8("Pizza Boy Session"), pizza_boy_session_window)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 220)
            local t = pizza_boy_session_stats.session_time or 0
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            local s = math.floor(t % 60)
            
            imgui.Text((string.format(u8("Session time:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%02d:%02d:%02d"), h, m, s))); imgui.NextColumn()
            imgui.Text((string.format(u8("Pizzas delivered:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), pizza_boy_session_stats.pizzas_delivered))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(pizza_boy_session_stats.money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from pet:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_YELLOW, u8("$" .. formatComma(pizza_boy_session_stats.money_from_pet))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from skins:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(pizza_boy_session_stats.money_from_skins))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra money earned from skill:")))); imgui.NextColumn()          
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(pizza_boy_session_stats.extra_money_from_skill))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(pizza_boy_session_stats.total_money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra skill point earned:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), pizza_boy_session_stats.extra_skill_points_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Bad luck:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), pizza_boy_session_stats.bad_luck))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average skill point per pizza delivered:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%.2f"), pizza_boy_session_stats.extra_skill_points_earned / pizza_boy_session_stats.pizzas_delivered))); imgui.NextColumn()
            if imgui.Button(u8("End session"), imgui.ImVec2(120, 0)) then
                pizza_boy_session_window[0] = false
            end
            imgui.End()

            if wasOpen and not pizza_boy_session_window[0] then
                clearSessionsJobs()
            end
        end

        -- Trucker Window
        if trucker_window[0] then
            imgui.SetNextWindowSize(imgui.ImVec2(400, 350), imgui.Cond.Always)
            imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.Begin(u8("Trucker"), trucker_window)
            local t = ini.trucker.total_time_spent_working or 0
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            local s = math.floor(t % 60)

            local cleanSkill = (ini.trucker.skill or ""):gsub("{%x%x%x%x%x%x}", "")
            local cleanInfo = (ini.trucker.info or ""):gsub("{%x%x%x%x%x%x}", "")
            local skillColor = getSkillColor(cleanSkill)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 220)

            imgui.Text((string.format(u8("Skill:")))); imgui.NextColumn()
            imgui.TextColored(skillColor, u8(cleanSkill)); imgui.NextColumn()
            imgui.Text((string.format(u8("Points for rank up:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.trucker.points_for_rank_up))); imgui.NextColumn()
            imgui.Text((string.format(u8("Info:")))); imgui.NextColumn()
            imgui.TextColored(INFOJOB_COLOR, u8(cleanInfo)); imgui.NextColumn()
            imgui.Text((string.format(u8("Trailers delivered:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.trucker.trailers_delivered))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.trucker.money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from pet:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_YELLOW, u8("$" .. formatComma(ini.trucker.money_from_pet))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from skins:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.trucker.money_from_skins))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra money earned from skill:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.trucker.extra_money_from_skill))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.trucker.total_money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra skill point earned:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.trucker.extra_skill_points_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Bad luck:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.trucker.bad_luck))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average skill point per trailer delivered:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%.2f"), ini.trucker.extra_skill_points_earned / ini.trucker.trailers_delivered))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total time spent working:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%02d:%02d:%02d"), h, m, s))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average money per hour:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.trucker.average_money_per_hour))); imgui.NextColumn()
            if imgui.Button(u8("Close"), imgui.ImVec2(120, 0)) then
                trucker_window[0] = false
            end
            if imgui.Button(u8("Start session"), imgui.ImVec2(120, 0)) then
                if trucker_session_window[0] then return end
                trucker_session_window[0] = true
                trucker_session = true
                trucker_session_stats.session_time = 0
                trucker_session_start = os.time()
            end

            imgui.End()
        end

        if trucker_session and trucker_session_start then
            trucker_session_stats.session_time = os.time() - trucker_session_start
        end

        if trucker_session_window[0] then
            local wasOpen = trucker_session_window[0]
            imgui.SetNextWindowSize(imgui.ImVec2(400, 300), imgui.Cond.Always)
            imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            
            imgui.Begin(u8("Trucker Session"), trucker_session_window)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 220)
            local t = trucker_session_stats.session_time or 0
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            local s = math.floor(t % 60)
            
            imgui.Text((string.format(u8("Session time:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%02d:%02d:%02d"), h, m, s))); imgui.NextColumn()
            imgui.Text((string.format(u8("Trailers delivered:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), trucker_session_stats.trailers_delivered))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(trucker_session_stats.money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from pet:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_YELLOW, u8("$" .. formatComma(trucker_session_stats.money_from_pet))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from skins:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(trucker_session_stats.money_from_skins))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra money earned from skill:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(trucker_session_stats.extra_money_from_skill))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(trucker_session_stats.total_money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra skill point earned:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), trucker_session_stats.extra_skill_points_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Bad luck:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), trucker_session_stats.bad_luck)));	imgui.NextColumn()
            imgui.Text((string.format(u8("Average skill point per trailer delivered:"))));	imgui.NextColumn()
           	imgui.Text((string.format(u8("%.2f"), trucker_session_stats.extra_skill_points_earned / trucker_session_stats.trailers_delivered))); imgui.NextColumn()
            if imgui.Button(u8("End session"), imgui.ImVec2(120, 0)) then
                trucker_session_window[0] = false
            end
            imgui.End()

            if wasOpen and not trucker_session_window[0] then
                clearSessionsJobs()
            end
        end

        -- Bus Driver Window
        if bus_driver_window[0] then
            imgui.SetNextWindowSize(imgui.ImVec2(400, 350), imgui.Cond.Always)
            imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.Begin(u8("Bus Driver"), bus_driver_window)
            local t = ini.bus_driver.total_time_spent_working or 0
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            local s = math.floor(t % 60)

            local cleanSkill = (ini.bus_driver.skill or ""):gsub("{%x%x%x%x%x%x}", "")
            local cleanInfo = (ini.bus_driver.info or ""):gsub("{%x%x%x%x%x%x}", "")
            local skillColor = getSkillColor(cleanSkill)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 220)

            imgui.Text((string.format(u8("Skill:")))); imgui.NextColumn()
            imgui.TextColored(skillColor, u8(cleanSkill)); imgui.NextColumn()
            imgui.Text((string.format(u8("Points for rank up:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.bus_driver.points_for_rank_up))); imgui.NextColumn()
            imgui.Text((string.format(u8("Info:")))); imgui.NextColumn()
            imgui.TextColored(INFOJOB_COLOR, u8(cleanInfo)); imgui.NextColumn()
            imgui.Text((string.format(u8("Bus stops (x10):")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.bus_driver.bus_stops))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.bus_driver.money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from skins:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.bus_driver.money_from_skins))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra money earned from skill:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.bus_driver.extra_money_from_skill))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.bus_driver.total_money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra skill point earned:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.bus_driver.extra_skill_points_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Bad luck:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.bus_driver.bad_luck))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average skill point per bus stops (x10):")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%.2f"), ini.bus_driver.extra_skill_points_earned / ini.bus_driver.bus_stops))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total time spent working:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%02d:%02d:%02d"), h, m, s))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average money per hour:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.bus_driver.average_money_per_hour))); imgui.NextColumn()
            if imgui.Button(u8("Close"), imgui.ImVec2(120, 0)) then
                bus_driver_window[0] = false
            end
            if imgui.Button(u8("Start session"), imgui.ImVec2(120, 0)) then
                if bus_driver_session_window[0] then return end
                bus_driver_session_window[0] = true
                bus_driver_session = true
                bus_driver_session_stats.session_time = 0
                bus_driver_session_start = os.time()
            end
            imgui.End()
        end

        if bus_driver_session and bus_driver_session_start then
            bus_driver_session_stats.session_time = os.time() - bus_driver_session_start
        end

        if bus_driver_session_window[0] then
            local wasOpen = bus_driver_session_window[0]
            imgui.SetNextWindowSize(imgui.ImVec2(400, 300), imgui.Cond.Always)
            imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            
            imgui.Begin(u8("Bus Driver Session"), bus_driver_session_window)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 220)
            local t = bus_driver_session_stats.session_time or 0
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            local s = math.floor(t % 60)
            
            imgui.Text((string.format(u8("Session time:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%02d:%02d:%02d"), h, m, s))); imgui.NextColumn()
            imgui.Text((string.format(u8("Bus stops (x10):")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), bus_driver_session_stats.bus_stops))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(bus_driver_session_stats.money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from skins:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(bus_driver_session_stats.money_from_skins))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra money earned from skill:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(bus_driver_session_stats.extra_money_from_skill))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(bus_driver_session_stats.total_money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra skill point earned:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), bus_driver_session_stats.extra_skill_points_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Bad luck:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), bus_driver_session_stats.bad_luck)));	imgui.NextColumn()
            imgui.Text((string.format(u8("Average skill point per bus stops (x10):")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%.2f"), bus_driver_session_stats.extra_skill_points_earned / bus_driver_session_stats.bus_stops))); imgui.NextColumn()
            if imgui.Button(u8("End session"), imgui.ImVec2(120, 0)) then
                bus_driver_session_window[0] = false
            end
            imgui.End()

            if wasOpen and not bus_driver_session_window[0] then
                clearSessionsJobs()
            end
        end

        -- Garbage Man Window
        if garbage_man_window[0] then
            imgui.SetNextWindowSize(imgui.ImVec2(400, 350), imgui.Cond.Always)
            imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.Begin(u8("Garbage Man"), garbage_man_window)
            local t = ini.garbage_man.total_time_spent_working or 0
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            local s = math.floor(t % 60)

            local cleanSkill = (ini.garbage_man.skill or ""):gsub("{%x%x%x%x%x%x}", "")
            local cleanInfo = (ini.garbage_man.info or ""):gsub("{%x%x%x%x%x%x}", "")
            local skillColor = getSkillColor(cleanSkill)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 220) 

            imgui.Text((string.format(u8("Skill:")))); imgui.NextColumn()
            imgui.TextColored(skillColor, u8(cleanSkill)); imgui.NextColumn()
            imgui.Text((string.format(u8("Points for rank up:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.garbage_man.points_for_rank_up))); imgui.NextColumn()
            imgui.Text((string.format(u8("Info:")))); imgui.NextColumn()
            imgui.TextColored(INFOJOB_COLOR, u8(cleanInfo)); imgui.NextColumn()
            imgui.Text((string.format(u8("Shifts:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.garbage_man.shifts))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.garbage_man.money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from pet:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_YELLOW, u8("$" .. formatComma(ini.garbage_man.money_from_pet))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from skins:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.garbage_man.money_from_skins))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra money earned from skill:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.garbage_man.extra_money_from_skill))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.garbage_man.total_money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra skill point earned:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.garbage_man.extra_skill_points_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Bad luck:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.garbage_man.bad_luck))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average skill point per shifts:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%.2f"), ini.garbage_man.extra_skill_points_earned / ini.garbage_man.shifts))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total time spent working:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%02d:%02d:%02d"), h, m, s))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average money per hour:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.garbage_man.average_money_per_hour))); imgui.NextColumn()
            if imgui.Button(u8("Close"), imgui.ImVec2(120, 0)) then
                garbage_man_window[0] = false
            end
            if imgui.Button(u8("Start session"), imgui.ImVec2(120, 0)) then
                if garbage_man_session_window[0] then return end
                garbage_man_session_window[0] = true
                garbage_man_session = true
                garbage_man_session_stats.session_time = 0
                garbage_man_session_start = os.time()
            end
            imgui.End()
        end

        if garbage_man_session and garbage_man_session_start then
            garbage_man_session_stats.session_time = os.time() - garbage_man_session_start
        end

        if garbage_man_session_window[0] then
            local wasOpen = garbage_man_session_window[0]
            imgui.SetNextWindowSize(imgui.ImVec2(400, 300), imgui.Cond.Always)
            imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            
            imgui.Begin(u8("Garbage Man Session"), garbage_man_session_window)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 220)
            local t = garbage_man_session_stats.session_time or 0
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            local s = math.floor(t % 60)

            imgui.Text((string.format(u8("Session time:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%02d:%02d:%02d"), h, m, s))); imgui.NextColumn()
            imgui.Text((string.format(u8("Shifts:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), garbage_man_session_stats.shifts))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(garbage_man_session_stats.money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from pet:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_YELLOW, u8("$" .. formatComma(garbage_man_session_stats.money_from_pet))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from skins:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(garbage_man_session_stats.money_from_skins))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra money earned from skill:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(garbage_man_session_stats.extra_money_from_skill))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(garbage_man_session_stats.total_money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra skill point earned:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), garbage_man_session_stats.extra_skill_points_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Bad luck:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), garbage_man_session_stats.bad_luck)));	imgui.NextColumn()
            imgui.Text((string.format(u8("Average skill point per shifts:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%.2f"), garbage_man_session_stats.extra_skill_points_earned / garbage_man_session_stats.shifts))); imgui.NextColumn()
            if imgui.Button(u8("End session"), imgui.ImVec2(120, 0)) then
                garbage_man_session_window[0] = false
            end
            imgui.End()

            if wasOpen and not garbage_man_session_window[0] then
                clearSessionsJobs()
            end
        end

        -- Farmer Window
        if farmer_window[0] then
            imgui.SetNextWindowSize(imgui.ImVec2(400, 350), imgui.Cond.Always)
            imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.Begin(u8("Farmer"), farmer_window)
            local t = ini.farmer.total_time_spent_working or 0
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            local s = math.floor(t % 60)

            local cleanSkill = (ini.farmer.skill or ""):gsub("{%x%x%x%x%x%x}", "")
            local cleanInfo = (ini.farmer.info or ""):gsub("{%x%x%x%x%x%x}", "")
            local skillColor = getSkillColor(cleanSkill)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 220)  

            imgui.Text((string.format(u8("Skill:")))); imgui.NextColumn()
            imgui.TextColored(skillColor, u8(cleanSkill)); imgui.NextColumn()
            imgui.Text((string.format(u8("Points for rank up:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.farmer.points_for_rank_up))); imgui.NextColumn()
            imgui.Text((string.format(u8("Info:")))); imgui.NextColumn()
            imgui.TextColored(INFOJOB_COLOR, u8(cleanInfo)); imgui.NextColumn()
            imgui.Text((string.format(u8("Flour sold:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.farmer.flour_sold))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.farmer.money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from pet:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_YELLOW, u8("$" .. formatComma(ini.farmer.money_from_pet))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from skins:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.farmer.money_from_skins))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra money earned from skill:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.farmer.extra_money_from_skill))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.farmer.total_money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra skill point earned:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.farmer.extra_skill_points_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Bad luck:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.farmer.bad_luck))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average skill point per flour sold:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%.2f"), ini.farmer.extra_skill_points_earned / ini.farmer.flour_sold))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total time spent working:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%02d:%02d:%02d"), h, m, s))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average money per hour:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.farmer.average_money_per_hour))); imgui.NextColumn()
            if imgui.Button(u8("Close"), imgui.ImVec2(120, 0)) then
                farmer_window[0] = false
            end
            if imgui.Button(u8("Start session"), imgui.ImVec2(120, 0)) then
                if farmer_session_window[0] then return end
                farmer_session_window[0] = true
                farmer_session = true
                farmer_session_stats.session_time = 0
                farmer_session_start = os.time()
            end
            imgui.End()
        end

        if farmer_session and farmer_session_start then
            farmer_session_stats.session_time = os.time() - farmer_session_start
        end

        if farmer_session_window[0] then
            local wasOpen = farmer_session_window[0]
            imgui.SetNextWindowSize(imgui.ImVec2(400, 300), imgui.Cond.Always)
            imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            
            imgui.Begin(u8("Farmer Session"), farmer_session_window)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 220)
            local t = farmer_session_stats.session_time or 0
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            local s = math.floor(t % 60)

            imgui.Begin(u8("Farmer Session"), farmer_session_window)
            imgui.Text((string.format(u8("Session time:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%02d:%02d:%02d"), h, m, s))); imgui.NextColumn()
            imgui.Text((string.format(u8("Flour sold:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), farmer_session_stats.flour_sold))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(farmer_session_stats.money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from pet:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_YELLOW, u8("$" .. formatComma(farmer_session_stats.money_from_pet))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from skins:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(farmer_session_stats.money_from_skins))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra money earned from skill:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(farmer_session_stats.extra_money_from_skill))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(farmer_session_stats.total_money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra skill point earned:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), farmer_session_stats.extra_skill_points_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Bad luck:")))); imgui.NextColumn() 
            imgui.Text((string.format(u8("%d"), farmer_session_stats.bad_luck)));	imgui.NextColumn()
            imgui.Text((string.format(u8("Average skill point per flour sold:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%.2f"), farmer_session_stats.extra_skill_points_earned / farmer_session_stats.flour_sold))); imgui.NextColumn()
            if imgui.Button(u8("End session"), imgui.ImVec2(120, 0)) then
                farmer_session_window[0] = false
            end
            imgui.End()

            if wasOpen and not farmer_session_window[0] then
                clearSessionsJobs()
            end
        end

        -- Boat Transporter Window
        if boat_transporter_window[0] then
            imgui.SetNextWindowSize(imgui.ImVec2(400, 350), imgui.Cond.Always)
            imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.Begin(u8("Boat Transporter"), boat_transporter_window)
            local t = ini.boat_transporter.total_time_spent_working or 0
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            local s = math.floor(t % 60)

            local cleanSkill = (ini.boat_transporter.skill or ""):gsub("{%x%x%x%x%x%x}", "")
            local cleanInfo = (ini.boat_transporter.info or ""):gsub("{%x%x%x%x%x%x}", "")
            local skillColor = getSkillColor(cleanSkill)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 220)

            imgui.Text((string.format(u8("Skill:")))); imgui.NextColumn()
            imgui.TextColored(skillColor, u8(cleanSkill)); imgui.NextColumn()
            imgui.Text((string.format(u8("Points for rank up:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.boat_transporter.points_for_rank_up))); imgui.NextColumn()
            imgui.Text((string.format(u8("Info:")))); imgui.NextColumn()
            imgui.TextColored(INFOJOB_COLOR, u8(cleanInfo)); imgui.NextColumn()
            imgui.Text((string.format(u8("Shifts:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.boat_transporter.shifts))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.boat_transporter.money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from pet:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_YELLOW, u8("$" .. formatComma(ini.boat_transporter.money_from_pet))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from skins:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.boat_transporter.money_from_skins))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra money earned from skill:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.boat_transporter.extra_money_from_skill))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.boat_transporter.total_money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra skill point earned:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.boat_transporter.extra_skill_points_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Bad luck:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.boat_transporter.bad_luck))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average skill point per shifts:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%.2f"), ini.boat_transporter.extra_skill_points_earned / ini.boat_transporter.shifts))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total time spent working:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%02d:%02d:%02d"), h, m, s))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average money per hour:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.boat_transporter.average_money_per_hour))); imgui.NextColumn()
            if imgui.Button(u8("Close"), imgui.ImVec2(120, 0)) then
                boat_transporter_window[0] = false
            end
            if imgui.Button(u8("Start session"), imgui.ImVec2(120, 0)) then
                if boat_transporter_session_window[0] then return end
                boat_transporter_session_window[0] = true
                boat_transporter_session = true
                boat_transporter_session_stats.session_time = 0
                boat_transporter_session_start = os.time()
            end
            imgui.End()
        end

        if boat_transporter_session and boat_transporter_session_start then
            boat_transporter_session_stats.session_time = os.time() - boat_transporter_session_start
        end

        if boat_transporter_session_window[0] then
            local wasOpen = boat_transporter_session_window[0]
            imgui.SetNextWindowSize(imgui.ImVec2(400, 300), imgui.Cond.Always)
            imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            
            imgui.Begin(u8("Boat Transporter Session"), boat_transporter_session_window)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 220)
            local t = boat_transporter_session_stats.session_time or 0
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            local s = math.floor(t % 60)

            imgui.Text((string.format(u8("Session time:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%02d:%02d:%02d"), h, m, s))); imgui.NextColumn()
            imgui.Text((string.format(u8("Shifts:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), boat_transporter_session_stats.shifts))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(boat_transporter_session_stats.money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from pet:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_YELLOW, u8("$" .. formatComma(boat_transporter_session_stats.money_from_pet))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from skins:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(boat_transporter_session_stats.money_from_skins))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra money earned from skill:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(boat_transporter_session_stats.extra_money_from_skill))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(boat_transporter_session_stats.total_money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra skill point earned:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), boat_transporter_session_stats.extra_skill_points_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Bad luck:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), boat_transporter_session_stats.bad_luck)));	imgui.NextColumn()
            imgui.Text((string.format(u8("Average skill point per shifts:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%.2f"), boat_transporter_session_stats.extra_skill_points_earned / boat_transporter_session_stats.shifts))); imgui.NextColumn()
            if imgui.Button(u8("End session"), imgui.ImVec2(120, 0)) then
                boat_transporter_session_window[0] = false
            end
            imgui.End()

            if wasOpen and not boat_transporter_session_window[0] then
                clearSessionsJobs()
            end
        end

        -- Delivery Driver Window
        if delivery_driver_window[0] then
            imgui.SetNextWindowSize(imgui.ImVec2(400, 350), imgui.Cond.Always)
            imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.Begin(u8("Delivery Driver"), delivery_driver_window)
            local t = ini.delivery_driver.total_time_spent_working or 0
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            local s = math.floor(t % 60)

            local cleanSkill = (ini.delivery_driver.skill or ""):gsub("{%x%x%x%x%x%x}", "")
            local cleanInfo = (ini.delivery_driver.info or ""):gsub("{%x%x%x%x%x%x}", "")
            local skillColor = getSkillColor(cleanSkill)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 220)

            imgui.Text((string.format(u8("Skill:")))); imgui.NextColumn()
            imgui.TextColored(skillColor, u8(cleanSkill)); imgui.NextColumn()
            imgui.Text((string.format(u8("Points for rank up:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.delivery_driver.points_for_rank_up))); imgui.NextColumn()
            imgui.Text((string.format(u8("Info:")))); imgui.NextColumn()
            imgui.TextColored(INFOJOB_COLOR, u8(cleanInfo)); imgui.NextColumn()
            imgui.Text((string.format(u8("Deliveries made:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.delivery_driver.deliveries_made))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.delivery_driver.money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from skins:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.delivery_driver.money_from_skins))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.delivery_driver.total_money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra skill point earned:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.delivery_driver.extra_skill_points_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Bad luck:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.delivery_driver.bad_luck))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average skill point per delivery:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%.2f"), ini.delivery_driver.extra_skill_points_earned / ini.delivery_driver.deliveries_made))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total time spent working:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%02d:%02d:%02d"), h, m, s))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average money per hour:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.delivery_driver.average_money_per_hour))); imgui.NextColumn()
            if imgui.Button(u8("Close"), imgui.ImVec2(120, 0)) then
                delivery_driver_window[0] = false
            end
            if imgui.Button(u8("Start session"), imgui.ImVec2(120, 0)) then
                if delivery_driver_session_window[0] then return end
                delivery_driver_session_window[0] = true
                delivery_driver_session = true
                delivery_driver_session_stats.session_time = 0
                delivery_driver_session_start = os.time()
            end
            imgui.End()
        end

        if delivery_driver_session and delivery_driver_session_start then
            delivery_driver_session_stats.session_time = os.time() - delivery_driver_session_start
        end

        if delivery_driver_session_window[0] then
            local wasOpen = delivery_driver_session_window[0]
            imgui.SetNextWindowSize(imgui.ImVec2(400, 300), imgui.Cond.Always)
            imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            
            imgui.Begin(u8("Delivery Driver Session"), delivery_driver_session_window)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 220)
            local t = delivery_driver_session_stats.session_time or 0
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            local s = math.floor(t % 60)

            imgui.Text((string.format(u8("Session time:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%02d:%02d:%02d"), h, m, s))); imgui.NextColumn()
            imgui.Text((string.format(u8("Deliveries made:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), delivery_driver_session_stats.deliveries_made))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(delivery_driver_session_stats.money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from skins:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(delivery_driver_session_stats.money_from_skins))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(delivery_driver_session_stats.total_money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra skill point earned:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), delivery_driver_session_stats.extra_skill_points_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Bad luck:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), delivery_driver_session_stats.bad_luck)));	imgui.NextColumn()
            imgui.Text((string.format(u8("Average skill point per delivery:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%.2f"), delivery_driver_session_stats.extra_skill_points_earned / delivery_driver_session_stats.deliveries_made))); imgui.NextColumn()
            if imgui.Button(u8("End session"), imgui.ImVec2(120, 0)) then
                delivery_driver_session_window[0] = false
            end 
            imgui.End()

            if wasOpen and not delivery_driver_session_window[0] then
                clearSessionsJobs()
            end
        end

        -- Tow Trucker Window
        if tow_trucker_window[0] then
            imgui.SetNextWindowSize(imgui.ImVec2(400, 350), imgui.Cond.Always)
            imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.Begin(u8("Tow Trucker"), tow_trucker_window)
            local t = ini.tow_trucker.total_time_spent_working or 0
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            local s = math.floor(t % 60)

            local cleanSkill = (ini.tow_trucker.skill or ""):gsub("{%x%x%x%x%x%x}", "")
            local cleanInfo = (ini.tow_trucker.info or ""):gsub("{%x%x%x%x%x%x}", "")
            local skillColor = getSkillColor(cleanSkill)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 220)

            imgui.Text((string.format(u8("Skill:")))); imgui.NextColumn()
            imgui.TextColored(skillColor, u8(cleanSkill)); imgui.NextColumn()
            imgui.Text((string.format(u8("Points for rank up:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.tow_trucker.points_for_rank_up))); imgui.NextColumn()
            imgui.Text((string.format(u8("Info:")))); imgui.NextColumn()
            imgui.TextColored(INFOJOB_COLOR, u8(cleanInfo)); imgui.NextColumn()
            imgui.Text((string.format(u8("Cars trucked:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.tow_trucker.cars_trucked))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.tow_trucker.money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from pet:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_YELLOW, u8("$" .. formatComma(ini.tow_trucker.money_from_pet))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from skins:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.tow_trucker.money_from_skins))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra money earned from skill:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.tow_trucker.extra_money_from_skill))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.tow_trucker.total_money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra skill point earned:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.tow_trucker.extra_skill_points_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Bad luck:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.tow_trucker.bad_luck))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average skill point per cars trucked:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%.2f"), ini.tow_trucker.extra_skill_points_earned / ini.tow_trucker.cars_trucked))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total time spent working:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%02d:%02d:%02d"), h, m, s))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average money per hour:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.tow_trucker.average_money_per_hour))); imgui.NextColumn()
            if imgui.Button(u8("Close"), imgui.ImVec2(120, 0)) then
                tow_trucker_window[0] = false
            end
            if imgui.Button(u8("Start session"), imgui.ImVec2(120, 0)) then
                if tow_trucker_session_window[0] then return end
                tow_trucker_session_window[0] = true
                tow_trucker_session = true
                tow_trucker_session_stats.session_time = 0
                tow_trucker_session_start = os.time()
            end
            imgui.End()
        end

        if tow_trucker_session and tow_trucker_session_start then
            tow_trucker_session_stats.session_time = os.time() - tow_trucker_session_start
        end

        if tow_trucker_session_window[0] then
            local wasOpen = tow_trucker_session_window[0]
            imgui.SetNextWindowSize(imgui.ImVec2(400, 300), imgui.Cond.Always)
            imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            
            imgui.Begin(u8("Tow Trucker Session"), tow_trucker_session_window)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 220)
            local t = tow_trucker_session_stats.session_time or 0
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            local s = math.floor(t % 60)

            imgui.Text((string.format(u8("Session time:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%02d:%02d:%02d"), h, m, s))); imgui.NextColumn()
            imgui.Text((string.format(u8("Cars trucked:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), tow_trucker_session_stats.cars_trucked))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(tow_trucker_session_stats.money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from pet:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_YELLOW, u8("$" .. formatComma(tow_trucker_session_stats.money_from_pet))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from skins:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(tow_trucker_session_stats.money_from_skins))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra money earned from skill:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(tow_trucker_session_stats.extra_money_from_skill))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(tow_trucker_session_stats.total_money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra skill point earned:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), tow_trucker_session_stats.extra_skill_points_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Bad luck:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), tow_trucker_session_stats.bad_luck)));	imgui.NextColumn()
            imgui.Text((string.format(u8("Average skill point per cars trucked:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%.2f"), tow_trucker_session_stats.extra_skill_points_earned / tow_trucker_session_stats.cars_trucked))); imgui.NextColumn()
            if imgui.Button(u8("End session"), imgui.ImVec2(120, 0)) then
                tow_trucker_session_window[0] = false
            end
            imgui.End()

            if wasOpen and not tow_trucker_session_window[0] then
                clearSessionsJobs()
            end
        end

        if total_job_stats_window[0] then
            imgui.SetNextWindowSize(imgui.ImVec2(400, 400), imgui.Cond.Always)
            imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.Begin(u8("Total Job Stats"), total_job_stats_window)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 220)
            local t = ini.total_job_stats.total_time_spent_working or 0
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            local s = math.floor(t % 60)

            imgui.Text((string.format(u8("Money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.total_job_stats.money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from pet:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_YELLOW, u8("$" .. formatComma(ini.total_job_stats.money_from_pet))); imgui.NextColumn()
            imgui.Text((string.format(u8("Money earned from skins:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.total_job_stats.money_from_skins))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra money earned from skill:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.total_job_stats.extra_money_from_skill))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total money earned:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.total_job_stats.total_money_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Extra skill point earned:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.total_job_stats.extra_skill_points_earned))); imgui.NextColumn()
            imgui.Text((string.format(u8("Bad luck:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%d"), ini.total_job_stats.bad_luck))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average skill point per shifts:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%.2f"), ini.total_job_stats.extra_skill_points_earned / ini.total_job_stats.total_shifts))); imgui.NextColumn()
            imgui.Text((string.format(u8("Total time spent working:")))); imgui.NextColumn()
            imgui.Text((string.format(u8("%02d:%02d:%02d"), h, m, s))); imgui.NextColumn()
            imgui.Text((string.format(u8("Average money per hour:")))); imgui.NextColumn()
            imgui.TextColored(MONEY_GREEN, u8("$" .. formatComma(ini.total_job_stats.average_money_per_hour))); imgui.NextColumn()
            if imgui.Button(u8("Close"), imgui.ImVec2(120, 0)) then
                total_job_stats_window[0] = false
            end
            imgui.End()
        end
              
    end        
)


function main()
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand("jobstats", function() 
        main_window[0] = not main_window[0] 
        if ini.read_skills.enable == false then
            lua_thread.create(function()
                sampSendChat("/skills")
                wait(50)
                setVirtualKeyDown(VK_ESCAPE, true)
                wait(80)
                setVirtualKeyDown(VK_ESCAPE, false)
            end)
            ini.read_skills.enable = true
            inicfg.save(ini, "JobStats.ini")
        end
    end)
    sampRegisterChatCommand("activejob", function() isDeliveryDriver = true end)
    sampRegisterChatCommand("senddbg", function()
        handleJobSkillText("Felicitari! Ai acum skill Silver 5 pentru acest job!")
    end)
    sampAddChatMessage("{00FFAA}[JobStats] Loaded! /jobstats = menu", -1)
end