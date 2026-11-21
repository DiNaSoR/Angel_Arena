"""The 99 Angel Arena items: the single source for build_arena_items.py.

Each entry is item(key, name, section, ...). `key` becomes item_arena_<key>.

  cost      gold price of a plain shop item
  recipe    (components, scroll cost) for a combined item; its price is derived
  values    AbilityValues. Names starting with bonus_ are plain stats (see arena_modifiers.lua)
  mech      passive mechanics, each driven by its own values
  active    (kind, cooldown, mana cost) for an item with a click effect
  consume   kind of single-use effect for tomes, potions and flasks
  lore      one line of flavour
  icon      what the icon shows; build_arena_items.py wraps it in the shared art direction

Components are named by key for items defined here and by full name (item_boots) for Dota items.
"""

ITEMS = []


def item(key, name, section, cost=None, recipe=None, values=None, mech=(), active=None,
         consume=None, lore="", icon=""):
    ITEMS.append(dict(key=key, name=name, section=section, cost=cost, recipe=recipe,
                      values=values or {}, mech=list(mech), active=active, consume=consume,
                      lore=lore, icon=icon))


# ------------------------------------------------------------------ consumables (10)

item("tome_vitality", "Tome of Vitality", "consumables", cost=2400, consume="tome_health",
     values={"tome_health": 120},
     lore="Its pages are warm, and they beat like a pulse.",
     icon="a thick closed leather tome with a glowing red heart emblem on its cover, crimson ribbon bookmark")
item("tome_stoneskin", "Tome of Stoneskin", "consumables", cost=2600, consume="tome_armor",
     values={"tome_armor": 1.5},
     lore="Read it once and your skin never forgets the lesson.",
     icon="a heavy tome bound in grey carved stone plates with iron clasps and a shield emblem")
item("tome_slaughter", "Tome of Slaughter", "consumables", cost=2800, consume="tome_damage",
     values={"tome_damage": 8},
     lore="A manual of arms written by someone who never lost.",
     icon="a black tome with crossed blood-red swords embossed on the cover, sharp steel corners")
item("tome_ascension", "Tome of Ascension", "consumables", cost=4000, consume="tome_level",
     values={"tome_levels": 1},
     lore="The last page is blank. You are meant to become it.",
     icon="a radiant white and gold tome floating open with a beam of light rising from its pages")
item("codex", "Codex of the Arena", "consumables", cost=5200, consume="tome_stats",
     values={"tome_all_stats": 4},
     lore="Every champion who ever won here added a line.",
     icon="an ornate tome with a three-coloured gem, red green and blue, set in a golden laurel wreath on the cover")
item("angels_tear", "Angel's Tear", "consumables", cost=350, consume="potion_heal",
     values={"potion_heal_pct": 35},
     lore="Shed for the fallen, bottled for the living.",
     icon="a small crystal teardrop vial filled with luminous pale-blue liquid, tiny feathered wings on the stopper")
item("starlight_phial", "Phial of Starlight", "consumables", cost=300, consume="potion_mana",
     values={"potion_mana_pct": 60},
     lore="Night sky, decanted.",
     icon="a slender glass phial of deep indigo liquid full of tiny glittering stars, silver cap")
item("demons_blood", "Demon's Blood", "consumables", cost=600, consume="potion_buff",
     values={"potion_duration": 15, "buff_damage": 60, "buff_attack_speed": 40, "buff_armor": -6},
     lore="It is not yours, and it wants out.",
     icon="a jagged black iron flask of boiling glowing red blood, horned stopper, red steam")
item("ironskin_elixir", "Elixir of Iron Skin", "consumables", cost=600, consume="potion_buff",
     values={"potion_duration": 15, "buff_armor": 12, "buff_magic_resistance": 25},
     lore="Tastes of nails. Works like them too.",
     icon="a squat steel-banded bottle of thick metallic silver liquid with rivets around the neck")
item("ember_flask", "Ember Flask", "consumables", cost=500, consume="potion_ember",
     values={"potion_duration": 10, "ember_dps": 60, "ember_radius": 350},
     lore="Do not shake. Do not hold. Do not stand near.",
     icon="a round glass flask holding a live swirling fireball, glowing orange cracks in the glass, cork wired shut")

# ------------------------------------------------------------- attributes (9)

item("seraph_feather", "Seraph Feather", "attributes", cost=900, values={"bonus_agility": 9},
     lore="It never quite touches the ground.",
     icon="a single large white feather with a golden quill, softly glowing, drifting")
item("halo_shard", "Halo Shard", "attributes", cost=900, values={"bonus_intellect": 9},
     lore="A broken ring of light that still hums.",
     icon="a curved broken fragment of a glowing golden halo ring, bright cyan light at the fracture")
item("demon_horn", "Demon Horn", "attributes", cost=900, values={"bonus_strength": 9},
     lore="Taken from something that did not want to give it.",
     icon="a single curved ridged black demon horn with glowing ember cracks at the base")
item("champions_ring", "Champion's Signet", "attributes", cost=1500, values={"bonus_all_stats": 5},
     lore="Worn smooth by a hundred victories.",
     icon="a heavy gold signet ring engraved with a laurel wreath and a tiny sword")
item("titan_knuckle", "Titan Knuckle", "attributes", cost=2700, values={"bonus_strength": 22},
     lore="One finger bone of something the size of a hill.",
     icon="a massive spiked knuckle-duster made of ancient bronze and giant bone, glowing red runes")
