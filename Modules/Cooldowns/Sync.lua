local SYNC_PREFIX = "UHCDSync";
local CHANNEL_PREFIX = "uhsync";
local FAKE_SYNC_FLAG = "_isFakeSync";

local currentChannel = nil;
local knownPeers = {};

---@type Cooldowns
local CooldownsModule = UtilityHub.Addon:GetModule("Cooldowns");

---@return boolean
local function IsSyncEnabled()
  local opts = UtilityHub.Database.global.options;
  return opts.cooldowns and opts.cooldownSync;
end

---@return boolean
local function IsDebugMode()
  return UtilityHub.Database and UtilityHub.Database.global and UtilityHub.Database.global.debugMode;
end

---@return Character|nil
local function GetCurrentCharacterData()
  local playerName = UnitName("player");

  for _, character in ipairs(UtilityHub.Database.global.characters) do
    if (character.name == playerName) then
      return character;
    end
  end

  return nil;
end

--- Get all known peers
---@return string[]
local function GetChannelMembers()
  local members = {};

  for name in pairs(knownPeers) do
    tinsert(members, name);
  end

  return members;
end

--- Send a single character's data to all channel members via WHISPER
---@param charData Character
local function SendCharacterData(charData)
  local json = C_EncodingUtil.SerializeJSON(charData);

  if (not json) then
    return;
  end

  local members = GetChannelMembers();

  for _, member in ipairs(members) do
    UtilityHub.Addon:SendCommMessage(SYNC_PREFIX, json, "WHISPER", member, "BULK");
  end
end

--- Send current player's data to all channel members
local function BroadcastSyncData()
  if (not currentChannel) then
    return;
  end

  local charData = GetCurrentCharacterData();

  if (not charData) then
    return;
  end

  SendCharacterData(charData);
end

local function LeaveSyncChannel()
  if (currentChannel) then
    LeaveChannelByName(currentChannel);
    currentChannel = nil;
    wipe(knownPeers);
  end
end

---@param channelName string
local function JoinSyncChannel(channelName)
  if (not channelName or channelName == "") then
    return;
  end

  local fullName = CHANNEL_PREFIX .. channelName;

  if (currentChannel and currentChannel ~= fullName) then
    LeaveSyncChannel();
  end

  if (currentChannel == fullName) then
    return;
  end

  -- Join, then leave and rejoin to force CHAT_MSG_CHANNEL_JOIN on other clients
  JoinChannelByName(fullName);
  currentChannel = fullName;

  C_Timer.After(1, function()
    LeaveChannelByName(fullName);

    C_Timer.After(1, function()
      JoinChannelByName(fullName);

      C_Timer.After(2, function()
        local id = GetChannelName(fullName);

        if (id and id > 0) then
          BroadcastSyncData();
        else
          currentChannel = nil;
        end
      end);
    end);
  end);
end

local function ClearFakeCharactersFromDB()
  local removed = 0;

  for i = #UtilityHub.Database.global.characters, 1, -1 do
    if (UtilityHub.Database.global.characters[i][FAKE_SYNC_FLAG]) then
      tremove(UtilityHub.Database.global.characters, i);
      removed = removed + 1;
    end
  end

  return removed;
end

--- When receiving character data via WHISPER, merge into local DB
---@param prefix string
---@param data string
---@param distribution string
---@param sender string
local function OnSyncDataReceived(prefix, data, distribution, sender)
  sender = Ambiguate(sender, "none");
  local myName = UnitName("player");

  if (sender == myName) then
    return;
  end

  local charData = C_EncodingUtil.DeserializeJSON(data);

  if (not charData) then
    return;
  end

  -- Handle clear command
  if (charData.action == "clearFakeSync") then
    local removed = ClearFakeCharactersFromDB();
    CooldownsModule:UpdateCooldownsFrameList();
    return;
  end

  if (not charData.name) then
    return;
  end

  -- Track sender as a known peer and reply if first contact
  local isNewPeer = (currentChannel and not knownPeers[sender]);

  if (currentChannel) then
    knownPeers[sender] = true;
  end

  local found = false;

  for index, character in ipairs(UtilityHub.Database.global.characters) do
    if (character.name == charData.name) then
      UtilityHub.Database.global.characters[index].cooldownGroup = charData.cooldownGroup;
      UtilityHub.Database.global.characters[index].race = charData.race;
      UtilityHub.Database.global.characters[index].className = charData.className;

      if (charData.group) then
        UtilityHub.Database.global.characters[index].group = charData.group;
      end

      found = true;
      break;
    end
  end

  if (not found) then
    tinsert(UtilityHub.Database.global.characters, charData);
  end

  -- Refresh UI directly — do NOT fire CHARACTER_UPDATED to avoid sync loops
  CooldownsModule:UpdateCooldownsFrameList();

  -- If this is a new peer, reply with all our local characters
  if (isNewPeer) then
    for _, character in ipairs(UtilityHub.Database.global.characters) do
      local json = C_EncodingUtil.SerializeJSON(character);

      if (json) then
        UtilityHub.Addon:SendCommMessage(SYNC_PREFIX, json, "WHISPER", sender, "BULK");
      end
    end
  end
end

-- Register AceComm handler for sync data
UtilityHub.Addon:RegisterComm(SYNC_PREFIX, OnSyncDataReceived);

-- Broadcast to channel members when local character data updates
UtilityHub.Events:RegisterCallback("CHARACTER_UPDATED", function()
  if (currentChannel) then
    BroadcastSyncData();
  end
end);

