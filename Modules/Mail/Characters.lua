local ADDON_NAME = ...;
---@type MailDistributionHelper
local MDH = LibStub('AceAddon-3.0'):GetAddon(ADDON_NAME);
local moduleName = 'Characters';
---@class Characters
---@diagnostic disable-next-line: undefined-field
local Module = MDH:NewModule(moduleName);

function Module:OnEnable()
  -- TODO
end

function Module:GetAccountCharactersGeneratorFunction()
  local refMDH = MDH;

  return function(owner, rootDescription)
    rootDescription:CreateTitle("Account characters");

    for i, value in pairs(refMDH.db.global.characters) do
      rootDescription:CreateButton(value, function()
        Module:StartMail(value);
      end);
    end

    rootDescription:CreateDivider();
    rootDescription:CreateTitle("Options");
    local button = rootDescription:CreateButton("Manage");

    for i, value in pairs(refMDH.db.global.characters) do
      local buttonAction = button:CreateButton(value);

      if (value ~= UnitName("player")) then
        buttonAction:CreateButton("Remove", function()
          local newCharacters = {};

          for j, value in pairs(refMDH.db.global.characters) do
            if (i ~= j) then
              tinsert(newCharacters, value);
            end
          end

          refMDH.db.global.characters = newCharacters;
        end);
      end
    end
  end
end

function Module:StartMail(characterName)
  MailFrameTab_OnClick(_G["MailFrameTab2"]);
  SendMailNameEditBox:SetText(characterName);
end