item("phantom_quill", "Phantom Quill", "attributes", cost=2700, values={"bonus_agility": 22},
     lore="It writes faster than the hand that holds it.",
     icon="a sleek ghostly green translucent feather quill trailing wisps of mist, silver nib")
item("oracle_eye", "Oracle's Eye", "attributes", cost=2700, values={"bonus_intellect": 22},
     lore="It blinks when you are about to be wrong.",
     icon="a glowing blue crystal eye set in an ornate silver amulet frame with fine chains")
item("prism_core", "Prism Core", "attributes", cost=4200, values={"bonus_all_stats": 14},
     lore="Red for might, green for speed, blue for cunning. It refuses to choose.",
     icon="a faceted crystal prism core splitting light into red green and blue beams, held in a gold cage")
item("gilded_buckle", "Gilded Buckle", "attributes", cost=1000, values={"bonus_health": 220},
     lore="Holds your belt, and your insides, where they belong.",
     icon="a broad ornate golden belt buckle with a red gem on a thick leather strap")

# ----------------------------------------------------------- weapons_armor (10)

item("hellforged_ingot", "Hellforged Ingot", "weapons_armor", cost=1400, values={"bonus_damage": 18},
     lore="Still hot. It will always be hot.",
     icon="a dark metal ingot glowing molten orange at the edges, stamped with a demonic rune")
item("blessed_ingot", "Blessed Ingot", "weapons_armor", cost=1300, values={"bonus_armor": 5},
     lore="Quenched in holy water, which hissed in protest.",
     icon="a polished silver-white metal ingot glowing softly, stamped with a winged sigil")
item("obsidian_plate", "Obsidian Plate", "weapons_armor", cost=2200,
     values={"bonus_armor": 7, "bonus_health": 150},
     lore="Volcanic glass, a hand thick.",
     icon="a thick slab of glossy black obsidian armour plate with sharp facets and iron rivets")
item("whetstone", "Whetstone of Wrath", "weapons_armor", cost=1100, values={"bonus_attack_speed": 20},
     lore="It sharpens the arm as much as the blade.",
     icon="a worn grey whetstone throwing bright orange sparks, wrapped in red cord")
item("wardens_buckler", "Warden's Buckler", "weapons_armor", cost=1600,
     values={"bonus_armor": 3, "block_chance": 60, "block_amount": 24}, mech=["block"],
     lore="Small enough to carry, big enough to matter.",
     icon="a small round steel buckler shield with a bronze boss and a dented rim")
item("executioner_axe", "Headsman's Axe", "weapons_armor", cost=3200, values={"bonus_damage": 38},
     lore="It has only ever needed one swing.",
     icon="a huge single-bladed executioner axe with a dark crescent blade and a long black haft")
item("gladius", "Arena Gladius", "weapons_armor", cost=1900,
     values={"bonus_damage": 14, "bonus_attack_speed": 14},
     lore="Short, quick and honest.",
     icon="a short broad roman gladius sword with a bronze guard and a red tassel on the pommel")
item("spiked_pauldron", "Spiked Pauldron", "weapons_armor", cost=2100,
     values={"bonus_armor": 4, "thorns_pct": 14}, mech=["thorns"],
     lore="A shoulder to cry on, briefly.",
     icon="a dark iron shoulder pauldron covered in long sharp spikes")
item("duelist_glove", "Duelist's Glove", "weapons_armor", cost=2400,
     values={"bonus_attack_speed": 30, "bonus_agility": 6},
     lore="Thrown down more often than it is worn.",
     icon="an elegant fingerless leather fencing glove with gold stitching and a steel knuckle guard")
item("bone_club", "Ogre Bone Club", "weapons_armor", cost=2000,
     values={"bonus_strength": 12, "bonus_damage": 10},
     lore="The ogre is not using it any more.",
     icon="a crude massive club made from a giant thigh bone bound with leather and iron nails")

# ------------------------------------------------------------------- misc (9)

item("cinder_heart", "Cinder Heart", "misc", cost=1200, values={"bonus_health_regen": 7},
     lore="Blow on it gently and it glows.",
     icon="a heart-shaped lump of black coal with glowing orange embers inside")
item("starlight_thread", "Starlight Thread", "misc", cost=1100, values={"bonus_mana_regen": 3},
     lore="Spun at night, by nobody anyone has met.",
     icon="a spool of fine glowing silver-blue thread sparkling with tiny stars")
item("blood_vial", "Vampire's Vial", "misc", cost=1700, values={"lifesteal_pct": 12}, mech=["lifesteal"],
     lore="Always half full. Never ask of what.",
     icon="a gothic vial of dark red blood in a black iron frame with small bat wings")
item("wind_charm", "Zephyr Charm", "misc", cost=1300, values={"bonus_movement_speed": 25},
     lore="A breeze follows whoever wears it.",
     icon="a teal jade charm carved as a swirling gust of wind on a leather cord")
item("ward_stone", "Warding Stone", "misc", cost=1500, values={"bonus_magic_resistance": 18},
     lore="Spells slide off it like rain.",
     icon="a smooth river stone carved with glowing violet protective runes")
item("mist_cloak", "Mistveil Cloak", "misc", cost=1800, values={"bonus_evasion": 15},
     lore="There, and then somewhere slightly to the left.",
     icon="a hooded grey-blue cloak dissolving into drifting mist at its edges")
