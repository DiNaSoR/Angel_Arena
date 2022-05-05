LOD_AI_VERSION = "0.1"
--------------------------------------------------------------
-- Setting
--------------------------------------------------------------
LOD_SOUNDBOX 	= {	"angel_arena.spawnadd01", 
					"angel_arena.spawnadd02", 
					"angel_arena.spawnadd03", 
					"angel_arena.spawnadd04"
				  }		

LOD_DIALOG 		= {	"YOU THINK YOU CAN TAKE ME?",
					"FOOL!",
					"DESPICABLE INSECTS!",
					"YOU DARE COMING TO MY DOMAIN!" 
				  }
--------------------------------------------------------------
-- InitGameMode
--------------------------------------------------------------
function 	Spawn( entityKeyValues )
	print("[Angel Arena] Starting AI for "..thisEntity:GetUnitName().." "..LOD_AI_VERSION)			
	lodbossskill 		= thisEntity:FindAbilityByName("skill_lordofdeath_boss_skill")
	lodbossmobs 		= thisEntity:FindAbilityByName("skill_lordofdeath_boss_mobs")
	lodbossdive 		= thisEntity:FindAbilityByName("skill_lordofdeath_boss_dive")
	lodbosssplitter 	= thisEntity:FindAbilityByName("elder_titan_earth_splitter")

	thisEntity:SetContextThink( "Fightingskills", Fightingskills , 1)
	thisEntity:SetContextThink( "AIThinking", AIThinking , 0.5)
	thisEntity:SetContextThink("CastItemName", CastItemName, 0.5)
	spawnmobslimit = true
	

end
--------------------------------------------------------------
-- AI Behavior
--------------------------------------------------------------
function AIThinking()

	local point = Vector(6224.55, -3831.79, -1021.27)
	local units = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 1300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false)
    
    if thisEntity:IsNull() or not thisEntity:IsAlive() then
        return nil
    end	

    if (point - thisEntity:GetOrigin()):Length2D() > 1400 then
        thisEntity:MoveToPosition(point)
    end
 
    return 0.5;
end


