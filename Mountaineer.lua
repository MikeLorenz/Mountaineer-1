--[[
--------------------------------------------------------------------------------
Created v1 12/2021 by ManchegoMike (MSL) - https://github.com/ManchegoMike
Created v2 08/2022 by ManchegoMike (MSL)

http://tinyurl.com/hc-mountaineers
--------------------------------------------------------------------------------
--]]

-- These function as constants, but upon initialization they may be reset based on the current game version.
local MAX_LEVEL = 60
local MAX_SKILL = MAX_LEVEL * 5

-- The first player level where the run could end if their first aid, fishing,
-- cooking skills aren't up to the minimum requirement.
local FIRST_REQUIRED_SKILL_CHECK_PLAYER_LEVEL = 10

-- The skill rank required at the above player level.
local FIRST_REQUIRED_SKILL_CHECK_SKILL_RANK = FIRST_REQUIRED_SKILL_CHECK_PLAYER_LEVEL * 5

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

local PLAYER_LOC, PLAYER_CLASS_NAME, PLAYER_CLASS_ID

-- Used in CHAT_MSG_SKILL to let the player know immediately when all their skills are up to date.
local gSkillsAreUpToDate = false

SLASH_MOUNTAINEER1, SLASH_MOUNTAINEER2 = '/mountaineer', '/mtn'
SlashCmdList["MOUNTAINEER"] = function(str)

    local p1, p2, cmd, arg1
    local override = true

    p1, p2 = str:find("^sound +on$")
    if p1 then
        setQuiet(false)
        printInfo("Sound is now on")
        return
    end

    p1, p2 = str:find("^sound +off$")
    if p1 then
        setQuiet(true)
        printInfo("Sound is now off")
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

    p1, p2 = str:find("^reset everything$")
    if p1 ~= nil then
        initSavedVarsIfNec(true)
        printInfo("All allowed/disallowed designations reset to 'factory' settings")
        return
    end

    p1, p2 = str:find("^check$")
    if p1 ~= nil then
        local level = UnitLevel('player');
        local nWarnings = checkSkills(level)
        gSkillsAreUpToDate = (nWarnings == 0)
        checkEquippedItems()
        return
    end

    print("/mtn sound on/off")
    print("     Turns addon sounds on or off")
    print("/mtn check")
    print("     Checks your skills and currently equipped items for conformance.")
    print("/mtn allow {id/name/link}")
    print("     Allows you to use the item you specify, either by id# or name or link.")
    print("     Example:  \"/mtn allow 7005\",  \"/mtn allow Skinning Knife\"")
    print("/mtn disallow {id/name/link}")
    print("     Disallows the item you specify, either by id# or name or link.")
    print("     Example:  \"/mtn disallow 7005\",  \"/mtn disallow Skinning Knife\"")
    print("/mtn forget {id/name/link}")
    print("     Forgets any allow/disallow that might be set for the item you specify, either by id# or name or link.")
    print("     This will force the item to be re-evaluated then next time you loot or buy it.")
    print("     Example:  \"/mtn forget 7005\",  \"/mtn forget Skinning Knife\"")
    print("/mtn reset everything")
    print("     Resets all allowed/disallowed lists to their default state.")
    print("     This will lose all your custom allows & disallows and cannot be undone, so use with caution.")

end

local PUNCH_SOUND_FILE = "Interface\\AddOns\\Mountaineer\\Sounds\\SharpPunch.ogg"
local ERROR_SOUND_FILE = "Interface\\AddOns\\Mountaineer\\Sounds\\ErrorBeep.ogg"

local EventFrame = CreateFrame('frame', 'EventFrame')
EventFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
EventFrame:RegisterEvent('CHAT_MSG_LOOT')
EventFrame:RegisterEvent('CHAT_MSG_SKILL')
EventFrame:RegisterEvent('PLAYER_CAMPING')
EventFrame:RegisterEvent('PLAYER_LEVEL_UP')
EventFrame:RegisterEvent('PLAYER_XP_UPDATE')
EventFrame:RegisterEvent('PLAYER_UPDATE_RESTING')
EventFrame:RegisterEvent('PLAYER_EQUIPMENT_CHANGED')
EventFrame:RegisterEvent('PLAYER_REGEN_DISABLED')
EventFrame:RegisterEvent('UNIT_SPELLCAST_SENT')

