--[[
===== ChatCommand =====
Makes it easier to create commands from anywhere in your code.
Does not break when using script_reload
Usage:
  -Create a function MyFunction(keys)             OR     function SomeClass:SomeFunction(keys)
    keys are those delivered from the 'player_chat' event
  -Use ChatCommand:LinkCommand("-MyTrigger", MyFunction, context)
    Use this to call this function everytime someone's chat starts with -MyTrigger
created by Zarnotox with a lot of constructive help from the mod data guys https://discord.gg/Z7eCcGT (THIS IS NOT THE OAA DISCORD, THIS IS THE MODDATA DISCORD. YOU DID NOT FIND THE SECRET. check it out!)
]]

ChatCommand = ChatCommand or {}

function ChatCommand:Init()
  ListenToGameEvent("player_chat", Dynamic_Wrap(ChatCommand, 'OnPlayerChat'), self)
end

-- Function to create the link
function ChatCommand:LinkCommand(command, func, obj)
  self.commands = self.commands or {}
  self.commands[command] = {func, obj}
end

-- Function that's called when somebody chats
function ChatCommand:OnPlayerChat(keys)
  self.commands = self.commands or {}
  local text = string.lower(keys.text)
  local teamonly = keys.teamonly
  local playerID = keys.playerid
  local hero = PlayerResource:GetSelectedHeroEntity(playerID)

  local splitted = split(text, " ")

  if (IsInToolsMode() or GameRules:IsCheatMode()) and self.commands[splitted[1]] ~= nil then
    local location = self.commands[splitted[1]]
    local func = location[1]
    local context = location[2]

    if context == nil then
      func(keys)
    else
      func(context, keys)
    end
  end
end
