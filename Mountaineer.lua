--[[
Created 12/2021 by ManchegoMike - https://github.com/ManchegoMike
--]]

local MAX_LEVEL = 60
local MAX_SKILL = 300

local FIRST_REQUIRED_SKILL_CHECK_PLAYER_LEVEL = 10  -- The first player level where the run could end if their first aid, fishing, cooking skills aren't up to the minimum requirement.
local FIRST_REQUIRED_SKILL_CHECK_SKILL_RANK = FIRST_REQUIRED_SKILL_CHECK_PLAYER_LEVEL * 5  -- The skill rank required at the above player level.

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

local RACE_HUMAN = 1
local RACE_ORC = 2
local RACE_DWARF = 3
local RACE_NIGHT = 4
local RACE_UNDEAD = 5
local RACE_TAUREN = 6
local RACE_GNOME = 7
local RACE_TROLL = 8

local PLAYER_LOC, PLAYER_RACE_ID, PLAYER_RACE_NAME, PLAYER_CLASS_NAME, PLAYER_CLASS_ID

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
        checkSkills(level, true)
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

        PLAYER_LOC = PlayerLocation:CreateFromUnit("player")
        PLAYER_RACE_ID = C_PlayerInfo.GetRace(PLAYER_LOC)
        PLAYER_RACE_NAME = C_CreatureInfo.GetRaceInfo(PLAYER_RACE_ID).raceName
        PLAYER_CLASS_NAME, _, PLAYER_CLASS_ID = C_PlayerInfo.GetClass(PLAYER_LOC)

        if not (PLAYER_CLASS_ID == CLASS_WARRIOR or PLAYER_CLASS_ID == CLASS_ROGUE or PLAYER_CLASS_ID == CLASS_HUNTER) then
            PlaySoundFile(ERROR_SOUND_FILE)
            printWarning(PLAYER_CLASS_NAME .. " is not a valid Mountaineer class. You can only be a warrior, rogue, or hunter.")
            flashWarning(PLAYER_CLASS_NAME .. " is not a valid Mountaineer class")
            return
        end

        local level = UnitLevel('player');
        local xp = UnitXP('player');

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
                    if PLAYER_RACE_ID == RACE_HUMAN or PLAYER_RACE_ID == RACE_GNOME or PLAYER_RACE_ID == RACE_DWARF then
                        printInfo("Time to punch some wolves!  :)")
                    elseif PLAYER_RACE_ID == RACE_ORC or PLAYER_RACE_ID == RACE_TROLL then
                        printInfo("Time to punch some pigs!  :)")
                    elseif PLAYER_RACE_ID == RACE_NIGHT then
                        printInfo("Time to punch some pigs and cats!  :)")
                    elseif PLAYER_RACE_ID == RACE_TAUREN then
                        printInfo("Time to punch some birds!  :)")
                    elseif PLAYER_RACE_ID == RACE_UNDEAD then
                        printInfo("Time to punch some zombies!  :)")
                    else
                        printInfo("Time to do some punching!  :)")
                    end
                end

            end)

        else

            -- Do the following after a short delay.
            C_Timer.After(1, function()

                checkSkills(level, true)
                checkEquippedItems()

            end)

        end

    elseif event == 'PLAYER_REGEN_DISABLED' then

        -- Fired whenever you enter combat, as normal regen rates are disabled during combat.
        -- This means that either you are in the hate list of a NPC or that you've been taking part in a pvp action (either as attacker or victim).

        -- Do the following after a short delay.
        C_Timer.After(.3, function()

            local nBadItems = 0
            local badLink = ''

            -- Look at each character slot...
            for slot = 0, 18 do
                local itemId = GetInventoryItemID("player", slot)
                -- If there's an item in the slot, check it.
                if not itemIsAllowed(itemId) then
                    nBadItems = nBadItems + 1
                    if nBadItems == 1 then
                        local name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice = GetItemInfo(itemId)
                        badLink = link
                    end
                end
            end

            if nBadItems > 0 then
                local msg
                if nBadItems == 1 then
                    msg = badLink .. " should be unequipped"
                else
                    msg = nBadItems .. " disallowed items should be unequipped"
                end
                playSound(ERROR_SOUND_FILE)
                printWarning(msg)
                flashWarning(msg)
            end

        end)

    elseif event == 'PLAYER_LEVEL_UP' then

        local level, hp, mana, tp, str, agi, sta, int, spi = ...

        -- Do the following after a short delay.
        C_Timer.After(1, function()

            --print(" level=", level, " hp=", hp, " mana=", mana, " tp=", tp, " str=", str, " agi=", agi, " sta=", sta, " int=", int, " spi=", spi)
            checkSkills(level, true)

        end)

    elseif event == 'PLAYER_XP_UPDATE' then

        -- Do the following after a short delay.
        C_Timer.After(1, function()

            local xp = UnitXP('player')
            local xpMax = UnitXPMax('player')
            local level = UnitLevel('player');

            if level >= FIRST_REQUIRED_SKILL_CHECK_PLAYER_LEVEL - 2 and xp > getXPFromLastGain() then

                local percent1 = getXPFromLastGain() * 100 / xpMax
                local percent2 = xp * 100 / xpMax
                --print(" percent1=", percent1, " percent2=", percent2)

                if percent1 < percent2 then
                    for _, p in ipairs({ 20, 40, 60, 70, 80, 85, 90, 95 }) do
                        if percent1 < p and percent2 >= p then
                            local warningCount = checkSkills(level, false)
                            if warningCount > 0 and p >= 50 then
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
                printInfo(msg)
                flashInfo(msg)
            else
                local msg = "Exiting resting zone"
                printInfo(msg)
            end

        end)

    elseif event == 'PLAYER_CAMPING' then

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
            goodItems = {
                ['159'] = true, -- Refreshing Spring Water for cooking, engineering, etc.
                ['6529'] = true, -- Shiny Bauble
                ['6530'] = true, -- Nightcrawlers
                ['6532'] = true, -- Bright Baubles
                ['6533'] = true, -- Aquadynamic Fish Attractor
            },
            badItems = {},
            quiet = false,
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

