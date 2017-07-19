--[[
--------------------------------------------
Author: CryDeS
--------------------------------------------
item_table struct

{
	["item"] = { [1] = 10, [2] = 1, [3] = 3, [4] = 1} -- 1 - chance, 2 - min_count, 3 - max_count, 4 - priority
}

creep_drop_table_struct = 
{
	["my_little_creep"] = item_table
}
]]

local items = {
	["item_ward_observer"]			 = { [1] = 30, [2] = 1, [3] = 2, [4] = 1 },
	["item_slippers"]				 = { [1] = 30, [2] = 1, [3] = 1, [4] = 1 },
	["item_mantle"]					 = { [1] = 30, [2] = 1, [3] = 1, [4] = 1 },
	["item_gauntlets"]				 = { [1] = 30, [2] = 1, [3] = 1, [4] = 1 },
	["item_circlet"]				 = { [1] = 30, [2] = 1, [3] = 1, [4] = 1 },
	--["item_enchanted_mango"]		 = { [1] = 30, [2] = 1, [3] = 1, [4] = 1 },
	["item_ring_of_protection"]		 = { [1] = 30, [2] = 1, [3] = 1, [4] = 1 },
	
	["item_boots"]					 = { [1] = 30, [2] = 1, [3] = 1, [4] = 2 },
	["item_belt_of_strength"]		 = { [1] = 30, [2] = 1, [3] = 1, [4] = 2 },
	["item_boots_of_elves"]			 = { [1] = 30, [2] = 1, [3] = 1, [4] = 2 },
	["item_robe"]					 = { [1] = 30, [2] = 1, [3] = 1, [4] = 2 },
	["item_gloves"]					 = { [1] = 30, [2] = 1, [3] = 1, [4] = 2 },
	["item_bottle"]					 = { [1] = 30, [2] = 1, [3] = 1, [4] = 2 },
	["item_blight_stone"]			 = { [1] = 30, [2] = 1, [3] = 1, [4] = 2 },		
	["item_sobi_mask"]				 = { [1] = 30, [2] = 1, [3] = 1, [4] = 2 },	
	["item_ring_of_regen"] 			 = { [1] = 30, [2] = 1, [3] = 1, [4] = 2 },	
	
	["item_medallion_of_courage"]	 = { [1] = 30, [2] = 1, [3] = 1, [4] = 3 },
	["item_phase_boots"]			 = { [1] = 30, [2] = 1, [3] = 1, [4] = 3 },
	["item_power_treads"]			 = { [1] = 30, [2] = 1, [3] = 1, [4] = 3 },
	["item_arcane_boots"]			 = { [1] = 30, [2] = 1, [3] = 1, [4] = 3 },
	
	["item_solar_crest"]			 = { [1] = 30, [2] = 1, [3] = 1, [4] = 4 },
	["item_sange"]					 = { [1] = 30, [2] = 1, [3] = 1, [4] = 4 },
	["item_yasha"]					 = { [1] = 30, [2] = 1, [3] = 1, [4] = 4 },
	
	["item_tome_agi_60"]			 = { [1] = 50, [2] = 1, [3] = 3, [4] = 5 },
	["item_tome_int_60"]			 = { [1] = 50, [2] = 1, [3] = 3, [4] = 5 },
	["item_tome_str_60"]			 = { [1] = 50, [2] = 1, [3] = 3, [4] = 5 },
	["item_cursed_sange"]			 = { [1] = 45, [2] = 1, [3] = 1, [4] = 5 },
	["item_saint_yasha"]			 = { [1] = 45, [2] = 1, [3] = 1, [4] = 5 },
	["item_dead_boots"]				 = { [1] = 45, [2] = 1, [3] = 1, [4] = 5 },
	["item_angels_blood"]			 = { [1] = 60, [2] = 1, [3] = 1, [4] = 5 },
	["item_blessed_essence"]		 = { [1] = 50, [2] = 1, [3] = 1, [4] = 5 },

	["item_tome_un_60"]				 = { [1] = 50, [2] = 1, [3] = 3, [4] = 6 },
	["item_angels_blood"]			 = { [1] = 60, [2] = 1, [3] = 1, [4] = 5 },
	["item_icarus"]					 = { [1] = 45, [2] = 1, [3] = 1, [4] = 6 },
	["item_angels_armor"]			 = { [1] = 45, [2] = 1, [3] = 1, [4] = 6 },
	["item_possessed_sword"]		 = { [1] = 45, [2] = 1, [3] = 1, [4] = 6 },
	["item_awful_mask"] 			 = { [1] = 45, [2] = 1, [3] = 1, [4] = 6 },
	["item_angels_sword"]		 	 = { [1] = 60, [2] = 1, [3] = 1, [4] = 6 },
	["item_blessed_essence"]		 = { [1] = 50, [2] = 1, [3] = 1, [4] = 6 },

	["item_awful_mask"] 			 = { [1] = 60, [2] = 1, [3] = 1, [4] = 7 },
	["item_icarus"]					 = { [1] = 60, [2] = 1, [3] = 1, [4] = 7 },
	["item_skadi_2"]				 = { [1] = 60, [2] = 1, [3] = 1, [4] = 7 },
	["item_aegis_aa"]				 = { [1] = 60, [2] = 1, [3] = 1, [4] = 7 },
	["item_angels_blood"]			 = { [1] = 60, [2] = 1, [3] = 1, [4] = 7 },
	["item_angels_sword"]			 = { [1] = 60, [2] = 1, [3] = 1, [4] = 7 },
	["item_blessed_essence"]		 = { [1] = 50, [2] = 1, [3] = 1, [4] = 7 },
	["item_eclipse_amphora"]		 = { [1] = 45, [2] = 1, [3] = 1, [4] = 7 },
}