item("lucky_coin", "Gambler's Coin", "misc", cost=2000, values={"gold_per_second": 2}, mech=["gold"],
     lore="Heads you win. It has no tails.",
     icon="a large gold coin stamped with a skull on a four-leaf clover, glinting")
item("mana_prism", "Mana Prism", "misc", cost=1600, values={"bonus_mana": 350, "bonus_spell_amp": 6},
     lore="It drinks light and gives back power.",
     icon="a floating triangular blue crystal prism crackling with arcane energy")
item("hourglass", "Sands of Haste", "misc", cost=2600, values={"bonus_cooldown_reduction": 10},
     lore="The sand runs upward when you are not looking.",
     icon="a small brass hourglass with glowing golden sand flowing upward")

# ------------------------------------------------------------- secretshop (8)

item("seraph_plume", "Archangel's Plume", "secretshop", cost=5200,
     values={"bonus_agility": 30, "bonus_movement_speed": 30},
     lore="Fallen in battle, and still falling.",
     icon="a magnificent long golden-white wing plume with a blazing halo ring around its quill")
item("fallen_star", "Fallen Star", "secretshop", cost=5400, values={"bonus_damage": 70},
     lore="It landed in the arena. Nobody dared to move it.",
     icon="a jagged chunk of star metal meteorite glowing white-hot at its core with a blue flame trail")
item("abyssal_heart", "Heart of the Abyss", "secretshop", cost=5600,
     values={"bonus_health": 600, "bonus_health_regen": 12},
     lore="It kept beating after the demon stopped.",
     icon="a huge dark demonic heart wrapped in black chains with glowing magma veins")
item("celestial_orb", "Celestial Orb", "secretshop", cost=5500,
     values={"bonus_intellect": 32, "bonus_mana": 500},
     lore="A small sky you can hold.",
     icon="a glass orb containing a miniature swirling galaxy held in golden angel-wing clasps")
item("dragon_scale", "Elder Dragon Scale", "secretshop", cost=5200, values={"bonus_armor": 14},
     lore="One scale. The dragon had thousands. You would not have wanted to meet it.",
     icon="a large iridescent bronze-green dragon scale shaped like a kite shield")
item("titan_core", "Titan's Core", "secretshop", cost=5400,
     values={"bonus_strength": 32, "bonus_health": 300},
     lore="The furnace that drove a walking mountain.",
     icon="a dense glowing orange core of molten rock clamped in cracked ancient bronze bands")
item("storm_shard", "Thunderbird Shard", "secretshop", cost=5000, values={"bonus_attack_speed": 60},
     lore="Hold it to your ear and you will hear the storm it came from.",
     icon="a jagged yellow-blue crystal shard crackling with lightning, shaped like a talon")
item("void_crystal", "Void Crystal", "secretshop", cost=5600,
     values={"bonus_spell_amp": 16, "bonus_magic_resistance": 15},
     lore="It is not purple. It is the absence of every other colour.",
     icon="a floating dark violet crystal with a black core that bends the light around it")

# --------------------------------------------------------------- weapons (15)

item("dawn_blade", "Dawn Blade", "weapons", recipe=(["gladius", "seraph_feather"], 400),
     values={"bonus_agility": 16, "bonus_damage": 22, "bonus_attack_speed": 18,
             "smite_attacks": 5, "smite_damage": 90}, mech=["smite"],
     lore="Forged at first light and never dulled since.",
     icon="a slim elegant sword with a pale gold blade glowing with soft sunrise light, white winged crossguard")
item("seraph_blade", "Seraph Blade", "weapons", recipe=(["dawn_blade", "phantom_quill"], 900),
     values={"bonus_agility": 40, "bonus_damage": 40, "bonus_attack_speed": 30,
             "smite_attacks": 4, "smite_damage": 220}, mech=["smite"],
     lore="Carried by those who guard the gates above.",
     icon="a radiant longsword with a blade of bright white light and an ornate golden angel-wing hilt")
item("first_light", "Blade of the First Light", "weapons", recipe=(["seraph_blade", "seraph_plume"], 2000),
     values={"bonus_agility": 75, "bonus_damage": 80, "bonus_attack_speed": 50, "bonus_movement_speed": 30,
             "smite_attacks": 3, "smite_damage": 520}, mech=["smite"],
     lore="Before there was a sun, there was this.",
     icon="a legendary greatsword of blinding golden light with six small wings on the hilt and a halo around the blade")
item("hellcleaver", "Hellcleaver", "weapons", recipe=(["bone_club", "hellforged_ingot"], 300),
     values={"bonus_strength": 14, "bonus_damage": 36, "cleave_pct": 30, "cleave_radius": 300}, mech=["cleave"],
     lore="Too heavy to swing gently.",
     icon="a brutal wide butcher cleaver of blackened iron with a glowing red-hot chipped edge")
item("infernal_cleaver", "Infernal Cleaver", "weapons", recipe=(["hellcleaver", "titan_knuckle"], 1000),
     values={"bonus_strength": 38, "bonus_damage": 60, "cleave_pct": 45, "cleave_radius": 350,
             "burn_dps": 30, "burn_duration": 3}, mech=["cleave", "burn"],
     lore="The edge is on fire. So is whatever it touches.",
     icon="a massive demonic cleaver wreathed in flames with a jagged obsidian blade and horned guard")