function checkSkills(playerLevel, showMessageIfAllIsWell)
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

    -- Check the skill ranks against the expected rank.
    for _, skill in pairs(skills) do
        if skill.rank == 0 then
            if FIRST_REQUIRED_SKILL_CHECK_PLAYER_LEVEL - playerLevel <= 3 then
                warningCount = warningCount + 1
                printWarning("You must train " .. skill.name .. " and level it to " .. FIRST_REQUIRED_SKILL_CHECK_SKILL_RANK .. " before you ding " .. FIRST_REQUIRED_SKILL_CHECK_PLAYER_LEVEL)
                flashWarning("You must train" .. skill.name)
            end
        else
            if skill.name == "Unarmed" then
                if playerLevel >= 5 then
                    local minimumRank = playerLevel * 5 - 15
                    local minimumRankAtNextLevel = minimumRank + 5
                    if skill.rank < minimumRank then
                        warningCount = warningCount + 1
                        printWarning("Your " .. skill.name .. " skill is " .. skill.rank .. ". The minimum requirement at this level is " .. minimumRank .. ".")
                        printWarning("YOUR MOUNTAINEER CHALLENGE IS OVER")
                        flashWarning("YOUR MOUNTAINEER CHALLENGE IS OVER")
                        playSound(ERROR_SOUND_FILE)
                    elseif skill.rank < minimumRankAtNextLevel and playerLevel < MAX_LEVEL then
                        -- Warn if dinging will invalidate the run.
                        warningCount = warningCount + 1
                        printWarning("Your " .. skill.name .. " skill is " .. skill.rank .. ", but MUST be at least " .. minimumRankAtNextLevel .. " before you ding " .. (playerLevel + 1))
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
                        printWarning("Your " .. skill.name .. " skill is " .. skill.rank .. ", but MUST be at least " .. FIRST_REQUIRED_SKILL_CHECK_SKILL_RANK .. " before you ding " .. FIRST_REQUIRED_SKILL_CHECK_PLAYER_LEVEL)
                    end
                else
                    if skill.rank < minimumRank and playerLevel >= FIRST_REQUIRED_SKILL_CHECK_PLAYER_LEVEL then
                        -- At this level the player must be at least the minimum rank.
                        warningCount = warningCount + 1
                        printWarning("Your " .. skill.name .. " skill is " .. skill.rank .. ". The minimum requirement at this level is " .. minimumRank .. ".")
                        printWarning("YOUR MOUNTAINEER CHALLENGE IS OVER")
                        flashWarning("YOUR MOUNTAINEER CHALLENGE IS OVER")
                        playSound(ERROR_SOUND_FILE)
                    elseif skill.rank < minimumRankAtNextLevel and playerLevel < MAX_LEVEL then
                        -- Warn if dinging will invalidate the run.
                        warningCount = warningCount + 1
                        printWarning("Your " .. skill.name .. " skill is " .. skill.rank .. ", but MUST be at least " .. minimumRankAtNextLevel .. " before you ding " .. (playerLevel + 1))
                    end
                end
            end
        end
    end

    if warningCount == 0 and showMessageIfAllIsWell then
        printGood("All skills are up to date")
    end

    return warningCount
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
    if classId == Enum.ItemClass.Weapon then
        --print("Skinning knives, mining picks, fishing poles are allowed")
        if subclassId == Enum.ItemWeaponSubclass.Generic or subclassId == Enum.ItemWeaponSubclass.Fishingpole then
            return true
        end
    end
    --print("Fell through to return false")
    return false
end

function playSound(path)
    initSavedVarsIfNec()
    if not AcctSaved.quiet then
        PlaySoundFile(path, "Master")
    end
end

