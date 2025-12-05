local addonName, addonTable = ...;
---@class MailDistributionHelper
local MDH = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceComm-3.0");
MDH:SetDefaultModuleState(false);
MDH.UTILS = LibStub("Utils-1.0");
MDH.Compatibility = {};
MDH.Helpers = {};
MDH.prefix = "MDH";

function MDH.Helpers:Benchmark(label, func, level)
    if level == nil or type(level) ~= 'number' then level = 1; end
    -- level = level or 1;
    if level < 1 then
        local firstStr = string.format('|cffffd100-----Start Bench: |r|cff8080ff%s|r-----', label)
        MDH.Helpers:ShowNotification(firstStr);
    end
    local startTime = GetTimePreciseSec();
    local results = { func() };
    local endTime = GetTimePreciseSec();
    local duration = endTime - startTime;

    local levelStr = '';
    if level > 0 then levelStr = string.rep("~", level) .. '>'; end

    local str = string.format("|cffffd100%sBench: |r|cff8080ff%s|r took |cffffd100%.4f|r ms", levelStr, label,
        duration * 1000)
    -- print(str)
    MDH.Helpers:ShowNotification(str);
    return results, duration, startTime, endTime;
end

function MDH:InitVariables()
    local version = C_AddOns.GetAddOnMetadata(addonName, "Version");

    self.db = LibStub("AceDB-3.0"):New("MDHdatabase", {
        global = {
            version = version,
            debugMode = false,
            minimapIcon = {
                hide = false
            },
            presets = {},
            whispers = {},
            characters = {}
        }
    }, "Default");

    local name = UnitName("player");

    if (not MDH.UTILS:ValueInTable(MDH.db.global.characters, name)) then
        tinsert(MDH.db.global.characters, name);
    end

    if (version ~= self.db.global.version) then
        MDH:MigrateDB();
    end
end

function MDH:MigrateDB()
    if (#MDH.db.global.presets <= 0) then
        return;
    end

    for _, preset in pairs(MDH.db.global.presets) do
        local shouldFixEssenceElemental = false;

        for j, _ in pairs(preset.itemGroups) do
            if (j == "Essence") then
                shouldFixEssenceElemental = true;
            end
        end

        if (shouldFixEssenceElemental) then
            local newItemGroups = {};

            for key, value in pairs(preset.itemGroups) do
                if (key == "Essence") then
                    newItemGroups["EssenceElemental"] = value;
                else
                    newItemGroups[key] = value;
                end
            end

            preset.itemGroups = newItemGroups;
        end
    end
end

function MDH:SetupSlashCommands()
    SLASH_MailDistributionHelper1 = "/mdh"
    SlashCmdList.MailDistributionHelper = function(strParam)
        local fragments = {}
        for word in string.gmatch(strParam, "%S+") do
            table.insert(fragments, word)
        end

        local command = (fragments[1] or ""):trim();

        if (command == "") then
            MDH.Helpers:ShowNotification("Type /mdh help for commands");
        elseif (command == "help") then
            MDH.Helpers:ShowNotification("Use the following parameters with /mdh");
            print("- |cffddff00debug|r");
            print("  Toggle the debug mode");
        elseif (command == "debug") then
            MDH.db.global.debugMode = (not MDH.db.global.debugMode);
            local debugText = MDH.db.global.debugMode and "ON" or "OFF";
            MDH.Helpers:ShowNotification("Debug mode " .. debugText);
        else
            MDH.Helpers:ShowNotification("Command not found");
        end
    end
end

function MDH:OnInitialize()
    MDH:InitVariables();
    MDH:SetupSlashCommands();

    MDH.Compatibility.Baganator();
end
