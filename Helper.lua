local ADDON_NAME = ...;
---@type MailDistributionHelper
local MDH = LibStub('AceAddon-3.0'):GetAddon(ADDON_NAME);
---@class Helpers
MDH.Helpers = {};

--- Return true or false if the player is in the raid or group by his name and his index if in raid
---@param playerName string
function MDH.Helpers:CheckIfPlayerInTheRaidOrGroupByName(playerName)
    if (not IsInGroup() or not IsInRaid()) then
        return false;
    end

    for i = 1, GetNumGroupMembers() do
        local name = GetRaidRosterInfo(i);

        if (name == playerName) then
            return true, i;
        end
    end

    return false, nil;
end

function MDH.Helpers:FormatDuration(seconds)
    local hours = math.floor(seconds / 3600);
    local minutes = math.floor((seconds % 3600) / 60);
    local secs = seconds % 60;
    return string.format("%02d:%02d:%02d", hours, minutes, secs),
        (hours > 24 or (hours == 24 and minutes > 0 and seconds > 0));
end

function MDH.Helpers:ShowNotification(text)
    MDH.UTILS:ShowChatNotification(text, MDH.prefix);
end

function MDH.Helpers:ApplyPrefix(text)
    return MDH.prefix .. text;
end