local monsters_names = {
	"Croco",
	"Centaur",
	"Salamander",
	"Dragon",
	"Wildwing",
	"Golem",
	"Troll",
	"Ursa"
}

function SetMonsterDrop(monsters_table, monstername, item_name, item_table)
	if not monsters_table[monstername] then
		monsters_table[monstername] = { }
	end
	monsters_table[monstername][item_name] = item_table
end



function SetMonsterDropOfTable(monsters_table, monstername, item_name, item_tables)
	SetMonsterDrop(monsters_table, monstername, item_name, item_tables[item_name])
end

function ExtendMonsterDrop(monsters_table, monstername, monstername2)
	if not monsters_table[monstername2] then
		return
	end
	if not monsters_table[monstername] then
		monsters_table[monstername] = {}
	end
	for i, x in pairs(monsters_table[monstername2]) do
		if not monsters_table[monstername][i] then
			monsters_table[monstername][i] = x
		end
	end
end

function SetMonstersDropByLevel(monsters_table, level, item_name, item_table)

	for _, x in pairs(monsters_names) do
		local name = x .. "_level_" .. level
		SetMonsterDropOfTable(monsters_table, name, item_name, item_table)
	end
end

function ExtendsMonsterDropsByLevels(monsters_table, level1, level2, item_table)

	for _, x in pairs(monsters_names) do 
		local name1 = x .. "_level_" .. level1
		local name2 = x .. "_level_" .. level2
		if not monsters_table[name1] then
			monsters_table[name1] = {}
		end
		for j, y in pairs(monsters_table[name2]) do
			if not monsters_table[name1][j] then
				monsters_table[name1][j] = item_table[j]
			end
		end

	end
end

