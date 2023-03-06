--[[
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@                                                                              @@
@@  Created v1 12/2021 by ManchegoMike (MSL)                                    @@
@@  Created v2 08/2022 by ManchegoMike (MSL)                                    @@
@@                                                                              @@
@@  http://tinyurl.com/hc-mountaineers                                          @@
@@  https://www.twitch.tv/ManchegoMike                                          @@
@@                                                                              @@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
]]

local ADDON_VERSION = '2.1.1' -- This should be the same as in the .toc file.

--[[
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@                                                                              @@
@@  Lua utility functions that are independent of WoW                           @@
@@                                                                              @@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
]]

local ut = {}

function ut.tfmt(tbl, indent)

    if type(tbl) ~= 'table' then
        return 'argument is a ' .. type(tbl) .. ', not a table'
    end

    local function tableContainsTable(tbl)
        for k, v in pairs(tbl) do
            if (type(v) == "table") then
                return true
            end
        end
        return false
    end

    local function tfmtSimple(tbl)
        local s = '{'
        local showedIndex = false
        local expectedIndex = 1
        for k, v in pairs(tbl) do
            if expectedIndex > 1 then
                s = s .. ', '
            end
            if type(k) == 'number' then
                if showedIndex or k ~= expectedIndex then
                    s = s .. '[' .. k .. ']='
                    showedIndex = true
                end
            else
                s = s .. k .. '='
            end
            if type(v) == 'number' or type(v) == 'boolean' then
                s = s .. tostring(v)
            elseif (type(v) == 'string') then
                s = s .. '"' .. v .. '"'
            else
                s = s .. '"' .. tostring(v) .. '"'
            end
            expectedIndex = expectedIndex + 1
        end
        s = s .. "}";
        return s
    end

    local function tfmtRecursive(tbl, indent)
        local showedIndex = false
        local expectedIndex = 1
        local s = string.rep(' ', indent) .. '{\r\n'
        indent = indent + 4
        for k, v in pairs(tbl) do
            s = s .. string.rep(' ', indent)
            if (type(k) == 'number') then
                if showedIndex or k ~= expectedIndex then
                    s = s .. '[' .. k .. '] = '
                    showedIndex = true
                end
            else
                s = s .. k .. ' = '
            end
            if type(v) == 'number' or type(v) == 'boolean' then
                s = s .. tostring(v) .. ',\r\n'
            elseif (type(v) == 'string') then
                s = s .. '"' .. v .. '",\r\n'
            elseif (type(v) == 'table') then
                s = s .. ut.tfmt(v, indent + 4) .. ',\r\n'
            else
                s = s .. '"' .. tostring(v) .. '",\r\n'
            end
            expectedIndex = expectedIndex + 1
        end
        indent = indent - 4
        s = s .. string.rep(' ', indent - 4) .. '}'
        return s
    end

    if tableContainsTable(tbl) then
        return tfmtRecursive(tbl, 0)
    else
        return tfmtSimple(tbl)
    end

end

local Queue = {}

function Queue.new()
    return {first = 0, last = -1}
end

function Queue.push(q, value)
    local last = q.last + 1
    q.last = last
    q[last] = value
end

function Queue.pop(q)
    local first = q.first
    if first > q.last then return nil end
    local value = q[first]
    q[first] = nil -- allow gc
    q.first = first + 1
    return value
end

--[[
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@                                                                              @@
@@  WoW utility functions & vars that could be used by any WoW addon            @@
@@                                                                              @@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
]]

local PRINT_PREFIX = "MOUNTAINEER: "
local GAME_VERSION = nil -- 1 = Classic Era or SoM, 2 = TBC, 3 = WotLK

local CLASS_WARRIOR = 1
local CLASS_PALADIN = 2
local CLASS_HUNTER = 3
local CLASS_ROGUE = 4
local CLASS_PRIEST = 5
local CLASS_DEATHKNIGHT = 6
local CLASS_SHAMAN = 7
local CLASS_MAGE = 8
local CLASS_WARLOCK = 9
local CLASS_MONK = 10
local CLASS_DRUID = 11
local CLASS_DEMONHUNTER = 12

local CLASS_IDS_ALPHABETICAL = {CLASS_DRUID, CLASS_HUNTER, CLASS_MAGE, CLASS_PALADIN, CLASS_PRIEST, CLASS_ROGUE, CLASS_SHAMAN, CLASS_WARLOCK, CLASS_WARRIOR}

local SLOT_AMMO = 0
local SLOT_HEAD = 1
local SLOT_NECK = 2
local SLOT_SHOULDER = 3
local SLOT_SHIRT = 4
local SLOT_CHEST = 5
local SLOT_WAIST = 6
local SLOT_LEGS = 7
local SLOT_FEET = 8
local SLOT_WRIST = 9
local SLOT_HANDS = 10
local SLOT_FINGER_1 = 11
local SLOT_FINGER_2 = 12
local SLOT_TRINKET_1 = 13
local SLOT_TRINKET_2 = 14
local SLOT_BACK = 15
local SLOT_MAIN_HAND = 16
local SLOT_OFF_HAND = 17
local SLOT_RANGED = 18
local SLOT_TABARD = 19
local SLOT_BAG_1 = 20 -- the rightmost one
local SLOT_BAG_2 = 21
local SLOT_BAG_3 = 22
local SLOT_BAG_4 = 23 -- the leftmost one

local function gameVersion()
    if GAME_VERSION ~= nil then return GAME_VERSION end
    local version, build, date, tocversion = GetBuildInfo()
    if version:sub(1, 2) == '1.' then
        return 1
    elseif version:sub(1, 2) == '2.' then
        return 2
    elseif version:sub(1, 2) == '3.' then
        return 3
    else
        return 0
    end
end

local function maxLevel()
    local ver = gameVersion()
    if ver == 1 then return 60 end
    if ver == 2 then return 70 end
    if ver == 3 then return 80 end
    return 60
end

local function printableLink(link)
    if not link then return nil end
    return string.gsub(link, '|', '||')
end

local function colorText(hex6, text)
    return "|cFF" .. hex6 .. text .. "|r"
end

local function printInfo(text)
    print(colorText('c0c0c0', PRINT_PREFIX) .. colorText('ffffff', text))
end

local function printWarning(text)
    print(colorText('ff0000', PRINT_PREFIX) .. colorText('ff8000', text))
end

local function printGood(text)
    print(colorText('0080FF', PRINT_PREFIX) .. colorText('00ff00', text))
end

local function flashWarning(text)
    UIErrorsFrame:AddMessage(text, 1.0, 0.5, 0.0, GetChatTypeIndex('SYSTEM'), 8);
end

local function flashInfo(text)
    UIErrorsFrame:AddMessage(text, 1.0, 1.0, 1.0, GetChatTypeIndex('SYSTEM'), 8);
end

local function flashGood(text)
    UIErrorsFrame:AddMessage(text, 0.0, 1.0, 0.0, GetChatTypeIndex('SYSTEM'), 8);
end

local function getContainerNumSlots(bag)
    if gameVersion() < 3 then return GetContainerNumSlots(bag) else return C_Container.GetContainerNumSlots(bag) end
end

local function getContainerItemInfo(bag, slot)
    if gameVersion() < 3 then return GetContainerItemInfo(bag, slot) else return C_Container.GetContainerItemInfo(bag, slot) end
end

local function getInventoryItemID(unit, slot)
    local itemId = GetInventoryItemID(unit, slot)
    if itemId == 0 then itemId = nil end
    if itemId and type(itemId) ~= 'string' then itemId = tostring(itemId) end
    return itemId
end

local function parseItemLink(link)
    if not link then return nil end
    -- |cff9d9d9d|Hitem:3299::::::::20:257::::::|h[Fractured Canine]|h|r
    local _, _, id, text = link:find(".*|.*|Hitem:(%d+):.*|h%[(.*)%]|h|r")
    return id, text
end

local function getSpellName(id)
    local name = GetSpellInfo(id)
    if not name then return nil end
    local subtext = GetSpellSubtext(id)
    --print(name, subtext)
    local fullName = name
    if subtext and subtext ~= '' then fullName = fullName .. '(' .. subtext .. ')' end
    return fullName
end

--[[
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@                                                                              @@
@@  Local vars and functions for this addon                                     @@
@@                                                                              @@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
]]

-- Localization (i18n) strings. The string after each '=' sign will need to be changed if not US English.
local L = {
    ["You receive loot"] = "You receive loot",  -- The message you get when you loot a corpse.
    ["You receive item"] = "You receive item",  -- The message you get when you get a quest reward or buy something from a merchant.
    ["You create"] = "You create",  -- The message you get when you create something.
    ["Professions"] = "Professions",  -- The heading for the section of the Skills dialog that contains your primary professions.
    ["Unarmed"] = "Unarmed",  -- Secondary profession name as it appears in the Skills dialog.
    ["First Aid"] = "First Aid",  -- Secondary profession name as it appears in the Skills dialog.
    ["Fishing"] = "Fishing",  -- Secondary profession name as it appears in the Skills dialog.
    ["Cooking"] = "Cooking",  -- Secondary profession name as it appears in the Skills dialog.
}

local PLAYER_LOC, PLAYER_CLASS_NAME, PLAYER_CLASS_ID

local PUNCH_SOUND_FILE = "Interface\\AddOns\\Mountaineer\\Sounds\\SharpPunch.ogg"
local ERROR_SOUND_FILE = "Interface\\AddOns\\Mountaineer\\Sounds\\ErrorBeep.ogg"
local WORK_COMPLETE_SOUND = 558132
local I_HAVE_FAILED_SOUND = 557928

local gPlayerGUID = ''
local gLastUnitTargeted = nil
local gLastLootSourceGUID = ''

-- I had to make these two mutually exclusive due to the screwy way WoW events work.
-- When we set one to a unit id, we set the other to nil.
local gLastQuestUnitTargeted = nil
local gLastMerchantUnitTargeted = nil

-- Used in CHAT_MSG_SKILL to let the player know immediately when all their skills are up to date.
local gSkillsAreUpToDate = false

local gSpellIdBeingCast = nil

local gPlayedFailedSound = false

-- This list is shorter than before because I've done a better job of allowing items according to their categories.
local gDefaultAllowedItems = {
    [ '2686'] = "drink", -- thunder ale (listed as 0,0 misc consumable in wow)
    [ '2894'] = "drink", -- rhapsody malt (listed as 0,0 misc consumable in wow)
    [ '2901'] = "used for profession and as a crude weapon", -- mining pick
    [ '3342'] = "looted from a chest", -- captain sander's shirt
    [ '3343'] = "looted from a chest", -- captain sander's booty bag
    [ '3344'] = "looted from a chest", -- captain sander's sash
    [ '5956'] = "used for profession and as a crude weapon", -- blacksmith hammer
    [ '5976'] = "basic item used for guilds", -- guild tabard
    [ '6256'] = "used for profession and as a crude weapon", -- fishing pole
    [ '6365'] = "used for profession and as a crude weapon", -- strong fishing pole
    [ '6529'] = "used for fishing", -- shiny bauble
    [ '6530'] = "used for fishing", -- nightcrawlers
    [ '6532'] = "used for fishing", -- bright baubles
    [ '6533'] = "used for fishing", -- aquadynamic fish attractor
    [ '7005'] = "used for profession and as a crude weapon", -- skinning knife
    [ '8067'] = "made via engineering", -- Crafted Light Shot
    [ '8068'] = "made via engineering", -- Crafted Heavy Shot
    [ '8069'] = "made via engineering", -- Crafted Solid Shot
    ['10512'] = "made via engineering", -- Hi-Impact Mithril Slugs
    ['10513'] = "made via engineering", -- Mithril Gyro-Shot
    ['15997'] = "made via engineering", -- Thorium Shells
    ['18042'] = "make Thorium Shells & trade with an NPC in TB or IF", -- Thorium Headed Arrow
    ['22250'] = "used for profession", -- Herb Bag
    ['23772'] = "made via engineering", -- Fel Iron Shells
    ['23773'] = "made via engineering", -- Adamantite Shells
    ['30745'] = "used for profession", -- Heavy Toolbox
    ['30746'] = "used for profession", -- Mining Sack
    ['30747'] = "used for profession", -- Gem Pouch
    ['30748'] = "used for profession", -- Enchanter's Satchel
    ['33803'] = "made via engineering", -- Adamantite Stinger
    ['39489'] = "used for profession", -- Scribe's Satchel
    ['41164'] = "made via engineering", -- Mammoth Cutters
    ['41165'] = "made via engineering", -- Saronite Razorheads
    ['52020'] = "made via engineering", -- Shatter Rounds
    ['52021'] = "made via engineering", -- Iceblade Arrow
}