EventFrame:SetScript('OnEvent', function(self, event, ...)

    if event == 'PLAYER_ENTERING_WORLD' then

        printInfo("Loaded - use /mtn or /mountaineer to access options and features")
        printInfo("For rules, go to http://tinyurl.com/hc-mountaineers")

        -- Check the WoW version and set constants accordingly.

        local version = GetBuildInfo()
        if version:sub(1, 2) == '1.' then
            -- Classic / vanilla
            MAX_LEVEL = 60
        elseif version:sub(1, 2) == '2.' then
            -- TBC
            MAX_LEVEL = 70
        elseif version:sub(1, 2) == '3.' then
            -- WotLK
            MAX_LEVEL = 80
        else
            printWarning("This addon only designed for WoW versions 1 through 3 -- version " .. version .. " is not supported")
        end
        MAX_SKILL = MAX_LEVEL * 5

        -- Hide the minimap. Mountaineer 2.0 rules do not allow maps.

        --MinimapCluster:Hide()

        -- Hide the left & right gryphons next to the main toolbar.

        --MainMenuBarLeftEndCap:Hide()
        --MainMenuBarRightEndCap:Hide()

        PLAYER_LOC = PlayerLocation:CreateFromUnit("player")
        PLAYER_CLASS_NAME, _, PLAYER_CLASS_ID = C_PlayerInfo.GetClass(PLAYER_LOC)

        -- MSL 2022-08-07
        -- I've expanded Mountaineer to include all classes except DKs.
        -- Previously we only allowed warriors, rogues, and hunters.

        if PLAYER_CLASS_ID == CLASS_DEATHKNIGHT then
            PlaySoundFile(ERROR_SOUND_FILE)
            printWarning(PLAYER_CLASS_NAME .. " is not a valid Mountaineer class")
            flashWarning(PLAYER_CLASS_NAME .. " is not a valid Mountaineer class")
            return
        end

        local level = UnitLevel('player')
        local xp = UnitXP('player')

        -- If the character is just starting out
        if level == 1 and xp < 200 then

            -- If no XP, give it a little time for the user to get rid of the intro dialog.
            local seconds = (xp == 0) and 5 or 1

            -- Do the following after a delay of a few seconds.
            C_Timer.After(seconds, function()

                -- Look at each character slot...
                local nUnequipped = 0
                for slot = 0, 18 do
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

                local nWarnings = checkSkills(level)
                gSkillsAreUpToDate = (nWarnings == 0)
                checkEquippedItems()

            end)

        end

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
            local nWarnings = checkSkills(level)
            gSkillsAreUpToDate = (nWarnings == 0)

        end)

    elseif event == 'PLAYER_XP_UPDATE' then

        -- Do the following after a short delay.
        C_Timer.After(1, function()

            local xp = UnitXP('player')
            local xpMax = UnitXPMax('player')
            local level = UnitLevel('player');

            if level >= FIRST_REQUIRED_SKILL_CHECK_PLAYER_LEVEL - 2 and xp > getXPFromLastGain() then

                local percentList = (level < FIRST_REQUIRED_SKILL_CHECK_PLAYER_LEVEL - 1)
                    and {33, 66}
                    or  {25, 50, 75, 85, 95}

                local percent1 = getXPFromLastGain() * 100 / xpMax
                local percent2 = xp * 100 / xpMax
                --print(" percent1=", percent1, " percent2=", percent2)

                if percent1 < percent2 then
                    for _, p in ipairs(percentList) do
                        if percent1 < p and percent2 >= p then
                            local warningCount = checkSkills(level, true)
                            if warningCount > 0 -- there's a potential problem, so maybe play the error sound
                            and p >= 50 -- only play the sound if player xp is past the halfway point for the level
                            and level >= FIRST_REQUIRED_SKILL_CHECK_PLAYER_LEVEL - 1 -- don't play the sound if level N is the first level check and we're still at level N-2
                            then
                                playSound(ERROR_SOUND_FILE)
                            end
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

        -- Do the following after a short delay.
        C_Timer.After(.3, function()

            local itemId, itemText = parseItemLink(text)

            local matched = false
            if not matched then
                local _, _, item = text:find("You receive loot: (.*)%.")
                if item ~= nil then
                    matched = true
                    --printGood("You can use " .. item .. " (" .. itemId .. ")")
                    local name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice = GetItemInfo(itemId)
                    if type == Enum.ItemClass.Container and subType == 0 then -- normal bag
                        local msg = "THE BLESSED RUN! " .. item
                        printGood(msg)
                        flashGood(msg)
                    end
                end
            end
            if not matched then
                local _, _, item = text:find("You receive item: (.*)%.")
                if item ~= nil then
                    matched = true
                    if not itemIsAllowed(itemId, mountaineersCanUseNonLootedItem) then
                        --playSound(ERROR_SOUND_FILE)
                        printWarning("You cannot use " .. item .. " (" .. itemId .. ")")
                        allowOrDisallowItem(itemId, false)
                    end
                end
            end
            if not matched then
                local _, _, item = text:find("You create: (.*)%.")
                if item ~= nil then
                    matched = true
                    -- Make sure the player is allowed to use this item, since they made it.
                    allowOrDisallowItem(itemId, true)
                end
            end

        end)

    elseif event == 'CHAT_MSG_SKILL' then

        local text = ...
        local level = UnitLevel('player')

        -- Do the following after a short delay.
        C_Timer.After(.3, function()

            local _, _, skill = text:find("Your skill in (.*) has increased")
            if skill ~= nil then
                skill = skill:lower()
                if skill == 'unarmed' or skill == 'first aid' or skill == 'fishing' or skill == 'cooking' then
                    if not gSkillsAreUpToDate then
                        local nWarnings = checkSkills(level, true, true)
                        if nWarnings == 0 then
                            -- If we're here, the player just transitioned to all skills being up to date.
                            gSkillsAreUpToDate = true
                            -- Repeat the check so the all-is-well message is displayed.
                            checkSkills(level)
                            -- Congratulate them with the "WORK COMPLETE" sound.
                            PlaySoundFile(558132)
                        end
                    end
                end
            end
        end)

    elseif event == 'UNIT_SPELLCAST_SENT' then

        local unitTarget, _, castGUID, spellId = ...

        -- Do the following after a short delay.
        C_Timer.After(.1, function()

            if PLAYER_CLASS_ID == CLASS_HUNTER and spellId == 982 then -- Revive Pet
                local msg = "Pets are mortal, you must abandon after reviving"
                printWarning(msg)
                flashWarning(msg)
                playSound(ERROR_SOUND_FILE)
            end

        end)

    end

end)