-- Detect when someone joins the sync channel and send them our data
EventRegistry:RegisterFrameEventAndCallback("CHAT_MSG_CHANNEL_JOIN", function(_, _, sender, _, _, _, _, _, _, channelBaseName)
  if (not currentChannel) then
    return;
  end

  local myName = UnitName("player");
  sender = Ambiguate(sender, "none");

  if (sender == myName) then
    return;
  end

  if (not channelBaseName or channelBaseName ~= currentChannel) then
    return;
  end

  knownPeers[sender] = true;

  C_Timer.After(1, function()
    for _, character in ipairs(UtilityHub.Database.global.characters) do
      local json = C_EncodingUtil.SerializeJSON(character);

      if (json) then
        UtilityHub.Addon:SendCommMessage(SYNC_PREFIX, json, "WHISPER", sender, "BULK");
      end
    end
  end);
end);

-- Remove peers when they leave the sync channel
EventRegistry:RegisterFrameEventAndCallback("CHAT_MSG_CHANNEL_LEAVE", function(_, _, sender, _, _, _, _, _, _, channelBaseName)
  if (not currentChannel) then
    return;
  end

  if (not channelBaseName or channelBaseName ~= currentChannel) then
    return;
  end

  sender = Ambiguate(sender, "none");
  knownPeers[sender] = nil;
end);

---@return boolean "true if joined, false otherwise"
local function TryJoinSyncChannel()
  if (not IsSyncEnabled()) then
    return false;
  end

  local channelName = UtilityHub.Database.global.options.cooldownSyncChannel;

  if (channelName and channelName ~= "") then
    JoinSyncChannel(channelName);
    return true;
  end

  return false;
end

-- Join channel on addon ready if configured
EventRegistry:RegisterFrameEventAndCallback("LOADING_SCREEN_DISABLED", function()
  C_Timer.After(4, function()
    TryJoinSyncChannel();
  end);
end);

-- Handle sync option changes
UtilityHub.Events:RegisterCallback("OPTIONS_CHANGED", function(_, name)
  if (name == "cooldownSync" or name == "cooldownSyncChannel" or name == "cooldowns") then
    if (not TryJoinSyncChannel()) then
      LeaveSyncChannel();
    end
  end
end);

-- Debug: fake sync data

local function GenerateFakeCharacters()
  local now = GetTime();

  return {
    {
      name = "Fakemage",
      race = "Human",
      className = "MAGE",
      group = UtilityHub.Enums.CharacterGroup.UNGROUPED,
      [FAKE_SYNC_FLAG] = true,
      cooldownGroup = {
        Tailoring = {
          { name = "Mooncloth", start = 0, maxCooldown = 0 },
        },
        Alchemy = {
          { name = "Arcanite Bar", start = now, maxCooldown = 172800 },
        },
      },
    },
    {
      name = "Fakepriest",
      race = "NightElf",
      className = "PRIEST",
      group = UtilityHub.Enums.CharacterGroup.UNGROUPED,
      [FAKE_SYNC_FLAG] = true,
      cooldownGroup = {
        Tailoring = {
          { name = "Mooncloth", start = now - 86400, maxCooldown = 259200 },
        },
        Alchemy = {
          { name = "Arcanite Bar", start = 0, maxCooldown = 0 },
          { name = "Water to Air", start = now - 3600, maxCooldown = 172800 },
        },
      },
    },
    {
      name = "Fakewarrior",
      race = "Dwarf",
      className = "WARRIOR",
      group = UtilityHub.Enums.CharacterGroup.UNGROUPED,
      [FAKE_SYNC_FLAG] = true,
      cooldownGroup = {
        Leatherworking = {
          { name = "Refined Deeprock Salt", start = 0, maxCooldown = 0 },
        },
      },
    },
  };
end

function CooldownsModule:InjectFakeSyncData()
  if (not IsDebugMode()) then
    UtilityHub.Helpers.Notification:ShowNotification("Debug mode must be enabled to use fakesync");
    return;
  end

  local channelName = UtilityHub.Database.global.options.cooldownSyncChannel;
  JoinSyncChannel((channelName and channelName ~= "") and channelName or "test");

  local fakeChars = GenerateFakeCharacters();
  local injected = 0;

  for _, fakeChar in ipairs(fakeChars) do
    local found = false;

    for index, character in ipairs(UtilityHub.Database.global.characters) do
      if (character.name == fakeChar.name) then
        UtilityHub.Database.global.characters[index] = fakeChar;
        found = true;
        break;
      end
    end

    if (not found) then
      tinsert(UtilityHub.Database.global.characters, fakeChar);
    end

    injected = injected + 1;
  end

  CooldownsModule:UpdateCooldownsFrameList();
  BroadcastSyncData();

  for _, fakeChar in ipairs(fakeChars) do
    SendCharacterData(fakeChar);
  end

  UtilityHub.Helpers.Notification:ShowNotification("Injected " .. injected .. " fake sync characters");
end

function CooldownsModule:ClearFakeSyncData()
  if (not IsDebugMode()) then
    UtilityHub.Helpers.Notification:ShowNotification("Debug mode must be enabled to use clearfakesync");
    return;
  end

  -- Send clear command to peers before cleaning locally
  local clearPayload = C_EncodingUtil.SerializeJSON({ action = "clearFakeSync" });

  if (clearPayload) then
    local members = GetChannelMembers();

    for _, member in ipairs(members) do
      UtilityHub.Addon:SendCommMessage(SYNC_PREFIX, clearPayload, "WHISPER", member, "BULK");
    end
  end

  local removed = ClearFakeCharactersFromDB();
  CooldownsModule:UpdateCooldownsFrameList();
  LeaveSyncChannel();
  UtilityHub.Helpers.Notification:ShowNotification("Removed " .. removed .. " fake sync characters");
end
