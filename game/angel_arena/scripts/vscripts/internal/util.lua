---------------------------------------------------------------------------
-- ??
-- This file provides the DebugPrint and DebugPrintTable functions, which are wrappers for print
-- with some added functionality useful for debugging. Documentation available in docs/debug_print_lua.md
---------------------------------------------------------------------------
Debug = Debug or {
  EnabledModules = {
    ['internal:*'] = true,
    ['gamemode:*'] = true
  },
  EnableAll = false
}
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function regexsplit(s, delimiter)
    result = {};
    for match in s:gmatch("([^"..delimiter.."]+)") do
        table.insert(result, match);
    end
    return result;
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function TracesFromFilename (filename)
  local traces = {}
  local i = 1

  local parts = regexsplit(filename, '%s/\\')
  local partialTrade = nil
  for i, part in ipairs(parts) do
    if partialTrade == nil and part ~= "components" then
      partialTrade = part
      table.insert(traces, partialTrade .. ":*")
    elseif partialTrade ~= nil then
      partialTrade = partialTrade .. ":" .. part
      table.insert(traces, partialTrade .. ":*")
    end
  end

  table.insert(traces, partialTrade)

  return traces
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function IsAnyTraceEnabled (traces)
  if Debug.EnableAll then
    return true
  end

  for i, trace in ipairs(traces) do
    if Debug.EnabledModules[trace] then
      return true
    end
  end

  return false
end
---------------------------------------------------------------------------
-- ??
-- written by yeahbuddy, taken from https://github.com/OpenAngelArena/oaa/pull/80
-- modified for clarity
---------------------------------------------------------------------------
function GetCallingFile (offset)
  offset = offset or 4

  local functionInfo = debug.getinfo(offset - 1, "Sl")
  local filePath = string.match(functionInfo.source, "scripts[/\\]vscripts[/\\](.+).lua")
  if functionInfo.currentline then
    return TracesFromFilename(filePath), filePath .. ":" .. functionInfo.currentline
  else
    return TracesFromFilename(filePath), filePath
  end
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function DebugPrint(...)
  local spew = Convars:GetInt('barebones_spew') or -1
  if spew == -1 and BAREBONES_DEBUG_SPEW then
    spew = 1
  end

  local trace, dir = GetCallingFile()

  if IsAnyTraceEnabled(trace) then
    spew = 1
  end

  local output = {...}

  local prefix, msg = string.match(output[1], "%[([^%]]*)%]%s*(.*)")

  if prefix ~= nil then
    output[1] = msg
  end

  if spew == 1 then
    print("[" .. dir .. "]", unpack(output))
  end
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function DebugPrintTable(...)
  local spew = Convars:GetInt('barebones_spew') or -1
  if spew == -1 and BAREBONES_DEBUG_SPEW then
    spew = 1
  end

  local trace, dir = GetCallingFile()

  if IsAnyTraceEnabled(trace) then
    spew = 1
  end

  if spew == 1 then
    PrintTable("[" .. dir .. "]", ...)
  end