item("worldender", "Worldender", "weapons", recipe=(["infernal_cleaver", "fallen_star"], 2200),
     values={"bonus_strength": 60, "bonus_damage": 150, "cleave_pct": 70, "cleave_radius": 450,
             "burn_dps": 90, "burn_duration": 4}, mech=["cleave", "burn"],
     lore="It was made to end one world. It has had practice.",
     icon="a colossal apocalyptic greataxe of molten lava and black iron with a blazing meteor in its head")
item("soul_sickle", "Soul Sickle", "weapons", recipe=(["executioner_axe", "blood_vial"], 300),
     values={"bonus_damage": 44, "lifesteal_pct": 14, "soul_damage": 3, "soul_max": 20},
     mech=["lifesteal", "souls"],
     lore="It reaps, and it remembers.",
     icon="a curved dark sickle with pale ghostly green souls swirling along its blade")
item("soul_reaver", "Soul Reaver", "weapons", recipe=(["soul_sickle", "duelist_glove"], 1200),
     values={"bonus_damage": 60, "bonus_attack_speed": 35, "lifesteal_pct": 18, "soul_damage": 5, "soul_max": 30,
             "crit_chance": 20, "crit_multiplier": 180}, mech=["lifesteal", "souls", "crit"],
     lore="The screaming is on the inside.",
     icon="a wicked double-bladed scythe sword with a spectral green glow and screaming ghost faces in the steel")
item("harvester_of_kings", "Harvester of Kings", "weapons", recipe=(["soul_reaver", "fallen_star"], 2600),
     values={"bonus_damage": 140, "bonus_attack_speed": 50, "lifesteal_pct": 25, "soul_damage": 8, "soul_max": 40,
             "crit_chance": 25, "crit_multiplier": 240}, mech=["lifesteal", "souls", "crit"],
     lore="Crowns roll further than heads.",
     icon="a towering royal war scythe with a crown-shaped guard, black blade, spectral green flames and tiny golden crowns hanging from chains")
item("sparkfang", "Sparkfang", "weapons", recipe=(["gladius", "whetstone"], 400),
     values={"bonus_damage": 16, "bonus_attack_speed": 40, "chain_chance": 20, "chain_damage": 90, "chain_targets": 3},
     mech=["chain"],
     lore="It bites, and the bite travels.",
     icon="a short curved dagger shaped like a fang crackling with small blue sparks")
item("stormfang", "Stormfang", "weapons", recipe=(["sparkfang", "duelist_glove"], 1000),
     values={"bonus_damage": 24, "bonus_attack_speed": 80, "bonus_agility": 8,
             "chain_chance": 25, "chain_damage": 180, "chain_targets": 4}, mech=["chain"],
     lore="Thunder arrives a moment after the cut.",
     icon="a pair of crossed fang daggers arcing with bright blue lightning and storm clouds")
item("tempest_fang", "Tempest Fang", "weapons", recipe=(["stormfang", "storm_shard"], 2200),
     values={"bonus_damage": 50, "bonus_attack_speed": 150, "bonus_agility": 20,
             "chain_chance": 30, "chain_damage": 400, "chain_targets": 6}, mech=["chain"],
     lore="A whole storm, taught to hold still long enough to be a knife.",
     icon="a legendary blade made of solid lightning with a thunderbird-head hilt and a swirling tempest around it")
item("judges_gavel", "Judge's Gavel", "weapons", recipe=(["bone_club", "demon_horn"], 500),
     values={"bonus_strength": 24, "bonus_damage": 14, "bash_chance": 15, "bash_duration": 0.8, "bash_damage": 60},
     mech=["bash"],
     lore="Order in the arena.",
     icon="a heavy wooden and iron judge's gavel war hammer with a square head")
item("hammer_of_verdicts", "Hammer of Verdicts", "weapons", recipe=(["judges_gavel", "executioner_axe"], 900),
     values={"bonus_strength": 30, "bonus_damage": 60, "bash_chance": 20, "bash_duration": 1.0, "bash_damage": 140},
     mech=["bash"],
     lore="Guilty.",
     icon="an ornate gold and steel war hammer engraved with scales of justice, glowing white runes")
item("final_judgment", "Final Judgment", "weapons", recipe=(["hammer_of_verdicts", "titan_core"], 2400),
     values={"bonus_strength": 70, "bonus_damage": 90, "bonus_health": 400,
             "bash_chance": 25, "bash_duration": 1.3, "bash_damage": 320,
             "active_damage": 600, "active_stun": 2.0, "active_range": 700},
     mech=["bash"], active=("smite", 30, 100),
     lore="There is no appeal.",
     icon="a colossal divine war hammer of white marble and gold with a blazing sun in its head and angel wings on the haft")

# ------------------------------------------------------------- artifacts (12)

item("fledgling_wings", "Fledgling Wings", "artifacts", recipe=(["seraph_feather", "wind_charm"], 600),
     values={"bonus_agility": 12, "bonus_movement_speed": 30, "active_duration": 4, "active_move_speed": 15},
     active=("flight", 40, 50),
     lore="Not much to look at. They get you over the wall.",
     icon="a pair of small downy white feathered wings on a simple leather harness")