function parseItemLink(link)
    -- |cff9d9d9d|Hitem:3299::::::::20:257::::::|h[Fractured Canine]|h|r
    local _, _, id, text = link:find(".*|.*|Hitem:(%d+):.*|h%[(.*)%]|h|r")
    return id, text
end

function allowOrDisallowItem(itemStr, allow, userOverride)
    local name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent = GetItemInfo(itemStr)
    if not name then
        printWarning("Item not found: " .. arg1)
        return
    end
    local id, text = parseItemLink(link)
    if not id or not text then
        printWarning("Unable to parse item link: \"" .. link .. '"')
        return
    end
    initSavedVarsIfNec()
    if allow == nil then
        -- Special case, when passing allow==nil, it means clear the item from both the good and bad lists
        AcctSaved.badItems[id .. ''] = nil
        AcctSaved.goodItems[id .. ''] = nil
        if userOverride then printInfo(link .. ' (' .. id .. ') is now forgotten') end
    elseif allow then
        -- If the user is manually overriding an item to be good, put it on the good list.
        if userOverride then AcctSaved.goodItems[id .. ''] = true end
        AcctSaved.badItems[id .. ''] = nil
        if userOverride then printInfo(link .. ' (' .. id .. ') is now allowed') end
    else
        -- If the user is manually overriding an item to be bad, remove it from the good list.
        if userOverride then AcctSaved.goodItems[id .. ''] = nil end
        AcctSaved.badItems[id .. ''] = true
        if userOverride then printInfo(link .. ' (' .. id .. ') is now disallowed') end
    end
end

function setQuiet(tf)
    initSavedVarsIfNec()
    AcctSaved.quiet = tf
end

function initSavedVarsIfNec(force)
    if force or AcctSaved == nil then
        AcctSaved = {
            badItems = {},
            quiet = false,
            goodItems = {
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
            },
        }
    end
    if force or CharSaved == nil then
        CharSaved = {
            xpFromLastGain = 0,
        }
    end
end

function getXPFromLastGain()
    initSavedVarsIfNec()
    return CharSaved.xpFromLastGain
end

function setXPFromLastGain(xp)
    initSavedVarsIfNec()
    CharSaved.xpFromLastGain = xp
end

function string:beginsWith(token)
    return string.sub(self, 1, token:len()) == token