end
---------------------------------------------------------------------------
-- Print Table
---------------------------------------------------------------------------
function PrintTable(prefix, t, indent, done)
  --print ( string.format ('PrintTable type %s', type(keys)) )
  if type(prefix) == "table" then
    -- shift
    done = indent
    indent = t
    t = prefix

    local trace = nil
    -- set prefix
    trace, prefix = GetCallingFile()

    prefix = "[" .. prefix .. "] "
  end
  if type(t) ~= "table" then return end

  done = done or {}
  done[t] = true
  indent = indent or 1

  local l = {}
  for k, v in pairs(t) do
    table.insert(l, k)
  end

  table.sort(l)
  for k, v in ipairs(l) do
    -- Ignore FDesc
    if v ~= 'FDesc' then
      local value = t[v]

      if type(value) == "table" and not done[value] then
        done [value] = true
        print(prefix .. string.rep ("\t", indent)..tostring(v)..":")
        PrintTable (prefix, value, indent + 2, done)
      elseif type(value) == "userdata" and not done[value] then
        done [value] = true
        print(prefix .. string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
        PrintTable (prefix, (getmetatable(value) and getmetatable(value).__index) or getmetatable(value), indent + 2, done)
      else
        if t.FDesc and t.FDesc[v] then
          print(prefix .. string.rep ("\t", indent)..tostring(t.FDesc[v]))
        else
          print(prefix .. string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
        end
      end
    end
  end
end
--------------------------------------------------------------
--	Print Table 2
--------------------------------------------------------------
function PrintTable2(title,table)
	print("--------------------Start of Print table--------------------------")
	print(title)
	for k,v in pairs(table) do
		print(k,v)
	end
	print("--------------------End of Print table--------------------------")
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
-- Colors
COLOR_NONE = '\x06'
COLOR_GRAY = '\x06'
COLOR_GREY = '\x06'
COLOR_GREEN = '\x0C'
COLOR_DPURPLE = '\x0D'
COLOR_SPINK = '\x0E'
COLOR_DYELLOW = '\x10'
COLOR_PINK = '\x11'
COLOR_RED = '\x12'
COLOR_LGREEN = '\x15'
COLOR_BLUE = '\x16'
COLOR_DGREEN = '\x18'
COLOR_SBLUE = '\x19'
COLOR_PURPLE = '\x1A'
COLOR_ORANGE = '\x1B'
COLOR_LRED = '\x1C'
COLOR_GOLD = '\x1D'

---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function DebugAllCalls()
    if not GameRules.DebugCalls then
        print("Starting DebugCalls")
        GameRules.DebugCalls = true

        debug.sethook(function(...)
            local info = debug.getinfo(2)
            local src = tostring(info.short_src)
            local name = tostring(info.name)
            if name ~= "__index" then
                print("Call: ".. src .. " -- " .. name .. " -- " .. info.currentline)
            end
        end, "c")
    else
        print("Stopped DebugCalls")
        GameRules.DebugCalls = false
        debug.sethook(nil, "c")
    end
end
---------------------------------------------------------------------------
-- ??
-- Credits:
-- Angel Arena Blackstar
-- Description:
-- Returns the player id from a given unit / player / table.
-- For example, you should be able to pass in a reference to a lycan wolf and get back the correct player's ID.
-- chrisinajar
---------------------------------------------------------------------------
function UnitVarToPlayerID(unitvar)
  if unitvar then
    if type(unitvar) == "number" then
      return unitvar
    elseif type(unitvar) == "table" and not unitvar:IsNull() and unitvar.entindex and unitvar:entindex() then
      if unitvar.GetPlayerID and unitvar:GetPlayerID() > -1 then
        return unitvar:GetPlayerID()
      elseif unitvar.GetPlayerOwnerID then
        return unitvar:GetPlayerOwnerID()
      end
    end
  end
  return -1
end
---------------------------------------------------------------------------
-- ??
-- Author: Noya
-- Date: 09.08.2015.
-- Hides all dem hats
---------------------------------------------------------------------------
function HideWearables( unit )
  unit.hiddenWearables = {} -- Keep every wearable handle in a table to show them later
    local model = unit:FirstMoveChild()
    while model ~= nil do
        if model:GetClassname() == "dota_item_wearable" then
            model:AddEffects(EF_NODRAW) -- Set model hidden
            table.insert(unit.hiddenWearables, model)
        end
        model = model:NextMovePeer()
    end
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function ShowWearables( unit )

  for i,v in pairs(unit.hiddenWearables) do
    v:RemoveEffects(EF_NODRAW)
  end
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function GetShortTeamName (teamID)
  local teamNames = {
    [DOTA_TEAM_GOODGUYS] = "good",
    [DOTA_TEAM_BADGUYS] = "bad",
    [DOTA_TEAM_NEUTRALS] = "neutral",
    [DOTA_TEAM_CUSTOM_1] = "custom1",
    [DOTA_TEAM_CUSTOM_2] = "custom2",
    [DOTA_TEAM_CUSTOM_3] = "custom3",
    [DOTA_TEAM_CUSTOM_4] = "custom4",
    [DOTA_TEAM_CUSTOM_5] = "custom5",
    [DOTA_TEAM_CUSTOM_6] = "custom6",
    [DOTA_TEAM_CUSTOM_7] = "custom7",
    [DOTA_TEAM_CUSTOM_8] = "custom8",
  }
  return teamNames[teamID]
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function IsInTrigger(entity, trigger)
  local triggerOrigin = trigger:GetAbsOrigin()
  local bounds = trigger:GetBounds()

  local origin = entity
  if entity.GetAbsOrigin then
    origin = entity:GetAbsOrigin()
  end

  if origin.x < bounds.Mins.x + triggerOrigin.x then
    -- DebugPrint('x is too small')
    return false
  end
  if origin.y < bounds.Mins.y + triggerOrigin.y then
    -- DebugPrint('y is too small')
    return false
  end
  if origin.x > bounds.Maxs.x + triggerOrigin.x then
    -- DebugPrint('x is too large')
    return false
  end
  if origin.y > bounds.Maxs.y + triggerOrigin.y then
    -- DebugPrint('y is too large')
    return false
  end

  return true
end
---------------------------------------------------------------------------
-- Find Heroes in Radius
---------------------------------------------------------------------------
function FindHeroesInRadius (...)
  local units = FindUnitsInRadius(...)

  local function isHero (hero)
    if hero.IsRealHero and hero:IsRealHero() then
      return true
    end
    return false
  end

  return totable(filter(isHero, iter(units)))
end
---------------------------------------------------------------------------
-- Move Camera To Player
---------------------------------------------------------------------------
function MoveCameraToPlayer(handle)
  local playerID = nil
  local entity = nil
  if IsValidEntity(handle) and handle:IsPlayer() then
    playerID = handle:GetPlayerID()
    entity = handle:GetAssignedHero()
  elseif IsValidEntity(handle) and handle:IsOwnedByAnyPlayer() then
    playerID = handle:GetPlayerOwnerID()
    entity = handle
  elseif tonumber(handle) and PlayerResource:IsValidPlayerID(handle) then
    playerID = handle
    entity = PlayerResource:GetSelectedHeroEntity(handle)
  else
    return
  end
  if playerID and entity then
    MoveCameraToEntity(playerID, entity)
  end
end
---------------------------------------------------------------------------
-- Move Camera to Entity
---------------------------------------------------------------------------
function MoveCameraToEntity(playerID, entity)
  if IsValidEntity(entity) and PlayerResource:IsValidPlayerID(playerID) then
    PlayerResource:SetCameraTarget(playerID, entity)
    Timers:CreateTimer(0.5, function ()
      PlayerResource:SetCameraTarget(playerID, nil)
    end)
  end
end

---------------------------------------------------------------------------
-- [IMBA Utilities]
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function split2(inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            t[i] = str
            i = i + 1
    end
    return t
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function tableContains(list, element)
    if list == nil then return false end
    for i=1,#list do
        if list[i] == element then
            return true
        end
    end
    return false
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function getIndex(list, element)
    if list == nil then return false end
    for i=1,#list do
        if list[i] == element then
            return i
        end
    end
    return -1
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function getUnitIndex(list, unitName)
    --print("Given Table")
    --DeepPrintTable(list)
    if list == nil then return false end
    for k,v in pairs(list) do
        for key,value in pairs(list[k]) do
            --print(key,value)
            if value == unitName then 
                return key
            end
        end        
    end
    return -1
end
---------------------------------------------------------------------------
-- ??
-- Talents modifier function
---------------------------------------------------------------------------
function ApplyAllTalentModifiers()
	Timers:CreateTimer(0.1,function()
		local current_hero_list = HeroList:GetAllHeroes()
		for k,v in pairs(current_hero_list) do
			local hero_name = string.match(v:GetName(),"npc_dota_hero_(.*)")
			for i = 1, 8 do
				local talent_name = "special_bonus_imba_"..hero_name.."_"..i
				local modifier_name = "modifier_special_bonus_imba_"..hero_name.."_"..i
				if v:HasTalent(talent_name) and not v:HasModifier(modifier_name) then
					v:AddNewModifier(v,v,modifier_name,{})
				end
			end
		end
		return 0.5
	end)
end
-----------------------------------------------------------------------------------------------------------
------------------------------------\--/-------------------------------------------------------------------
-------------------------------------||--------------------------------------------------------------------
-- AABS -----------------------------||--------------------------------------------------------------------
-------------------------------------||--------------------------------------------------------------------
-------------------------------------\/--------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------
-- Get all players
---------------------------------------------------------------------------
function GetAllPlayers(bOnlyWithHeroes)
	local Players = {}
	for playerID = 0, DOTA_MAX_TEAM_PLAYERS-1  do
		if PlayerResource:IsValidPlayerID(playerID) then
			local player = PlayerResource:GetPlayer(playerID)
			if player and ((bOnlyWithHeroes and player:GetAssignedHero()) or not bOnlyWithHeroes) then
				table.insert(Players, player)
			end
		end
	end
	return Players
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function CreateTeamNotificationSettings(team, bSecond)
	local textColor = ColorTableToCss(Teams:GetColor(team))
	return {text = Teams:GetName(team, bSecond), continue = true, style = {color = textColor}}
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function CreateItemNotificationSettings(sItemName)
	return {text= "#DOTA_Tooltip_ability_" .. sItemName, duration=7.0, continue=true, style={color="orange"}}
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function GetDOTATimeInMinutesFull()
	return math.floor(GameRules:GetDOTATime(false, false)/60)
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function CreatePortal(vLocation, vTarget, iRadius, sParticle, sDisabledParticle, bEnabled, fOptionalActOnTeleport, sOptionalName)
	local unit = CreateUnitByName("npc_dummy_unit", vLocation, false, nil, nil, DOTA_TEAM_NEUTRALS)
	unit.Teleport_Radius = iRadius
	unit.Teleport_Target = vTarget
	unit.Teleport_ParticleName = sParticle
	unit.Teleport_DisabledParticleName = sDisabledParticle
	unit.Teleport_ActionOnTeleport = fOptionalActOnTeleport
	unit.Teleport_Name = sOptionalName
	unit.Teleport_Enabled = not bEnabled
	unit:AddAbility("teleport_passive")
	if bEnabled then
		unit:EnablePortal()
	else
		unit:DisablePortal()
	end
	return unit
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function CreateLoopedPortal(point1, point2, iRadius, sParticle, sDisabledParticle, bEnabled, fOptionalActOnTeleport, sOptionalName)
	for i = 1, 2 do
		local point
		local target
		if i == 1 then
			point = point1
			target = point2
		else
			point = point2
			target = point1
		end
		local unit = CreateUnitByName("npc_dummy_unit", point, false, nil, nil, DOTA_TEAM_NEUTRALS)
		unit.Teleport_Radius = iRadius
		unit.Teleport_Target = target
		unit.Teleport_ParticleName = sParticle
		unit.Teleport_DisabledParticleName = sDisabledParticle
		unit.Teleport_ActionOnTeleport = fOptionalActOnTeleport
		unit.Teleport_Name = sOptionalName
		unit.Teleport_Enabled = not bEnabled
		unit.Teleport_Looped = true
		unit:AddAbility("teleport_passive")
		if bEnabled then
			unit:EnablePortal()
		else
			unit:DisablePortal()
		end
	end
	return unit
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function CreateGoldNotificationSettings(amount)
	return {text=amount, continue=true, style={color="gold"}}, {text="#notifications_gold", continue=true, style={color="gold"}}
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function GetEnemiesIds(heroteam)
	local enemies = {}
	for _,playerID in ipairs(GetAllPlayers(false)) do
		if PlayerResource:GetTeam(playerID:GetPlayerID()) ~= heroteam then
			table.insert(enemies, playerID)
		end
	end
	return enemies
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function GenerateAttackProjectile(unit, optAbility)
	local projectile_info = {}
	projectile_info = {
		EffectName = unit:GetKeyValue("ProjectileModel"),
		Ability = optAbility,
		vSpawnOrigin = unit:GetAbsOrigin(),
		Source = unit,
		bHasFrontalCone = false,
		iMoveSpeed = unit:GetKeyValue("ProjectileSpeed") or 99999,
		bReplaceExisting = false,
		bProvidesVision = false
	}
	return projectile_info
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function FindFountain(team)
	return Entities:FindByName(nil, "npc_arena_fountain_" .. team)
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function HasDamageFlag(damage_flags, flag)
	return bit.band(damage_flags, flag) == flag
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function DrugEffectStrangeMove(target, amplitude)
	if not target:IsStunned() then
		FindClearSpaceForUnit(target, target:GetAbsOrigin() + Vector(RandomInt(-amplitude, amplitude), RandomInt(-amplitude, amplitude), 0), false)
	end
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function DrugEffectRandomParticles(target, duration)
	--TODO Different particles
	for _,v in ipairs(FindUnitsInRadius(target:GetTeamNumber(), target:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)) do
		local particle = ParticleManager:CreateParticleForPlayer("particles/dark_smoke_test.vpcf", PATTACH_ABSORIGIN, v, target:GetPlayerOwner())
		Timers:CreateTimer(duration, function()
			ParticleManager:DestroyParticle(particle, false)
		end)
	end
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function GetDrugDummyAbility(itemName)
	local abilityName = string.gsub(itemName, "item_", "dummy_drug_")
	local ability = DRUG_DUMMY:AddAbility(abilityName)
	return ability
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function GetLevelValue(value, level)
	local split = {}
	for i in string.gmatch(value, "%S+") do
		table.insert(split, i)
	end
	if i[level+1] then
		return split[level+1]
	end
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function PreformAbilityPrecastActions(unit, ability)
	if ability:IsCooldownReady() and ability:IsOwnersManaEnough() then
		ability:PayManaCost()
		ability:AutoStartCooldown()
		--ability:UseResources(true, true, true) -- not works with items?
		return true
	end
	return false
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function ReplaceAbilities(unit, oldAbility, newAbility, keepLevel, keepCooldown)
	local ability = unit:FindAbilityByName(oldAbility)
	local level = ability:GetLevel()
	local cooldown = ability:GetCooldownTimeRemaining()
	unit:RemoveAbility(oldAbility)
	local new_ability = unit:AddAbility(newAbility)
	if keepLevel then
		new_ability:SetLevel(level)
	end
	if keepCooldown then
		new_ability:StartCooldown(cooldown)
	end
	return new_ability
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function PreformMulticast(caster, ability_cast, multicast, multicast_delay, target)
	if ability_cast:IsMulticastable() then
		local prt = ParticleManager:CreateParticle('particles/units/heroes/hero_ogre_magi/ogre_magi_multicast.vpcf', PATTACH_OVERHEAD_FOLLOW, caster)
		ParticleManager:SetParticleControl(prt, 1, Vector(multicast, 0, 0))
		prt = ParticleManager:CreateParticle('particles/units/heroes/hero_ogre_magi/ogre_magi_multicast_b.vpcf', PATTACH_OVERHEAD_FOLLOW, caster:GetCursorCastTarget() or caster)
		prt = ParticleManager:CreateParticle('particles/units/heroes/hero_ogre_magi/ogre_magi_multicast_b.vpcf', PATTACH_OVERHEAD_FOLLOW, caster)
		prt = ParticleManager:CreateParticle('particles/units/heroes/hero_ogre_magi/ogre_magi_multicast_c.vpcf', PATTACH_OVERHEAD_FOLLOW, caster:GetCursorCastTarget() or caster)
		ParticleManager:SetParticleControl(prt, 1, Vector(multicast, 0, 0))
		CastMulticastedSpell(caster, ability_cast, target, multicast-1, multicast_delay)
	end
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function CastMulticastedSpell(caster, ability, target, multicasts, delay)
	if multicasts >= 1 then
		Timers:CreateTimer(delay, function()
			CastAdditionalAbility(caster, ability, target)
			caster:EmitSound('Hero_OgreMagi.Fireblast.x'.. multicasts)
			if multicasts >= 2 then
				CastMulticastedSpell(caster, ability, target, multicasts - 1, delay)
			end
		end)
	end
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function CastAdditionalAbility(caster, ability, target)
	local skill = ability
	local unit = caster
	local channelled = false
	if ability:HasBehavior(DOTA_ABILITY_BEHAVIOR_CHANNELLED) then
		local dummy = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
		--TODO сделать чтобы дамаг от скилла умножался от инты.
		for i = 0, DOTA_ITEM_SLOT_9 do
			local citem = caster:GetItemInSlot(i)
			if citem then
				dummy:AddItem(CopyItem(citem))
			end
		end
		if caster:HasScepter() then dummy:AddNewModifier(caster, nil, "modifier_item_ultimate_scepter", {}) end
		dummy:SetControllableByPlayer(caster:GetPlayerID(), true)
		dummy:SetOwner(caster)
		dummy:SetAbsOrigin(caster:GetAbsOrigin())
		dummy.GetStrength = function()
			return caster:GetStrength()
		end
		dummy.GetAgility = function()
			return caster:GetAgility()
		end
		dummy.GetIntellect = function()
			return caster:GetIntellect()
		end
		skill = dummy:AddAbility(ability:GetName())
		unit = dummy
		skill:SetLevel(ability:GetLevel())
		channelled = true
	end
	if skill:HasBehavior(DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) then
		if target and type(target) == "table" then
			unit:SetCursorCastTarget(target)
		end
	elseif skill:HasBehavior(DOTA_ABILITY_BEHAVIOR_POINT) then
		if target and target.x and target.y and target.z then
			unit:SetCursorPosition(target)
		end
	end
	skill:OnSpellStart()
	if channelled then
		Timers:CreateTimer(0.03, function()
			if not caster:IsChanneling() then
				skill:EndChannel(true)
				skill:OnChannelFinish(true)
				Timers:CreateTimer(0.03, function()
					if skill then UTIL_Remove(skill) end
					if unit then UTIL_Remove(unit) end
				end)
			else
				return 0.03
			end
		end)
	end
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function IsHeroInAbilityPhase(unit)
	for i = 0, unit:GetAbilityCount()-1 do
		local ability = unit:GetAbilityByIndex(i)
		if ability and ability.IsInAbilityPhase and ability:IsInAbilityPhase() then
			return true
		end
	end
	for i = 0, 5 do
		local item = unit:GetItemInSlot(i)
		if item and item.IsInAbilityPhase and item:IsInAbilityPhase() then
			return true
		end
	end
	return false
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function GetAllAbilitiesCooldowns(unit)
	local cooldowns = {}
	for i = 0, unit:GetAbilityCount()-1 do
		local ability = unit:GetAbilityByIndex(i)
		if ability then
			table.insert(cooldowns, ability:GetReducedCooldown())
		end
	end
	return cooldowns
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function RefreshAbilities(unit, tExceptions)
	for i = 0, unit:GetAbilityCount()-1 do
		local ability = unit:GetAbilityByIndex(i)
		if ability and (not tExceptions or not tExceptions[ability:GetAbilityName()]) then
			ability:EndCooldown()
		end
	end
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function RefreshItems(unit, tExceptions)
	for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
		local item = unit:GetItemInSlot(i)
		if item and (not tExceptions or not tExceptions[item:GetAbilityName()]) then
			item:EndCooldown()
		end
	end
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
--illusion_incoming_damage = tooltip - 100
--illusion_outgoing_damage = tooltip - 100
function CreateIllusion(unit, ability, illusion_origin, illusion_incoming_damage, illusion_outgoing_damage, illusion_duration)
	local heroname = unit:GetFullName()
	local unitname = unit:GetUnitName()
	local illusion = CreateUnitByName(unitname, illusion_origin, true, unit, unit:GetPlayerOwner(), unit:GetTeamNumber())
	FindClearSpaceForUnit(illusion, illusion_origin, true)
	illusion:SetModelScale(unit:GetModelScale())
	illusion:SetControllableByPlayer(unit:GetPlayerID(), true)

	local caster_level = unit:GetLevel()
	for i = 1, caster_level - 1 do
		illusion:HeroLevelUp(false)
	end

	illusion:SetAbilityPoints(0)
	for slot_ability = 0, unit:GetAbilityCount()-1 do
		local illusion_ability = illusion:GetAbilityByIndex(slot_ability)
		local unit_ability = unit:GetAbilityByIndex(slot_ability)

		if unit_ability then
			local newName = unit_ability:GetAbilityName()
			if illusion_ability then
				if illusion_ability:GetAbilityName() ~= newName then
					illusion:RemoveAbility(illusion_ability:GetAbilityName())
					illusion_ability = illusion:AddNewAbility(newName, true)
				end
			else
				illusion_ability = illusion:AddNewAbility(newName, true)
			end
			illusion_ability:SetHidden(unit_ability:IsHidden())
			local ualevel = unit_ability:GetLevel()
			if ualevel > 0 and illusion_ability:GetAbilityName() ~= "meepo_divided_we_stand" then
				illusion_ability:SetLevel(ualevel)
			end
		elseif illusion_ability then
			illusion:RemoveAbility(illusion_ability:GetAbilityName())
		end
	end
	for item_slot = 0, 5 do
		local item = unit:GetItemInSlot(item_slot)
		if item then
			local illusion_item = illusion:AddItem(CreateItem(item:GetName(), illusion, illusion))
			illusion_item:SetCurrentCharges(item:GetCurrentCharges())
		end
	end
	illusion:SetHealth(unit:GetHealth())
	illusion:SetMana(unit:GetMana())
	illusion:AddNewModifier(unit, ability, "modifier_illusion", {duration = illusion_duration, outgoing_damage = illusion_outgoing_damage, incoming_damage = illusion_incoming_damage})
	illusion:MakeIllusion()
	if unit.Additional_str then
		illusion:ModifyStrength(unit.Additional_str)
	end
	if unit.Additional_agi then
		illusion:ModifyAgility(unit.Additional_agi)
	end
	if unit.Additional_int then
		illusion:ModifyIntellect(unit.Additional_int)
	end
	if unit.Additional_attackspeed then
		if not illusion:HasModifier("modifier_item_shard_attackspeed_stack") then
			illusion:AddNewModifier(caster, nil, "modifier_item_shard_attackspeed_stack", {})
		end
		local mod = illusion:FindModifierByName("modifier_item_shard_attackspeed_stack")
		if mod then
			mod:SetStackCount(unit.Additional_attackspeed)
		end
	end
	illusion.UnitName = unit.UnitName
	illusion:SetNetworkableEntityInfo("unit_name", illusion:GetFullName())
	if not NPC_HEROES[heroname] and NPC_HEROES_CUSTOM[heroname] then
		TransformUnitClass(illusion, NPC_HEROES_CUSTOM[heroname], true)
	end
	if unit:GetModelName() ~= illusion:GetModelName() then
		illusion.ModelOverride = unit:GetModelName()
		illusion:SetModel(illusion.ModelOverride)
		illusion:SetOriginalModel(illusion.ModelOverride)
	end
	local rc = unit:GetRenderColor()
	if rc ~= Vector(255, 255, 255) then
		illusion:SetRenderColor(rc.x, rc.y, rc.z)
	end

	return illusion
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function PerformGlobalAttack(unit, hTarget, bUseCastAttackOrb, bProcessProcs, bSkipCooldown, bIgnoreInvis, bUseProjectile, bFakeAttack, bNeverMiss, AttackFuncs)
	local abs = unit:GetAbsOrigin()
	unit:SetAbsOrigin(hTarget:GetAbsOrigin())
	SafePerformAttack(unit, hTarget, bUseCastAttackOrb, bProcessProcs, bSkipCooldown, bIgnoreInvis, bUseProjectile, bFakeAttack, bNeverMiss, AttackFuncs)
	unit:SetAbsOrigin(abs)
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function SafePerformAttack(unit, hTarget, bUseCastAttackOrb, bProcessProcs, bSkipCooldown, bIgnoreInvis, bUseProjectile, bFakeAttack, bNeverMiss, AttackFuncs)
	--bNoSplashesMelee, bNoSplashesRanged, bNoDoubleAttackMelee, bNoDoubleAttackRanged
	if AttackFuncs then
		if not unit.AttackFuncs then unit.AttackFuncs = {} end
		table.merge(unit.AttackFuncs, AttackFuncs)
	end
	unit:PerformAttack(hTarget,bUseCastAttackOrb,bProcessProcs,bSkipCooldown,bIgnoreInvis,bUseProjectile,bFakeAttack,bNeverMiss)
	unit.AttackFuncs = nil
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function UniqueRandomInts(min, max, count)
	local output = {}
	while #output < count do
		local r = RandomInt(min, max)
		if not table.contains(output, r) then
			table.insert(output, r)
		end
	end
	return output
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function ColorTableToCss(color)
	return "rgb(" .. color[1] .. ',' .. color[2] .. ',' .. color[3] .. ')'
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function IsPlayerAbandoned(playerID)
	return PLAYER_DATA[playerID].IsAbandoned == true
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function FindAllOwnedUnits(player)
	local summons = {}
	local pid = type(player) == "number" and player or player:GetPlayerID()
	local units = FindUnitsInRadius(PlayerResource:GetTeam(pid), Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED, FIND_ANY_ORDER, false)
	for _,v in ipairs(units) do
		if type(player) == "number" and ((v.GetPlayerID ~= nil and v:GetPlayerID() or v:GetPlayerOwnerID()) == pid) or v:GetPlayerOwner() == player then
			if not (v:HasModifier("modifier_dummy_unit") or v:HasModifier("modifier_containers_shopkeeper_unit") or v:HasModifier("modifier_teleport_passive")) and v ~= hero then
				table.insert(summons, v)
			end
		end
	end
	return summons
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function RemoveAllOwnedUnits(playerId)
	local player = PlayerResource:GetPlayer(playerId)
	local hero = PlayerResource:GetSelectedHeroEntity(playerId)
	local courier = FindCourier(PlayerResource:GetTeam(playerId))
	for _,v in ipairs(FindAllOwnedUnits(player or playerId)) do
		if v ~= hero and v ~= courier then
			v:ClearNetworkableEntityInfo()
			v:ForceKill(false)
			UTIL_Remove(v)
		end
	end
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function GetTeamPlayerCount(iTeam)
	local counter = 0
	for i = 0, 23 do
		if PlayerResource:IsValidPlayerID(i) and not IsPlayerAbandoned(i) and PlayerResource:GetTeam(i) == iTeam then
			counter = counter + 1
		end
	end
	return counter
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function GetTeamAbandonedPlayerCount(iTeam)
	local counter = 0
	for i = 0, 23 do
		if PlayerResource:IsValidPlayerID(i) and IsPlayerAbandoned(i) and PlayerResource:GetTeam(i) == iTeam then
			counter = counter + 1
		end
	end
	return counter
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function GetOneRemainingTeam()
	local teamLeft
	for i = DOTA_TEAM_FIRST, DOTA_TEAM_CUSTOM_MAX do
		local count = GetTeamPlayerCount(i)
		if count > 0 then
			if teamLeft then
				return
			else
				teamLeft = i
			end
		end
	end
	return teamLeft
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function CopyItem(item)
	local newItem = CreateItem(item:GetAbilityName(), caster, caster)
	newItem:SetPurchaseTime(item:GetPurchaseTime())
	newItem:SetPurchaser(item:GetPurchaser())
	newItem:SetOwner(item:GetOwner())
	newItem:SetCurrentCharges(item:GetCurrentCharges())
	return newItem
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function math.round(x)
	if x%2 ~= 0.5 then
		return math.floor(x+0.5)
	end
	return x-0.5
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function SafeHeal(unit, flAmount, hInflictor, overhead)
	if unit:IsAlive() then
		unit:Heal(flAmount, hInflictor)
		if overhead then
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, unit, flAmount, nil)
		end
	end
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function InvokeCheatCommand(s)
	Convars:SetInt("sv_cheats", 1)
	SendToServerConsole(s)
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function CreateSimpleBox(point1, point2)
	local hlen = point2.y-point1.y
	local cen = point1.y+hlen/2
	local new1 = Vector(point1.x, cen, 0)
	local new2 = Vector(point2.x, cen, point2.y)
	return Physics:CreateBox(new2, new1, hlen, true)
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function FindUnitsInBox(teamNumber, vStartPos, vEndPos, cacheUnit, teamFilter, typeFilter, flagFilter)
	local hlen = (vEndPos.y-vStartPos.y) / 2
	local cen = vStartPos.y+hlen
	vStartPos.y = cen
	vEndPos.y = cen
	vStartPos.z = 0
	vEndPos.z = 0
	return FindUnitsInLine(teamNumber, vStartPos, vEndPos, cacheUnit, hlen, teamFilter, typeFilter, flagFilter)
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function GetTrueItemCost(name)
	local cost = GetItemCost(name)
	if cost <= 0 then
		local tempItem = CreateItem(name, nil, nil)
		if not tempItem then
			print("[GetTrueItemCost] Warning: " .. name)
		else
			cost = tempItem:GetCost()
			UTIL_Remove(tempItem)
		end
	end
	return cost
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function FindNearestEntity(vec3, units)
	local unit
	local range
	for _,v in ipairs(units) do
		if not range or (v:GetAbsOrigin()-vec3):Length2D() < range then
			unit = v
			range = (v:GetAbsOrigin()-vec3):Length2D()
		end
	end
	return unit
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function FindCourier(team)
	if type(TEAMS_COURIERS[team]) == "table" then
		return TEAMS_COURIERS[team]
	end
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function GetNotScaledDamage(damage, unit)
	return math.floor(damage/(1 + Attributes:GetTotalGrantedSpellAmplify(unit) / 100) + 0.5)
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function IsUltimateAbility(ability)
	return bit.band(ability:GetAbilityType(), 1) == 1
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function IsUltimateAbilityKV(abilityname)
	return GetKeyValue(abilityname, "AbilityType") == "DOTA_ABILITY_TYPE_ULTIMATE"
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function RandomPositionAroundPoint(pos, radius)
	return RotatePosition(pos, QAngle(0, RandomInt(0,359), 0), pos + Vector(1, 1, 0) * RandomInt(0, radius))
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function EvalString(str)
	return DebugCallFunction(loadstring(str))
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function GetPlayersInTeam(team)
	local players = {}
	for playerID = 0, DOTA_MAX_TEAM_PLAYERS-1  do
		if PlayerResource:IsValidPlayerID(playerID) and (not team or PlayerResource:GetTeam(playerID) == team) and not PLAYER_DATA[playerID].IsAbandoned then
			table.insert(players, playerID)
		end
	end
	return players
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function RemoveAbilityWithModifiers(unit, ability)
	for _,v in ipairs(unit:FindAllModifiers()) do
		if v:GetAbility() == ability then
			v:Destroy()
		end
	end
	if ability.DestroyHookParticles then
		ability:DestroyHookParticles()
	end
	unit:RemoveAbility(ability:GetAbilityName())
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function CreateGlobalParticle(name, callback, pattach)
	local ps = {}
	for team = DOTA_TEAM_FIRST, DOTA_TEAM_CUSTOM_MAX do
		local f = FindFountain(team)
		if f then
			local p = ParticleManager:CreateParticleForTeam(name, pattach or PATTACH_WORLDORIGIN, f, team)
			callback(p)
			table.insert(ps, p)
		end
	end
	return ps
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function WorldPosToMinimap(vec)
	local pct1 = (vec.x + MAP_LENGTH) / (MAP_LENGTH * 2)
	local pct2 = (MAP_LENGTH - vec.y) / (MAP_LENGTH * 2)
	return pct1*100 .. "% " .. pct2*100 .. "%"
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function GetHeroTableByName(name)
	local output = {}
	local custom = NPC_HEROES_CUSTOM[name]
	if not custom then
		print("[GetHeroTableByName] Missing hero: " .. name)
		return
	end
	if custom.base_hero then
		table.merge(output, GetUnitKV(custom.base_hero))
		for i = 1, 24 do
			output["Ability" .. i] = nil
		end
		table.merge(output, custom)
	else
		table.merge(output, GetUnitKV(name))
	end
	return output
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function CreateExplosion(position, minRadius, fullRdius, minForce, fullForce, teamNumber, teamFilter, typeFilter, flagFilter)
	for _,v in ipairs(FindUnitsInRadius(teamNumber, position, nil, fullRdius, teamFilter, typeFilter, flagFilter, FIND_CLOSEST, false)) do
		if IsPhysicsUnit(v) then
			local force = 0
			local len = (position - v:GetAbsOrigin()):Length2D()
			if len < minRadius then
				force = fullForce
			elseif len <= fullRdius then
				local forceNotFullLen = fullRdius - minRadius
				local forceMid = fullForce - minForce
				local forceLevel = (fullRdius - len)/forceNotFullLen
				force = minForce + (forceMid*forceLevel)
			end
			local velocity = (v:GetAbsOrigin() - position):Normalized() * force
			v:AddPhysicsVelocity(velocity)
		end
	end
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function IsInBox(point, point1, point2)
	return point.x > point1.x and point.y > point1.y and point.x < point2.x and point.y < point2.y
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function GetConnectionState(pid)
	if DebugConnectionStates then
		local map = {
			[3] = "DOTA_CONNECTION_STATE_DISCONNECTED",
			[6] = "DOTA_CONNECTION_STATE_FAILED",
			[0] = "DOTA_CONNECTION_STATE_UNKNOWN",
			[1] = "DOTA_CONNECTION_STATE_NOT_YET_CONNECTED",
			[4] = "DOTA_CONNECTION_STATE_ABANDONED",
			[2] = "DOTA_CONNECTION_STATE_CONNECTED",
			[5] = "DOTA_CONNECTION_STATE_LOADING",
		}
		CPrint(pid, map[PlayerResource:GetConnectionState(pid)])
	end
	return PlayerResource:IsFakeClient(pid) and DOTA_CONNECTION_STATE_CONNECTED or PlayerResource:GetConnectionState(pid)
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function DebugCallFunction(fun)
	local status, nextCall = xpcall(fun, function (msg)
		return msg..'\n'..debug.traceback()..'\n'
	end)
	if not status then
		Timers:HandleEventError(nil, nil, nextCall)
	end
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function GetInGamePlayerCount()
	local counter = 0
	for i = 0, 23 do
		if PlayerResource:IsValidPlayerID(i) then
			counter = counter + 1
		end
	end
	return counter
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function GetTeamAllPlayerCount(iTeam)
	local counter = 0
	for i = 0, 23 do
		if PlayerResource:IsValidPlayerID(i) then
			if PlayerResource:GetTeam(i) == iTeam then
				counter = counter + 1
			end
		end
	end
	return counter
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function Lifesteal(ability, unit, target, damage)
	local target = keys.target
	local lifesteal = keys.damage * keys.percent * 0.01
	SafeHeal(caster, lifesteal, keys.ability, true)
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function RecreateAbility(unit, ability)
	local name = ability:GetAbilityName()
	local level = ability:GetLevel()
	RemoveAbilityWithModifiers(unit, ability)
	ability = unit:AddNewAbility(name, true)
	if ability then
		ability:SetLevel(level)
	end
	return ability
end
---------------------------------------------------------------------------
-- ??
---------------------------------------------------------------------------
function CDOTA_Buff:SetSharedKey(key, value)
	local t = CustomNetTables:GetTableValue("shared_modifiers", self:GetParent():GetEntityIndex() .. "_" .. self:GetName()) or {}
	t[key] = value
	CustomNetTables:SetTableValue("shared_modifiers", self:GetParent():GetEntityIndex() .. "_" .. self:GetName(), t)
end
---------------------------------------------------------------------------
-- ??
--  By Noya, from DotaCraft
---------------------------------------------------------------------------
function GetPreMitigationDamage(value, victim, attacker, damagetype)
	if damagetype == DAMAGE_TYPE_PHYSICAL then
		local armor = victim:GetPhysicalArmorValue()
		local reduction = ((armor)*0.06) / (1+0.06*(armor))
		local damage = value / (1 - reduction)
		return damage,reduction
	elseif damagetype == DAMAGE_TYPE_MAGICAL then
		local reduction = victim:GetMagicalArmorValue()*0.01
		local damage = value / (1 - reduction)

		return damage,reduction
	else
		return value,0
	end
end
---------------------------------------------------------------------------
--  ??
---------------------------------------------------------------------------
function SimpleDamageReflect(victim, attacker, damage, flags, ability, damage_type)
	if victim:IsAlive() and not HasDamageFlag(flags, DOTA_DAMAGE_FLAG_REFLECTION) and attacker:GetTeamNumber() ~= victim:GetTeamNumber() then
		--print("Reflected " .. damage .. " damage from " .. victim:GetUnitName() .. " to " .. attacker:GetUnitName())
		ApplyDamage({
			victim = attacker,
			attacker = victim,
			damage = damage,
			damage_type = damage_type,
			damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_REFLECTION,
			ability = ability
		})
		return true
	end
	return false
end
---------------------------------------------------------------------------
--  ??
---------------------------------------------------------------------------
function GetLinkedHeroNames(hero)
	local linked = GetKeyValue(hero, "LinkedHero")
	return linked and string.split(linked, " | ") or {}
end
---------------------------------------------------------------------------
--  ??
---------------------------------------------------------------------------
function IsModifierStrongest(unit, modifier, modifierList)
	local ind = modifierList[modifier]
	if not ind then return false end
	for v,i in pairs(modifierList) do
		if unit:HasModifier(v) and i > ind then
			return false
		end
	end
	return true
end
---------------------------------------------------------------------------
--  ??
---------------------------------------------------------------------------
function GetDirectoryFromPath(path)
	return path:match("(.*[/\\])")
end
---------------------------------------------------------------------------
--  ??
---------------------------------------------------------------------------
function ModuleRequire(this, fileName)
	return require(GetDirectoryFromPath(this) .. fileName)
end
---------------------------------------------------------------------------
--  ??
---------------------------------------------------------------------------
function ModuleLinkLuaModifier(this, className, fileName, LuaModifierType)
	return LinkLuaModifier(className, GetDirectoryFromPath(this) .. (fileName or className), LuaModifierType or LUA_MODIFIER_MOTION_NONE)
end
---------------------------------------------------------------------------
--  ??
---------------------------------------------------------------------------
function pluralize(n, one, many)
	return n == 1 and one or (many or one .. "s")
end
---------------------------------------------------------------------------
--  ??
---------------------------------------------------------------------------
function iif(cond, yes, no)
	if cond then return yes else return no end
end
---------------------------------------------------------------------------
--  ??
---------------------------------------------------------------------------
function RemoveAllUnitsByName(name)
	local units = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
	for _,v in ipairs(units) do
		if v:GetUnitName():match(name) then
			v:ClearNetworkableEntityInfo()
			v:ForceKill(false)
			UTIL_Remove(v)
		end
	end
end