item("seraph_wings", "Seraph Wings", "artifacts", recipe=(["fledgling_wings", "phantom_quill", "mist_cloak"], 900),
     values={"bonus_agility": 36, "bonus_movement_speed": 40, "bonus_evasion": 18,
             "active_duration": 6, "active_move_speed": 20}, active=("flight", 32, 50),
     lore="Six feathers of every seven are light. The seventh is a blade.",
     icon="a pair of large graceful white angel wings with golden tips, softly glowing")
item("archangel_wings", "Wings of the Archangel", "artifacts", recipe=(["seraph_wings", "seraph_plume"], 2400),
     values={"bonus_agility": 70, "bonus_movement_speed": 75, "bonus_evasion": 25, "bonus_health": 300,
             "active_duration": 8, "active_move_speed": 30}, active=("flight", 25, 50),
     lore="The sky makes room for whoever wears them.",
     icon="six majestic radiant golden-white wings spread wide with a blazing halo above them")
item("imp_horns", "Imp Horns", "artifacts", recipe=(["demon_horn", "hellforged_ingot"], 500),
     values={"bonus_strength": 10, "bonus_damage": 20,
             "berserk_threshold": 40, "berserk_damage": 40, "berserk_attack_speed": 40}, mech=["berserk"],
     lore="Small horns. Large temper.",
     icon="a pair of small curved red imp horns on a spiked leather headband")
item("demon_lord_horns", "Demon Lord's Horns", "artifacts", recipe=(["imp_horns", "titan_knuckle", "blood_vial"], 900),
     values={"bonus_strength": 34, "bonus_damage": 30, "lifesteal_pct": 15,
             "berserk_threshold": 40, "berserk_damage": 90, "berserk_attack_speed": 80},
     mech=["lifesteal", "berserk"],
     lore="He is still looking for them.",
     icon="a pair of large twisted black demon horns with glowing lava cracks on a dark iron circlet")
item("crown_of_the_abyss", "Crown of the Abyss", "artifacts", recipe=(["demon_lord_horns", "titan_core"], 2500),
     values={"bonus_strength": 70, "bonus_damage": 60, "bonus_health": 300, "lifesteal_pct": 22,
             "berserk_threshold": 50, "berserk_damage": 200, "berserk_attack_speed": 140,
             "active_duration": 8, "active_attack_speed": 150, "active_damage": 100},
     mech=["lifesteal", "berserk"], active=("rage", 35, 0),
     lore="Heavy is the head. Heavier is everything in front of it.",
     icon="a terrifying crown of jagged black horns and obsidian spikes burning with hellfire, a red gem at the brow")
item("tarnished_halo", "Tarnished Halo", "artifacts", recipe=(["halo_shard", "cinder_heart"], 500),
     values={"bonus_intellect": 10, "bonus_health_regen": 8,
             "aura_radius": 900, "aura_armor": 3, "aura_health_regen": 4}, mech=["aura_ally"],
     lore="Dull, dented, and still kind.",
     icon="a dull scratched bronze halo ring with a faint warm glow")
item("radiant_halo", "Radiant Halo", "artifacts", recipe=(["tarnished_halo", "oracle_eye", "blessed_ingot"], 1000),
     values={"bonus_intellect": 30, "bonus_armor": 6, "bonus_health_regen": 10,
             "aura_radius": 900, "aura_armor": 6, "aura_health_regen": 10,
             "active_heal": 400, "active_radius": 900}, mech=["aura_ally"], active=("heal", 40, 150),
     lore="Stand close. It has enough for everyone.",
     icon="a bright polished golden halo ring shining with warm light rays")
item("seraphim_halo", "Halo of the Seraphim", "artifacts", recipe=(["radiant_halo", "celestial_orb"], 2400),
     values={"bonus_intellect": 60, "bonus_armor": 10, "bonus_health_regen": 18, "bonus_mana": 500,
             "aura_radius": 1000, "aura_armor": 10, "aura_health_regen": 20,
             "active_heal": 1100, "active_radius": 1000}, mech=["aura_ally"], active=("heal", 40, 200),
     lore="Three rings of light, one inside the other, turning.",
     icon="three concentric blazing golden halo rings rotating around a star of white light with tiny wings")
item("brimstone_censer", "Brimstone Censer", "artifacts", recipe=(["hellforged_ingot", "cinder_heart"], 400),
     values={"bonus_damage": 18, "bonus_health_regen": 7,
             "aura_radius": 400, "aura_burn_dps": 30}, mech=["aura_enemy"],
     lore="Swing it and the air itself coughs.",
     icon="a black iron censer on a chain leaking yellow sulphur smoke and embers")
item("hellfire_brazier", "Hellfire Brazier", "artifacts", recipe=(["brimstone_censer", "obsidian_plate", "demon_horn"], 1200),
     values={"bonus_damage": 26, "bonus_strength": 16, "bonus_armor": 8, "bonus_health": 150,
             "aura_radius": 450, "aura_burn_dps": 70, "aura_armor_reduction": 3}, mech=["aura_enemy"],
     lore="It does not warm. It only burns.",
     icon="a horned black iron brazier bowl filled with roaring red and orange hellfire")
item("heart_of_the_inferno", "Heart of the Inferno", "artifacts", recipe=(["hellfire_brazier", "abyssal_heart"], 2300),
     values={"bonus_damage": 40, "bonus_strength": 30, "bonus_armor": 12, "bonus_health": 800, "bonus_health_regen": 14,
             "aura_radius": 500, "aura_burn_dps": 160, "aura_armor_reduction": 6,
             "active_damage": 700, "active_radius": 600, "burn_dps": 80, "burn_duration": 4},
     mech=["aura_enemy"], active=("nova", 25, 120),
     lore="Somewhere below, a furnace is missing its fire.",
     icon="a blazing molten heart of pure hellfire inside a cage of black demonic claws, fire erupting from it")