end

function colorText(hex6, text)
    return "|cFF" .. hex6 .. text .. "|r"
end

function flashWarning(text)
    UIErrorsFrame:AddMessage(text, 1.0, 0.5, 0.0, GetChatTypeIndex('SYSTEM'), 8);
end

function flashInfo(text)
    UIErrorsFrame:AddMessage(text, 1.0, 1.0, 1.0, GetChatTypeIndex('SYSTEM'), 8);
end

function flashGood(text)
    UIErrorsFrame:AddMessage(text, 0.0, 1.0, 0.0, GetChatTypeIndex('SYSTEM'), 8);
end

function printInfo(text)
    print(colorText('c0c0c0', "MOUNTAINEER: ") .. colorText('ffffff', text))
end

function printWarning(text)
    print(colorText('ff0000', "MOUNTAINEER: ") .. colorText('ff8000', text))
end

function printGood(text)
    print(colorText('0080FF', "MOUNTAINEER: ") .. colorText('00ff00', text))
end

-- Checks skills. Returns (warningCount, challengeIsOver).
function checkSkills(playerLevel, hideMessageIfAllIsWell, hideWarnings)
    -- These are the only skills we care about.
    local skills = {
        ['unarmed']   = { rank = 0, name = 'Unarmed' },
        ['cooking']   = { rank = 0, name = 'Cooking' },
        ['fishing']   = { rank = 0, name = 'Fishing' },
        ['first aid'] = { rank = 0, name = 'First Aid' },
    }

    -- Gather data on the above skills.
    for skillIndex = 1, GetNumSkillLines() do
        local skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, skillCostType, skillDescription = GetSkillLineInfo(skillIndex)
        if not isHeader then
            if skills[skillName:lower()] ~= nil then
                skills[skillName:lower()].rank = skillRank
            end
        end
    end

    local warningCount = 0
    local challengeIsOver = false

    -- Check the skill ranks against the expected rank.
    for _, skill in pairs(skills) do
        if skill.rank == 0 then
            if playerLevel >= FIRST_REQUIRED_SKILL_CHECK_PLAYER_LEVEL - 3 then
                warningCount = warningCount + 1
                if not hideWarnings then
                    printWarning("You must train " .. skill.name .. " and level it to " .. FIRST_REQUIRED_SKILL_CHECK_SKILL_RANK .. " before you ding " .. FIRST_REQUIRED_SKILL_CHECK_PLAYER_LEVEL)
                    flashWarning("You must train " .. skill.name)
                end
            end
        else
            if skill.name == "Unarmed" then
                if playerLevel >= 5 then
                    local minimumRank = playerLevel * 5 - 15
                    local minimumRankAtNextLevel = minimumRank + 5
                    if skill.rank < minimumRank then
                        warningCount = warningCount + 1
                        if not hideWarnings then
                            printWarning("Your " .. skill.name .. " skill is " .. skill.rank .. ". The minimum requirement at this level is " .. minimumRank .. ".")
                            printWarning("YOUR MOUNTAINEER CHALLENGE IS OVER")
                            flashWarning("YOUR MOUNTAINEER CHALLENGE IS OVER")
                            playSound(ERROR_SOUND_FILE)
                        end
                        challengeIsOver = true
                    elseif skill.rank < minimumRankAtNextLevel and playerLevel < MAX_LEVEL then
                        -- Warn if dinging will invalidate the run.
                        warningCount = warningCount + 1
                        if not hideWarnings then
                            printWarning("Your " .. skill.name .. " skill is " .. skill.rank .. ", but MUST be at least " .. minimumRankAtNextLevel .. " before you ding " .. (playerLevel + 1))
                        end
                    end
                end
            else
                local minimumRank = playerLevel * 5
                local minimumRankAtNextLevel = minimumRank + 5
                --print(" skill.name=", skill.name, " skill.rank=", skill.rank, " minimumRank=", minimumRank, " minimumRankAtNextLevel=", minimumRankAtNextLevel)
                if FIRST_REQUIRED_SKILL_CHECK_PLAYER_LEVEL - playerLevel > 3 then
                    -- Don't check if more than 3 levels away from the first required level.
                elseif FIRST_REQUIRED_SKILL_CHECK_PLAYER_LEVEL - playerLevel > 1 then
                    if skill.rank < FIRST_REQUIRED_SKILL_CHECK_SKILL_RANK then
                        warningCount = warningCount + 1
                        if not hideWarnings then
                            printWarning("Your " .. skill.name .. " skill is " .. skill.rank .. ", but MUST be at least " .. FIRST_REQUIRED_SKILL_CHECK_SKILL_RANK .. " before you ding " .. FIRST_REQUIRED_SKILL_CHECK_PLAYER_LEVEL)
                        end
                    end
                else
                    if skill.rank < minimumRank and playerLevel >= FIRST_REQUIRED_SKILL_CHECK_PLAYER_LEVEL then
                        -- At this level the player must be at least the minimum rank.
                        warningCount = warningCount + 1
                        if not hideWarnings then
                            printWarning("Your " .. skill.name .. " skill is " .. skill.rank .. ". The minimum requirement at this level is " .. minimumRank .. ".")
                            printWarning("YOUR MOUNTAINEER CHALLENGE IS OVER")
                            flashWarning("YOUR MOUNTAINEER CHALLENGE IS OVER")
                            playSound(ERROR_SOUND_FILE)
                        end
                        challengeIsOver = true
                    elseif skill.rank < minimumRankAtNextLevel and playerLevel < MAX_LEVEL then
                        -- Warn if dinging will invalidate the run.
                        warningCount = warningCount + 1
                        if not hideWarnings then
                            printWarning("Your " .. skill.name .. " skill is " .. skill.rank .. ", but MUST be at least " .. minimumRankAtNextLevel .. " before you ding " .. (playerLevel + 1))
                        end
                    end
                end
            end
        end
    end

    if warningCount == 0 and not hideMessageIfAllIsWell then
        printGood("All skills are up to date")
    end

    return warningCount, challengeIsOver
