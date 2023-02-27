--[[
================================================================================

Created v1 12/2021 by ManchegoMike (MSL) -- https://www.twitch.tv/ManchegoMike
Created v2 08/2022 by ManchegoMike (MSL)

http://tinyurl.com/hc-mountaineers

================================================================================
]]

local ADDON_VERSION = '2.0.5' -- This should be the same as in the .toc file.

local PLAYER_LOC, PLAYER_CLASS_NAME, PLAYER_CLASS_ID

local PUNCH_SOUND_FILE = "Interface\\AddOns\\Mountaineer\\Sounds\\SharpPunch.ogg"
local ERROR_SOUND_FILE = "Interface\\AddOns\\Mountaineer\\Sounds\\ErrorBeep.ogg"

local gPlayerOpening = 0            -- 1=opening, 2=opened -- This is set when UNIT_SPELLCAST_SUCCEEDED fires on spell 3365 (Opening); set to 0 on LOOT_CLOSED
local gPlayerGUID = ''
local gLastUnitTargeted = nil
local gQuestInteraction = false
local gMerchantInteraction = false
local gLastLootSourceGUID = ''

-- Used in CHAT_MSG_SKILL to let the player know immediately when all their skills are up to date.
local gSkillsAreUpToDate = false

-- This list is shorter than before because I've done a better job of allowing items according to their categories.
local gNewDefaultGoodItems = {
    [ '2901'] = "used for profession and as a crude weapon", -- mining pick
    [ '3342'] = "looted from a chest", -- captain sander's shirt
    [ '3343'] = "looted from a chest", -- captain sander's booty bag
    [ '3344'] = "looted from a chest", -- captain sander's sash
    [ '5976'] = "basic item used for guilds", -- guild tabard
    [ '6256'] = "used for profession and as a crude weapon", -- fishing pole
    [ '6365'] = "used for profession and as a crude weapon", -- strong fishing pole
    [ '6529'] = "used for fishing", -- shiny bauble
    [ '6530'] = "used for fishing", -- nightcrawlers
    [ '6532'] = "used for fishing", -- bright baubles
    [ '6533'] = "used for fishing", -- aquadynamic fish attractor
    [ '7005'] = "used for profession and as a crude weapon", -- skinning knife
    ['52021'] = "made via engineering", -- Iceblade Arrow
    ['41164'] = "made via engineering", -- Mammoth Cutters
    ['41165'] = "made via engineering", -- Saronite Razorheads
    ['52020'] = "made via engineering", -- Shatter Rounds
    ['10512'] = "made via engineering", -- Hi-Impact Mithril Slugs
    ['15997'] = "made via engineering", -- Thorium Shells
    ['10513'] = "made via engineering", -- Mithril Gyro-Shot
    ['23772'] = "made via engineering", -- Fel Iron Shells
    [ '8067'] = "made via engineering", -- Crafted Light Shot
    [ '8068'] = "made via engineering", -- Crafted Heavy Shot
    [ '8069'] = "made via engineering", -- Crafted Solid Shot
    ['23773'] = "made via engineering", -- Adamantite Shells
    ['18042'] = "make Thorium Shells & trade with an NPC in TB or IF", -- Thorium Headed Arrow
    ['33803'] = "made via engineering", -- Adamantite Stinger
}

