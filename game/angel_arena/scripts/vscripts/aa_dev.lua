-- TEMPORARY dev helper (UI work): stretch pregame timers so screens can be inspected.
GameRules:SetCustomGameSetupTimeout(-1)
GameRules:SetHeroSelectionTime(400)
GameRules:SetStrategyTime(400)
GameRules:SetShowcaseTime(0)
print("AADEV timers stretched, state=" .. tostring(GameRules:State_Get()))