local gDefaultDisallowedItems = {
    ['11285'] = "vendor-only", -- Jagged Arrow
    [ '3030'] = "vendor-only", -- Razor Arrow
    ['28056'] = "vendor-only", -- Blackflight Arrow
    ['31737'] = "vendor-only", -- Timeless Arrow
    ['28053'] = "vendor-only", -- Wicked Arrow
    ['41586'] = "vendor-only", -- Terrorshaft Arrow
    [ '2515'] = "vendor-only", -- Sharp Arrow
    ['41584'] = "vendor-only", -- Frostbite Bullets
    ['34581'] = "vendor-only", -- Mysterious Arrow
    ['11284'] = "vendor-only", -- Accurate Slugs
    [ '2519'] = "vendor-only", -- Heavy Shot
    [ '3033'] = "vendor-only", -- Solid Shot
    ['31735'] = "vendor-only", -- Timeless Shell
    [ '2512'] = "vendor-only", -- Rough Arrow
    ['28061'] = "vendor-only", -- Ironbite Shell
    ['10579'] = "requires a vendor-only item", -- Explosive Arrow
    ['28060'] = "vendor-only", -- Impact Shot
    ['19316'] = "vendor-only", -- Ice Threaded Arrow
    ['19317'] = "vendor-only", -- Ice Threaded Bullet
    ['32882'] = "vendor-only", -- Hellfire Shot
    [ '2516'] = "vendor-only", -- Light Shot
    ['31949'] = "vendor-only", -- Warden's Arrow
    ['30611'] = "vendor-only", -- Halaani Razorshaft
    ['24412'] = "vendor-only", -- Warden's Arrow
    ['30612'] = "vendor-only", -- Halaani Grimshot
    ['32761'] = "vendor-only", -- The Sarge's Bullet
    ['32883'] = "vendor-only", -- Felbane Slugs
    ['24417'] = "vendor-only", -- Scout's Arrow
    ['34582'] = "vendor-only", -- Mysterious Shell
}

local gUsableSpellIds = {
    [CLASS_WARRIOR] = {2457, 6673, 100},
    [CLASS_PALADIN] = {21084, 635, 465, 19740, 21082, 498, 639, 853, 1152},
    [CLASS_HUNTER]  = {1494, 13163, 1130},
    [CLASS_ROGUE]   = {1784, 921, 5277},
    [CLASS_PRIEST]  = {585, 2050, 1243, 2052, 17, 586, 139},
    [CLASS_SHAMAN]  = {403, 331, 8017, 8071, 2484, 332, 8018, 5730},
    [CLASS_MAGE]    = {168, 133, 1459, 5504, 587, 118},
    [CLASS_WARLOCK] = {686, 687, 702, 1454, 5782},
    [CLASS_DRUID]   = {5185, 1126, 774, 8921, 5186},
}

local gNonUsableSpellIds = {
    [CLASS_WARRIOR] = {78, 772, 6343, 34428, 1715},
    [CLASS_PALADIN] = {20271},
    [CLASS_HUNTER]  = {2973, 1978, 3044, 5116, 14260},
    [CLASS_ROGUE]   = {1752, 2098, 53, 1776, 1757, 6760},
    [CLASS_PRIEST]  = {589, 591},
    [CLASS_SHAMAN]  = {8042, 324, 529},
    [CLASS_MAGE]    = {116, 2136, 143, 5143},
    [CLASS_WARLOCK] = {688, 348, 172, 695, 980},
    [CLASS_DRUID]   = {8921, 467, 5177, 339},
}

local ITEM_DISPOSITION_ALLOWED      =  1    -- /mtn allow, items fished, taken from chests, and self-made
local ITEM_DISPOSITION_DISALLOWED   =  2    -- /mtn disallow
local ITEM_DISPOSITION_LOOTED       =  3    -- items looted from mobs
local ITEM_DISPOSITION_REWARDED     =  4    -- items given as quest rewards
local ITEM_DISPOSITION_PURCHASED    =  5    -- items purchased from a vendor
local ITEM_DISPOSITION_TRAILBLAZER  =  6    -- items purchased from an approved trailblazer vendor
local ITEM_DISPOSITION_RARE_MOB     =  7    -- items looted from rare mobs
local ITEM_DISPOSITION_FISHING      =  8    -- items looted via fishing
local ITEM_DISPOSITION_CONTAINER    =  9    -- items looted from a container (chest, trunk)
local ITEM_DISPOSITION_SELF_MADE    = 10    -- items created by the player

local functionQueue = Queue.new()

local function initSavedVarsIfNec(force)
    if force or AcctSaved == nil then
        AcctSaved = {
            quiet = false,
            showMiniMap = false,
            verbose = true,
        }
    end
    if force or CharSaved == nil then
        CharSaved = {
            isLucky = true,
            isTrailblazer = false,
            dispositions = {}, -- table of item dispositions (key = itemId, value = ITEM_DISPOSITION_xxx)
            madeWeapon = false,
            xpFromLastGain = 0,
            did = {}, -- 429=taxi, 895=hearth, 609=skills
        }
    end
end

local function printAllowedItem(itemLink, why)
    --itemLink = itemLink or 'Unknown item'
    if AcctSaved.verbose then
        if why and why ~= '' then
            printGood(itemLink .. " is allowed (" .. why .. ")")
        else
            printGood(itemLink .. " is allowed")
        end
    end
end

local function printDisallowedItem(itemLink, why)
    --itemLink = itemLink or 'Unknown item'
    local show = true
    if not AcctSaved.verbose then
        local itemId = parseItemLink(itemLink)
        if itemId then
            local name, link, rarity = GetItemInfo(itemLink)
            if name then
                if rarity == 0 then
                    show = false
                end
            end
        end
    end
    if show then
        if why and why ~= '' then
            printWarning(itemLink .. " is not allowed (" .. why .. ")")
        else
            printWarning(itemLink .. " is not allowed")
        end
    end
end

local function playSound(path)
    initSavedVarsIfNec()
    if not AcctSaved.quiet then
        PlaySoundFile(path, "Master")
    end
end

local function setSound(tf)
    initSavedVarsIfNec()
    if tf == nil then
        AcctSaved.quiet = not AcctSaved.quiet
    else
        AcctSaved.quiet = tf
    end
    local value = ''
    if AcctSaved.quiet then value = 'off' else value = 'on' end
    printInfo("Sound is now " .. value)
end

local function setVerbose(tf)
    initSavedVarsIfNec()
    if tf == nil then
        AcctSaved.verbose = not AcctSaved.verbose
    else
        AcctSaved.verbose = tf
    end
    local value = ''
    if AcctSaved.verbose then value = 'on' else value = 'off' end
    printInfo("Verbose mode is now " .. value)
end

local function setShowMiniMap(tf)
    initSavedVarsIfNec()
    if tf == nil then
        AcctSaved.showMiniMap = not AcctSaved.showMiniMap
    else
        AcctSaved.showMiniMap = tf
    end
    if AcctSaved.showMiniMap then
        MinimapCluster:Show()
    else
        MinimapCluster:Hide()
    end
end

local function getXPFromLastGain()
    initSavedVarsIfNec()
    return CharSaved.xpFromLastGain
end

local function setXPFromLastGain(xp)
    initSavedVarsIfNec()
    CharSaved.xpFromLastGain = xp
end

local function whatAmI()
    initSavedVarsIfNec()
    return "You are a"
        .. (CharSaved.isLucky and " lucky" or " hardtack")
        .. (CharSaved.isLazyBastard and " lazy bastard" or "")
        .. (CharSaved.isTrailblazer and " trailblazing" or "")
        .. " mountaineer"
end