end

function checkEquippedItems()
    local warningCount = 0
    for slot = 0, 18 do
        local itemId = GetInventoryItemID("player", slot)
        -- If there's an item in the slot, check it.
        if not itemIsAllowed(itemId) then
            warningCount = warningCount + 1
            local _, link = GetItemInfo(itemId)
            printWarning(link .. " should be unequipped")
        end
    end

    if warningCount == 0 then
        printGood("All equipped items are OK")
    else
        playSound(ERROR_SOUND_FILE)
    end

    return warningCount
end

function getFreeSlotCount()
    local nFree = 0
    for bagId = 0, NUM_BAG_SLOTS do
        --print(" bagId=", bagId)
        local nSlots = GetContainerNumSlots(bagId)
        if nSlots > 0 then
            --if bagId > 0 then
            --    local invId = ContainerIDToInventoryID(bagId)
            --    local bagLink = GetInventoryItemLink("player", invId)
            --    --print(" bagLink=", bagLink)
            --end
            local bagFreeSlots, bagType = GetContainerNumFreeSlots(bagId)
            if bagType == 0 then
                nFree = nFree + bagFreeSlots
            end
        end
    end
    --print(" nFree=", nFree)
    return nFree
end

-- Returns the number of equipped bags, NOT INCLUDING the default backpack. Valid return range is 0-4.
function getBagCount()
    local nBags = 0
    for bagId = 1, NUM_BAG_SLOTS do
        --print(" bagId=", bagId)
        local nSlots = GetContainerNumSlots(bagId)
        if nSlots > 0 then
            nBags = nBags + 1
        end
    end
    --print(" nBags=", nBags)
    return nBags
end

function allBagSlotsAreFilled()
    return getBagCount() == 4
end

-- This function is used to decide on an item that we assume has already undergone the mountaineersCanUseNonLootedItem() test.
function itemIsAllowed(itemId, evaluationFunction)

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

-- This function is used to decide on an item the first time it's looted.
function mountaineersCanUseNonLootedItem(itemId)
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
        --print("Shields, librams, idols, totems, sigils, relics are allowed")
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

function playerHasItem(arg)
    if type(arg) == 'function' then
        for bag = 0, NUM_BAG_SLOTS do
            for slot = 1, GetContainerNumSlots(bag) do
                if arg(GetContainerItemID(bag, slot)) then
                    return true
                end
            end
        end
    elseif type(arg) == 'number' then
        for bag = 0, NUM_BAG_SLOTS do
            for slot = 1, GetContainerNumSlots(bag) do
                if GetContainerItemID(bag, slot) == arg then
                    return true
                end
            end
        end
    end
    return false
end

function playSound(path)
    initSavedVarsIfNec()
    if not AcctSaved.quiet then
        PlaySoundFile(path, "Master")
    end
end