function SetBossessDrop(monster_table, item_table)
	SetMonsterDropOfTable(monster_table, "npc_dota_custom_guardian", "item_cursed_sange", item_table)
	SetMonsterDropOfTable(monster_table, "npc_dota_custom_guardian", "item_saint_yasha", item_table)
	SetMonsterDropOfTable(monster_table, "npc_dota_custom_guardian", "item_dead_boots", item_table)
	SetMonsterDropOfTable(monster_table, "npc_dota_custom_guardian", "item_holy_book", item_table)
	SetMonsterDropOfTable(monster_table, "npc_dota_custom_guardian", "item_potion_immune", item_table)
	SetMonsterDropOfTable(monster_table, "npc_dota_custom_guardian", "item_angels_blood", item_table)
	SetMonsterDropOfTable(monster_table, "npc_dota_custom_guardian", "item_angels_sword", item_table)
	SetMonsterDropOfTable(monster_table, "npc_dota_custom_guardian", "item_blessed_essence", item_table)

	ExtendMonsterDrop(monster_table, "npc_monk_of_hate", "npc_dota_custom_guardian")
	ExtendMonsterDrop(monster_table, "npc_monk_of_love", "npc_dota_custom_guardian")
	ExtendMonsterDrop(monster_table, "npc_monk_of_life", "npc_dota_custom_guardian")
	ExtendMonsterDrop(monster_table, "npc_monk_of_death", "npc_dota_custom_guardian")
	ExtendMonsterDrop(monster_table, "npc_angel_of_hate", "npc_dota_custom_guardian")

	SetMonsterDropOfTable(monster_table, "npc_angel_of_hate", "item_tome_agi_60", item_table)
	SetMonsterDropOfTable(monster_table, "npc_angel_of_hate", "item_tome_int_60", item_table)
	SetMonsterDropOfTable(monster_table, "npc_angel_of_hate", "item_tome_str_60", item_table)
	SetMonsterDropOfTable(monster_table, "npc_angel_of_hate", "item_tome_un_60", item_table)
	SetMonsterDropOfTable(monster_table, "npc_angel_of_hate", "item_icarus", item_table)
	SetMonsterDropOfTable(monster_table, "npc_angel_of_hate", "item_angels_armor", item_table)
	SetMonsterDropOfTable(monster_table, "npc_angel_of_hate", "item_awful_mask", item_table)
	
	ExtendMonsterDrop(monster_table, "npc_angel_of_love", "npc_angel_of_hate")
	ExtendMonsterDrop(monster_table, "npc_angel_of_life", "npc_angel_of_hate")
	ExtendMonsterDrop(monster_table, "npc_angel_of_death", "npc_angel_of_hate")
	ExtendMonsterDrop(monster_table, "Demon_possessed", "npc_angel_of_hate")

	SetMonsterDropOfTable(monster_table, "npc_boss_travaler", "item_awful_mask", item_table)
	SetMonsterDropOfTable(monster_table, "npc_boss_travaler", "item_icarus", item_table)
	SetMonsterDropOfTable(monster_table, "npc_boss_travaler", "item_skadi_2", item_table)
	SetMonsterDropOfTable(monster_table, "npc_boss_travaler", "item_aegis_aa", item_table)
	SetMonsterDropOfTable(monster_table, "npc_boss_travaler", "item_eclipse_amphora", item_table)
	
	SetMonsterDropOfTable(monster_table, "Demon_possessed", "item_possessed_sword", item_table)
	SetMonsterDropOfTable(monster_table, "Demon_possessed", "item_eclipse_amphora", item_table)

	
end

local monsters = {}

SetMonstersDropByLevel(monsters, 1, "item_ward_observer", items)
SetMonstersDropByLevel(monsters, 1, "item_slippers", items)
SetMonstersDropByLevel(monsters, 1, "item_mantle", items)
SetMonstersDropByLevel(monsters, 1, "item_gauntlets", items)
SetMonstersDropByLevel(monsters, 1, "item_circlet", items)
SetMonstersDropByLevel(monsters, 1, "item_enchanted_mango", items)
SetMonstersDropByLevel(monsters, 1, "item_ring_of_protection", items)

ExtendsMonsterDropsByLevels(monsters, 5, 1, items)

SetMonstersDropByLevel(monsters, 10, "item_boots", items)
SetMonstersDropByLevel(monsters, 10, "item_belt_of_strength", items)
SetMonstersDropByLevel(monsters, 10, "item_boots_of_elves", items)
SetMonstersDropByLevel(monsters, 10, "item_robe", items)
SetMonstersDropByLevel(monsters, 10, "item_bottle", items)
SetMonstersDropByLevel(monsters, 10, "item_gloves", items)
SetMonstersDropByLevel(monsters, 10, "item_blight_stone", items)
SetMonstersDropByLevel(monsters, 10, "item_sobi_mask", items)
SetMonstersDropByLevel(monsters, 10, "item_ring_of_regen", items)

ExtendsMonsterDropsByLevels(monsters, 15, 10, items)

SetMonstersDropByLevel(monsters, 15, "item_medallion_of_courage", items)
SetMonstersDropByLevel(monsters, 15, "item_phase_boots", items)
SetMonstersDropByLevel(monsters, 15, "item_power_treads", items)
SetMonstersDropByLevel(monsters, 15, "item_arcane_boots", items)

ExtendsMonsterDropsByLevels(monsters, 20, 15, items)

SetMonstersDropByLevel(monsters, 25, "item_solar_crest", items)
SetMonstersDropByLevel(monsters, 25, "item_sange", items)
SetMonstersDropByLevel(monsters, 25, "item_yasha", items)

ExtendMonsterDrop(monsters, "npc_dota_neutral_kobold", "Croco_level_1")
ExtendMonsterDrop(monsters, "npc_dota_neutral_harpy_scout", "Croco_level_1")
ExtendMonsterDrop(monsters, "npc_dota_neutral_ghost", "Croco_level_1")
ExtendMonsterDrop(monsters, "npc_dota_neutral_gnoll_assassin", "Croco_level_1")
ExtendMonsterDrop(monsters, "npc_dota_neutral_harpy_storm", "Croco_level_1")


SetBossessDrop(monsters, items)

return monsters
-----------------------------