local function getUsableSpellNames(class)
    local t = {}
    for _, id in ipairs(gUsableSpellIds[class]) do
        local name = getSpellName(id)
        if name then t[#t + 1] = name end
    end
    return table.concat(t, ', ')
end

local function getNonUsableSpellNames(class)
    local t = {}
    for _, id in ipairs(gNonUsableSpellIds[class]) do
        local name = getSpellName(id)
        if name then t[#t + 1] = name end
    end
    return table.concat(t, ', ')
end

local function printSpellsICanAndCannotUse()
    local level = UnitLevel('player');
    if CharSaved.madeWeapon then
        printGood("You have made your self-crafted weapon, so you can use any spells and abilities.")
    else
        printInfo("You can use " .. getUsableSpellNames(PLAYER_CLASS_ID) .. ".")
        printInfo("You cannot use " .. getNonUsableSpellNames(PLAYER_CLASS_ID) .. ".")
    end
end

local function spellIsAllowed(spellId)
    if CharSaved.madeWeapon then return true end
    for _, id in ipairs(gNonUsableSpellIds[PLAYER_CLASS_ID]) do
        if tostring(spellId) == tostring(id) then
            return false
        end
    end
    return true
end

--[[
=DUMP=
]]

local function dumpItem(itemStr)
    local name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent = GetItemInfo(itemStr)
    local id, _ = parseItemLink(link)
    print('id=', id, 'name=', name, 'link=', link, 'rarity=', rarity, 'level=', level, 'minLevel=', minLevel, 'type=', type, 'subType=', subType, 'stackCount=', stackCount, 'equipLoc=', equipLoc, 'texture=', texture, 'sellPrice=', sellPrice, 'classId=', classId, 'subclassId=', subclassId, 'bindType=', bindType, 'expacId=', expacId, 'setId=', setId, 'isCraftingReagent=', isCraftingReagent)
end

-- Allows or disallows an item (or forgets an item if allow == nil). Returns true if the item was found and modified. Returns false if there was an error.
local function allowOrDisallowItem(itemStr, allow, userOverride)

    local name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent = GetItemInfo(itemStr)

    if not name then
        printWarning("Item not found: " .. arg1)
        return false
    end

    local itemId, text = parseItemLink(link)
    if not itemId or not text then
        printWarning("Unable to parse item link: \"" .. link .. '"')
        return false
    end

    initSavedVarsIfNec()

    if allow == nil then

        if gDefaultAllowedItems[itemId] then
            if userOverride then printWarning(link .. " (" .. itemId .. ") is allowed by default and cannot be changed") end
            return false
        end
        if gDefaultDisallowedItems[itemId] then
            if userOverride then printWarning(link .. " (" .. itemId .. ") is disallowed by default and cannot be changed") end
            return false
        end
        CharSaved.dispositions[itemId] = nil
        if userOverride then printInfo(link .. " (" .. itemId .. ") is now forgotten") end

    elseif allow then

        if gDefaultDisallowedItems[itemId] then
            if userOverride then printWarning(link .. " (" .. itemId .. ") is disallowed by default and cannot be changed") end
            return false
        end
        CharSaved.dispositions[itemId] = ITEM_DISPOSITION_ALLOWED
        if userOverride then printInfo(link .. " (" .. itemId .. ") is now allowed") end
        --print('CharSaved.dispositions', itemId, 'ALLOWED')

    else

        if gDefaultAllowedItems[itemId] then
            if userOverride then printWarning(link .. " (" .. itemId .. ") is allowed by default and cannot be changed") end
            return false
        end
        CharSaved.dispositions[itemId] = ITEM_DISPOSITION_DISALLOWED
        if userOverride then printInfo(link .. " (" .. itemId .. ") is now disallowed") end
        --print('CharSaved.dispositions', itemId, 'DISALLOWED')

    end

    return true

end

-- Checks skills. Returns 4 arrays of strings: fatals, warnings, reminders, exceptions.
-- Fatals are messages that the run is invalidated.
-- Warnings are messages that the run will be invalidated on the next ding.
-- Reminders are warnings that are 2+ levels away, so a ding is still OK.
-- Exceptions are unexpected error messages.
local function getSkillCheckMessages(hideMessageIfAllIsWell, hideWarningsAndNotes)

    local fatals, warnings, reminders, notes, exceptions = {}, {}, {}, {}, {}

    -- These are the only skills we care about.
    local skills = {
        ['unarmed']   = { rank = 0, firstCheckLevel =  4, name = L['Unarmed'] },
        ['first aid'] = { rank = 0, firstCheckLevel = 10, name = L['First Aid'] },
        ['fishing']   = { rank = 0, firstCheckLevel = 10, name = L['Fishing'] },
        ['cooking']   = { rank = 0, firstCheckLevel = 10, name = L['Cooking'] },
    }

    local playerLevel = UnitLevel('player');

    -- Gather data on the above skills.
    for i = 1, GetNumSkillLines() do
        local skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, skillCostType, skillDescription = GetSkillLineInfo(i)
        if not isHeader then
            local name = skillName:lower()
            if skills[name] ~= nil then
                skills[name].rank = skillRank
            end
        end
    end

    if skills['unarmed'].rank == 0 then

        exceptions[#exceptions+1] = "Cannot find your unarmed skill - please go into your skill window and expand the \"Weapon Skills\" section"

    else

        -- Check the skill ranks against the expected rank.
        for key, skill in pairs(skills) do

            if skill.rank == 0 then

                -- The player has not yet trained this skill.
                if playerLevel >= skill.firstCheckLevel - 3 then
                    local rank = skill.firstCheckLevel * 5
                    reminders[#reminders+1] = "You must train " .. skill.name .. " and level it to " .. rank .. " before you ding " .. skill.firstCheckLevel
                end

            else

                -- The player has trained this skill.
                if key == 'unarmed' then
                    local rankRequiredAtThisLevel = playerLevel * 5 - 15
                    local rankRequiredAtNextLevel = rankRequiredAtThisLevel + 5
                    if skill.rank < rankRequiredAtThisLevel then
                        fatals[#fatals+1] = "Your " .. skill.name .. " skill is " .. skill.rank .. ", but the minimum requirement at this level is " .. rankRequiredAtThisLevel
                    elseif skill.rank < rankRequiredAtNextLevel and playerLevel < maxLevel() then
                        warnings[#warnings+1] = "Your " .. skill.name .. " skill is " .. skill.rank .. ", but MUST be at least " .. rankRequiredAtNextLevel .. " before you ding " .. (playerLevel + 1)
                    end
                else
                    local rankRequiredAtThisLevel = playerLevel * 5
                    local rankRequiredAtNextLevel = rankRequiredAtThisLevel + 5
                    local rankRequiredAtFirstCheckLevel = skill.firstCheckLevel * 5
                    local levelsToFirstSkillCheck = skill.firstCheckLevel - playerLevel
                    if levelsToFirstSkillCheck > 3 then
                        -- Don't check if more than 3 levels away from the first required level.
                    elseif levelsToFirstSkillCheck >= 2 then
                        -- The first skill check level is 2 or more levels away. Give them a gentle reminder.
                        if skill.rank < rankRequiredAtFirstCheckLevel then
                            reminders[#reminders+1] = "Your " .. skill.name .. " skill is " .. skill.rank .. ", but MUST be at least " .. rankRequiredAtFirstCheckLevel .. " before you ding " .. skill.firstCheckLevel
                        end
                    else
                        -- The player is either 1 level away from the first required level, or (more likely) they are past it.
                        if skill.rank < rankRequiredAtThisLevel and playerLevel >= skill.firstCheckLevel then
                            -- At this level the player must be at least the minimum rank.
                            fatals[#fatals+1] = "Your " .. skill.name .. " skill is " .. skill.rank .. ", but the minimum requirement at this level is " .. rankRequiredAtThisLevel
                        elseif skill.rank < rankRequiredAtNextLevel and playerLevel < maxLevel() then
                            warnings[#warnings+1] = "Your " .. skill.name .. " skill is " .. skill.rank .. ", but MUST be at least " .. rankRequiredAtNextLevel .. " before you ding " .. (playerLevel + 1)
                        else
                            local untilLevel = math.floor(skill.rank / 5)
                            notes[#notes+1] = "You won't have to improve " .. skill.name .. " until level " .. untilLevel
                        end
                    end
                end

            end

        end -- for

        if not CharSaved.madeWeapon then
            if playerLevel >= 10 then
                fatals[#fatals+1] = "You did not make your self-crafted weapon before reaching level 10."
            elseif playerLevel == 9 then
                warnings[#warnings+1] = "You have not yet made your self-crafted weapon - you need to do that before reaching level 10"
            elseif playerLevel >= 6 then
                reminders[#reminders+1] = "You have not yet made your self-crafted weapon - you will need to do that before reaching level 10"
            end
        end

        if CharSaved.isLazyBastard then
            local sawProfessionsHeader = false
            for i = 1, GetNumSkillLines() do
                local name, isHeader, isExpanded, rank, nTempPoints, modifier, maxRank, isAbandonable, stepCost, rankCost, minLevel, costType, desc = GetSkillLineInfo(i)
                if isHeader then
                    if sawProfessionsHeader then
                        -- We're at a new header after seeing the Professions header, so we're done.
                        break
                    elseif string.lower(name) == string.lower(L["Professions"]) then
                        sawProfessionsHeader = true
                        if not isExpanded then
                            exceptions[#exceptions+1] = "Cannot find your primary professions - please go into your skill window and expand the \"" .. L["Professions"] .. "\" section"
                        end
                    end
                else
                    if sawProfessionsHeader then
                        -- It's a primary profession.
                        if playerLevel >= 10 then
                            fatals[#fatals+1] = "You are a lazy bastard mountaineer, but you did not drop your primary professions before reaching level 10."
                        elseif playerLevel == 9 then
                            warnings[#warnings+1] = "As a lazy bastard mountaineer, you need to drop all primary professions BEFORE reaching level 10"
                        elseif playerLevel == 8 then
                            reminders[#reminders+1] = "As a lazy bastard mountaineer, you will need to drop all primary professions before reaching level 10"
                        end
                        break
                    else
                        -- It's not a primary profession, we're not interested in it.
                    end
                end
            end
        end

    end

    return fatals, warnings, reminders, notes, exceptions

end

-- Checks skills. Returns (warningCount, challengeIsOver).
-- The warning count is the number of skills that are low enough to either have
-- already invalidated the run, or *will* invalidate it when the player dings.
local function checkSkills(hideMessageIfAllIsWell, hideWarningsAndNotes)

    if CharSaved.did[609] then
        printWarning("You have previously violated a skill check - your mountaineer challenge is over")
        flashWarning("YOUR MOUNTAINEER CHALLENGE IS OVER")
        if not gPlayedFailedSound then
            playSound(I_HAVE_FAILED_SOUND)
            gPlayedFailedSound = true
        end
        return
    end

    local fatals, warnings, reminders, notes, exceptions = getSkillCheckMessages()

    local warningCount = #fatals + #warnings
    local challengeIsOver = #fatals > 0

    if #exceptions > 0 then
        for i = 1, #exceptions do
            printWarning(exceptions[i])
        end
    else
        if not hideWarningsAndNotes then
            if #fatals > 0 then
                for i = 1, #fatals do
                    printWarning(fatals[i])
                end
                CharSaved.did[609] = true
                printWarning("YOUR MOUNTAINEER CHALLENGE IS OVER")
                flashWarning("YOUR MOUNTAINEER CHALLENGE IS OVER")
                if not gPlayedFailedSound then
                    playSound(I_HAVE_FAILED_SOUND)
                    gPlayedFailedSound = true
                end
            else
                if #warnings > 0 then
                    for i = 1, #warnings do
                        printWarning(warnings[i])
                    end
                end
                if #reminders > 0 then
                    for i = 1, #reminders do
                        printWarning(reminders[i])
                    end
                end
            end
        end
    end

    if #fatals == 0 and #warnings == 0 and #reminders == 0 and not hideMessageIfAllIsWell then
        printGood("All skills are up to date")
    end

    if not hideWarningsAndNotes and #notes > 0 then
        for i = 1, #notes do
            printGood(notes[i])
        end
    end

    return warningCount, challengeIsOver

end

--[[
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@                                                                              @@
@@  This group of 'itemIs...' and 'unitIs...' functions are used by the current @@
@@  implementation of the Table of Usable Items. None of these function use the @@
@@  allowed or disallowed item lists.                                           @@
@@                                                                              @@
@@  They use itemInfo = {itemId, GetItemInfo(itemId)} as set in                 @@
@@  itemCanBeUsed().                                                            @@
@@                                                                              @@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
]]

-- Returns true if the item cannot be crafted in this version of WoW, and is therefore allowed to be looted or accepted as a quest reward.
local function itemIsUncraftable(t)

    -- t is a table with the following fields: name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    if t.classId == Enum.ItemClass.Weapon then
        if t.subclassId == Enum.ItemWeaponSubclass.Wand
        or t.subclassId == Enum.ItemWeaponSubclass.Staff
        or t.subclassId == Enum.ItemWeaponSubclass.Polearm
        then
            return true
        end
    end

    if t.classId == Enum.ItemClass.Armor then
        if t.subclassId == Enum.ItemArmorSubclass.Shield
        or t.subclassId == Enum.ItemArmorSubclass.Libram
        or t.subclassId == Enum.ItemArmorSubclass.Idol
        or t.subclassId == Enum.ItemArmorSubclass.Totem
        or t.subclassId == Enum.ItemArmorSubclass.Sigil
        or t.subclassId == Enum.ItemArmorSubclass.Relic
        then
            return true
        end

        if t.subclassId == Enum.ItemArmorSubclass.Generic then
            if equipLoc == INVTYPE_FINGER
            or equipLoc == INVTYPE_NECK
            then
                return (gameVersion() == 1)
            end
        end
    end

    if t.classId == Enum.ItemClass.Consumable then
        if t.subclassId == Enum.ItemConsumableSubclass.Scroll then
            return (gameVersion() < 3)
        end
    end

    return false

end

local function itemRequiresSelfMadeWeapon(t)

    -- t is a table with the following fields: name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    local classId, subclassId

    if type(t) == 'table' then
        classId = t.classId
        subclassId = t.subclassId
    elseif type(t) == 'string' or type(t) == 'number' then
        _, _, _, _, _, _, _, _, _, _, _, classId, subclassId = GetItemInfo(t)
    end

    if classId == Enum.ItemClass.Weapon then
        if  subclassId ~= Enum.ItemWeaponSubclass.FishingPole
        and subclassId ~= Enum.ItemWeaponSubclass.Generic
        then
            return true
        end
    end

    if classId == Enum.ItemClass.Armor then
        if subclassId == Enum.ItemArmorSubclass.Shield
        or subclassId == Enum.ItemArmorSubclass.Libram
        or subclassId == Enum.ItemArmorSubclass.Idol
        or subclassId == Enum.ItemArmorSubclass.Totem
        or subclassId == Enum.ItemArmorSubclass.Sigil
        or subclassId == Enum.ItemArmorSubclass.Relic
        then
            return true
        end
    end

    return false

end

local function itemIsAQuestItem(t)

    -- t is a table with the following fields: name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    return (t.classId == 12)

end

local function itemIsFoodOrDrink(t)

    -- t is a table with the following fields: name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    --print('itemIsFoodOrDrink', t.link, t.itemId, 'class', t.classId, 'subclass', t.subclassId, '==>', (t.classId == 0 and (t.subclassId == 0 or t.subclassId == 5)))

    return (t.classId == 0 and (t.subclassId == 0 or t.subclassId == 5))

end

-- Returns true if the item is a drink.
local function itemIsADrink(t)

    -- t is a table with the following fields: name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    -- These are all the drinks I could find on wowhead for WoW up to WotLK.
    -- Unfortunately WoW categorizes food & drinks as the same thing, so I had to make this list.
    local drinkIds = {
        [  '159'] = 1, -- Refreshing Spring Water
        [ '1179'] = 1, -- Ice Cold Milk
        [ '1205'] = 1, -- Melon Juice
        [ '1645'] = 1, -- Moonberry Juice
        [ '1708'] = 1, -- Sweet Nectar
        [ '2593'] = 1, -- Flask of Stormwind Tawny
        [ '2594'] = 1, -- Flagon of Dwarven Honeymead
        [ '2595'] = 1, -- Jug of Badlands Bourbon
        [ '2596'] = 1, -- Skin of Dwarven Stout
        [ '2723'] = 1, -- Bottle of Dalaran Noir
        [ '4600'] = 1, -- Cherry Grog
        [ '8766'] = 1, -- Morning Glory Dew
        ['17196'] = 1, -- Holiday Spirits
        ['17402'] = 1, -- Greatfather's Winter Ale
        ['17403'] = 1, -- Steamwheedle Fizzy Spirits
        ['17404'] = 1, -- Blended Bean Brew
        ['18287'] = 1, -- Evermurky
        ['18288'] = 1, -- Molasses Firewater
        ['19299'] = 1, -- Fizzy Faire Drink
        ['19300'] = 1, -- Bottled Winterspring Water
        ['27860'] = 1, -- Purified Draenic Water
        ['28399'] = 1, -- Filtered Draenic Water
        ['29401'] = 1, -- Sparkling Southshore Cider
        ['29454'] = 1, -- Silverwine
        ['32453'] = 1, -- Star's Tears
        ['32455'] = 1, -- Star's Lament
        ['32667'] = 1, -- Bash Ale
        ['32668'] = 1, -- Dos Ogris
        ['32722'] = 1, -- Enriched Terocone Juice
        ['33042'] = 1, -- Black Coffee
        ['33444'] = 1, -- Pungent Seal Whey
        ['33445'] = 1, -- Honeymint Tea
        ['35954'] = 1, -- Sweetened Goat's Milk
        ['37253'] = 1, -- Frostberry Juice
        ['38429'] = 1, -- Blackrock Spring Water
        ['38430'] = 1, -- Blackrock Mineral Water
        ['38431'] = 1, -- Blackrock Fortified Water
        ['38432'] = 1, -- Plugger's Blackrock Ale
        ['38698'] = 1, -- Bitter Plasma
        ['40035'] = 1, -- Honey Mead
        ['40036'] = 1, -- Snowplum Brandy
        ['40042'] = 1, -- Caraway Burnwine
        ['40357'] = 1, -- Grizzleberry Juice
        ['41731'] = 1, -- Yeti Milk
        ['42777'] = 1, -- Crusader's Waterskin
        ['43086'] = 1, -- Fresh Apple Juice
        ['43236'] = 1, -- Star's Sorrow
        ['44570'] = 1, -- Glass of Eversong Wine
        ['44571'] = 1, -- Bottle of Silvermoon Port
        ['44573'] = 1, -- Cup of Frog Venom Brew
        ['44574'] = 1, -- Skin of Mulgore Firewater
        ['44575'] = 1, -- Flask of Bitter Cactus Cider
        ['44616'] = 1, -- Glass of Dalaran White
        ['44617'] = 1, -- Glass of Dalaran Red
        ['44618'] = 1, -- Glass of Aged Dalaran Red
        ['44941'] = 1, -- Fresh-Squeezed Limeade
    }

    return (drinkIds[t.itemId] == 1)

end

-- Returns true if the item can be used for a profession, and is therefore allowed to be purchased, looted, or accepted as a quest reward.
local function itemIsReagentOrUsableForAProfession(t)

    -- t is a table with the following fields: name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    if t.isCraftingReagent then
        return true
    end

    if (t.classId == Enum.ItemClass.Reagent)
    or (t.classId == Enum.ItemClass.Tradegoods)
    or (t.classId == Enum.ItemClass.ItemEnhancement)
    or (t.classId == Enum.ItemClass.Recipe)
    or (t.classId == Enum.ItemClass.Miscellaneous and t.subclassId == Enum.ItemMiscellaneousSubclass.Reagent)
    then
        return true
    end

    return false

end

-- Returns true if the item is a normal bag.
local function itemIsANormalBag(t)

    -- t is a table with the following fields: name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    return (t.classId == Enum.ItemClass.Container and subclassId == 0) -- Container subclass of 0 means it's a standard bag.

end

-- Returns true if the item is a special container (quiver, ammo pouch, soul shard bag) and is therefore allowed to be accepted as a quest reward.
local function itemIsASpecialContainer(t)

    -- t is a table with the following fields: name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    return (t.classId == Enum.ItemClass.Quiver)
        or (t.classId == Enum.ItemClass.Container and subclassId > 0) -- Container subclass of 0 means it's a standard bag. Anything else is special.

end

-- Returns true if the item is a reward from a class-specific quest and is therefore allowed to be accepted as a quest reward.
local function itemIsFromClassQuest(t)

    -- t is a table with the following fields: name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    -- I scoured wowhead for class quest reward items, and this is the list I came up with.
    -- I don't see anything in the WoW API where a quest is labelled as a class quest.
    -- The closest is the quest log headers, but collapsed quest headers present a problem.
    -- Sometime in the future maybe I can revisit this. (2023-02-21)
    local classQuestItems = {
        -- Druid
        ["32387"]=1, ["15883"]=1, ["15882"]=1, ["22274"]=1, ["22272"]=1, ["22458"]=1, ["32481"]=1, ["15877"]=1, ["32449"]=1, ["16608"]=1, ["13446"]=1, ["15866"]=1,
        -- Hunter
        ["20083"]=1, ["19991"]=1, ["19992"]=1, ["18714"]=1, ["18724"]=1, ["24136"]=1, ["18707"]=1, ["24138"]=1,
        -- Mage
        ["37006"]=1, ["7514"]=1, ["11263"]=1, ["7513"]=1, ["20035"]=1, ["20037"]=1, ["20036"]=1, ["7515"]=1, ["9517"]=1, ["7508"]=1, ["9513"]=1, ["7507"]=1, ["9514"]=1, ["7509"]=1, ["7510"]=1, ["7512"]=1, ["9515"]=1, ["7511"]=1, ["9516"]=1,
        -- Paladin
        ["25549"]=1, ["25464"]=1, ["6953"]=1, ["30696"]=1, ["20620"]=1, ["20504"]=1, ["20512"]=1, ["20505"]=1, ["7083"]=1, ["6993"]=1, ["9607"]=1, ["6776"]=1, ["6866"]=1, ["18775"]=1, ["6916"]=1, ["18746"]=1, ["6775"]=1,
        -- Priest
        ["19990"]=1, ["20082"]=1, ["20006"]=1, ["18659"]=1, ["23924"]=1, ["16605"]=1, ["23931"]=1, ["16604"]=1, ["16607"]=1, ["16606"]=1,
        -- Rogue
        ["18160"]=1, ["25878"]=1, ["7676"]=1, ["30504"]=1, ["30505"]=1, ["8066"]=1, ["19984"]=1, ["20255"]=1, ["19982"]=1, ["7907"]=1, ["8432"]=1, ["8095"]=1, ["7298"]=1, ["7208"]=1, ["23921"]=1, ["23919"]=1,
        -- Shaman
        ["20369"]=1, ["20503"]=1, ["20556"]=1, ["6636"]=1, ["6637"]=1, ["5175"]=1, ["5178"]=1, ["6654"]=1, ["5177"]=1, ["5176"]=1, ["20134"]=1, ["18807"]=1, ["18746"]=1, ["6635"]=1,
        -- Warlock
        ["18762"]=1, ["22244"]=1, ["20536"]=1, ["20534"]=1, ["20530"]=1, ["6900"]=1, ["22243"]=1, ["6898"]=1, ["15109"]=1, ["12642"]=1, ["15108"]=1, ["15106"]=1, ["18602"]=1, ["15107"]=1, ["15105"]=1, ["12293"]=1, ["4925"]=1, ["5778"]=1,
        -- Warrior
        ["20521"]=1, ["20130"]=1, ["20517"]=1, ["6851"]=1, ["6975"]=1, ["6977"]=1, ["6976"]=1, ["6783"]=1, ["6979"]=1, ["6983"]=1, ["6980"]=1, ["6985"]=1, ["7326"]=1, ["7328"]=1, ["7327"]=1, ["7329"]=1, ["7115"]=1, ["7117"]=1, ["7116"]=1, ["7118"]=1, ["7133"]=1, ["6978"]=1, ["6982"]=1, ["6981"]=1, ["6984"]=1, ["6970"]=1, ["6974"]=1, ["7120"]=1, ["7130"]=1, ["23429"]=1, ["23423"]=1, ["23431"]=1, ["23430"]=1, ["6973"]=1, ["6971"]=1, ["6966"]=1, ["6968"]=1, ["6969"]=1, ["6967"]=1, ["7129"]=1, ["7132"]=1,
    }

    return (classQuestItems[t.itemId] == 1)

end

-- Returns true if the item's rarity is beyond green (e.g., blue, purple) and is therefore allowed to be looted.
local function itemIsRare(t)

    -- t is a table with the following fields: name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    return (t.rarity and t.rarity >= Enum.ItemQuality.Rare)

end

-- Returns true if the item's rarity is gray.
local function itemIsGray(t)

    -- t is a table with the following fields: name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    return (t.rarity and t.rarity == 0)

end

-- Returns true if the unit is labelled as rare or rare elite, meaning that it can be looted.
local function unitIsRare(unitId)

    unitId = unitId .. "";
    if unitId == '' or unitId == '0' then return false end

    local c = UnitClassification(unitId)
    return (c == "rare" or c == "rareelite" or c == "worldboss")

end

-- Returns true if the unit is a vendor approved by the Trailblazer challenge.
local function unitIsOpenWorldVendor(unitId)

    unitId = unitId .. "";
    if unitId == '' or unitId == '0' then return false end

    -- https://www.warcrafttavern.com/wow-classic/guides/hidden-special-vendor/
    -- The link above was missing some vendors that I added below. I'm sure there are others.
    local vendorIds = {
        [  '844'] = 1, -- Antonio Perelli
        [  '954'] = 1, -- Kat Sampson
        [ '1146'] = 1, -- Vharr
        [ '1669'] = 1, -- Defias Profiteer
        [ '1685'] = 1, -- Xandar Goodbeard
        [ '2481'] = 1, -- Bliztik
        [ '2672'] = 1, -- Cowardly Crosby
        [ '2679'] = 1, -- Wenna Silkbeard
        [ '2697'] = 1, -- Clyde Ranthal
        [ '2698'] = 1, -- George Candarte
        [ '2805'] = 1, -- Deneb Walker
        [ '2843'] = 1, -- Jutak
        [ '3134'] = 1, -- Kzixx
        [ '3534'] = 1, -- Wallace the Blind
        [ '3535'] = 1, -- Blackmoss the Fetid
        [ '3536'] = 1, -- Kris Legace
        [ '3537'] = 1, -- Zixil
        [ '3552'] = 1, -- Alexandre Lefevre
        [ '3682'] = 1, -- Vrang Wildgore
        [ '3683'] = 1, -- Kiknikle
        [ '3684'] = 1, -- Pizznukle
        [ '3956'] = 1, -- Harklan Moongrove
        [ '4085'] = 1, -- Nizzik
        [ '4086'] = 1, -- Veenix
        [ '8305'] = 1, -- Kixxle
        [ '8678'] = 1, -- Jubie Gadgetspring
        [ '9179'] = 1, -- Jazzrik
        ['11557'] = 1, -- Meilosh
        ['11874'] = 1, -- Masat T'andr
        ['12245'] = 1, -- Vendor-Tron 1000
        ['12246'] = 1, -- Super-Seller 680
        ['12384'] = 1, -- Augustus the Touched
        ['14371'] = 1, -- Shen'dralar Provisioner
        ['15293'] = 1, -- Aendel Windspear
        ['16015'] = 1, -- Vi'el
    }

    return (vendorIds[unitId] == 1)

end

--[[
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@                                                                              @@
@@  BEGIN Table of Usable Items (see the Mountaineer document)                  @@
@@                                                                              @@
@@  This function can be called in one of two modes:                            @@
@@      No source arguments:                                                    @@
@@          This is typically from a player request about an item where we      @@
@@          don't know how they got the item. The best we can do it see if      @@
@@          it meets any of the special item criteria and advise them           @@
@@          accordingly.                                                        @@
@@      source & sourceId arguments provided:                                   @@
@@          Given the origin of the item, the function can make a decision      @@
@@          about whether the item is usable.                                   @@
@@                                                                              @@
@@  The function returns 3 values:                                              @@
@@      Number:                                                                 @@
@@          0=no, 1=yes, 2=it depends on the context.                           @@
@@          If exactly one unitId argument is passed, the value is 0 or 1.      @@
@@          If none are passed, the value will probably be 2.                   @@
@@      String:                                                                 @@
@@          The link for the item                                               @@
@@      String:                                                                 @@
@@          If source and sourceId arguments are passed, the text should fit    @@
@@          with this: Item allowed (...) or Item not allowed (...)             @@
@@          If no source arguments are passed, the text is longer, providing    @@
@@          a more complete explanation, as you might find in the document.     @@
@@                                                                              @@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
]]

local ITEM_SOURCE_UNKNOWN       = nil
local ITEM_SOURCE_LOOTED        = 1
local ITEM_SOURCE_REWARDED      = 2
local ITEM_SOURCE_PURCHASED     = 3
local ITEM_SOURCE_GAME_OBJECT   = 4
local ITEM_SOURCE_SELF_MADE     = 5

local function itemStatus(t, source, sourceId, isNewItem)

    -- t is a table with the following fields: name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    -- If the item is already on the allowed or disallowed lists, we don't need to use any logic.
    if gDefaultAllowedItems[t.itemId] then
        return 1, t.link, gDefaultAllowedItems[t.itemId]
    end
    if gDefaultDisallowedItems[t.itemId] then
        return 0, t.link, gDefaultDisallowedItems[t.itemId]
    end

    -- Get the existing disposition for the item, or nil if there is none.
    local dispo = CharSaved.dispositions[t.itemId]

    --print('itemStatus:', t.link, t.itemId, t.rarity, source, sourceId, dispo)

    if dispo and not isNewItem then

        if dispo == ITEM_DISPOSITION_ALLOWED then
            return 1, t.link, "allowed item"
        end

        if dispo == ITEM_DISPOSITION_DISALLOWED then
            return 0, t.link, "disallowed item"
        end

        if dispo == ITEM_DISPOSITION_FISHING then
            return 1, t.link, "via fishing"
        end

        if dispo == ITEM_DISPOSITION_CONTAINER then
            return 1, t.link, "via container"
        end

        if not source then
            if dispo == ITEM_DISPOSITION_FISHING    or dispo == ITEM_DISPOSITION_CONTAINER    then  source = ITEM_SOURCE_GAME_OBJECT   end
            if dispo == ITEM_DISPOSITION_LOOTED     or dispo == ITEM_DISPOSITION_RARE_MOB     then  source = ITEM_SOURCE_LOOTED        end
            if dispo == ITEM_DISPOSITION_PURCHASED  or dispo == ITEM_DISPOSITION_TRAILBLAZER  then  source = ITEM_SOURCE_LOOTED        end
            if dispo == ITEM_DISPOSITION_REWARDED                                             then  source = ITEM_SOURCE_REWARDED      end
            if dispo == ITEM_DISPOSITION_SELF_MADE                                            then  source = ITEM_SOURCE_SELF_MADE     end
        end

    end

    if not source then

        if itemRequiresSelfMadeWeapon(t) and not CharSaved.madeWeapon then
            return 0, t.link, "until you equip a self-crafted weapon"
        end

        if itemIsGray(t) then
            -- Grey items are always looted. You can't buy them or get them as quest rewards.
            if CharSaved.isLucky then
                return 1, t.link, "lucky mountaineers can use any looted gray quality items"
            else
                return 0, t.link, "hardtack mountaineers cannot use looted gray quality items"
            end
        end

        if itemIsReagentOrUsableForAProfession(t) then
            return 1, t.link, "reagents & items usable by a profession are always allowed"
        end

        if itemIsADrink(t) then
            return 1, t.link, "drinks are always allowed"
        end

        if itemIsAQuestItem(t) then
            return 1, t.link, "quest items are always allowed"
        end

        if itemIsFoodOrDrink(t) then
            return 2, t.link, "food can be looted or accepted as quest rewards, but cannot be purchased; drinks are always allowed"
        end

        if itemIsUncraftable(t) then
            return 2, t.link, "uncraftable items can be looted or accepted as quest rewards, but cannot be purchased"
        end

        if itemIsRare(t) then
            return 2, t.link, "rare items can be looted, but cannot be purchased or accepted as quest rewards"
        end

        if itemIsASpecialContainer(t) then
            return 2, t.link, "special containers can be accepted as quest rewards, but cannot be purchased or looted"
        end

        if itemIsFromClassQuest(t) then
            return 2, t.link, "class quest rewards can be accepted"
        end

        if CharSaved.isLucky then
            if CharSaved.isTrailblazer then
                return 2, t.link, "lucky trailblazer mountaineers can only use this item if it is self-made, fished, looted, or purchased from an open-world vendor"
            else
                return 2, t.link, "lucky mountaineers can only use this item if it is self-made, fished, or looted"
            end
        else
            if CharSaved.isTrailblazer then
                return 2, t.link, "hardtack trailblazer mountaineers can only use this item if it is self-made, fished, looted from a container or a rare mob, or purchased from an open-world vendor"
            else
                return 2, t.link, "hardtack mountaineers can only use this item if it is self-made, fished, or looted from a container or a rare mob"
            end
        end

    else

        -- Setting CharSaved.dispositions[t.itemId] to nil means that there is
        -- enough information in the item intrinsically to determine its
        -- disposition.

        if source == ITEM_SOURCE_SELF_MADE then
            CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_SELF_MADE
            return 1, t.link, "self-made"
        end

        if itemRequiresSelfMadeWeapon(t) and not CharSaved.madeWeapon then
            CharSaved.dispositions[t.itemId] = nil
            return 0, t.link, "cannot use weapons until crafting one of your own"
        end

        if itemIsReagentOrUsableForAProfession(t) then
            -- Don't need to save the item's disposition, since it's intrinsically allowed regardless of how it was received.
            CharSaved.dispositions[t.itemId] = nil
            return 1, t.link, "reagent / profession item"
        end

        if itemIsADrink(t) then
            -- Don't need to save the item's disposition, since it's intrinsically allowed regardless of how it was received.
            CharSaved.dispositions[t.itemId] = nil
            return 1, t.link, "drink"
        end

        if itemIsAQuestItem(t) then
            -- Don't need to save the item's disposition, since it's intrinsically allowed regardless of how it was received.
            CharSaved.dispositions[t.itemId] = nil
            return 1, t.link, "quest item"
        end

        if source == ITEM_SOURCE_GAME_OBJECT then

            if dispo == ITEM_DISPOSITION_FISHING or tonumber(sourceId) == 35591 then
                CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_FISHING
                return 1, t.link, "via fishing"
            else
                -- We don't know 100% for sure, but it's very likely this item is looted from a chest or something similar, so we allow it.
                CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_CONTAINER
                return 1, t.link, "via container"
            end

        end

        if source == ITEM_SOURCE_PURCHASED then

            if CharSaved.isTrailblazer and (dispo == ITEM_DISPOSITION_TRAILBLAZER or unitIsOpenWorldVendor(sourceId)) then
                CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_TRAILBLAZER
                return 1, t.link, "trailblazer approved vendor"
            end

            CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_PURCHASED
            return 0, t.link, "vendor"

        end

        if source == ITEM_SOURCE_LOOTED or source == ITEM_SOURCE_REWARDED then

            if itemIsFoodOrDrink(t) then
                if isLooted then
                    CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_LOOTED
                else
                    CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_REWARDED
                end
                return 1, t.link, "food"
            end

            if itemIsUncraftable(t) then
                if isLooted then
                    CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_LOOTED
                else
                    CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_REWARDED
                end
                return 1, t.link, "uncraftable item"
            end

        end

        if source == ITEM_SOURCE_LOOTED then

            if CharSaved.isLucky then
                if itemIsANormalBag(t) then
                    CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_LOOTED
                    return 1, t.link, "THE BLESSED RUN!"
                end
                if t.rarity > 0 then
                    -- Don't save disposition if the item is gray. We know they are looted, and there's no need to pollute CharSaved with all the grays.
                    CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_LOOTED
                end
                return 1, t.link, "looted"
            end

            if itemIsRare(t) then
                CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_LOOTED
                return 1, t.link, "rare item"
            end

            if dispo == ITEM_DISPOSITION_RARE_MOB or unitIsRare(sourceId) then
                CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_RARE_MOB
                return 1, t.link, "looted from rare mob"
            end

            if t.rarity > 0 then
                -- Don't save disposition if the item is gray. We know they are looted, and there's no need to pollute CharSaved with all the grays.
                CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_LOOTED
            end
            return 0, t.link, "looted"

        end

        if source == ITEM_SOURCE_REWARDED then

            if itemIsASpecialContainer(t) then
                CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_REWARDED
                return 1, t.link, "special container"
            end

            if itemIsFromClassQuest(t) then
                CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_REWARDED
                return 1, t.link, "class quest reward"
            end

            CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_REWARDED
            return 0, t.link, "quest reward"

        end

        CharSaved.dispositions[t.itemId] = nil
        return 0, t.link, "failed all tests"

    end

end

local function itemCanBeUsed(itemId, source, sourceId, isNewItem, completionFunc)

    --print('itemCanBeUsed', itemId, source, sourceId, isNewItem, completionFunc)

    itemId = itemId or ''
    if itemId == '' or itemId == '0' then
        if completionFunc then
            return completionFunc(0, "", "no item id")
        else
            return 0, "", "no item id"
        end
    end
    itemId = tostring(itemId)

    --if not string.find(itemId, "^%d+$") then
    --    print("ITEM -> " .. itemId)
    --end

    initSavedVarsIfNec()

    -- Place detailed item information into an array of results so that each individual function we
    -- call doesn't have to call GetItemInfo, which gets its data from the server. Presumably the
    -- game is smart enough to cache it, but who knows.
    -- https://wowpedia.fandom.com/wiki/API_GetItemInfo
    local t = {}
    t.itemId = itemId
    t.name, t.link, t.rarity, t.level, t.minLevel, t.type, t.subType, t.stackCount, t.equipLoc, t.texture, t.sellPrice, t.classId, t.subclassId, t.bindType, t.expacId, t.setId, t.isCraftingReagent = GetItemInfo(itemId)

    -- If we got information for the item, then return the item's status immediately.
    if not completionFunc then
        return itemStatus(t, source, sourceId, isNewItem)
    end

    -- Sometimes we don't get anything back from GetitemInfo() because it needs time to retrieve it from the server.
    -- In that case, we queue up the completion function to be executed later.

    -- Do the following after a short delay as a last resort in case GET_ITEM_INFO_RECEIVED never fires.
    C_Timer.After(.25, function()
        local func = Queue.pop(functionQueue)
        if func then
            func()
        end
    end)

    Queue.push(functionQueue, function ()
        -- Although we return the values returned by itemStatus(), you can't count on them; they are probably nil.
        return completionFunc(itemStatus(t, source, sourceId, isNewItem))
    end)

end

local function afterItemCanBeUsed(ok, link, why)
    --print ('afterItemCanBeUsed:', ok, link, why)
    if ok == 0 then
        if not link then link = "That item" end
        printDisallowedItem(link, why)
    elseif ok == 1 then
        if not link then link = "That item" end
        printAllowedItem(link, why)
    else
        if link then
            printInfo(link .. ": " .. why)
        else
            printWarning("Unable to look up item - please try again")
        end
    end
end

--[[
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@                                                                              @@
@@  END Table of Usable Items (see the Mountaineer document)                    @@
@@                                                                              @@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
]]

local function isItemAllowed(itemId)

    if not itemId then return false, "no item id" end
    itemId = tostring(itemId)

    initSavedVarsIfNec()

    -- If there's an item in the slot, check it.
    local name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent = GetItemInfo(itemId)
    local dispo = CharSaved.dispositions[itemId]
    if rarity == 0 and not dispo then dispo = ITEM_DISPOSITION_LOOTED end

    if gDefaultAllowedItems[itemId] then

        return true, gDefaultAllowedItems[itemId]

    elseif gDefaultDisallowedItems[itemId] then

        return false, gDefaultAllowedItems[itemId]

    elseif dispo == ITEM_DISPOSITION_ALLOWED then

        return true, "allowed"

    elseif dispo == ITEM_DISPOSITION_DISALLOWED then

        return false, "disallowed"

    elseif dispo == ITEM_DISPOSITION_TRAILBLAZER then

        if not CharSaved.isTrailblazer then
            return false, "purchased"
        end

    elseif dispo == ITEM_DISPOSITION_PURCHASED then

        return false, "purchased"

    elseif dispo == ITEM_DISPOSITION_LOOTED then

        if not CharSaved.isLucky then
            return false, "looted"
        end

    elseif dispo == ITEM_DISPOSITION_REWARDED then

        return false, "quest reward"

    end

    return true, "no disposition"

end

local function inventoryWarnings()
    local msgs = {}
    for slot = 1, 18 do
        local itemId = getInventoryItemID('player', slot)
        if itemId then
            -- If there's an item in the slot, check it.
            local status, link, why = itemCanBeUsed(itemId)
            --print(status, link, why)

            if not CharSaved.madeWeapon and slot == SLOT_OFF_HAND then
                status = 0
                why = "cannot equip the off-hand/shield slot until crafting your own weapon"
            elseif not CharSaved.madeWeapon and slot == SLOT_RANGED then
                status = 0
                why = "cannot equip the ranged slot until crafting your own weapon"
            end

            --print("slot", slot, ":", itemId, status, link, why)
            if status == 0 then
                if why then
                    why = '(' .. why .. ')'
                else
                    why = ''
                end
                msgs[#msgs+1] = link .. " should be unequipped " .. why
            end
        end
    end
    return msgs
end

local function checkInventory()
    local msgs = inventoryWarnings()
    if #msgs == 0 then
        printGood("All equipped items are OK")
    else
        for _, msg in ipairs(msgs) do
            printWarning(msg)
        end
        playSound(ERROR_SOUND_FILE)
    end
end

--[[
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@                                                                              @@
@@  Parsing command line                                                        @@
@@                                                                              @@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
]]

SLASH_MOUNTAINEER1, SLASH_MOUNTAINEER2 = '/mountaineer', '/mtn'
SlashCmdList["MOUNTAINEER"] = function(str)

    local p1, p2, p3, p4, cmd, arg1, match
    local override = true

    str = str:lower()

    p1, p2 = str:find("^lucky$")
    if p1 then
        CharSaved.isLucky = true
        printGood(whatAmI() .. " - good luck! " .. colorText('ffffff', "You can use any looted items."))
        checkInventory()
        return
    end

    p1, p2 = str:find("^hardtack$")
    p3, p4 = str:find("^ht$")
    if p1 or p3 then
        CharSaved.isLucky = false
        printGood(whatAmI() .. " - good luck! " .. colorText('ffffff', "You CANNOT use looted items (with some exceptions, of course)."))
        if CharSaved.isLazyBastard then
            CharSaved.isLazyBastard = false
            printWarning("Your lazy bastard challenge has been turned off")
        end
        checkInventory()
        return
    end

    p1, p2 = str:find("^trailblazer$")
    p3, p4 = str:find("^tb$")
    if p1 or p3 then
        if CharSaved.did[429] then
            printWarning("You have flown on a taxi, so you cannot be a trailblazer")
            return
        end
        if CharSaved.did[895] then
            printWarning("You have hearthed, so you cannot be a trailblazer")
            return
        end
        CharSaved.isTrailblazer = not CharSaved.isTrailblazer
        if CharSaved.isTrailblazer then
            printGood(whatAmI() .. " - good luck! " .. colorText('ffffff', "Delete your hearthstone. You cannot use flight paths. Normal vendor rules apply, but you are also allowed to use anything from a qualifying vendor who is in the open world. All traveling vendors qualify. Stationary vendors qualify if they are nowhere near a flight path."))
        else
            printGood(whatAmI() .. " - good luck! " .. colorText('ffffff', "Trailblazer mode off. You can use a hearthstone and flight paths, but you can no longer buy from open world vendors."))
        end
        return
    end

    p1, p2 = str:find("^lazy$")
    p3, p4 = str:find("^lb$")
    if p1 or p3 then
        CharSaved.isLazyBastard = not CharSaved.isLazyBastard
        if CharSaved.isLazyBastard then
            printGood(whatAmI() .. " - good luck! " .. colorText('ffffff', "BEFORE you reach level 10, you must drop your primary professions and never take another one while leveling. All primary professions can be taken, dropped, and retaken before level 10. All secondary professions are required throughout your run as usual."))
            if not CharSaved.isLucky then
                CharSaved.isLucky = true
                printWarning("Your mode has been changed from hardtack to lucky")
            end
        else
            printGood(whatAmI() .. " - good luck! " .. colorText('ffffff', "Lazy bastard mode off"))
        end
        return
    end

    p1, p2 = str:find("^made weapon$")
    if p1 then
        CharSaved.madeWeapon = not CharSaved.madeWeapon
        if CharSaved.madeWeapon then
            printGood("You are now marked as having made your self-crafted weapon, congratulations! " .. colorText('ffffff', "All your spells and abilities are unlocked."))
        else
            printGood("You are now marked as not yet having made your self-crafted weapon")
            printSpellsICanAndCannotUse()
        end
        return
    end

    p1, p2, match = str:find("^verbose *(%a*)$")
    if p1 then
        match = string.lower(match)
        if match == 'on' then
            setVerbose(true)
        elseif match == 'off' then
            setVerbose(false)
        else
            setVerbose(nil)
        end
        return
    end

    p1, p2, arg1 = str:find("^check +(.*)$")
    if p1 and arg1 then
        itemCanBeUsed(arg1, nil, nil, nil, afterItemCanBeUsed)
        return
    end

    p1, p2 = str:find("^check$")
    if p1 then
        checkInventory()
        local warningCount = checkSkills()
        gSkillsAreUpToDate = (warningCount == 0)
        return
    end

    p1, p2 = str:find("^spells$")
    if p1 then
        printSpellsICanAndCannotUse()
        return
    end

    p1, p2, match = str:find("^sound *(%a*)$")
    if p1 then
        match = string.lower(match)
        if match == 'on' then
            setSound(false)
        elseif match == 'off' then
            setSound(true)
        else
            setSound(nil)
        end
        return
    end

    p1, p2, match = str:find("^minimap *(%a*)$")
    if p1 then
        match = string.lower(match)
        if match == 'on' or match == 'show' then
            setShowMiniMap(true)
        elseif match == 'off' or match == 'hide' then
            setShowMiniMap(false)
        else
            setShowMiniMap(nil)
        end
        return
    end

    p1, p2, arg1 = str:find("^allow +(.*)$")
    if arg1 then
        allowOrDisallowItem(arg1, true, override)
        return
    end

    p1, p2, arg1 = str:find("^disallow +(.*)$")
    if arg1 then
        allowOrDisallowItem(arg1, false, override)
        return
    end

    p1, p2, arg1 = str:find("^forget +(.*)$")
    if arg1 then
        allowOrDisallowItem(arg1, nil, override)
        return
    end

    p1, p2, arg1 = str:find("^id +(.*)$")
    if arg1 then
        dumpItem(arg1)
        return
    end

    p1, p2 = str:find("^reset everything i really mean it$")
    if p1 then
        initSavedVarsIfNec(true)
        printInfo("All allowed/disallowed designations reset to 'factory' settings")
        return
    end

    p1, p2 = str:find("^version$")
    if p1 then
        printGood(ADDON_VERSION)
        return
    end

--[[
=DUMP=
]]

    print(colorText('ffff00', "/mtn lucky/hardtack"))
    print("   Switches you to lucky or hardtack mountaineer mode.")

    print(colorText('ffff00', "/mtn trailblazer/lazy"))
    print("   Toggles the trailblazer and/or the lazy bastard challenge.")

    print(colorText('ffff00', "/mtn check"))
    print("   Checks your skills and currently equipped items for conformance.")

    print(colorText('ffff00', "/mtn made weapon"))
    print("   Toggles whether or not you made your self-crafted weapon.")

    if CharSaved.madeWeapon then
        -- Nothing to print.
    else
        print(colorText('ffff00', "/mtn spells"))
        print("   Lists the abilities you may use before making your self-crafted weapon.")
    end

    print(colorText('ffff00', "/mtn version"))
    print("   Shows the current version of the addon.")

    print(colorText('ffff00', "/mtn verbose [on/off]"))
    print("   Turns verbose mode on or off. When on, you will see all evaluation messages when receiving items. When off, all \"item is allowed\" messages will be suppressed, as well as \"item is disallowed\" for gray items.")

    print(colorText('ffff00', "/mtn sound [on/off]"))
    print("   Turns addon sounds on or off.")

    print(colorText('ffff00', "/mtn minimap [on/off]"))
    print("   Turns the minimap on or off.")

    print(colorText('ffff00', "/mtn check {id/name/link}"))
    print("   Checks an item to see if you can use it.")

    print(colorText('ffff00', "/mtn allow {id/name/link}"))
    print("   Allows you to use the item you specify, either by id# or name or link.")
    print("   Example:  \"/mtn allow 7005\",  \"/mtn allow Skinning Knife\"")

    print(colorText('ffff00', "/mtn disallow {id/name/link}"))
    print("   Disallows the item you specify, either by id# or name or link.")
    print("   Example:  \"/mtn disallow 7005\",  \"/mtn disallow Skinning Knife\"")

    print(colorText('ffff00', "/mtn forget {id/name/link}"))
    print("   Forgets any allow/disallow that might be set for the item you specify, either by id# or name or link.")
    print("   This will force the item to be re-evaluated then next time you loot or buy it.")
    print("   Example:  \"/mtn forget 7005\",  \"/mtn forget Skinning Knife\"")

    print(colorText('ffff00', "/mtn reset everything i really mean it"))
    print("   Resets all allowed/disallowed lists to their default state.")
    print("   This will lose all your custom allows & disallows and cannot be undone, so use with caution.")

end

--[[
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@                                                                              @@
@@  Event processing                                                            @@
@@                                                                              @@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
]]

local EventFrame = CreateFrame('frame', 'EventFrame')
EventFrame:RegisterEvent('ACTIONBAR_SLOT_CHANGED')
EventFrame:RegisterEvent('CHAT_MSG_LOOT')
EventFrame:RegisterEvent('CHAT_MSG_SKILL')
EventFrame:RegisterEvent('GET_ITEM_INFO_RECEIVED')
EventFrame:RegisterEvent('LEARNED_SPELL_IN_TAB')
EventFrame:RegisterEvent('LOOT_READY')
EventFrame:RegisterEvent('MERCHANT_CLOSED')
EventFrame:RegisterEvent('MERCHANT_SHOW')
EventFrame:RegisterEvent('PLAYER_CONTROL_LOST')
EventFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
EventFrame:RegisterEvent('PLAYER_EQUIPMENT_CHANGED')
EventFrame:RegisterEvent('PLAYER_LEVEL_UP')
EventFrame:RegisterEvent('PLAYER_REGEN_DISABLED')
EventFrame:RegisterEvent('PLAYER_TARGET_CHANGED')
EventFrame:RegisterEvent('PLAYER_UPDATE_RESTING')
EventFrame:RegisterEvent('PLAYER_XP_UPDATE')
EventFrame:RegisterEvent('TAXIMAP_OPENED')
EventFrame:RegisterEvent('QUEST_COMPLETE')
EventFrame:RegisterEvent('QUEST_DETAIL')
EventFrame:RegisterEvent('QUEST_FINISHED')
EventFrame:RegisterEvent('QUEST_PROGRESS')
EventFrame:RegisterEvent('UNIT_SPELLCAST_SENT')
EventFrame:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')

EventFrame:SetScript('OnEvent', function(self, event, ...)

    if event == 'PLAYER_ENTERING_WORLD' then

        initSavedVarsIfNec()

        local level = UnitLevel('player')
        local xp = UnitXP('player')

        gPlayerGUID = UnitGUID('player')

        printInfo("Loaded - type /mtn to access options and features")
        printInfo("For rules, go to http://tinyurl.com/hc-mountaineers")

        -- Prime the pump for getting spell subtext if needed somewhere later on.
        -- It looks like each spell has its own cache for subtext (spell ranks).
        for _, classId in ipairs(CLASS_IDS_ALPHABETICAL) do
            getUsableSpellNames(classId)
            getNonUsableSpellNames(classId)
        end

        -- Get basic player information.

        PLAYER_LOC = PlayerLocation:CreateFromUnit("player")
        PLAYER_CLASS_NAME, _, PLAYER_CLASS_ID = C_PlayerInfo.GetClass(PLAYER_LOC)

        -- In case the player is using old CharSaved data, set some appropriate defaults.

        if CharSaved.isLucky        == nil then CharSaved.isLucky       = true          end
        if CharSaved.isTrailblazer  == nil then CharSaved.isTrailblazer = false         end
        if CharSaved.madeWeapon     == nil then CharSaved.madeWeapon    = (level >= 10) end
        if CharSaved.dispositions   == nil then CharSaved.dispositions  = {}            end
        if CharSaved.did            == nil then CharSaved.did           = {}            end
        if AcctSaved.verbose        == nil then AcctSaved.verbose       = true          end

        -- MSL 2022-08-07
        -- I've expanded Mountaineer to include all classes except DKs.
        -- Previously we only allowed warriors, rogues, and hunters.

        if PLAYER_CLASS_ID == CLASS_DEATHKNIGHT then
            PlaySoundFile(ERROR_SOUND_FILE)
            printWarning(PLAYER_CLASS_NAME .. " is not a valid Mountaineer class")
            flashWarning(PLAYER_CLASS_NAME .. " is not a valid Mountaineer class")
            return
        end

        -- Let the user know what mode they're playing in.

        printInfo(whatAmI())
        if level >= 6 and not CharSaved.madeWeapon then
            printWarning("You have not yet made your self-crafted weapon. You need to do that before reaching level 10.")
            printSpellsICanAndCannotUse()
        end

        -- Check the WoW version and set constants accordingly.

        if gameVersion() == 0 then
            local version, build, date, tocversion = GetBuildInfo()
            printWarning("This addon only designed for WoW versions 1 through 3 -- version " .. version .. " is not supported")
        end

        -- Show or hide the minimap based on preferences.
        -- (Mountaineer 2.0 rules do not allow maps, but we offer flexibility because of the addons buttons around the minimap.)

        if AcctSaved.showMiniMap then
            MinimapCluster:Show()
        else
            MinimapCluster:Hide()
        end

        -- Hide the left & right gryphons next to the main toolbar.

        --MainMenuBarLeftEndCap:Hide()
        --MainMenuBarRightEndCap:Hide()

        -- If the character is just starting out
        if level == 1 and xp < 200 then

            -- If no XP, give it a little time for the user to get rid of the intro dialog.
            local seconds = (xp == 0) and 5 or 1

            -- Do the following after a delay of a few seconds.
            C_Timer.After(seconds, function()

                local nUnequipped = 0;

                for slot = 0, 18 do
                    local itemId = getInventoryItemID("player", slot)
                    if itemId then
                        local name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice = GetItemInfo(itemId)
                        --print(" slot=", slot, " itemId=", itemId, " name=", name, " link=", link, " rarity=", rarity, " level=", level, " minLevel=", minLevel, " type=", type, " subType=", subType, " stackCount=", stackCount, " equipLoc=", equipLoc, " texture=", texture, " sellPrice=", sellPrice)
                        if slot == SLOT_MAIN_HAND or slot == SLOT_OFF_HAND or slot == SLOT_RANGED or slot == SLOT_AMMO then
                            -- The player must remove any items in the lower slots.
                            PickupInventoryItem(slot)
                            PutItemInBackpack()
                            printInfo("Unequipped " .. link .. " (" .. itemId .. ")")
                            nUnequipped = nUnequipped + 1
                        else
                            -- The player can keep anything in the upper slots.
                            -- We mark them as allowed to override older versions of the addon that blacklisted them across all characters in the account.
                            allowOrDisallowItem(itemId, true)
                        end
                    end
                end

                if nUnequipped > 0 then
                    playSound(PUNCH_SOUND_FILE)
                    printInfo("Time to do some punching!  :)")
                end

            end)

        else

            -- Do the following after a short delay.
            C_Timer.After(1, function()

                local warningCount = checkSkills()
                gSkillsAreUpToDate = (warningCount == 0)
                checkInventory()

            end)

        end

    elseif event == 'QUEST_DETAIL' or event == 'QUEST_PROGRESS' or event == 'QUEST_COMPLETE' then

        gLastQuestUnitTargeted = gLastUnitTargeted
        gLastMerchantUnitTargeted = nil
        --printInfo("Quest interaction begun with " .. tostring(gLastUnitTargeted))

    elseif event == 'QUEST_FINISHED' then

        --printInfo("Quest interaction ended")

    elseif event == 'MERCHANT_SHOW' then

        gLastMerchantUnitTargeted = gLastUnitTargeted
        gLastQuestUnitTargeted = nil
        --printInfo("Merchant interaction begun with " .. tostring(gLastUnitTargeted))

    elseif event == 'MERCHANT_CLOSED' then

        --printInfo("Merchant interaction ended")

    elseif event == 'LOOT_READY' then

        local lootTable = GetLootInfo()
        local skipLoot = false

        for i = 1, #lootTable do

            -- Each item in lootTable is a table with these keys:
            --      isQuestItem boolean?
            --      item        string
            --      locked      boolean
            --      quality     number
            --      quantity    number
            --      roll        boolean
            --      texture     number
            local item = lootTable[i]

            -- Add the first source GUID to the item. (In Era, TBC, Wrath there is only 1 source.)
            local sourceInfo = {GetLootSourceInfo(i)}
            if sourceInfo and #sourceInfo > 0 then
                local guid = sourceInfo[1]
                if guid == gLastLootSourceGUID then
                    skipLoot = true
                else
                    gLastLootSourceGUID = guid
                end
            end

        end

        --if not skipLoot then
        --    printInfo("Loot table (" .. gLastLootSourceGUID .. ")")
        --    print(ut.tfmt(lootTable))
        --end

        --=--for i = 1, #lootTable do
        --=--    print(ut.tfmt(lootTable[i]))
        --=--end

    elseif event == 'PLAYER_TARGET_CHANGED' then

        -- The purpose of this code is to set the value of gLastUnitTargeted appropriately.
        -- If the player is targeting an NPC, we set gLastUnitTargeted to its unitId.
        -- We use that later in determining the source of newly arriving items. For the most
        -- part, it's used to determine which vendor sold an item so we can check it against
        -- the list of approved vendors for the trailblazer challenge.

        local guid = UnitGUID('target')
        local name = UnitName('target')

        if guid and guid ~= gPlayerGUID then
            local unitType = strsplit("-", guid)
            -- We only care about Creatures, which are basically NPCs.
            if unitType == 'Creature' then
                local _, _, serverId, instanceId, zoneUID, unitId, spawnUID = strsplit("-", guid)
                gLastUnitTargeted = unitId
                --print("Targeting NPC", unitId, name)
            elseif unitType == 'Player' then
                --printInfo("Targeting player " .. name .. " (" .. guid .. ")")
            else
                --printInfo("Targeting " .. name .. " (" .. guid .. ")")
            end
        end

        --if not gLastUnitTargeted then
        --    printInfo("Targeting nothing")
        --end

    elseif event == 'PLAYER_REGEN_DISABLED' then

        -- Fired whenever you enter combat, as normal regen rates are disabled during combat.
        -- This means that either you are in the hate list of a NPC or that you've been taking part in a pvp action (either as attacker or victim).

        -- Do the following after a short delay.
        C_Timer.After(.3, function()
            local msgs = inventoryWarnings()
            if #msgs > 0 then
                playSound(ERROR_SOUND_FILE)
                for _, msg in ipairs(msgs) do
                    printWarning(msg)
                end
                if #msgs == 1 then
                    flashWarning(msgs[1])
                else
                    flashWarning("Unequip " .. #msgs .. " disallowed items")
                end
            end
        end)

    elseif event == 'PLAYER_LEVEL_UP' then

        local level, hp, mana, tp, str, agi, sta, int, spi = ...

        -- Do the following after a short delay.
        C_Timer.After(1, function()

            --print(" level=", level, " hp=", hp, " mana=", mana, " tp=", tp, " str=", str, " agi=", agi, " sta=", sta, " int=", int, " spi=", spi)
            local warningCount = checkSkills()
            gSkillsAreUpToDate = (warningCount == 0)

        end)

    elseif event == 'PLAYER_XP_UPDATE' then

        -- Do the following after a short delay.
        C_Timer.After(1, function()

            local xp = UnitXP('player')
            local xpMax = UnitXPMax('player')
            local level = UnitLevel('player');

            local fatals, warnings, reminders, notes, exceptions = getSkillCheckMessages()

            if #fatals > 0 or #warnings > 0 or #reminders > 0 then

                local percentList = (#fatals > 0 or #warnings > 0)
                    and { 20, 35, 50, 60, 70, 80, 85, 90, 95 }
                    or  { 25, 50, 75 }

                local percent1 = getXPFromLastGain() * 100 / xpMax
                local percent2 = xp * 100 / xpMax
                --print(" percent1=", percent1, " percent2=", percent2)

                if percent1 < percent2 then
                    for _, p in ipairs(percentList) do
                        if percent1 < p and percent2 >= p then
                            if ( #fatals > 0 )
                            or ( #warnings > 0 -- there's a potential problem, so maybe play the error sound
                                 and p >= 50 ) -- only play the sound if player xp is past the halfway point for the level
                            then
                                playSound(ERROR_SOUND_FILE)
                                flashWarning("SKILL CHECK WARNING!")
                            end
                            checkSkills()
                            break
                        end
                    end
                end

            end

            setXPFromLastGain(xp)

        end)

    elseif event == 'PLAYER_UPDATE_RESTING' then

        -- Do the following after a short delay.
        C_Timer.After(.3, function()

            if IsResting() then
                local msg = "Entering resting zone - don't logout here"
                printWarning(msg)
                flashInfo(msg)
            else
                local msg = "Exiting resting zone"
                printInfo(msg)
            end

        end)

    elseif event == 'PLAYER_EQUIPMENT_CHANGED' then

        local slot, isEmpty = ...
        --print('PLAYER_EQUIPMENT_CHANGED', slot, isEmpty)

        -- Do the following after a short delay.
        C_Timer.After(.3, function()

            if not isEmpty and slot >= 0 and slot <= 18 then

                local itemId = getInventoryItemID("player", slot)
                --print('getInventoryItemID', itemId)

                if itemId then
                    itemId = tostring(itemId)
                    local status, link, why = itemCanBeUsed(itemId)
                    --print("Equipping", name, itemId, allowed, why)

                    if status == 0 then
                        local msg = "You cannot equip " .. link .. " (" .. why .. ")"
                        playSound(ERROR_SOUND_FILE)
                        printWarning(msg)
                        flashWarning(msg)
                    elseif status == 1 then
                        if not CharSaved.madeWeapon then
                            if itemRequiresSelfMadeWeapon(itemId) then
                                if CharSaved.dispositions[itemId] == ITEM_DISPOSITION_SELF_MADE then
                                    DoEmote('CHEER')
                                    printGood("Congratulations, you just equipped your first self-made weapon!!!")
                                    printGood("All your spells and abilities are not unlocked.")
                                    printGood("You can continue to use the weapon, or discard it.")
                                    CharSaved.madeWeapon = true
                                end
                            end
                        end
                    end
                end

            end

        end)

    elseif event == 'CHAT_MSG_LOOT' then

        local text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, unused, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons = ...
        --print("CHAT_MSG_LOOT", text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, unused, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)

        -- Do the following after a short delay.
        C_Timer.After(.3, function()

            local itemId, itemText = parseItemLink(text)
            local matched = false

            local _, _, itemLink = text:find(L['You receive loot'] .. ": (.*)%.")
            if not matched and itemLink ~= nil then
                matched = true
                --print('match you receive loot')
                -- The LOOT_READY event has already fired and set gLastLootSourceGUID.
                local unitType, _, serverId, instanceId, zoneUID, unitId, spawnUID = strsplit("-", gLastLootSourceGUID)
                if unitType == 'GameObject' then
                    itemCanBeUsed(itemId, ITEM_SOURCE_GAME_OBJECT, unitId, true, afterItemCanBeUsed)
                else
                    itemCanBeUsed(itemId, ITEM_SOURCE_LOOTED, gLastUnitTargeted, true, afterItemCanBeUsed)
                end
            end

            local _, _, itemLink = text:find(L['You receive item'] .. ": (.*)%.")
            if not matched and itemLink ~= nil then
                matched = true
                --print('match you receive item')
                if gLastQuestUnitTargeted then
                    itemCanBeUsed(itemId, ITEM_SOURCE_REWARDED, gLastQuestUnitTargeted, true, afterItemCanBeUsed)
                elseif gLastMerchantUnitTargeted then
                    itemCanBeUsed(itemId, ITEM_SOURCE_PURCHASED, gLastMerchantUnitTargeted, true, afterItemCanBeUsed)
                else
                    itemCanBeUsed(itemId, nil, nil, true, afterItemCanBeUsed)
                end
            end

            local _, _, itemLink = text:find(L['You create'] .. ": (.*)%.")
            if not matched and itemLink ~= nil then
                matched = true
                --print('match you create')
                itemCanBeUsed(itemId, ITEM_SOURCE_SELF_MADE, nil, true, afterItemCanBeUsed)
            end

            if not matched then
                printWarning("Unable to determine whether or not you can use " .. itemLink .. " - check the localization strings in Mountaineer.lua")
            end

        end)

    elseif event == 'CHAT_MSG_SKILL' then

        local text = ...
        local level = UnitLevel('player')

        if level >= 3 then
            -- Do the following after a short delay.
            C_Timer.After(.3, function()
                local _, _, skill = text:find("Your skill in (.*) has increased")
                if skill ~= nil then
                    skill = skill:lower()
                    if skill == 'unarmed' or skill == 'first aid' or skill == 'fishing' or skill == 'cooking' then
                        if not gSkillsAreUpToDate then
                            local warningCount = checkSkills(true, true)
                            if warningCount == 0 then
                                -- If we're here, the player just transitioned to all skills being up to date.
                                gSkillsAreUpToDate = true
                                -- Repeat the check so the all-is-well message is displayed.
                                checkSkills()
                                -- Congratulate them with the "WORK COMPLETE" sound.
                                PlaySoundFile(WORK_COMPLETE_SOUND)
                            end
                        end
                    end
                end
            end)
        end

    elseif event == 'UNIT_SPELLCAST_SENT' then

        local unitTarget, _, castGUID, spellId = ...
        local name = getSpellName(spellId)
        --print('UNIT_SPELLCAST_SENT', spellId, name)

        gSpellIdBeingCast = spellId

        -- Do the following after a short delay.
        C_Timer.After(.1, function()

            if PLAYER_CLASS_ID == CLASS_HUNTER and spellId == 982 then -- Revive Pet

                local msg = "Pets are mortal, you must abandon after reviving"
                printWarning(msg)
                flashWarning(msg)
                playSound(ERROR_SOUND_FILE)

            elseif CharSaved.isTrailblazer and spellId == 8690 then

                printWarning("Trailblazers cannot use a hearthstone")
                flashWarning("You cannot use a hearthstone")
                playSound(ERROR_SOUND_FILE)

            elseif not spellIsAllowed(spellId) then

                printWarning("You cannot use " .. name .. " until you create and equip a self-crafted weapon")
                flashWarning("You cannot use " .. name)
                playSound(ERROR_SOUND_FILE)

            end

        end)

    elseif event == 'UNIT_SPELLCAST_SUCCEEDED' then

        local name = getSpellName(gSpellIdBeingCast)
        --print('UNIT_SPELLCAST_SUCCEEDED', gSpellIdBeingCast, name)

        -- Do the following after a short delay.
        C_Timer.After(.1, function()

            if gSpellIdBeingCast == 8690 then

                CharSaved.did[895] = true
                if CharSaved.isTrailblazer then
                    printWarning("Trailblazer mountaineers cannot hearth")
                    flashWarning("YOU ARE NO LONGER A TRAILBLAZER")
                    if not gPlayedFailedSound then
                        playSound(I_HAVE_FAILED_SOUND)
                        gPlayedFailedSound = true
                    end
                    printWarning("You are no longer a trailblazer - you can now hearth and use flight paths, but you cannot buy from open world vendors anymore")
                    CharSaved.isTrailblazer = false
                    printInfo(whatAmI())
                end

            end

            gSpellIdBeingCast = nil

        end)

    elseif event == 'GET_ITEM_INFO_RECEIVED' then

        local func = Queue.pop(functionQueue)
        if func then
            --print('GET_ITEM_INFO_RECEIVED')
            func()
        end

    elseif event == 'LEARNED_SPELL_IN_TAB' then

        local spellId, tabIndex, isGuildPerkSpell = ...
        local name = getSpellName(spellId)

        if not CharSaved.madeWeapon then
            if not spellIsAllowed(spellId) then
                printWarning("You cannot use " .. name .. " until you create and equip a self-crafted weapon")
                flashWarning("You cannot use " .. name)
                playSound(ERROR_SOUND_FILE)
            end
        end

    elseif event == 'ACTIONBAR_SLOT_CHANGED' then

        local slot = ...

        if HasAction(slot) then
            local actionType, id = GetActionInfo(slot)
            if actionType == 'spell' then
                local name = getSpellName(id)
                if not spellIsAllowed(id) then
                    printWarning("You cannot use " .. name .. " until you create and equip a self-crafted weapon")
                    flashWarning("You cannot use " .. name)
                    playSound(ERROR_SOUND_FILE)
                end
            end
        end

    elseif event == 'TAXIMAP_OPENED' then

        local mapSystemId = ...

        if CharSaved.isTrailblazer and mapSystemId == Enum.UIMapSystem.Taxi then
            printWarning("Trailblazers cannot use flying taxis!")
            flashWarning("You cannot use flying taxis!")
            playSound(ERROR_SOUND_FILE)
        end

    elseif event == 'PLAYER_CONTROL_LOST' then

        C_Timer.After(5, function()
            if UnitOnTaxi("player") then
                CharSaved.did[429] = true
                if CharSaved.isTrailblazer then
                    printWarning("Trailblazer mountaineers cannot use flying taxis")
                    flashWarning("YOU ARE NO LONGER A TRAILBLAZER")
                    if not gPlayedFailedSound then
                        playSound(I_HAVE_FAILED_SOUND)
                        gPlayedFailedSound = true
                    end
                    printWarning("You are no longer a trailblazer - you can now hearth and use flight paths, but you cannot buy from open world vendors anymore")
                    CharSaved.isTrailblazer = false
                    printInfo(whatAmI())
                end
            end
        end)

    end

end)

