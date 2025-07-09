--[[
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@                                                                              @@
@@  Created v1 12/2021 by ManchegoMike (MSL)                                    @@
@@  Created v2 08/2022 by ManchegoMike (MSL)                                    @@
@@  Created v3 11/2024 by ManchegoMike (MSL)                                    @@
@@                                                                              @@
@@  http://tinyurl.com/hc-mountaineers                                          @@
@@  https://www.twitch.tv/ManchegoMike                                          @@
@@                                                                              @@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
]]

local addonName, core = ...;
local pdb = print
local function printnothing() end

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

local MAX_LEVEL_TO_CHANGE_PLAY_MODE = 4

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

local function contains(s, sub)
    return s:find(sub, 1, true) ~= nil
end

local function startswith(s, start)
    return s:sub(1, #start) == start
end

local function endswith(s, ending)
    return ending == "" or s:sub(-#ending) == ending
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
    ["receives loot"] = "receives loot",  -- The message you get when someone loots a corpse.
    ["receives item"] = "receives item",  -- The message you get when someone gets a quest reward or buys something from a merchant.
    ["creates"] = "creates",  -- The message you get when someone creates something.
    ["Professions"] = "Professions",  -- The heading for the section of the Skills dialog that contains your primary professions.
    ["First Aid"] = "First Aid",  -- Secondary profession name as it appears in the Skills dialog.
    ["Fishing"] = "Fishing",  -- Secondary profession name as it appears in the Skills dialog.
    ["Cooking"] = "Cooking",  -- Secondary profession name as it appears in the Skills dialog.
    ["Unarmed"] = "Unarmed",  -- Secondary profession name as it appears in the Skills dialog.
    ["Defense"] = "Defense",  -- Secondary profession name as it appears in the Skills dialog.
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

-- These are the skills we check.
local gSkills = {
    ['first aid'] = { rank = 0, playerToSkillLevel = function(n) return n*5 end,     skillToPlayerLevel = function(n) return math.floor(n/5) end,   showWontHaveToImproveUntil = true,  doNotReportBeforeLevel = 6, firstCheckLevel = 10, name = L['First Aid'] },
    ['fishing']   = { rank = 0, playerToSkillLevel = function(n) return n*5 end,     skillToPlayerLevel = function(n) return math.floor(n/5) end,   showWontHaveToImproveUntil = true,  doNotReportBeforeLevel = 6, firstCheckLevel = 10, name = L['Fishing']   },
    ['cooking']   = { rank = 0, playerToSkillLevel = function(n) return n*5 end,     skillToPlayerLevel = function(n) return math.floor(n/5) end,   showWontHaveToImproveUntil = true,  doNotReportBeforeLevel = 6, firstCheckLevel = 10, name = L['Cooking']   },
    ['unarmed']   = { rank = 0, playerToSkillLevel = function(n) return (n-3)*5 end, skillToPlayerLevel = function(n) return math.floor(n/5+3) end, showWontHaveToImproveUntil = false, doNotReportBeforeLevel = 8, firstCheckLevel = 10, name = L['Unarmed']   },
    ['defense']   = { rank = 0, playerToSkillLevel = function(n) return (n-3)*5 end, skillToPlayerLevel = function(n) return math.floor(n/5+3) end, showWontHaveToImproveUntil = false, doNotReportBeforeLevel = 8, firstCheckLevel = 10, name = L['Defense']   },
}

-- Used in CHAT_MSG_SKILL to let the player know immediately when all their skills are up to date.
local gSkillsAreUpToDate = false
local gSkillsAreReadyForLevel10 = false

local gSpellIdBeingCast = nil

local gPlayedFailedSound = false

-- This list is shorter than before because I've done a better job of allowing items according to their categories.
local gDefaultAllowedItems = {
    [ '2686'] = "drink", -- thunder ale (listed as 0,0 misc consumable in wow)
    [ '2725'] = "quest item", -- Green Hills of Stranglethorn - Page 1
    [ '2728'] = "quest item", -- Green Hills of Stranglethorn - Page 4
    [ '2730'] = "quest item", -- Green Hills of Stranglethorn - Page 6
    [ '2732'] = "quest item", -- Green Hills of Stranglethorn - Page 8
    [ '2734'] = "quest item", -- Green Hills of Stranglethorn - Page 10
    [ '2735'] = "quest item", -- Green Hills of Stranglethorn - Page 11
    [ '2738'] = "quest item", -- Green Hills of Stranglethorn - Page 14
    [ '2740'] = "quest item", -- Green Hills of Stranglethorn - Page 16
    [ '2742'] = "quest item", -- Green Hills of Stranglethorn - Page 18
    [ '2744'] = "quest item", -- Green Hills of Stranglethorn - Page 20
    [ '2745'] = "quest item", -- Green Hills of Stranglethorn - Page 21
    [ '2748'] = "quest item", -- Green Hills of Stranglethorn - Page 24
    [ '2749'] = "quest item", -- Green Hills of Stranglethorn - Page 25
    [ '2750'] = "quest item", -- Green Hills of Stranglethorn - Page 26
    [ '2751'] = "quest item", -- Green Hills of Stranglethorn - Page 27
    [ '2755'] = "quest item", -- Green Hills of Stranglethorn - (whole book)
    [ '2756'] = "quest item", -- Green Hills of Stranglethorn - Chapter I
    [ '2757'] = "quest item", -- Green Hills of Stranglethorn - Chapter II
    [ '2758'] = "quest item", -- Green Hills of Stranglethorn - Chapter III
    [ '2759'] = "quest item", -- Green Hills of Stranglethorn - Chapter IV
    [ '2894'] = "drink", -- rhapsody malt (listed as 0,0 misc consumable in wow)
    [ '2901'] = "used for profession and as a crude weapon", -- mining pick
    [ '3342'] = "looted from a chest", -- captain sander's shirt
    [ '3343'] = "looted from a chest", -- captain sander's booty bag
    [ '3344'] = "looted from a chest", -- captain sander's sash
    [ '5020'] = "used to open a container", -- kolkar booty key
    [ '5523'] = "click to open", -- small barnacled clam
    [ '5524'] = "click to open", -- thick-shelled clam
    [ '5956'] = "used for profession and as a crude weapon", -- blacksmith hammer
    [ '5976'] = "basic item used for guilds", -- guild tabard
    [ '6256'] = "used for profession and as a crude weapon", -- fishing pole
    [ '6365'] = "used for profession and as a crude weapon", -- strong fishing pole
    [ '6529'] = "used for fishing", -- shiny bauble
    [ '6530'] = "used for fishing", -- nightcrawlers
    [ '6532'] = "used for fishing", -- bright baubles
    [ '6533'] = "used for fishing", -- aquadynamic fish attractor
    [ '7005'] = "used for profession and as a crude weapon", -- skinning knife
    [ '7973'] = "click to open", -- big-mouth clam
    [ '8067'] = "made via engineering", -- Crafted Light Shot
    [ '8068'] = "made via engineering", -- Crafted Heavy Shot
    [ '8069'] = "made via engineering", -- Crafted Solid Shot
    ['10456'] = "quest item", -- A Bulging Coin Purse (Dry Times)
    ['10512'] = "made via engineering", -- Hi-Impact Mithril Slugs
    ['11407'] = "misc item", -- Torn Bear Pelt
    ['12225'] = "used for fishing", -- Blump Family Fishing Pole
    ['15874'] = "click to open", -- soft-shelled clam
    ['15997'] = "made via engineering", -- Thorium Shells
    ['16645'] = "quest item", -- Shredder Operating Manual - Page 1
    ['16646'] = "quest item", -- Shredder Operating Manual - Page 2
    ['16647'] = "quest item", -- Shredder Operating Manual - Page 3
    ['16648'] = "quest item", -- Shredder Operating Manual - Page 4
    ['16649'] = "quest item", -- Shredder Operating Manual - Page 5
    ['16650'] = "quest item", -- Shredder Operating Manual - Page 6
    ['16651'] = "quest item", -- Shredder Operating Manual - Page 7
    ['16652'] = "quest item", -- Shredder Operating Manual - Page 8
    ['16653'] = "quest item", -- Shredder Operating Manual - Page 9
    ['16654'] = "quest item", -- Shredder Operating Manual - Page 10
    ['16655'] = "quest item", -- Shredder Operating Manual - Page 11
    ['16656'] = "quest item", -- Shredder Operating Manual - Page 12
    ['18042'] = "make Thorium Shells & trade with an NPC in TB or IF", -- Thorium Headed Arrow
    ['19022'] = "used for fishing", -- Nat Pagle's Extreme Angler FC-5000
    ['19970'] = "used for fishing", -- Arcanite Fishing Pole
    ['20393'] = "special event", -- Treat Bag
    ['22250'] = "used for profession", -- Herb Bag
    ['23247'] = "summer fire festival", -- Burning Blossom
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

-- Currently there are none, but I want to leave this logic for possible future items.
local gDefaultDisallowedItems = {
}

local gUsableSpellIds = {
    [CLASS_WARRIOR] = {
        2457,   -- Battle Stance
        6673,   -- Battle Shout
    },
    [CLASS_PALADIN] = {
        20154,  -- Seal of Righteousness
        21084,  -- Seal of Righteousness
        635,    -- Holy Light
        465,    -- Devotion Aura
        1875,   -- Devotion Aura
    },
    [CLASS_HUNTER]  = {
        1494,   -- Track Beasts
    },
    [CLASS_ROGUE]   = {
        --nothing!
    },
    [CLASS_PRIEST]  = {
        585,    -- Smite
        2050,   -- Lesser Heal
        1243,   -- Power Word: Fortitude
    },
    [CLASS_SHAMAN]  = {
        403,    -- Lightning Bolt
        331,    -- Healing Wave
    },
    [CLASS_MAGE]    = {
        168,    -- Frost Armor
        133,    -- Fireball
        1459,   -- Arcane Intellect
    },
    [CLASS_WARLOCK] = {
        686,    -- Shadow Bolt
        687,    -- Demon Skin
        348,    -- Immolate
    },
    [CLASS_DRUID]   = {
        5176,   -- Wrath
        5185,   -- Healing Touch
        1126,   -- Mark of the Wild
    },
}

local gNonUsableSpellIds = {
    [CLASS_WARRIOR] = {100, 78, 772, 6343, 34428, 1715},
    [CLASS_PALADIN] = {20271, 19740, 21082, 498, 639, 853, 1152},
    [CLASS_HUNTER]  = {13163, 1130, 2973, 1978, 3044, 5116, 14260},
    [CLASS_ROGUE]   = {1784, 921, 5277, 1752, 2098, 53, 1776, 1757, 6760},
    [CLASS_PRIEST]  = {2052, 17, 586, 139, 589, 591},
    [CLASS_SHAMAN]  = {8017, 8071, 2484, 332, 324, 8018, 5730, 8042, 529},
    [CLASS_MAGE]    = {5504, 587, 118, 116, 2136, 143, 5143},
    [CLASS_WARLOCK] = {702, 1454, 5782, 688, 172, 695, 980},
    [CLASS_DRUID]   = {467, 774, 8921, 5186, 8921, 5177, 339},
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

local function initSavedVarsIfNec(forceAcct, forceChar)
    if forceAcct or AcctSaved == nil then
        AcctSaved = {
            quiet = false,
            showMiniMap = true,
            verbose = true,
        }
    end
    if forceChar or CharSaved == nil then
        CharSaved = {
            challengeMode = 1,
            isTrailblazer = false,
            isPunchy = false,
            dispositions = {}, -- table of item dispositions (key = itemId, value = ITEM_DISPOSITION_xxx)
            madeWeapon = false,
            xpFromLastGain = 0,
            did = {}, -- 501=challenge is over, 429=taxi, 895=hearth, 609=skills, 779=failed punchy, 382=revived pet
            hideLootWarnings = false,
        }
    end
end

local function printAllowedItem(itemLink, why, alwaysShowWhy)
    --itemLink = itemLink or 'Unknown item'
    if AcctSaved.verbose or alwaysShowWhy then
        if why and why ~= '' then
            printGood(itemLink .. " allowed (" .. why .. ")")
        else
            printGood(itemLink .. " allowed")
        end
    end
end

local function printDisallowedItem(itemLink, why, alwaysShowWhy)
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
    if show or alwaysShowWhy then
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

local function setHideLootWarnings(tf)
    initSavedVarsIfNec()
    if tf == nil then
        CharSaved.hideLootWarnings = not CharSaved.hideLootWarnings
    else
        CharSaved.hideLootWarnings = tf
    end
    if CharSaved.hideLootWarnings then value = 'off' else value = 'on' end
    printInfo("Loot warnings are now " .. value)
end

local function getXPFromLastGain()
    initSavedVarsIfNec()
    return CharSaved.xpFromLastGain
end

local function setXPFromLastGain(xp)
    initSavedVarsIfNec()
    CharSaved.xpFromLastGain = xp
end

local function modeWord()
    if CharSaved.challengeMode == 1 then return 'lucky'     end
    if CharSaved.challengeMode == 2 then return 'hardtack'  end
    if CharSaved.challengeMode == 3 then return 'craftsman' end
    return ''
end

local function whatAmI()
    initSavedVarsIfNec()
    local word = modeWord()
    if word ~= '' then word = ' ' .. word end
    return "You are a"
        .. word
        .. (CharSaved.isLazyBastard and " lazy bastard" or "")
        .. (CharSaved.isTrailblazer and " trailblazing" or "")
        .. (CharSaved.isPunchy      and " punchy"       or "")
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

local function printSpellsICanAndCannotUse()
    local level = UnitLevel('player');
    if CharSaved.madeWeapon then
        printGood("You have made your self-crafted weapon, so you can use any spells and abilities.")
    else
        printInfo("You can use " .. getUsableSpellNames(PLAYER_CLASS_ID) .. ".")
    end
end

local function spellIsAllowed(spellId)
    -- If weapon is already crafted, then everything is allowed.
    if CharSaved.madeWeapon then
        return true
    end
    -- Check spells that this class cannot use.
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
            if userOverride then printWarning(link .. " (" .. itemId .. ") allowed by default and cannot be changed") end
            return false
        end
        if gDefaultDisallowedItems[itemId] then
            if userOverride then printWarning(link .. " (" .. itemId .. ") disallowed by default and cannot be changed") end
            return false
        end
        CharSaved.dispositions[itemId] = nil
        if userOverride then printInfo(link .. " (" .. itemId .. ") now forgotten") end

    elseif allow then

        if gDefaultDisallowedItems[itemId] then
            if userOverride then printWarning(link .. " (" .. itemId .. ") disallowed by default and cannot be changed") end
            return false
        end
        CharSaved.dispositions[itemId] = ITEM_DISPOSITION_ALLOWED
        if userOverride then printInfo(link .. " (" .. itemId .. ") now allowed") end
        --print('CharSaved.dispositions', itemId, 'ALLOWED')

    else

        if gDefaultAllowedItems[itemId] then
            if userOverride then printWarning(link .. " (" .. itemId .. ") allowed by default and cannot be changed") end
            return false
        end
        CharSaved.dispositions[itemId] = ITEM_DISPOSITION_DISALLOWED
        if userOverride then printInfo(link .. " (" .. itemId .. ") now disallowed") end
        --print('CharSaved.dispositions', itemId, 'DISALLOWED')

    end

    return true

end

local function completedLevel10Requirements()                                   --pdb('completedLevel10Requirements()')

    local skills = {
        ['fishing'  ] = 0,
        ['cooking'  ] = 0,
        ['first aid'] = 0,
        ['defense'  ] = 0,
    }

    -- Gather data on the skills we care about.
    for i = 1, GetNumSkillLines() do
        local skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, skillCostType, skillDescription = GetSkillLineInfo(i)
        if not isHeader then
            local key = skillName:lower()
            local gskill = gSkills[key]
            if skills[key] and gskill then                                      --pdb('  [1] key:', key, ', rank:', skillRank)
                skills[key] = skillRank
                local minSkillAt10 = gskill.playerToSkillLevel(10)                        --pdb('  minSkillAt10:', minSkillAt10)
                if skillRank < minSkillAt10 then                                --pdb('  [1] returning false')
                    return false
                end
            end
        end
    end

    for key, skillRank in pairs(skills) do                                      --pdb('  [2] key:', key, ', rank:', skillRank)
        if skillRank == 0 then                                                  --pdb('  [2] returning false')
            return false
        end
    end

    return true

end

local function playerHasAPrimaryProfession()
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
                return true
            end
        end
    end
    return false
end

-- Checks skills. Returns 4 arrays of strings: fatals, warnings, reminders, exceptions.
-- Fatals are messages that the run is invalidated.
-- Warnings are messages that the run will be invalidated on the next ding.
-- Reminders are warnings that are 2+ levels away, so a ding is still OK.
-- Exceptions are unexpected error messages.
local function getSkillCheckMessages(hideMessageIfAllIsWell, hideWarningsAndNotes)

    local fatals, warnings, reminders, notes, exceptions = {}, {}, {}, {}, {}

    local playerLevel = UnitLevel('player');

    -- Clear out the skill ranks; we fill them in here.
    for key, skill in pairs(gSkills) do
        skill.rank = 0
    end

    -- Gather data on the skills we care about.
    for i = 1, GetNumSkillLines() do
        local skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, skillCostType, skillDescription = GetSkillLineInfo(i)
        if not isHeader then
            local name = skillName:lower()
            if gSkills[name] ~= nil then
                gSkills[name].rank = skillRank
            end
        end
    end

    if CharSaved.isPunchy and gSkills['unarmed'].rank == 0 then

        exceptions[#exceptions+1] = "Cannot find your unarmed skill - please go into your skill window and expand the \"Weapon Skills\" section"

    else

        -- Check the skill ranks against the expected rank.
        for key, skill in pairs(gSkills) do

            local levelsToFirstSkillCheck       = skill.firstCheckLevel - playerLevel
            local rankRequiredAtFirstCheckLevel = skill.playerToSkillLevel(skill.firstCheckLevel)
            local rankRequiredAtThisLevel       = skill.playerToSkillLevel(playerLevel)
            local rankRequiredAtNextLevel       = skill.playerToSkillLevel(playerLevel + 1)

            if skill.rank == 0 then

                -- The player has not yet trained this skill.

                if levelsToFirstSkillCheck <= 3 then
                    local text = "You must train " .. skill.name .. " and level it to " .. rankRequiredAtFirstCheckLevel .. " before you reach level " .. skill.firstCheckLevel
                    if levelsToFirstSkillCheck > 1 then
                        reminders[#reminders+1] = text
                    else
                        warnings[#warnings+1] = text
                    end
                end

            else

                -- The player has trained this skill.

                if key == 'unarmed' then

                    if CharSaved.isPunchy and playerLevel >= skill.doNotReportBeforeLevel then

                        rankRequiredAtThisLevel = skill.playerToSkillLevel(playerLevel)
                        rankRequiredAtNextLevel = skill.playerToSkillLevel(playerLevel + 1)

                        if skill.rank < rankRequiredAtThisLevel then
                            if not CharSaved.did[779] then
                                warnings[#warnings+1] = "YOU FAILED THE PUNCHY ACHIEVEMENT"
                            end
                            warnings[#warnings+1] = "Your " .. skill.name .. " skill is " .. skill.rank .. ", but the minimum requirement at this level is " .. rankRequiredAtThisLevel
                            notes[#notes+1] = "You can continue the Mountaineer Challenge without the punchy achievement"
                            CharSaved.did[779] = true
                            CharSaved.isPunchy = false
                        elseif skill.rank < rankRequiredAtNextLevel and playerLevel < maxLevel() then
                            warnings[#warnings+1] = "Your " .. skill.name .. " skill is " .. skill.rank .. ", but MUST be at least " .. rankRequiredAtNextLevel .. " before you reach level " .. (playerLevel + 1)
                        end

                    end

                else

                    if levelsToFirstSkillCheck > 3 then
                        -- Don't check if more than 3 levels away from the first required level.
                    elseif levelsToFirstSkillCheck >= 2 then
                        -- The first skill check level is 2 or more levels away. Give them a gentle reminder.
                        if skill.rank < rankRequiredAtFirstCheckLevel and playerLevel >= skill.doNotReportBeforeLevel then
                            reminders[#reminders+1] = "Your " .. skill.name .. " skill is " .. skill.rank .. ", but MUST be at least " .. rankRequiredAtFirstCheckLevel .. " before you reach level " .. skill.firstCheckLevel
                        end
                    else
                        -- The player is either 1 level away from the first required level, or they are past it.
                        if skill.rank < rankRequiredAtThisLevel and playerLevel >= skill.firstCheckLevel and playerLevel >= skill.doNotReportBeforeLevel then
                            -- At this level the player must be at least the minimum rank.
                            fatals[#fatals+1] = "Your " .. skill.name .. " skill is " .. skill.rank .. ", but the minimum requirement at this level is " .. rankRequiredAtThisLevel
                        elseif skill.rank < rankRequiredAtNextLevel and playerLevel < maxLevel() then
                            warnings[#warnings+1] = "Your " .. skill.name .. " skill is " .. skill.rank .. ", but MUST be at least " .. rankRequiredAtNextLevel .. " before you reach level " .. (playerLevel + 1)
                        else
                            local untilLevel = skill.skillToPlayerLevel(skill.rank)
                            if untilLevel > playerLevel and skill.showWontHaveToImproveUntil then
                                notes[#notes+1] = "You won't have to improve " .. skill.name .. " until level " .. untilLevel
                            end
                        end
                    end

                end

            end

        end -- for

        --if not CharSaved.madeWeapon then
        --    if playerLevel >= 10 then
        --        fatals[#fatals+1] = "You did not make your self-crafted weapon before reaching level 10."
        --    elseif playerLevel == 9 then
        --        warnings[#warnings+1] = "You have not yet made your self-crafted weapon - you need to do that before reaching level 10"
        --    elseif playerLevel >= 6 then
        --        reminders[#reminders+1] = "You have not yet made your self-crafted weapon - you will need to do that before reaching level 10"
        --    end
        --end

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
        if type(CharSaved.did[609]) == 'string' then
            printWarning("You have previously violated a skill check: \"" .. CharSaved.did[609] .. "\"")
        else
            printWarning("You have previously violated a skill check")
        end
        printWarning("YOUR MOUNTAINEER CHALLENGE IS OVER")
        flashWarning("YOUR MOUNTAINEER CHALLENGE IS OVER")
        CharSaved.did[501] = true
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
                CharSaved.did[609] = fatals[1]
                printWarning("YOUR MOUNTAINEER CHALLENGE IS OVER")
                flashWarning("YOUR MOUNTAINEER CHALLENGE IS OVER")
                CharSaved.did[501] = true
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

    -- t is a table with the following fields: itemId, name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

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
            if t.equipLoc == 'INVTYPE_FINGER'
            or t.equipLoc == 'INVTYPE_NECK'
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

    -- t is a table with the following fields: itemId, name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

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

    -- t is a table with the following fields: itemId, name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    return (t.classId == 12)

end

local function itemIsFoodOrDrink(t)

    -- t is a table with the following fields: itemId, name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    local tf = (t.classId == 0 and (t.subclassId == 0 or t.subclassId == 5))
    --print('itemIsFoodOrDrink', t.link, t.itemId, 'class', t.classId, 'subclass', t.subclassId, '==>', tf)

    return tf

end

local gClassSpellReagents = {
    ['17056']=1,    -- Light Feather
    ['17057']=1,    -- Shiny Fish Scales
    ['17058']=1,    -- Fish Oil
}

-- Returns true if the item can be used for a profession, and is therefore allowed to be purchased, looted, or accepted as a quest reward.
local function itemIsReagentOrUsableForAProfession(t)

    -- t is a table with the following fields: itemId, name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

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

    if gClassSpellReagents[t.itemId] == 1 then
        return true
    end

    return false

end

-- Returns true if the item is a normal bag.
local function itemIsANormalBag(t)

    -- t is a table with the following fields: itemId, name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    return (t.classId == Enum.ItemClass.Container and t.subclassId == 0) -- Container subclass of 0 means it's a standard bag.

end

-- Returns true if the item is a special container (quiver, ammo pouch, soul shard bag) and is therefore allowed to be accepted as a quest reward.
local function itemIsASpecialContainer(t)

    -- t is a table with the following fields: itemId, name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    return (t.classId == Enum.ItemClass.Quiver)
        or (t.classId == Enum.ItemClass.Container and t.subclassId > 0) -- Container subclass of 0 means it's a standard bag. Anything else is special.

end

-- I scoured wowhead for class quest reward items, and this is the list I came up with.
-- I don't see anything in the WoW API where a quest is labelled as a class quest.
-- The closest is the quest log headers, but collapsed quest headers present a problem.
-- Sometime in the future maybe I can revisit this. (2023-02-21)
local gClassQuestItems = {
    --[[ Druid   ]] ["32387"]=1, ["15883"]=1, ["15882"]=1, ["22274"]=1, ["22272"]=1, ["22458"]=1, ["32481"]=1, ["15877"]=1, ["32449"]=1, ["16608"]=1, ["13446"]=1, ["15866"]=1,
    --[[ Hunter  ]] ["20083"]=1, ["19991"]=1, ["19992"]=1, ["18714"]=1, ["18724"]=1, ["24136"]=1, ["18707"]=1, ["24138"]=1,
    --[[ Mage    ]] ["37006"]=1, ["7514"]=1, ["11263"]=1, ["7513"]=1, ["20035"]=1, ["20037"]=1, ["20036"]=1, ["7515"]=1, ["9517"]=1, ["7508"]=1, ["9513"]=1, ["7507"]=1, ["9514"]=1, ["7509"]=1, ["7510"]=1, ["7512"]=1, ["9515"]=1, ["7511"]=1, ["9516"]=1,
    --[[ Paladin ]] ["25549"]=1, ["25464"]=1, ["6953"]=1, ["30696"]=1, ["20620"]=1, ["20504"]=1, ["20512"]=1, ["20505"]=1, ["7083"]=1, ["6993"]=1, ["9607"]=1, ["6776"]=1, ["6866"]=1, ["18775"]=1, ["6916"]=1, ["18746"]=1, ["6775"]=1,
    --[[ Priest  ]] ["19990"]=1, ["20082"]=1, ["20006"]=1, ["18659"]=1, ["23924"]=1, ["16605"]=1, ["23931"]=1, ["16604"]=1, ["16607"]=1, ["16606"]=1,
    --[[ Rogue   ]] ["18160"]=1, ["25878"]=1, ["7676"]=1, ["30504"]=1, ["30505"]=1, ["8066"]=1, ["19984"]=1, ["20255"]=1, ["19982"]=1, ["7907"]=1, ["8432"]=1, ["8095"]=1, ["7298"]=1, ["7208"]=1, ["23921"]=1, ["23919"]=1,
    --[[ Shaman  ]] ["20369"]=1, ["20503"]=1, ["20556"]=1, ["6636"]=1, ["6637"]=1, ["5175"]=1, ["5178"]=1, ["6654"]=1, ["5177"]=1, ["5176"]=1, ["20134"]=1, ["18807"]=1, ["18746"]=1, ["6635"]=1,
    --[[ Warlock ]] ["18762"]=1, ["22244"]=1, ["20536"]=1, ["20534"]=1, ["20530"]=1, ["6900"]=1, ["22243"]=1, ["6898"]=1, ["15109"]=1, ["12642"]=1, ["15108"]=1, ["15106"]=1, ["18602"]=1, ["15107"]=1, ["15105"]=1, ["12293"]=1, ["4925"]=1, ["5778"]=1,
    --[[ Warrior ]] ["20521"]=1, ["20130"]=1, ["20517"]=1, ["6851"]=1, ["6975"]=1, ["6977"]=1, ["6976"]=1, ["6783"]=1, ["6979"]=1, ["6983"]=1, ["6980"]=1, ["6985"]=1, ["7326"]=1, ["7328"]=1, ["7327"]=1, ["7329"]=1, ["7115"]=1, ["7117"]=1, ["7116"]=1, ["7118"]=1, ["7133"]=1, ["6978"]=1, ["6982"]=1, ["6981"]=1, ["6984"]=1, ["6970"]=1, ["6974"]=1, ["7120"]=1, ["7130"]=1, ["23429"]=1, ["23423"]=1, ["23431"]=1, ["23430"]=1, ["6973"]=1, ["6971"]=1, ["6966"]=1, ["6968"]=1, ["6969"]=1, ["6967"]=1, ["7129"]=1, ["7132"]=1,
}

-- Returns true if the item is a reward from a class-specific quest and is therefore allowed to be accepted as a quest reward.
local function itemIsFromClassQuest(t)

    -- t is a table with the following fields: itemId, name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    return (gClassQuestItems[t.itemId] == 1)

end

-- Returns true if the item's rarity is beyond green (e.g., blue, purple) and is therefore allowed to be looted.
local function itemIsRare(t)

    -- t is a table with the following fields: itemId, name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    return (t.rarity and t.rarity >= Enum.ItemQuality.Rare)

end

-- Returns true if the item is some kind of ammunition.
local function itemIsAmmo(t)

    -- t is a table with the following fields: itemId, name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    return (t.classId == 6)

end

-- Returns true if the item is some kind of thrown weapon.
local function itemIsThrown(t)

    -- t is a table with the following fields: itemId, name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    return (t.classId == 2 and t.subclassId == 16)

end

-- Returns true if the item's rarity is gray.
local function itemIsGray(t)

    -- t is a table with the following fields: itemId, name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    return (t.rarity and t.rarity == 0)

end

-- Returns true if the unit is labelled as rare or rare elite, meaning that it can be looted.
local function unitIsRare(unitId)

    unitId = (unitId or '') .. '';
    if unitId == '' or unitId == '0' then return false end

    local c = UnitClassification(unitId)
    return (c == "rare" or c == "rareelite" or c == "worldboss")

end

-- https://www.warcrafttavern.com/wow-classic/guides/hidden-special-vendor/
-- The link above was missing some vendors that I added below. I'm sure there are others.
local gOpenWorldVendorIds = {
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

local gSpellsDisallowedForTrailblazer = {
    [ 8690] = 1, -- Hearthstone
    [  556] = 1, -- Astral Recall
    [ 3561] = 1, -- Teleport
    [ 3562] = 1, -- Teleport
    [ 3563] = 1, -- Teleport
    [ 3565] = 1, -- Teleport
    [ 3566] = 1, -- Teleport
    [ 3567] = 1, -- Teleport
--  [18960] = 1, -- Teleport: Moonglade (2025-05-11: this spell is now allowed)
    [10059] = 1, -- Portal
    [11416] = 1, -- Portal
    [11417] = 1, -- Portal
    [11418] = 1, -- Portal
    [11419] = 1, -- Portal
    [11420] = 1, -- Portal
}

-- Returns true if the unit is a vendor approved by the Trailblazer challenge.
local function unitIsOpenWorldVendor(unitId)

    unitId = unitId .. "";
    if unitId == '' or unitId == '0' then return false end

    return (gOpenWorldVendorIds[unitId] == 1)

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
@@  The function returns 4 values:                                              @@
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
@@      Boolean:                                                                @@
@@          True if the string above should always be displayed, regardless     @@
@@          of the verbosity setting. False if normal verbosity applies.        @@
@@                                                                              @@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
]]

local ITEM_SOURCE_UNKNOWN       = nil
local ITEM_SOURCE_LOOTED        = 1
local ITEM_SOURCE_REWARDED      = 2
local ITEM_SOURCE_PURCHASED     = 3
local ITEM_SOURCE_GAME_OBJECT   = 4
local ITEM_SOURCE_SELF_MADE     = 5
local ITEM_SOURCE_CONTAINER     = 6

local function itemStatus(t, source, sourceId, isNewItem)

    local MODE = CharSaved.challengeMode
    local MODEWORD = modeWord()
    local playerLevel = UnitLevel('player');

    -- t is a table with the following fields: itemId, name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    -- If the item is already on the allowed or disallowed lists, we don't need to use any logic.
    if gDefaultAllowedItems[t.itemId] then
        return 1, t.link, gDefaultAllowedItems[t.itemId]
    end

    -- Get the existing disposition for the item, or nil if there is none.
    local dispo = CharSaved.dispositions[t.itemId]

    --pdb('itemStatus:', t.link, t.itemId, t.rarity, source, sourceId, dispo)

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

        if itemIsReagentOrUsableForAProfession(t) then
            return 1, t.link, "reagents & items usable by a profession are always allowed"
        end

        --if itemIsFoodOrDrink(t) or itemIsAmmo(t) or itemIsThrown(t) then
        --    return 2, t.link, "if from a vendor, mountaineers must sell cooked food to buy food, drink, ammo, or thrown weapons"
        --end

        if itemIsAmmo(t) or itemIsThrown(t) then
            if MODE == 3 then
                return 2, t.link, "ammo and thrown weapons must be self-made"
            else
                return 2, t.link, "ammo and thrown weapons can be looted or accepted as a quest reward, but cannot be purchased"
            end
        end

        if itemIsFoodOrDrink(t) then
            if MODE == 3 then
                return 2, t.link, "drinks are OK, food cannot be bought from a vendor, found food can only be used by pets"
            else
                return 2, t.link, "drinks are OK, food cannot be bought from a vendor"
            end
        end

        if itemIsAQuestItem(t) then
            return 1, t.link, "quest items are always allowed"
        end

        if itemIsUncraftable(t) then
            if MODE == 3 then
                return 2, t.link, "uncraftable items are not allowed"
            else
                return 2, t.link, "uncraftable items can be looted, but cannot be purchased or accepted as a quest reward"
            end
        end

        if itemIsGray(t) then
            -- Grey items are always looted. You can't buy them or get them as quest rewards.
            if MODE == 1 then
                return 1, t.link, MODEWORD .. " mountaineers can use any looted gray quality items"
            else
                return 0, t.link, MODEWORD .. " mountaineers cannot use looted gray quality items"
            end
        end

        if itemIsRare(t) then
            if MODE == 3 then
                return 2, t.link, "rare items must be self-made"
            else
                return 2, t.link, "rare items can be looted, but cannot be purchased or accepted as quest rewards"
            end
        end

        if itemIsASpecialContainer(t) then
            if MODE == 3 then
                return 2, t.link, "special containers are not allowed"
            else
                return 2, t.link, "special containers can be accepted as quest rewards, but cannot be purchased or looted"
            end
        end

        if itemIsFromClassQuest(t) then
            if MODE == 3 then
                return 2, t.link, "class quest rewards are not allowed"
            else
                return 2, t.link, "class quest rewards can be accepted"
            end
        end

        if CharSaved.isTrailblazer then
            if MODE == 1 then
                return 2, t.link, MODEWORD .. " trailblazer mountaineers can only use this item if it is self-made, fished, looted, or purchased from an open-world vendor"
            elseif MODE == 2 then
                return 2, t.link, MODEWORD .. " trailblazer mountaineers can only use this item if it is self-made, fished, looted from a container or a rare mob, or purchased from an open-world vendor"
            else
                return 2, t.link, MODEWORD .. " trailblazer mountaineers can only use this item if it is self-made or purchased from an open-world vendor"
            end
        else
            if MODE == 1 then
                return 2, t.link, MODEWORD .. " mountaineers can only use this item if it is self-made, fished, or looted"
            elseif MODE == 2 then
                return 2, t.link, MODEWORD .. " mountaineers can only use this item if it is self-made, fished, or looted from a container or a rare mob"
            else
                return 2, t.link, MODEWORD .. " mountaineers can only use this item if it is self-made"
            end
        end

    else -- there is a non-nil source

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

        if source == ITEM_SOURCE_CONTAINER then

            if MODE == 3 then
                -- Craftsmen items have to be judged on their own merit. Coming from a container does not give them a pass.
            else
                -- This item is looted from a chest or something similar, so we allow it.
                CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_CONTAINER
                return 1, t.link, "via container"
            end

        end

        if source == ITEM_SOURCE_GAME_OBJECT then

            if MODE == 3 then
                -- Craftsmen items have to be judged on their own merit. Coming from a container does not give them a pass.
                -- return 0, t.link, MODEWORD .. " mountaineers cannot use items from fishing or containers"
                if dispo == ITEM_DISPOSITION_FISHING or tonumber(sourceId) == 35591 then
                    if itemIsFoodOrDrink(t) and startswith(t.name, "Raw ") then
                        CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_FISHING
                        return 1, t.link, "via fishing"
                    end
                end
            else
                if dispo == ITEM_DISPOSITION_FISHING or tonumber(sourceId) == 35591 then
                    CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_FISHING
                    return 1, t.link, "via fishing"
                else
                    -- We don't know 100% for sure, but it's very likely this item is looted from a chest or something similar, so we allow it.
                    CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_CONTAINER
                    return 1, t.link, "from container"
                end
            end

        end

        if itemIsReagentOrUsableForAProfession(t) then
            -- Don't need to save the item's disposition, since it's intrinsically allowed regardless of how it was received.
            CharSaved.dispositions[t.itemId] = nil
            return 1, t.link, "reagent / profession item"
        end

        if itemIsAmmo(t) or itemIsThrown(t) then
            if MODE == 3 then
                return 0, t.link, "ammo and thrown weapons must be self-made"
            else
                if source == ITEM_SOURCE_PURCHASED then
                    return 0, t.link, "ammo and thrown weapons cannot be purchased"
                else
                    return 1, t.link, "ammo / thrown weapons"
                end
            end
        end

        if itemIsFoodOrDrink(t) and (source == ITEM_SOURCE_LOOTED or source == ITEM_SOURCE_REWARDED) then
            -- Show these reminders 5% of the time; otherwise they can be very spammy.
            if MODE == 3 then
                return 2, t.link, "drinks are OK, found food can only be used by pets"
            else
                return 1, t.link, "food/drink"
            end
        end

        if itemIsAmmo(t) and (source == ITEM_SOURCE_LOOTED or source == ITEM_SOURCE_REWARDED) then
            if MODE == 3 then
                return 0, t.link, "ammo must be self-made"
            else
                return 1, t.link, "ammo"
            end
        end

        if itemIsAQuestItem(t) then
            -- Don't need to save the item's disposition, since it's intrinsically allowed regardless of how it was received.
            CharSaved.dispositions[t.itemId] = nil
            return 1, t.link, "quest item"
        end

        if source == ITEM_SOURCE_PURCHASED then

            if CharSaved.isTrailblazer and (dispo == ITEM_DISPOSITION_TRAILBLAZER or unitIsOpenWorldVendor(sourceId)) then
                CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_TRAILBLAZER
                return 1, t.link, "trailblazer approved vendor"
            end

            if itemIsFoodOrDrink(t) then
                return 2, t.link, "all drinks can be purchased; food can only be purchased if it's a reagent or if you sell the same amount of cooked food"
            end

            --if itemIsFoodOrDrink(t) or itemIsAmmo(t) or itemIsThrown(t) then
            --    return 2, t.link, "you must sell cooked food for that"
            --end

            CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_PURCHASED
            return 0, t.link, "vendor"

        end

        if source == ITEM_SOURCE_LOOTED then

            if itemIsUncraftable(t) then
                CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_LOOTED
                if MODE == 3 then
                    return 0, t.link, "uncraftable items are not allowed"
                else
                    return 1, t.link, "uncraftable looted item", true
                end
            end

            if MODE == 1 then
                if itemIsANormalBag(t) then
                    CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_LOOTED
                    return 1, t.link, "THE BLESSED RUN!"
                end
                if t.rarity ~= nil and t.rarity > 0 then
                    -- Don't save disposition if the item is gray. We know they are looted, and there's no need to pollute CharSaved with all the grays.
                    CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_LOOTED
                end
                return 1, t.link, "looted"
            end

            if itemIsRare(t) then
                CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_LOOTED
                if MODE == 3 then
                    return 0, t.link, "rare items are not allowed"
                else
                    return 1, t.link, "rare item"
                end
            end

            if dispo == ITEM_DISPOSITION_RARE_MOB or unitIsRare(sourceId) then
                CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_RARE_MOB
                if MODE == 3 then
                    return 0, t.link, "items from rare mobs are not allowed"
                else
                    return 1, t.link, "looted from rare mob"
                end
            end

            if t.rarity > 0 then
                -- Don't save disposition if the item is gray. We know they are looted, and there's no need to pollute CharSaved with all the grays.
                CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_LOOTED
            end
            return 0, t.link, "looted"

        end

        if source == ITEM_SOURCE_REWARDED then

            if itemIsUncraftable(t) then
                CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_REWARDED
                return 0, t.link, "uncraftable items are not allowed"
            end

            if itemIsASpecialContainer(t) then
                CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_REWARDED
                if MODE == 3 then
                    return 0, t.link, "special containers are not allowed"
                else
                    return 1, t.link, "special container"
                end
            end

            if itemIsFromClassQuest(t) then
                CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_REWARDED
                if MODE == 3 then
                    return 0, t.link, "class quest rewards are not allowed"
                else
                    return 1, t.link, "class quest reward"
                end
            end

            CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_REWARDED
            return 0, t.link, "quest reward"

        end

        if itemIsUncraftable(t) then
            CharSaved.dispositions[t.itemId] = nil
            if MODE == 3 then
                return 0, t.link, "uncraftable items are not allowed"
            else
                return 0, t.link, "uncraftable items are only allowed if looted"
            end
        end

        CharSaved.dispositions[t.itemId] = nil
        return 0, t.link --, "failed all tests"

    end

end

local function itemCanBeUsed(itemId, source, sourceId, isNewItem, completionFunc)

    --pdb('itemCanBeUsed', itemId, source, sourceId, isNewItem, completionFunc)

    itemId = itemId or ''
    if itemId == '' or itemId == '0' then
        if completionFunc then
            return completionFunc(0, "", "no item id")
        else
            return 0, "", "no item id"
        end
    end
    itemId = tostring(itemId)

    if not string.find(itemId, "^%d+$") then
        --pdb("ITEM -> " .. itemId)
    end

    initSavedVarsIfNec()

    -- Place detailed item information into an array of results so that each individual function we
    -- call doesn't have to call GetItemInfo, which gets its data from the server. Presumably the
    -- game is smart enough to cache it, but who knows.
    -- https://wowpedia.fandom.com/wiki/API_GetItemInfo
    local t = {}
    t.itemId = itemId
    t.name, t.link, t.rarity, t.level, t.minLevel, t.type, t.subType, t.stackCount, t.equipLoc, t.texture, t.sellPrice, t.classId, t.subclassId, t.bindType, t.expacId, t.setId, t.isCraftingReagent = GetItemInfo(itemId)

    --pdb('source, link, classId, subclassId:', source, t.link, t.classId, t.subclassId)

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

local function afterItemCanBeUsed(ok, link, why, alwaysShowWhy)
    --pdb('afterItemCanBeUsed:', ok, link, why)
    if ok == 0 then
        if not link then link = "That item" end
        printDisallowedItem(link, why, alwaysShowWhy)
    elseif ok == 1 then
        if not link then link = "That item" end
        printAllowedItem(link, why, alwaysShowWhy)
    else
        if link then
            printInfo(link .. ": " .. why)
        else
            printWarning("Unable to look up item - please try again")
        end
    end
    --pdb(' ')
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

        if CharSaved.challengeMode ~= 1 then
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
            --pdb("status, link, why:", status, link, why)

            if not CharSaved.madeWeapon and slot == SLOT_OFF_HAND then
                status = 0
                why = "cannot equip the off-hand/shield slot until crafting your own weapon"
            elseif not CharSaved.madeWeapon and slot == SLOT_RANGED then
                status = 0
                why = "cannot equip the ranged slot until crafting your own weapon"
            end

            --pdb("slot", slot, ":", itemId, status, link, why)
            if status == 0 then
                if why then
                    why = '(' .. why .. ')'
                else
                    why = ''
                end
                if link == nil then
                    link = GetItemInfo(itemId)
                end
                if link == nil then
                    link = '???'
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
    local playerLevel = UnitLevel('player');
    local xp = UnitXP('player')

    str = str:lower()

    p1, p2 = str:find("^lucky *(%a*)$")
    p3, p4 = str:find("^sudo lucky$")
    if p1 or p3 then
        if CharSaved.challengeMode == 1 then
            printGood(whatAmI())
        else
            CharSaved.challengeMode = 1
            printGood(whatAmI() .. " - good luck! " .. colorText('ffffff', "You can use any looted items."))
            if playerLevel == 1 and xp == 0 then
                printWarning("You must have at least 1 XP before your choice will be saved for your next session")
            end
            checkInventory()
        end
        return
    end

    p1, p2 = str:find("^hardtack$")
    p3, p4 = str:find("^sudo hardtack$")
    if p1 or p3 then
        if CharSaved.challengeMode == 2 then
            printGood(whatAmI())
        else
            if CharSaved.challengeMode < 2 and playerLevel > MAX_LEVEL_TO_CHANGE_PLAY_MODE and p3 == nil then
                printWarning("Sorry, you cannot switch to hardtack mode after level " .. MAX_LEVEL_TO_CHANGE_PLAY_MODE)
                return
            end
            CharSaved.challengeMode = 2
            printGood(whatAmI() .. " - good luck! " .. colorText('ffffff', "You cannot use looted items (with some exceptions, of course)."))
            if CharSaved.isLazyBastard then
                CharSaved.isLazyBastard = false
                printWarning("Your lazy bastard challenge has been turned off")
            end
            if playerLevel == 1 and xp == 0 then
                printWarning("You must have at least 1 XP before your choice will be saved for your next session")
            end
            checkInventory()
        end
        return
    end

    p1, p2 = str:find("^craftsman$")
    p3, p4 = str:find("^sudo craftsman$")
    if p1 or p3 then
        if CharSaved.challengeMode == 3 then
            printGood(whatAmI())
        else
            if CharSaved.challengeMode < 3 and playerLevel > MAX_LEVEL_TO_CHANGE_PLAY_MODE and p3 == nil then
                printWarning("Sorry, you cannot switch to craftsman mode after level " .. MAX_LEVEL_TO_CHANGE_PLAY_MODE)
                return
            end
            CharSaved.challengeMode = 3
            printGood(whatAmI() .. " - good luck! " .. colorText('ffffff', "All items you use must be self-made."))
            if CharSaved.isLazyBastard then
                CharSaved.isLazyBastard = false
                printWarning("Your lazy bastard challenge has been turned off")
            end
            if playerLevel == 1 and xp == 0 then
                printWarning("You must have at least 1 XP before your choice will be saved for your next session")
            end
            checkInventory()
        end
        return
    end

    p1, p2 = str:find("^trailblazer$")
    p3, p4 = str:find("^sudo trailblazer$")
    if p1 or p3 then
        --if playerLevel > MAX_LEVEL_TO_CHANGE_PLAY_MODE and p3 == nil then
        --    printWarning("Sorry, you cannot change mountaineer achievements after level " .. MAX_LEVEL_TO_CHANGE_PLAY_MODE)
        --    return
        --end
        if p3 == nil then
            if not CharSaved.isTrailblazer then
                if CharSaved.did[429] then
                    printWarning("You have flown on a taxi, so you cannot be a trailblazer")
                    return
                end
                if CharSaved.did[895] then
                    printWarning("You have hearthed/teleported, so you cannot be a trailblazer")
                    return
                end
            end
        else
            CharSaved.did[429] = nil
            CharSaved.did[895] = nil
        end
        CharSaved.isTrailblazer = not CharSaved.isTrailblazer
        if CharSaved.isTrailblazer then
            printGood(whatAmI() .. " - good luck! " .. colorText('ffffff', "Delete your hearthstone. You cannot use flight paths. Normal vendor rules apply, but you are also allowed to use anything from a qualifying vendor who is in the open world. All traveling vendors qualify. Stationary vendors qualify if they are nowhere near a flight path."))
        else
            printGood(whatAmI() .. " - good luck! " .. colorText('ffffff', "Trailblazer mode off. You can use a hearthstone and flight paths, but you can no longer buy from open world vendors."))
        end
        if playerLevel == 1 and xp == 0 then
            printWarning("You must have at least 1 XP before your choice will be saved for your next session")
        end
        return
    end

    p1, p2 = str:find("^lazy$")
    p3, p4 = str:find("^sudo lazy$")
    if p1 or p3 then
        if not CharSaved.isLazyBastard and playerLevel > 9 and p3 == nil then
            printWarning("Sorry, you cannot become a lazy bastard after level 9")
            return
        end
        CharSaved.isLazyBastard = not CharSaved.isLazyBastard
        if CharSaved.isLazyBastard then
            if playerLevel <= 9 then
                printGood(whatAmI() .. " - good luck! " .. colorText('ffffff', "You are now a lazy bastard. BEFORE you reach level 10, you must drop your primary professions and never take another one while leveling. All primary professions can be taken, dropped, and retaken before level 10. All secondary professions are required throughout your run as usual."))
            else
                if playerHasAPrimaryProfession() then
                    printWarning("You must drop your primary profession(s) before becoming a lazy bastard.")
                    return
                end
                printGood(whatAmI() .. " - good luck! " .. colorText('ffffff', "You are now a lazy bastard and can no longer learn any primary professions."))
            end
            if CharSaved.challengeMode ~= 1 then
                CharSaved.challengeMode = 1
                printWarning("Your mountaineer mode has been changed to lucky.")
            end
        else
            printGood(whatAmI() .. " - good luck! " .. colorText('ffffff', "You are no longer a lazy bastard: you can learn any professions you want."))
        end
        if playerLevel == 1 and xp == 0 then
            printWarning("You must have at least 1 XP before your choice will be saved for your next session")
        end
        return
    end

    p1, p2 = str:find("^punchy$")
    p3, p4 = str:find("^sudo punchy$")
    if p1 or p3 then
        if not CharSaved.isPunchy then
            if p3 == nil then
                if CharSaved.did[779] then
                    printWarning("You cannot do the punchy achievement on this character since you have already failed it")
                    return
                end
            else
                CharSaved.did[779] = nil
            end
        end
        CharSaved.isPunchy = not CharSaved.isPunchy
        if CharSaved.isPunchy then
            printGood(whatAmI() .. " - good luck! " .. colorText('ffffff', "You must maintain your unarmed skill within 15 points of maximum at all times."))
        else
            printGood(whatAmI() .. " - good luck! " .. colorText('ffffff', "Punchy mode off."))
        end
        if playerLevel == 1 and xp == 0 then
            printWarning("You must have at least 1 XP before your choice will be saved for your next session")
        end
        checkSkills(true)
        return
    end

    p1, p2 = str:find("^made weapon$")
    if p1 then
        CharSaved.madeWeapon = not CharSaved.madeWeapon
        if CharSaved.madeWeapon then
            printGood("You are now marked as having made your self-crafted weapon, congratulations! " .. colorText('ffffff', "All your spells and abilities are unlocked."))
        else
            printGood("You are now marked as not yet having made your self-crafted weapon.")
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
        gSkillsAreReadyForLevel10 = completedLevel10Requirements()
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

    p1, p2, match = str:find("^lootwarn *(%a*)$")
    if p1 then
        match = string.lower(match)
        if match == 'on' or match == 'show' then
            setHideLootWarnings(false)
        elseif match == 'off' or match == 'hide' then
            setHideLootWarnings(true)
        else
            setHideLootWarnings(nil)
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
        initSavedVarsIfNec(true, true)
        printInfo("All allowed/disallowed designations reset to 'factory' settings")
        return
    end

--[[
=DUMP=
]]

    print(colorText('ffff00', "/mtn lucky/hardtack/craftsman"))
    print("   Switches you to lucky/hardtack/craftsman mountaineer mode.")

    print(colorText('ffff00', "/mtn trailblazer/lazy"))
    print("   Toggles the trailblazer and/or the lazy bastard achievement.")

    print(colorText('ffff00', "/mtn punchy"))
    print("   Toggles the punchy achievement.")

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

    print(colorText('ffff00', "/mtn verbose [on/off]"))
    print("   Turns verbose mode on or off. (Now " .. (AcctSaved.verbose and 'ON' or 'OFF') .. ")")
    print("   When on, you will see all evaluation messages when receiving items.")
    print("   When off, all \"item allowed\" messages will be suppressed, as well as \"item disallowed\" for gray items.")

    print(colorText('ffff00', "/mtn sound [on/off]"))
    print("   Turns addon sounds on or off. (Now " .. (AcctSaved.quiet and 'OFF' or 'ON') .. ")")

    print(colorText('ffff00', "/mtn minimap [on/off]"))
    print("   Turns the minimap on or off. (Now " .. (AcctSaved.showMiniMap and 'ON' or 'OFF') .. ")")

    print(colorText('ffff00', "/mtn lootwarn [on/off]"))
    print("   Turns on or off warnings if loot messages cannot be parsed. (Now " .. (CharSaved.hideLootWarnings and 'OFF' or 'ON') .. ")")

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

local function onPlayerEnteringWorld()

    initSavedVarsIfNec()

    local level = UnitLevel('player')
    local xp = UnitXP('player')

    gPlayerGUID = UnitGUID('player')

    printGood("Loaded - type /mtn to access options and features")

    -- If this is the first login for this character, clear all CharSaved
    -- values in case the player rolled a previous toon with the same name.
    if level == 1 and xp == 0 then
        initSavedVarsIfNec(false, true)
    end

    -- Prime the pump for getting spell subtext if needed somewhere later on.
    -- It looks like each spell has its own cache for subtext (spell ranks).
    for _, classId in ipairs(CLASS_IDS_ALPHABETICAL) do
        getUsableSpellNames(classId)
    end

    -- Get basic player information.

    PLAYER_LOC = PlayerLocation:CreateFromUnit("player")
    PLAYER_CLASS_NAME, _, PLAYER_CLASS_ID = C_PlayerInfo.GetClass(PLAYER_LOC)

    -- If the player just upgraded from before Craftsman, set the mode as appropriate.
    -- Mode 1=lucky, 2=hardtack, 3=craftsman.

    if CharSaved.challengeMode == nil and CharSaved.isLucky ~= nil then
        CharSaved.challengeMode = (CharSaved.isLucky) and 1 or 2
        CharSaved.isLucky = nil
    end

    -- In case the player is using old CharSaved data, set some appropriate defaults.

    if CharSaved.challengeMode  == nil then CharSaved.challengeMode = 1             end
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

    if CharSaved.did[501] then
        -- Do the following after a delay of a few seconds.
        C_Timer.After(6, function()
            playSound(I_HAVE_FAILED_SOUND)
            printWarning("Sorry, you have failed a previous requirement")
            printWarning("YOUR MOUNTAINEER CHALLENGE IS OVER")
            flashWarning("YOUR MOUNTAINEER CHALLENGE IS OVER")
        end)
        return
    end

    -- Let the user know what mode they're playing in.

    printGood(whatAmI())
    printInfo("For rules, go to http://tinyurl.com/hc-mountaineers")

    if level == 1 and xp < 200 then
        if CharSaved.challengeMode == 1 then
            printInfo("If you want to do the hardtack challenge, type " .. colorText('ffff00', "/mtn hardtack") .. " before reaching level " .. (MAX_LEVEL_TO_CHANGE_PLAY_MODE+1))
            printInfo("If you want to do the craftsman challenge, type " .. colorText('ffff00', "/mtn craftsman") .. " before reaching level " .. (MAX_LEVEL_TO_CHANGE_PLAY_MODE+1))
        end
        if not CharSaved.isPunchy then
            printInfo("If you want to do the punchy achievement, type " .. colorText('ffff00', "/mtn punchy") .. " before reaching level " .. (MAX_LEVEL_TO_CHANGE_PLAY_MODE+1))
        end
        if not CharSaved.isTrailblazer then
            printInfo("If you want to do the trailblazer achievement, type " .. colorText('ffff00', "/mtn trailblazer"))
        end
    end

    if CharSaved.madeWeapon then
        if level < 10 then
            printGood("You made your self-crafted weapon, so all abilities are available to you")
        end
    else
        if level >= 6 then
            printWarning("You have not yet made your self-crafted weapon - you need to do that before reaching level 10")
            printSpellsICanAndCannotUse()
        end
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


--local SLOT_AMMO = 0
--local SLOT_HEAD = 1
--local SLOT_NECK = 2
--local SLOT_SHOULDER = 3
--local SLOT_SHIRT = 4
--local SLOT_CHEST = 5
--local SLOT_WAIST = 6
--local SLOT_LEGS = 7
--local SLOT_FEET = 8
--local SLOT_WRIST = 9
--local SLOT_HANDS = 10
--local SLOT_FINGER_1 = 11
--local SLOT_FINGER_2 = 12
--local SLOT_TRINKET_1 = 13
--local SLOT_TRINKET_2 = 14
--local SLOT_BACK = 15
--local SLOT_MAIN_HAND = 16
--local SLOT_OFF_HAND = 17
--local SLOT_RANGED = 18


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
                    --if slot == SLOT_MAIN_HAND or slot == SLOT_OFF_HAND or slot == SLOT_RANGED or slot == SLOT_AMMO then
                    if true then
                        PickupInventoryItem(slot)
                        PutItemInBackpack()
                        printInfo("Unequipped " .. link .. " (" .. itemId .. ")")
                        nUnequipped = nUnequipped + 1
                        allowOrDisallowItem(itemId, false)
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
            gSkillsAreReadyForLevel10 = completedLevel10Requirements()
            checkInventory()

        end)

    end

    C_Timer.After(4, function()

        if AcctSaved.showMiniMap then
            print(" ")
            printInfo("Don't forget: Options > Interface > Display > Rotate Minimap")
            print(" ")
        end

    end)

end

local function onPlayerSkillUp(text)

    local playerLevel = UnitLevel('player')
    local _, _, skillName, skillLevel = text:find("Your skill in (.*) has increased to (.*)")

    if skillName ~= nil and skillLevel ~= nil then

        local key = skillName:lower()                                           --pdb('key:', key)
        skillLevel = tonumber(skillLevel)                                       --pdb('skillLevel:', skillLevel)

        if (key == 'first aid' or key == 'fishing' or key == 'cooking' or key == 'defense') or (CharSaved.isPunchy and (key == 'unarmed')) then

            local workComplete = false

                                                                                --pdb('gSkillsAreUpToDate:', gSkillsAreUpToDate)
                                                                                --pdb('gSkillsAreReadyForLevel10:', gSkillsAreReadyForLevel10)
            local readyForLevel10 = completedLevel10Requirements()              --pdb('readyForLevel10:', readyForLevel10)

            if not gSkillsAreUpToDate then
                local warningCount = checkSkills(true, true)                    --pdb('warningCount:', warningCount)
                if warningCount == 0 then
                    workComplete = true
                end
            elseif not gSkillsAreReadyForLevel10 and readyForLevel10 then
                printGood("Congratulations! You've completed all the Mountaineer requirements for level 10")
                workComplete = true
            end
                                                                                --pdb('workComplete:', workComplete)
            if workComplete then

                gSkillsAreUpToDate = true
                gSkillsAreReadyForLevel10 = true

                -- Repeat the check so the all-is-well message is displayed.
                checkSkills()

                -- Congratulate them with the "WORK COMPLETE" sound.
                PlaySoundFile(WORK_COMPLETE_SOUND)

            elseif skillLevel%5 == 0 then

                local skill = gSkills[key]
                if skill and skill.firstCheckLevel and skill.showWontHaveToImproveUntil then
                    local pLevel = skill.skillToPlayerLevel(skillLevel)         --pdb('pLevel:', pLevel)
                    if pLevel >= skill.firstCheckLevel then
                        printGood("You won't have to improve " .. skillName .. " until level " .. pLevel)
                    end
                end

            end

        end

    end

end

EventFrame:SetScript('OnEvent', function(self, event, ...)

    if event == 'PLAYER_ENTERING_WORLD' then

        onPlayerEnteringWorld()

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
                if guid ~= gLastLootSourceGUID then
                    gLastLootSourceGUID = guid
                    --pdb('[', i, ']', 'gLastLootSourceGUID:', gLastLootSourceGUID)
                end
            end

        end

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
            gSkillsAreReadyForLevel10 = completedLevel10Requirements()

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
                    or  { 33, 66 }

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
                                    printGood("All your spells and abilities are now unlocked.")
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
        --pdb("CHAT_MSG_LOOT", text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, unused, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)

        -- Do the following after a short delay.
        C_Timer.After(.3, function()

            local itemId, itemText = parseItemLink(text)
            local matched = false

            local _, _, itemLink = text:find(L['You receive loot'] .. ": (.*)%.")
            if not itemLink then
                -- Maybe it's a party member.
                _, _, itemLink = text:find(".* " .. L['receives loot'] .. ": (.*)%.")
            end
            if not matched and itemLink ~= nil then
                matched = true
                --pdb('match you receive loot')
                -- The LOOT_READY event has already fired and set gLastLootSourceGUID.
                local unitType, _, serverId, instanceId, zoneUID, unitId, spawnUID = strsplit("-", gLastLootSourceGUID)
                --pdb('unitType:', unitType)
                if unitType == 'GameObject' then
                    itemCanBeUsed(itemId, ITEM_SOURCE_GAME_OBJECT, unitId, true, afterItemCanBeUsed)
                elseif unitType == 'Item' then
                    itemCanBeUsed(itemId, ITEM_SOURCE_CONTAINER, unitId, true, afterItemCanBeUsed)
                else
                    itemCanBeUsed(itemId, ITEM_SOURCE_LOOTED, gLastUnitTargeted, true, afterItemCanBeUsed)
                end
            end

            local _, _, itemLink = text:find(L['You receive item'] .. ": (.*)%.")
            if not itemLink then
                -- Maybe it's a party member.
                _, _, itemLink = text:find(".* " .. L['receives item'] .. ": (.*)%.")
            end
            if not matched and itemLink ~= nil then
                matched = true
                --pdb('match you receive item')
                if gLastQuestUnitTargeted then
                    itemCanBeUsed(itemId, ITEM_SOURCE_REWARDED, gLastQuestUnitTargeted, true, afterItemCanBeUsed)
                elseif gLastMerchantUnitTargeted then
                    itemCanBeUsed(itemId, ITEM_SOURCE_PURCHASED, gLastMerchantUnitTargeted, true, afterItemCanBeUsed)
                else
                    itemCanBeUsed(itemId, nil, nil, true, afterItemCanBeUsed)
                end
            end

            local _, _, itemLink = text:find(L['You create'] .. ": (.*)%.")
            if not itemLink then
                -- Maybe it's a party member.
                _, _, itemLink = text:find(".* " .. L['creates'] .. ": (.*)%.")
            end
            if not matched and itemLink ~= nil then
                matched = true
                --pdb('match you create')
                itemCanBeUsed(itemId, ITEM_SOURCE_SELF_MADE, nil, true, afterItemCanBeUsed)
            end

            if not matched then
                local name = itemLink or 'item'
                if not CharSaved.hideLootWarnings then
                    printWarning("Unable to determine whether or not you can use " .. name .. " - check the localization strings in Mountaineer.lua")
                end
            end

        end)

    elseif event == 'CHAT_MSG_SKILL' then

        --pdb('CHAT_MSG_SKILL')

        local text = ...
        local playerLevel = UnitLevel('player')

        if playerLevel >= 3 then

            -- Do the following after a short delay.
            C_Timer.After(.3, function()
                onPlayerSkillUp(text)
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

                if not CharSaved.did[382] then
                    flashWarning("Are you sure you can revive?")
                    printWarning("If you're doing the \"All in the Family\" or \"I'm Special\" achievement, your pet is mortal and must be abandoned. If you're not doing either of these achievements, you may revive your pet.")
                    CharSaved.did[382] = true
                end

            elseif CharSaved.isTrailblazer then

                if gSpellsDisallowedForTrailblazer[spellId] then
                    printWarning("Trailblazers cannot use " .. (name or "that spell"))
                    flashWarning("You cannot cast " .. (name or "that spell"))
                    playSound(ERROR_SOUND_FILE)
                end

            elseif not spellIsAllowed(spellId) then

                printWarning("You cannot use " .. name .. " until you create and equip a self-crafted weapon (" .. spellId .. ")")
                flashWarning("You cannot use " .. name)
                playSound(ERROR_SOUND_FILE)

            end

        end)

    elseif event == 'UNIT_SPELLCAST_SUCCEEDED' then

        local name = getSpellName(gSpellIdBeingCast)                            --pdb('UNIT_SPELLCAST_SUCCEEDED', gSpellIdBeingCast, name)

        -- Do the following after a short delay.
        C_Timer.After(.1, function()

            if gSpellsDisallowedForTrailblazer[gSpellIdBeingCast] then

                CharSaved.did[895] = true                                       --pdb("895: hearth, Astral Recall, teleport, or portal")

                if CharSaved.isTrailblazer then
                    printWarning("Trailblazer mountaineers cannot hearth, Astral Recall, teleport, or portal")
                    printWarning("YOUR MOUNTAINEER CHALLENGE IS OVER")
                    flashWarning("YOUR MOUNTAINEER CHALLENGE IS OVER")
                    CharSaved.did[501] = true
                    if not gPlayedFailedSound then
                        playSound(I_HAVE_FAILED_SOUND)
                        gPlayedFailedSound = true
                    end
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
                printWarning("You cannot use " .. name .. " until you create and equip a self-crafted weapon (" .. spellId .. ")")
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
                    printWarning("You cannot use " .. name .. " until you create and equip a self-crafted weapon (" .. id .. ")")
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

