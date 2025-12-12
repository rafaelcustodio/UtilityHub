local ADDON_NAME, addonTable = ...;
---@class UtilityHub
local UH = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceComm-3.0");

UH:SetDefaultModuleState(false);
UH.UTILS = LibStub("Utils-1.0");
UH.AceConfigDialog = LibStub("AceConfigDialog-3.0");
UH.Compatibility = {};
UH.Helpers = {};
UH.prefix = "UH";
UH.Options = {};
UH.defaultOptions = {
  simpleStatsTooltip = true,
  autoBuy = false,
  autoBuyList = {},
};
UH.Enums = {};
UH.Enums.CHARACTER_GROUP = {
  UNGROUPED = 0,
  MAIN_ALT = 1,
  BANK = 2,
  CD = 3,
};
UH.Enums.CHARACTER_GROUP_TEXT = {
  [UH.Enums.CHARACTER_GROUP.UNGROUPED] = "Ungrouped",
  [UH.Enums.CHARACTER_GROUP.MAIN_ALT] = "Main/alt",
  [UH.Enums.CHARACTER_GROUP.BANK] = "Bank",
  [UH.Enums.CHARACTER_GROUP.CD] = "CD",
};

UH.Events = CreateFromMixins(CallbackRegistryMixin);
UH.Events:OnLoad();
UH.Events:GenerateCallbackEvents({
  "OPTIONS_CHANGED",
  "CHARACTER_DELETED",
});

function UH:InitVariables()
  local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version");
  local oldVersion = nil;

  if (UHdatabase and UHdatabase.global and UHdatabase.global.oldVersion) then
    oldVersion = UHdatabase.global.oldVersion;
  end

  self.db = LibStub("AceDB-3.0"):New("UHdatabase", {
    global = {
      version = version,
      debugMode = false,
      minimapIcon = {
        hide = false,
      },
      options = UH.defaultOptions,
      presets = {},
      whispers = {},
      ---@type Characters[]
      characters = {},
    },
  }, "Default");
  self.db.global.oldVersion = version;

  if (oldVersion and oldVersion ~= version) then
    UH:MigrateDB(version, oldVersion);
  end

  UH:AddCharacterToList();
end

function UH:MigrateDB(version, oldVersion)
  if (version and oldVersion) then
    self.Helpers:ShowNotification("Migrating DB version from " .. oldVersion .. " to " .. version);
  else
    self.Helpers:ShowNotification("Migrating DB version - Forced action without any version change");
  end

  if (#self.db.global.presets > 0) then
    for _, preset in pairs(self.db.global.presets) do
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

  if (not self.db.global.options) then
    self.db.global.options = UH.defaultOptions;
  end

  if (not self.db.global.options.autoBuyList) then
    self.db.global.options.autoBuyList = UH.defaultOptions.autoBuyList;
  end

  if (self.db.global.characters) then
    for index, value in ipairs(self.db.global.characters) do
      if (type(value) == "string") then
        local name = self.db.global.characters[index];

        if (name == UnitName("player")) then
          local race = select(2, UnitRace("player"));
          local className = select(2, UnitClass("player"));

          self.db.global.characters[index] = {
            name = name,
            race = race,
            className = className,
            group = nil,
          };
        else
          self.db.global.characters[index] = {
            name = name,
            race = nil,
            className = nil,
            group = nil,
          };
        end
      end
    end
  end
end

function UH:SetupSlashCommands()
  SLASH_UtilityHub1 = "/UH"
  SlashCmdList.UtilityHub = function(strParam)
    local fragments = {}
    for word in string.gmatch(strParam, "%S+") do
      table.insert(fragments, word)
    end

    local command = (fragments[1] or ""):trim();

    if (command == "") then
      UH.Helpers:ShowNotification("Type /UH help for commands");
    elseif (command == "help") then
      UH.Helpers:ShowNotification("Use the following parameters with /UH");
      print("- |cffddff00debug|r");
      print("  Toggle the debug mode");
      print("- |cffddff00options|r");
      print("  Open the options");
    elseif (command == "debug") then
      UH.db.global.debugMode = (not UH.db.global.debugMode);
      local debugText = UH.db.global.debugMode and "ON" or "OFF";
      UH.Helpers:ShowNotification("Debug mode " .. debugText);
    elseif (command == "options") then
      Settings.OpenToCategory(ADDON_NAME);
    elseif (command == "migrate") then
      UH:MigrateDB();
    else
      UH.Helpers:ShowNotification("Command not found");
    end
  end
end

function UH:RegisterOptions()
  LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, UH.Options);
  UH.AceConfigDialog:AddToBlizOptions(ADDON_NAME, ADDON_NAME);
end

function UH:OnInitialize()
  -- Migration code from the old name, should be
  if (MDHdatabase) then
    UHdatabase = MDHdatabase;
    MDHdatabase = nil;
  end

  UH:InitVariables();
  UH:SetupSlashCommands();
  UH:RegisterOptions();

  UH.Compatibility.Baganator();

  if (UH.db.global.options.simpleStatsTooltip) then
    UH:EnableModule("Tooltip");
  end

  if (UH.db.global.options.autoBuy) then
    UH:EnableModule("AutoBuy");
  end
end

function UH:AddCharacterToList()
  local name = UnitName("player");
  local playerTable = {
    name = name,
    race = select(2, UnitRace("player")),
    className = select(2, UnitClass("player")),
    group = UH.Enums.CHARACTER_GROUP.UNGROUPED,
  };

  for index, value in pairs(UH.db.global.characters) do
    if (value.name == name) then
      playerTable.group = value.group;
      UH.db.global.characters[index] = playerTable;
      return;
    end
  end

  tinsert(UH.db.global.characters, playerTable);
end

---@class Character
---@field name string
---@field race number
---@field className number
---@field group number
