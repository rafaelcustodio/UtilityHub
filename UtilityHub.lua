local ADDON_NAME, addonTable = ...;

---@class UtilityHub
UtilityHub = {
  Addon = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceComm-3.0"),
  Libs = {
    LDBIcon = LibStub("LibDBIcon-1.0"),
    AceDB = LibStub("AceDB-3.0"),
    AceConfigDialog = LibStub("AceConfigDialog-3.0"),
    AceConfig = LibStub("AceConfig-3.0"),
    LDB = LibStub:GetLibrary("LibDataBroker-1.1"),
    Utils = LibStub("Utils-1.0"),
  },
  ---@type Constants
  ---@diagnostic disable-next-line: missing-fields
  Constants = {},
  GameOptions = {
    defaults = {
      -- Tooltip
      simpleStatsTooltip = true,
      -- AutoBuy
      autoBuy = false,
      autoBuyList = {},
      -- Cooldowns
      cooldowns = false,
      cooldowsList = {},
      cooldownPlaySound = false,
      -- DailyQuests
      dailyQuests = false,
      -- Trade
      tradeExtraInfo = false,
    },
    ---@type Option[]
    options = {},
    category = nil,
    subcategories = {},
    Register = function() end,
    OpenConfig = function()
      if (UtilityHub.GameOptions.category == nil) then
        return;
      end

      Settings.OpenToCategory(UtilityHub.GameOptions.category:GetID());
    end,
  },
  Integration = {},
  ---@type Helpers
  ---@diagnostic disable-next-line: missing-fields
  Helpers = {},
  Flags = {
    ---@type boolean
    addonReady = false,
  },
  Database = {},
  Events = CreateFromMixins(CallbackRegistryMixin),
};

UtilityHub.Addon:SetDefaultModuleState(false);

---@type boolean
UtilityHub.tempPreset = {};

---@class Character
---@field name string
---@field race number
---@field className number
---@field group number
---@field cooldownGroup table<string, CurrentCooldown[]>

---@class Option
---@field categoryID number