--//--------------------------------------------------------------------------------------
--//	cast Urn
--//--------------------------------------------------------------------------------------
function CastItemName()
	--print("CastItemNmae run")
	local healthRemaining = thisEntity:GetHealth() / thisEntity:GetMaxHealth()
	local units = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 950, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false)
	local index = RandomInt( 1, #units )
	local target = units[index]
	if units ~= nil then
		if #units >= 1 then
		    for i=0,5 do
		        local item = thisEntity:GetItemInSlot(i)
		        --if item and item:GetAbilityName() == "item_urn_of_shadows" and (target:GetAbsOrigin() - thisEntity:GetAbsOrigin()):Length2D() > 700 then
		        	--print("casting urn")
		            --thisEntity:CastAbilityOnTarget(target, item, -1)

				if item and item:GetAbilityName() == "item_shivas_guard" and healthRemaining <= 0.75 then
		        	--print("casting Shiva Guard")
		            thisEntity:CastAbilityNoTarget(item, -1)

		        elseif item and item:GetAbilityName() == "item_lotus_orb" and healthRemaining <= 0.85 then
		        	--print("casting Lotus Orb")
		            thisEntity:CastAbilityOnTarget(thisEntity, item, -1)

		        elseif item and item:GetAbilityName() == "item_blade_mail" and healthRemaining <= 0.95 then
		        	--print("casting Blade Mail")
		            thisEntity:CastAbilityNoTarget(item, -1)
				else

		        end
		    end
		end
	end
	return 1
end
--------------------------------------------------------------
-- AI Fighting Skills
--------------------------------------------------------------
function Fightingskills()
local healthRemaining = thisEntity:GetHealth() / thisEntity:GetMaxHealth()

	if lodbosssplitter:IsFullyCastable() then
		local units = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false)

		if units ~= nil then
			if #units >= 1 then
				
				local index = RandomInt( 1, #units )
				local target = units[index]

				thisEntity:CastAbilityOnPosition(target:GetAbsOrigin(), lodbosssplitter, -1)
				
			else
				
			end
		end
	end


	if lodbossskill:IsFullyCastable() then
		local units = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false)

		if units ~= nil then
			if #units >= 1 then
				
				local index = RandomInt( 1, #units )
				local target = units[index]

				--thisEntity:CastAbilityNoTarget(lodbossskill, -1)
				thisEntity:CastAbilityOnPosition(target:GetAbsOrigin(), lodbossskill, -1)
				
			else
				
			end
		end
	end

	if lodbossmobs:IsFullyCastable() and healthRemaining <= 0.5 and spawnmobslimit == true then
		local units = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false)

		if units ~= nil then
			if #units >= 1 then
				
				local index = RandomInt( 1, #units )
				local target = units[index]
				dialoglod()
				EmitGlobalSound(LOD_SOUNDBOX[RandomInt(1,4)])
				thisEntity:CastAbilityNoTarget(lodbossmobs, -1)

				
			else
				
			end
		end
		spawnmobslimit = false
		Timers:CreateTimer(30, -- Start this timer 10 game-time seconds later
		  function()
			spawnmobslimit = true 
		  end)
	end
	if lodbossdive:IsFullyCastable() then

		local units = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false)

		if units ~= nil then
			if #units >= 1 then
				
				local index = RandomInt( 1, #units )
				local target = units[index]
				
				thisEntity:CastAbilityNoTarget(lodbossdive, -1)
				
			    
			else
				
			end
		end
	end
	return 1
end

--------------------------------------------------------------
-- Dialog
--------------------------------------------------------------
function dialoglod()
end

































--[[behaviorSystem = {} -- create the global so we can assign to it

function Spawn( entityKeyValues )
	local thinkInterval = (math.random(20) + 40)/100
	thisEntity:SetContextThink( "AIThink", AIThink, thinkInterval )
	thisEntity.owner = "forest_boss"
    behaviorSystem = AICore:CreateBehaviorSystem( { BehaviorNone, BasicSkill, DiveSkill, SplitterSkill, Die} ) 
end

function AIThink() -- For some reason AddThinkToEnt doesn't accept member functions
       return behaviorSystem:Think()
end

function CollectRetreatMarkers()

end
POSITIONS_retreat = CollectRetreatMarkers()

--------------------------------------------------------------------------------------------------------


function Begin()
	self.endTime = GameRules:GetGameTime() + 1

	local enemy =  AICore:RandomEnemyHeroInRange( thisEntity, 1300 )
	
	if enemy and not thisEntity.dead then
		print("order_attack_move")
		self.order =
		{
			UnitIndex = thisEntity:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
			Position = enemy:GetOrigin()
		}
	else
		self.order =
		{
			UnitIndex = thisEntity:entindex(),
		}
	end
end

function Continue()
	self.endTime = GameRules:GetGameTime() + 0.4
end

--------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------

BasicSkill = {}

function BasicSkill:Evaluate()
	local desire = 0
	print("evaluate basic skill")
	-- let's not choose this twice in a row
	if currentBehavior == self then return desire end

	self.baseAbility = thisEntity:FindAbilityByName( "forest_boss_skill" )
	
	if self.baseAbility and self.baseAbility:IsFullyCastable() and not thisEntity.dead then
		desire = 4
	end
	


	return desire
end

function BasicSkill:Begin()
	print("fire basic")
	self.endTime = GameRules:GetGameTime() + 1
		self.order =
		{
			UnitIndex = thisEntity:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
			AbilityIndex = self.baseAbility:entindex(),
		}
		ExecuteOrderFromTable(self.order)

end

BasicSkill.Continue = BasicSkill.Begin

--------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------

DiveSkill = {}

function DiveSkill:Evaluate()
	local desire = 0
	print("evaluate dive skill")
	-- let's not choose this twice in a row
	if currentBehavior == self then return desire end

	self.diveAbility = thisEntity:FindAbilityByName( "forest_boss_dive" )
	
	if self.diveAbility and self.diveAbility:IsFullyCastable() and not thisEntity.dead then
		desire = 3
	end
	


	return desire
end

function DiveSkill:Begin()
	print("fire dive")
	self.endTime = GameRules:GetGameTime() + 1
		self.order =
		{
			UnitIndex = thisEntity:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
			AbilityIndex = self.diveAbility:entindex(),
		}
		ExecuteOrderFromTable(self.order)
end

DiveSkill.Continue = DiveSkill.Begin

--------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------

SplitterSkill = {}

function SplitterSkill:Evaluate()
	local desire = 0
	print("evaluate Splitter skill")
	-- let's not choose this twice in a row
	if currentBehavior == self then return desire end

	self.SplitterAbility = thisEntity:FindAbilityByName( "forest_boss_splitter" )
	
	if self.SplitterAbility and self.SplitterAbility:IsFullyCastable() and not thisEntity.dead then
		desire = 8
	end
	


	return desire
end

function SplitterSkill:Begin()
	print("fire Splitter")
	self.endTime = GameRules:GetGameTime() + 1
		self.order =
		{
			UnitIndex = thisEntity:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
			AbilityIndex = self.SplitterAbility:entindex(),
		}
		ExecuteOrderFromTable(self.order)
end

SplitterSkill.Continue = SplitterSkill.Begin

--------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------

Die = {}
DEATH_SOUND_TABLE = {"nevermore_nev_arc_death_12"}
function Die:Evaluate()
	local desire = 0
	print("evaluate Splitter skill")
	-- let's not choose this twice in a row
	if thisEntity:GetHealth() < 10 and not thisEntity.dead then
   		desire = 15
	end

	return desire
end

function Die:Begin()
	print("Dying")
	self.endTime = GameRules:GetGameTime() + 13
		--ParticleCity(thisEntity)
		thisEntity.dead = true
		Events:updateKillQuest(thisEntity)
		local ability = thisEntity:FindAbilityByName( "cant_die" )
		ability:ApplyDataDrivenModifier(thisEntity, thisEntity, "modifier_dying", {duration = 13})
      	thisEntity:SetMoveCapability(DOTA_UNIT_CAP_MOVE_NONE)
      	thisEntity:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)
		Events:ForestBossKill(thisEntity)
      	StartAnimation(thisEntity, {duration=6.5, activity=ACT_DOTA_FLAIL, rate=0.8})
      	local sound = DEATH_SOUND_TABLE[1]
      	EmitGlobalSound(sound)
      	EmitGlobalSound(sound)
      	EmitGlobalSound(sound)
        Timers:CreateTimer(6.5, 
        function()
          EmitGlobalSound("nevermore_nev_ability_requiem_07")
          StartAnimation(thisEntity, {duration=6.1, activity=ACT_DOTA_DIE, rate=0.25})
         		Timers:CreateTimer(6.1, 
        		function()
        			
        			thisEntity:RemoveSelf()
        		end)
        end)   
end

Die.Continue = Die.Begin

--------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------




AICore.possibleBehaviors = { BehaviorNone, BasicSkill, DiveSkill, SplitterSkill, Die}]]