# --------------------------------------------------------------- defense (12)

item("templar_plate", "Templar Plate", "defense", recipe=(["blessed_ingot", "wardens_buckler"], 400),
     values={"bonus_armor": 9, "bonus_health": 100, "block_chance": 60, "block_amount": 30}, mech=["block"],
     lore="Plain steel and a clear conscience.",
     icon="a polished steel knight breastplate with a simple engraved cross and leather straps")
item("paladin_plate", "Paladin's Plate", "defense", recipe=(["templar_plate", "obsidian_plate", "gilded_buckle"], 1000),
     values={"bonus_armor": 18, "bonus_health": 450, "block_chance": 60, "block_amount": 60}, mech=["block"],
     lore="Each dent is a prayer answered.",
     icon="an ornate white and gold paladin chest armour with winged shoulder guards and a sun emblem")
item("bulwark_of_heaven", "Bulwark of Heaven", "defense", recipe=(["paladin_plate", "dragon_scale"], 2400),
     values={"bonus_armor": 36, "bonus_health": 800, "bonus_health_regen": 10,
             "block_chance": 70, "block_amount": 110, "guardian_heal_pct": 40, "guardian_cooldown": 150},
     mech=["block", "guardian"],
     lore="The wall the angels stand behind.",
     icon="a legendary radiant golden full plate cuirass with large angel wings and a glowing halo behind it")
item("barbed_hide", "Barbed Hide", "defense", recipe=(["spiked_pauldron", "gilded_buckle"], 300),
     values={"bonus_armor": 5, "bonus_health": 250, "thorns_pct": 20}, mech=["thorns"],
     lore="Hugging is discouraged.",
     icon="a rough dark leather vest studded all over with iron barbs and hooks")
item("hellspike_carapace", "Hellspike Carapace", "defense", recipe=(["barbed_hide", "obsidian_plate", "demon_horn"], 1100),
     values={"bonus_armor": 13, "bonus_health": 500, "bonus_strength": 12, "thorns_pct": 32}, mech=["thorns"],
     lore="Grown, not forged.",
     icon="a demonic black chitin carapace chest armour covered in long red-tipped spikes")
item("abyssal_thornmail", "Abyssal Thornmail", "defense", recipe=(["hellspike_carapace", "dragon_scale"], 2300),
     values={"bonus_armor": 28, "bonus_health": 900, "bonus_strength": 25, "thorns_pct": 50}, mech=["thorns"],
     lore="Strike it and learn something about yourself.",
     icon="a monstrous suit of black armour bristling with huge glowing magma spikes and chains")
item("trollheart_locket", "Trollheart Locket", "defense", recipe=(["gilded_buckle", "cinder_heart"], 500),
     values={"bonus_health": 300, "bonus_health_regen": 10},
     lore="The troll grew another. Probably.",
     icon="a green warty heart inside a rough iron locket on a chain")
item("hydra_heart", "Hydra Heart", "defense", recipe=(["trollheart_locket", "titan_knuckle", "gilded_buckle"], 1100),
     values={"bonus_strength": 26, "bonus_health": 700, "bonus_health_regen_pct": 1},
     lore="Cut it and two heartbeats answer.",
     icon="a large scaly green heart with three snake heads growing from it, pulsing")
item("leviathan_heart", "Leviathan's Heart", "defense", recipe=(["hydra_heart", "abyssal_heart"], 2400),
     values={"bonus_strength": 50, "bonus_health": 1800, "bonus_health_regen": 15, "bonus_health_regen_pct": 2},
     lore="The sea has been quieter since.",
     icon="an enormous deep-sea blue heart encrusted with barnacles and coral, glowing teal, water swirling around it")
item("runed_mantle", "Runed Mantle", "defense", recipe=(["ward_stone", "starlight_thread"], 400),
     values={"bonus_magic_resistance": 22, "bonus_mana_regen": 3.5},
     lore="The stitching is the spell.",
     icon="a short violet shoulder mantle embroidered with glowing silver runes")
item("spellward_shroud", "Spellward Shroud", "defense", recipe=(["runed_mantle", "mist_cloak", "champions_ring"], 1200),
     values={"bonus_magic_resistance": 30, "bonus_status_resistance": 15, "bonus_all_stats": 8, "bonus_evasion": 15},
     lore="Curses get lost in the folds.",
     icon="a flowing dark blue hooded shroud covered in shifting glowing arcane wards")
item("mantle_of_the_void", "Mantle of the Void", "defense", recipe=(["spellward_shroud", "void_crystal"], 2400),
     values={"bonus_magic_resistance": 40, "bonus_status_resistance": 25, "bonus_all_stats": 16, "bonus_evasion": 20,
             "bonus_spell_amp": 16, "active_shield": 900, "active_duration": 6}, active=("shield", 35, 100),
     lore="Wear the dark, and nothing in it can find you.",
     icon="a regal cloak made of starless black void with violet lightning at its edges and a crystal clasp")

# ----------------------------------------------------------------- magics (9)