local gNewDefaultBadItems = {
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

local gDefaultGoodItems = {
    [  '159'] = true, -- refreshing spring water
    [  '765'] = true, -- silverleaf (herb)
    [  '785'] = true, -- mageroyal (herb)
    [ '1179'] = true, -- ice cold milk
    [ '1205'] = true, -- melon juice
    [ '1645'] = true, -- moonberry juice
    [ '1708'] = true, -- sweet nectar
    [ '2320'] = true, -- coarse thread
    [ '2321'] = true, -- fine thread
    [ '2324'] = true, -- bleach
    [ '2325'] = true, -- black dye
    [ '2447'] = true, -- peacebloom (herb)
    [ '2449'] = true, -- earthroot (herb)
    [ '2450'] = true, -- briarthorn (herb)
    [ '2452'] = true, -- swiftthistle (herb)
    [ '2453'] = true, -- bruiseweed (herb)
    [ '2593'] = true, -- flaks of stormwind tawny
    [ '2594'] = true, -- flagon of dwarven honeymead
    [ '2595'] = true, -- jug of badlands bourbon
    [ '2596'] = true, -- skin of dwarven stout
    [ '2604'] = true, -- red dye
    [ '2605'] = true, -- green dye
    [ '2665'] = true, -- stormwind seasoning herbs
    [ '2678'] = true, -- mild spices
    [ '2692'] = true, -- hot spices
    [ '2723'] = true, -- bottle of dalaran noir
    [ '2880'] = true, -- weak flux
    [ '2901'] = true, -- mining pick
    [ '2928'] = true, -- dust of decay
    [ '2930'] = true, -- essence of pain
    [ '3342'] = true, -- captain sander's shirt
    [ '3343'] = true, -- captain sander's booty bag
    [ '3344'] = true, -- captain sander's sash
    [ '3355'] = true, -- wild steelbloom (herb)
    [ '3356'] = true, -- kingsblood (herb)
    [ '3357'] = true, -- liferoot (herb)
    [ '3358'] = true, -- khadgar's whisker (herb)
    [ '3369'] = true, -- grave moss (herb)
    [ '3371'] = true, -- empty vial
    [ '3371'] = true, -- mpty vial
    [ '3372'] = true, -- leaded vial
    [ '3419'] = true, -- red rose
    [ '3420'] = true, -- black rose
    [ '3421'] = true, -- simple wildflowers
    [ '3422'] = true, -- beautiful wildflowers
    [ '3423'] = true, -- bouquet of white roses
    [ '3424'] = true, -- bouquet of black roses
    [ '3466'] = true, -- strong flux
    [ '3713'] = true, -- soothing spices
    [ '3777'] = true, -- lethargy root
    [ '3818'] = true, -- fadeleaf (herb)
    [ '3819'] = true, -- wintersbite (herb)
    [ '3820'] = true, -- stranglekelp (herb)
    [ '3821'] = true, -- goldthorn (herb)
    [ '3857'] = true, -- coal
    [ '4289'] = true, -- salt
    [ '4291'] = true, -- silken thread
    [ '4340'] = true, -- gray dye
    [ '4341'] = true, -- yellow dye
    [ '4342'] = true, -- purple dye
    [ '4470'] = true, -- simple wood
    [ '4471'] = true, -- flint and tinder
    [ '4536'] = true, -- shiny red apple
    [ '4625'] = true, -- firebloom (herb)
    [ '5042'] = true, -- red ribboned wrapping paper
    [ '5048'] = true, -- blue ribboned wrapping paper
    [ '5060'] = true, -- thieves' tools
    [ '5140'] = true, -- flash powder
    [ '5173'] = true, -- deathweed
    [ '5565'] = true, -- infernal stone
    [ '5956'] = true, -- blacksmith hammer
    [ '5976'] = true, -- guild tabard
    [ '6217'] = true, -- copper rod
    [ '6256'] = true, -- fishing pole
    [ '6260'] = true, -- blue dye
    [ '6261'] = true, -- orange dye
    [ '6365'] = true, -- strong fishing pole
    [ '6529'] = true, -- shiny bauble
    [ '6530'] = true, -- nightcrawlers
    [ '6532'] = true, -- bright baubles
    [ '6533'] = true, -- aquadynamic fish attractor
    [ '6953'] = true, -- verigan's fist (paladin quest)
    [ '6966'] = true, -- elunite axe (warrior quest)
    [ '6967'] = true, -- elunite sword (warrior quest)
    [ '6968'] = true, -- elunite hammer (warrior quest)
    [ '6969'] = true, -- elunite dagger (warrior quest)
    [ '6975'] = true, -- whirlwind axe (warrior quest)
    [ '6976'] = true, -- whirlwind warhammer (warrior quest)
    [ '6977'] = true, -- whirlwind sword (warrior quest)
    [ '6978'] = true, -- umbral axe (warrior quest)
    [ '6979'] = true, -- haggard's axe (warrior quest)
    [ '6980'] = true, -- haggard's dagger (warrior quest)
    [ '6981'] = true, -- umbral dagger (warrior quest)
    [ '6982'] = true, -- umbral mace (warrior quest)
    [ '6983'] = true, -- haggard's hammer (warrior quest)
    [ '6984'] = true, -- umbral sword (warrior quest)
    [ '6985'] = true, -- haggard's sword (warrior quest)
    [ '7005'] = true, -- skinning knife
    [ '7115'] = true, -- heirloom axe (warrior quest)
    [ '7116'] = true, -- heirloom dagger (warrior quest)
    [ '7117'] = true, -- heirloom hammer (warrior quest)
    [ '7118'] = true, -- heirloom sword (warrior quest)
    [ '7298'] = true, -- blade of cunning (rogue quest)
    [ '7326'] = true, -- thun'grim's axe (warrior quest)
    [ '7327'] = true, -- thun'grim's dagger (warrior quest)
    [ '7328'] = true, -- thun'grim's mace (warrior quest)
    [ '7329'] = true, -- thun'grim's sword (warrior quest)
    [ '8153'] = true, -- wildvine (herb)
    [ '8343'] = true, -- heavy silken thread
    [ '8766'] = true, -- morning glory dew
    [ '8831'] = true, -- purple lotus (herb)
    [ '8836'] = true, -- arthas' tears (herb)
    [ '8838'] = true, -- sungrass (herb)
    [ '8839'] = true, -- blindweed (herb)
    [ '8845'] = true, -- ghost mushroom (herb)
    [ '8846'] = true, -- gromsblood (herb)
    [ '8923'] = true, -- essence of agony
    [ '8924'] = true, -- dust of deterioration
    [ '8925'] = true, -- crystal vial
    [ '9517'] = true, -- celestial stave (mage quest)
    ['10290'] = true, -- pink dye
    ['10572'] = true, -- freezing shard (mage quest)
    ['10766'] = true, -- plaguerot sprig (mage quest)
    ['10938'] = true, -- lesser magic essence
    ['10940'] = true, -- strange dust
    ['11291'] = true, -- star wood
    ['13463'] = true, -- dreamfoil (herb)
    ['13464'] = true, -- golden sansam (herb)
    ['13465'] = true, -- mountain silversage (herb)
    ['13466'] = true, -- plaguebloom (herb)
    ['13467'] = true, -- icecap (herb)
    ['13468'] = true, -- black lotus (herb)
    ['14341'] = true, -- rune thread
    ['16583'] = true, -- demonic figurine
    ['17020'] = true, -- arcane powder
    ['17021'] = true, -- wild berries
    ['17026'] = true, -- wild thornroot
    ['17028'] = true, -- holy candle
    ['17029'] = true, -- sacred candle
    ['17030'] = true, -- ankh
    ['17031'] = true, -- rune of teleportation
    ['17032'] = true, -- rune of portals
    ['17033'] = true, -- symbol of divinity
    ['17034'] = true, -- maple seed
    ['17035'] = true, -- stranglethorn seed
    ['17036'] = true, -- ashwood seed
    ['17037'] = true, -- hornbeam seed
    ['17038'] = true, -- ironwood seed
    ['18256'] = true, -- imbued vial
    ['18567'] = true, -- elemental flux
    ['19726'] = true, -- bloodvine (herb)
    ['19727'] = true, -- blood scythe (herb)
    ['20815'] = true, -- jeweler's kit
    ['20824'] = true, -- simple grinder
    ['21177'] = true, -- symbol of kings
    ['22147'] = true, -- flintweed seed
    ['22148'] = true, -- wild quillvine
    ['22710'] = true, -- bloodthistle (herb)
    ['22785'] = true, -- felweed (herb)
    ['22786'] = true, -- dreaming glory (herb)
    ['22787'] = true, -- ragveil (herb)
    ['22788'] = true, -- flame cap (herb)
    ['22789'] = true, -- terocone (herb)
    ['22790'] = true, -- ancient lichen (herb)
    ['22791'] = true, -- netherbloom (herb)
    ['22792'] = true, -- nightmare vine (herb)
    ['22793'] = true, -- mana thistle (herb)
    ['22794'] = true, -- fel lotus (herb)
    ['22797'] = true, -- nightmare seed (herb)
    ['23420'] = true, -- engraved axe (warrior quest)
    ['23421'] = true, -- engraved sword (warrior quest)
    ['23422'] = true, -- engraved dagger (warrior quest)
    ['23423'] = true, -- mercenary greatsword (warrior quest)
    ['23429'] = true, -- mercenary clout (warrior quest)
    ['23430'] = true, -- mercenary sword (warrior quest)
    ['23431'] = true, -- mercenary stiletto (warrior quest)
    ['23432'] = true, -- engraved greatsword (warrior quest)
    ['24136'] = true, -- farstrider's bow (hunter quest)
    ['24138'] = true, -- silver crossbow (hunter quest)
    ['27860'] = true, -- purified draenic water
    ['28399'] = true, -- filtered draenic water
    ['30504'] = true, -- leafblade dagger (rogue quest)
    ['30817'] = true, -- simple flour
    ['33034'] = true, -- gordok grog
    ['33035'] = true, -- ogre mead
    ['33036'] = true, -- mudder's milk
    ['38518'] = true, -- cro's apple
}

--[[
================================================================================

Lua utility functions that are independent of WoW

================================================================================
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
================================================================================

WoW utility functions & vars that could be used by any WoW addon

================================================================================
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

local function parseItemLink(link)
    -- |cff9d9d9d|Hitem:3299::::::::20:257::::::|h[Fractured Canine]|h|r
    local _, _, id, text = link:find(".*|.*|Hitem:(%d+):.*|h%[(.*)%]|h|r")
    return id, text
end

--[[
================================================================================

Local vars and functions for this addon

================================================================================
]]

-- These will need to be localized if not enUS.
local L = {
    ["You receive loot"] = "You receive loot",
    ["You receive item"] = "You receive item",
    ["You create"] = "You create",
}

local ITEM_DISPOSITION_ALLOWED      = 1 -- /mtn allow, items fished, taken from chests, and self-made
local ITEM_DISPOSITION_DISALLOWED   = 2 -- /mtn disallow
local ITEM_DISPOSITION_LOOTED       = 3 -- items looted from mobs
local ITEM_DISPOSITION_REWARDED     = 4 -- items given as quest rewards
local ITEM_DISPOSITION_PURCHASED    = 5 -- items purchased from a vendor
local ITEM_DISPOSITION_TRAILBLAZER  = 6 -- items purchased from an approved trailblazer vendor

local functionQueue = Queue.new()

local function initSavedVarsIfNec(force)
    if force or AcctSaved == nil then
        AcctSaved = {
            badItems = {},
            quiet = false,
            goodItems = {},
            showMiniMap = false,
            hideGoodItems = false,
        }
        for k,v in pairs(gDefaultGoodItems) do
            AcctSaved.goodItems[k] = v
        end
    end
    if force or CharSaved == nil then
        CharSaved = {
            isLucky = true,
            isTrailblazer = false,
            dispositions = {}, -- table of item dispositions (key = itemId, value = ITEM_DISPOSITION_xxx)
            madeWeapon = false,
            xpFromLastGain = 0,
        }
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

local function dumpSpell(spellId)
    local name, rank, icon, castTime, minRange, maxRange = GetSpellInfo(spellId)
    print(name
        .. (rank and ' (rank ' .. tostring(rank) .. ')' or '')
        .. '  castTime=' .. tostring(castTime)
        .. '  minRange=' .. tostring(minRange)
        .. '  maxRange=' .. tostring(maxRange)
    )
end

local function dumpQuests()
    local i = 1
    local isClassQuest = false
    while GetQuestLogTitle(i) do
        local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle(i);
        if isHeader then
            printGood(title)
            isClassQuest = (title == PLAYER_CLASS_NAME)
        else
            printInfo("[" .. level .. "] " .. questID .. ": " .. title .. (isTask and " (task)" or " -") .. (isStory and " (story)" or " -") .. (isComplete and " (done)" or " -") .. (isClassQuest and " (class)" or " -"))
        end
        i = i + 1
    end
end

local function dumpBags()
    for bag = 0, NUM_BAG_SLOTS do
        if getContainerNumSlots(bag) > 0 then
            print("=== Bag " .. bag .. " ===")
            for slot = 1, getContainerNumSlots(bag) do
                local texture, stackCount, isLocked, quality, isReadable, hasLoot, hyperlink, isFiltered, hasNoValue, itemId, isBound = getContainerItemInfo(bag, slot)
                if texture then
                    print(tostring(hyperlink)
                        .. '  id='      .. tostring(itemId)
                        .. '  quality=' .. tostring(quality)
                        .. '  count='   .. tostring(stackCount)
                        .. '  texture=' .. tostring(texture)
                        .. (isLocked    and '  (locked)'    or '')
                        .. (isReadable  and '  (readable)'  or '')
                        .. (isFiltered  and '  (filtered)'  or '')
                        .. (isBound     and '  (bound)'     or '')
                        .. (hasNoValue  and '  (novalue)'   or '')
                    )
                end
            end
        end
    end
end

local function dumpInventory(unit)
    unit = unit or 'player'
    for slot = 0, 23 do -- need to iterate through every slot, this does not include items in bag I think, need to get the ID's for these from the emulator
        local itemId = GetInventoryItemID(unit, slot)
        local link = GetInventoryItemLink(unit, slot)
        if link then
            print(slot, itemId, link, printableLink(link))
        end
    end
end

local function dumpSkills()
    for i = 1, GetNumSkillLines() do
        local name, isHeader, isExpanded, rank, nTempPoints, modifier, maxRank, isAbandonable, stepCost, rankCost, minLevel, costType, desc = GetSkillLineInfo(i)
        print(name, isHeader, isExpanded, rank, nTempPoints, modifier, maxRank, isAbandonable, stepCost, rankCost, minLevel, costType, desc)
    end
end

local function whatAmI()
    initSavedVarsIfNec()
    return "You are a"
        .. (CharSaved.isLucky and " lucky" or " hardtack")
        .. (CharSaved.isLazyBastard and " lazy bastard" or "")
        .. (CharSaved.isTrailblazer and " trailblazing" or "")
        .. " mountaineer"
end

local function whichSpellsCanIUse(class)
    -- The string are used in this sentence: "You can only train and use ____"
    if class == CLASS_WARRIOR then
        if gameVersion() < 3 then
            return "Battle Shout, Battle Stance, Charge, Thunder Clap"
        else
            return "Battle Shout, Battle Stance, Charge, Thunder Clap, Victory Rush"
        end
    elseif class == CLASS_PALADIN then
        return "Blessing of Might, Devotion Aura, Divine Protection, Hammer of Justice, Holy Light, Purify, Seals"
    elseif class == CLASS_HUNTER then
        return "Aspect of the Monkey, Hunter's Mark, Tracking"
    elseif class == CLASS_ROGUE then
        return "Evasion, Pick Pocket, Stealth"
    elseif class == CLASS_PRIEST then
        return "Fade, Lesser Heal, Power Word Fortitude, Power Word Shield, Renew, Smite (Rank 1)"
    elseif class == CLASS_SHAMAN then
        return "All earth totems, Healing Wave, Lightning Bolt (Rank 1), Lightning Shield, Rockbiter Weapon"
    elseif class == CLASS_MAGE then
        return "Arcane Intellect, Conjure Food & Water, Fireball (Rank 1), Frost Armor, Polymorph"
    elseif class == CLASS_WARLOCK then
        return "Curse of Weakness, Demon Skin, Fear, Life Tap, Shadow Bolt (Rank 1)"
    elseif class == CLASS_DRUID then
        return "Healing Touch, Mark of the Wild, Rejuvenation, Thorns, Wrath (Rank 1)"
    else
        return "defensive abilities, or those that only cause damage at melee range, or do not require a melee weapon to be equipped"
    end
end

local function whichSpellsCanINotUse(class)
    -- The string are used in this sentence: "You cannot use ____"
    if class == CLASS_WARRIOR then
        return "Heroic Strike, Rend, Hamstring"
    elseif class == CLASS_PALADIN then
        return "Judgement"
    elseif class == CLASS_HUNTER then
        return "Arcane Shot, Concussive Shot, Serpent Sting"
    elseif class == CLASS_ROGUE then
        return "Backstab, Eviscerate, Gouge, Sinister Strike"
    elseif class == CLASS_PRIEST then
        return "Shadow Word Pain, Smite (Rank 2)"
    elseif class == CLASS_SHAMAN then
        return "Earth Shock, Lightning Bolt (Rank 2)"
    elseif class == CLASS_MAGE then
        return "Arcane Missiles, Fire Blast, Fireball (Rank 2), Frostbolt"
    elseif class == CLASS_WARLOCK then
        return "Corruption, Curse of Agony, Immolate, Shadow Bolt, Summon Imp"
    elseif class == CLASS_DRUID then
        return "Entangling Roots, Moonfire, Wrath (Rank 2)"
    else
        return "abilities that cause damage beyond melee range, or abilities that require a melee weapon to be equipped"
    end
end

local function printSpellsICanAndCannotUse()
    local level = UnitLevel('player');
    if CharSaved.madeWeapon then
        printGood("You have made your self-crafted weapon, so you can use any spells and abilities.")
    else
        printInfo("You can use " .. whichSpellsCanIUse(PLAYER_CLASS_ID) .. ".")
        printInfo("You cannot use " .. whichSpellsCanINotUse(PLAYER_CLASS_ID) .. ".")
    end
end

-- Allows or disallows an item (or forgets an item if allow == nil). Returns true if the item was found and modified. Returns false if there was an error.
local function allowOrDisallowItem(itemStr, allow, userOverride)
    local name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent = GetItemInfo(itemStr)
    if not name then
        printWarning("Item not found: " .. arg1)
        return false
    end
    local id, text = parseItemLink(link)
    if not id or not text then
        printWarning("Unable to parse item link: \"" .. link .. '"')
        return false
    end
    initSavedVarsIfNec()
    if allow == nil then
        -- Special case, when passing allow==nil, it means clear the item from both the good and bad lists
        AcctSaved.badItems[id] = nil
        if not gDefaultGoodItems[id] then
            AcctSaved.goodItems[id] = nil
        end
        if userOverride then printInfo(link .. ' (' .. id .. ') is now forgotten') end
    elseif allow then
        -- If the user is manually overriding an item to be good, put it on the good list.
        if userOverride then AcctSaved.goodItems[id] = true end
        AcctSaved.badItems[id] = nil
        if userOverride then printInfo(link .. ' (' .. id .. ') is now allowed') end
    else
        -- If the user is manually overriding an item to be bad, remove it from the good list.
        if gDefaultGoodItems[id] then
            if userOverride then printInfo(link .. ' (' .. id .. ') is always allowed & cannot be disallowed') end
            return false
        end
        if userOverride then AcctSaved.goodItems[id] = nil end
        AcctSaved.badItems[id] = true
        if userOverride then printInfo(link .. ' (' .. id .. ') is now disallowed') end
    end
    return true
end

-- This function is used to decide on an item the first time it's looted.
local function mountaineersCanUseNonLootedItem(itemId)
    itemId = tostring(itemId)
    local name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent = GetItemInfo(itemId)
    --print(" name=", name, " link=", link, " rarity=", rarity, " level=", level, " minLevel=", minLevel, " type=", type, " subType=", subType, " stackCount=", stackCount, " equipLoc=", equipLoc, " texture=", texture, " sellPrice=", sellPrice, " classId=", classId, " subclassId=", subclassId, " bindType=", bindType, " expacId=", expacId, " setId=", setId, " isCraftingReagent=", isCraftingReagent)
    local lname = name:lower();
    if classId == Enum.ItemClass.Questitem then
        --print("Quest items are allowed")
        return true
    end
    if classId == Enum.ItemClass.Tradegoods then
        --print("Trade goods are allowed")
        return true
    end
    if classId == Enum.ItemClass.Recipe then
        --print("Recipes are allowed")
        return true
    end
    if classId == Enum.ItemClass.Reagent then
        --print("Reagents are allowed")
        return true
    end
    if isCraftingReagent then
        --print("Crafting reagents are allowed")
        return true
    end
    if classId == Enum.ItemClass.Gem then
        --print("Gems are allowed")
        return true
    end
    if classId == Enum.ItemClass.Glyph then
        --print("Glyphs are allowed")
        return true
    end
    if classId == Enum.ItemClass.ItemEnhancement then
        --print("Item enhancements are allowed")
        return true
    end
    if classId == Enum.ItemClass.Weapon then
        --print("Skinning knives, mining picks, fishing poles, wands, staves, polearms are allowed")
        if subclassId == Enum.ItemWeaponSubclass.Generic
        or subclassId == Enum.ItemWeaponSubclass.Fishingpole
        or subclassId == Enum.ItemWeaponSubclass.Wand
        or subclassId == Enum.ItemWeaponSubclass.Staff
        or subclassId == Enum.ItemWeaponSubclass.Polearm
        or subclassId == Enum.ItemWeaponSubclass.Unarmed
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
            --print("Shields, librams, idols, totems, sigils, relics are allowed")
            return true
        end
        if subclassId == Enum.ItemArmorSubclass.Generic then
            if (equipLoc == INVTYPE_FINGER and gameVersion() >= 2)
            or (equipLoc == INVTYPE_NECK and gameVersion() >= 2)
            then
                --print("Armor that can be created via jewelcrafting is not allowed")
                return false
            else
                --print("Generic armor items are allowed (Spellstones, Firestones, Trinkets, Rings and Necks)")
                return true
            end
        end
    end
    if lname:find("^pattern: ") or lname:find("^formula: ") or lname:find("^recipe: ") or lname:find("^design: ") or lname:find("^plans: ") then
        --print("Recipes etc are allowed")
        return true
    end
    if lname:find("^inscription of ") then
        --print("Aldor/Scryer inscriptions allowed")
        return true
    end
    --print("Fell through to return false")
    return false
end

-- Checks skills. Returns 4 arrays of strings: fatals, warnings, reminders, exceptions.
-- Fatals are messages that the run is invalidated.
-- Warnings are messages that the run will be invalidated on the next ding.
-- Reminders are warnings that are 2+ levels away, so a ding is still OK.
-- Exceptions are unexpected error messages.
local function getSkillCheckMessages(hideMessageIfAllIsWell, hideWarnings)

    local fatals, warnings, reminders, exceptions = {}, {}, {}, {}

    -- These are the only skills we care about.
    local skills = {
        ['unarmed']   = { rank = 0, firstCheckLevel =  4, name = 'Unarmed' },
        ['first aid'] = { rank = 0, firstCheckLevel = 10, name = 'First Aid' },
        ['fishing']   = { rank = 0, firstCheckLevel = 10, name = 'Fishing' },
        ['cooking']   = { rank = 0, firstCheckLevel = 10, name = 'Cooking' },
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

    end

    return fatals, warnings, reminders, exceptions

end

-- Checks skills. Returns (warningCount, challengeIsOver).
-- The warning count is the number of skills that are low enough to either have
-- already invalidated the run, or *will* invalidate it when the player dings.
local function checkSkills(hideMessageIfAllIsWell, hideWarnings)

    local fatals, warnings, reminders, exceptions = getSkillCheckMessages()

    local warningCount = #fatals + #warnings
    local challengeIsOver = #fatals > 0

    if #exceptions > 0 then
        for i = 1, #exceptions do
            printWarning(exceptions[i])
        end
    else
        if not hideWarnings then
            if #fatals > 0 then
                for i = 1, #fatals do
                    printWarning(fatals[i])
                end
                printWarning("YOUR MOUNTAINEER CHALLENGE IS OVER")
                flashWarning("YOUR MOUNTAINEER CHALLENGE IS OVER")
                playSound(ERROR_SOUND_FILE)
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

    return warningCount, challengeIsOver

end

--[[
================================================================================

This group of 'itemIs...' and 'unitIs...' functions are used by the current
implementation of the Table of Usable Items. None of these functions use the
allowed or disallowed item lists.

They use itemInfo = {itemId, GetItemInfo(itemId)} as set in itemCanBeUsed().

================================================================================
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

local function itemIsAQuestItem(t)

    -- t is a table with the following fields: name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    return (t.classId == 12)

end

local function itemIsFoodOrDrink(t)

    -- t is a table with the following fields: name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent

    return (t.classId == 0 and t.subclassId == 5)

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
================================================================================

BEGIN Table of Usable Items (see the Mountaineer document)

This function can be called in one of two modes:
    No unitId arguments:
        This is typically from a player request about an item where we don't
        know how they got the item. The best we can do it see if it meets any
        of the special item criteria and advise them accordingly.
    Exactly one non-nil unitId argument:
        Given the origin of the item, the function can make a decision about
        whether the item is usable.

The function returns 3 values:
    Number:
        0=no, 1=yes, 2=it depends on the context.
        If exactly one unitId argument is passed, the value will be 0 or 1.
        If none are passed, the value will probably be 2.
    String:
        The link for the item
    String:
        If exactly one unitId argument is passed, the text should fit with
        this: Item allowed (...) or Item not allowed (...)
        If no unitId arguments are passed, the text is longer, providing a
        more complete explanation, as you might find in the document.

================================================================================
]]

local function itemCanBeUsed(itemId, lootedFromUnitId, rewardedByUnitId, purchasedFromUnitId, completionFunc)

    itemId = itemId or ''
    if itemId == '' or itemId == '0' then
        completionFunc(false, "", "no item id")
        return
    end

    --if not string.find(itemId, "^%d+$") then
    --    print("ITEM -> " .. itemId)
    --end

    initSavedVarsIfNec()

    -- Place detailed item information into an array of results so that each individual function we
    -- call doesn't have to call GetItemInfo, which gets its data from the server. Presumably the
    -- game is smart enough to cache it, but who knows.
    -- https://wowpedia.fandom.com/wiki/API_GetItemInfo
    GetItemInfo(itemId)

    -- Do the following after a short delay as a last resort in case GET_ITEM_INFO_RECEIVED never fires.
    C_Timer.After(.25, function()
        local func = Queue.pop(functionQueue)
        if func then
            func()
        end
    end)

    Queue.push(functionQueue, function ()

        local t = {}
        t.itemId = itemId
        t.name, t.link, t.rarity, t.level, t.minLevel, t.type, t.subType, t.stackCount, t.equipLoc, t.texture, t.sellPrice, t.classId, t.subclassId, t.bindType, t.expacId, t.setId, t.isCraftingReagent = GetItemInfo(itemId)
        --=--print("HI THERE: " .. ut.tfmt(t))

        --local itemInfo = {itemId, GetItemInfo(itemId)}
        --local id, name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent = unpack(itemInfo)

        -- If the item is already on the allowed list, we don't need to use any logic.
        if gNewDefaultGoodItems[itemId] then
            completionFunc(1, t.link, gNewDefaultGoodItems[itemId], link)
            return
        end

        -- If the item is already on the allowed list, we don't need to use any logic.
        --if AcctSaved.goodItems[itemId] then
        --    completionFunc(true, t.link, "on your allowed list")
        --    return
        --end

        -- Convenience booleans that make the code below a little easier to read.
        local isLooted    = (lootedFromUnitId    ~= nil)
        local isPurchased = (purchasedFromUnitId ~= nil)
        local isRewarded  = (rewardedByUnitId    ~= nil)

        -- Make sure there is ONE AND ONLY ONE source.
        local                 sourceCount = 0;
        if isLooted     then  sourceCount = sourceCount + 1  end
        if isPurchased  then  sourceCount = sourceCount + 1  end
        if isRewarded   then  sourceCount = sourceCount + 1  end
        if sourceCount > 1 then
            completionFunc(0, t.link, sourceCount .. " item sources were specified")
            return
        end

        if sourceCount == 0 then

            -- We don't know where the item came from.

            if itemIsReagentOrUsableForAProfession(t) then
                completionFunc(1, t.link, "reagents & items usable by a profession are always allowed")
                return
            end

            if itemIsADrink(t) then
                completionFunc(1, t.link, "drinks are always allowed")
                return
            end

            if itemIsAQuestItem(t) then
                completionFunc(1, t.link, "quest items are always allowed")
                return
            end

            if itemIsFoodOrDrink(t) then
                completionFunc(2, t.link, "food can be looted or accepted as quest rewards, but cannot be purchased; drinks are always allowed")
                return
            end

            if itemIsUncraftable(t) then
                completionFunc(2, t.link, "uncraftable items can be looted or accepted as quest rewards, but cannot be purchased")
                return
            end

            if itemIsRare(t) then
                completionFunc(2, t.link, "rare items can be looted, but cannot be purchased or accepted as quest rewards")
                return
            end

            if itemIsGray(t) == 0 then
                -- Grey items are always looted. You can't buy them or get them as quest rewards.
                if CharSaved.isLucky then
                    completionFunc(1, t.link, "lucky mountaineers can use any looted gray quality items")
                else
                    completionFunc(0, t.link, "hardtack mountaineers cannot use looted gray quality items")
                end
                return
            end

            if itemIsASpecialContainer(t) then
                completionFunc(2, t.link, "special containers can be accepted as quest rewards, but cannot be purchased or looted")
                return
            end

            if itemIsFromClassQuest(t) then
                completionFunc(2, t.link, "class quest rewards can be accepted")
                return
            end

            if CharSaved.isLucky then
                if CharSaved.isTrailblazer then
                    completionFunc(2, t.link, "lucky trailblazer mountaineers can only use this item if it is self-made, fished, looted, or purchased from an open-world vendor")
                else
                    completionFunc(2, t.link, "lucky mountaineers can only use this item if it is self-made, fished, or looted")
                end
                return
            else
                if CharSaved.isTrailblazer then
                    completionFunc(2, t.link, "hardtack trailblazer mountaineers can only use this item if it is self-made, fished, looted from a container or a rare mob, or purchased from an open-world vendor")
                else
                    completionFunc(2, t.link, "hardtack mountaineers can only use this item if it is self-made, fished, or looted from a container or a rare mob")
                end
                return
            end

        else

            -- We know where the item came from.

            if itemIsReagentOrUsableForAProfession(t) then
                completionFunc(1, t.link, "reagent / profession item")
                -- Don't need to save the item's disposition, since it's intrinsically allowed regardless of how it was received.
                return
            end

            if itemIsADrink(t) then
                completionFunc(1, t.link, "drink")
                -- Don't need to save the item's disposition, since it's intrinsically allowed regardless of how it was received.
                return
            end

            if itemIsAQuestItem(t) then
                completionFunc(1, t.link, "quest item")
                -- Don't need to save the item's disposition, since it's intrinsically allowed regardless of how it was received.
                return
            end

            if isPurchased then

                if CharSaved.isTrailblazer and unitIsOpenWorldVendor(purchasedFromUnitId) then
                    completionFunc(1, t.link, "trailblazer approved vendor")
                    CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_TRAILBLAZER
                    return
                end

                completionFunc(0, t.link, "vendor")
                CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_PURCHASED
                return

            end

            -- TODO: Need to figure out if the item came from a chest or fishing.

            if isLooted or isRewarded then

                if itemIsFoodOrDrink(t) then
                    completionFunc(1, t.link, "food")
                    CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_ALLOWED
                    return
                end

                if itemIsUncraftable(t) then
                    completionFunc(1, t.link, "uncraftable item")
                    CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_ALLOWED
                    return
                end

            end

            if isLooted then

                if CharSaved.isLucky then
                    if itemIsANormalBag(t) then
                        completionFunc(1, t.link, "THE BLESSED RUN!")
                        CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_LOOTED
                        return
                    end
                    completionFunc(1, t.link, "looted")
                    if t.rarity > 0 then
                        -- Don't save disposition if the item is gray. We know they are looted, and there's no need to pollute CharSaved with all the grays.
                        CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_LOOTED
                    end
                    return
                end

                if itemIsRare(t) then
                    completionFunc(1, t.link, "rare item")
                    CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_ALLOWED
                    return
                end

                if unitIsRare(lootedFromUnitId) then
                    completionFunc(1, t.link, "looted from rare mob")
                    CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_ALLOWED
                    return
                end

                completionFunc(0, t.link, "looted")
                if t.rarity > 0 then
                    -- Don't save disposition if the item is gray. We know they are looted, and there's no need to pollute CharSaved with all the grays.
                    CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_LOOTED
                end
                return

            end

            if isRewarded then

                if itemIsASpecialContainer(t) then
                    completionFunc(1, t.link, "special container")
                    CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_ALLOWED
                    return
                end

                if itemIsFromClassQuest(t) then
                    completionFunc(1, t.link, "class quest reward")
                    CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_ALLOWED
                    return
                end

                completionFunc(0, t.link, "quest reward")
                CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_REWARDED
                return

            end

            completionFunc(0, t.link, "failed all tests")
            CharSaved.dispositions[t.itemId] = ITEM_DISPOSITION_DISALLOWED
            return

        end

    end)

end

--[[
================================================================================

END Table of Usable Items (see the Mountaineer document)

================================================================================
]]

-- This function is used to decide on an item that we assume has already undergone the mountaineersCanUseNonLootedItem() test.
local function itemIsAllowed(itemId, evaluationFunction)

    if itemId == nil or itemId == 0 then return true end
    --print("itemIsAllowed("..itemId..")")

    itemId = tostring(itemId)
    initSavedVarsIfNec()

    -- Anything on the good list overrides anything on the bad list because the good list is only set by the player.
    if AcctSaved.goodItems[itemId] then
        --print("On the nice list")
        return true
    end

    -- If it's on the bad list, it's bad.
    if AcctSaved.badItems[itemId] then
        --print("On the naughty list")
        return false
    end

    if evaluationFunction then
        -- If there's an additional evaluation function, use that.
        local ret = evaluationFunction(itemId)
        --print("Evaluation function returned ", ret)
        return ret
    else
        -- If no additional evaluation is required, then assume it's allowed.
        --print("Fell through to return true")
        return true
    end

end

local function isItemAllowed(itemId)

    if not itemId then return false, "no item id" end

    initSavedVarsIfNec()

    -- If there's an item in the slot, check it.
    local name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent = GetItemInfo(itemId)
    local dispo = CharSaved.dispositions[itemId]
    if rarity == 0 then dispo = ITEM_DISPOSITION_LOOTED end

    if AcctSaved.goodItems and AcctSaved.goodItems[itemId] then
        -- All good (legacy data)
    elseif dispo == ITEM_DISPOSITION_ALLOWED then
        -- All good
    elseif AcctSaved.badItems and AcctSaved.badItems[itemId] then
        return false, "" -- (legacy data)
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

    return true

end

local function checkInventory()
    --  0 = ammo
    --  1 = head
    --  2 = neck
    --  3 = shoulder
    --  4 = shirt
    --  5 = chest
    --  6 = waist
    --  7 = legs
    --  8 = feet
    --  9 = wrist
    -- 10 = hands
    -- 11 = finger 1
    -- 12 = finger 2
    -- 13 = trinket 1
    -- 14 = trinket 2
    -- 15 = back
    -- 16 = main hand
    -- 17 = off hand
    -- 18 = ranged
    -- 19 = tabard
    -- 20 = first bag (the rightmost one)
    -- 21 = second bag
    -- 22 = third bag
    -- 23 = fourth bag (the leftmost one)

    local warningCount = 0
    for slot = 0, 18 do
        local itemId = GetInventoryItemID('player', slot)
        if itemId then
            -- If there's an item in the slot, check it.
            local ok, reason = isItemAllowed(itemId)
            if not ok then
                if reason then
                    reason = '(' .. reason .. ')'
                else
                    reason = ''
                end
                local name, link = GetItemInfo(itemId)
                printWarning(link .. " should be unequipped " .. reason)
                warningCount = warningCount + 1
            end
        end
    end

    if warningCount == 0 then
        printGood("All equipped items are OK")
    else
        playSound(ERROR_SOUND_FILE)
    end

    return warningCount
end

--[[
================================================================================

Parsing command line

================================================================================
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
            printGood("You are now marked as having made your self-crafted weapon, congratulations! " .. colorText('ffffff', "All your spells and abilities are now unlocked."))
        else
            printGood("You are now marked as not yet having made your self-crafted weapon. " .. colorText('ffffff', "You may only use the abilities you were \"born\" with, plus non-damanging spells and abilities."))
        end
        return
    end

    p1, p2, arg1 = str:find("^check +(.*)$")
    if p1 and arg1 then
        itemCanBeUsed(arg1, nil, nil, nil, function(ok, link, why)
            if ok == 0 then
                if not link then link = "That item" end
                printWarning(link .. " cannot be used (" .. why .. ")")
            elseif ok == 1 then
                if not link then link = "That item" end
                printGood(link .. " can be used (" .. why .. ")")
            else
                if link then
                    printInfo(link .. ": " .. why)
                else
                    printWarning("Unable to look up item - please try again")
                end
            end
        end)
        return
    end

    p1, p2 = str:find("^check$")
    if p1 then
        local level = UnitLevel('player');
        local warningCount = checkSkills()
        gSkillsAreUpToDate = (warningCount == 0)
        checkInventory()
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
        local name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent = GetItemInfo(arg1)
        if link == nil then
            printWarning("Item not found")
            return
        end
        local id, _ = parseItemLink(link)
        print(" id=", id, " name=", name, " rarity=", rarity, " level=", level, " minLevel=", minLevel, " type=", type, " subType=", subType, " stackCount=", stackCount, " equipLoc=", equipLoc, " texture=", texture, " sellPrice=", sellPrice, " classId=", classId, " subclassId=", subclassId, " bindType=", bindType, " expacId=", expacId, " setId=", setId, " isCraftingReagent=", isCraftingReagent)
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

    p1, p2 = str:find("^dq$")
    if p1 then
        dumpQuests()
        return
    end

    p1, p2 = str:find("^db$")
    if p1 then
        dumpBags()
        return
    end

    p1, p2 = str:find("^di$")
    if p1 then
        dumpInventory()
        return
    end

    p1, p2 = str:find("^ds$")
    if p1 then
        dumpSkills()
        return
    end

    p1, p2, arg1 = str:find("^spell +(.*)$")
    if p1 and arg1 then
        dumpSpell(arg1)
        return
    end

    print(colorText('ffff00', "/mtn lucky/hardtack"))
    print("     Switches you to lucky or hardtack mountaineer mode.")

    print(colorText('ffff00', "/mtn trailblazer/lazy"))
    print("     Toggles the trailblazer and/or the lazy bastard challenge.")

    print(colorText('ffff00', "/mtn check"))
    print("     Checks your skills and currently equipped items for conformance.")

    print(colorText('ffff00', "/mtn made weapon"))
    print("     Toggles whether or not you made your self-crafted weapon.")

    if CharSaved.madeWeapon then
        -- Nothing to print.
    else
        print(colorText('ffff00', "/mtn spells"))
        print("     Lists the abilities you may use before making your self-crafted weapon.")
    end

    print(colorText('ffff00', "/mtn version"))
    print("     Shows the current version of the addon.")

    print(colorText('ffff00', "/mtn sound [on/off]"))
    print("     Turns addon sounds on or off.")

    print(colorText('ffff00', "/mtn minimap [on/off]"))
    print("     Turns the minimap on or off.")

    print(colorText('ffff00', "/mtn check {id/name/link}"))
    print("     Checks an item to see if you can use it.")

    print(colorText('ffff00', "/mtn allow {id/name/link}"))
    print("     Allows you to use the item you specify, either by id# or name or link.")
    print("     Example:  \"/mtn allow 7005\",  \"/mtn allow Skinning Knife\"")

    print(colorText('ffff00', "/mtn disallow {id/name/link}"))
    print("     Disallows the item you specify, either by id# or name or link.")
    print("     Example:  \"/mtn disallow 7005\",  \"/mtn disallow Skinning Knife\"")

    print(colorText('ffff00', "/mtn forget {id/name/link}"))
    print("     Forgets any allow/disallow that might be set for the item you specify, either by id# or name or link.")
    print("     This will force the item to be re-evaluated then next time you loot or buy it.")
    print("     Example:  \"/mtn forget 7005\",  \"/mtn forget Skinning Knife\"")

    print(colorText('ffff00', "/mtn reset everything i really mean it"))
    print("     Resets all allowed/disallowed lists to their default state.")
    print("     This will lose all your custom allows & disallows and cannot be undone, so use with caution.")

end

--[[
================================================================================

Event processing

================================================================================
]]

local EventFrame = CreateFrame('frame', 'EventFrame')
EventFrame:RegisterEvent('CHAT_MSG_LOOT')
EventFrame:RegisterEvent('CHAT_MSG_SKILL')
EventFrame:RegisterEvent('GET_ITEM_INFO_RECEIVED')
EventFrame:RegisterEvent('ITEM_PUSH')
EventFrame:RegisterEvent('LOOT_CLOSED')
EventFrame:RegisterEvent('LOOT_READY')
EventFrame:RegisterEvent('LOOT_SLOT_CLEARED')
EventFrame:RegisterEvent('MERCHANT_CLOSED')
EventFrame:RegisterEvent('MERCHANT_SHOW')
EventFrame:RegisterEvent('PLAYER_CAMPING')
EventFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
EventFrame:RegisterEvent('PLAYER_EQUIPMENT_CHANGED')
EventFrame:RegisterEvent('PLAYER_LEVEL_UP')
EventFrame:RegisterEvent('PLAYER_REGEN_DISABLED')
EventFrame:RegisterEvent('PLAYER_TARGET_CHANGED')
EventFrame:RegisterEvent('PLAYER_UPDATE_RESTING')
EventFrame:RegisterEvent('PLAYER_XP_UPDATE')
EventFrame:RegisterEvent('QUEST_COMPLETE')
EventFrame:RegisterEvent('QUEST_DETAIL')
EventFrame:RegisterEvent('QUEST_FINISHED')
EventFrame:RegisterEvent('QUEST_PROGRESS')
EventFrame:RegisterEvent('UNIT_SPELLCAST_INTERRUPTED')
EventFrame:RegisterEvent('UNIT_SPELLCAST_SENT')
EventFrame:RegisterEvent('UNIT_SPELLCAST_STOP')
EventFrame:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')

EventFrame:SetScript('OnEvent', function(self, event, ...)

    if event == 'PLAYER_ENTERING_WORLD' then

        initSavedVarsIfNec()

        local level = UnitLevel('player')
        local xp = UnitXP('player')

        gPlayerGUID = UnitGUID('player')

        printInfo("Loaded - type /mtn to access options and features")
        printInfo("For rules, go to http://tinyurl.com/hc-mountaineers")

        -- Get basic player information.

        PLAYER_LOC = PlayerLocation:CreateFromUnit("player")
        PLAYER_CLASS_NAME, _, PLAYER_CLASS_ID = C_PlayerInfo.GetClass(PLAYER_LOC)

        -- In case the player is using old CharSaved data, set some appropriate defaults.

        if CharSaved.isLucky        == nil then CharSaved.isLucky       = true          end
        if CharSaved.isTrailblazer  == nil then CharSaved.isTrailblazer = false         end
        if CharSaved.madeWeapon     == nil then CharSaved.madeWeapon    = (level >= 10) end
        if CharSaved.dispositions   == nil then CharSaved.dispositions  = {}            end

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

        -- Make sure that every default good item is on the current good list and off the bad list.

        for k,v in pairs(gDefaultGoodItems) do
            AcctSaved.goodItems[k] = v
            AcctSaved.badItems[k] = nil
        end

        -- If the character is just starting out
        if level == 1 and xp < 200 then

            -- If no XP, give it a little time for the user to get rid of the intro dialog.
            local seconds = (xp == 0) and 5 or 1

            -- Do the following after a delay of a few seconds.
            C_Timer.After(seconds, function()

                -- Look at each weapon slot (16=mainhand, 17=offhand, 18=ranged)...
                -- (Prior to 2022-12-13, all items were stripped. Now it's just weapons.)
                local nUnequipped = 0
                for slot = 16, 18 do
                    local itemId = GetInventoryItemID("player", slot)
                    -- If there's an item in the slot, the player must remove it.
                    if itemId ~= nil and itemId ~= 0 then
                        local name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice = GetItemInfo(itemId)
                        --print (" slot=", slot, " itemId=", itemId, " name=", name, " link=", link, " rarity=", rarity, " level=", level, " minLevel=", minLevel, " type=", type, " subType=", subType, " stackCount=", stackCount, " equipLoc=", equipLoc, " texture=", texture, " sellPrice=", sellPrice)
                        allowOrDisallowItem(itemId, false)
                        PickupInventoryItem(slot)
                        PutItemInBackpack()
                        printInfo("Unequipped " .. link)
                        nUnequipped = nUnequipped + 1
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

        gQuestInteraction = true
        --=--printInfo("Quest interaction begun with " .. tostring(gLastUnitTargeted))

    elseif event == 'QUEST_FINISHED' then

        gQuestInteraction = false
        --=--printInfo("Quest interaction ended")

    elseif event == 'MERCHANT_SHOW' then

        gMerchantInteraction = true
        --=--printInfo("Merchant interaction begun with " .. tostring(gLastUnitTargeted))

    elseif event == 'MERCHANT_CLOSED' then

        gMerchantInteraction = false
        --=--printInfo("Merchant interaction ended")

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

            --local icon, name, count, currencyID, quality, isLocked, isQuestItem, questID, startsANewQuest = GetLootSlotInfo(i)

            --itemCanBeUsed(arg1, unitId, nil, nil, function(ok, link, why)
            --    if ok == 0 then
            --        if not link then link = "That item" end
            --        printWarning(link .. " cannot be used: " .. why)
            --    elseif ok == 1 then
            --        if not link then link = "That item" end
            --        printGood(link .. " can be used: " .. why)
            --    else
            --        if link then
            --            printInfo(link .. ": " .. why)
            --        else
            --            printWarning("Unable to look up item - please try again")
            --        end
            --    end
            --end)

        end

        --if not skipLoot then
        --    printInfo("Loot table (" .. gLastLootSourceGUID .. ")")
        --    print(ut.tfmt(lootTable))
        --end

        --=--for i = 1, #lootTable do
        --=--    print(ut.tfmt(lootTable[i]))
        --=--end

    elseif event == 'LOOT_SLOT_CLEARED' then

    elseif event == 'LOOT_CLOSED' then

        -- In case the item being looted is a chest or other item that was opened, we turn off this flag.
        gPlayerOpening = 0
        --=--printGood("Closed it")

    elseif event == 'ITEM_PUSH' then

        --=--local bag, texturePushed = ...
        --=--if bag >= 0 then
        --=--    printInfo("Item added to bag " .. bag .. " (" .. texturePushed .. ")")
        --=--    -- Do the following after a short delay.
        --=--    C_Timer.After(.3, function()
        --=--        local nSlots = getContainerNumSlots(bag)
        --=--        for slot = 1, nSlots do
        --=--            local texture, stackCount, isLocked, quality, isReadable, hasLoot, hyperlink, isFiltered, hasNoValue, itemId, isBound = getContainerItemInfo(bag, slot)
        --=--            if texture and tostring(texture) == tostring(texturePushed) then
        --=--                print('Pushed ' .. tostring(hyperlink)
        --=--                    .. '  id='      .. tostring(itemId)
        --=--                    .. '  quality=' .. tostring(quality)
        --=--                    .. '  count='   .. tostring(stackCount)
        --=--                    .. (isLocked    and '  (locked)'    or '')
        --=--                    .. (isReadable  and '  (readable)'  or '')
        --=--                    .. (isFiltered  and '  (filtered)'  or '')
        --=--                    .. (isBound     and '  (bound)'     or '')
        --=--                    .. (hasNoValue  and '  (novalue)'   or '')
        --=--                )
        --=--            end
        --=--        end
        --=--    end)
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
                --printInfo("Targeting NPC " .. name .. " (" .. unitId .. ")")
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

            local nBadItems = 0
            local name, link

            -- Look at each character slot...
            for slot = 0, 18 do
                local itemId = GetInventoryItemID("player", slot)
                -- If there's an item in the slot, check it.
                if not itemIsAllowed(itemId) then
                    nBadItems = nBadItems + 1
                    name, link = GetItemInfo(itemId)
                    printWarning("Unequip " .. link)
                end
            end

            if nBadItems > 0 then
                playSound(ERROR_SOUND_FILE)
                if nBadItems == 1 then
                    flashWarning("Unequip " .. name)
                else
                    flashWarning("Unequip " .. nBadItems .. " disallowed items")
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

            local fatals, warnings, reminders, exceptions = getSkillCheckMessages()

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

    elseif event == 'PLAYER_CAMPING' then

        -- MSL 2022-08-07
        -- I noticed this was commented out, and my hunch is that by the time
        -- this code is executed, if the player is in a rested XP area, they
        -- have already logged out and it's too late to show the warning.

        --if IsResting() then
        --    local msg = "You should logout in the great outdoors after starting a campfire"
        --    printInfo(msg)
        --    flashInfo(msg)
        --else
        --    printGood("Camping approved")
        --end

    elseif event == 'PLAYER_EQUIPMENT_CHANGED' then

        local slot, isEmpty = ...

        -- Do the following after a short delay.
        C_Timer.After(.3, function()

            if not isEmpty and slot >= 0 and slot <= 18 then

                local itemId = GetInventoryItemID("player", slot)

                if not itemIsAllowed(itemId) then
                    local name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice = GetItemInfo(itemId)
                    local msg = "You cannot equip " .. link
                    playSound(ERROR_SOUND_FILE)
                    printWarning(msg)
                    flashWarning(msg)
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

            if not matched then
                local _, _, itemLink = text:find(L['You receive loot'] .. ": (.*)%.")
                if itemLink ~= nil then
                    matched = true
                    -- The LOOT_READY event has already fired and set gLastLootSourceGUID.
                    local unitType, _, serverId, instanceId, zoneUID, unitId, spawnUID = strsplit("-", gLastLootSourceGUID)
                    if unitType == 'GameObject' then
                        -- We don't know 100% for sure, but it's very likely this item is looted from a chest or something similar, so we allow it.
                        if tonumber(unitId) == 35591 then
                            printGood(itemLink .. " can be used (via fishing)")
                        else
                            printGood(itemLink .. " can be used (via container)")
                        end
                    else
                        itemCanBeUsed(itemId, gLastUnitTargeted, nil, nil, function(ok, link, why)
                            if ok == 0 then
                                if not link then link = "That item" end
                                printWarning(link .. " cannot be used (" .. why .. ")")
                            elseif ok == 1 then
                                if not link then link = "That item" end
                                printGood(link .. " can be used (" .. why .. ")")
                            else
                                if link then
                                    printInfo(link .. ": " .. why)
                                else
                                    printWarning("Unable to look up item - please try again")
                                end
                            end
                        end)
                    end
                end
            end

            if not matched then
                local _, _, itemLink = text:find(L['You receive item'] .. ": (.*)%.")
                if itemLink ~= nil then
                    matched = true
                    local questSource, merchantSource = nil, nil
                    if gQuestInteraction then
                        questSource = gLastUnitTargeted
                    elseif gMerchantInteraction then
                        merchantSource = gLastUnitTargeted
                    end
                    itemCanBeUsed(itemId, nil, questSource, merchantSource, function(ok, link, why)
                        if ok == 0 then
                            if not link then link = "That item" end
                            printWarning(link .. " cannot be used (" .. why .. ")")
                        elseif ok == 1 then
                            if not link then link = "That item" end
                            printGood(link .. " can be used (" .. why .. ")")
                        else
                            if link then
                                printInfo(link .. ": " .. why)
                            else
                                printWarning("Unable to look up item - please try again")
                            end
                        end
                    end)
                end
            end

            if not matched then
                local _, _, itemLink = text:find(L['You create'] .. ": (.*)%.")
                if itemLink ~= nil then
                    matched = true
                    -- Make sure the player is allowed to use this itemLink, since they made it.
                    allowOrDisallowItem(itemId, true)
                end
            end

            if not matched then
                printWarning("Unable to determine whether or not you can use " .. itemLink)
            end

        end)

    elseif event == 'CHAT_MSG_SKILL' then

        local text = ...
        local level = UnitLevel('player')

        if level >= 5 then
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
                                PlaySoundFile(558132)
                            end
                        end
                    end
                end
            end)
        end

    elseif event == 'UNIT_SPELLCAST_SENT' then

        local unitTarget, _, castGUID, spellId = ...

        -- Do the following after a short delay.
        C_Timer.After(.1, function()

            if unitTarget == 'player' and spellId == 3365 then
                gPlayerOpening = 1
                printGood("Opening something")
            end

            if PLAYER_CLASS_ID == CLASS_HUNTER and spellId == 982 then -- Revive Pet
                local msg = "Pets are mortal, you must abandon after reviving"
                printWarning(msg)
                flashWarning(msg)
                playSound(ERROR_SOUND_FILE)
            end

        end)

    elseif event == 'UNIT_SPELLCAST_SUCCEEDED' then

        local unitTarget, _, castGUID, spellId = ...
        --printGood("UNIT_SPELLCAST_SUCCEEDED " .. unitTarget .. " " .. tostring(spellId))

        if unitTarget == 'player' and gPlayerOpening == 1 then -- Opening
            -- This happens when the player is opening something like a chest.
            gPlayerOpening = 2
            printGood("Opened something")
        end

    elseif event == 'UNIT_SPELLCAST_STOP' or event == 'UNIT_SPELLCAST_INTERRUPTED' then

        gPlayerOpening = 0
        --=--printGood("Closed it")

    elseif event == 'GET_ITEM_INFO_RECEIVED' then


        local func = Queue.pop(functionQueue)
        if func then
            --print('GET_ITEM_INFO_RECEIVED')
            func()
        end

    end

end)
