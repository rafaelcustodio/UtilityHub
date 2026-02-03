---@enum EnumCharacterGroup
local CHARACTER_GROUP = {
  UNGROUPED = 0,
  MAIN_ALT = 1,
  BANK = 2,
  CD = 3,
};

---@class Enums
UtilityHub.Enums = {
  CharacterGroup = CHARACTER_GROUP,
  ---@enum ECharacterGroupText
  CharacterGroupText = {
    [CHARACTER_GROUP.UNGROUPED] = "Ungrouped",
    [CHARACTER_GROUP.MAIN_ALT] = "Main/alt",
    [CHARACTER_GROUP.BANK] = "Bank",
    [CHARACTER_GROUP.CD] = "CD",
  },
  ---@enum EQuestType
  QuestType = {
    DUNGEON_NORMAL = 0,
    DUNGEON_HEROIC = 1,
    PROFESSION_COOKING = 2,
    PROFESSION_FISHING = 3,
    CONSORTIUM = 4,
    SHATARI_SKYGUARD = 5,
    OGRILA = 6,
    SHATARI_SKYGUARD_AND_OGRILA = 7,
    NETHERWING = 8,
    PVP = 9,
  },
  ---@enum EExpansion
  Expansions = {
    CLASSIC = 0,
    TBC = 1,
  },
  ---@enum EReputationStanding
  ReputationStanding = {
    HATED = 1,
    HOSTILE = 2,
    UNFRIENDLY = 3,
    NEUTRAL = 4,
    FRIENDLY = 5,
    HONORED = 6,
    REVERED = 7,
    EXALTED = 8,
  },
  ---@enum EPeriodicity
  Periodicity = {
    DAILY = 1,
    WEEKLY = 2,
    MONTHLY = 3,
  },
  ---@enum ESide
  Side = {
    ALLIANCE = "Alliance",
    HORDE = "Horde",
  },
};