item("wand_of_sparks", "Wand of Sparks", "magics", recipe=(["halo_shard", "mana_prism"], 400),
     values={"bonus_intellect": 12, "bonus_mana": 350, "bonus_spell_amp": 8,
             "active_damage": 180, "active_stun": 0, "active_range": 700}, active=("smite", 14, 60),
     lore="A beginner's wand that has outlived several beginners.",
     icon="a short wooden wand tipped with a small bright yellow crystal throwing sparks")
item("staff_of_sunfire", "Staff of Sunfire", "magics", recipe=(["wand_of_sparks", "oracle_eye", "starlight_thread"], 1300),
     values={"bonus_intellect": 36, "bonus_mana": 400, "bonus_mana_regen": 4, "bonus_spell_amp": 14,
             "active_damage": 420, "active_stun": 0.6, "active_range": 750}, active=("smite", 13, 90),
     lore="Point it at something you can live without.",
     icon="a tall golden staff topped with a burning miniature sun held by three prongs")
item("solar_scepter", "Solar Scepter", "magics", recipe=(["staff_of_sunfire", "celestial_orb"], 2400),
     values={"bonus_intellect": 75, "bonus_mana": 1000, "bonus_mana_regen": 7, "bonus_spell_amp": 24,
             "active_damage": 1000, "active_stun": 1.2, "active_range": 800}, active=("smite", 12, 130),
     lore="Noon, on demand.",
     icon="a magnificent royal scepter of white gold with a blazing sun orb crowned by angel wings and solar flares")
item("apprentice_codex", "Apprentice's Codex", "magics", recipe=(["halo_shard", "starlight_thread"], 500),
     values={"bonus_intellect": 10, "bonus_mana_regen": 4, "spell_lifesteal_pct": 8}, mech=["spell_lifesteal"],
     lore="Margins full of corrections, in several hands.",
     icon="a small worn blue spellbook with a brass lock and ink stains, a quill tucked in it")
item("grimoire_of_echoes", "Grimoire of Echoes", "magics", recipe=(["apprentice_codex", "hourglass", "oracle_eye"], 900),
     values={"bonus_intellect": 32, "bonus_mana_regen": 5, "bonus_cooldown_reduction": 15,
             "spell_lifesteal_pct": 14}, mech=["spell_lifesteal"],
     lore="Read a line aloud and it reads itself back.",
     icon="a floating open purple grimoire with glowing runes rising from its pages as echoing rings")
item("infinite_verses", "Tome of Infinite Verses", "magics", recipe=(["grimoire_of_echoes", "void_crystal"], 2400),
     values={"bonus_intellect": 55, "bonus_mana_regen": 8, "bonus_cooldown_reduction": 25, "bonus_spell_amp": 16,
             "bonus_cast_range": 200, "spell_lifesteal_pct": 22}, mech=["spell_lifesteal"],
     lore="Nobody has reached the end. Nobody has found the beginning either.",
     icon="a legendary cosmic tome bound in starlight with endless pages spiralling out of it into a galaxy")
item("rimeglass_orb", "Rimeglass Orb", "magics", recipe=(["champions_ring", "mana_prism"], 300),
     values={"bonus_all_stats": 5, "bonus_mana": 350, "bonus_spell_amp": 6, "slow_pct": 14, "slow_duration": 2},
     mech=["slow"],
     lore="Cold enough to stick to your fingers.",
     icon="a frosted pale-blue glass orb with ice crystals growing on its surface")
item("frostbound_orb", "Frostbound Orb", "magics", recipe=(["rimeglass_orb", "prism_core"], 900),
     values={"bonus_all_stats": 19, "bonus_mana": 400, "bonus_spell_amp": 8, "slow_pct": 24, "slow_duration": 2.5,
             "mana_burn": 30}, mech=["slow", "mana_burn"],
     lore="Winter, with a grudge.",
     icon="a large orb of swirling blizzard held in a claw of jagged blue ice")
item("heart_of_winter", "Heart of Winter", "magics", recipe=(["frostbound_orb", "celestial_orb"], 2300),
     values={"bonus_all_stats": 30, "bonus_mana": 1000, "bonus_spell_amp": 12, "bonus_armor": 10,
             "slow_pct": 35, "slow_duration": 3, "mana_burn": 70}, mech=["slow", "mana_burn"],
     lore="It has never once thawed.",
     icon="a huge crystalline frozen heart of deep blue ice radiating a snowstorm, with a white glow at its centre")

# ---------------------------------------------------------------- support (3)

item("pilgrims_lantern", "Pilgrim's Lantern", "support", recipe=(["whetstone", "starlight_thread"], 500),
     values={"bonus_attack_speed": 20, "bonus_mana_regen": 3, "aura_radius": 900, "aura_attack_speed": 15},
     mech=["aura_ally"],
     lore="Follow it. Others already are.",
     icon="a small brass travelling lantern with a warm steady flame on a wooden staff hook")
item("beacon_of_hope", "Beacon of Hope", "support", recipe=(["pilgrims_lantern", "champions_ring", "hellforged_ingot"], 1200),
     values={"bonus_all_stats": 5, "bonus_damage": 18, "bonus_attack_speed": 25,
             "aura_radius": 900, "aura_attack_speed": 30, "aura_damage_pct": 10}, mech=["aura_ally"],
     lore="Seen from the far side of the arena, and from further than that.",
     icon="an ornate golden lantern with a brilliant white flame and light rays, small wings on its top")
item("lighthouse_of_souls", "Lighthouse of Souls", "support", recipe=(["beacon_of_hope", "prism_core"], 2400),
     values={"bonus_all_stats": 20, "bonus_damage": 30, "bonus_attack_speed": 40,
             "aura_radius": 1000, "aura_attack_speed": 55, "aura_damage_pct": 20, "aura_health_regen": 6},
     mech=["aura_ally"],
     lore="The dead steer by it. The living fight under it.",
     icon="a miniature white marble lighthouse tower with a blazing rotating beam and ghostly blue spirits circling it")

# ----------------------------------------------------------------- basics (2)

item("pilgrim_sandals", "Pilgrim's Sandals", "basics", recipe=(["item_boots", "cinder_heart"], 300),
     values={"bonus_movement_speed": 55, "bonus_health_regen": 8},
     lore="Ten thousand miles, and the soles are still good.",
     icon="a pair of simple worn leather sandals with a faint golden glow and small wing charms")
item("legion_greaves", "Greaves of the Legion", "basics", recipe=(["item_boots", "whetstone", "blessed_ingot"], 600),
     values={"bonus_movement_speed": 60, "bonus_attack_speed": 30, "bonus_armor": 6},
     lore="March in step, and nothing in front of you stays standing.",
     icon="a pair of heavy steel plated war boots with red legion cloth and bronze trim")


# ------------------------------------------------------------------ tooltip wording
#
# TITLES names an item's abilities in its tooltip: {effect: name}, shared by every item listed.
# An effect without a name here uses the plain one from build_arena_items.py. Lifesteal and
# spell lifesteal are stat lines unless they are named here, which gives them a paragraph too.
# NOTES adds free paragraphs: {key: [(heading, text)]}, for things that are not an effect.

TITLES = {
    ("wardens_buckler",): {"block": "Deflect"},
    ("spiked_pauldron",): {"thorns": "Spikes"},
    ("blood_vial",): {"lifesteal": "Thirst"},
    ("lucky_coin",): {"gold": "The house always pays"},
    ("dawn_blade", "seraph_blade", "first_light"): {"smite": "Daybreak"},
    ("hellcleaver", "infernal_cleaver", "worldender"): {"cleave": "Butcher's arc", "burn": "Hellfire edge"},
    ("soul_sickle", "soul_reaver", "harvester_of_kings"): {"souls": "Soul harvest", "crit": "Reaper's due",
                                                           "lifesteal": "Feast"},
    ("sparkfang", "stormfang", "tempest_fang"): {"chain": "Forked lightning"},
    ("judges_gavel", "hammer_of_verdicts", "final_judgment"): {"bash": "Order in the arena", "smite": "Final verdict"},
    ("fledgling_wings", "seraph_wings", "archangel_wings"): {"flight": "Take wing"},
    ("imp_horns", "demon_lord_horns", "crown_of_the_abyss"): {"berserk": "Cornered fury", "rage": "Blood rage",
                                                              "lifesteal": "Blood price"},
    ("tarnished_halo", "radiant_halo", "seraphim_halo"): {"aura_ally": "Sanctuary", "heal": "Benediction"},
    ("brimstone_censer", "hellfire_brazier", "heart_of_the_inferno"): {"aura_enemy": "Brimstone", "nova": "Inferno"},
    ("templar_plate", "paladin_plate", "bulwark_of_heaven"): {"block": "Shield wall", "guardian": "Guardian angel"},
    ("barbed_hide", "hellspike_carapace", "abyssal_thornmail"): {"thorns": "Barbs"},
    ("mantle_of_the_void",): {"shield": "Void shell"},
    ("wand_of_sparks", "staff_of_sunfire", "solar_scepter"): {"smite": "Sunlance"},
    ("apprentice_codex", "grimoire_of_echoes", "infinite_verses"): {"spell_lifesteal": "Echo"},
    ("rimeglass_orb", "frostbound_orb", "heart_of_winter"): {"slow": "Rime", "mana_burn": "Frostbite"},
    ("pilgrims_lantern", "beacon_of_hope", "lighthouse_of_souls"): {"aura_ally": "Guiding light"},
}

NOTES = {
    "hydra_heart": [("Passive: Regrowth", "Restores %bonus_health_regen_pct%%% of your maximum health every second, in and out of combat.")],
    "leviathan_heart": [("Passive: Regrowth", "Restores %bonus_health_regen_pct%%% of your maximum health every second, in and out of combat.")],
    "pilgrim_sandals": [("Passive: The long road", "The movement speed adds to that of any other boots you carry.")],
    "legion_greaves": [("Passive: Forced march", "The movement speed adds to that of any other boots you carry.")],
    "hourglass": [("Passive: Borrowed time", "Abilities and items come off cooldown %bonus_cooldown_reduction%%% sooner.")],
    "mana_prism": [("Passive: Focus", "Your spells deal %bonus_spell_amp%%% more damage.")],
    "void_crystal": [("Passive: Unmaking", "Your spells deal %bonus_spell_amp%%% more damage, and spells cast at you deal %bonus_magic_resistance%%% less.")],
}

for keys, titles in TITLES.items():
    for key in keys:
        entry = next(entry for entry in ITEMS if entry["key"] == key)
        entry.setdefault("titles", {}).update(titles)
for key, notes in NOTES.items():
    next(entry for entry in ITEMS if entry["key"] == key)["notes"] = notes

assert len(ITEMS) == 99, len(ITEMS)
